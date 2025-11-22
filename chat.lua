local ADDON_NAME, WoWofEmpires = ...
WoWofEmpires = WoWofEmpires or {}
WoWofEmpires.Chat = WoWofEmpires.Chat or {}

local playerName = UnitName("player")
local IntToSound = WoWofEmpires.Config.IntToSound
local StringToSound = WoWofEmpires.Config.StringToSound
local chatEvents = WoWofEmpires.Config.chatEvents

local lastFiveSounds = {}
local currentHandle

local chatFrame = CreateFrame("Frame")
for i = 1, #chatEvents do
    chatFrame:RegisterEvent(chatEvents[i])
end

chatFrame:SetScript("OnEvent", function(self, event, text, sender)
    if not WoWofEmpiresDB or not WoWofEmpiresDB.disabledList then
        return
    end
    
    local eventCheck = false
    currentHandle = nil
    
    for i = 1, #chatEvents do
        if event == chatEvents[i] then
            eventCheck = true
            break
        end
    end
    
    if eventCheck == true then
        local ttsSTR = string.sub(text, 1, 4)
        if ttsSTR == "tts:" then
            local newText = text:sub(string.len(ttsSTR))
            EmpireSay(newText)
        end
        
        local fplayerName = playerName .. "-" .. GetRealmName()
        local spamSTR = string.sub(text, 1, 5)
        if spamSTR == "spam:" and sender == fplayerName then
            local newText = text:sub(2 + string.len(spamSTR))
            EmpireWhisper(newText)
        end
        
        if event == "CHAT_MSG_GUILD" and text == "!kos" and sender == fplayerName and Spy ~= nil then
            local namesSent = ""
            for k, v in pairs(SpyPerCharDB["PlayerData"]) do
                if v.kos == 1 then
                    C_ChatInfo.SendAddonMessage("WoWofEmpiresKoS", v.name, "GUILD")
                    namesSent = v.name .. ", " .. namesSent
                end
            end
            print("Shared: " .. namesSent .. "to guild.")
        end
    end
    
    if (eventCheck == true and not (WoWofEmpiresDB.disabledList[string.lower(text)] or WoWofEmpiresDB.disabledList[tonumber(text)])) then
        if StringToSound[tostring(string.lower(text))] ~= nil then
            _, currentHandle = EmpirePlay("" .. StringToSound[tostring(string.lower(text))])
        end
        if IntToSound[tonumber(text)] ~= nil then
            _, currentHandle = EmpirePlay("" .. IntToSound[tonumber(text)])
        end
        if #lastFiveSounds > 4 then
            table.remove(lastFiveSounds, 1)
        end
        table.insert(lastFiveSounds, currentHandle)
    end
end)

function WoWofEmpires.Chat.StopLastSounds()
    for i = 1, #lastFiveSounds do
        local handle = lastFiveSounds[i]
        if handle then
            StopSound(handle, 500)
        end
    end
end

WoWofEmpires.Chat.GetCurrentHandle = function()
    return currentHandle
end
