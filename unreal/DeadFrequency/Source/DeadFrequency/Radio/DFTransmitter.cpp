#include "Radio/DFTransmitter.h"

#include "DeadFrequency.h"
#include "Engine/GameInstance.h"
#include "Kismet/GameplayStatics.h"
#include "Story/DFStorySubsystem.h"

TArray<TWeakObjectPtr<ADFTransmitter>> ADFTransmitter::Registry;

ADFTransmitter::ADFTransmitter()
{
	PrimaryActorTick.bCanEverTick = false;
	RootComponent = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
}

void ADFTransmitter::BeginPlay()
{
	Super::BeginPlay();
	Registry.RemoveAll([](const TWeakObjectPtr<ADFTransmitter>& T) { return !T.IsValid(); });
	Registry.Add(this);

	const UGameInstance* GI = GetGameInstance();
	const UDFStorySubsystem* Story = GI ? GI->GetSubsystem<UDFStorySubsystem>() : nullptr;
	const FDFChapterData* Data = Story ? Story->GetChapter(Chapter) : nullptr;
	const FDFLegendEntry* Entry = Data ? Data->FindLegend(Symbol) : nullptr;
	if (!Entry)
	{
		UE_LOG(LogDeadFrequency, Warning, TEXT("Transmitter %s: no legend entry '%s' in %s"), *GetName(), *Symbol, *Chapter);
		return;
	}
	Frequency = FCString::Atof(*Entry->Prop(TEXT("f"), TEXT("89.1")));
	Range = FCString::Atof(*Entry->Prop(TEXT("r"), TEXT("14"))) * DF_METRES;
	Title = Entry->Prop(TEXT("title"));
	Condition = Entry->Prop(TEXT("if"));
	ConditionNot = Entry->Prop(TEXT("ifnot"));
	Flag = Entry->Prop(TEXT("flag"));
	bDone = Story->HasFlag(FName(*(TEXT("u:") + Chapter + TEXT(":") + Symbol)));
}

void ADFTransmitter::EndPlay(const EEndPlayReason::Type Reason)
{
	Registry.Remove(this);
	Super::EndPlay(Reason);
}

bool ADFTransmitter::IsActive() const
{
	if (bDone)
	{
		return false;
	}
	const UGameInstance* GI = GetGameInstance();
	const UDFStorySubsystem* Story = GI ? GI->GetSubsystem<UDFStorySubsystem>() : nullptr;
	if (!Story)
	{
		return false;
	}
	if (!Condition.IsEmpty() && !Story->HasFlag(FName(*Condition)))
	{
		return false;
	}
	if (!ConditionNot.IsEmpty() && Story->HasFlag(FName(*ConditionNot)))
	{
		return false;
	}
	return true;
}

void ADFTransmitter::Receive()
{
	UGameInstance* GI = GetGameInstance();
	UDFStorySubsystem* Story = GI ? GI->GetSubsystem<UDFStorySubsystem>() : nullptr;
	if (!Story || bDone)
	{
		return;
	}
	bDone = true;
	Story->SetFlag(FName(*(TEXT("u:") + Chapter + TEXT(":") + Symbol)));
	if (!Flag.IsEmpty())
	{
		Story->SetFlag(FName(*Flag));
	}
	// the journal keeps the transcript of a titled transmission (Godot radio._receive)
	const FDFChapterData* Data = Story->GetChapter(Chapter);
	const FDFLegendEntry* Entry = Data ? Data->FindLegend(Symbol) : nullptr;
	if (Entry && !Title.IsEmpty())
	{
		FString Transcript;
		if (const FDFStorySequence* Lines = Story->GetSequence(Chapter, Entry->Lines))
		{
			for (const FDFStoryStep& Step : Lines->Steps)
			{
				if (Step.Command == TEXT("line") && !Step.Arg(0).IsEmpty())
				{
					Transcript += FString::Printf(TEXT("%s: %s\n\n"), *Step.Arg(0), *Step.Arg(1));
				}
			}
		}
		FDFJournalEntry Journal;
		Journal.Title = FString::Printf(TEXT("%.1f MHz - %s"), Frequency, *Title);
		Journal.Text = Transcript;
		Journal.Kind = TEXT("tape");
		Story->Journal.Add(Journal);
		Story->OnJournal.Broadcast(Journal);
	}
	Story->RunLegendEntry(Chapter, Symbol);
}
