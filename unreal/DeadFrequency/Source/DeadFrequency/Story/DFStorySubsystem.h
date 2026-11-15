#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "TimerManager.h"
#include "UObject/Interface.h"
#include "Story/DFStoryTypes.h"
#include "DFStorySubsystem.generated.h"

class UDFStorySubsystem;
class UDFSequenceRunner;

/**
 * Implemented by whoever owns the world side of a chapter (the level's director actor): lights, the Listener,
 * teleports, cameras, sounds, doors... Return true when the command is latent; the handler then calls
 * Runner->Resume() when it is done.
 */
UINTERFACE(MinimalAPI, meta = (CannotImplementInterfaceInBlueprint))
class UDFStoryCommandHandler : public UInterface
{
	GENERATED_BODY()
};

class DEADFREQUENCY_API IDFStoryCommandHandler
{
	GENERATED_BODY()

public:
	virtual bool HandleStoryCommand(UDFSequenceRunner* Runner, const FDFStoryStep& Step) = 0;
};

/** Executes one sequence (and the blocks it pushes) step by step; latent steps pause it until Resume(). */
UCLASS()
class DEADFREQUENCY_API UDFSequenceRunner : public UObject
{
	GENERATED_BODY()

public:
	void Start(UDFStorySubsystem* InStory, const FString& InChapter, int32 Sequence, FName InId);

	/** Continue after a latent step (a line, a wait, a fade, a camera move...). */
	UFUNCTION(BlueprintCallable, Category = "Story")
	void Resume();

	/** Answer a pending "choice". */
	UFUNCTION(BlueprintCallable, Category = "Story")
	void Choose(int32 Option);

	/** Run a nested block before the rest of the current one. */
	void Push(int32 Sequence);

	/** A "choice" is waiting for Choose(). */
	void AwaitChoice(const TArray<FDFChoiceOption>& Options);

	bool IsFinished() const { return bFinished; }
	const FString& GetChapterKey() const { return ChapterKey; }
	FName GetId() const { return Id; }

	FTimerHandle WaitTimer;
	FSimpleDelegate OnFinished;

private:
	struct FFrame
	{
		int32 Sequence = INDEX_NONE;
		int32 Step = 0;
	};

	void Advance();
	void Finish();

	TWeakObjectPtr<UDFStorySubsystem> Story;
	FString ChapterKey;
	FName Id;
	TArray<FFrame> Stack;
	TArray<FDFChoiceOption> PendingOptions;
	bool bWaiting = false;
	bool bAdvancing = false;
	bool bResumeRequested = false;
	bool bFinished = false;
};

DECLARE_DYNAMIC_MULTICAST_DELEGATE_FourParams(FDFOnLine, const FString&, Speaker, const FString&, Text, const FString&, VoId, float, Seconds);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_ThreeParams(FDFOnChoice, UDFSequenceRunner*, Runner, const FString&, Prompt, const TArray<FString>&, Labels);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FDFOnObjective, const FString&, Objective);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FDFOnUiCommand, FName, Command, const TArray<FString>&, Args);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FDFOnAchievement, FName, Achievement);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FDFOnJournal, const FDFJournalEntry&, Entry);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FDFOnFlow, FName, Event, const FString&, Arg);

/**
 * The story runtime: loads the converted story data, owns the run's flags, inventory, objective and journal, and
 * runs the event sequences of the Godot game command for command. World-side commands go to the registered
 * IDFStoryCommandHandler; presentation commands are broadcast to the UI with fixed durations, so a missing
 * widget can never stall the story.
 */
UCLASS()
class DEADFREQUENCY_API UDFStorySubsystem : public UGameInstanceSubsystem
{
	GENERATED_BODY()

public:
	virtual void Initialize(FSubsystemCollectionBase& Collection) override;

	/** chapter_00 .. chapter_13, ending_A .. ending_D, slice. */
	const FDFChapterData* GetChapter(const FString& Key) const { return Chapters.Find(Key); }
	const FDFStorySequence* GetSequence(const FString& Key, int32 Index) const;
	const FDFMimicData& GetMimicry() const { return Mimicry; }
	int32 NumChapters() const { return Chapters.Num(); }

