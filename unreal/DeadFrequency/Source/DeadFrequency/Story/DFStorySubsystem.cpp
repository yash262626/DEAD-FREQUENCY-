#include "Story/DFStorySubsystem.h"

#include "DeadFrequency.h"
#include "Dom/JsonObject.h"
#include "Engine/GameInstance.h"
#include "JsonObjectConverter.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "Serialization/JsonReader.h"
#include "Serialization/JsonSerializer.h"
#include "TimerManager.h"

namespace DFStory
{
	const TCHAR* Dir = TEXT("Data/Story");

	/** Presentation commands and how long the story waits for them; the UI animates in parallel. */
	float UiDuration(FName Command, const FDFStoryStep& Step)
	{
		if (Command == TEXT("card")) return 5.8f;                  // fade in 1.2 + hold 3.2 + fade out 1.4 (Godot ui.chapter_card)
		if (Command == TEXT("fade")) return Step.ArgFloat(1, 1.0f);
		if (Command == TEXT("text")) return Step.ArgFloat(1, 3.0f);
		if (Command == TEXT("monitor")) return Step.ArgFloat(1, 2.5f);
		if (Command == TEXT("title")) return 12.0f;
		return 0.f;                                                 // toast, cine, ... do not hold the story
	}

	bool IsUiCommand(FName Command)
	{
		static const TSet<FName> Ui = { TEXT("card"), TEXT("fade"), TEXT("text"), TEXT("monitor"), TEXT("title"), TEXT("toast"), TEXT("cine") };
		return Ui.Contains(Command);
	}

	bool IsFlowCommand(FName Command)
	{
		static const TSet<FName> Flow = { TEXT("save"), TEXT("next"), TEXT("ending"), TEXT("credits"), TEXT("menu") };
		return Flow.Contains(Command);
	}

	int32 FlagValue(const FString& Arg)
	{
		if (Arg.IsEmpty() || Arg.Equals(TEXT("true"), ESearchCase::IgnoreCase)) return 1;
		if (Arg.Equals(TEXT("false"), ESearchCase::IgnoreCase)) return 0;
		return FCString::Atoi(*Arg);
	}
}

// ------------------------------------------------------------------------------------------------ runner

void UDFSequenceRunner::Start(UDFStorySubsystem* InStory, const FString& InChapter, int32 Sequence, FName InId)
{
	Story = InStory;
	ChapterKey = InChapter;
	Id = InId;
	Push(Sequence);
	Advance();
}

void UDFSequenceRunner::Push(int32 Sequence)
{
	if (Sequence != INDEX_NONE)
	{
		Stack.Add({ Sequence, 0 });
	}
}

void UDFSequenceRunner::Resume()
{
	if (bFinished)
	{
		return;
	}
	if (bAdvancing)
	{
		bResumeRequested = true;            // a handler finished synchronously: keep going in the running loop
		return;
	}
	Advance();
}

void UDFSequenceRunner::Choose(int32 Option)
{
	if (bFinished || PendingOptions.Num() == 0)
	{
		return;
	}
	const int32 Pick = FMath::Clamp(Option, 0, PendingOptions.Num() - 1);
	const int32 Next = PendingOptions[Pick].Sequence;
	PendingOptions.Reset();
	Push(Next);
	Resume();
}

void UDFSequenceRunner::AwaitChoice(const TArray<FDFChoiceOption>& Options)
{
	PendingOptions = Options;
}

void UDFSequenceRunner::Advance()
{
	UDFStorySubsystem* S = Story.Get();
	bWaiting = false;
	bAdvancing = true;
	int32 Guard = 0;
	while (S && Stack.Num() > 0 && !bWaiting)
	{
		if (++Guard > 100000)
		{
			UE_LOG(LogDeadFrequency, Error, TEXT("Story: runaway sequence in %s"), *ChapterKey);
			break;
		}
		FFrame& Top = Stack.Last();
		const FDFStorySequence* Seq = S->GetSequence(ChapterKey, Top.Sequence);
		if (!Seq || !Seq->Steps.IsValidIndex(Top.Step))
		{
			Stack.Pop();
			continue;
		}
		const FDFStoryStep Step = Seq->Steps[Top.Step];   // copy: the step may push frames and invalidate Top
		++Top.Step;
		bWaiting = S->ExecuteStep(this, Step);
		if (bWaiting && bResumeRequested)
		{
			bWaiting = false;
		}
		bResumeRequested = false;
	}
	bAdvancing = false;
	if (Stack.Num() == 0 && !bWaiting)
	{
		Finish();
	}
}

