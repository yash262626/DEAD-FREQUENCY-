#pragma once

#include "CoreMinimal.h"
#include "AIController.h"
#include "Perception/AIPerceptionTypes.h"
#include "DFListenerController.generated.h"

class ADFPlayerCharacter;
class UAISenseConfig_Hearing;
class UDFStorySubsystem;

UENUM(BlueprintType)
enum class EDFListenerState : uint8
{
	Dormant,
	Patrol,
	Investigate,
	Search,
	Stalk,
	Hunt,
	Ambush,
	Retreat
};

/**
 * The Listener's mind, ported from the Godot game's listener.gd:
 * - it hears through Unreal's perception system, with the Godot rules: blurred localisation (0.18 m of error per
 *   metre of distance, up to 5 m), a dormant Listener ignores quiet distant sounds, an ambushing one ignores far ones;
 * - it sees with custom rules: 8 m, +7 m when the torch is on, x0.55 when the player crouches, +4 m while hunting,
 *   less in the dark; a forward cone except at close range or while hunting; never into a hiding place;
 * - eight states: dormant, patrol (weighted toward where it heard you), investigate, search (checks the hiding
 *   places you use most), stalk (freezes while you look at it; mimics voices), hunt (a 40 s fairness cap; never as
 *   fast as a sprint), ambush (cuts you off ahead), retreat;
 * - it learns across the run and, in New Game+, from the previous one (story flags m_* and mem_*).
 * Navigation uses the navmesh; vents and doors are nav links and smart objects placed in the levels.
 */
UCLASS()
class DEADFREQUENCY_API ADFListenerController : public AAIController
{
	GENERATED_BODY()

public:
	ADFListenerController();

	virtual void OnPossess(APawn* InPawn) override;
	virtual void Tick(float DeltaSeconds) override;
	virtual void OnMoveCompleted(FAIRequestID RequestID, const FPathFollowingResult& Result) override;

	/** Story commands: dormant, patrol, hunt, stalk, seek, face, blind, sighted, retreat, ambush, watch, goto. */
	UFUNCTION(BlueprintCallable, Category = "Listener")
	void Command(FName Mode, FVector Location = FVector::ZeroVector);

	/** A noise: how far it carries (metres) and what it is (Step, Radio, Door, Click, Object). */
	void Hear(const FVector& Where, float LoudMetres, FName Kind);

	/** The player just hid: if it was watching, that hiding place is no secret. */
	void PlayerHid(AActor* Spot);

	UFUNCTION(BlueprintPure, Category = "Listener") EDFListenerState GetState() const { return State; }
	UFUNCTION(BlueprintPure, Category = "Listener") bool SeesPlayer() const { return bSees; }

	/** The level's power: in the dark it sees less unless the torch is on. */
	UPROPERTY(BlueprintReadWrite, Category = "Listener") bool bPowerOn = true;
	/** 0-1 visual certainty. */
	UPROPERTY(BlueprintReadOnly, Category = "Listener") float Alert = 0.f;
	/** State history, for automated tests. */
	TArray<EDFListenerState> Trace;

protected:
	UFUNCTION() void OnPerception(AActor* Actor, FAIStimulus Stimulus);

	UPROPERTY(VisibleAnywhere, Category = "Listener") TObjectPtr<UAIPerceptionComponent> Perception;
	UPROPERTY() TObjectPtr<UAISenseConfig_Hearing> HearingConfig;

private:
	/** Gathers patrol points and hiding places and applies the New Game+ memory (once, on the first order). */
	void Begin();
	void Go(EDFListenerState NewState);
	void MoveTo(const FVector& Where);
	bool CanSee() const;
	bool Observed() const;
	void NextPatrol();
	void NextSearch();
	void Attack();
	void DragOut();
	void Escaped();
	void Heat(const FVector& Where);
	void TryMimic(float Distance);
	FVector RandomFloorNear(const FVector& Origin, float RadiusCm) const;
	ADFPlayerCharacter* GetPlayer() const;
	UDFStorySubsystem* GetStory() const;
	float SpeedOf(EDFListenerState S) const;
	int32 Memory(const FString& Name) const;
	void Remember(const FString& Name);

	/** The pawn's InitialMode, given on the first tick unless the story gives an order first. */
	FName PendingMode = TEXT("patrol");
	bool bInitialised = false;
	bool bCommanded = false;
	EDFListenerState State = EDFListenerState::Patrol;
	float StateTime = 0.f;
	float LostTime = 0.f;
	float Repath = 0.f;
	float MimicCooldown = 12.f;
	float LastLure = -100.f;
	int32 SearchLeft = 0;
	bool bSees = false;
	bool bPassive = false;
	bool bBlind = false;
	bool bRouteDone = true;
	FAIRequestID CurrentMove;
	FVector Target = FVector::ZeroVector;
	FVector LastKnown = FVector::ZeroVector;
	TWeakObjectPtr<AActor> SawHide;
	TWeakObjectPtr<AActor> CheckHide;
	TArray<TWeakObjectPtr<AActor>> PatrolPoints;
	TArray<TWeakObjectPtr<AActor>> HidingSpots;
	TMap<int32, int32> HeatMap;
	FRandomStream Rng;

	// New Game+ ("Second Signal"): bounded adaptations from the previous completed run
	bool bNewGamePlus = false;
	bool bLureWise = false;
	float HuntSpeed = 440.f;     // never reaches the player's sprint (530)
	float HuntCap = 40.f;
};