	/** First entry: cinematic lock, pre-script, chapter card, fade in, start script. Re-entry: the resume script. */
	UDFSequenceRunner* BeginChapter(const FString& Key, bool bFirstEntry);
	UDFSequenceRunner* RunSequence(const FString& Key, int32 Sequence, FName Id = NAME_None);
	/** A transmitter, tape or note: its spoken lines first, then its script (as the Godot radio did). */
	UDFSequenceRunner* RunLegendEntry(const FString& Key, const FString& Symbol);

	/** True while any sequence runs (the radio does not lock onto a new transmission meanwhile). */
	bool IsBusy() const;

	void SetCommandHandler(UObject* Handler);

	// --- run state (saved with the run) ---
	UFUNCTION(BlueprintCallable, Category = "Story") void SetFlag(FName Flag, int32 Value = 1);
	UFUNCTION(BlueprintPure, Category = "Story") int32 GetFlag(FName Flag) const;
	UFUNCTION(BlueprintPure, Category = "Story") bool HasFlag(FName Flag) const { return GetFlag(Flag) != 0; }
	/** Godot condition strings: a flag name, optionally negated with "!". */
	bool EvalCondition(const FString& Condition) const;

	UFUNCTION(BlueprintCallable, Category = "Story") void Give(FName Item, int32 Count = 1);
	UFUNCTION(BlueprintCallable, Category = "Story") bool Take(FName Item);
	UFUNCTION(BlueprintPure, Category = "Story") int32 Count(FName Item) const;

	UPROPERTY(BlueprintReadOnly, Category = "Story") TMap<FName, int32> Flags;
	UPROPERTY(BlueprintReadOnly, Category = "Story") TMap<FName, int32> Inventory;
	UPROPERTY(BlueprintReadOnly, Category = "Story") TArray<FDFJournalEntry> Journal;
	UPROPERTY(BlueprintReadOnly, Category = "Story") FString Objective;
	UPROPERTY(BlueprintReadOnly, Category = "Story") FString Checkpoint;
	UPROPERTY(BlueprintReadOnly, Category = "Story") FString CurrentChapter;

	/** Automated tests and skipping: every timed step finishes on the next tick. */
	UPROPERTY(BlueprintReadWrite, Category = "Story") bool bSkip = false;

	UPROPERTY(BlueprintAssignable) FDFOnLine OnLine;
	UPROPERTY(BlueprintAssignable) FDFOnChoice OnChoice;
	UPROPERTY(BlueprintAssignable) FDFOnObjective OnObjective;
	UPROPERTY(BlueprintAssignable) FDFOnUiCommand OnUiCommand;
	UPROPERTY(BlueprintAssignable) FDFOnAchievement OnAchievement;
	UPROPERTY(BlueprintAssignable) FDFOnJournal OnJournal;
	/** checkpoint, save, next, ending, credits, menu */
	UPROPERTY(BlueprintAssignable) FDFOnFlow OnFlow;

	/** Executes one step; returns true when the runner must wait for Resume()/Choose(). */
	bool ExecuteStep(UDFSequenceRunner* Runner, const FDFStoryStep& Step);

private:
	struct FPendingLine
	{
		TWeakObjectPtr<UDFSequenceRunner> Runner;
		FString Speaker;
		FString Text;
		FString Vo;
		float Seconds = 0.f;
	};

	bool LoadJson(const FString& File, FString& Out) const;
	void Wait(UDFSequenceRunner* Runner, float Seconds);
	void QueueLine(UDFSequenceRunner* Runner, const FDFStoryStep& Step);
	void NextLine();
	static float ReadingTime(const FString& Text);

	TArray<FPendingLine> LineQueue;
	bool bLineActive = false;
	FTimerHandle LineTimer;

	UPROPERTY() TMap<FString, FDFChapterData> Chapters;
	UPROPERTY() FDFMimicData Mimicry;
	UPROPERTY() TArray<TObjectPtr<UDFSequenceRunner>> Running;
	UPROPERTY() TWeakObjectPtr<UObject> CommandHandler;
	/** Synthesised per chapter at load: the first-entry program (cine on, pre, card, fade in, start, cine off). */
	TMap<FString, int32> IntroSequence;
};
