-- WoW of Empires: Age of Empires taunts and meme sounds for your group, plus a few
-- quality-of-life helpers. Built for WoW Forever (Midnight client, interface 16001).
local addonName, ns = ...

local SOUND_PATH = "Interface\\AddOns\\WoWofEmpires\\sound\\"
local PREFIX_BLINK, PREFIX_KOS = "WoWofEmpires2", "WoWofEmpiresKoS"

ns.defaults = {
	disabledList = {}, -- muted sounds, keyed like ns.taunts / ns.words
	vendorGrey = false,
	repair = false,
	autoInv = false,
	minimapAngle = 200,
	chatFrame = 1, -- chat tab for the addon's messages (1 = the main tab)
}

-- Saying the number (taunts) or the word (sound bites) in chat plays it for everyone with the addon.
ns.taunts = {
	[1] = "Yes.ogg",
	[2] = "No.ogg",
	[3] = "Food,_please.ogg",
	[4] = "Wood,_please.ogg",
	[5] = "Gold,_please.ogg",
	[6] = "Stone,_please.ogg",
	[7] = "Ahh.ogg",
	[8] = "All_hail.ogg",
	[9] = "Oooh.ogg",
	[10] = "Back_to_age_one.ogg",
	[11] = "Herb_laugh.ogg",
	[12] = "Being_rushed.ogg",
	[13] = "Blame_your_isp.ogg",
	[14] = "Start_the_game.ogg",
	[15] = "Don't_point_that_thing.ogg",
	[16] = "Enemy_sighted.ogg",
	[17] = "It_is_good.ogg",
	[18] = "I_need_a_monk.ogg",
	[19] = "Long_time_no_siege.ogg",
	[20] = "My_granny.ogg",
	[21] = "Nice_town_i'll_take_it.ogg",
	[22] = "Quit_touchin.ogg",
	[23] = "Raiding_party.ogg",
	[24] = "Dadgum.ogg",
	[25] = "Smite_me.ogg",
	[26] = "The_wonder.ogg",
	[27] = "You_play_two_hours.ogg",
	[28] = "You_should_see_the_other_guy.ogg",
	[29] = "Roggan.ogg",
	[30] = "Wololo.ogg",
	[31] = "Attack_an_enemy_now.ogg",
	[36] = "Wait_for_my_signal_to_attack.ogg",
	[42] = "What_age_are_you_in.ogg",
	[105] = "Resign.ogg",
}

ns.words = {
	["anton"] = "anton.mp3",
	["aura"] = "Aura.mp3",
	["bitconnect"] = "Bitconnect.ogg",
	["bruh"] = "bruh.mp3",
	["damn"] = "goddamnboah.mp3",
	["dog"] = "Dog.mp3",
	["durudu"] = "durudu.ogg",
	["fahhh"] = "Fahhh.mp3",
	["fake news"] = "fake-news-great.mp3",
	["fast"] = "im-fast-as-fuck-boii-2.mp3",
	["gay"] = "hah-gay.mp3",
	["goat"] = "Thats-why-hes-the-goat.mp3",
	["hehehey"] = "heheheey.ogg",
	["huuu"] = "huuuuuuu.mp3",
	["hype"] = "Zulp Hype.ogg",
	["lightweight"] = "Lightweight-baby.mp3",
	["maths"] = "Quick maths.ogg",
	["nonono"] = "mmhmmhnonono.ogg",
	["ohnono"] = "Oh-no-no-no.mp3",
	["profamity"] = "Watch yo profamity.ogg",
	["rassla"] = "Rassla.mp3",
	["run"] = "run.ogg",
	["sawarim"] = "Sawarim.mp3",
	["skrra"] = "Skrra.ogg",
	["snoop"] = "snoop dogg.mp3",
	["stats"] = "Check the statistacs.ogg",
	["wassawassa"] = "wasa-wasa-wasa-wassup.ogg",
	["whaat"] = "whaaat.ogg",
	["whatsup"] = "wowwowWhatsUp.ogg",
	["whyrun"] = "Why are you running.ogg",
	["wow"] = "wow.ogg",
	["yeboi"] = "heheyeahboy.ogg",
	["yebuddy"] = "Yeah-buddy-lightweight.mp3",
	["zzz"] = "zzz.ogg",
}

