local ADDON_NAME, WoWofEmpires = ...
WoWofEmpires = WoWofEmpires or {}
WoWofEmpires.Sounds = WoWofEmpires.Sounds or {}

local soundFolder = WoWofEmpires.Config.soundFolder

function EmpirePlay(sound)
    return PlaySoundFile(soundFolder .. sound, "Dialog")
end

function EmpireSay(text)
    return C_VoiceChat.SpeakText(0, text, Enum.VoiceTtsDestination.LocalPlayback, 0, 100)
end

local whisperList = {}
local whisperFrame = CreateFrame("Frame")
whisperFrame:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
whisperFrame:SetScript("OnEvent", function(self, event, text, sender)
    local i, j = string.find(sender, GetRealmName())
    if i ~= nil then
        sender = string.sub(sender, 1, i-2)
    end
    whisperList[sender] = {lastWhisper = GetTime()}
end)

function EmpireWhisper(message)
    for i = 1, C_FriendList.GetNumWhoResults() do
        local name = C_FriendList.GetWhoInfo(i).fullName
        if whisperList[name] == nil or GetTime() - whisperList[name].lastWhisper > 10*60 then
            SendChatMessage(message, "WHISPER", nil, name)
        end
    end
end

local function PlayDeathSound(int)
    if int == nil then
        local i = math.random(5)
        EmpirePlay("death" .. i .. ".mp3")
    else
        EmpirePlay("death" .. int .. ".mp3")
    end
end

local deathFrame = CreateFrame("Frame")
deathFrame:RegisterEvent("PLAYER_DEAD")
deathFrame:SetScript("OnEvent", function(self, event, ...)
    PlayDeathSound()
end)

local raiseFrame = CreateFrame("Frame")
raiseFrame:RegisterEvent("PLAYER_UNGHOST")
raiseFrame:SetScript("OnEvent", function(self, event, ...)
    EmpirePlay("born.mp3")
end)

WoWofEmpires.Sounds.PlayDeathSound = PlayDeathSound
