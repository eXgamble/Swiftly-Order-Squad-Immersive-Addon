Scriptname qfcAliasScript extends ReferenceAlias  

message property qfcMessage auto
actor property playerRef auto
string property waitingText auto
string property stopWaitingText auto
FormList property qfcList Auto
FormList property qfcDisabledList auto
FormList property qfcBlockList auto
faction property PetFramework_PetFollowingFaction auto

int hotkey
int stopWaitingHotkey
int startWaitingHotkey
int inventoryHotkey
int teleportHotkey
Bool hasFollowers = false	

ReferenceAlias Property Character Auto  
Float distance = 100.0

event OnPlayerLoadGame()
	SetUp()
endEvent

event OnInit()
	SetUp()
endEvent

function checkPapyrusUtil()
	if !PapyrusUtil.GetVersion()
		Debug.MessageBox(\
			"PapyrusUtil is not correctly installed in your game. This is user error on your part. " +\
			"You must fix this by installing the correct version of PapyrusUtil for your Skyrim and SKSE versions.\n\n" +\
			"Popular mods known to contain outdated and broken versions of PapyrusUtil include: \n"+\
			"1. Campfire - Complete Camping System\n2. Wearable Lanterns MCM Fix.\n\n" +\
			"This error message is accurate and should not be ignored."\
		)
;		Utility.Wait(0.1)
;		Debug.QuitGame()
	endIf
endFunction

; Notification text and gather settings, overridable in Data\SOS Immersive Settings.json.
; A missing file or key falls back to the default.
string function SettingsFile()
	return "../../../SOS Immersive Settings.json"
endFunction

string function Str(string keyName, string default)
	return JsonUtil.GetStringValue(SettingsFile(), keyName, default)
endFunction

int function Cfg(string keyName, int default)
	return JsonUtil.GetIntValue(SettingsFile(), keyName, default)
endFunction

; Helper function to refresh our array data right when a key is pressed
Function UpdateFollowerState()
	hasFollowers = false
	; GetPlayerFollowers() only sees actors loaded near the player, so waiting followers
	; left far behind or in another cell are missed. qfcList tracks them regardless of location.
	int n = qfcList.GetSize()
	while n && !hasFollowers
		n -= 1
		Actor follower = qfcList.GetAt(n) as Actor
		if IsFollower(follower) && !IsDismissedCustomFollower(follower)
			hasFollowers = true
		endIf
	endWhile
	if !hasFollowers
		Actor[] activeSquad = PO3_SKSEFunctions.GetPlayerFollowers()
		hasFollowers = activeSquad && activeSquad.Length > 0
	endif
EndFunction

function SetUp()
	checkPapyrusUtil()
	hotkeyRebind()
	RegisterForModEvent("QuickFollowerMenu", "MenuEvent")
	RegisterForModEvent("QuickFollowerMenu_Toggle", "ToggleEvent")
	RegisterForModEvent("QuickFollowerMenu_Delete", "RemoveEvent")
	refreshProperties()
	refreshModForms()
endFunction

