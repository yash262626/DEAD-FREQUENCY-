#include "Core/DFGameInstance.h"

#include "Core/DFSaveGame.h"
#include "DeadFrequency.h"
#include "Dom/JsonObject.h"
#include "Kismet/GameplayStatics.h"
#include "Misc/Crc.h"
#include "Misc/DateTime.h"
#include "Player/DFPlayerCharacter.h"
#include "Radio/DFRadioComponent.h"
#include "Serialization/JsonReader.h"
#include "Serialization/JsonSerializer.h"
#include "Story/DFStorySubsystem.h"
#include "TimerManager.h"
#include "UObject/UObjectGlobals.h"

namespace DFSave
{
	// Every slot is sealed with a CRC and a magic number, so a torn or damaged file is rejected before it is
	// deserialised (the Godot game validated its JSON the same way before trusting it).
	constexpr uint32 Magic = 0x31534644;     // "DFS1"

	void Seal(TArray<uint8>& Bytes)
	{
		const uint32 Crc = FCrc::MemCrc32(Bytes.GetData(), Bytes.Num());
		Bytes.Append(reinterpret_cast<const uint8*>(&Crc), sizeof(Crc));
		Bytes.Append(reinterpret_cast<const uint8*>(&Magic), sizeof(Magic));
	}

	bool Unseal(TArray<uint8>& Bytes)
	{
		if (Bytes.Num() <= 8)
		{
			return false;
		}
		uint32 Crc = 0;
		uint32 Tail = 0;
		FMemory::Memcpy(&Crc, Bytes.GetData() + Bytes.Num() - 8, sizeof(Crc));
		FMemory::Memcpy(&Tail, Bytes.GetData() + Bytes.Num() - 4, sizeof(Tail));
		if (Tail != Magic)
		{
			return false;
		}
		Bytes.SetNum(Bytes.Num() - 8);
		return FCrc::MemCrc32(Bytes.GetData(), Bytes.Num()) == Crc;
	}

	bool Write(USaveGame* Object, const FString& Slot)
	{
		TArray<uint8> Bytes;
		if (!UGameplayStatics::SaveGameToMemory(Object, Bytes))
		{
			return false;
		}
		Seal(Bytes);
		return UGameplayStatics::SaveDataToSlot(Bytes, Slot, 0);
	}

	USaveGame* Read(const FString& Slot)
	{
		TArray<uint8> Bytes;
		if (!UGameplayStatics::LoadDataFromSlot(Bytes, Slot, 0) || !Unseal(Bytes))
		{
			return nullptr;
		}
		return UGameplayStatics::LoadGameFromMemory(Bytes);
	}

	FString ChapterKey(int32 Chapter)
	{
		return Chapter == UDFGameInstance::SliceChapter ? FString(TEXT("slice")) : FString::Printf(TEXT("chapter_%02d"), Chapter);
	}
}

void UDFGameInstance::Init()
{
	Super::Init();
	LoadProfile();
	if (UDFStorySubsystem* S = Story())
	{
		S->OnFlow.AddUniqueDynamic(this, &UDFGameInstance::HandleFlow);
		S->OnAchievement.AddUniqueDynamic(this, &UDFGameInstance::HandleAchievement);
	}
	FCoreUObjectDelegates::PreLoadMap.AddUObject(this, &UDFGameInstance::HandlePreLoadMap);

	// titles for the achievement toast ("First Contact - receive your first transmission")
	FString Json;
	TSharedPtr<FJsonObject> Titles;
	if (UDFStorySubsystem::LoadStoryFile(TEXT("achievements.json"), Json)
		&& FJsonSerializer::Deserialize(TJsonReaderFactory<>::Create(Json), Titles) && Titles.IsValid())
	{
		for (const TPair<FString, TSharedPtr<FJsonValue>>& Pair : Titles->Values)
		{
			AchievementTitles.Add(Pair.Key, Pair.Value->AsString());
		}
	}
}

void UDFGameInstance::Shutdown()
{
	FCoreUObjectDelegates::PreLoadMap.RemoveAll(this);
	Super::Shutdown();
}

UDFStorySubsystem* UDFGameInstance::Story() const
{
	return GetSubsystem<UDFStorySubsystem>();
}

