#include "Player/DFPlayerCharacter.h"

#include "Camera/CameraComponent.h"
#include "Components/CapsuleComponent.h"
#include "Components/SpotLightComponent.h"
#include "DeadFrequency.h"
#include "EnhancedInputComponent.h"
#include "EnhancedInputSubsystems.h"
#include "Engine/GameInstance.h"
#include "Engine/LocalPlayer.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/PlayerController.h"
#include "InputAction.h"
#include "InputMappingContext.h"
#include "InputModifiers.h"
#include "Kismet/GameplayStatics.h"
#include "Perception/AISense_Hearing.h"
#include "Player/DFInteractable.h"
#include "Radio/DFRadioComponent.h"
#include "Story/DFStorySubsystem.h"

ADFPlayerCharacter::ADFPlayerCharacter()
{
	PrimaryActorTick.bCanEverTick = true;

	GetCapsuleComponent()->InitCapsuleSize(34.f, 88.f);
	UCharacterMovementComponent* Move = GetCharacterMovement();
	Move->MaxWalkSpeed = WalkSpeed;
	Move->MaxWalkSpeedCrouched = CrouchSpeed;
	Move->NavAgentProps.bCanCrouch = true;
	Move->BrakingDecelerationWalking = 1600.f;
	BaseEyeHeight = EyeHeight - 88.f;
	CrouchedEyeHeight = (EyeHeight - 88.f) * 0.55f;

	Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("Camera"));
	Camera->SetupAttachment(GetCapsuleComponent());
	Camera->SetRelativeLocation(FVector(0.f, 0.f, EyeHeight - 88.f));
	Camera->bUsePawnControlRotation = true;
	Camera->SetFieldOfView(75.f);

	// the torch: hot core inside a wider spill, shadowed, scattering in the volumetric fog
	Torch = CreateDefaultSubobject<USpotLightComponent>(TEXT("Torch"));
	Torch->SetupAttachment(Camera);
	Torch->SetRelativeLocation(FVector(30.f, 12.f, -11.f));
	Torch->SetIntensityUnits(ELightUnits::Lumens);
	Torch->SetIntensity(0.f);
	Torch->SetLightColor(FLinearColor(1.f, 0.95f, 0.85f));
	Torch->SetInnerConeAngle(10.f);
	Torch->SetOuterConeAngle(28.f);
	Torch->SetAttenuationRadius(2200.f);
	Torch->SetVolumetricScatteringIntensity(1.6f);
	Torch->SetCastShadows(true);

	Radio = CreateDefaultSubobject<UDFRadioComponent>(TEXT("Radio"));

	bUseControllerRotationYaw = true;
}

void ADFPlayerCharacter::BeginPlay()
{
	Super::BeginPlay();
	BuildInput();
}

// ------------------------------------------------------------------------------------------------ input (in code)