Faction AAEMTindraFollowFaction
Faction DismissedFollowerFactionVilja
Keyword LocTypeHold
WorldSpace Tamriel
WorldSpace[] cityWorlds
MiscObject ABRKnockoutToken
function refreshModForms()
	; Optional mods: only look them up when loaded, so users without them get no log errors
	ABRKnockoutToken = None
	if IsPluginLoaded("ANDR_Bleedout_Revamp.esp")
		; Andrealletius' Bleedout Revamp marks knocked-out actors with this token
		ABRKnockoutToken = Game.GetFormFromFile(0x807, "ANDR_Bleedout_Revamp.esp") as MiscObject
	endIf
	AAEMTindraFollowFaction = None
	DismissedFollowerFactionVilja = None
	if IsPluginLoaded("EMCompViljaSkyrim.esp")
		AAEMTindraFollowFaction = Game.GetFormFromFile(0x1FB779, "EMCompViljaSkyrim.esp") as Faction
		DismissedFollowerFactionVilja = Game.GetFormFromFile(0xD6867, "EMCompViljaSkyrim.esp") as Faction
	endIf
	LocTypeHold = Game.GetFormFromFile(0x16771, "Skyrim.esm") as Keyword
	Tamriel = Game.GetFormFromFile(0x3C, "Skyrim.esm") as WorldSpace
	; City worldspaces laid out on Tamriel's coordinates, so positions compare directly across them
	cityWorlds = new WorldSpace[6]
	cityWorlds[0] = Game.GetFormFromFile(0x1A26F, "Skyrim.esm") as WorldSpace ; WhiterunWorld
	cityWorlds[1] = Game.GetFormFromFile(0x46033, "Skyrim.esm") as WorldSpace ; WhiterunDragonsreachWorld
	cityWorlds[2] = Game.GetFormFromFile(0x1691D, "Skyrim.esm") as WorldSpace ; WindhelmWorld
	cityWorlds[3] = Game.GetFormFromFile(0x16BB4, "Skyrim.esm") as WorldSpace ; RiftenWorld
	cityWorlds[4] = Game.GetFormFromFile(0x16D71, "Skyrim.esm") as WorldSpace ; MarkarthWorld
	cityWorlds[5] = Game.GetFormFromFile(0x37EDF, "Skyrim.esm") as WorldSpace ; SolitudeWorld
endFunction

function refreshProperties()
	qfcMessage = Game.GetFormFromFile(0x801, "Quick Follower Commands.esp") as message
	qfcList = Game.GetFormFromFile(0x804, "Quick Follower Commands.esp") as formList
	qfcDisabledList = Game.GetFormFromFile(0xB06, "Quick Follower Commands.esp") as formList
	qfcBlockList = Game.GetFormFromFile(0x810, "Quick Follower Commands.esp") as formList
endFunction

function hotkeyRebind()
	string fileName = "../../../Quick Follower Commands.json"
	unregisterForAllKeys()

	hotkey = JsonUtil.GetIntValue(fileName, "dxcode", -1)
	stopWaitingHotkey = JsonUtil.GetIntValue(fileName, "qfc_stopWaiting", -1)
	startWaitingHotkey = JsonUtil.GetIntValue(fileName, "qfc_startWaiting", -1)
	inventoryHotkey = JsonUtil.GetIntValue(fileName, "qfc_inventory", -1)
	teleportHotkey = JsonUtil.GetIntValue(fileName, "qfc_teleport", -1)

	RegisterForKey(hotkey)
	registerforkey(stopWaitingHotkey)
    registerforkey(startWaitingHotkey)
    registerforkey(inventoryHotkey)
    registerforkey(teleportHotkey)
endfunction

state busy
	event OnKeyDown(int keyCode)
	endEvent

	function showMenu()
	endFunction
endState

event OnKeyDown(int keyCode)
	if !Utility.IsInMenuMode() && !UI.IsMenuOpen("Crafting Menu") && !UI.IsMenuOpen("RaceSex Menu") && !UI.IsMenuOpen("CustomMenu")
		UpdateFollowerState()

		if keyCode == hotkey
			if !hasFollowers
				Debug.Notification(Str("noCompany", "You find yourself without company on this trek."))
			else
				showMenu()
			endif
		elseif keyCode == stopWaitingHotkey
			if !hasFollowers
				Debug.Notification(Str("noneToFollow", "There are no party members to follow you."))
			else
				cleanUp()
				doCommand("StopWaiting")
			endif
		elseif keyCode == startWaitingHotkey
			if !hasFollowers
				Debug.Notification(Str("noneToWait", "There are no party members to wait for you."))
			else
				cleanUp()
				doCommand("StartWaiting")
			endif
		elseif keyCode == inventoryHotkey
			if !hasFollowers
				Debug.Notification(Str("noneToTrade", "You have no party members to trade with."))
			else
				cleanUp()
				doCommand("Inventory")
			endif
		elseif ( Game.GetPlayer().GetCombatState() != 0 ) && keyCode == teleportHotkey
			Debug.Notification(Str("enemiesNearby", "You can not do this while enemies are nearby!"))
		elseif ( Game.GetPlayer().GetCombatState() == 0 ) && keyCode == teleportHotkey
			if !hasFollowers
				Debug.Notification(Str("noneToGather", "You have no party members to gather."))
			elseif CanGatherParty()
				cleanUp()
				GatherParty()
			endif
		endIf
	endif
