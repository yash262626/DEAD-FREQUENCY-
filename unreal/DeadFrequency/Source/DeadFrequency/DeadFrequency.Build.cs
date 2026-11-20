using UnrealBuildTool;

public class DeadFrequency : ModuleRules
{
	public DeadFrequency(ReadOnlyTargetRules Target) : base(Target)
	{
		PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;
		PublicDependencyModuleNames.AddRange(new string[]
		{
			"Core", "CoreUObject", "Engine", "InputCore", "EnhancedInput",
			"AIModule", "GameplayTasks", "NavigationSystem",
			"Json", "JsonUtilities",
			"UMG", "Slate", "SlateCore"
		});
	}
}