void ADFPlayerCharacter::BuildInput()
{
	if (Mapping)
	{
		return;
	}
	Mapping = NewObject<UInputMappingContext>(this, TEXT("IMC_Player"));
	auto MakeAction = [this](const TCHAR* Name, EInputActionValueType Type) -> UInputAction*
	{
		UInputAction* Action = NewObject<UInputAction>(this, FName(Name));
		Action->ValueType = Type;
		Actions.Add(FName(Name), Action);
		return Action;
	};
	auto Map = [this](UInputAction* Action, FKey Key, bool bNegate = false, bool bSwizzle = false) -> FEnhancedActionKeyMapping&
	{
		FEnhancedActionKeyMapping& M = Mapping->MapKey(Action, Key);
		if (bSwizzle)
		{
			UInputModifierSwizzleAxis* Swizzle = NewObject<UInputModifierSwizzleAxis>(this);
			Swizzle->Order = EInputAxisSwizzle::YXZ;
			M.Modifiers.Add(Swizzle);
		}
		if (bNegate)
		{
			M.Modifiers.Add(NewObject<UInputModifierNegate>(this));
		}
		return M;
	};

	UInputAction* Move = MakeAction(TEXT("IA_Move"), EInputActionValueType::Axis2D);
	Map(Move, EKeys::W, false, true);
	Map(Move, EKeys::S, true, true);
	Map(Move, EKeys::A, true);
	Map(Move, EKeys::D);
	Map(Move, EKeys::Gamepad_Left2D);

	UInputAction* Look = MakeAction(TEXT("IA_Look"), EInputActionValueType::Axis2D);
	FEnhancedActionKeyMapping& Mouse = Mapping->MapKey(Look, EKeys::Mouse2D);
	UInputModifierNegate* NegateY = NewObject<UInputModifierNegate>(this);
	NegateY->bX = false;
	NegateY->bZ = false;
	Mouse.Modifiers.Add(NegateY);
	Map(Look, EKeys::Gamepad_Right2D);

	UInputAction* Sprint = MakeAction(TEXT("IA_Sprint"), EInputActionValueType::Boolean);
	Map(Sprint, EKeys::LeftShift);
	Map(Sprint, EKeys::Gamepad_LeftThumbstick);

	UInputAction* Crouch = MakeAction(TEXT("IA_Crouch"), EInputActionValueType::Boolean);
	Map(Crouch, EKeys::LeftControl);
	Map(Crouch, EKeys::C);
	Map(Crouch, EKeys::Gamepad_FaceButton_Right);

	UInputAction* LeanAction = MakeAction(TEXT("IA_Lean"), EInputActionValueType::Axis1D);
	Map(LeanAction, EKeys::Q, true);
	Map(LeanAction, EKeys::E);
	Map(LeanAction, EKeys::Gamepad_LeftShoulder, true);
	Map(LeanAction, EKeys::Gamepad_RightShoulder);

	UInputAction* Interact = MakeAction(TEXT("IA_Interact"), EInputActionValueType::Boolean);
	Map(Interact, EKeys::F);
	Map(Interact, EKeys::LeftMouseButton);
	Map(Interact, EKeys::Gamepad_FaceButton_Bottom);

	UInputAction* TorchAction = MakeAction(TEXT("IA_Torch"), EInputActionValueType::Boolean);
	Map(TorchAction, EKeys::T);
	Map(TorchAction, EKeys::MiddleMouseButton);
	Map(TorchAction, EKeys::Gamepad_FaceButton_Top);

	UInputAction* RadioAction = MakeAction(TEXT("IA_Radio"), EInputActionValueType::Boolean);
	Map(RadioAction, EKeys::R);
	Map(RadioAction, EKeys::RightMouseButton);
	Map(RadioAction, EKeys::Gamepad_FaceButton_Left);

	UInputAction* Wheel = MakeAction(TEXT("IA_TuneWheel"), EInputActionValueType::Axis1D);
	Map(Wheel, EKeys::MouseWheelAxis);

	UInputAction* TuneKeys = MakeAction(TEXT("IA_Tune"), EInputActionValueType::Axis1D);
	Map(TuneKeys, EKeys::Right);
	Map(TuneKeys, EKeys::Left, true);
	Map(TuneKeys, EKeys::Gamepad_DPad_Right);
	Map(TuneKeys, EKeys::Gamepad_DPad_Left, true);
}

