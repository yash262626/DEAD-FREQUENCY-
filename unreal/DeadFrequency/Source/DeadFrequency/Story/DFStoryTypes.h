#pragma once

#include "CoreMinimal.h"
#include "DFStoryTypes.generated.h"

// Story data as converted from the Godot game by tools/ue/godot_to_ue.py (Content/Data/Story/*.json).
// Field names match the JSON keys; FJsonObjectConverter matches them case-insensitively.
// Nested blocks (if / ifnot / choice / group) live in their own sequence and are referenced by index,
// so no struct contains itself.

/** One option of a "choice" step: the label the player sees and the sequence it runs. */
USTRUCT(BlueprintType)
struct DEADFREQUENCY_API FDFChoiceOption
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	FString Label;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	int32 Sequence = INDEX_NONE;
};

/** One step of a story sequence: a command and its arguments, all stored as strings. */
USTRUCT(BlueprintType)
struct DEADFREQUENCY_API FDFStoryStep
{
	GENERATED_BODY()

	/** "line" for spoken lines; otherwise one of the Godot event commands (wait, obj, flag, if, choice, listener, ...). */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	FName Command;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	TArray<FString> Args;

	/** Voice-over id of a "line" (same id as docs/vo/vo_script.csv and the Godot game). */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	FString Vo;

	/** "if"/"ifnot": the sequence to run when the condition holds, and (if) the one to run otherwise. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	int32 Then = INDEX_NONE;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	int32 Else = INDEX_NONE;

	/** "choice": the options. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	TArray<FDFChoiceOption> Options;

	FString Arg(int32 Index, const FString& Default = FString()) const
	{
		return Args.IsValidIndex(Index) ? Args[Index] : Default;
	}

	float ArgFloat(int32 Index, float Default) const
	{
		return Args.IsValidIndex(Index) && Args[Index].IsNumeric() ? FCString::Atof(*Args[Index]) : Default;
	}

	bool ArgBool(int32 Index, bool Default) const
	{
		if (!Args.IsValidIndex(Index)) return Default;
		return Args[Index].Equals(TEXT("true"), ESearchCase::IgnoreCase) || Args[Index] == TEXT("1");
	}
};

USTRUCT(BlueprintType)
struct DEADFREQUENCY_API FDFStorySequence
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	TArray<FDFStoryStep> Steps;
};

/** An interactive thing of a chapter (transmitter, note, tape, door, device, hiding place, marker, ...). */
USTRUCT(BlueprintType)
struct DEADFREQUENCY_API FDFLegendEntry
{
	GENERATED_BODY()

	/** The character that marks it on the original 2 m grid; placed actors refer to it. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	FString Symbol;

	/** radio, tape, note, item, use, door, hide, ghost, trig, mark, prop, light, npc, plate, pcrate, ... */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	FName Kind;

	/** Every other property of the Godot legend entry (f, r, flag, title, prompt, code, ...), as strings. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	TMap<FString, FString> Props;

	/** Script run when it is used or triggered, and the spoken lines of tapes and transmissions. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	int32 Sequence = INDEX_NONE;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	int32 Lines = INDEX_NONE;

	FString Prop(const FString& Key, const FString& Default = FString()) const
	{
		const FString* Value = Props.Find(Key);
		return Value ? *Value : Default;
	}
};

USTRUCT(BlueprintType)
struct DEADFREQUENCY_API FDFPlacement
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	FString Symbol;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	FIntPoint Cell = FIntPoint::ZeroValue;
};

/** One chapter, ending or the vertical slice. */
USTRUCT(BlueprintType)
struct DEADFREQUENCY_API FDFChapterData
{
	GENERATED_BODY()

	/** 0 = prologue, 1-13 chapters, 99 = vertical slice, -1 for endings. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	int32 Number = INDEX_NONE;

	/** "A".."D" for endings. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	FString Ending;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	FString Title;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	FString Subtitle;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	int32 PreSequence = INDEX_NONE;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	int32 StartSequence = INDEX_NONE;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	int32 ResumeSequence = INDEX_NONE;

	/** Puzzle groups: name -> sequence run when the group is solved (the "group" command). */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	TMap<FString, int32> Groups;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	TArray<FDFLegendEntry> Legend;

	/** The original Godot grid (rows of characters, 2 m cells): greybox reference and reachability checks. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	TArray<FString> Map;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	float CellSize = 200.f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	TArray<FDFPlacement> Placements;

	/** Level properties: palette, music, ambience, dark, cloaked, exterior, AI spawn rules, ... */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	TMap<FString, FString> Props;

	/** The QA critical path (JSON strings), driven by the automated playthrough. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	TArray<FString> Walkthrough;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	TArray<FDFStorySequence> Sequences;

	const FDFLegendEntry* FindLegend(const FString& Symbol) const
	{
		return Legend.FindByPredicate([&Symbol](const FDFLegendEntry& E) { return E.Symbol == Symbol; });
	}

	FString Prop(const FString& Key, const FString& Default = FString()) const
	{
		const FString* Value = Props.Find(Key);
		return Value ? *Value : Default;
	}
};

/** A line of the Listener's mimicry (listener_mimicry.json). */
USTRUCT(BlueprintType)
struct DEADFREQUENCY_API FDFMimicLine
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	FString Speaker;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	FString Text;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	FString Vo;

	/** New Game+ lines: the ending of the previous run that unlocks it ("A".."D"). */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	FString Ending;
};

USTRUCT(BlueprintType)
struct DEADFREQUENCY_API FDFMimicData
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	TArray<FDFMimicLine> Lines;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Story")
	TArray<FDFMimicLine> NewGamePlus;
};

USTRUCT(BlueprintType)
struct DEADFREQUENCY_API FDFJournalEntry
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadOnly, SaveGame, Category = "Story")
	FString Title;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, SaveGame, Category = "Story")
	FString Text;

	/** note, tape, radio, ... */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, SaveGame, Category = "Story")
	FName Kind;
};