void UDFSequenceRunner::Cancel()
{
	Stack.Reset();
	PendingOptions.Reset();
	bWaiting = false;
	bResumeRequested = false;
	bFinished = true;
}

void UDFSequenceRunner::Finish()
{
	if (bFinished)
	{
		return;
	}
	bFinished = true;
	OnFinished.ExecuteIfBound();
}

// ------------------------------------------------------------------------------------------------ subsystem

void UDFStorySubsystem::Initialize(FSubsystemCollectionBase& Collection)
{
	Super::Initialize(Collection);

	FString IndexJson;
	if (!LoadJson(TEXT("index.json"), IndexJson))
	{
		UE_LOG(LogDeadFrequency, Error, TEXT("Story: %s/index.json not found"), DFStory::Dir);
		return;
	}
	TSharedPtr<FJsonObject> Index;
	const TSharedRef<TJsonReader<>> Reader = TJsonReaderFactory<>::Create(IndexJson);
	if (!FJsonSerializer::Deserialize(Reader, Index) || !Index.IsValid())
	{
		UE_LOG(LogDeadFrequency, Error, TEXT("Story: index.json is not valid JSON"));
		return;
	}

	TArray<FString> Files;
	for (const TSharedPtr<FJsonValue>& Entry : Index->GetArrayField(TEXT("chapters")))
	{
		Files.Add(Entry->AsObject()->GetStringField(TEXT("file")));
	}
	Files.Add(TEXT("slice.json"));

	for (const FString& File : Files)
	{
		FString Json;
		if (!LoadJson(File, Json))
		{
			UE_LOG(LogDeadFrequency, Warning, TEXT("Story: %s missing"), *File);
			continue;
		}
		FDFChapterData Data;
		if (!FJsonObjectConverter::JsonObjectStringToUStruct(Json, &Data, 0, 0))
		{
			UE_LOG(LogDeadFrequency, Error, TEXT("Story: %s could not be read"), *File);
			continue;
		}
		// The first-entry program, exactly as the Godot game composed it in main.gd start_chapter():
		// cinematic lock, pre-script, chapter card, fade in over 2 s, start script, release the player.
		FDFStorySequence Intro;
		auto Add = [&Intro](const TCHAR* Command, TArray<FString> Args)
		{
			FDFStoryStep Step;
			Step.Command = FName(Command);
			Step.Args = MoveTemp(Args);
			Intro.Steps.Add(MoveTemp(Step));
		};
		Add(TEXT("cine"), { TEXT("true") });
		if (Data.PreSequence != INDEX_NONE) Add(TEXT("run"), { FString::FromInt(Data.PreSequence) });
		Add(TEXT("card"), {});
		Add(TEXT("fade"), { TEXT("false"), TEXT("2.0") });
		if (Data.StartSequence != INDEX_NONE) Add(TEXT("run"), { FString::FromInt(Data.StartSequence) });
		Add(TEXT("cine"), { TEXT("false") });

		const FString Key = FPaths::GetBaseFilename(File);
		IntroSequence.Add(Key, Data.Sequences.Add(MoveTemp(Intro)));
		Chapters.Add(Key, MoveTemp(Data));
	}

	FString MimicJson;
	if (LoadJson(TEXT("listener_mimicry.json"), MimicJson))
	{
		FJsonObjectConverter::JsonObjectStringToUStruct(MimicJson, &Mimicry, 0, 0);
	}
	UE_LOG(LogDeadFrequency, Log, TEXT("Story: %d scripts, %d mimicry lines"), Chapters.Num(), Mimicry.Lines.Num() + Mimicry.NewGamePlus.Num());
}

bool UDFStorySubsystem::LoadStoryFile(const FString& File, FString& Out)
{
	return FFileHelper::LoadFileToString(Out, *(FPaths::ProjectContentDir() / DFStory::Dir / File));
}

