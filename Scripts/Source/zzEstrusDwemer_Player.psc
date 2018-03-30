Scriptname zzEstrusDwemer_Player extends ReferenceAlias

event OnPlayerLoadGame()
	Quest me = self.GetOwningQuest()

	( me as zzEstrusDwemer_MCMScript ).registerMenus()	;start/restart mcm on saveload
	( me as zzEstrusDwemer_Events ).InitModEvents()		;register estrus anims/event
	( me as zzEstrusDwemer_AE ).RegisterForSLDwemer()	;register sexlab anims/event

endEvent
