#include "AI/DFListenerCharacter.h"

#include "Components/CapsuleComponent.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Kismet/GameplayStatics.h"
#include "Player/DFPlayerCharacter.h"
#include "Radio/DFRadioComponent.h"

ADFListenerCharacter::ADFListenerCharacter()
{
	PrimaryActorTick.bCanEverTick = true;
	AIControllerClass = ADFListenerController::StaticClass();
	AutoPossessAI = EAutoPossessAI::PlacedInWorldOrSpawned;

	GetCapsuleComponent()->InitCapsuleSize(40.f, 115.f);
	bUseControllerRotationYaw = false;
	UCharacterMovementComponent* Move = GetCharacterMovement();
	Move->bOrientRotationToMovement = true;
	Move->RotationRate = FRotator(0.f, 240.f, 0.f);
	Move->MaxWalkSpeed = 150.f;
	Move->NavAgentProps.bCanCrouch = true;          // vents
}

void ADFListenerCharacter::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);
	if (!bCloaked)
	{
		if (!bShown)
		{
			bShown = true;
			SetActorHiddenInGame(false);
		}
		return;
	}
	// cloaked: seen only on 107.9 or at arm's length (the reveal itself is a stencil post-process on the mesh)
	const ADFPlayerCharacter* Player = Cast<ADFPlayerCharacter>(UGameplayStatics::GetPlayerPawn(this, 0));
	const bool bReveal = Player && (Player->Radio->bRevealOn || FVector::Dist(Player->GetActorLocation(), GetActorLocation()) < 220.f);
	if (bReveal != bShown)
	{
		bShown = bReveal;
		SetActorHiddenInGame(!bShown);
	}
}
