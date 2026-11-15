#include "DeadFrequency.h"

#include "Modules/ModuleManager.h"
#include "Perception/AISense_Hearing.h"

DEFINE_LOG_CATEGORY(LogDeadFrequency);

IMPLEMENT_PRIMARY_GAME_MODULE(FDefaultGameModuleImpl, DeadFrequency, "DeadFrequency");

void DFReportNoise(UWorld* World, const FVector& Where, float LoudMetres, AActor* Instigator, FName Kind, float RangeMultiplier)
{
	if (!World || LoudMetres <= 0.f)
	{
		return;
	}
	const FName Tag(*FString::Printf(TEXT("%s:%.2f"), *Kind.ToString(), LoudMetres));
	UAISense_Hearing::ReportNoiseEvent(World, Where, 1.f, Instigator, LoudMetres * RangeMultiplier * DF_METRES, Tag);
}

bool DFParseNoiseTag(FName Tag, FName& OutKind, float& OutLoudMetres)
{
	FString Kind, Loud;
	if (!Tag.ToString().Split(TEXT(":"), &Kind, &Loud))
	{
		return false;
	}
	OutKind = FName(*Kind);
	OutLoudMetres = FCString::Atof(*Loud);
	return true;
}
