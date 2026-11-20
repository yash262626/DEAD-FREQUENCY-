#include "Core/DFGameMode.h"

#include "Core/DFGameInstance.h"
#include "EngineUtils.h"
#include "GameFramework/PlayerStart.h"
#include "Kismet/GameplayStatics.h"
#include "Player/DFPlayerCharacter.h"
#include "Story/DFStorySubsystem.h"

ADFGameMode::ADFGameMode()
{
	// the production pawn is a Blueprint subclass (meshes, sounds); set it in a BP game mode or here once it exists
	DefaultPawnClass = ADFPlayerCharacter::StaticClass();
}

AActor* ADFGameMode::ChoosePlayerStart_Implementation(AController* Player)
{
	const UDFStorySubsystem* Story = GetGameInstance() ? GetGameInstance()->GetSubsystem<UDFStorySubsystem>() : nullptr;
	const FString Checkpoint = Story ? Story->Checkpoint : FString();
	APlayerStart* Start = nullptr;
	for (TActorIterator<APlayerStart> It(GetWorld()); It; ++It)
	{
		const FString Tag = It->PlayerStartTag.ToString();
		if (!Checkpoint.IsEmpty() && Tag == Checkpoint)
		{
			return *It;                                  // the saved checkpoint
		}
		if (Tag == TEXT("S") && !Start)
		{
			Start = *It;                                 // the chapter start (the Godot "S" marker)
		}
	}
	return Start ? Start : Super::ChoosePlayerStart_Implementation(Player);
}

void ADFGameMode::FinishRestartPlayer(AController* NewPlayer, const FRotator& StartRotation)
{
	Super::FinishRestartPlayer(NewPlayer, StartRotation);
	ADFPlayerCharacter* Player = NewPlayer ? Cast<ADFPlayerCharacter>(NewPlayer->GetPawn()) : nullptr;
	if (!Player)
	{
		return;
	}
	if (const UDFGameInstance* GI = GetGameInstance<UDFGameInstance>())
	{
		GI->ApplyRunToPlayer(Player);
	}
	Player->OnDied.AddUniqueDynamic(this, &ADFGameMode::HandlePlayerDied);
}

void ADFGameMode::StartPlay()
{
	Super::StartPlay();                                  // every actor's BeginPlay has run after this
	if (UDFGameInstance* GI = GetGameInstance<UDFGameInstance>())
	{
		ADFPlayerCharacter* Player = Cast<ADFPlayerCharacter>(UGameplayStatics::GetPlayerPawn(this, 0));
		GI->BeginStoryInWorld(Player, UGameplayStatics::GetCurrentLevelName(this, true));
	}
}

void ADFGameMode::HandlePlayerDied()
{
	if (UDFGameInstance* GI = GetGameInstance<UDFGameInstance>())
	{
		GI->OnPlayerDied();
	}
}