const FDFStorySequence* UDFStorySubsystem::GetSequence(const FString& Key, int32 Index) const
{
	const FDFChapterData* Chapter = Chapters.Find(Key);
	return Chapter && Chapter->Sequences.IsValidIndex(Index) ? &Chapter->Sequences[Index] : nullptr;
}

UDFSequenceRunner* UDFStorySubsystem::BeginChapter(const FString& Key, bool bFirstEntry)
{
	const FDFChapterData* Chapter = GetChapter(Key);
	if (!Chapter)
	{
		UE_LOG(LogDeadFrequency, Error, TEXT("Story: no chapter %s"), *Key);
		return nullptr;
	}
	CurrentChapter = Key;
	if (bFirstEntry)
	{
		return RunSequence(Key, IntroSequence.FindRef(Key), TEXT("intro"));
	}
	if (!Objective.IsEmpty())
	{
		OnObjective.Broadcast(Objective);
	}
	OnUiCommand.Broadcast(TEXT("fade"), { TEXT("false"), TEXT("1.2") });
	return RunSequence(Key, Chapter->ResumeSequence, TEXT("resume"));
}

UDFSequenceRunner* UDFStorySubsystem::RunSequence(const FString& Key, int32 Sequence, FName Id)
{
	if (!GetSequence(Key, Sequence))
	{
		return nullptr;
	}
	UDFSequenceRunner* Runner = NewObject<UDFSequenceRunner>(this);
	Running.Add(Runner);
	TWeakObjectPtr<UDFStorySubsystem> WeakThis(this);
	TWeakObjectPtr<UDFSequenceRunner> WeakRunner(Runner);
	Runner->OnFinished.BindLambda([WeakThis, WeakRunner]()
	{
		if (WeakThis.IsValid())
		{
			WeakThis->Running.Remove(WeakRunner.Get());
		}
	});
	Runner->Start(this, Key, Sequence, Id);
	return Runner;
}

UDFSequenceRunner* UDFStorySubsystem::RunLegendEntry(const FString& Key, const FString& Symbol)
{
	const FDFChapterData* Chapter = GetChapter(Key);
	const FDFLegendEntry* Entry = Chapter ? Chapter->FindLegend(Symbol) : nullptr;
	if (!Entry)
	{
		return nullptr;
	}
	// spoken lines first, then the entry's script: push the script, then start with the lines on top
	if (Entry->Lines == INDEX_NONE)
	{
		return RunSequence(Key, Entry->Sequence, FName(*Symbol));
	}
	UDFSequenceRunner* Runner = NewObject<UDFSequenceRunner>(this);
	Running.Add(Runner);
	TWeakObjectPtr<UDFStorySubsystem> WeakThis(this);
	TWeakObjectPtr<UDFSequenceRunner> WeakRunner(Runner);
	Runner->OnFinished.BindLambda([WeakThis, WeakRunner]()
	{
		if (WeakThis.IsValid())
		{
			WeakThis->Running.Remove(WeakRunner.Get());
		}
	});
	Runner->Push(Entry->Sequence);
	Runner->Start(this, Key, Entry->Lines, FName(*Symbol));
	return Runner;
}

void UDFStorySubsystem::StopAll()
{
	FTimerManager& Timers = GetGameInstance()->GetTimerManager();
	for (UDFSequenceRunner* Runner : Running)
	{
		if (Runner)
		{
			Timers.ClearTimer(Runner->WaitTimer);
			Runner->Cancel();
		}
	}
	Running.Reset();
	Timers.ClearTimer(LineTimer);
	LineQueue.Reset();
	bLineActive = false;
}

void UDFStorySubsystem::ResetRun()
{
	StopAll();
	Flags.Reset();
	Inventory.Reset();
	Journal.Reset();
	Objective.Reset();
	Checkpoint.Reset();
	CurrentChapter.Reset();
}

int32 UDFStorySubsystem::CountFlags(const FString& Prefix) const
{
	int32 N = 0;
	for (const TPair<FName, int32>& Flag : Flags)
	{
		if (Flag.Value != 0 && Flag.Key.ToString().StartsWith(Prefix))
		{
			++N;
		}
	}
	return N;
}