endEvent

function showMenu()
	UpdateFollowerState()

	if !hasFollowers
		Debug.Notification(Str("noCompany", "You find yourself without company on this trek."))
	else
		GotoState("busy")
		ui.OpenCustomMenu("mfc_menu")
		Game.SetHudCartMode(true)
		int i = checkAndSendInfo()
		UICallback.Send(i)
		while(Utility.IsInMenuMode())
			Utility.Wait(0.1)
		endWhile
		GotoState("")
	endif
endFunction

int function checkAndSendInfo()
	int i = UICallback.create("CustomMenu", "_root.QuickFollowerMenu_mc.getFollowersFromString")
	UiCallback.PushString(i, getFollowerString(qfcList)) ;as2 doesn't support named arguements, so we have to send all three always.
	UiCallback.PushString(i, getFollowerString(qfcDisabledList))
	return i
endFunction

string function cleanUp()
	Form[] arr = qfcList.ToArray()
	int n = arr.Length
	while n
		n -= 1
		Form followerForm = arr[n]
		if !IsFollower(followerForm)
			qfcList.RemoveAddedForm(followerForm)
		endIf
	endWhile
endFunction

string function getFollowerString(formlist f)
	string ret = ""
	Form[] arr = f.ToArray()
	int n = arr.Length
	while n
		n -= 1
		Form followerForm = arr[n]
		Actor follower = followerForm as Actor
		if IsFollower(followerForm)
			if !IsDismissedCustomFollower(follower)
				ret += follower.GetDisplayName()+","+follower.getFormID()+","
			endIf
		else
			f.RemoveAddedForm(followerForm)
		endIf
	endWhile
	return ret
endfunction

event RemoveEvent(string eventName, string strArg, float numArg, Form sender)
    qfcList.RemoveAddedForm(sender)
    qfcDisabledList.RemoveAddedForm(sender)
	qfcBlockList.AddForm(sender)
endEvent

Event ToggleEvent(string eventName, string strArg, float numArg, Form sender)
	if numArg == 0
		qfcDisabledList.AddForm(sender)
	else
		qfcDisabledList.RemoveAddedForm(sender)
	endif
endEvent

Event MenuEvent(string eventName, string strArg, float numArg, Form sender)
	if strArg == "CloseMenuNoChoice"
		Game.SetHudCartMode(false)
	elseif strArg == "Teleport" && ( Game.GetPlayer().GetCombatState() == 0 ) && !CanGatherParty()
		Game.SetHudCartMode(false)
	elseif strArg == "Teleport" && ( Game.GetPlayer().GetCombatState() == 0 )
		GatherParty()
	elseif strArg == "Teleport" && ( Game.GetPlayer().GetCombatState() != 0 )
		Debug.Notification(Str("enemiesNearby", "You can not do this while enemies are nearby!"))
	else
		doCommand(strArg)
	endif
endEvent

; True if at least one follower doCommand("Teleport") would act on is fit to travel.
; Otherwise explains why and returns false, so no time passes for an empty gathering.
bool Function CanGatherParty()
	bool anyWounded = false
	int n = qfcList.GetSize()
	while n
		n -= 1
		Actor follower = qfcList.GetAt(n) as Actor
		if IsFollower(follower) && !qfcDisabledList.HasForm(follower) && !IsDismissedCustomFollower(follower)
			if !IsDown(follower)
				return true
			endIf
			anyWounded = true
		endIf
	endWhile
	if anyWounded
		Debug.Notification(Str("companionsWounded", "Your companions are in no state to travel."))
	else
		Debug.Notification(Str("noneToGather", "You have no party members to gather."))
	endIf
	return false
EndFunction