void ADFPlayerCharacter::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);
	BuildInput();

	if (const APlayerController* PC = Cast<APlayerController>(GetController()))
	{
		if (UEnhancedInputLocalPlayerSubsystem* Sub = ULocalPlayer::GetSubsystem<UEnhancedInputLocalPlayerSubsystem>(PC->GetLocalPlayer()))
		{
			Sub->AddMappingContext(Mapping, 0);
		}
	}
	UEnhancedInputComponent* Input = Cast<UEnhancedInputComponent>(PlayerInputComponent);
	if (!Input)
	{
		UE_LOG(LogDeadFrequency, Error, TEXT("Player: Enhanced Input is not the input component class (Config/DefaultInput.ini)"));
		return;
	}
	Input->BindAction(Actions[TEXT("IA_Move")], ETriggerEvent::Triggered, this, &ADFPlayerCharacter::Move);
	Input->BindAction(Actions[TEXT("IA_Move")], ETriggerEvent::Completed, this, &ADFPlayerCharacter::Move);
	Input->BindAction(Actions[TEXT("IA_Look")], ETriggerEvent::Triggered, this, &ADFPlayerCharacter::Look);
	Input->BindAction(Actions[TEXT("IA_Sprint")], ETriggerEvent::Started, this, &ADFPlayerCharacter::SprintOn);
	Input->BindAction(Actions[TEXT("IA_Sprint")], ETriggerEvent::Completed, this, &ADFPlayerCharacter::SprintOff);
	Input->BindAction(Actions[TEXT("IA_Crouch")], ETriggerEvent::Started, this, &ADFPlayerCharacter::CrouchOn);
	Input->BindAction(Actions[TEXT("IA_Crouch")], ETriggerEvent::Completed, this, &ADFPlayerCharacter::CrouchOff);
	Input->BindAction(Actions[TEXT("IA_Lean")], ETriggerEvent::Triggered, this, &ADFPlayerCharacter::LeanInput);
	Input->BindAction(Actions[TEXT("IA_Lean")], ETriggerEvent::Completed, this, &ADFPlayerCharacter::LeanStop);
	Input->BindAction(Actions[TEXT("IA_Interact")], ETriggerEvent::Started, this, &ADFPlayerCharacter::InteractPressed);
	Input->BindAction(Actions[TEXT("IA_Torch")], ETriggerEvent::Started, this, &ADFPlayerCharacter::TorchPressed);
	Input->BindAction(Actions[TEXT("IA_Radio")], ETriggerEvent::Started, this, &ADFPlayerCharacter::RadioPressed);
	Input->BindAction(Actions[TEXT("IA_TuneWheel")], ETriggerEvent::Triggered, this, &ADFPlayerCharacter::TuneStep);
	Input->BindAction(Actions[TEXT("IA_Tune")], ETriggerEvent::Started, this, &ADFPlayerCharacter::TuneStep);
	Input->BindAction(Actions[TEXT("IA_Tune")], ETriggerEvent::Triggered, this, &ADFPlayerCharacter::TuneHeld);
	Input->BindAction(Actions[TEXT("IA_Tune")], ETriggerEvent::Completed, this, &ADFPlayerCharacter::TuneReleased);
}

void ADFPlayerCharacter::Move(const FInputActionValue& Value)
{
	MoveInput = (bLocked || IsHidden()) ? FVector2D::ZeroVector : Value.Get<FVector2D>();
}

void ADFPlayerCharacter::Look(const FInputActionValue& Value)
{
	if (bLocked)
	{
		return;
	}
	const FVector2D Axis = Value.Get<FVector2D>();
	AddControllerYawInput(Axis.X);
	AddControllerPitchInput(Axis.Y);
}

void ADFPlayerCharacter::CrouchOn(const FInputActionValue& Value)
{
	if (!bLocked && !IsHidden())
	{
		Crouch();
	}
}

void ADFPlayerCharacter::CrouchOff(const FInputActionValue& Value)
{
	UnCrouch();
}

void ADFPlayerCharacter::InteractPressed(const FInputActionValue& Value)
{
	if (bLocked)
	{
		return;
	}
	if (IsHidden())
	{
		ExitHiding();
		return;
	}
	if (AActor* Target = FocusActor.Get())
	{
		IDFInteractable::Execute_Interact(Target, this);
	}
}

void ADFPlayerCharacter::TorchPressed(const FInputActionValue& Value)
{
	if (bLocked || !bHasTorch)
	{
		return;
	}
	const UGameInstance* GI = GetGameInstance();
	UDFStorySubsystem* Story = GI ? GI->GetSubsystem<UDFStorySubsystem>() : nullptr;
	if (!bTorchOn && TorchBattery <= 0.f && !(Story && Story->Count(TEXT("battery")) > 0))
	{
		return;                                          // "Flashlight cell is dead."
	}
	bTorchOn = !bTorchOn;
	if (TorchClickSound)
	{
		UGameplayStatics::PlaySoundAtLocation(this, TorchClickSound, GetActorLocation());
	}
	ReportNoise(2.f, TEXT("Click"));
}

