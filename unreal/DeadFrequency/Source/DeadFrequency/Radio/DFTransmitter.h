#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "DFTransmitter.generated.h"

/**
 * A radio source in a level: an "echo" of the past, a forecast, a hidden carrier. It refers to its entry in the
 * chapter's story data (legend kind "radio") by symbol; frequency, range, flag and condition come from there unless
 * overridden. Placed by level designers where the Godot grid had the symbol.
 */
UCLASS()
class DEADFREQUENCY_API ADFTransmitter : public AActor
{
	GENERATED_BODY()

public:
	ADFTransmitter();

	/** Chapter key (chapter_07, slice, ...) and the legend symbol in that chapter. */
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Radio")
	FString Chapter;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Radio")
	FString Symbol;

	/** MHz. */
	UPROPERTY(VisibleInstanceOnly, BlueprintReadOnly, Category = "Radio")
	float Frequency = 89.1f;

	/** Reception range in centimetres (Godot "r", default 14 m). */
	UPROPERTY(VisibleInstanceOnly, BlueprintReadOnly, Category = "Radio")
	float Range = 1400.f;

	UPROPERTY(VisibleInstanceOnly, BlueprintReadOnly, Category = "Radio")
	FString Title;

	/** Story conditions (Godot "if" / "ifnot" on the entry). */
	UPROPERTY(VisibleInstanceOnly, BlueprintReadOnly, Category = "Radio")
	FString Condition;

	UPROPERTY(VisibleInstanceOnly, BlueprintReadOnly, Category = "Radio")
	FString ConditionNot;

	UPROPERTY(BlueprintReadOnly, Category = "Radio")
	bool bDone = false;

	/** Can it be received right now (not done, conditions met)? */
	bool IsActive() const;

	/** Received: marks it done, runs its lines and script, sets its flag, adds it to the journal. */
	void Receive();

	/** Every transmitter in the running world (for the radio's per-frame scan). */
	static const TArray<TWeakObjectPtr<ADFTransmitter>>& All() { return Registry; }

protected:
	virtual void BeginPlay() override;
	virtual void EndPlay(const EEndPlayReason::Type Reason) override;

private:
	static TArray<TWeakObjectPtr<ADFTransmitter>> Registry;
	FString Flag;
};