-- Auras on you: the client plays these itself, so they work in combat even though addons
-- can't read auras there. Forever keeps Classic spell IDs; the client stops each clip after 5s.
local PLAYER_AURA_SOUNDS = {
	[605] = "Ingemar-Franko.mp3", [10911] = "Ingemar-Franko.mp3", [10912] = "Ingemar-Franko.mp3", -- Mind Control
	[6789] = "vemvare.ogg", [17925] = "vemvare.ogg", [17926] = "vemvare.ogg", -- Death Coil
	[17941] = "ShadowTrance.ogg", -- Shadow Trance
}

------------------------------------------------------------------------
-- Events: one frame, any number of handlers per event.
-- Handlers get (event, ...). Pass unit tokens to register a unit event.
------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
local handlers = {}

-- Runs an event's handlers. Also exposed as ns.Fire so /woe levelup can fake a level-up.
function ns.Fire(event, ...)
	for _, handler in ipairs(handlers[event] or {}) do
		handler(event, ...)
	end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
	ns.Fire(event, ...)
end)

function ns.On(event, handler, ...)
	if not handlers[event] then
		handlers[event] = {}
		if ... then
			eventFrame:RegisterUnitEvent(event, ...)
		else
			eventFrame:RegisterEvent(event)
		end
	end
	table.insert(handlers[event], handler)
end
local On = ns.On

On("ADDON_LOADED", function(_, name)
	if name ~= addonName then return end
	WoWofEmpiresDB = WoWofEmpiresDB or {}
	for key, value in pairs(ns.defaults) do
		if WoWofEmpiresDB[key] == nil then
			WoWofEmpiresDB[key] = type(value) == "table" and CopyTable(value) or value
		end
	end
	ns.db = WoWofEmpiresDB
end)

------------------------------------------------------------------------
-- Sound helpers
------------------------------------------------------------------------
local recentHandles = {}

-- Plays a file from the sound folder on the Dialog channel. Global so macros can use it.
function EmpirePlay(file)
	local willPlay, handle = PlaySoundFile(SOUND_PATH .. file, "Dialog")
	if handle then
		table.insert(recentHandles, handle)
		if #recentHandles > 5 then table.remove(recentHandles, 1) end
	end
	return willPlay, handle
end

-- Text to speech on your own speakers. Global so macros can use it.
function EmpireSay(text)
	C_VoiceChat.SpeakText(0, text, 0, 100)
end

function ns.StopRecentSounds()
	for _, handle in ipairs(recentHandles) do
		StopSound(handle, 500)
	end
	wipe(recentHandles)
end

function ns.SoundFor(key)
	return ns.taunts[key] or ns.words[key]
end

function ns.IsMuted(key)
	return ns.db.disabledList[key] == true
end

function ns.SetMuted(key, muted)
	ns.db.disabledList[key] = muted or nil
end


-- "Oh-no-no-no.mp3" -> "Oh no no no"
function ns.LabelFor(file)
	return (file:gsub("%.%a+$", ""):gsub("[_-]", " "))
end

-- Prints in the chat tab picked in Settings, or the main tab if that tab has been closed.
function ns.Print(message)
	local id = ns.db and ns.db.chatFrame or 1
	local shown, _, docked = select(7, GetChatWindowInfo(id))
	local frame = (shown or docked) and _G["ChatFrame" .. id] or DEFAULT_CHAT_FRAME
	frame:AddMessage("|cffffd100WoW of Empires:|r " .. message)
end

------------------------------------------------------------------------
-- Chat triggers
------------------------------------------------------------------------
-- Forever names can have a surname. UnitName("player") returns it as a second value ("Döds",
-- "Maskinen"), while chat and addon messages carry the joined name ("Döds Maskinen").
local function MyName()
	return NameUtil.GetUnmodifiedUnitFullName("player")
end

local function IsMe(sender)
	return Ambiguate(sender, "short") == MyName()
end

local function IsFriend(name)
	name = Ambiguate(name, "short")
	for i = 1, C_FriendList.GetNumFriends() do
		local info = C_FriendList.GetFriendInfoByIndex(i)
		if info and Ambiguate(info.name, "short") == name then return true end
	end
	for i = 1, BNGetNumFriends() do
		local account = C_BattleNet.GetFriendAccountInfo(i)
		if account and account.gameAccountInfo.characterName == name then return true end
	end
	return false