ADFPlayerCharacter* UDFGameInstance::GetPlayer() const
{
	const APlayerController* PC = GetFirstLocalPlayerController();
	return PC ? Cast<ADFPlayerCharacter>(PC->GetPawn()) : nullptr;
}

void UDFGameInstance::Toast(const FString& Text) const
{
	if (UDFStorySubsystem* S = Story())
	{
		S->OnUiCommand.Broadcast(TEXT("toast"), { Text });
	}
}

// ------------------------------------------------------------------------------------------------ menu

void UDFGameInstance::NewGame()
{
	NewRun(1);
	bHasRadio = false;
	StartChapter(1);
}

bool UDFGameInstance::ContinueGame()
{
	if (!LoadRun())
	{
		if (LoadError.IsEmpty())
		{
			LoadError = TEXT("No saved game found.");
		}
		return false;
	}
	PendingToast = LoadError;          // shown once the chapter has loaded
	StartChapter(Chapter);
	return true;
}

void UDFGameInstance::NewGamePlus()
{
	NewRunPlus();
	bHasRadio = false;
	StartChapter(1);
}

void UDFGameInstance::SelectChapter(int32 InChapter)
{
	const int32 N = FMath::Clamp(InChapter, 0, LastChapter);
	NewRun(N);
	StartChapter(N);
}

void UDFGameInstance::StartSlice()
{
	NewRun(1);
	bHasRadio = true;
	bHasTorch = true;
	StartChapter(SliceChapter);
}

void UDFGameInstance::ReloadCheckpoint()
{
	if (Chapter == SliceChapter)
	{
		StartSlice();
		return;
	}
	if (LoadRun())
	{
		PendingToast = LoadError;
		StartChapter(Chapter);
		return;
	}
	PendingToast = LoadError.IsEmpty() ? FString(TEXT("No checkpoint to return to.")) : LoadError;
	ShowMenu();
}

void UDFGameInstance::ShowMenu()
{
	OpenMap(TEXT("menu"), false);
}

void UDFGameInstance::PlayCredits()
{
	OpenMap(TEXT("credits"), false);
}

// ------------------------------------------------------------------------------------------------ run

void UDFGameInstance::NewRun(int32 InChapter)
{
	UDFStorySubsystem* S = Story();
	S->ResetRun();
	Chapter = InChapter;
	Health = 100.f;
	TorchBattery = 100.f;
	RadioBattery = 100.f;
	bHasRadio = InChapter > 1;
	bHasTorch = true;
	RunId = FString::Printf(TEXT("run_%lld_%04d"), FDateTime::UtcNow().ToUnixTimestamp(), FMath::RandRange(0, 9999));
	if (InChapter > 1)
	{
		// chapter-select runs get neutral story defaults
		S->Give(TEXT("battery"));
		S->Give(TEXT("medkit"));
		S->SetFlag(TEXT("cs_run"));
	}
}

void UDFGameInstance::NewRunPlus()
{
	NewRun(1);
	UDFStorySubsystem* S = Story();
	const FDFRunMemory& M = Profile->Memory;
	S->SetFlag(TEXT("ngp"));
	S->SetFlag(FName(*(TEXT("mem_end_") + (M.Ending.IsEmpty() ? FString(TEXT("C")) : M.Ending))));
	// carried at half strength: it remembers, but not perfectly
	S->SetFlag(TEXT("m_radio"), M.Radio / 2);
	for (const TPair<FName, int32>& Hide : M.Hides)
	{
		S->SetFlag(Hide.Key, FMath::DivideAndRoundUp(Hide.Value, 2));
	}
	S->SetFlag(TEXT("m_hunts"), FMath::Min(2, M.Hunts));
	S->SetFlag(TEXT("mem_bottles"), M.Bottles);
	S->SetFlag(TEXT("mem_sprint"), M.SprintEscapes);
}

void UDFGameInstance::StartChapter(int32 N)
{
	Chapter = N;
	OpenMap(DFSave::ChapterKey(N), true);
}

void UDFGameInstance::OpenMap(const FString& Key, bool bStory)
{
	StoryKey = bStory ? Key : FString();
	UGameplayStatics::OpenLevel(this, FName(*(MapRoot + TEXT("L_") + Key)));
}