bool UDFStorySubsystem::IsBusy() const
{
	return Running.Num() > 0;
}

void UDFStorySubsystem::SetCommandHandler(UObject* Handler)
{
	CommandHandler = Handler;
}

void UDFStorySubsystem::SetFlag(FName Flag, int32 Value)
{
	Flags.Add(Flag, Value);
}

int32 UDFStorySubsystem::GetFlag(FName Flag) const
{
	const int32* Value = Flags.Find(Flag);
	return Value ? *Value : 0;
}

bool UDFStorySubsystem::EvalCondition(const FString& Condition) const
{
	FString Name = Condition.TrimStartAndEnd();
	const bool bNot = Name.RemoveFromStart(TEXT("!"));
	const bool bSet = HasFlag(FName(*Name));
	return bNot ? !bSet : bSet;
}

void UDFStorySubsystem::Give(FName Item, int32 Num)
{
	Inventory.FindOrAdd(Item) += Num;
}

bool UDFStorySubsystem::Take(FName Item)
{
	int32* Have = Inventory.Find(Item);
	if (!Have || *Have <= 0)
	{
		return false;
	}
	if (--(*Have) == 0)
	{
		Inventory.Remove(Item);
	}
	return true;
}

int32 UDFStorySubsystem::Count(FName Item) const
{
	const int32* Have = Inventory.Find(Item);
	return Have ? *Have : 0;
}

float UDFStorySubsystem::ReadingTime(const FString& Text)
{
	return FMath::Clamp(1.4f + Text.Len() * 0.058f, 2.0f, 9.0f);   // Godot ui.say()
}

void UDFStorySubsystem::Wait(UDFSequenceRunner* Runner, float Seconds)
{
	const float Delay = bSkip ? 0.001f : FMath::Max(Seconds, 0.001f);
	GetGameInstance()->GetTimerManager().SetTimer(Runner->WaitTimer, FTimerDelegate::CreateUObject(Runner, &UDFSequenceRunner::Resume), Delay, false);
}

void UDFStorySubsystem::QueueLine(UDFSequenceRunner* Runner, const FDFStoryStep& Step)
{
	// one voice at a time: lines from parallel scripts wait their turn, as in the Godot game
	FPendingLine Line;
	Line.Runner = Runner;
	Line.Speaker = Step.Arg(0);
	Line.Text = Step.Arg(1);
	Line.Vo = Step.Vo;
	Line.Seconds = Step.ArgFloat(2, ReadingTime(Line.Text));
	Enqueue(MoveTemp(Line));
}

void UDFStorySubsystem::Say(const FString& Speaker, const FString& Text, const FString& Vo, float Seconds)
{
	FPendingLine Line;
	Line.Speaker = Speaker;
	Line.Text = Text;
	Line.Vo = Vo;
	Line.Seconds = Seconds > 0.f ? Seconds : ReadingTime(Text);
	Enqueue(MoveTemp(Line));
}

void UDFStorySubsystem::Enqueue(FPendingLine&& Line)
{
	LineQueue.Add(MoveTemp(Line));
	if (!bLineActive)
	{
		NextLine();
	}
}

void UDFStorySubsystem::NextLine()
{
	if (LineQueue.Num() == 0)
	{
		bLineActive = false;
		return;
	}
	bLineActive = true;
	const FPendingLine Line = LineQueue[0];
	LineQueue.RemoveAt(0);
	OnLine.Broadcast(Line.Speaker, Line.Text, Line.Vo, Line.Seconds);
	TWeakObjectPtr<UDFStorySubsystem> WeakThis(this);
	const TWeakObjectPtr<UDFSequenceRunner> WeakRunner = Line.Runner;
	GetGameInstance()->GetTimerManager().SetTimer(LineTimer, FTimerDelegate::CreateLambda([WeakThis, WeakRunner]()
	{
		if (WeakRunner.IsValid())
		{
			WeakRunner->Resume();
		}
		if (WeakThis.IsValid())
		{
			WeakThis->NextLine();
		}
	}), bSkip ? 0.001f : FMath::Max(Line.Seconds, 0.001f), false);
}

