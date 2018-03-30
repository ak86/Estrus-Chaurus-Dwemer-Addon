Scriptname zzEstrusDwemer_AliasScript extends ReferenceAlias

zzEstrusDwemer_MCMScript	Property MCM				Auto 
Float						Property fIncubationTime	Auto

Actor kTarget				= None
Actor kCaster				= None
Actor kPlayer				= None
Bool  bDisableNodeChange	= False
Bool  bEnableBreast			= False
Bool  bEnableButt			= False
Bool  bEnableBelly			= False
Bool  bEnableSkirt02		= False
Bool  bEnableSkirt03		= False
Bool  bBreastEnabled		= False
Bool  bButtEnabled			= False
Bool  bBellyEnabled			= False
Bool  bUninstall			= False
Bool  bIsFemale				= False
Bool  bTorpedoFixEnabled	= True
Float fOrigBreast			= 1.0
Float fPregBreast			= 1.0
Float fResiBreast			= 1.0
Float fOrigBreast01			= 1.0
Float fPregBreast01			= 1.0
Float fOrigButt				= 1.0
Float fPregButt				= 1.0
Float fOrigBelly			= 1.0
Float fPregBelly			= 1.0
Float fInfectionStart		= 0.0
Float fInfectionSwell		= 0.0
Float fInfectionLastMsg		= 0.0
Float fBreastSwell			= 0.0
Int   iBreastSwellGlobal	= 0
Float fButtSwell			= 0.0
Int   iButtSwellGlobal		= 0
Float fBellySwell			= 0.0
Int   iBellySwellGlobal		= 0
Float fUpdateTime			= 5.0
Float fWaitingTime			= 10.0
Float fOviparityTime		= 7.5

; * zzEstrusIncubationPeriod3 ( days )
Float fIncubationTimeMin	= 22.6
Float fIncubationTimeMax	= 26.6
Float fthisIncubation		= 0.0
Float fGameTime				= 0.0
Int iIncubationIdx			= -1
Int iBirthingLoops			= 3

; SexLab Aroused
Int iOrigSLAExposureRank	= -3
Int iAnimationIndex			= 1
bool bIsAnimating			= false

String[] sSwellingMsgs
String ActiveState

Event OnLoad()
	;debug.Notification("Load event: " + kTarget.GetActorBase().getname())
	GoToState(ActiveState)
EndEvent
	
Event OnUnload()
	;debug.Notification("Unload event: " + kTarget.GetActorBase().getname())
	ActiveState = GetState()
	GoToState("SUSPEND")
EndEvent

event OnUpdateGameTime()
	int Timer = 5
	while !kTarget.Is3DLoaded() && Timer > 0
		Timer -= 1
		Utility.Wait( 1.0 )
	endWhile

	If kTarget.Is3DLoaded() && kTarget.GetParentCell() == kPlayer.GetParentCell()
	Debug.Trace("_ED_::GTS::BIRTHING")
		GoToState("BIRTHING")
	else
		GoToState("ENDPREGNANCY")
	endif
endEvent