void UDFGameInstance::BeginStoryInWorld(ADFPlayerCharacter* Player, const FString& MapName)
{
	UDFStorySubsystem* S = Story();
	if (StoryKey.IsEmpty() && MapName.StartsWith(TEXT("L_")))
	{
		// a story map opened directly (editor, automation): play it as a fresh chapter-select run
		const FString Key = MapName.RightChop(2);
		if (S->GetChapter(Key))
		{
			const bool bEnding = Key.StartsWith(TEXT("ending_"));
			const int32 N = Key == TEXT("slice") ? SliceChapter : (bEnding ? LastChapter : FCString::Atoi(*Key.RightChop(8)));
			NewRun(N);
			if (N == SliceChapter)
			{
				bHasRadio = true;
			}
			StoryKey = Key;
			ApplyRunToPlayer(Player);
		}
	}
	if (StoryKey.IsEmpty())
	{
		if (!PendingToast.IsEmpty())
		{
			Toast(PendingToast);
			PendingToast.Reset();
		}
		return;                                    // menu, credits, test maps
	}

	if (StoryKey.StartsWith(TEXT("ending_")))
	{
		// endings: no card and no save; the player only watches (main.gd play_ending)
		S->CurrentChapter = StoryKey;
		S->OnUiCommand.Broadcast(TEXT("cine"), { TEXT("true") });
		if (Player)
		{
			Player->SetLocked(true);
		}
		if (const FDFChapterData* Data = S->GetChapter(StoryKey))
		{
			S->RunSequence(StoryKey, Data->StartSequence, TEXT("start"));
		}
		return;
	}

	const FName Started(*FString::Printf(TEXT("started%d"), Chapter));
	const bool bFirst = !S->HasFlag(Started);
	if (bFirst)
	{
		S->SetFlag(Started);
		S->Checkpoint.Reset();
		if (Chapter != SliceChapter)
		{
			SaveRun();                             // the slice is a standalone demo: it never touches the campaign save
		}
		S->SetFlag(TEXT("hunts_start"), S->GetFlag(TEXT("m_hunts")));
	}
	S->BeginChapter(StoryKey, bFirst);
	if (!PendingToast.IsEmpty())
	{
		Toast(PendingToast);
		PendingToast.Reset();
	}
}

void UDFGameInstance::ApplyRunToPlayer(ADFPlayerCharacter* Player) const
{
	if (!Player)
	{
		return;
	}
	Player->Health = Health;
	Player->TorchBattery = TorchBattery;
	Player->bHasTorch = bHasTorch;
	if (Player->Radio)
	{
		Player->Radio->Battery = RadioBattery;
		Player->Radio->bHasRadio = bHasRadio;
	}
}

void UDFGameInstance::CapturePlayer(const ADFPlayerCharacter* Player)
{
	if (!Player)
	{
		return;
	}
	Health = Player->Health;
	TorchBattery = Player->TorchBattery;
	bHasTorch = Player->bHasTorch;
	if (Player->Radio)
	{
		RadioBattery = Player->Radio->Battery;
		bHasRadio = Player->Radio->bHasRadio;
	}
}

void UDFGameInstance::NextChapter()
{
	UDFStorySubsystem* S = Story();
	if (Chapter == SliceChapter)
	{
		ShowMenu();
		return;
	}
	if (Chapter >= LastChapter)
	{
		PlayEnding();
		return;
	}
	const int32 N = Chapter + 1;
	if (Chapter >= 2 && S->Flags.Contains(TEXT("hunts_start")) && S->GetFlag(TEXT("m_hunts")) == S->GetFlag(TEXT("hunts_start")))
	{
		Achieve(TEXT("no_hunt"));
	}
	UnlockChapter(N);
	S->Checkpoint.Reset();
	if (const ADFPlayerCharacter* P = GetPlayer())
	{
		CapturePlayer(P);
		Health = FMath::Max(P->Health, 40.f);
	}
	Chapter = N;
	SaveRun();
	S->OnUiCommand.Broadcast(TEXT("fade"), { TEXT("true"), TEXT("1.5") });
	FTimerHandle Handle;
	GetTimerManager().SetTimer(Handle, FTimerDelegate::CreateUObject(this, &UDFGameInstance::StartChapter, N), 1.5f, false);
}