bool UDFStorySubsystem::ExecuteStep(UDFSequenceRunner* Runner, const FDFStoryStep& Step)
{
	const FName C = Step.Command;

	if (C == TEXT("line"))
	{
		QueueLine(Runner, Step);
		return true;
	}
	if (C == TEXT("wait"))
	{
		Wait(Runner, Step.ArgFloat(0, 1.0f));
		return true;
	}
	if (C == TEXT("run"))
	{
		Runner->Push(FCString::Atoi(*Step.Arg(0)));
		return false;
	}
	if (C == TEXT("if") || C == TEXT("ifnot"))
	{
		const bool bSet = HasFlag(FName(*Step.Arg(0)));
		const int32 Next = (C == TEXT("if")) == bSet ? Step.Then : Step.Else;
		Runner->Push(Next);
		return false;
	}
	if (C == TEXT("group"))
	{
		const FDFChapterData* Chapter = GetChapter(Runner->GetChapterKey());
		if (const int32* Group = Chapter ? Chapter->Groups.Find(Step.Arg(0)) : nullptr)
		{
			Runner->Push(*Group);
		}
		return false;
	}
	if (C == TEXT("choice"))
	{
		if (Step.Options.Num() == 0)
		{
			return false;
		}
		if (bSkip || !OnChoice.IsBound())
		{
			Runner->Push(Step.Options[0].Sequence);   // automated runs take the first option unless a test says otherwise
			return false;
		}
		TArray<FString> Labels;
		for (const FDFChoiceOption& Option : Step.Options)
		{
			Labels.Add(Option.Label);
		}
		Runner->AwaitChoice(Step.Options);
		OnChoice.Broadcast(Runner, Step.Arg(0), Labels);
		return true;
	}
	if (C == TEXT("flag"))
	{
		SetFlag(FName(*Step.Arg(0)), DFStory::FlagValue(Step.Arg(1)));
		return false;
	}
	if (C == TEXT("obj"))
	{
		Objective = Step.Arg(0);
		OnObjective.Broadcast(Objective);
		return false;
	}
	if (C == TEXT("give"))
	{
		Give(FName(*Step.Arg(0)), Step.Args.Num() > 1 ? FCString::Atoi(*Step.Arg(1)) : 1);
		return false;
	}
	if (C == TEXT("take"))
	{
		Take(FName(*Step.Arg(0)));
		return false;
	}
	if (C == TEXT("ach"))
	{
		OnAchievement.Broadcast(FName(*Step.Arg(0)));
		return false;
	}
	if (C == TEXT("journal"))
	{
		FDFJournalEntry Entry;
		Entry.Title = Step.Arg(0);
		Entry.Text = Step.Arg(1);
		Entry.Kind = TEXT("note");
		Journal.Add(Entry);
		OnJournal.Broadcast(Entry);
		return false;
	}
	if (C == TEXT("checkpoint"))
	{
		Checkpoint = Step.Arg(0);
		OnFlow.Broadcast(C, Checkpoint);
		return false;
	}
	if (DFStory::IsFlowCommand(C))
	{
		OnFlow.Broadcast(C, Step.Arg(0));
		return false;
	}
	if (DFStory::IsUiCommand(C))
	{
		OnUiCommand.Broadcast(C, Step.Args);
		const float Hold = DFStory::UiDuration(C, Step);
		if (Hold > 0.f)
		{
			Wait(Runner, Hold);
			return true;
		}
		return false;
	}
	// lights, art, listener, tp, look, cam, camoff, sfx, music, loop, unloop, loop3d, unloop3d, shake, hurt, lock,
	// unlock, close, hide_ent, show_ent, reveal, radio_on, noise_mult, pulse, move, ext: the level's director
	if (IDFStoryCommandHandler* Handler = Cast<IDFStoryCommandHandler>(CommandHandler.Get()))
	{
		return Handler->HandleStoryCommand(Runner, Step);
	}
	UE_LOG(LogDeadFrequency, Warning, TEXT("Story: no handler for '%s' in %s"), *C.ToString(), *Runner->GetChapterKey());
	return false;
}
