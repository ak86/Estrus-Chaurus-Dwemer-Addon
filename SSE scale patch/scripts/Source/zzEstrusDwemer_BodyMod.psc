Scriptname zzEstrusDwemer_BodyMod extends Quest

Function SetNodeScale(Actor akActor, string nodeName, float value, bool isFemale)
	If NetImmerse.HasNode(akActor, nodeName, false)
		NetImmerse.SetNodeScale(akActor, nodeName, value, false)
		NetImmerse.SetNodeScale(akActor, nodeName, value, true)
	Endif
EndFunction

float Function GetNodeScale(Actor akActor, string nodeName, bool isFemale)
	float default = 1
	If NetImmerse.HasNode(akActor, nodeName, false)
		return NetImmerse.GetNodeScale(akActor, nodeName, false)
	Endif
	return default
EndFunction

string function ConvertNodeToKey(String nodeName)
endFunction