void UDFGameInstance::PlayEnding()
{
	UDFStorySubsystem* S = Story();
	const FString Id = EndingId();
	Profile->Endings.AddUnique(Id);
	Achieve(FName(*(TEXT("end_") + Id)));
	if (Profile->Endings.Num() >= 4)
	{
		Achieve(TEXT("all_endings"));
	}
	if (S->HasFlag(TEXT("ngp")))
	{
		Achieve(TEXT("second_signal"));
	}
	SnapshotMemory();
	OpenMap(TEXT("ending_") + Id, true);
}

FString UDFGameInstance::EndingId() const
{
	const UDFStorySubsystem* S = Story();
	const int32 Tapes = S->CountFlags(TEXT("tape_ev"));
	if (S->HasFlag(TEXT("final_open")))
	{
		return TEXT("B");
	}
	if (S->HasFlag(TEXT("final_send")) && S->HasFlag(TEXT("trust_mira")) && S->HasFlag(TEXT("hale_truth")) && Tapes >= 5 && S->HasFlag(TEXT("shutdown_key")))
	{
		return TEXT("D");
	}
	if (S->HasFlag(TEXT("final_silence")) && S->HasFlag(TEXT("shutdown_key")))
	{
		return TEXT("A");
	}
	return TEXT("C");
}

void UDFGameInstance::SnapshotMemory()
{
	const UDFStorySubsystem* S = Story();
	FDFRunMemory M;
	for (const TPair<FName, int32>& Flag : S->Flags)
	{
		if (Flag.Value > 0 && Flag.Key.ToString().StartsWith(TEXT("m_hide_")))
		{
			M.Hides.Add(Flag.Key, Flag.Value);
		}
	}
	M.Radio = S->GetFlag(TEXT("m_radio"));
	M.Hunts = S->GetFlag(TEXT("m_hunts"));
	M.Bottles = S->GetFlag(TEXT("m_bottles"));
	M.SprintEscapes = S->GetFlag(TEXT("m_sprint_esc"));
	M.Ending = EndingId();
	M.Runs = Profile->Memory.Runs + 1;
	Profile->Memory = M;
	Profile->bNewGamePlusUnlocked = true;
	SaveProfile();
}

void UDFGameInstance::UnlockChapter(int32 N)
{
	if (N > Profile->Unlocked && N <= LastChapter)
	{
		Profile->Unlocked = N;
		SaveProfile();
	}
}

void UDFGameInstance::Achieve(FName Id)
{
	if (Id.IsNone() || Profile->Achievements.Contains(Id))
	{
		return;
	}
	Profile->Achievements.Add(Id);
	SaveProfile();
	const FString* Title = AchievementTitles.Find(Id.ToString());
	Toast(TEXT("ACHIEVEMENT  ") + (Title ? *Title : Id.ToString()));
	// Steam achievements are mirrored here once the game has a Steam App ID (none is assumed).
}

void UDFGameInstance::OnPlayerDied()
{
	UDFStorySubsystem* S = Story();
	S->OnUiCommand.Broadcast(TEXT("cine"), { TEXT("false") });
	S->OnUiCommand.Broadcast(TEXT("fade"), { TEXT("true"), TEXT("0.8") });
	FTimerHandle Handle;
	GetTimerManager().SetTimer(Handle, FTimerDelegate::CreateUObject(this, &UDFGameInstance::ShowGameOver), 0.8f, false);
}

void UDFGameInstance::ShowGameOver()
{
	// the UI answers with ReloadCheckpoint() or ShowMenu()
	Story()->OnUiCommand.Broadcast(TEXT("gameover"), {});
}

// ------------------------------------------------------------------------------------------------ story events

void UDFGameInstance::HandleFlow(FName Event, const FString& Arg)
{
	// flow changes wait for the next tick, as the Godot game's call_deferred did: the running step finishes first
	FTimerManager& Timers = GetTimerManager();
	if (Event == TEXT("checkpoint"))
	{
		if (const ADFPlayerCharacter* P = GetPlayer())
		{
			Health = P->Health;
		}
		SaveRun();
	}
	else if (Event == TEXT("save")) SaveRun();
	else if (Event == TEXT("next")) Timers.SetTimerForNextTick(this, &UDFGameInstance::NextChapter);
	else if (Event == TEXT("ending")) Timers.SetTimerForNextTick(this, &UDFGameInstance::PlayEnding);
	else if (Event == TEXT("credits")) Timers.SetTimerForNextTick(this, &UDFGameInstance::PlayCredits);
	else if (Event == TEXT("menu")) Timers.SetTimerForNextTick(this, &UDFGameInstance::ShowMenu);
}

