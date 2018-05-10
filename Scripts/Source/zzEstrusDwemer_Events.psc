Scriptname zzEstrusDwemer_Events extends Quest

zzEstrusDwemer_MCMScript	property mcm Auto

Actor[] sexActors

sslBaseAnimation[] animations

actor Property PlayerRef Auto

faction property ECTentaclefaction		Auto
faction property ECVictimfaction		Auto
faction property CurrentFollowerFaction	auto

armor	property zzEstrusDwemerBinders	auto
armor	property zzEstrusDwemerBelt		auto

spell	property zzEstrusDwemerParasite	auto 
spell	property ZZEstrusDwemerExhaustion	Auto

sound	property zzEstrusChaurusVibrate	Auto

Quest	property zzEstrusDwemer	Auto
Quest	property zzEstrusChaurusVictims	Auto
Quest	property zzEstrusChaurusSpectators	Auto

Actor[]	Victim

Keyword	property zzEstrusDwemerArmor	Auto

int EventFxID0 = 0
int EventFxID1 = 0
int iNotifyStage = 0

String strCallback

bool UseEDFX = true


;************************************
;**Estrus Dwemer Public Interface **
;************************************
;
;The ED interface uses ModEvents. This method can be used without loading ED as a master or using GetFormFromFile
; 
;To call an ED event use the following code:
;
; 	int EDTrap = ModEvent.Create("EDStartAnimation"); Int 			Int does not have to be named "ECTrap" any name would do
;	if (EDTrap)	
;		ModEvent.PushForm(EDTrap, self)             ; Form			Pass the calling form to the event
;		ModEvent.PushForm(EDTrap, akActor) 			; Form	 		The animation target
;		ModEvent.PushInt(EDTrap, EstrusTraptype)    ; Int			The animation required   -1 = Impregnation only with No Amimation , 1 = Machines
;		ModEvent.PushBool(EDTrap, true)             ; Bool			Apply the linked ED effect (Exhaustion for Machine) 
;		ModEvent.Pushint(EDTrap, 500)               ; Int			Alarm radius in units (0 to disable) 
;		ModEvent.PushBool(EDTrap, true)             ; Bool			Use ED (basic) crowd control on hostiles if the Player is trapped
;	ModEvent.Send(EDtrap)
;	else
;		;ED is not installed
;	endIf
;
; Setting the animation required to -1 applies ES breeder effect without any animation or visual effects, alarms, chastity device checks, or crowd control however ALL 6 parameters still
; need to be passed for the modevent to function.
;
; To use impregnation only the required parameter values are: self, akActor, -1, False, 0, False
;
;
;
;To register a callback to trigger on a specific stage of the next animation played use this modevent immediately BEFORE calling the ES event
;
;	SendModEvent("EDRegisterforStage,"MyModsCallbackName", CallbackAnimationStage as Float)
;
; 	**NB** Only one stage can be registered & the callback registration is cleared once the animation plays, it must therefore be sent each time you trigger the EC animation event that needs a stage callback
;	Don't forget to Register for the callback event (e.g. RegisterForModEvent("MyModsCallbackName", "OnEDStage" ) in your own mod 
;
;************************************
; Please do not link directly to ES functions - they are likely to change and break your mod!

function InitModEvents()

	RegisterForModEvent("EDRegisterforStage", "OnEDRegisterforStage")
	RegisterForModEvent("EDStartAnimation", "OnEDStartAnimation")
	
endFunction

Function OnEDRegisterforStage(String strEventName, String strReqCB, Float fStage, Form kSender)
	iNotifyStage = fStage as Int
	strCallback = strReqCB
EndFunction


bool function OnEDStartAnimation_xjAlt(Form Sender, actor akVictim, actor akAggressor)
	;debug.Notification("Xj - spit start")

	actor akActor = akVictim
	Bool bGenderOk = mcm.zzEstrusChaurusGender.GetValueInt() == 2 || akActor.GetLeveledActorBase().GetSex() == mcm.zzEstrusChaurusGender.GetValueInt()
	Bool invalidateVictim = !bGenderOk || akActor.IsBleedingOut() || akActor.isDead()
	;debug.notification("OnEDStartAnimation_xjAlt "+invalidateVictim)

	if invalidateVictim 
		return false
	endif
	
	int SexlabValidation = mcm.SexLab.ValidateActor(akActor)
	if SexlabValidation != 1
		return false
	endif

	sexActors    = new actor[2]
	sexActors[0] = akVictim
	sexActors[1] = akAggressor
	animations   = mcm.SexLab.PickAnimationsByActors(sexActors,Aggressive=True)
	
	
	if mcm.SexLab.StartSex(sexActors, animations, akVictim, AllowBed=False) != -1
		if !zzEstrusChaurusVictims.IsRunning()
			zzEstrusChaurusVictims.start()
			utility.wait(0.5)
		endif
		int VictimRefs = zzEstrusChaurusVictims.GetNumAliases()
		while VictimRefs > 0
			VictimRefs -= 1
			If (zzEstrusChaurusVictims.GetNthAlias(VictimRefs) as ReferenceAlias).ForceRefIfEmpty(akVictim)
				(zzEstrusChaurusVictims.GetNthAlias(VictimRefs) as ReferenceAlias).RegisterForSingleUpdate(5)
				VictimRefs = 0
			endif
		endwhile

		OnUpdate()
		return true
	else
		return false
	endif	
endfunction

bool function OnEDStartAnimation(Form Sender, form akTarget, int intAnim, bool bUseFX, int intUseAlarm, bool bUseCrowdControl)

	actor akActor = akTarget as Actor
	;why do we even check gender for tentacle/machine animation?
	Bool bGenderOk = mcm.zzEstrusChaurusGender.GetValueInt() == 2 || akActor.GetLeveledActorBase().GetSex() == mcm.zzEstrusChaurusGender.GetValueInt()
	Bool invalidateVictim = !bGenderOk || akActor.IsBleedingOut() || akActor.isDead()

	if !invalidateVictim 
		int SexlabValidation = mcm.SexLab.ValidateActor(akActor)
		;debug.notification("intAnim "+intAnim + " SexlabValidation "+SexlabValidation)
		if intAnim == -1 && SexlabValidation != -12 ; Exclude Child Races
			Oviposition(akActor, false)
		elseif intAnim == 1 && SexlabValidation == 1
			DoEDAnimation(akActor, intAnim, bUseFX, intUseAlarm, bUseCrowdControl)
		else
			return false
		endif
		
		return true
	else
		return false
	endIf	
endfunction

function DoEDAnimation(actor akVictim, int AnimID, bool UseFX, int UseAlarm, bool UseCrowdControl)

		bool isPlayer = (akVictim == PlayerRef)
		string EstrusType
		string strVictimRefid = akVictim.getformid() as string
		UseEDFX = UseFx

		int EstrusID = AnimID

		If EstrusID == 1
			EstrusType = "Dwemer,Machine"
		Endif

		zzEstrusDwemer_DDI DDI = Quest.GetQuest("zzEstrusDwemer_DDI") as zzEstrusDwemer_DDI
		DDI.ddi_check(akVictim, EstrusID, UseAlarm)
		
		if isplayer
			SendModEvent("dhlp-Suspend") ;ED Scene starting - suspend Deviously Helpless Events
		endif 
		
		animations   = mcm.SexLab.GetAnimationsByTag(1, "Estrus", EstrusType)
		sexActors    = new actor[1]
		sexActors[0] = akVictim
		RegisterForModEvent("AnimationStart_" + strVictimRefid, "EDAnimStart")
		RegisterForModEvent("StageEnd_" + strVictimRefid, "EDAnimStage")
		RegisterForModEvent("AnimationEnd_" + strVictimRefid, "EDAnimEnd")

		akVictim.StopCombatAlarm()
		akVictim.StopCombat()
	
		if mcm.SexLab.StartSex(sexActors, animations, akVictim, none, false, strVictimRefid) > -1
			if !zzEstrusChaurusVictims.IsRunning()
				zzEstrusChaurusVictims.start()
				utility.wait(0.5)
			endif
			int VictimRefs = zzEstrusChaurusVictims.GetNumAliases()
			while VictimRefs > 0
				VictimRefs -= 1
				If (zzEstrusChaurusVictims.GetNthAlias(VictimRefs) as ReferenceAlias).ForceRefIfEmpty(akVictim)
					(zzEstrusChaurusVictims.GetNthAlias(VictimRefs) as ReferenceAlias).RegisterForSingleUpdate(5)
					VictimRefs = 0
				endif
			endwhile

			if isplayer && UseCrowdControl
				zzEstruschaurusSpectators.start()
				OnUpdate()
			endif
		endIf
		
		if UseAlarm
			akVictim.CreateDetectionEvent(akVictim, UseAlarm)
		endif

endFunction

event EDAnimStart(string hookName, string argString, float argNum, form sender)
	
	actor[] actorList = mcm.SexLab.HookActors(argString)
	sslBaseAnimation animation = mcm.SexLab.HookAnimation(argString)
	string strVictimRefid = actorList[0].getformid() as string
	bool isPlayer = (actorlist[0] == PlayerRef)
	armor zzEstrusArmorItem = none

	actorList[0].RestoreActorValue("health", 10000)

	if animation.hastag("Machine")
		if animation.name == "Dwemer Machine"
			zzEstrusArmorItem = zzEstrusDwemerBinders
		else
			zzEstrusArmorItem = zzEstrusDwemerBelt
		endif

		utility.wait(0.3)
		if isplayer
			actorList[0].EquipItem(zzEstrusArmorItem, true, true)
			actorList[0].QueueNiNodeUpdate()						;Hopefully fix equip visual glitches 
			utility.wait(5)
			EventFxID0 = zzEstrusChaurusVibrate.Play(actorList[0]) 
		else	
			actorList[0].EquipItem(zzEstrusArmorItem, true, true)
			actorList[0].QueueNiNodeUpdate()						;Hopefully fix equip visual glitches 
			stripFollower(actorList[0])
			if EventFxID1 == 0
				EventFxID1 = zzEstrusChaurusVibrate.Play(actorList[0]) 
			endif
		endif
	endif
endevent

event EDAnimStage(string hookName, string argString, float argNum, form sender)
	
	int stage = mcm.SexLab.HookStage(argString)
	actor[] actorList = mcm.SexLab.HookActors(argString)
	bool isPlayer = (actorlist[0] == PlayerRef)
	sslBaseAnimation animation = mcm.SexLab.HookAnimation(argString)
	sslThreadController controller = mcm.SexLab.GetController(argString as int)
	armor EDArmor = none

	if Stage == iNotifyStage && strCallback != ""
		actorlist[0].SendModEvent(strCallback)
		iNotifyStage = 0
		strCallback = ""
	endif

	if animation.hastag("Machine")
		if stage == 3 && UseEDFX
			controller.ActorAlias(actorlist[0]).OrgasmEffect()
			if isPlayer
				debug.notification("$ED_MACHINE_MSG1")
			endif
		elseif stage == 4
			controller.ActorAlias(actorlist[0]).OrgasmEffect()
		elseif stage == 5
			mcm.SexLab.ApplyCum(actorlist[0], 5)
			controller.ActorAlias(actorlist[0]).OrgasmEffect()
			if isPlayer && UseEDFX
				debug.notification("$ED_MACHINE_MSG2")
			endif
		elseif stage == 6
			controller.ActorAlias(actorlist[0]).OrgasmEffect()
		elseif stage == 7
			controller.ActorAlias(actorlist[0]).OrgasmEffect()
		elseif stage == 8
			if UseEDFX
				zzEstrusDwemerExhaustion.RemoteCast(actorlist[0],actorlist[0],actorlist[0])
			endIf
			if !(mcm.zzEstrusDwemerDisablePregnancy.GetValueInt() as Bool)
				Oviposition(actorlist[0], true)
			endIf
			controller.ActorAlias(actorlist[0]).OrgasmEffect()
			if isPlayer && UseEDFX
				debug.notification("$ED_MACHINE_MSG3")
			endif
		elseif stage == 9
			;actorlist[0].RemoveItem(zzEstrusDwemerBinders, 1, true)
			;actorList[0].QueueNiNodeUpdate()								;Hopefully fix equip visual glitches 
			;if !isPlayer
				;stripFollower(actorlist[0])
			;endif
			controller.ActorAlias(actorlist[0]).OrgasmEffect()
		elseif stage == 10
			controller.ActorAlias(actorlist[0]).OrgasmEffect()
			if isPlayer && UseEDFX
				debug.notification("$ED_MACHINE_MSG4")
			endif
		elseif stage == 11
			if isPlayer && UseEDFX
				debug.notification("$ED_MACHINE_MSG5")
			endif
		endif
	endif
	
	if stage > 8 ;Safety Check for active sounds and Estrus Armor at each stage >8 to allow for stage interrupts/lag
		
		if actorlist[0].WornHasKeyword(zzEstrusDwemerArmor)
			if animation.name == "Dwemer Machine"
				EDArmor = zzEstrusDwemerBinders
			else
				EDArmor = zzEstrusDwemerBelt
			endif
			actorList[0].RemoveItem(EDArmor, 1, true)
			if !isplayer
				stripFollower(actorList[0])
			endif
		endif

		if !isPlayer && EventFxID1 > 0
			Sound.StopInstance(EventFxID1)
			EventFxID1 = 0
		elseif EventFxID0 >0
			Sound.StopInstance(EventFxID0)
			EventFxID0 = 0
		endif
	endif
endevent

event EDAnimEnd(string hookName, string argString, float argNum, form sender)
	
	actor[] actorList = mcm.SexLab.HookActors(argString)
	sslBaseAnimation animation = mcm.SexLab.HookAnimation(argString)
	unregisterforupdate()
	string strVictimRefid = actorList[0].getformid() as string
	unregisterformodevent("StageEnd_" + strVictimRefid)
	armor EDArmor = none
	
	int stage = mcm.SexLab.HookStage(argString)
	
	bool isPlayer = (actorlist[0] == PlayerRef)
	
	if actorlist[0].WornHasKeyword(zzEstrusDwemerArmor)
		EDArmor = zzEstrusDwemerBinders
		actorList[0].RemoveItem(EDArmor, 1, true)
	endif

	if !isPlayer && EventFxID1 > 0 ;Sound failsafe for stage skipping sound bug
		Sound.StopInstance(EventFxID1)
		EventFxID1 = 0
	elseif EventFxID0 >0
		Sound.StopInstance(EventFxID0)
		EventFxID0 = 0
	endif
	
	unregisterformodevent("AnimationStart_" + strVictimRefid)
	unregisterformodevent("AnimationEnd_" + strVictimRefid)

	if isplayer
		SendModEvent("dhlp-Resume") ;Resume Deviously Helpless Events
	else
		;Debug.SendAnimationEvent(actorlist[0], "IdleForceDefaultState");Prevent "AI Frozen" Followers
		actorlist[0].evaluatepackage()
	endif

endevent

Function Oviposition(actor akVictim, bool UseParasiteSpell = true)
	;block pregnancies from other estruses
	Bool invalidateVictim = False

	;Estrus Chaurus+
		if akVictim.HasSpell( Game.GetFormFromFile(0x19121, "EstrusChaurus.esp") as Spell )		;ChaurusBreeder spell
			invalidateVictim = True
		endif
		if akVictim.HasKeyword( Game.GetFormFromFile(0x160A8, "EstrusChaurus.esp") as Keyword )	;zzEstrusParasite Keyword
			invalidateVictim = True
		endif
	
	;Estrus Spider+
		if akVictim.HasSpell( Game.GetFormFromFile(0x4e255, "EstrusSpider.esp") as Spell )		;SpiderBreeder spell
			invalidateVictim = True
		endif
		if akVictim.HasKeyword( Game.GetFormFromFile(0x4F2A3, "EstrusSpider.esp") as Keyword )	;zzEstrusSpiderParasiteKWD Keyword
			invalidateVictim = True
		endif
	
	;Estrus Dwemer+
		if akVictim.HasSpell( Game.GetFormFromFile(0x4e255, "EstrusDwemer.esp") as Spell )		;DwemerBreeder spell
			invalidateVictim = True
		endif
		if akVictim.HasKeyword( Game.GetFormFromFile(0x4F2A3, "EstrusDwemer.esp") as Keyword )	;zzEstrusDwemerParasiteKWD Keyword
			invalidateVictim = True
		endif
	
	;Hentai pregnancy LE/SE
		Faction HentaiPregnantFaction = ( Game.GetFormFromFile(0x12085, "HentaiPregnancy.esm") as Faction )		;HentaiPregnantFaction
		if HentaiPregnantFaction
			if akVictim.GetFactionRank(HentaiPregnantFaction) == 2 || akVictim.GetFactionRank(HentaiPregnantFaction) == 3
				invalidateVictim = True
			endif
		endif
	
	if !invalidateVictim
		if akVictim == PlayerRef
			if akVictim.IsInFaction(mcm.zzEstrusDwemerBreederFaction)
				return
			endIf
			if ( !akVictim.HasSpell(mcm.zzEstrusDwemerBreederAbility ) );
				akVictim.AddSpell(mcm.zzEstrusDwemerBreederAbility , false)
				mcm.SexLab.AdjustPlayerPurity(-5.0)
			endIf
		else
			If MCM.kIncubationDue.Find(akVictim, 1) < 0
				Int BreederIdx = MCM.kIncubationDue.Find(none, 1)
				if BreederIdx > 0
					(zzEstrusDwemer.GetNthAlias(BreederIdx) as ReferenceAlias).ForceRefTo(akVictim)
					(zzEstrusDwemer.GetNthAlias(BreederIdx) as zzEstrusDwemer_AliasScript).OnBreederStart(akVictim, BreederIdx)
				endif
			else
				return
			endif
		endif	
	endif	
	if UseParasiteSpell
		zzEstrusDwemerParasite.RemoteCast(akVictim, akVictim, akVictim)
	endif
	
endFunction

Event OnUpdate()

	Cell c = PlayerRef.GetParentCell()
	Actor akactor
	int followerIndex = 0
	Int NumRefs = c.GetNumRefs(43)
	bool FoundVictim = False

	While (NumRefs > 0)
		NumRefs -= 1
		akactor = c.GetNthRef(NumRefs, 43) as Actor
		if akactor.IsInFaction(ECVictimfaction)
			FoundVictim = true
		Endif
		actor aktarget = akactor.GetCombatTarget()
		If aktarget != none && !akactor.IsInFaction(CurrentFollowerFaction) && akactor.HasLOS(aktarget)
			if aktarget.IsInFaction(ECVictimfaction) 
				if ( !akactor.IsInFaction(ECTentaclefaction) )
					int SpectatorRefs = zzEstrusChaurusSpectators.GetNumAliases()
						while SpectatorRefs > 1
							SpectatorRefs -= 1
							If (zzEstrusChaurusSpectators.GetNthAlias(SpectatorRefs) as ReferenceAlias).ForceRefIfEmpty(akactor)
								akactor.stopcombat()
								SpectatorRefs = 0
							endif
						endwhile

				;elseif aktarget.IsInFaction(ECTentaclefaction) 
				;	aktarget.removefromFaction(ECTentaclefaction); Clear Alias
				;	aktarget.StartCombat(akactor)
				endif
			endif
		Endif
	EndWhile 
	if FoundVictim
		RegisterforSingleUpdate(1)
	else
		;int SpectatorRefs = zzEstrusChaurusSpectators.GetNumAliases() **********************************************!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!************************************************
		;while SpectatorRefs > 1
			;SpectatorRefs -= 1
			;(zzestruschaurusSpectators.GetNthAlias(SpectatorRefs) as ReferenceAlias).Clear()
		;EndWhile
		zzEstrusChaurusSpectators.stop()
		zzEstrusChaurusVictims.stop()
	endif

EndEvent

function stripFollower(actor akVictim)

	Form ItemRef = None
	ItemRef = akVictim.GetWornForm(Armor.GetMaskForSlot(32))
	StripItem(akVictim, ItemRef)
	ItemRef = akVictim.GetWornForm(Armor.GetMaskForSlot(31))
	StripItem(akVictim, ItemRef)
	ItemRef = akVictim.GetWornForm(Armor.GetMaskForSlot(30))
	StripItem(akVictim, ItemRef)
	ItemRef = akVictim.GetWornForm(Armor.GetMaskForSlot(33))
	StripItem(akVictim, ItemRef)
	ItemRef = akVictim.GetWornForm(Armor.GetMaskForSlot(34))
	StripItem(akVictim, ItemRef)
	;ItemRef = akVictim.GetWornForm(Armor.GetMaskForSlot(37)) #You can keep your boots on!#
	;StripItem(akVictim, ItemRef)
	ItemRef = akVictim.GetWornForm(Armor.GetMaskForSlot(38))
	StripItem(akVictim, ItemRef)	
	ItemRef = akVictim.GetWornForm(Armor.GetMaskForSlot(39))
	StripItem(akVictim, ItemRef)
	ItemRef = akVictim.GetEquippedWeapon(false)
	if ItemRef
		akVictim.UnequipItemEX(ItemRef, 1, false)
	endIf
	ItemRef = akVictim.GetEquippedWeapon(true)
	if ItemRef
		akVictim.UnequipItemEX(ItemRef, 2, false)
	endif
endfunction

function StripItem(actor akVictim, form ItemRef)
	If ItemRef
		Armor akArmor = ItemRef as Armor
		if !akArmor.haskeyword(zzEstrusDwemerArmor)
			akVictim.UnequipItem(ItemRef, false, true)
		endif
	endif
endfunction

