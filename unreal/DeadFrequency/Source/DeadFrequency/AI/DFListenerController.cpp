#include "AI/DFListenerController.h"

#include "AI/DFListenerCharacter.h"
#include "DeadFrequency.h"
#include "EngineUtils.h"
#include "Engine/GameInstance.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Kismet/GameplayStatics.h"
#include "NavigationSystem.h"
#include "Navigation/PathFollowingComponent.h"
#include "Perception/AIPerceptionComponent.h"
#include "Perception/AISenseConfig_Hearing.h"
#include "Perception/AISense_Hearing.h"
#include "Player/DFInteractable.h"
#include "Player/DFPlayerCharacter.h"
#include "Story/DFStorySubsystem.h"

namespace DFListener
{
	// metres per second in the Godot game, centimetres here: dormant, patrol, investigate, search, stalk, hunt, ambush, retreat
	const float Speeds[] = { 0.f, 150.f, 230.f, 180.f, 200.f, 440.f, 300.f, 320.f };
}

ADFListenerController::ADFListenerController()
{
	PrimaryActorTick.bCanEverTick = true;
	Perception = CreateDefaultSubobject<UAIPerceptionComponent>(TEXT("Perception"));
	HearingConfig = CreateDefaultSubobject<UAISenseConfig_Hearing>(TEXT("Hearing"));
	HearingConfig->HearingRange = 60.f * DF_METRES;       // each noise carries its own range (DFReportNoise)
	HearingConfig->DetectionByAffiliation.bDetectEnemies = true;
	HearingConfig->DetectionByAffiliation.bDetectNeutrals = true;
	HearingConfig->DetectionByAffiliation.bDetectFriendlies = true;
	HearingConfig->SetMaxAge(1.f);
	Perception->ConfigureSense(*HearingConfig);
	Perception->SetDominantSense(UAISense_Hearing::StaticClass());
	SetPerceptionComponent(*Perception);
}

void ADFListenerController::OnPossess(APawn* InPawn)
{
	Super::OnPossess(InPawn);
	Rng.GenerateNewSeed();
	Perception->OnTargetPerceptionUpdated.AddUniqueDynamic(this, &ADFListenerController::OnPerception);
	// Possession can happen while the level is still loading (placed pawns possess in PostInitializeComponents):
	// the first order waits for the first tick, when navigation and the player exist.
	const ADFListenerCharacter* Body = Cast<ADFListenerCharacter>(InPawn);
	PendingMode = Body ? Body->InitialMode : FName(TEXT("patrol"));
	bCommanded = false;
}

void ADFListenerController::Begin()
{
	if (bInitialised)
	{
		return;
	}
	bInitialised = true;

	// patrol points are the Godot "P" markers: actors tagged ListenerPatrol in the level
	PatrolPoints.Reset();
	HidingSpots.Reset();
	for (TActorIterator<AActor> It(GetWorld()); It; ++It)
	{
		if (It->ActorHasTag(TEXT("ListenerPatrol")))
		{
			PatrolPoints.Add(*It);
		}
		if (It->GetClass()->ImplementsInterface(UDFHidingSpot::StaticClass()))
		{
			HidingSpots.Add(*It);
		}
	}

	// New Game+: what it remembers from the previous run, at half strength
	bNewGamePlus = Memory(TEXT("ngp")) > 0;
	if (bNewGamePlus)
	{
		HuntCap = 45.f;
		if (Memory(TEXT("mem_sprint")) >= 2)
		{
			HuntSpeed = 460.f;
		}
		bLureWise = Memory(TEXT("mem_bottles")) >= 3;
	}
}

UDFStorySubsystem* ADFListenerController::GetStory() const
{
	const UGameInstance* GI = GetGameInstance();
	return GI ? GI->GetSubsystem<UDFStorySubsystem>() : nullptr;
}

ADFPlayerCharacter* ADFListenerController::GetPlayer() const
{
	return Cast<ADFPlayerCharacter>(UGameplayStatics::GetPlayerPawn(this, 0));
}

int32 ADFListenerController::Memory(const FString& Name) const
{
	const UDFStorySubsystem* Story = GetStory();
	return Story ? Story->GetFlag(FName(*Name)) : 0;
}

