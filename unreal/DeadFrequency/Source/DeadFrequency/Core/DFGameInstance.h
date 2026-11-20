#pragma once

#include "CoreMinimal.h"
#include "Engine/GameInstance.h"
#include "DFGameInstance.generated.h"

class ADFPlayerCharacter;
class UDFProfileSave;
class UDFSaveGame;
class UDFStorySubsystem;

/**
 * The run and the profile, ported from the Godot game's g.gd and main.gd: new game, continue, chapter select,
 * New Game+ ("Second Signal") and the vertical slice; chapter changes, endings and credits; saves with a backup slot
 * and an integrity check, so a damaged save falls back to the previous one; achievements; the Listener's memory
 * between runs. Maps are opened by story key: <MapRoot>L_chapter_03, L_ending_B, L_slice, L_menu, L_credits.
 */
UCLASS(Config = Game)
class DEADFREQUENCY_API UDFGameInstance : public UGameInstance
{
	GENERATED_BODY()

public:
	static constexpr int32 LastChapter = 13;
	/** The Godot Story.SLICE_N. */
	static constexpr int32 SliceChapter = 99;

	virtual void Init() override;
	virtual void Shutdown() override;

	// --- main menu ---
	UFUNCTION(BlueprintCallable, Category = "Run") void NewGame();
	/** False, with LoadError set when there is a reason, if there is nothing valid to continue. */
	UFUNCTION(BlueprintCallable, Category = "Run") bool ContinueGame();
	UFUNCTION(BlueprintCallable, Category = "Run") void NewGamePlus();
	UFUNCTION(BlueprintCallable, Category = "Run") void SelectChapter(int32 InChapter);
	UFUNCTION(BlueprintCallable, Category = "Run") void StartSlice();
	/** The game-over screen's "Return to checkpoint" (the slice restarts from its beginning). */
	UFUNCTION(BlueprintCallable, Category = "Run") void ReloadCheckpoint();
	UFUNCTION(BlueprintCallable, Category = "Run") void ShowMenu();
	UFUNCTION(BlueprintCallable, Category = "Run") void PlayCredits();

	UFUNCTION(BlueprintPure, Category = "Run") bool HasSave() const;
	UFUNCTION(BlueprintPure, Category = "Run") int32 GetChapter() const { return Chapter; }
	/** chapter_03, ending_B, slice; empty on the menu and credits maps. */
	UFUNCTION(BlueprintPure, Category = "Run") FString GetStoryKey() const { return StoryKey; }
	UFUNCTION(BlueprintPure, Category = "Profile") UDFProfileSave* GetProfile() const { return Profile; }
	/** The Godot ending_id(): decided by what the player learned and chose (docs/02_STORY_BIBLE.md). */
	UFUNCTION(BlueprintPure, Category = "Run") FString EndingId() const;

	UFUNCTION(BlueprintCallable, Category = "Run") bool SaveRun();
	UFUNCTION(BlueprintCallable, Category = "Profile") void Achieve(FName Id);

	/** The last load problem, for the menu toast. */
	UPROPERTY(BlueprintReadOnly, Category = "Run") FString LoadError;

	/** Automated tests use their own save slots and never touch the player's. */
	UPROPERTY(BlueprintReadWrite, Category = "Run") bool bTestMode = false;

	/** Content folder of the maps. */
	UPROPERTY(Config) FString MapRoot = TEXT("/Game/DeadFrequency/Maps/");

	// --- called by ADFGameMode ---
	/** The map has loaded and the player exists: play the chapter's first entry or its resume script. */
	void BeginStoryInWorld(ADFPlayerCharacter* Player, const FString& MapName);
	void ApplyRunToPlayer(ADFPlayerCharacter* Player) const;
	void CapturePlayer(const ADFPlayerCharacter* Player);
	void OnPlayerDied();

private:
	UDFStorySubsystem* Story() const;
	ADFPlayerCharacter* GetPlayer() const;
	void NewRun(int32 InChapter);
	void NewRunPlus();
	void StartChapter(int32 N);
	void NextChapter();
	void PlayEnding();
	void SnapshotMemory();
	void UnlockChapter(int32 N);
	void OpenMap(const FString& Key, bool bStory);
	void ShowGameOver();
	void Toast(const FString& Text) const;

	bool LoadRun();
	bool ReadSave(const FString& Slot, UDFSaveGame*& Out) const;
	void LoadProfile();
	void SaveProfile();
	FString SaveSlot() const { return bTestMode ? TEXT("test_save") : TEXT("save"); }
	FString BackupSlot() const { return SaveSlot() + TEXT("_bak"); }
	FString ProfileSlot() const { return bTestMode ? TEXT("test_profile") : TEXT("profile"); }

	UFUNCTION() void HandleFlow(FName Event, const FString& Arg);
	UFUNCTION() void HandleAchievement(FName Id);
	void HandlePreLoadMap(const FString& MapName);

	UPROPERTY() TObjectPtr<UDFProfileSave> Profile;
	TMap<FString, FString> AchievementTitles;
	FString StoryKey;
	FString RunId;
	FString PendingToast;
	int32 Chapter = 1;
	float Health = 100.f;
	float TorchBattery = 100.f;
	float RadioBattery = 100.f;
	bool bHasRadio = false;
	bool bHasTorch = true;
};