void ADFPlayerCharacter::RadioPressed(const FInputActionValue& Value)
{
	if (!bLocked)
	{
		Radio->Toggle();
	}
}

void ADFPlayerCharacter::TuneStep(const FInputActionValue& Value)
{
	if (!bLocked)
	{
		Radio->Tune(Value.Get<float>());
	}
}

void ADFPlayerCharacter::TuneHeld(const FInputActionValue& Value)
{
	Radio->SetTuneHeld(bLocked ? 0.f : Value.Get<float>());
}

void ADFPlayerCharacter::TuneReleased(const FInputActionValue& Value)
{
	Radio->SetTuneHeld(0.f);
}

// ------------------------------------------------------------------------------------------------ per frame

void ADFPlayerCharacter::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);
	if (bDead)
	{
		return;
	}
	HurtCooldown = FMath::Max(0.f, HurtCooldown - DeltaSeconds);
	SprintRecent = FMath::Max(0.f, SprintRecent - DeltaSeconds);

	// movement relative to where the player looks
	if (!MoveInput.IsNearlyZero())
	{
		const FRotator Yaw(0.f, GetControlRotation().Yaw, 0.f);
		AddMovementInput(FRotationMatrix(Yaw).GetUnitAxis(EAxis::X), MoveInput.Y);
		AddMovementInput(FRotationMatrix(Yaw).GetUnitAxis(EAxis::Y), MoveInput.X);
	}

	// sprint and stamina
	bSprinting = bSprintHeld && MoveInput.Y > 0.2f && !bIsCrouched && !bWinded && !bLocked && !IsHidden();
	if (bSprinting)
	{
		SprintRecent = 3.f;
		Stamina -= DeltaSeconds * 16.f;
		if (Stamina <= 0.f)
		{
			Stamina = 0.f;
			bWinded = true;
		}
	}
	else
	{
		Stamina = FMath::Min(100.f, Stamina + DeltaSeconds * (MoveInput.Size() > 0.1f ? 9.f : 15.f));
		if (bWinded && Stamina > 30.f)
		{
			bWinded = false;
		}
	}
	GetCharacterMovement()->MaxWalkSpeed = bSprinting ? SprintSpeed : WalkSpeed;

	// lean: the head slides 42 cm and rolls 12.6 degrees
	Lean = FMath::FInterpTo(Lean, IsHidden() ? 0.f : LeanTarget, DeltaSeconds, 8.f);
	// BaseEyeHeight is relative to the capsule centre; ACharacter switches it to CrouchedEyeHeight while crouched
	Camera->SetRelativeLocation(FVector(0.f, Lean * 42.f, BaseEyeHeight));
	if (AController* C = GetController())
	{
		FRotator R = C->GetControlRotation();
		R.Roll = Lean * 12.6f;
		C->SetControlRotation(R);
	}

	// torch: a cell lasts 260 s; replaced from the inventory; it flickers when the cell is low
	float TargetLumens = 0.f;
	if (bTorchOn)
	{
		TorchBattery -= DeltaSeconds * (100.f / 260.f);
		if (TorchBattery <= 0.f)
		{
			const UGameInstance* GI = GetGameInstance();
			UDFStorySubsystem* Story = GI ? GI->GetSubsystem<UDFStorySubsystem>() : nullptr;
			if (Story && Story->Take(TEXT("battery")))
			{
				TorchBattery = 100.f;
			}
			else
			{
				TorchBattery = 0.f;
				bTorchOn = false;
			}
		}
		TargetLumens = 900.f * (TorchBattery > 12.f ? 1.f : FMath::FRandRange(0.5f, 1.f));
	}
	Torch->SetIntensity(FMath::Lerp(Torch->Intensity, TargetLumens, 0.4f));

	Footsteps(DeltaSeconds);
	UpdateInteraction();
}

