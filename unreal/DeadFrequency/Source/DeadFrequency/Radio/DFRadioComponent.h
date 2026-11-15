#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "DFRadioComponent.generated.h"

class ADFTransmitter;
class UDFStorySubsystem;

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FDFOnRadioPower, bool, bOn);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FDFOnRadioTuned, float, Frequency);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FDFOnRadioBeep, bool, bFacing, float, Strength);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FDFOnRadioReceived, ADFTransmitter*, Transmitter);

/**
 * The HX-7 field receiver, ported from the Godot game's radio.gd rule for rule:
 * - tunes 87.5-108.0 MHz in 0.1 steps (tap, or hold for auto-repeat after 0.35 s);
 * - four bands within 0.16 MHz: 89.1 ECHO (the past), 94.6 PROXIMITY (movement), 101.3 FORECAST (not yet),
 *   107.9 UNSEEN (what hides); 88.0 is the one channel the Listener cannot hear;
 * - transmissions are received when the signal stays above 0.72 for a second; the antenna is directional;
 * - the cell drains in 170 s and is replaced from the inventory;
 * - every 1.2 s while it is on, the carrier is a noise the Listener hears (8-15 m, more as it learns).
 */
UCLASS(ClassGroup = (DeadFrequency), meta = (BlueprintSpawnableComponent))
class DEADFREQUENCY_API UDFRadioComponent : public UActorComponent
{
	GENERATED_BODY()

public:
	UDFRadioComponent();

	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

	UFUNCTION(BlueprintCallable, Category = "Radio") void Toggle();
	/** One step (+/-0.1 MHz). */
	UFUNCTION(BlueprintCallable, Category = "Radio") void Tune(float Direction);
	/** Held tuning input (-1..1); call every frame with the axis value. */
	UFUNCTION(BlueprintCallable, Category = "Radio") void SetTuneHeld(float Direction);
	/** A scripted transmission takes the set over (the story's radio_on command); false gives it back. */
	UFUNCTION(BlueprintCallable, Category = "Radio") void Force(bool bState, float ForcedFrequency = -1.f);

	/** The band the dial is on (89.1, 94.6, 101.3, 107.9) or 0. */
	UFUNCTION(BlueprintPure, Category = "Radio") float GetBand() const;
	UFUNCTION(BlueprintPure, Category = "Radio") FString GetBandName() const;

	UPROPERTY(BlueprintReadOnly, Category = "Radio") bool bOn = false;
	UPROPERTY(BlueprintReadOnly, Category = "Radio") float Frequency = 89.1f;
	/** 0-100. */
	UPROPERTY(BlueprintReadOnly, Category = "Radio") float Battery = 100.f;
	/** 0-1: reception of the best transmission or band. */
	UPROPERTY(BlueprintReadOnly, Category = "Radio") float Signal = 0.f;
	/** 0-1: how audible the carrier is to the Listener right now. */
	UPROPERTY(BlueprintReadOnly, Category = "Radio") float Exposure = 0.f;
	/** 0-1: interference from the Listener's proximity (on or off). */
	UPROPERTY(BlueprintReadOnly, Category = "Radio") float Danger = 0.f;
	/** 107.9 is on: cloaked things are visible. */
	UPROPERTY(BlueprintReadOnly, Category = "Radio") bool bRevealOn = false;
	UPROPERTY(BlueprintReadOnly, Category = "Radio") bool bHasRadio = false;

	UPROPERTY(BlueprintAssignable) FDFOnRadioPower OnPower;
	UPROPERTY(BlueprintAssignable) FDFOnRadioTuned OnTuned;
	UPROPERTY(BlueprintAssignable) FDFOnRadioBeep OnBeep;
	UPROPERTY(BlueprintAssignable) FDFOnRadioReceived OnReceived;

	static constexpr float Tolerance = 0.16f;
	static constexpr float MinFrequency = 87.5f;
	static constexpr float MaxFrequency = 108.0f;
	static constexpr float SecondsPerCell = 170.f;

	/** How far the Listener hears a kind of noise, as it learns (Godot listener.gd hear_mult). */
	static float HearMultiplier(const UDFStorySubsystem* Story, FName Kind);

private:
	UDFStorySubsystem* GetStory() const;
	AActor* FindListener();
	void Receive(ADFTransmitter* Transmitter);

	float Hold = 0.f;
	float HeldDirection = 0.f;
	float EmitTimer = 0.f;
	float BeepTimer = 0.f;
	float LockTime = 0.f;
	float ListenerScan = 0.f;
	TWeakObjectPtr<ADFTransmitter> LockTarget;
	TWeakObjectPtr<AActor> Listener;
	bool bForced = false;
	bool bPreOn = false;
	float PreFrequency = 89.1f;
};
