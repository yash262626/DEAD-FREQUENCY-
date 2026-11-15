#pragma once

#include "CoreMinimal.h"

DECLARE_LOG_CATEGORY_EXTERN(LogDeadFrequency, Log, All);

/** Godot used metres; Unreal uses centimetres. Every distance ported from the Godot game goes through this. */
constexpr float DF_METRES = 100.f;