end

-- "spam: <message>" from you whispers everyone in your last /who results, once per 10 minutes each.
local lastWhisper = {}

On("CHAT_MSG_WHISPER_INFORM", function(_, _, target)
	if issecretvalue(target) then return end
	lastWhisper[Ambiguate(target, "short")] = GetTime()
end)

local function WhisperWhoResults(message)
	for i = 1, C_FriendList.GetNumWhoResults() do
		local name = C_FriendList.GetWhoInfo(i).fullName
		local last = lastWhisper[Ambiguate(name, "short")]
		if not last or GetTime() - last > 600 then
			C_ChatInfo.SendChatMessage(message, "WHISPER", nil, name)
		end
	end
end

-- Spy integration: "!kos" in guild chat shares your kill-on-sight list with guildmates who run this addon.
local function ShareKillOnSight()
	if not (Spy and SpyPerCharDB) then return end
	local names = {}
	for _, player in pairs(SpyPerCharDB.PlayerData) do
		if player.kos == 1 then
			C_ChatInfo.SendAddonMessage(PREFIX_KOS, player.name, "GUILD")
			table.insert(names, player.name)
		end
	end
	ns.Print("Shared " .. #names .. " kill-on-sight name(s) with your guild: " .. table.concat(names, ", "))
end

-- Plays a trigger's sound unless you muted it in the window.
local function PlayKey(key)
	local file = ns.SoundFor(key)
	if file and not ns.IsMuted(key) then
		EmpirePlay(file)
	end
end

local function OnChat(event, text, sender)
	-- Forever hides chat text in restricted content (dungeons, encounters); skip those messages.
	if issecretvalue(text) or issecretvalue(sender) then return end
	local lower = text:lower()

	if lower:sub(1, 4) == "tts:" then
		EmpireSay(strtrim(text:sub(5)))
	elseif lower:sub(1, 5) == "spam:" and IsMe(sender) then
		WhisperWhoResults(strtrim(text:sub(6)))
	elseif lower == "!kos" and event == "CHAT_MSG_GUILD" and IsMe(sender) then
		ShareKillOnSight()
	elseif lower == "inv" and event == "CHAT_MSG_WHISPER" and ns.db.autoInv and IsFriend(sender) then
		C_PartyInfo.InviteUnit(sender)
	end

	PlayKey(tonumber(text) or lower)
end

for _, event in ipairs({
	-- WHISPER_INFORM is your own outgoing whisper, so the sender hears it too.
	"CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE", "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_GUILD",
	"CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
}) do
	On(event, OnChat)
end

C_ChatInfo.RegisterAddonMessagePrefix(PREFIX_BLINK)
C_ChatInfo.RegisterAddonMessagePrefix(PREFIX_KOS)

-- Every copy of the addon joins this channel, so messages reach all addon users on the realm,
-- grouped or not. Chat windows never show it (Blizzard only auto-adds regional channels).
-- Joined a bit after login so General and Trade keep their usual /1 and /2.
local ADDON_CHANNEL = "WoWofEmpires"

On("PLAYER_LOGIN", function()
	-- Forever's UI only uses JoinPermanentChannel; the temporary one (not saved between logins) is preferred if it's there.
	C_Timer.After(15, function() (JoinTemporaryChannel or JoinPermanentChannel)(ADDON_CHANNEL) end)
end)

-- Addon messages never show up in chat; only players with the addon receive them.
-- Sends to your party or raid. Returns false when you're not in a group.
local function SendToGroup(message)
	if not IsInGroup() then return false end
	C_ChatInfo.SendAddonMessage(PREFIX_BLINK, message, IsInRaid() and "RAID" or "PARTY")
	return true
end

-- Sends to every addon user: the shared channel, plus your group (which can span realms).
local function SendToAddonUsers(message)
	local channel = GetChannelName(ADDON_CHANNEL)
	if channel > 0 then
		C_ChatInfo.SendAddonMessage(PREFIX_BLINK, message, "CHANNEL", tostring(channel))
	end
	SendToGroup(message)
end

-- For dots.lua, which shares DoT casts with the group.
ns.PREFIX, ns.SendToGroup, ns.IsMe = PREFIX_BLINK, SendToGroup, IsMe

-- Window click: plays the sound for you and your group, or for everyone with the addon when solo.
-- "Döds Maskinen played Zulp Hype (hype)" in the addon's chat tab, for the clicker and everyone who hears it.
local function SoundLine(name, key)
	local file = ns.SoundFor(key)
	ns.Print(("%s played %s (%s)"):format(name, file and ns.LabelFor(file) or key, key))
end

function ns.Broadcast(key)
	PlayKey(key)
	SoundLine(MyName(), key)
	if not SendToGroup("play:" .. key) then
		SendToAddonUsers("play:" .. key)
	end
end

-- One Snoop per player per level, however many copies of the news arrive: the channel and party
-- both deliver it, and your own message echoes back to you. Copies arrive within a second, so
-- anything after 10 seconds counts as new (that's what lets /woe levelup be repeated).
local announcedAt = {}

local function AnnounceLevel(name, level)
	local key = name .. ":" .. level
	local last = announcedAt[key]
	if last and GetTime() - last < 10 then return false end
	announcedAt[key] = GetTime()
	PlayKey("snoop")
	return true
end

On("CHAT_MSG_ADDON", function(_, prefix, text, _, sender)
	if issecretvalue(prefix) or issecretvalue(text) or issecretvalue(sender) then return end
	local level = prefix == PREFIX_BLINK and text:match("^levelup:(%d+)$")
	local key = prefix == PREFIX_BLINK and text:match("^play:(.+)$")
	if level then
		local name = Ambiguate(sender, "short")
		if AnnounceLevel(name, level) then
			ns.Print(name .. " LEVELED UP to " .. level .. "!")
		end
	elseif key then
		-- The sender already played it and printed the line for themselves.
		if not IsMe(sender) then
			key = tonumber(key) or key
			PlayKey(key)
			SoundLine(Ambiguate(sender, "short"), key)
		end
	elseif prefix == PREFIX_BLINK and text == "lowhp" then
		if not IsMe(sender) then
			PlayKey(18)
			ns.Print(Ambiguate(sender, "short") .. " needs a monk!")
		end
	elseif prefix == PREFIX_BLINK and text == "blinkCastSuccess" then
		EmpirePlay("blink.ogg")
		ns.Print("Här kan man va!")
	elseif prefix == PREFIX_KOS and Spy and SpyPerCharDB and not SpyPerCharDB.PlayerData[text] then
		Spy:ToggleKOSPlayer(true, text)
	end
end)

------------------------------------------------------------------------
-- Game event sounds
------------------------------------------------------------------------
for spellID, file in pairs(PLAYER_AURA_SOUNDS) do
	C_UnitAuras.AddAuraSound(Enum.UnitAuraSoundTrigger.Added, {
		unitToken = "player", spellID = spellID, soundFileName = SOUND_PATH .. file, outputChannel = "Dialog",
	})
end

-- ponytail: Web on your target is matched by name, so it only fires when auras aren't hidden (out of combat).
-- Move it to AddAuraSound with unitToken "target" once the Forever Web spell IDs are known.
On("UNIT_AURA", function(_, _, info)
	local added = info.addedAuras
	if issecretvalue(added) or not added then return end
	for _, aura in ipairs(added) do
		if not issecretvalue(aura) and not issecretvalue(aura.name) and aura.name == "Web" then
			EmpirePlay("spindelnat.ogg")
		end
	end
end, "target")

-- One Blink in ten makes your group play the blink sound.
On("UNIT_SPELLCAST_SUCCEEDED", function(_, _, _, spellID)
	if issecretvalue(spellID) or C_Spell.GetSpellName(spellID) ~= "Blink" or math.random(10) ~= 1 then return end
	C_ChatInfo.SendAddonMessage(PREFIX_BLINK, "blinkCastSuccess", IsInGroup() and "PARTY" or "SAY")
end, "player")

On("PLAYER_DEAD", function()
	EmpirePlay("death" .. math.random(5) .. ".mp3")
end)

On("PLAYER_UNGHOST", function()
	EmpirePlay("born.mp3")
end)

-- You or your party killed an enemy player outside battlegrounds: Herb laughs (taunt 11).
-- The GUID is secret in restricted content (instances), so it stays quiet there.
On("PARTY_KILL", function(_, _, targetGUID)
	if issecretvalue(targetGUID) or UnitInBattleground("player") then return end
	if C_PlayerInfo.GUIDIsPlayer(targetGUID) then
		ns.Print("VILKET NYP!!!!!!!")
		EmpirePlay(ns.taunts[11])
	end
end)

-- Level up: Snoop for you, and an addon message (not visible in chat) so everyone with the addon
-- hears it too and gets a "X LEVELED UP" line.
On("PLAYER_LEVEL_UP", function(_, level)
	if AnnounceLevel(MyName(), tostring(level)) then
		SendToAddonUsers("levelup:" .. level)
	end
end)

-- Low health: health is secret to addons, but Blizzard's red low-health pulse (LowHealthFrame, 35% or
-- less) is not. Each time it starts, you hear "I need a monk" (18), and so does everyone with the
-- addon in your group. Forever blocks addon messages during boss fights, so only you hear it there.
-- ponytail: rides on Blizzard's flash, so it stays silent if "Flash screen at low health" is turned off.
LowHealthFrame:HookScript("OnShow", function()
	-- The same frame also flashes in combat behind full-screen panels; that isn't low health.
	if GetUIPanel("fullscreen") then return end
	PlayKey(18)
	ns.Print(MyName() .. " needs a monk!")
	-- Its own message, so it reads "X needs a monk!" rather than a played sound. Only your party
	-- hears it: "PARTY" is your own group of five even in a raid, and solo it goes nowhere.
	if IsInGroup() then C_ChatInfo.SendAddonMessage(PREFIX_BLINK, "lowhp", "PARTY") end
end)

-- "Out of range": swap the default error voice for alternating "too far away" clips.
local outOfRangeReady, outOfRangeClip = true, 0

On("UI_ERROR_MESSAGE", function(_, errorType)
	if errorType ~= LE_GAME_ERR_OUT_OF_RANGE or not outOfRangeReady then return end
	if not C_CVar.GetCVarBool("Sound_EnableErrorSpeech") then return end
	C_CVar.SetCVar("Sound_EnableErrorSpeech", "0")
	outOfRangeClip = outOfRangeClip % 2 + 1
	EmpirePlay("Too_far_away" .. outOfRangeClip .. ".ogg")
	outOfRangeReady = false
	C_Timer.After(1, function()
		outOfRangeReady = true
		C_CVar.SetCVar("Sound_EnableErrorSpeech", "1")
	end)
end)

-- Rings get their own song (restarted if another ring drops); other rare+ loot gets a cheer.
local ringHandle

On("START_LOOT_ROLL", function(_, rollID)
	local _, _, _, quality = GetLootRollItemInfo(rollID)
	local link = GetLootRollItemLink(rollID)
	local equipLoc = link and select(9, C_Item.GetItemInfo(link))
	if equipLoc == "INVTYPE_FINGER" then
		if ringHandle then StopSound(ringHandle) end
		ringHandle = select(2, EmpirePlay("welkenring.ogg"))
	elseif quality and quality > 2 then
		EmpirePlay("Sopahit.ogg")
	end
end)

------------------------------------------------------------------------
-- Quality of life
------------------------------------------------------------------------
On("MERCHANT_SHOW", function()
	if ns.db.vendorGrey then
		local total, count = 0, 0
		for bag = 0, 4 do
			for slot = 1, C_Container.GetContainerNumSlots(bag) do
				local info = C_Container.GetContainerItemInfo(bag, slot)
				if info and info.quality == Enum.ItemQuality.Poor and not info.hasNoValue then
					total = total + (select(11, C_Item.GetItemInfo(info.itemID)) or 0) * info.stackCount
					count = count + info.stackCount
					C_Container.UseContainerItem(bag, slot)
				end
			end
		end
		if total > 0 then
			ns.Print("Sold " .. count .. " grey item(s) for " .. C_CurrencyInfo.GetCoinTextureString(total))
		end
	end

	if ns.db.repair and CanMerchantRepair() then
		local cost, canRepair = GetRepairAllCost()
		if canRepair then
			RepairAllItems()
			ns.Print("Repaired everything for " .. C_CurrencyInfo.GetCoinTextureString(cost))
		end
	end
end)

On("PARTY_INVITE_REQUEST", function(_, inviter)
	if ns.db.autoInv and IsFriend(inviter) then
		AcceptGroup()
		StaticPopup_Hide("PARTY_INVITE")
	end
end)
