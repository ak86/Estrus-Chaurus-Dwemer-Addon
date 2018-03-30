Scriptname zzEstrusDwemer_ExhaustionSpell extends activemagiceffect hidden

;not used in ED but maybe later something will change if i need to extend default EC script

actor property PlayerRef Auto

float EffectStartTime = 0.0
float LastUpdateTime = 0.0
float elapsedTime = 0.0
float statMult = 0.0		; Base Sta and Mag mult rate after event
float speedmult = 20.0		; Base movement mult rate after event
float improveRate = 6.0		; % of Mult regained per hour event
float sleepRate = 12.5		; additional % of mult regained per hour of sleep
float sleepbonus = 0.0
float sleepStartTime = 0.0
float moverecoveryrate = 20.0

bool recoveredspeedmult = false
bool hasslept = false
bool IsPlayer = false

actor akVictim = none


event OnEffectStart(actor AkTarget, actor akCaster)
	EffectStartTime = Utility.GetCurrentGameTime() 
	moverecoveryrate = utility.randomint(30,80) as float 		; Recover 30 - 80% of speedmult per hour

	akVictim = akTarget

	IsPlayer = (akVictim == PlayerRef)

	akVictim.setAV("speedmult",speedmult)

	float actorHealth = akVictim.GetActorValue("Health")
	float damageValue = actorHealth - 10

	akVictim.SetActorValue("StaminaRateMult",0.0)
	akVictim.SetActorValue("MagickaRateMult",0.0)

	akVictim.DamageAV("Stamina",akVictim.GetActorValue("Stamina"))
	akVictim.DamageAV("Magicka",akVictim.GetActorValue("Magicka"))

	LastUpdateTime= Utility.GetCurrentGameTime()

	RegisterForSingleUpdate(90) 								;Wait 90 seconds in real time before effect decay begins
	RegisterForSleep() 
endevent

event OnUpdate()
	NotifyPlayer("You desperately need rest...")
	RegisterForSingleUpdateGameTime(0.1)						;6 min updates to stat rate = 1% mult gain if not sleeping
endevent

Event OnUpdateGameTime() 

	float Currentgametime = Utility.GetCurrentGameTime()
	Elapsedtime = (Currentgametime - LastUpdateTime) * 24

	LastUpdateTime = Currentgametime

	statMult = statMult + (Elapsedtime * ImproveRate) + sleepbonus
	speedmult = speedmult + (Elapsedtime * moverecoveryrate) + sleepbonus

	if hasslept 												;Give sleep bonus
		statMult = statMult + sleepbonus
		speedmult = speedmult + sleepbonus
		hasslept = false
		if statMult >= 100.0
			NotifyPlayer("You have slept off the effects of the Dwemer device...")
		endif
	endif

	If statMult >= 100.0
		self.dispel()											;Recovery is complete
	else
		akVictim.setAV("StaminaRateMult",statMult)

		akVictim.setAV("MagickaRateMult",statMult)
	
		if speedmult < 100.0 ; need to handle enc?
			akVictim.setAV("speedmult",speedmult)
		elseif !recoveredspeedmult
			akVictim.setAV("speedmult",100.0) 
			recoveredspeedmult = true
			NotifyPlayer("Your legs no longer feel weak...")
		endif
		RegisterForSingleUpdateGameTime(0.1)
	endif
endevent


Event OnSleepStart(Float afSleepStartTime, Float afDesiredSleepEndTime) 
	SleepstartTime = afSleepStartTime
	hasslept = true
endevent

Event OnSleepStop(Bool abInterrupted) 
	sleepbonus = sleeprate * ((Utility.GetCurrentGameTime() - Sleepstarttime) * 24)
endevent


Event OnEffectFinish(Actor akTarget, Actor akCaster) 
	akTarget.setAV("StaminaRateMult",100.0) 					;Failsafe: back to 100 for akTarget on dispel
	akTarget.setAV("MagickaRateMult",100.0)
	if !recoveredspeedmult
		akTarget.setAV("speedmult",100.0)
	endif
endevent

function NotifyPlayer(string strNotification)
	if IsPlayer
		Debug.notification(strNotification)
	endif
endfunction
