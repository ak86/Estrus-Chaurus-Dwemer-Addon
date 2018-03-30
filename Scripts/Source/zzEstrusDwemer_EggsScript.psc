Scriptname zzEstrusDwemer_EggsScript extends ObjectReference

;not used in ED as there no hatchings yet

ActorBase					Property zzEstrusDwemerHachling Auto
ImpactDataSet				Property MAGSpiderSpitImpactSet Auto
zzEstrusDwemer_MCMScript	Property MCM Auto

Bool bIsTested				= False
Actor DwemerHachling		= None
Float fUpdate				= 0.0
Int iIncubationIdx			= 0
ObjectReference kContainer	= none

function hatch()
	PlayImpactEffect(MAGSpiderSpitImpactSet, "Egg:0")
	if !kContainer
		DwemerHachling = PlaceActorAtMe( zzEstrusDwemerHachling ).EvaluatePackage()
	else
		DwemerHachling = kContainer.PlaceActorAtMe( zzEstrusDwemerHachling ).EvaluatePackage()
	endIf

	MCM.fHatchingDue[iIncubationIdx] = 0.0
	MCM.kHatchingEgg[iIncubationIdx] = none
	Delete()
endFunction

Event OnLoad()
	if ( !bIsTested && MCM.zzEstrusDwemerInfestation.GetValueInt() as bool && Utility.RandomInt( 0, 100 ) < MCM.zzEstrusDwemerFertilityChance.GetValueInt() )
		bIsTested = True
		fUpdate = Utility.RandomFloat( 48.0, 96.0 )

		iIncubationIdx = 1
		while ( iIncubationIdx < MCM.kHatchingEgg.Length && MCM.kHatchingEgg[iIncubationIdx] != None )
			iIncubationIdx += 1
		endWhile
		
		MCM.fHatchingDue[iIncubationIdx] = (fUpdate/24.0) + Utility.GetCurrentGameTime()
		MCM.kHatchingEgg[iIncubationIdx] = self
		RegisterForSingleUpdateGameTime( fUpdate )
	endIf
EndEvent

Event OnUpdateGameTime()
	hatch()
EndEvent

event OnContainerChanged(ObjectReference akNewContainer, ObjectReference akOldContainer)
	kContainer = akNewContainer
endEvent