void ADFListenerController::Remember(const FString& Name)
{
	if (UDFStorySubsystem* Story = GetStory())
	{
		Story->SetFlag(FName(*Name), Story->GetFlag(FName(*Name)) + 1);
	}
}

float ADFListenerController::SpeedOf(EDFListenerState S) const
{
	return S == EDFListenerState::Hunt ? HuntSpeed : DFListener::Speeds[static_cast<int32>(S)];
}

FVector ADFListenerController::RandomFloorNear(const FVector& Origin, float RadiusCm) const
{
	if (const UNavigationSystemV1* Nav = UNavigationSystemV1::GetCurrent<UNavigationSystemV1>(GetWorld()))
	{
		FNavLocation Out;
		if (Nav->GetRandomReachablePointInRadius(Origin, RadiusCm, Out))
		{
			return Out.Location;
		}
	}
	return Origin;
}

void ADFListenerController::MoveTo(const FVector& Where)
{
	const EPathFollowingRequestResult::Type Result = MoveToLocation(Where, 40.f, true, true, true, true);
	if (Result == EPathFollowingRequestResult::RequestSuccessful)
	{
		CurrentMove = GetCurrentMoveRequestID();
		bRouteDone = false;
	}
	else
	{
		bRouteDone = true;
	}
}

void ADFListenerController::OnMoveCompleted(FAIRequestID RequestID, const FPathFollowingResult& Result)
{
	Super::OnMoveCompleted(RequestID, Result);
	if (RequestID == CurrentMove)
	{
		bRouteDone = true;           // a superseded request's abort does not end the current route
	}
}

// ------------------------------------------------------------------------------------------------ senses

void ADFListenerController::OnPerception(AActor* Actor, FAIStimulus Stimulus)
{
	if (Stimulus.Type != UAISense::GetSenseID<UAISense_Hearing>() || !Stimulus.WasSuccessfullySensed())
	{
		return;
	}
	FName Kind;
	float Loud = 0.f;
	if (!DFParseNoiseTag(Stimulus.Tag, Kind, Loud))
	{
		Kind = Stimulus.Tag;
		Loud = 5.f;
	}
	Hear(Stimulus.StimulusLocation, Loud, Kind);
}

void ADFListenerController::Hear(const FVector& Where, float LoudMetres, FName Kind)
{
	const APawn* Me = GetPawn();
	if (bPassive || !Me || State == EDFListenerState::Hunt || State == EDFListenerState::Retreat)
	{
		return;
	}
	const float Dist = FVector::Dist(Where, Me->GetActorLocation());
	if (Kind == TEXT("Object") && bLureWise)
	{
		// fooled by bottles last run: slower to fall for the same trick twice in a row
		const float Now = GetWorld()->GetTimeSeconds();
		const bool bRepeat = Now - LastLure < 20.f;
		LastLure = Now;
		if (bRepeat && Rng.FRand() < 0.35f)
		{
			Alert = FMath::Min(1.f, Alert + 0.15f);
			return;
		}
	}
	// blurred: the further the sound, the worse its fix
	const float Error = FMath::Clamp(Dist * 0.18f, 0.f, 5.f * DF_METRES);
	const FVector Guess = Error > 0.8f * DF_METRES ? RandomFloorNear(Where, Error) : Where;
	Heat(Where);
	if (State == EDFListenerState::Ambush && Dist > 6.f * DF_METRES)
	{
		return;
	}
	if (State == EDFListenerState::Dormant && LoudMetres < 4.f && Dist > 3.f * DF_METRES)
	{
		return;
	}
	Target = Guess;
	LastKnown = Guess;
	Alert = FMath::Min(1.f, Alert + (Kind == TEXT("Step") ? 0.12f : 0.2f));
	if (State != EDFListenerState::Investigate)
	{
		if (ADFListenerCharacter* Body = Cast<ADFListenerCharacter>(GetPawn()))
		{
			Body->OnClicks();
		}
	}
	Go(EDFListenerState::Investigate);
}

