Scriptname zzEstrusDwemer_AE extends Quest

zzEstrusDwemer_MCMScript	property mcm			auto 
zzEstrusDwemer_Events		property EDevents		auto 

Spell	property zzDwemerParasite					auto 
Spell	property zzEstrusDwemerAnimationCooldown	auto 


function RegisterForSLDwemer()
	
	;debug.notification("ED+ "+ mcm.GetStringVer() + " Registered...")
	RegisterForModEvent("OrgasmStart", "onOrgasm")
	RegisterForModEvent("AnimationEnd", "OnSexLabEnd")
	RegisterForModEvent("SexLabOrgasmSeparate", "onOrgasmS")

endfunction

; START ES FUNCTIONS ==========================================================

; // Our callback we registered onto the global event 
event onOrgasmS(Form ActorRef, Int Thread)
	actor akActor = ActorRef as actor
	
	; // Use the HookController() function to get the actorlist
	actor[] actorList = mcm.SexLab.HookActors(Thread as string)
	sslThreadController controller = mcm.Sexlab.GetController(Thread)
 
	if mcm.zzEstrusDwemerDisablePregnancy.GetValueInt()
		return
	endif
	
	if actorList.Length > 1 && akActor != actorList[0]
		;See if Dwemer was involved
		if mcm.Sexlab.PregnancyRisk(Thread, actorlist[0], false, true)
			if IsDwemer(akActor) == true														;SD+ Faction changes mean we can't rely on a faction check
				DwemerImpregnate(actorlist[0], akActor)
			endif
		endif
	endif
endEvent

; // Our callback we registered onto the global event 
event onOrgasm(string eventName, string argString, float argNum, form sender)
	; // Use the HookController() function to get the actorlist
	actor[] actorList = mcm.SexLab.HookActors(argString)
 	sslThreadController controller = mcm.Sexlab.GetController(argString as Int)

	if mcm.zzEstrusDwemerDisablePregnancy.GetValueInt()
		return
	endif
	
	if actorlist.Length > 1
		int i = 1
		while i < actorlist.Length
			;See if Dwemer was involved
			if mcm.Sexlab.PregnancyRisk(argString as Int, actorlist[0], false, true)
				if IsDwemer(actorlist[i]) == true												;SD+ Faction changes mean we can't rely on a faction check
					DwemerImpregnate(actorlist[0], actorlist[i])
				endif
			endif
			i += 1
		endwhile
	endif
endEvent

; // Our callback we registered onto the global event 
event OnSexLabEnd(string eventName, string argString, float argNum, form sender)
	; // Use the HookController() function to get the actorlist
;	actor[] actorList = mcm.SexLab.HookActors(argString)
	
	; // See if a Creature was involved, and try to fix broken spider animation it for SL1.62
;	if actorlist.Length > 1
;		int i = 0
;		while i < actorlist.Length
;			if IsSpiderRace(actorlist[i].GetRace())
;				Utility.Wait(0.1)
;				actorlist[i].disable()
;				actorlist[i].enable()
;				;Utility.Wait(1)
;				;actorlist[1].MoveToMyEditorLocation()
;			endif
;			i += 1
;		endwhile
;	endif
endEvent

bool function IsDwemer(Actor akActor)
	if akActor.HasKeyword( Game.GetFormFromFile(0x1397A, "Skyrim.esm") as Keyword ) ;ActorTypeDwarven Keyword
		if akActor.IsInFaction(Game.GetFormFromFile(0x43598 , "Skyrim.esm") as Faction)	;DwarvenAutomatonFaction
			return true
		endif
	endif
	
	Race akRace = akActor.GetRace()
	if akRace == (Game.GetFormFromFile(0x131F1 , "Skyrim.esm") as Race) 			;Dwarven Centurion
		return true
	elseif akRace == (Game.GetFormFromFile(0x131F2 , "Skyrim.esm") as Race) 		;Dwarven Sphere
		return true
	elseif akRace == (Game.GetFormFromFile(0x131F3 , "Skyrim.esm") as Race) 		;Dwarven Spider
		return true
	endif
	if Game.GetModbyName("Dawnguard.esm") != 255
		if akRace == (Game.GetFormFromFile(0x15C34 , "Dawnguard.esm") as Race) 		;The Forgemaster(Centurion)
			return true
		endif
	endif
	if Game.GetModbyName("Dragonborn.esm") != 255
		if akRace == (Game.GetFormFromFile(0x2B014 , "Dragonborn.esm") as Race)		;Dwarven Sphere(Balista)
			return true
		endif
	endif
	
	return false
endfunction

function DwemerImpregnate(actor akVictim, actor akAgressor)

	Bool bGenderOk = mcm.zzEstrusChaurusGender.GetValueInt() == 2 || akvictim.GetLeveledActorBase().GetSex() == mcm.zzEstrusChaurusGender.GetValueInt()
	Bool invalidateVictim = !bGenderOk || ( akVictim.IsBleedingOut() || akVictim.isDead() )
	;debug.notification("DwemerImpregnate "+invalidateVictim)

	if invalidateVictim
		return
	endif

	EDevents.Oviposition(akvictim)

	if ( !akAgressor.IsInFaction(mcm.zzEstrusDwemerBreederFaction) )
		akAgressor.AddToFaction(mcm.zzEstrusDwemerBreederFaction)
	endIf
	
	mcm.SexLab.ApplyCum(akvictim, 7)
	
	utility.wait(5) ; Allow time for ED to register oviposition and crowd control to kick in
	akVictim.DispelSpell(zzDwemerParasite)

endfunction

function DwemerAttack(Actor akVictim, Actor akAgressor)

	if !akVictim.HasSpell(zzEstrusDwemerAnimationCooldown)
		if mcm.TentacleSpitEnabled
			if utility.randomint(1,100) <= mcm.TentacleSpitChance
				zzEstrusDwemerAnimationCooldown.cast(akVictim,akVictim)
				
				if EDevents.OnEDStartAnimation(self, akVictim, 1, true, 0, true)
					if !akAgressor.IsInFaction(mcm.zzEstrusDwemerBreederFaction) 
						akAgressor.AddToFaction(mcm.zzEstrusDwemerBreederFaction)
					endif
				endIf
			endIf
		elseif mcm.ParalyzeSpitEnabled
			if utility.randomint(1,100) <= mcm.ParalyzeSpitChance
				zzEstrusDwemerAnimationCooldown.cast(akVictim,akVictim)
				
				Spell paralyzeSpell = (Game.GetFormFromFile(0x52DE4 , "EstrusDwemer.esp") as Spell)
				if paralyzeSpell
					paralyzeSpell.cast(akAgressor,akVictim)
					Utility.wait(2.0)
					akVictim.dispelSpell(paralyzeSpell)
					Utility.wait(1.0)
				endif
				
				if EDevents.OnEDStartAnimation_xjAlt(self, akVictim, akAgressor)
					if !akAgressor.IsInFaction(mcm.zzEstrusDwemerBreederFaction) 
						akAgressor.AddToFaction(mcm.zzEstrusDwemerBreederFaction)
					endif
				endIf
			endIf
		endif
	endif
	
endfunction