void UDFGameInstance::HandleAchievement(FName Id)
{
	Achieve(Id);
}

void UDFGameInstance::HandlePreLoadMap(const FString& MapName)
{
	if (UDFStorySubsystem* S = Story())
	{
		S->StopAll();                              // the old world's scripts cannot resume in the new one
		S->SetCommandHandler(nullptr);
	}
}

// ------------------------------------------------------------------------------------------------ saves

bool UDFGameInstance::SaveRun()
{
	if (Chapter == SliceChapter)
	{
		return false;
	}
	if (const ADFPlayerCharacter* P = GetPlayer())
	{
		CapturePlayer(P);
	}
	const UDFStorySubsystem* S = Story();
	UDFSaveGame* Save = NewObject<UDFSaveGame>(this);
	Save->RunId = RunId;
	Save->Chapter = Chapter;
	Save->Checkpoint = S->Checkpoint;
	Save->Flags = S->Flags;
	Save->Inventory = S->Inventory;
	Save->Journal = S->Journal;
	Save->Objective = S->Objective;
	Save->Health = Health;
	Save->TorchBattery = TorchBattery;
	Save->RadioBattery = RadioBattery;
	Save->bHasRadio = bHasRadio;
	Save->bHasTorch = bHasTorch;

	// keep the previous save as the backup, but only if it is itself sound
	UDFSaveGame* Previous = nullptr;
	if (ReadSave(SaveSlot(), Previous))
	{
		DFSave::Write(Previous, BackupSlot());
	}
	const bool bOk = DFSave::Write(Save, SaveSlot());
	UDFSaveGame* Check = nullptr;
	if (!bOk || !ReadSave(SaveSlot(), Check))
	{
		UE_LOG(LogDeadFrequency, Error, TEXT("Save: writing %s failed; the backup is kept"), *SaveSlot());
		return false;
	}
	return true;
}

bool UDFGameInstance::ReadSave(const FString& Slot, UDFSaveGame*& Out) const
{
	Out = Cast<UDFSaveGame>(DFSave::Read(Slot));
	return Out && Out->IsUsable(LastChapter);
}

bool UDFGameInstance::LoadRun()
{
	LoadError.Reset();
	UDFSaveGame* Save = nullptr;
	if (!ReadSave(SaveSlot(), Save))
	{
		if (!ReadSave(BackupSlot(), Save))
		{
			if (UGameplayStatics::DoesSaveGameExist(SaveSlot(), 0))
			{
				LoadError = TEXT("The save file is damaged and could not be loaded.");
			}
			return false;
		}
		LoadError = TEXT("The latest save was damaged. Loaded the previous checkpoint instead.");
	}
	UDFStorySubsystem* S = Story();
	S->ResetRun();
	S->Flags = Save->Flags;
	S->Inventory = Save->Inventory;
	S->Journal = Save->Journal;
	S->Checkpoint = Save->Checkpoint;
	S->Objective = Save->Objective;
	Chapter = Save->Chapter;
	Health = Save->Health;
	TorchBattery = Save->TorchBattery;
	RadioBattery = Save->RadioBattery;
	bHasRadio = Save->bHasRadio;
	bHasTorch = Save->bHasTorch;
	RunId = Save->RunId;
	return true;
}

bool UDFGameInstance::HasSave() const
{
	return UGameplayStatics::DoesSaveGameExist(SaveSlot(), 0) || UGameplayStatics::DoesSaveGameExist(BackupSlot(), 0);
}

void UDFGameInstance::LoadProfile()
{
	Profile = Cast<UDFProfileSave>(DFSave::Read(ProfileSlot()));
	if (!Profile)
	{
		Profile = NewObject<UDFProfileSave>(this);
	}
}

void UDFGameInstance::SaveProfile()
{
	if (Profile)
	{
		DFSave::Write(Profile, ProfileSlot());
	}
}
