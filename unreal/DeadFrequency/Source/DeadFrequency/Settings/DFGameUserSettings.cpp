#include "Settings/DFGameUserSettings.h"

#include "DeadFrequency.h"
#include "Engine/Engine.h"
#include "HAL/IConsoleManager.h"

FDFOnSettingsApplied UDFGameUserSettings::OnApplied;

UDFGameUserSettings* UDFGameUserSettings::GetDFSettings()
{
	return GEngine ? Cast<UDFGameUserSettings>(GEngine->GetGameUserSettings()) : nullptr;
}

void UDFGameUserSettings::SetToDefaults()
{
	Super::SetToDefaults();
	Preset = 2;
	Upscaler = EDFUpscaler::TSR;
	bHardwareRayTracing = false;
	Brightness = 1.f;
	bFilmGrain = true;
	bMotionBlur = false;
	FieldOfView = 75.f;
	LookSensitivity = 1.f;
	bInvertY = false;
	bToggleCrouch = true;
	bHeadBob = true;
	bHoldToSkip = true;
	bSubtitles = true;
	SubtitleSize = 1;
	bReduceFlashes = false;
	MasterVolume = 0.9f;
	MusicVolume = 0.8f;
	EffectsVolume = 1.f;
	VoiceVolume = 1.f;
}

void UDFGameUserSettings::SetPreset(int32 InPreset)
{
	Preset = FMath::Clamp(InPreset, 0, 4);
	SetOverallScalabilityLevel(Preset);
	// hardware ray tracing is offered from Epic up; below it Lumen runs in software (or not at all on Low)
	if (Preset < 3)
	{
		bHardwareRayTracing = false;
	}
}

void UDFGameUserSettings::SetCVarInt(const TCHAR* Name, int32 Value)
{
	if (IConsoleVariable* Var = IConsoleManager::Get().FindConsoleVariable(Name))
	{
		Var->Set(Value, ECVF_SetByGameOverride);
	}
}

EDFUpscaler UDFGameUserSettings::ApplyUpscaler() const
{
	// Vendor upscalers are plugins; each is switched through its own console variable when the plugin is present.
	// The names below are those of the current NVIDIA, AMD (FSR 3) and Intel plugins: check them against the plugin
	// versions actually installed when the plugins are added to the project.
	struct FVendor
	{
		EDFUpscaler Kind;
		const TCHAR* CVar;
	};
	static const FVendor Vendors[] = {
		{ EDFUpscaler::DLSS, TEXT("r.NGX.DLSS.Enable") },
		{ EDFUpscaler::FSR, TEXT("r.FidelityFX.FSR3.Enabled") },
		{ EDFUpscaler::XeSS, TEXT("r.XeSS.Enabled") },
	};
	EDFUpscaler Used = Upscaler;
	bool bVendorFound = false;
	for (const FVendor& Vendor : Vendors)
	{
		IConsoleVariable* Var = IConsoleManager::Get().FindConsoleVariable(Vendor.CVar);
		if (Vendor.Kind == Upscaler)
		{
			bVendorFound = Var != nullptr;
		}
		if (Var)
		{
			Var->Set(Vendor.Kind == Upscaler ? 1 : 0, ECVF_SetByGameOverride);
		}
	}
	if ((Upscaler == EDFUpscaler::DLSS || Upscaler == EDFUpscaler::FSR || Upscaler == EDFUpscaler::XeSS) && !bVendorFound)
	{
		UE_LOG(LogDeadFrequency, Warning, TEXT("Settings: upscaler plugin %d is not in this build; using TSR"), static_cast<int32>(Upscaler));
		Used = EDFUpscaler::TSR;
	}
	// r.AntiAliasingMethod: 2 = TAA, 4 = TSR (vendor upscalers sit on top of the temporal pipeline)
	SetCVarInt(TEXT("r.AntiAliasingMethod"), Used == EDFUpscaler::TAA ? 2 : 4);
	return Used;
}

void UDFGameUserSettings::ApplyNonResolutionSettings()
{
	Super::ApplyNonResolutionSettings();          // scalability groups, frame limit, V-Sync, render scale
	ApplyUpscaler();
	SetCVarInt(TEXT("r.Lumen.HardwareRayTracing"), bHardwareRayTracing && GetGlobalIlluminationQuality() >= 3 ? 1 : 0);
	SetCVarInt(TEXT("r.MotionBlurQuality"), bMotionBlur ? 4 : 0);
	OnApplied.Broadcast();
}