void ADFPlayerCharacter::Footsteps(float DeltaSeconds)
{
	const float Speed = GetVelocity().Size2D();
	if (Speed < 50.f || !GetCharacterMovement()->IsMovingOnGround())
	{
		return;
	}
	StepDistance += Speed * DeltaSeconds;
	if (StepDistance > (bSprinting ? 230.f : 190.f))
	{
		StepDistance = 0.f;
		float Loud = bSprinting ? 12.5f : (bIsCrouched ? 1.3f : 5.f);
		if (bInWater)
		{
			Loud *= 1.5f;
		}
		if (FootstepSound)
		{
			UGameplayStatics::PlaySoundAtLocation(this, FootstepSound, GetActorLocation(), bIsCrouched ? 0.35f : (bSprinting ? 1.f : 0.6f));
		}
		ReportNoise(Loud, TEXT("Step"));
	}
}

void ADFPlayerCharacter::ReportNoise(float LoudMetres, FName Kind)
{
	UAISense_Hearing::ReportNoiseEvent(GetWorld(), GetActorLocation(), LoudMetres, this, LoudMetres * DF_METRES, Kind);
}

void ADFPlayerCharacter::UpdateInteraction()
{
	AActor* Found = nullptr;
	FText Prompt;
	if (!bLocked && !IsHidden())
	{
		const FVector Start = Camera->GetComponentLocation();
		const FVector End = Start + Camera->GetForwardVector() * 270.f;
		FHitResult Hit;
		FCollisionQueryParams Params(SCENE_QUERY_STAT(DFInteract), false, this);
		if (GetWorld()->LineTraceSingleByChannel(Hit, Start, End, ECC_Visibility, Params))
		{
			AActor* A = Hit.GetActor();
			if (A && A->GetClass()->ImplementsInterface(UDFInteractable::StaticClass()))
			{
				Prompt = IDFInteractable::Execute_GetPrompt(A, this);
				if (!Prompt.IsEmpty())
				{
					Found = A;
				}
			}
		}
	}
	else if (IsHidden())
	{
		Prompt = NSLOCTEXT("DeadFrequency", "ComeOut", "Come out");
	}
	FocusActor = Found;
	if (!Prompt.EqualTo(CurrentPrompt))
	{
		CurrentPrompt = Prompt;
		OnPromptChanged.Broadcast(CurrentPrompt);
	}
}

// ------------------------------------------------------------------------------------------------ hiding, harm

void ADFPlayerCharacter::EnterHiding(AActor* Spot)
{
	if (!Spot || !Spot->GetClass()->ImplementsInterface(UDFHidingSpot::StaticClass()))
	{
		return;
	}
	PreHide = GetActorTransform();
	HidingSpot = Spot;
	UnCrouch();
	bTorchOn = false;
	const FTransform Eye = IDFHidingSpot::Execute_GetEyeTransform(Spot);
	SetActorLocation(Eye.GetLocation() - FVector(0.f, 0.f, Camera->GetRelativeLocation().Z));
	if (AController* C = GetController())
	{
		C->SetControlRotation(Eye.Rotator());
	}
	GetCharacterMovement()->DisableMovement();
	ReportNoise(4.f, TEXT("Door"));

	// the Listener checks the places you use most (Godot: G.flags["m_hide_<uid>"])
	if (const UGameInstance* GI = GetGameInstance())
	{
		if (UDFStorySubsystem* Story = GI->GetSubsystem<UDFStorySubsystem>())
		{
			const FName Key(*(TEXT("m_hide_") + IDFHidingSpot::Execute_GetHidingId(Spot).ToString()));
			Story->SetFlag(Key, Story->GetFlag(Key) + 1);
		}
	}
}

void ADFPlayerCharacter::ExitHiding()
{
	if (!IsHidden())
	{
		return;
	}
	HidingSpot = nullptr;
	SetActorTransform(PreHide);
	GetCharacterMovement()->SetMovementMode(MOVE_Walking);
	ReportNoise(4.f, TEXT("Door"));
}

void ADFPlayerCharacter::Hurt(float Amount)
{
	if (bDead || HurtCooldown > 0.f)
	{
		return;
	}
	HurtCooldown = 1.5f;
	Health -= Amount;
	if (Health <= 0.f)
	{
		Health = 0.f;
		bDead = true;
		bTorchOn = false;
		GetCharacterMovement()->DisableMovement();
		OnDied.Broadcast();
	}
}
