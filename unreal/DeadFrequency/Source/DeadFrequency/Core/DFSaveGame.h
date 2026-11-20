#pragma once

#include "CoreMinimal.h"
#include "GameFramework/SaveGame.h"
#include "Story/DFStoryTypes.h"
#include "DFSaveGame.generated.h"

/**
 * One run in progress (the Godot game's save.json): written when a chapter starts, at checkpoints and at the
 * emergency log terminals. The vertical slice never writes it.
 */
UCLASS()
class DEADFREQUENCY_API UDFSaveGame : public USaveGame
{
	GENERATED_BODY()

public:
	static constexpr int32 CurrentVersion = 1;

	UPROPERTY() int32 Version = CurrentVersion;
	UPROPERTY() FString RunId;
	UPROPERTY() int32 Chapter = 1;
	/** Tag of the checkpoint's PlayerStart (the Godot marker symbol); empty = the chapter's start. */
	UPROPERTY() FString Checkpoint;
	UPROPERTY() TMap<FName, int32> Flags;
	UPROPERTY() TMap<FName, int32> Inventory;
	UPROPERTY() TArray<FDFJournalEntry> Journal;
	/** Not in the Godot save (it kept the objective only in memory): restores the HUD after a restart. */
	UPROPERTY() FString Objective;
	UPROPERTY() float Health = 100.f;
	UPROPERTY() float TorchBattery = 100.f;
	UPROPERTY() float RadioBattery = 100.f;
	UPROPERTY() bool bHasRadio = false;
	UPROPERTY() bool bHasTorch = true;

	/** The Godot _read_save rules: a known version and a chapter in range. */
	bool IsUsable(int32 LastChapter) const
	{
		return Version >= 1 && Version <= CurrentVersion && Chapter >= 0 && Chapter <= LastChapter;
	}
};

/** What the Listener keeps between runs for New Game+ ("Second Signal"): habits, not knowledge. */
USTRUCT(BlueprintType)
struct FDFRunMemory
{
	GENERATED_BODY()

	UPROPERTY(BlueprintReadOnly, Category = "Memory") int32 Radio = 0;
	UPROPERTY(BlueprintReadOnly, Category = "Memory") int32 Hunts = 0;
	/** m_hide_<id> -> times used. */
	UPROPERTY(BlueprintReadOnly, Category = "Memory") TMap<FName, int32> Hides;
	UPROPERTY(BlueprintReadOnly, Category = "Memory") int32 Bottles = 0;
	UPROPERTY(BlueprintReadOnly, Category = "Memory") int32 SprintEscapes = 0;
	/** A, B, C or D. */
	UPROPERTY(BlueprintReadOnly, Category = "Memory") FString Ending;
	UPROPERTY(BlueprintReadOnly, Category = "Memory") int32 Runs = 0;
};

/** The profile (the Godot game's profile.json minus the settings, which live in GameUserSettings.ini). */
UCLASS()
class DEADFREQUENCY_API UDFProfileSave : public USaveGame
{
	GENERATED_BODY()

public:
	UPROPERTY() int32 Version = 1;
	/** Highest chapter open in chapter select. */
	UPROPERTY(BlueprintReadOnly, Category = "Profile") int32 Unlocked = 1;
	UPROPERTY(BlueprintReadOnly, Category = "Profile") TArray<FString> Endings;
	UPROPERTY(BlueprintReadOnly, Category = "Profile") TArray<FName> Achievements;
	UPROPERTY(BlueprintReadOnly, Category = "Profile") bool bIntroSeen = false;
	UPROPERTY(BlueprintReadOnly, Category = "Profile") bool bNewGamePlusUnlocked = false;
	UPROPERTY(BlueprintReadOnly, Category = "Profile") FDFRunMemory Memory;
};
