#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "AI/DFListenerController.h"
#include "DFListenerCharacter.generated.h"

/**
 * The Listener's body. Gameplay lives in ADFListenerController; this pawn carries the mesh (set in the Blueprint
 * subclass with the production skeletal mesh, Control Rig and Animation Blueprint), the cloaking rule and the
 * presentation hooks the Blueprint uses for animation and sound.
 */
UCLASS()
class DEADFREQUENCY_API ADFListenerCharacter : public ACharacter
{
	GENERATED_BODY()

public:
	ADFListenerCharacter();

	virtual void Tick(float DeltaSeconds) override;

	/** How it starts: patrol, dormant, hunt, stalk, watch, ambush, retreat (the story's listener spawn modes). */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Listener")
	FName InitialMode = TEXT("patrol");

	/** Containment chapters: visible only on 107.9 MHz or at arm's length. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Listener")
	bool bCloaked = false;

	UFUNCTION(BlueprintImplementableEvent, Category = "Listener") void OnStateChanged(EDFListenerState NewState);
	UFUNCTION(BlueprintImplementableEvent, Category = "Listener") void OnAttack();
	/** It heard something and turns its membrane toward it (the clicking). */
	UFUNCTION(BlueprintImplementableEvent, Category = "Listener") void OnClicks();
	UFUNCTION(BlueprintImplementableEvent, Category = "Listener") void OnScreech();
	/** It speaks in someone else's voice. */
	UFUNCTION(BlueprintImplementableEvent, Category = "Listener") void OnWhisper();
	/** It drags the player out of a hiding place. */
	UFUNCTION(BlueprintImplementableEvent, Category = "Listener") void OnDragOut();

private:
	bool bShown = true;
};