event OnBreederStart(Actor akTarget, Int akIncubationIdx)
	
	iIncubationIdx = akIncubationIdx

	kTarget            = akTarget
	kPlayer            = Game.GetPlayer()
	bDisableNodeChange = MCM.zzEstrusDisableNodeResize.GetValue() as Bool
	bIsAnimating	   = false
	
	;sSwellingMsgs      = new String[3]
	;sSwellingMsgs[0]   = "$ED_SWELLING_1_3RD"
	;sSwellingMsgs[1]   = "$ED_SWELLING_2_3RD"
	;sSwellingMsgs[2]   = "$ED_SWELLING_3_3RD"
	

	GoToState("IMPREGNATE")
	MCM.zzEstrusDwemerInfected.Mod( 1.0 )
	kTarget.StopCombatAlarm()

	Float fMinTime     = MCM.zzEstrusDwemerIncubationPeriod.GetValue() * fIncubationTimeMin
	Float fMaxTime     = MCM.zzEstrusDwemerIncubationPeriod.GetValue() * fIncubationTimeMax
	fIncubationTime    = Utility.RandomFloat( fMinTime, fMaxTime )
	fInfectionStart    = Utility.GetCurrentGameTime()
	fthisIncubation    = fInfectionStart + ( fIncubationTime / 24.0 )
	bIsFemale          = kTarget.GetLeveledActorBase().GetSex() == 1
	bTorpedoFixEnabled = MCM.zzEstrusChaurusTorpedoFix.GetValueInt() as Bool

	;kCaster.PathToReference(kTarget, 1.0)
	
	kTarget.AddToFaction(MCM.zzEstrusDwemerBreederFaction)

	;iIncubationIdx = Self.GetID() ;MCM.kIncubationDue.Find(kTarget, 1)
	;if iIncubationIdx > 0
	MCM.fIncubationDue[iIncubationIdx] = fthisIncubation
	MCM.kIncubationDue[iIncubationIdx] = kTarget
	
			;(ES.GetNthAlias(iIncubationIdx) as ReferenceAlias).ForceRefTo(kTarget)
		;else
			;self.Clear()
			;return
		;endif

	; SexLab Aroused
	manageSexLabAroused(0)

	bEnableSkirt02     = NetImmerse.HasNode(kTarget, MCM.NINODE_SKIRT02, false)
	bEnableSkirt03     = NetImmerse.HasNode(kTarget, MCM.NINODE_SKIRT03, false)
	bEnableBreast      = NetImmerse.HasNode(kTarget, MCM.NINODE_LEFT_BREAST, false) && NetImmerse.HasNode(kTarget, MCM.NINODE_RIGHT_BREAST, false)
	bEnableButt        = NetImmerse.HasNode(kTarget, MCM.NINODE_LEFT_BUTT, false) && NetImmerse.HasNode(kTarget, MCM.NINODE_RIGHT_BUTT, false)
	bEnableBelly       = NetImmerse.HasNode(kTarget, MCM.NINODE_BELLY, false)

	if ( !bDisableNodeChange )
		If !Check3dState()
			Registerforsingleupdate(fWaitingTime)
			return
		endIf
		bBreastEnabled     = ( bEnableBreast && MCM.zzEstrusSwellingBreasts.GetValueInt() as bool )
		bButtEnabled       = ( bEnableButt && MCM.zzEstrusSwellingButt.GetValueInt() as bool )
		bBellyEnabled      = ( bEnableBelly && MCM.zzEstrusSwellingBelly.GetValueInt() as bool )

		if ( bBreastEnabled && kTarget.GetLeveledActorBase().GetSex() == 1 )
			fOrigBreast = MCM.GetNodeTransformScale(kTarget, bIsFemale, MCM.NINODE_LEFT_BREAST)
			if bTorpedoFixEnabled
				fOrigBreast01 = MCM.GetNodeTransformScale(kTarget, bIsFemale, MCM.NINODE_LEFT_BREAST01)
			endif
		endif
		if ( bButtEnabled )
			fOrigButt = MCM.GetNodeTransformScale(kTarget, bIsFemale, MCM.NINODE_LEFT_BUTT)
		endif
		if ( bBellyEnabled )
			fOrigBelly = MCM.GetNodeTransformScale(kTarget, bIsFemale, MCM.NINODE_BELLY)
		endif
	endif

	if bEnableSkirt02
		RegisterForSingleUpdate( fUpdateTime )
		RegisterForSingleUpdateGameTime( fIncubationTime )
	Else
		Debug.MessageBox("$ED_INCOMPATIBLE")
		kTarget.RemoveSpell(MCM.zzEstrusDwemerBreederAbility)
	endif
endEvent