void ADFListenerController::Heat(const FVector& Where)
{
	int32 Best = INDEX_NONE;
	float BestDist = TNumericLimits<float>::Max();
	for (int32 i = 0; i < PatrolPoints.Num(); ++i)
	{
		if (const AActor* P = PatrolPoints[i].Get())
		{
			const float D = FVector::Dist(P->GetActorLocation(), Where);
			if (D < BestDist)
			{
				BestDist = D;
				Best = i;
			}
		}
	}
	if (Best != INDEX_NONE)
	{
		HeatMap.FindOrAdd(Best) += 1;
	}
}

bool ADFListenerController::CanSee() const
{
	const APawn* Me = GetPawn();
	const ADFPlayerCharacter* P = GetPlayer();
	if (!Me || !P || P->IsInHiding())
	{
		return false;
	}
	FVector To = P->GetActorLocation() - Me->GetActorLocation();
	To.Z = 0.f;
	const float Dist = To.Size();
	if (bBlind)
	{
		return Dist < 1.2f * DF_METRES;
	}
	float Range = 8.f * DF_METRES;
	if (P->IsTorchOn()) Range += 7.f * DF_METRES;
	if (P->bIsCrouched) Range *= 0.55f;
	if (State == EDFListenerState::Hunt) Range += 4.f * DF_METRES;
	if (!bPowerOn && !P->IsTorchOn()) Range *= 0.7f;
	if (Dist > Range)
	{
		return false;
	}
	if (State != EDFListenerState::Hunt && Dist > 2.f * DF_METRES && FVector::DotProduct(Me->GetActorForwardVector(), To.GetSafeNormal()) < 0.15f)
	{
		return false;
	}
	return LineOfSightTo(P);
}

bool ADFListenerController::Observed() const
{
	// is the player looking straight at it? (it does not move while watched)
	const APawn* Me = GetPawn();
	const ADFPlayerCharacter* P = GetPlayer();
	if (!Me || !P)
	{
		return false;
	}
	FVector To = Me->GetActorLocation() - P->GetActorLocation();
	To.Z = 0.f;
	FVector View = P->GetControlRotation().Vector();
	View.Z = 0.f;
	return FVector::DotProduct(View.GetSafeNormal(), To.GetSafeNormal()) > 0.75f && LineOfSightTo(P);
}

void ADFListenerController::PlayerHid(AActor* Spot)
{
	if (bSees || (State == EDFListenerState::Hunt && LostTime < 1.f))
	{
		SawHide = Spot;
	}
}

// ------------------------------------------------------------------------------------------------ states

void ADFListenerController::Command(FName Mode, FVector Location)
{
	Begin();
	bCommanded = true;
	bPassive = false;
	const ADFPlayerCharacter* P = GetPlayer();
	const FVector PlayerPos = P ? P->GetActorLocation() : Location;
	if (Mode == TEXT("dormant")) Go(EDFListenerState::Dormant);
	else if (Mode == TEXT("patrol")) Go(EDFListenerState::Patrol);
	else if (Mode == TEXT("hunt")) { LastKnown = PlayerPos; Go(EDFListenerState::Hunt); }
	else if (Mode == TEXT("stalk")) { LastKnown = RandomFloorNear(PlayerPos, 4.f * DF_METRES); Go(EDFListenerState::Stalk); }
	else if (Mode == TEXT("seek")) { Target = Location; LastKnown = Location; Go(EDFListenerState::Investigate); }
	else if (Mode == TEXT("face"))
	{
		if (APawn* Me = GetPawn())
		{
			FVector To = PlayerPos - Me->GetActorLocation();
			To.Z = 0.f;
			Me->SetActorRotation(To.Rotation());
		}
		bPassive = true;
		if (State != EDFListenerState::Dormant) Go(EDFListenerState::Dormant);
	}
	else if (Mode == TEXT("blind")) bBlind = true;
	else if (Mode == TEXT("sighted")) bBlind = false;
	else if (Mode == TEXT("retreat")) Go(EDFListenerState::Retreat);
	else if (Mode == TEXT("ambush")) Go(EDFListenerState::Ambush);
	else if (Mode == TEXT("watch")) { bPassive = true; Go(EDFListenerState::Dormant); }
	else if (Mode == TEXT("goto")) { bPassive = true; Target = Location; State = EDFListenerState::Investigate; StateTime = 0.f; MoveTo(Location); }
	else UE_LOG(LogDeadFrequency, Warning, TEXT("Listener: unknown command %s"), *Mode.ToString());
}