; Travel time is set by the furthest follower who will actually come. 0 hours = fade only.
Function GatherParty()
	int hours = GetGatherHours() ; measure before anyone is moved
	Debug.Notification(Str("gathering", "You spend sometime to gather your party."))
	Game.FadeOutGame(false, true, 2.0, 1.0)
	doCommand("Teleport")
	if hours > 0
		AdvanceGameTime(hours)
	endIf
	Utility.Wait(3)
EndFunction

int Function GetGatherHours()
	int hours = 0
	int n = qfcList.GetSize()
	while n
		n -= 1
		Actor follower = qfcList.GetAt(n) as Actor
		if IsFollower(follower) && !qfcDisabledList.HasForm(follower) && !IsDismissedCustomFollower(follower) && !IsDown(follower)
			int h = GetTravelHours(follower)
			if h > hours
				hours = h
			endIf
		endIf
	endWhile
	int maxHours = Cfg("gatherMaxHours", 24)
	if hours > maxHours
		hours = maxHours
	endIf
	return hours
EndFunction

int Function GetTravelHours(Actor follower)
	; Both outdoors on the same map: use the real distance
	if SharesMapSpace(playerRef, follower)
		float dx = playerRef.GetPositionX() - follower.GetPositionX()
		float dy = playerRef.GetPositionY() - follower.GetPositionY()
		float dist = Math.Sqrt(dx * dx + dy * dy)
		int h = (dist / Cfg("gatherUnitsPerHour", 16000)) as int
		GatherDebug(follower, "distance " + (dist as int) + " = " + h + "h")
		return h
	endIf

	; Otherwise compare locations: Breezehome -> Whiterun -> Whiterun Hold -> Tamriel
	Location playerLoc = playerRef.GetCurrentLocation()
	Location followerLoc = follower.GetCurrentLocation()
	if !playerLoc || !followerLoc
		GatherDebug(follower, "no location = unknown")
		return Cfg("gatherUnknownHours", 3)
	endIf
	Location common = GetCommonLocation(playerLoc, followerLoc)
	if !common
		GatherDebug(follower, "no shared location = unrelated")
		return Cfg("gatherUnrelatedHours", 8)
	elseIf common.HasKeyword(LocTypeHold)
		GatherDebug(follower, "same hold (" + common.GetName() + ")")
		return Cfg("gatherSameHoldHours", 4)
	elseIf !PO3_SKSEFunctions.GetParentLocation(common)
		GatherDebug(follower, "only share " + common.GetName() + " = unrelated")
		return Cfg("gatherUnrelatedHours", 8)
	endIf
	; A shared town, city, settlement, dungeon or building
	GatherDebug(follower, "same area (" + common.GetName() + ")")
	return 0
EndFunction

bool Function SharesMapSpace(Actor a, Actor b)
	if a.IsInInterior() || b.IsInInterior()
		return false
	endIf
	WorldSpace worldA = GetMapWorld(a.GetWorldSpace())
	return worldA && worldA == GetMapWorld(b.GetWorldSpace())
EndFunction

WorldSpace Function GetMapWorld(WorldSpace world)
	if world && cityWorlds && cityWorlds.Find(world) >= 0
		return Tamriel
	endIf
	return world
EndFunction

; The smallest location containing both, or None
Location Function GetCommonLocation(Location a, Location b)
	Location candidate = a
	int guard = 0
	while candidate && guard < 20
		if IsWithinLocation(b, candidate)
			return candidate
		endIf
		candidate = PO3_SKSEFunctions.GetParentLocation(candidate)
		guard += 1
	endWhile
	return None
EndFunction

bool Function IsWithinLocation(Location loc, Location ancestor)
	int guard = 0
	while loc && guard < 20
		if loc == ancestor
			return true
		endIf
		loc = PO3_SKSEFunctions.GetParentLocation(loc)
		guard += 1
	endWhile
	return false
EndFunction

Function GatherDebug(Actor follower, string msg)
	if Cfg("gatherDebug", 0)
		Debug.Notification(follower.GetDisplayName() + ": " + msg)
	endIf
EndFunction