event OnBreederFinish()
	MCM.zzEstrusDwemerInfected.Mod( -1.0 )
	bUninstall = MCM.zzEstrusDwemerUninstall.GetValueInt() as Bool

	if iIncubationIdx != -1
		MCM.fIncubationDue[iIncubationIdx] = 0.0
		MCM.kIncubationDue[iIncubationIdx] = None
	endIf

	if ( kTarget.IsInFaction(MCM.zzEstrusDwemerBreederFaction) )
		kTarget.RemoveFromFaction(MCM.zzEstrusDwemerBreederFaction)
	endIf

	; if we are uninstalling, report the first 128 infected NPCs
	if ( bUninstall )
		iIncubationIdx = MCM.kIncubationOff.Find(none)
		if ( iIncubationIdx >= 0 )
			MCM.kIncubationOff[iIncubationIdx] = kTarget
		endif
	endIf
	
	; SexLab Aroused
	manageSexLabAroused()

	if ( !bDisableNodeChange )
		; make sure we have loaded 3d to access
		
		while ( kTarget.IsOnMount() || Utility.IsInMenuMode() )
			Utility.Wait( 1.0 )
		endWhile

		if ( bBellyEnabled )
			MCM.SetNodeScaleBelly(kTarget, bIsFemale, fOrigBelly)
		endif

		if ( bButtEnabled )
			MCM.SetNodeScaleButt(kTarget, bIsFemale, fOrigButt)
		endif

		if ( bBreastEnabled )
			MCM.SetNodeScaleBreast(kTarget, bIsFemale, fOrigBreast, fOrigBreast01)
		endif
		
		if !kTarget.Is3DLoaded() ;******************************
			triggerNodeUpdate(true)
		endif
		
	endif
	
	Self.Clear()

endEvent

bool Function Check3dState() ;Got to Suspend state if 3d cannot be loaded
	If !kTarget.Is3DLoaded() 
		utility.wait(2)
	endif
	If kTarget.Is3DLoaded() && kTarget.GetParentCell() == kPlayer.GetParentCell()
		if Getstate() == "SUSPEND"
			OnLoad()
			;debug.Notification("Check3dState Resume event: " + kTarget.GetActorBase().getname())
		endif
		return true
	Else
		if !Getstate() == "SUSPEND"
			;debug.Notification("Check3dState Suspend event: " + kTarget.GetActorBase().getname())
			OnUnload()
		endif
		Return false
	endif
endFunction

int function minInt(int iA, int iB)
	if iA < iB
		return iA
	else
		return iB
	endIf
endFunction

Float function eggChain()
	ObjectReference[] thisEgg = new ObjectReference[13]
	bool bHasScrotNode        = NetImmerse.HasNode(kTarget, MCM.NINODE_GENSCROT, false)

	Sound.SetInstanceVolume( MCM.zzEstrusBreastPainMarker.Play(kTarget), 1.0 )
	Int idx = 0
	Int len = Utility.RandomInt( 5, 9 )
	while idx < len
		thisEgg[idx] = kTarget.PlaceAtme(MCM.zzEstrusDwemerEggs, abForcePersist = true)
		thisEgg[idx].SetActorOwner( kTarget.GetActorBase() )

			If bHasScrotNode
				thisEgg[idx].MoveToNode(kTarget, MCM.NINODE_GENSCROT)
				;thisEgg[idx].SplineTranslateToRefNode(kTarget, MCM.NINODE_GENSCROT, 100.0, 0.1)
			else
				thisEgg[idx].MoveToNode(kTarget, MCM.NINODE_SKIRT02)
				;thisEgg[idx].SplineTranslateToRefNode(kTarget, MCM.NINODE_SKIRT02, 100.0, 0.1)
			endif

		idx += 1
		Utility.Wait( Utility.RandomFloat( 3.5, 6.5 ) )
	endWhile

	return len / 4;(7)
endFunction

