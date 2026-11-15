#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "InputActionValue.h"
#include "DFPlayerCharacter.generated.h"

class UCameraComponent;
class USpotLightComponent;
class UDFRadioComponent;
class UInputAction;
class UInputMappingContext;
class USoundBase;

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FDFOnPrompt, const FText&, Prompt);
DECLARE_DYNAMIC_MULTICAST_DELEGATE(FDFOnDied);

/**
 * Daniel, first person. Ported from the Godot game's player.gd: walk 2.7 m/s, sprint 5.3 m/s, crouch 1.3 m/s;
 * stamina (drains 16/s sprinting, refills 9/s moving and 15/s still, winded at 0 until 30); lean; the torch with
 * cells (a cell lasts 260 s, it flickers under 12 %); footsteps the Listener hears (5 m walking, 12.5 m sprinting,
 * 1.3 m crouched, half again in water); interaction ray of 2.7 m; hiding. Input is defined in code (Enhanced
 * Input), keyboard/mouse and gamepad, so it is reviewable and needs no binary assets.
 */
UCLASS()
class DEADFREQUENCY_API ADFPlayerCharacter : public ACharacter
{
	GENERATED_BODY()

public:
	ADFPlayerCharacter();

	virtual void Tick(float DeltaSeconds) override;
	virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override;

	UFUNCTION(BlueprintCallable, Category = "Player") void EnterHiding(AActor* Spot);
	UFUNCTION(BlueprintCallable, Category = "Player") void ExitHiding();
	UFUNCTION(BlueprintCallable, Category = "Player") void Hurt(float Amount);
	UFUNCTION(BlueprintCallable, Category = "Player") void SetLocked(bool bInLocked) { bLocked = bInLocked; }

	UFUNCTION(BlueprintPure, Category = "Player") bool IsHidden() const { return HidingSpot.IsValid(); }
	UFUNCTION(BlueprintPure, Category = "Player") AActor* GetHidingSpot() const { return HidingSpot.Get(); }
	UFUNCTION(BlueprintPure, Category = "Player") bool IsTorchOn() const { return bTorchOn; }
	UFUNCTION(BlueprintPure, Category = "Player") bool IsSprinting() const { return bSprinting; }
	UFUNCTION(BlueprintPure, Category = "Player") bool IsCrouchedDF() const { return bIsCrouched; }
	/** Seconds since the last sprint (the Listener's memory counts escapes made by sprinting). */
	UFUNCTION(BlueprintPure, Category = "Player") bool SprintedRecently() const { return SprintRecent > 0.f; }

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Player") TObjectPtr<UCameraComponent> Camera;
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Player") TObjectPtr<USpotLightComponent> Torch;
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Player") TObjectPtr<UDFRadioComponent> Radio;

	UPROPERTY(BlueprintReadOnly, Category = "Player") float Health = 100.f;
	UPROPERTY(BlueprintReadOnly, Category = "Player") float Stamina = 100.f;
	/** Torch cell, 0-100. */
	UPROPERTY(BlueprintReadOnly, Category = "Player") float TorchBattery = 100.f;
	UPROPERTY(BlueprintReadWrite, Category = "Player") bool bHasTorch = false;
	/** Set by water volumes: footsteps are louder. */
	UPROPERTY(BlueprintReadWrite, Category = "Player") bool bInWater = false;

	UPROPERTY(EditDefaultsOnly, Category = "Audio") TObjectPtr<USoundBase> FootstepSound;
	UPROPERTY(EditDefaultsOnly, Category = "Audio") TObjectPtr<USoundBase> TorchClickSound;

	UPROPERTY(BlueprintAssignable) FDFOnPrompt OnPromptChanged;
	UPROPERTY(BlueprintAssignable) FDFOnDied OnDied;

	static constexpr float WalkSpeed = 270.f;
	static constexpr float SprintSpeed = 530.f;
	static constexpr float CrouchSpeed = 130.f;
	static constexpr float EyeHeight = 162.f;

protected:
	virtual void BeginPlay() override;

private:
	void BuildInput();
	void Move(const FInputActionValue& Value);
	void Look(const FInputActionValue& Value);
	void SprintOn(const FInputActionValue& Value) { bSprintHeld = true; }
	void SprintOff(const FInputActionValue& Value) { bSprintHeld = false; }
	void CrouchOn(const FInputActionValue& Value);
	void CrouchOff(const FInputActionValue& Value);
	void LeanInput(const FInputActionValue& Value) { LeanTarget = FMath::Clamp(Value.Get<float>(), -1.f, 1.f); }
	void LeanStop(const FInputActionValue& Value) { LeanTarget = 0.f; }
	void InteractPressed(const FInputActionValue& Value);
	void TorchPressed(const FInputActionValue& Value);
	void RadioPressed(const FInputActionValue& Value);
	void TuneStep(const FInputActionValue& Value);
	void TuneHeld(const FInputActionValue& Value);
	void TuneReleased(const FInputActionValue& Value);

	void UpdateInteraction();
	void Footsteps(float DeltaSeconds);
	void ReportNoise(float LoudMetres, FName Kind);

	UPROPERTY() TObjectPtr<UInputMappingContext> Mapping;
	UPROPERTY() TMap<FName, TObjectPtr<UInputAction>> Actions;

	TWeakObjectPtr<AActor> FocusActor;
	TWeakObjectPtr<AActor> HidingSpot;
	FTransform PreHide;
	FText CurrentPrompt;
	FVector2D MoveInput = FVector2D::ZeroVector;
	float Lean = 0.f;
	float LeanTarget = 0.f;
	float StepDistance = 0.f;
	float SprintRecent = 0.f;
	float HurtCooldown = 0.f;
	bool bTorchOn = false;
	bool bSprintHeld = false;
	bool bSprinting = false;
	bool bWinded = false;
	bool bLocked = false;
	bool bDead = false;
};