void ADFListenerController::Go(EDFListenerState NewState)
{
	State = NewState;
	StateTime = 0.f;
	Repath = 0.f;
	StopMovement();
	bRouteDone = true;
	Trace.Add(NewState);
	ADFListenerCharacter* Body = Cast<ADFListenerCharacter>(GetPawn());
	switch (NewState)
	{
	case EDFListenerState::Patrol:
		NextPatrol();
		break;
	case EDFListenerState::Investigate:
		MoveTo(Target);
		break;
	case EDFListenerState::Search:
		SearchLeft = 3 + Rng.RandRange(0, 1);
		NextSearch();
		break;
	case EDFListenerState::Hunt:
		Remember(TEXT("m_hunts"));
		if (Body) Body->OnScreech();
		break;
	case EDFListenerState::Retreat:
	{
		// back to the patrol point furthest from the player
		const ADFPlayerCharacter* P = GetPlayer();
		const AActor* Far = nullptr;
		float FarDist = -1.f;
		for (const TWeakObjectPtr<AActor>& Weak : PatrolPoints)
		{
			const AActor* Point = Weak.Get();
			if (!Point || !P) continue;
			const float D = FVector::Dist(Point->GetActorLocation(), P->GetActorLocation());
			if (D > FarDist)
			{
				FarDist = D;
				Far = Point;
			}
		}
		if (Far) MoveTo(Far->GetActorLocation());
		Alert = 0.f;
		break;
	}
	case EDFListenerState::Ambush:
	{
		// cut the player off: a spot ahead of where they are heading, out of sight
		if (const ADFPlayerCharacter* P = GetPlayer())
		{
			FVector Vel = P->GetVelocity();
			Vel.Z = 0.f;
			const FVector Dir = Vel.Size() > 50.f ? Vel.GetSafeNormal() : P->GetActorForwardVector();
			Target = RandomFloorNear(P->GetActorLocation() + Dir * 12.f * DF_METRES, 4.f * DF_METRES);
			MoveTo(Target);
		}
		break;
	}
	default:
		break;
	}
	if (Body)
	{
		Body->OnStateChanged(NewState);
	}
}

void ADFListenerController::NextPatrol()
{
	const APawn* Me = GetPawn();
	if (!Me)
	{
		return;
	}
	if (PatrolPoints.Num() == 0)
	{
		Target = RandomFloorNear(Me->GetActorLocation(), 10.f * DF_METRES);
		MoveTo(Target);
		return;
	}
	// weighted toward places where it has heard the player before
	TArray<float> Weights;
	float Total = 0.f;
	for (int32 i = 0; i < PatrolPoints.Num(); ++i)
	{
		const AActor* P = PatrolPoints[i].Get();
		float W = P ? 1.f + FMath::Min(4.f, HeatMap.FindRef(i) * 0.5f) : 0.f;
		if (P && FVector::Dist(P->GetActorLocation(), Me->GetActorLocation()) < 3.f * DF_METRES)
		{
			W = 0.05f;
		}
		Weights.Add(W);
		Total += W;
	}
	float Pick = Rng.FRand() * Total;
	for (int32 i = 0; i < Weights.Num(); ++i)
	{
		Pick -= Weights[i];
		if (Pick <= 0.f && PatrolPoints[i].IsValid())
		{
			Target = PatrolPoints[i]->GetActorLocation();
			break;
		}
	}
	MoveTo(Target);
}