function oviposition()
	bool finished = false
	float fReduction
	float fBreastReduction
	float fButtReduction

	; make sure we have 3d loaded to access
	while ( !kTarget.Is3DLoaded() )
		Utility.Wait( 1.0 )
	endWhile
	if ( MCM.zzEstrusDwemerUninstall.GetValueInt() == 1 )
		GoToState("AFTERMATH")
		return
	endIf
	
	fReduction       = eggChain()
	fBreastReduction = fReduction / 2.0
	fButtReduction   = fReduction / 2.0
		
	; BELLY SWELL =====================================================
	if ( bBellyEnabled )
		fPregBelly = fPregBelly - fReduction

		if ( fPregBelly <= fOrigBelly )
			fPregBelly = fOrigBelly
		endif
		
		finished = ( fPregBelly == fOrigBelly )
		
		MCM.SetNodeScaleBelly(kTarget, bIsFemale, fPregBelly)
	endif
	
	; BUTT SWELL ======================================================
	if ( bButtEnabled )
		fPregButt = fPregButt - fButtReduction

		if ( fPregButt <= fOrigButt )
			fPregButt = fOrigButt
			finished = ( !bBellyEnabled && !bBreastEnabled )
		endif
		
		MCM.SetNodeScaleButt(kTarget, bIsFemale, fPregButt)
	endif

	
	; BREAST SWELL ====================================================
	if ( bBreastEnabled )
		fPregBreast = fPregBreast - fBreastReduction
		if bTorpedoFixEnabled
			fPregBreast01 = fOrigBreast01 * (fOrigBreast / fPregBreast)
		endIf

		if ( fPregBreast <= fOrigBreast )
			fPregBreast = fOrigBreast
			finished = ( !bBellyEnabled && !bButtEnabled )
		endif

		if bTorpedoFixEnabled
			if ( fPregBreast01 < fOrigBreast01 )
				fPregBreast01 = fOrigBreast01
			endif
		endif
		
		MCM.SetNodeScaleBreast(kTarget, bIsFemale, fPregBreast, fPregBreast01)
	endif
	
	if !bBellyEnabled && !bBreastEnabled && !bButtEnabled
		fPregBelly = fPregBelly - fReduction
		
		finished = ( fPregBelly < fOrigBelly )
	endIf

	Utility.Wait( Utility.RandomFloat( fOviparityTime, fOviparityTime * 2.0 ) )

	if ( !finished && iBirthingLoops > 0 )
		iBirthingLoops -= 1
		oviposition()
	else
		if !finished
			debug.trace("_ED_::Oviposition timed out") 
		endif
		Debug.Trace("_ED_::GTS::AFTERMATH")
		GoToState("AFTERMATH")
	endif
endFunction

function manageSexLabAroused(int aiModRank = -1)
	if !MCM.kfSLAExposure
		return
	endIf
	
	int iRank = kTarget.GetFactionRank(MCM.kfSLAExposure)
	
	if aiModRank == 0 || iOrigSLAExposureRank < -2
		iOrigSLAExposureRank = iRank
	endIf
	if aiModRank < 0
		kTarget.SetFactionRank(MCM.kfSLAExposure, iOrigSLAExposureRank)
	endIf
	if aiModRank > 0 && iRank < 100
		kTarget.ModFactionRank(MCM.kfSLAExposure, minInt(aiModRank, 100 - aiModRank) )
	endIf
endFunction

function triggerNodeUpdate(bool abwait = false)
	iBreastSwellGlobal = MCM.zzEstrusSwellingBreasts.GetValueInt()
	iBellySwellGlobal  = MCM.zzEstrusSwellingBelly.GetValueInt()
	iButtSwellGlobal   = MCM.zzEstrusSwellingButt.GetValueInt()
endFunction

state SUSPEND
	event OnBeginState()
		Debug.Trace("_ED_::state::SUSPEND")
	endEvent

	event OnUpdate()
		Check3dState()
		RegisterForSingleUpdate( fWaitingTime )
	endEvent

	event OnUpdateGameTime()
		;debug.Notification("Suspend EndPregnancy event: " + kTarget.GetActorBase().getname())
		Debug.Trace("_ED_::END OF PREGNANCY WITH NPC UNLOADED - "+ kTarget.GetActorBase().getname())
		GoToState("ENDPREGNANCY")
	endEvent

endState

