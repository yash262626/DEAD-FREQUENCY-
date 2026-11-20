#pragma once

#include "CoreMinimal.h"

DECLARE_LOG_CATEGORY_EXTERN(LogDeadFrequency, Log, All);

/** Godot used metres; Unreal uses centimetres. Every distance ported from the Godot game goes through this. */
constexpr float DF_METRES = 100.f;

/**
 * Reports a noise the Listener can hear, with the Godot game's semantics: LoudMetres is how far it carries
 * (footsteps 5 m, sprinting 12.5 m, the radio carrier 8-15 m...), Kind is Step, Radio, Door, Click or Object.
 * Unreal's hearing sense multiplies MaxRange by the event's loudness, so loudness stays 1 and the Godot loudness
 * travels in the tag ("Radio:11.0").
 */
DEADFREQUENCY_API void DFReportNoise(UWorld* World, const FVector& Where, float LoudMetres, AActor* Instigator, FName Kind, float RangeMultiplier = 1.f);

/** Reads a tag written by DFReportNoise. */
DEADFREQUENCY_API bool DFParseNoiseTag(FName Tag, FName& OutKind, float& OutLoudMetres);
