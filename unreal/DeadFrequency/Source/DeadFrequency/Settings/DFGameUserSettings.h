#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameUserSettings.h"
#include "DFGameUserSettings.generated.h"

UENUM(BlueprintType)
enum class EDFUpscaler : uint8
{
	TSR,
	/** NVIDIA DLSS: needs the NVIDIA plugin in the project; falls back to TSR without it. */
	DLSS,
	/** AMD FSR: needs the AMD plugin; falls back to TSR without it. */
	FSR,
	/** Intel XeSS: needs the Intel plugin; falls back to TSR without it. */
	XeSS,
	/** Plain temporal AA at the render scale (no upscaler). */
	TAA
};

DECLARE_MULTICAST_DELEGATE(FDFOnSettingsApplied);

/**
 * Graphics, controls, accessibility and audio settings, saved in GameUserSettings.ini. The five presets are Unreal's
 * scalability levels (0 Low, 1 Medium, 2 High, 3 Epic, 4 Cinematic); the Godot game's individual options map onto
 * the scalability groups (shadows, global illumination, reflections, post-processing, textures, view distance,
 * effects), plus the upscaler, hardware ray tracing, frame limit, V-Sync, render scale and display mode that the base
 * class already stores. Nothing here is measured yet: preset costs come from profiling on the target PC.
 */
UCLASS()
class DEADFREQUENCY_API UDFGameUserSettings : public UGameUserSettings
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintPure, Category = "Settings", meta = (DisplayName = "Get DF Settings"))
	static UDFGameUserSettings* GetDFSettings();

	/** Set every scalability group from one preset (0-4). The options menu then calls ApplySettings(false). */
	UFUNCTION(BlueprintCallable, Category = "Settings")
	void SetPreset(int32 InPreset);

	virtual void SetToDefaults() override;
	virtual void ApplyNonResolutionSettings() override;

	/** Fired after settings are applied (the player re-reads field of view, look and brightness). */
	static FDFOnSettingsApplied OnApplied;

	/** 0-4, or -1 once a single group was changed by hand ("Custom"). */
	UPROPERTY(Config, BlueprintReadWrite, Category = "Graphics") int32 Preset = 2;
	UPROPERTY(Config, BlueprintReadWrite, Category = "Graphics") EDFUpscaler Upscaler = EDFUpscaler::TSR;
	/** Lumen with hardware ray tracing on Epic and Cinematic (RTX 20 / RX 6000 and newer). Off: software Lumen. */
	UPROPERTY(Config, BlueprintReadWrite, Category = "Graphics") bool bHardwareRayTracing = false;
	UPROPERTY(Config, BlueprintReadWrite, Category = "Graphics") float Brightness = 1.f;
	UPROPERTY(Config, BlueprintReadWrite, Category = "Graphics") bool bFilmGrain = true;
	UPROPERTY(Config, BlueprintReadWrite, Category = "Graphics") bool bMotionBlur = false;

	UPROPERTY(Config, BlueprintReadWrite, Category = "Controls") float FieldOfView = 75.f;
	UPROPERTY(Config, BlueprintReadWrite, Category = "Controls") float LookSensitivity = 1.f;
	UPROPERTY(Config, BlueprintReadWrite, Category = "Controls") bool bInvertY = false;
	UPROPERTY(Config, BlueprintReadWrite, Category = "Controls") bool bToggleCrouch = true;
	UPROPERTY(Config, BlueprintReadWrite, Category = "Controls") bool bHeadBob = true;
	UPROPERTY(Config, BlueprintReadWrite, Category = "Controls") bool bHoldToSkip = true;

	UPROPERTY(Config, BlueprintReadWrite, Category = "Accessibility") bool bSubtitles = true;
	/** 0 small, 1 medium, 2 large, 3 extra large. */
	UPROPERTY(Config, BlueprintReadWrite, Category = "Accessibility") int32 SubtitleSize = 1;
	UPROPERTY(Config, BlueprintReadWrite, Category = "Accessibility") bool bReduceFlashes = false;

	/** Applied through the game's sound mix (built with the audio pass). */
	UPROPERTY(Config, BlueprintReadWrite, Category = "Audio") float MasterVolume = 0.9f;
	UPROPERTY(Config, BlueprintReadWrite, Category = "Audio") float MusicVolume = 0.8f;
	UPROPERTY(Config, BlueprintReadWrite, Category = "Audio") float EffectsVolume = 1.f;
	UPROPERTY(Config, BlueprintReadWrite, Category = "Audio") float VoiceVolume = 1.f;

private:
	static void SetCVarInt(const TCHAR* Name, int32 Value);
	EDFUpscaler ApplyUpscaler() const;
};
