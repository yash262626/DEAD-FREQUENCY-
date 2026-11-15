#include "Radio/DFRadioComponent.h"

#include "AI/DFListenerCharacter.h"
#include "DeadFrequency.h"
#include "EngineUtils.h"
#include "Engine/GameInstance.h"
#include "GameFramework/Pawn.h"
#include "GameFramework/Controller.h"
#include "Perception/AISense_Hearing.h"
#include "Radio/DFTransmitter.h"
#include "Story/DFStorySubsystem.h"

namespace DFRadio
{
	struct FBand { float Frequency; const TCHAR* Name; };
	const FBand Bands[] = {
		{ 89.1f, TEXT("89.1  ECHO - the past") },
		{ 94.6f, TEXT("94.6  PROXIMITY - movement") },
		{ 101.3f, TEXT("101.3  FORECAST - not yet") },
		{ 107.9f, TEXT("107.9  UNSEEN - what hides") },
	};
}

UDFRadioComponent::UDFRadioComponent()
{
	PrimaryComponentTick.bCanEverTick = true;
}

UDFStorySubsystem* UDFRadioComponent::GetStory() const
{
	const UWorld* World = GetWorld();
	const UGameInstance* GI = World ? World->GetGameInstance() : nullptr;
	return GI ? GI->GetSubsystem<UDFStorySubsystem>() : nullptr;
}

float UDFRadioComponent::HearMultiplier(const UDFStorySubsystem* Story, FName Kind)
{
	// it learns: the more the radio is used, the further it hears the carrier
	if (Story && Kind == TEXT("Radio"))
	{
		return 1.f + FMath::Min(0.5f, Story->GetFlag(TEXT("m_radio")) * 0.004f);
	}
	return 1.f;
}

float UDFRadioComponent::GetBand() const
{
	for (const DFRadio::FBand& Band : DFRadio::Bands)
	{
		if (FMath::Abs(Frequency - Band.Frequency) < Tolerance)
		{
			return Band.Frequency;
		}
	}
	return 0.f;
}

FString UDFRadioComponent::GetBandName() const
{
	for (const DFRadio::FBand& Band : DFRadio::Bands)
	{
		if (FMath::Abs(Frequency - Band.Frequency) < Tolerance)
		{
			return Band.Name;
		}
	}
	return TEXT("- no carrier -");
}

void UDFRadioComponent::Toggle()
{
	if (!bHasRadio)
	{
		return;
	}
	UDFStorySubsystem* Story = GetStory();
	if (!bOn && Battery <= 0.f && !(Story && Story->Count(TEXT("battery")) > 0))
	{
		return;                                  // the UI says "Receiver cell is dead."
	}
	bOn = !bOn;
	OnPower.Broadcast(bOn);
}

void UDFRadioComponent::Tune(float Direction)
{
	if (!bOn || FMath::IsNearlyZero(Direction))
	{
		return;
	}
	const float Stepped = FMath::RoundToFloat((Frequency + 0.1f * FMath::Sign(Direction)) * 10.f) / 10.f;
	Frequency = FMath::Clamp(Stepped, MinFrequency, MaxFrequency);
	LockTime = 0.f;
	OnTuned.Broadcast(Frequency);
}

void UDFRadioComponent::SetTuneHeld(float Direction)
{
	HeldDirection = Direction;
}

void UDFRadioComponent::Force(bool bState, float ForcedFrequency)
{
	if (bState)
	{
		if (!bForced)
		{
			bPreOn = bOn;
			PreFrequency = Frequency;
		}
		bForced = true;
		bOn = true;
		if (ForcedFrequency > 0.f)
		{
			Frequency = ForcedFrequency;
		}
	}
	else
	{
		if (bForced)
		{
			bOn = bPreOn;
			Frequency = PreFrequency;
		}
		else
		{
			bOn = false;
		}
		bForced = false;
	}
	OnPower.Broadcast(bOn);
}

AActor* UDFRadioComponent::FindListener()
{
	ListenerScan -= GetWorld()->GetDeltaSeconds();
	if (!Listener.IsValid() && ListenerScan <= 0.f)
	{
		ListenerScan = 1.f;
		for (TActorIterator<ADFListenerCharacter> It(GetWorld()); It; ++It)
		{
			Listener = *It;
			break;
		}
	}
	return Listener.Get();
}

void UDFRadioComponent::Receive(ADFTransmitter* Transmitter)
{
	LockTime = 0.f;
	LockTarget = nullptr;
	Transmitter->Receive();
	OnReceived.Broadcast(Transmitter);
}

void UDFRadioComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	AActor* Owner = GetOwner();
	UDFStorySubsystem* Story = GetStory();
	if (!Owner || !Story)
	{
		return;
	}

	// held tuning: auto-repeat after 0.35 s, then every 0.05 s
	if (bOn && FMath::Abs(HeldDirection) > 0.5f)
	{
		Hold += DeltaTime;
		if (Hold > 0.35f)
		{
			Hold -= 0.05f;
			Tune(HeldDirection);
		}
	}
	else
	{
		Hold = 0.f;
	}

	bRevealOn = false;
	const FVector Me = Owner->GetActorLocation();
	AActor* TheListener = FindListener();
	const float ListenerDistance = TheListener ? FVector::Dist(TheListener->GetActorLocation(), Me) : TNumericLimits<float>::Max();
	// interference from its proximity exists whether or not the set is on
	const float Near = FMath::Clamp(1.f - ListenerDistance / (9.f * DF_METRES), 0.f, 1.f);
	if (!bOn || !bHasRadio)
	{
		Danger = Near * 0.6f;
		Signal = 0.f;
		Exposure = 0.f;
		return;
	}

	Battery -= DeltaTime * (100.f / SecondsPerCell);
	if (Battery <= 0.f)
	{
		if (Story->Take(TEXT("battery")))
		{
			Battery = 100.f;
		}
		else
		{
			Battery = 0.f;
			bOn = false;
			OnPower.Broadcast(false);
			return;
		}
	}

	const float Band = GetBand();
	FVector Forward = Owner->GetActorForwardVector();
	if (const APawn* Pawn = Cast<APawn>(Owner))
	{
		Forward = Pawn->GetControlRotation().Vector();       // the antenna points where the player looks
	}
	Forward.Z = 0.f;
	Forward.Normalize();

	Signal = 0.f;
	float Loud = 8.f;                                        // metres the carrier carries
	ADFTransmitter* Best = nullptr;
	for (const TWeakObjectPtr<ADFTransmitter>& Weak : ADFTransmitter::All())
	{
		ADFTransmitter* T = Weak.Get();
		if (!T || T->GetWorld() != GetWorld() || !T->IsActive() || FMath::Abs(Frequency - T->Frequency) > Tolerance)
		{
			continue;
		}
		FVector To = T->GetActorLocation() - Me;
		To.Z = 0.f;
		const float Dist = To.Size();
		if (Dist > T->Range)
		{
			continue;
		}
		const float Facing = Dist < 1.5f * DF_METRES ? 1.f : FMath::Max(0.f, FVector::DotProduct(Forward, To.GetSafeNormal()));
		float S = (1.f - Dist / T->Range) * 0.55f + 0.45f * Facing;
		if (Dist < T->Range * 0.5f && Facing > 0.8f)
		{
			S = FMath::Max(S, 0.9f);
		}
		if (S > Signal)
		{
			Signal = S;
			Best = T;
		}
	}
	if (Best)
	{
		Loud = 11.f;
		if (Signal > 0.72f && !Story->IsBusy())
		{
			if (LockTarget.Get() != Best)
			{
				LockTarget = Best;
				LockTime = 0.f;
			}
			LockTime += DeltaTime;
			if (LockTime > 1.f)
			{
				Receive(Best);
			}
		}
		else
		{
			LockTime = FMath::Max(0.f, LockTime - DeltaTime);
		}
	}

	if (FMath::IsNearlyEqual(Band, 94.6f))
	{
		// movement detector: beeps faster as it closes; the antenna sharpens the reading
		BeepTimer -= DeltaTime;
		if (TheListener && ListenerDistance < 60.f * DF_METRES)
		{
			FVector To = TheListener->GetActorLocation() - Me;
			To.Z = 0.f;
			const float Facing = FMath::Max(0.f, FVector::DotProduct(Forward, To.GetSafeNormal()));
			Signal = FMath::Max(Signal, FMath::Clamp(1.f - ListenerDistance / (45.f * DF_METRES), 0.05f, 1.f) * (0.5f + 0.5f * Facing));
			if (BeepTimer <= 0.f)
			{
				BeepTimer = FMath::Clamp(ListenerDistance / (14.f * DF_METRES), 0.12f, 2.2f);
				OnBeep.Broadcast(Facing > 0.85f, Signal);
			}
		}
		else if (BeepTimer <= 0.f)
		{
			BeepTimer = 3.f;
			OnBeep.Broadcast(false, 0.f);
		}
		Loud = 10.f;
	}
	else if (FMath::IsNearlyEqual(Band, 107.9f))
	{
		bRevealOn = true;
		Loud = 15.f;
		Signal = FMath::Max(Signal, 0.5f);
	}
	if (FMath::Abs(Frequency - 88.0f) < Tolerance)
	{
		Loud = 0.f;                                          // below the Listener's band: the one channel it cannot hear
	}

	// the carrier gives you away
	EmitTimer -= DeltaTime;
	if (EmitTimer <= 0.f)
	{
		EmitTimer = 1.2f;
		if (Loud > 0.f)
		{
			if (TheListener)
			{
				Story->SetFlag(TEXT("m_radio"), Story->GetFlag(TEXT("m_radio")) + 1);   // what it learns from (Godot hear())
			}
			const float Reach = Loud * HearMultiplier(Story, TEXT("Radio"));
			UAISense_Hearing::ReportNoiseEvent(GetWorld(), Me, Loud, Owner, Reach * DF_METRES, TEXT("Radio"));
		}
	}
	const float Reach = Loud * HearMultiplier(Story, TEXT("Radio")) * DF_METRES;
	Exposure = (TheListener && Loud > 0.f) ? FMath::Clamp(1.3f - ListenerDistance / Reach, 0.f, 1.f) : 0.f;
	Danger = FMath::Max(Exposure, Near);
}