state IMPREGNATE
	event OnBeginState()
		Debug.Trace("_ED_::state::IMPREGNATE")
	endEvent

	event OnUpdate()
		if ( MCM.zzEstrusDwemerUninstall.GetValueInt() == 1 )
			GoToState("AFTERMATH")
		endIf

		if ( !kTarget.IsInFaction( MCM.SexLabAnimatingFaction ) )
			; all will be false if bDisableNodeChange is true
			if ( bBellyEnabled || bBreastEnabled || bButtEnabled )
				GoToState("INCUBATION_NODE")
			Else
				GoToState("INCUBATION")
			endif
		endif

		RegisterForSingleUpdate( fWaitingTime )
	endEvent
endState

state INCUBATION_NODE
	event OnBeginState()
		Debug.Trace("_ED_::state::INCUBATION_NODE" )
	endEvent
	
	event OnCellLoad()
		Debug.Trace("_ED_::oncellload" )
		triggerNodeUpdate()
	endEvent

	event OnUpdate()
		if ( MCM.zzEstrusDwemerUninstall.GetValueInt() == 1 )
			GoToState("AFTERMATH")
		endIf
		; catch a state change caused by RegisterForSingleUpdate
		if ( GetState() == "INCUBATION_NODE" )
			while ( kTarget.IsOnMount() || Utility.IsInMenuMode() )
				Utility.Wait( 2.0 )
			endWhile
			; make sure we have 3d loaded to access
			if !Check3dState() 
				RegisterForSingleUpdate( fWaitingTime )
				Return
			Endif
			fGameTime       = Utility.GetCurrentGameTime()
			fInfectionSwell = ( fGameTime - fInfectionStart ) / 1.6666 ;1.6666
			fBellySwell     = 0.0
			fBreastSwell    = 0.0
			fButtSwell      = 0.0
			
			; SexLab Aroused ==================================================
			manageSexLabAroused(1)
			
			; BREAST SWELL ====================================================
			iBreastSwellGlobal = MCM.zzEstrusSwellingBreasts.GetValueInt()
			if ( bBreastEnabled && iBreastSwellGlobal )
				fBreastSwell       = fInfectionSwell / iBreastSwellGlobal
				fPregBreast        = fOrigBreast + fBreastSwell
				if bTorpedoFixEnabled
					fPregBreast01  = fOrigBreast01 * (fOrigBreast / fPregBreast)
				endIf

				if fInfectionLastMsg < fGameTime && fInfectionSwell > 0.05
					fInfectionLastMsg = fGameTime + Utility.RandomFloat(0.0417, 0.25)
					;Debug.Notification(sSwellingMsgs[Utility.RandomInt(0, sSwellingMsgs.Length - 1)])
					Sound.SetInstanceVolume( MCM.zzEstrusBreastPainMarker.Play(kTarget), 1.0 )
				endif

				if ( fPregBreast > MCM.NINODE_MAX_SCALE )
					fPregBreast = MCM.NINODE_MAX_SCALE
				endif
				if bTorpedoFixEnabled
					if ( fPregBreast01 < MCM.NINODE_MIN_SCALE )
						fPregBreast01 = MCM.NINODE_MIN_SCALE
					endif
				endif
				if ( fPregBreast > MCM.zzEstrusChaurusMaxBreastScale.GetValue() )
					fPregBreast = MCM.zzEstrusChaurusMaxBreastScale.GetValue()
				endif

				kTarget.SetAnimationVariableFloat("esBreastSwell", fBreastSwell)
				MCM.SetNodeScaleBreast(kTarget, bIsFemale, fPregBreast, fPregBreast01)
			elseIf ( bBreastEnabled && fPregBreast != fOrigBreast )
				fPregBreast = fOrigBreast
				if bTorpedoFixEnabled
					fPregBreast01 = fOrigBreast01
				endIf
				
				kTarget.SetAnimationVariableFloat("esBreastSwell", 0.0)
				MCM.SetNodeScaleBreast(kTarget, bIsFemale, fPregBreast, fPregBreast01)
			endif

			; BELLY SWELL =====================================================
			iBellySwellGlobal = MCM.zzEstrusSwellingBelly.GetValueInt()
			if ( bBellyEnabled && iBellySwellGlobal )
				
				if iBellySwellGlobal == 1   									;fBellySwell = fInfectionSwell / iBellySwellGlobal
					fBellySwell = (fInfectionSwell / iBellySwellGlobal) * 2 
				else
					fBellySwell = fInfectionSwell / iBellySwellGlobal
				endif
				fPregBelly = fOrigBelly + fBellySwell
				if fInfectionLastMsg < fGameTime && fInfectionSwell > 0.05
					fInfectionLastMsg = fGameTime + Utility.RandomFloat(0.0417, 0.25)
					Sound.SetInstanceVolume( MCM.zzEstrusBreastPainMarker.Play(kTarget), 1.0 )
				endif

				if ( fPregBelly > MCM.NINODE_MAX_SCALE * 2.0 ) 
					fPregBelly = MCM.NINODE_MAX_SCALE * 2.0 
				endif
				if ( fPregBelly > MCM.zzEstrusChaurusMaxBellyScale.GetValue() )
					fPregBelly = MCM.zzEstrusChaurusMaxBellyScale.GetValue()
				endif

				kTarget.SetAnimationVariableFloat("esBellySwell", fBellySwell)
				MCM.SetNodeScaleBelly(kTarget, bIsFemale, fPregBelly)
			elseIf ( bBellyEnabled && fPregBelly != fOrigBelly )
				fPregBelly = fOrigBelly
				kTarget.SetAnimationVariableFloat("esBellySwell", 0.0)
				MCM.SetNodeScaleBelly(kTarget, bIsFemale, fPregBelly)
			endif

			; BUTT SWELL ======================================================
			iButtSwellGlobal = MCM.zzEstrusSwellingButt.GetValueInt()
			if ( bButtEnabled && iButtSwellGlobal )
				fButtSwell = fInfectionSwell / iButtSwellGlobal
				fPregButt  = fOrigButt + fButtSwell

				if fInfectionLastMsg < fGameTime && fInfectionSwell > 0.05
					fInfectionLastMsg = fGameTime + Utility.RandomFloat(0.0417, 0.25)
					Sound.SetInstanceVolume( MCM.zzEstrusBreastPainMarker.Play(kTarget), 1.0 )
				endif

				if ( fPregButt > MCM.NINODE_MAX_SCALE )
					fPregButt = MCM.NINODE_MAX_SCALE 
				endif
				if ( fPregButt > MCM.zzEstrusChaurusMaxButtScale.GetValue() )
					fPregButt = MCM.zzEstrusChaurusMaxButtScale.GetValue()
				endif

				MCM.SetNodeScaleButt(kTarget, bIsFemale, fPregButt)
			elseIf ( bButtEnabled && fPregButt != fOrigButt )
				fPregButt = fOrigButt
				MCM.SetNodeScaleButt(kTarget, bIsFemale, fPregButt)
			endif

			kTarget.SetFactionRank(MCM.zzEstrusDwemerBreederFaction, Math.Floor(fBellySwell + fBreastSwell) )
			RegisterForSingleUpdate( fUpdateTime )
		endif
	endEvent
