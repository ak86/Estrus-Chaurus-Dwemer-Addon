Scriptname zzEstrusDwemer_HachlingScript extends Actor

;not used in ED as there no hatchings yet

SPELL Property crSpider01PoisonSpit Auto

event OnLoad()
	self.SetAV("SpeedMult", 150.0 / Self.GetScale() )
endEvent

event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
	self.RemoveAllItems()

	if ( self.GetScale() >= 5.0 && !self.HasSpell(crSpider01PoisonSpit) )
		self.AddSpell( crSpider01PoisonSpit )
	endIf
endEvent
