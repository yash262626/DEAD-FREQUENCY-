using UnrealBuildTool;

public class DeadFrequencyEditorTarget : TargetRules
{
	public DeadFrequencyEditorTarget(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Editor;
		DefaultBuildSettings = BuildSettingsVersion.Latest;
		IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
		ExtraModuleNames.Add("DeadFrequency");
	}
}