void ADFListenerController::NextSearch()
{
	CheckHide = nullptr;
	// hiding places near the last known position are checked more often the more the player has used them
	for (const TWeakObjectPtr<AActor>& Weak : HidingSpots)
	{
		AActor* Spot = Weak.Get();
		if (!Spot || FVector::Dist(Spot->GetActorLocation(), LastKnown) > 9.f * DF_METRES)
		{
			continue;
		}
		const int32 Uses = Memory(TEXT("m_hide_") + IDFHidingSpot::Execute_GetHidingId(Spot).ToString());
		const float Chance = Spot == SawHide.Get() ? 1.f : FMath::Min(0.7f, 0.08f + 0.18f * FMath::Max(0, Uses - 1));
		if (Rng.FRand() < Chance)
		{
			CheckHide = Spot;
			Target = Spot->GetActorLocation();
			break;
		}
	}
	if (!CheckHide.IsValid())
	{
		Target = RandomFloorNear(LastKnown, 6.f * DF_METRES);
	}
	MoveTo(Target);
}

void ADFListenerController::TryMimic(float Distance)
{
	UDFStorySubsystem* Story = GetStory();
	if (!Story || MimicCooldown > 0.f || Distance > 16.f * DF_METRES || Story->IsBusy())
	{
		return;
	}
	const FDFMimicData& Mimic = Story->GetMimicry();
	if (Mimic.Lines.Num() == 0)
	{
		return;
	}
	MimicCooldown = Rng.FRandRange(22.f, 40.f);
	const FDFMimicLine* Line = &Mimic.Lines[Rng.RandRange(0, Mimic.Lines.Num() - 1)];
	if (bNewGamePlus && Rng.FRand() < 0.5f)
	{
		// in New Game+ it may wear the words of the ending you reached last time
		for (const FDFMimicLine& Ngp : Mimic.NewGamePlus)
		{
			if (Memory(TEXT("mem_end_") + Ngp.Ending) > 0)
			{
				Line = &Ngp;
			}
		}
	}
	if (ADFListenerCharacter* Body = Cast<ADFListenerCharacter>(GetPawn()))
	{
		Body->OnWhisper();
	}
	Story->Say(Line->Speaker, Line->Text, Line->Vo);
}

void ADFListenerController::Attack()
{
	ADFPlayerCharacter* P = GetPlayer();
	if (ADFListenerCharacter* Body = Cast<ADFListenerCharacter>(GetPawn()))
	{
		Body->OnAttack();
	}
	if (P)
	{
		P->Hurt(55.f);
	}
	if (P && P->Health > 0.f)
	{
		if (UDFStorySubsystem* Story = GetStory())
		{
			Story->OnUiCommand.Broadcast(TEXT("toast"), { TEXT("It lets go. This time.") });
		}
		Go(EDFListenerState::Retreat);
	}
}

void ADFListenerController::DragOut()
{
	if (ADFListenerCharacter* Body = Cast<ADFListenerCharacter>(GetPawn()))
	{
		Body->OnDragOut();
	}
	if (ADFPlayerCharacter* P = GetPlayer())
	{
		P->ExitHiding();
	}
	SawHide = nullptr;
	Attack();
}

void ADFListenerController::Escaped()
{
	Remember(TEXT("m_escapes"));
	if (const ADFPlayerCharacter* P = GetPlayer())
	{
		if (P->SprintedRecently())
		{
			Remember(TEXT("m_sprint_esc"));
		}
	}
}