endState

state INCUBATION
	event OnBeginState()
		fOrigBelly = 1.0
		fPregBelly = MCM.NINODE_MAX_SCALE * 2.0
		Debug.Trace("_ED_::state::INCUBATION")
	endEvent

	event OnUpdate()
		if ( MCM.zzEstrusDwemerUninstall.GetValueInt() == 1 )
			GoToState("AFTERMATH")
		endIf

		; catch a state change caused by RegisterForSingleUpdate
		if ( GetState() == "INCUBATION" )
			; SexLab Aroused ==================================================
			manageSexLabAroused(1)

			RegisterForSingleUpdate( fUpdateTime )
		endif
	endEvent
endState

state BIRTHING
	event OnBeginState()
		Debug.Trace("_ED_::state::BIRTHING")
		while ( kTarget.IsOnMount() || Utility.IsInMenuMode() )
			Utility.Wait( 2.0 )
		endWhile

		if kTarget.IsWeaponDrawn()
			kTarget.SheatheWeapon()
		endIf		
		;Debug.SendAnimationEvent(kTarget, "BleedOutStart")
		MCM.stripActor(kTarget)
		Debug.SendAnimationEvent(kTarget, "IdleBedRollFrontEnterStart")
		Utility.Wait( 10.0 )
		;iAnimationIndex += 1
		;Debug.SendAnimationEvent(kTarget, "Arrok_Missionary_A1_S"+iAnimationIndex)
		Debug.SendAnimationEvent(kTarget, "zzEstrusCommon01Up")
		bIsAnimating = true

		if ( MCM.zzEstrusDwemerBirth.GetValueInt() == 1 )
			iBirthingLoops = 1
		else
			iBirthingLoops = 3
		endif

		if bIsFemale && MCM.zzEstrusChaurusFluids.GetValue() as bool
			;kTarget.AddItem(MCM.zzEstrusChaurusFluid, 1, true)
			kTarget.EquipItem(MCM.zzEstrusChaurusFluid, true, true)
			;kTarget.AddItem(zzEstrusChaurusMilkR, 1, true)
			kTarget.EquipItem(MCM.zzEstrusChaurusRMilk, true, true)
			;kTarget.AddItem(zzEstrusChaurusMilkL, 1, true)
			kTarget.EquipItem(MCM.zzEstrusChaurusLMilk, true, true)
		endIf
		
		if ( MCM.zzEstrusChaurusResidual.GetValueInt() == 1 )
			float fResidualScale = MCM.zzEstrusChaurusResidualScale.GetValue()

			fResiBreast = fOrigBreast * fResidualScale
			if bTorpedoFixEnabled
				fOrigBreast01 = (fOrigBreast / fResiBreast)
			endIf
			fOrigBreast = fResiBreast
		endIf
		
		if kTarget == kPlayer
			Game.ForceThirdPerson()
			Game.SetPlayerAIDriven()
		else
			kTarget.SetRestrained(true)
			kTarget.SetDontMove(true)
		endIf
		oviposition()
	endEvent

	event OnUpdate()
		; catch any pending updates
	endEvent
