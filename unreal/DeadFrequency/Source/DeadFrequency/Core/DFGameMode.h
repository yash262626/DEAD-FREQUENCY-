#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "DFGameMode.generated.h"

/**
 * One per map. Puts the player at the chapter start or the saved checkpoint (PlayerStarts tagged with the Godot
 * marker symbol; the chapter start is tagged "S"), hands the run's health, cells and tools to the pawn, and starts
 * the chapter's story once every actor has begun play (so the level's director is registered as the story's command
 * handler first).
 */
UCLASS()
class DEADFREQUENCY_API ADFGameMode : public AGameModeBase
{
	GENERATED_BODY()

public:
	ADFGameMode();

	virtual void StartPlay() override;
	virtual AActor* ChoosePlayerStart_Implementation(AController* Player) override;
	virtual void FinishRestartPlayer(AController* NewPlayer, const FRotator& StartRotation) override;

protected:
	UFUNCTION() void HandlePlayerDied();
};
