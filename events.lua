local ADDON_NAME, WoWofEmpires = ...
WoWofEmpires = WoWofEmpires or {}
WoWofEmpires.Events = WoWofEmpires.Events or {}

local playerName = UnitName("player")

local partyInviteFrame = CreateFrame("Frame")
partyInviteFrame:RegisterEvent("PARTY_INVITE_REQUEST")
partyInviteFrame:SetScript("OnEvent", function(self, event, name)
    C_FriendList.ShowFriends()
    if (WoWofEmpires.Utils.IsFriend(name) or WoWofEmpires.Utils.IsBnetFriend(name)) and WoWofEmpiresDB.autoInv then
        for i = 1, STATICPOPUP_NUMDIALOGS do
            local staticpopup = _G["StaticPopup" .. i]
            if staticpopup:IsVisible() and staticpopup.which == "PARTY_INVITE" then
                StaticPopup_OnClick(staticpopup, 1)
            end
        end
    end
end)

local whisperInviteFrame = CreateFrame("Frame")
whisperInviteFrame:RegisterEvent("CHAT_MSG_WHISPER")
whisperInviteFrame:SetScript("OnEvent", function(self, event, text, sender)
    local r = {}
    for word in sender:gmatch("[^-]+") do
        table.insert(r, word)
    end
    local senderShort = r[1]
    if (WoWofEmpires.Utils.IsFriend(senderShort) or WoWofEmpires.Utils.IsBnetFriend(senderShort)) and WoWofEmpiresDB.autoInv then
        if text == "inv" then
            InviteUnit(sender)
        end
    end
end)

local oorFrame = CreateFrame("Frame")
oorFrame.shouldOOR = true
oorFrame.counter = 0
oorFrame:RegisterEvent("UI_ERROR_MESSAGE")
oorFrame:SetScript("OnEvent", function(self, event, id, str)
    if id == 363 and tonumber((GetCVar("Sound_EnableErrorSpeech"))) > 0 then
        SetCVar("Sound_EnableErrorSpeech", "0")
        if str == "Out of range." and self.shouldOOR then
            if self.counter > 1 then
                self.counter = 0
            end
            self.counter = self.counter + 1
            EmpirePlay("Too_far_away" .. self.counter .. ".ogg")
            self.shouldOOR = false
            C_Timer.After(1, function()
                self.shouldOOR = true
                SetCVar("Sound_EnableErrorSpeech", "1")
            end)
        end
    end
end)

local cleuFrame = CreateFrame("Frame")
cleuFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
cleuFrame:SetScript("OnEvent", function(self, event)
    local timestamp, subevent, hideCaster, sourceGUID, sourceName, SourceFlags, SourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, _, spellType = CombatLogGetCurrentEventInfo()
    local targetName = UnitName("target") or "noTarget"
    
    if subevent == "SPELL_AURA_APPLIED" and spellName == "Mind Control" and destName == playerName then
        EmpirePlay("Ingemar-Franko.mp3")
    end
    
    if subevent == "SPELL_AURA_APPLIED" and (spellName == "Web" and destName == targetName) then
        EmpirePlay("spindelnat.ogg")
    end
    
    if subevent == "SPELL_AURA_APPLIED" and spellName == "Shadow Trance" and destName == playerName then
        EmpirePlay("ShadowTrance.ogg")
    end
    
    if subevent == "SPELL_AURA_BROKEN_SPELL" then
        local timestamp, subevent, hideCaster, sourceGUID, sourceName, SourceFlags, SourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, _, spellType, extraSpellId, extraSpellName, extraSchool, auraType = CombatLogGetCurrentEventInfo()
        print(spellName .. " broken by: " .. sourceName .. " on: " .. destName)
    end
    
    if subevent == "SPELL_CAST_SUCCESS" then
        if spellName == "Death Coil" and destName == playerName then
            EmpirePlay("vemvare.ogg")
        end
        if spellName == "Blink" and sourceName == playerName then
            local channel
            if UnitInParty("player") then
                channel = "PARTY"
            else
                channel = "SAY"
            end
            
            local i = math.random(1, 10)
            if i == 1 then
                C_ChatInfo.SendAddonMessage("WoWofEmpires2", "blinkCastSuccess", channel)
            end
        end
    end
    
    if subevent == "PARTY_KILL" and UnitInBattleground("player") == nil then
        locClass = GetPlayerInfoByGUID(destGUID)
        if locClass ~= nil then
            print("VILKET NYP!!!!!!!")
            EmpirePlay("Herb_laugh.ogg")
        end
    end
end)

local itemSoundHandle = 1
local lootFrame = CreateFrame("Frame")
lootFrame:RegisterEvent("START_LOOT_ROLL")
lootFrame:SetScript("OnEvent", function(_, _, id)
    if not id then return end
    local texture, name, count, quality = GetLootRollItemInfo(id)
    local rollLink = GetLootRollItemLink(id)
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(rollLink)
    if itemEquipLoc == "INVTYPE_FINGER" then
        StopSound(itemSoundHandle)
        _, itemSoundHandle = EmpirePlay("welkenring.ogg")
    elseif quality > 2 then
        EmpirePlay("Sopahit.ogg")
    end
end)

local addonFrame = CreateFrame("Frame")
addonFrame:RegisterEvent("CHAT_MSG_ADDON")
C_ChatInfo.RegisterAddonMessagePrefix("WoWofEmpires2")
C_ChatInfo.RegisterAddonMessagePrefix("WoWofEmpiresKoS")
addonFrame:SetScript("OnEvent", function(self, event, prefix, text, chan)
    if prefix == "WoWofEmpires2" and text == "blinkCastSuccess" then
        EmpirePlay("blink.ogg")
        print("Här kan man va!")
    end
    
    if prefix == "WoWofEmpiresKoS" and Spy ~= nil then
        if SpyPerCharDB["PlayerData"][text] == nil then
            Spy:ToggleKOSPlayer(true, text)
        end
    end
end)

local levelupFrame = CreateFrame("Frame")
levelupFrame:RegisterEvent("PLAYER_LEVEL_UP")
levelupFrame:SetScript("OnEvent", function(self, event)
    if UnitInParty("player") then
        SendChatMessage("snoop", "PARTY")
    else
        SendChatMessage("snoop", "EMOTE")
    end
end)

local shouldRun = true
local function checkHealth()
    local healthPercentage = UnitHealth("player") / UnitHealthMax("player")
    
    if healthPercentage >= 0.3 then
        shouldRun = true
    end
    
    if healthPercentage < 0.3 and shouldRun == true then
        if UnitInParty("player") == true and not WoWofEmpires.Utils.inPublicParty() then
            SendChatMessage("18", "PARTY")
        end
        shouldRun = false
    end
end

local healthFrame = CreateFrame("FRAME")
healthFrame:RegisterEvent("UNIT_HEALTH_FREQUENT")
healthFrame:SetScript("OnEvent", function(self, event, unit)
    if unit == "player" then
        checkHealth()
    end
end)
