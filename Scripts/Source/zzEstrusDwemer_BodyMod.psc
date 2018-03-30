Scriptname zzEstrusDwemer_BodyMod extends Quest

Function SetNodeScale(Actor akActor, string nodeName, float value, bool isFemale)
	string modName = "Estrus_Dwemer"
	;Debug.Notification(akActor.GetLeveledActorBase().GetName() + " zzestrusDwemerae_BodyMod Scaling " + nodeName + " to " + value)
	
	If Game.GetModbyName("SexLab Inflation Framework.esp") != 255
		string SLIF_modName = "Estrus Dwemer"
		string sKey = ""
		
		If nodeName == "NPC L Breast"
			sKey = "slif_breast"
		ElseIf nodeName == "NPC L Breast01"
			sKey = "slif_breast01"
		ElseIf nodeName == "NPC L Breast P1"
			sKey = "slif_breast_p"
		ElseIf nodeName == "NPC L GenitalsScrotum [LGenScrot]"
			sKey = "slif_scrotum"
		ElseIf nodeName == "NPC Belly"
			sKey = "slif_belly"
		EndIf
		
		If (sKey != "")
			int SLIF_inflate = ModEvent.Create("SLIF_inflate")
			If (SLIF_inflate)
				ModEvent.PushForm(SLIF_inflate, akActor)
				ModEvent.PushString(SLIF_inflate, SLIF_modName)
				ModEvent.PushString(SLIF_inflate, sKey)
				ModEvent.PushFloat(SLIF_inflate, value)
				ModEvent.PushString(SLIF_inflate, modName)
				ModEvent.Send(SLIF_inflate)
			EndIf
		EndIf
	ElseIf NetImmerse.HasNode(akActor, nodeName, false)
		If SKSE.GetPluginVersion("NiOverride") >= 3 && NiOverride.GetScriptVersion() >= 2								;nioverride, if value = 1, mod is removed from skse nio scaling
			if akActor == Game.GetPlayer()																				;update 1st person view/skeleton (player only)
				If value != 1.0
					NiOverride.AddNodeTransformScale(akActor, true, isFemale, nodeName, modName, value)
				Else
					NiOverride.RemoveNodeTransformScale(akActor, true, isFemale, nodeName, modName)
				Endif
				NiOverride.UpdateNodeTransform(akActor, true, isFemale, nodeName)
			endif
			If value != 1.0																								;update 3rd person view/skeleton (player & NPCs)
				NiOverride.AddNodeTransformScale(akActor, false, isFemale, nodeName, modName, value)
			Else
				NiOverride.RemoveNodeTransformScale(akActor, false, isFemale, nodeName, modName)
			Endif
			NiOverride.UpdateNodeTransform(akActor, false, isFemale, nodeName)
		Endif
	Endif
EndFunction

float Function GetNodeScale(Actor akActor, string nodeName, bool isFemale)
	string modName = "Estrus_Dwemer"
	;Debug.Notification(akActor.GetLeveledActorBase().GetName() + " zzestrusDwemerae_BodyMod Scaling " + nodeName + " to " + value)
	float default = 1
	If NetImmerse.HasNode(akActor, nodeName, false)
		If SKSE.GetPluginVersion("NiOverride") >= 3 && NiOverride.GetScriptVersion() >= 2								;nioverride, if value = 1, mod is removed from skse nio scaling
			If (NiOverride.HasNodeTransformScale(akActor, false, isFemale, nodeName, modName))
				default = NiOverride.GetNodeTransformScale(akActor, false, isFemale, nodeName, modName)
			Endif
		Endif
	Endif
	If Game.GetModbyName("SexLab Inflation Framework.esp") != 255
		string sKey = ConvertNodeToKey(nodeName)
		if (sKey != "")
			return StorageUtil.GetFloatValue(akActor, "Estrus Dwemer" + sKey, default)
		endIf
	Endif
	return default
EndFunction

string function ConvertNodeToKey(String nodeName)
	int index = JsonUtil.StringListFind("SexLab Inflation Framework/Lists.json", "nodes", nodeName)
	if (index != -1)
		return JsonUtil.StringListGet("SexLab Inflation Framework/Lists.json", "keys", index)
	endIf
	return ""
endFunction