endState

state AFTERMATH
	event OnBeginState()
		Debug.Trace("_ED_::state::AFTERMATH")

		if bIsFemale
			;kTarget.UnequipItem(MCM.zzEstrusChaurusFluid, false, true)
			kTarget.RemoveItem(MCM.zzEstrusChaurusFluid, 1, true)
			;kTarget.UnequipItem(zzEstrusChaurusMilkR, false, true)
			kTarget.RemoveItem(MCM.zzEstrusChaurusRMilk, 1, true)
			;kTarget.UnequipItem(zzEstrusChaurusMilkL, false, true)
			kTarget.RemoveItem(MCM.zzEstrusChaurusLMilk, 1, true)
		endIf

		if kTarget == kPlayer
			Game.SetPlayerAIDriven(false)
		else
			kTarget.SetRestrained(false)
			kTarget.SetDontMove(false)
		endIf

		if bIsAnimating
			Debug.SendAnimationEvent(kTarget, "zzEstrusGetUpFaceUp")
		endIf

		;Debug.SendAnimationEvent(kTarget, "zzEstrusGetUpFaceUp")
		;Debug.SendAnimationEvent(kTarget, "BleedOutStop")
		OnBreederFinish()
	
		SendModEvent("EDBirthCompleted") ;as requested by Skyrimll

	endEvent
	
	event OnUpdate()
		; catch any pending updates
	endEvent
endState

state ENDPREGNANCY
	event OnBeginState()
		Debug.Trace("_ED_::state::ENDPREGNANCY")

		;Debug.SendAnimationEvent(kTarget, "BleedOutStop")
		OnBreederFinish()
	endEvent

	event OnUpdate()
		; catch any pending updates
	endEvent

endState