Function doCommand(string command)
	Game.SetHudCartMode(false)
	int n = qfcList.GetSize()
	while n
		n -= 1
		Actor follower = qfcList.GetAt(n) as Actor
		if IsFollower(follower) && !qfcDisabledList.HasForm(follower) && !IsDismissedCustomFollower(follower)
			doFollower(command, follower)
		endIf
	endWhile
endFunction

function doFollower(string command, Actor follower)
	if  command != "Teleport" && Game.GetPlayer().GetDistance(follower) >= 2000
		Debug.Notification(follower.GetDisplayName() + Str("tooFar", " is too far away to receive your commands!"))
	elseIf command == "StartWaiting" && Game.GetPlayer().GetDistance(follower) < 2000
		WaitActor(follower)
	elseIf command == "StopWaiting" && Game.GetPlayer().GetDistance(follower) < 2000
		StopWaitingActor(follower)
	elseIf command == "Inventory" && Game.GetPlayer().GetDistance(follower) < 2000
		OpenInventoryActor(follower)
	elseIf command == "Teleport" && IsDown(follower)
		Debug.Notification(follower.GetDisplayName() + Str("tooWounded", " is too wounded to rejoin you."))
	elseIf command == "Teleport"
		follower.MoveTo(playerRef)
	endIf
endFunction

function OpenInventoryActor(actor akActor)
	while Utility.IsInMenuMode()
		Utility.Wait(0.5)
	endWhile
	akActor.OpenInventory(true)
endFunction

function StopWaitingActor(actor akActor)
	if akActor.GetActorValue("WaitingForPlayer")
		akActor.SetActorValue("WaitingForPlayer", 0)
		akActor.EvaluatePackage()
		Debug.Notification(akActor.GetDisplayName() + Str("stopWaiting", stopWaitingText))
	endIf
endFunction

function WaitActor(actor akActor)
	if !akActor.GetActorValue("WaitingForPlayer")
		akActor.SetActorValue("WaitingForPlayer", 1)
		akActor.EvaluatePackage()
		Debug.Notification(akActor.GetDisplayName() + Str("startWaiting", waitingText))
	endIf
endFunction

; Regular (255 = not loaded) or light (65535 = not loaded) plugin
bool function IsPluginLoaded(string fileName)
	return Game.GetModByName(fileName) != 255 || Game.GetLightModByName(fileName) != 65535
endFunction

; Bleeding out, or knocked out by Bleedout Revamp (which swaps bleedout for paralysis + unconsciousness)
bool function IsDown(Actor akActor)
	if akActor.IsBleedingOut()
		return true
	endIf
	return ABRKnockoutToken && akActor.GetItemCount(ABRKnockoutToken) > 0
endFunction

bool function IsFollower(Form akForm)
	Actor akActor = akForm as Actor
	If !akActor
		Return False
	ElseIf akActor.IsDead()
		Return False
	ElseIf akActor.IsDisabled()
		Return False
	Else
		Return akActor.IsPlayerTeammate() || akActor.GetFactionRank(PetFramework_PetFollowingFaction) >= 1
	EndIf
endFunction

bool function IsDismissedCustomFollower(actor akActor)
	if DismissedFollowerFactionVilja && akActor.IsInFaction(DismissedFollowerFactionVilja)
		return true
	endIf
	if AAEMTindraFollowFaction && akActor.GetFactionRank(AAEMTindraFollowFaction) == 0
		return true
	endIf
	; This here denotes inigo's dismissed state. This is because inigo does not follow the standard practice of using PlayerTeammate.
	if akActor.GetActorValue("WaitingForPlayer") == -1
		return true
	endIf
	return false
endFunction

Function AdvanceGameTime(int HoursToPass)
	if (HoursToPass <= 0)
		HoursToPass = 1
	EndIf
	GlobalVariable GameHr
	GameHr = Game.GetForm(0x00000038) as GlobalVariable
	float t = GameHr.GetValue()
	GameHr.SetValue(t + HoursToPass)
	if HoursToPass == 1
		Debug.Notification(HoursToPass + Str("hourPassed", " hour has passed"))
	else
		Debug.Notification(HoursToPass + Str("hoursPassed", " hours have passed"))
	endIf
EndFunction