void ADFListenerController::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);
	APawn* Me = GetPawn();
	ADFPlayerCharacter* P = GetPlayer();
	if (!Me || !P || P->Health <= 0.f)
	{
		return;
	}
	if (!bCommanded)
	{
		Command(PendingMode, Me->GetActorLocation());
	}
	StateTime += DeltaSeconds;
	MimicCooldown -= DeltaSeconds;
	const FVector MyPos = Me->GetActorLocation();
	const FVector PlayerPos = P->GetActorLocation();
	const float Dist = FVector::Dist(MyPos, PlayerPos);

	bSees = CanSee() && !bPassive;
	if (bSees)
	{
		LastKnown = PlayerPos;
		LostTime = 0.f;
		Alert = FMath::Min(1.f, Alert + DeltaSeconds * FMath::Clamp(1.5f - Dist / (9.f * DF_METRES), 0.25f, 1.4f) * (P->IsSprinting() ? 1.6f : 1.f));
	}
	else
	{
		LostTime += DeltaSeconds;
		Alert = FMath::Max(0.f, Alert - DeltaSeconds * 0.05f);
	}

	bool bHold = false;                                          // stands still this frame (watched, or lying in wait)
	switch (State)
	{
	case EDFListenerState::Dormant:
		if (!bPassive && (Alert > 0.5f || StateTime > 25.f)) Go(EDFListenerState::Patrol);
		break;
	case EDFListenerState::Patrol:
		if (Alert >= 1.f) Go(EDFListenerState::Hunt);
		else if (bSees && Alert > 0.35f) Go(EDFListenerState::Stalk);
		else if (bRouteDone)
		{
			// sometimes it waits; sometimes it sets a trap where the player keeps going
			if (Memory(TEXT("m_hunts")) > 1 && Rng.FRand() < 0.25f) Go(EDFListenerState::Ambush);
			else if (Rng.FRand() < 0.3f) Go(EDFListenerState::Dormant);
			else NextPatrol();
		}
		break;
	case EDFListenerState::Investigate:
		if (Alert >= 1.f && bSees) Go(EDFListenerState::Hunt);
		else if (bRouteDone)
		{
			if (bPassive)
			{
				Go(EDFListenerState::Dormant);
				bPassive = true;
			}
			else
			{
				Go(EDFListenerState::Search);
			}
		}
		break;
	case EDFListenerState::Search:
		if (Alert >= 1.f && bSees) Go(EDFListenerState::Hunt);
		else if (bRouteDone)
		{
			if (CheckHide.IsValid() && P->IsInHiding() && P->GetHidingSpot() == CheckHide.Get())
			{
				DragOut();
				return;
			}
			if (--SearchLeft <= 0) Go(Alert > 0.4f ? EDFListenerState::Stalk : EDFListenerState::Patrol);
			else NextSearch();
		}
		break;
	case EDFListenerState::Stalk:
		if (Alert >= 1.f && bSees && (Dist < 7.f * DF_METRES || P->IsTorchOn()))
		{
			Go(EDFListenerState::Hunt);                         // never shine the light on it
		}
		else if (Observed() && Dist > 2.5f * DF_METRES)
		{
			bHold = true;                                         // it does not move while you are looking at it
			StopMovement();
		}
		else
		{
			Repath -= DeltaSeconds;
			if (Repath <= 0.f)
			{
				Repath = 1.f;
				if (Dist > 6.f * DF_METRES) MoveTo(LastKnown);
				else StopMovement();
			}
			TryMimic(Dist);
		}
		if (State == EDFListenerState::Stalk && StateTime > 22.f)
		{
			Go(Rng.FRand() < 0.4f ? EDFListenerState::Ambush : EDFListenerState::Retreat);
		}
		break;
	case EDFListenerState::Hunt:
		Repath -= DeltaSeconds;
		if (Repath <= 0.f)
		{
			Repath = 0.35f;
			MoveTo(bSees ? PlayerPos : LastKnown);
		}
		if (Dist < 1.25f * DF_METRES && !P->IsInHiding() && LineOfSightTo(P))
		{
			Attack();
			return;
		}
		if (P->IsInHiding() && SawHide.IsValid() && SawHide.Get() == P->GetHidingSpot() && FVector::Dist(MyPos, SawHide->GetActorLocation()) < 1.8f * DF_METRES)
		{
			DragOut();
			return;
		}
		if (LostTime > 4.5f)
		{
			Escaped();
			Go(EDFListenerState::Search);
		}
		else if (StateTime > HuntCap)
		{
			Go(EDFListenerState::Retreat);                       // fairness valve: no endless chases
		}
		break;
	case EDFListenerState::Ambush:
		if (bRouteDone)
		{
			bHold = true;
			if (Dist < 3.6f * DF_METRES && !P->IsInHiding() && LineOfSightTo(P)) Go(EDFListenerState::Hunt);
			else if (StateTime > 26.f) Go(EDFListenerState::Patrol);
		}
		break;
	case EDFListenerState::Retreat:
		if (bRouteDone) Go(EDFListenerState::Dormant);
		break;
	}

	if (const ACharacter* Body = Cast<ACharacter>(Me))
	{
		Body->GetCharacterMovement()->MaxWalkSpeed = bHold ? 0.f : SpeedOf(State);         // of the state it ends the frame in
	}
}
