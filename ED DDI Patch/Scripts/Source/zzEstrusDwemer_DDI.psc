Scriptname zzEstrusDwemer_DDI extends Quest

Function ddi_check(Actor akVictim, int EstrusID, int UseAlarm)
	zadlibs dDlibs = Game.GetFormFromFile(0xF624, "Devious Devices - Integration.esm") as Zadlibs
	bool isPlayer = (akVictim == Game.GetPlayer())

	armor dDArmbinder = none

	if dDlibs
		dDArmbinder = dDlibs.GetWornDeviceFuzzyMatch(akVictim, dDlibs.zad_DeviousArmbinder) 

		if akVictim.WornHasKeyword(dDlibs.zad_DeviousBelt) || ( akVictim.WornHasKeyword(dDlibs.zad_DeviousHeavyBondage) && !dDArmbinder) || (dDArmbinder && dDArmbinder.HasKeyword(dDlibs.zad_BlockGeneric))
			if isPlayer
				if EstrusID == 1 
					debug.notification("$ED_DDI_MSG1")
				else
					debug.notification("$ED_DDI_MSG2")
				endIf
					if UseAlarm
						akvictim.CreateDetectionEvent(akVictim, UseAlarm)
					endif
				return
			endif
		endif
	endif

	If dDArmbinder
		dDlibs.ManipulateGenericDevice(akVictim, dDArmbinder, false)
		utility.wait(1)
		If !akVictim.GetWornForm(0x00010000) as Armor
			if isPlayer
				debug.notification("$ED_DDI_MSG3")					
			endIf
			akVictim.DropObject(dDArmbinder, 1)
		Else
			debug.notification("$ED_DDI_MSG4")
			if UseAlarm
				akvictim.CreateDetectionEvent(akVictim, UseAlarm)
			endif 
			return
		Endif
	Endif
EndFunction