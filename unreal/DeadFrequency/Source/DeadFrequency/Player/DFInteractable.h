#pragma once

#include "CoreMinimal.h"
#include "UObject/Interface.h"
#include "DFInteractable.generated.h"

class ADFPlayerCharacter;

UINTERFACE(BlueprintType)
class UDFInteractable : public UInterface
{
	GENERATED_BODY()
};

/** Doors, devices, notes, tapes, items, hiding places: anything the player can use with the interact key. */
class DEADFREQUENCY_API IDFInteractable
{
	GENERATED_BODY()

public:
	/** Shown under the crosshair ("Open door", "Hide under the desk", ...); empty means not usable right now. */
	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Interaction")
	FText GetPrompt(ADFPlayerCharacter* Player) const;

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Interaction")
	void Interact(ADFPlayerCharacter* Player);
};

UINTERFACE(BlueprintType)
class UDFHidingSpot : public UInterface
{
	GENERATED_BODY()
};

/** Lockers and low places (under desks). The Listener searches the ones the player uses most. */
class DEADFREQUENCY_API IDFHidingSpot
{
	GENERATED_BODY()

public:
	/** Where the eye goes while hidden, and whether the place is low (no locker slats, lower view). */
	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hiding")
	FTransform GetEyeTransform() const;

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hiding")
	bool IsLow() const;

	/** Stable id for the learning memory (m_hide_<id>). */
	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hiding")
	FName GetHidingId() const;
};
