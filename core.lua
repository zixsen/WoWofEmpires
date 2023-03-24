

local soundFolder = "Interface\\AddOns\\WoWofEmpires\\sound\\"
function EmpirePlay(sound)
return PlaySoundFile(soundFolder..""..sound,"Dialog")
end
gSoundFolder = soundFolder
local events = {"CHAT_MSG_YELL","CHAT_MSG_SAY","CHAT_MSG_PARTY","CHAT_MSG_WHISPER","CHAT_MSG_PARTY_LEADER","CHAT_MSG_GUILD","CHAT_MSG_RAID","CHAT_MSG_RAID_LEADER","CHAT_MSG_EMOTE"}
local playerName = UnitName("player")
local IntToSound = {
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
[22]= "Quit_touchin.ogg",
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

local StringToSound = {
["ohnono"] = "Oh-no-no-no.mp3",
["damn"] = "goddamnboah.mp3",
["bruh"] = "bruh.mp3",
["yeaboi"] = "heheyeahboy.ogg",
["anton"] = "anton.mp3",
["zzz"] = "zzz.ogg",
["gay"] = "hah-gay.mp3",
["huuu"] = "huuuuuuu.mp3",
["fake news"] = "fake-news-great.mp3",
["fast"] = "im-fast-as-fuck-boii-2.mp3",
["snoop"] = "snoop dogg.mp3",
["wow"] = "wow.ogg",
["hype"] = "Zulp Hype.ogg",
}


local TEH_SQUAD = {
["Addons"] = true,
["Krasslig"] = true,
["Moffegreven"] = true,
}
local listPopulated = false
local displayList = {};	
 
 

 --YOINKED sorted pairs function ez4me
local function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end
local function DeathSound(int)
if int == nil then
local i = math.random(5)
EmpirePlay("death"..i..".mp3")
else
EmpirePlay("death"..int..".mp3")
end
end
local function DeathEvent(self, event, ...)
    DeathSound()
end
local deathframe = CreateFrame("Frame")
deathframe:RegisterEvent("PLAYER_DEAD")
deathframe:SetScript("OnEvent", DeathEvent)

local function RaiseEvent(self, event, ...)
    EmpirePlay("born.mp3")
end
local raiseframe = CreateFrame("Frame")
raiseframe:RegisterEvent("PLAYER_UNGHOST")
raiseframe:SetScript("OnEvent", RaiseEvent)


local function cleuEvent(self, event)
local timestamp,subevent,hideCaster,sourceGUID,sourceName,SourceFlags,SourceRaidFlags,destGUID,destName,destFlags,destRaidFlags,spellID,spellName,_,spellType = CombatLogGetCurrentEventInfo()

if subevent == "SPELL_AURA_REFRESH" and spellName == "Mind Control" and destName == playerName then
EmpirePlay("Ingemar-Franko.mp3")
end
if subevent == "SPELL_CAST_SUCCESS" then
if spellName == "Death Coil" and destName == playerName then
EmpirePlay("vemvare.ogg")
end
if spellName == "Blink" and sourceName == playerName then
local i = math.random(1,10)
if i == 1 then
EmpirePlay("blink.ogg")
print("Här kan man va!")
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

end

local cleu = CreateFrame("Frame")
cleu:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
cleu:SetScript("OnEvent", cleuEvent)


local minibtn = CreateFrame("Button", nil, Minimap)
minibtn:SetFrameLevel(8)
minibtn:SetSize(32,32)
minibtn:SetMovable(true)
  
minibtn:SetNormalTexture("Interface/COMMON/Indicator-Yellow.png")
minibtn:SetPushedTexture("Interface/COMMON/Indicator-Yellow.png")
minibtn:SetHighlightTexture("Interface/COMMON/Indicator-Yellow.png")

 
 
local myIconPos = 0
 
local function UpdateMapBtn()
local Xpoa, Ypoa = GetCursorPosition()
local Xmin, Ymin = Minimap:GetLeft(), Minimap:GetBottom()
Xpoa = Xmin - Xpoa / Minimap:GetEffectiveScale() + 70
Ypoa = Ypoa / Minimap:GetEffectiveScale() - Ymin - 70
myIconPos = math.deg(math.atan2(Ypoa, Xpoa))
minibtn:ClearAllPoints()
minibtn:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 52 - (80 * cos(myIconPos)), (80 * sin(myIconPos)) - 52)
end
 
minibtn:RegisterForDrag("LeftButton")
minibtn:SetScript("OnDragStart", function()
minibtn:StartMoving()
minibtn:SetScript("OnUpdate", UpdateMapBtn)
end)
 minibtn:RegisterForClicks("AnyUp")
minibtn:SetScript("OnDragStop", function()
minibtn:StopMovingOrSizing();
minibtn:SetScript("OnUpdate", nil)
UpdateMapBtn();
end)
 
minibtn:ClearAllPoints();
minibtn:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 52 - (80 * cos(myIconPos)),(80 * sin(myIconPos)) - 52)
 
local msgFrame = CreateFrame("FRAME", nil, UIParent,BackdropTemplateMixin and "BackdropTemplate") 
local backdropInfo =
{
bgFile = "Interface\\QuestFrame\\QuestBG",
edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
tile = true,
tileEdge = true,
tileSize = 550,
edgeSize = 8,
insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

msgFrame:SetWidth(350)
msgFrame:SetHeight(400)
msgFrame:SetBackdrop(backdropInfo);
msgFrame:SetBackdropColor(255/255,240/255,179/255,0.4);
msgFrame:SetBackdropBorderColor(0.1,0.1,0.1,1);
msgFrame:SetMovable(true);
msgFrame:EnableMouse(true);
msgFrame:SetMovable(true);
msgFrame:SetToplevel(true);
msgFrame:SetClampedToScreen(true);


msgFrame:SetPoint("CENTER")
msgFrame:SetFrameStrata("TOOLTIP")
msgFrame.text = msgFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
msgFrame.text:SetJustifyH("LEFT")
msgFrame.text:SetJustifyV("TOP")
msgFrame.text:SetPoint("TOPLEFT",10,-10)
msgFrame.close = CreateFrame("Button",nil,msgFrame,"UIPanelCloseButton");
msgFrame.close:SetPoint("TOPLEFT",0,3);
msgFrame.close:SetScript("OnClick",function(self,button,down) msgFrame:Hide()
minibtn:SetNormalTexture("Interface/COMMON/Indicator-Yellow.png")
minibtn:SetPushedTexture("Interface/COMMON/Indicator-Yellow.png")
minibtn:SetHighlightTexture("Interface/COMMON/Indicator-Yellow.png")
 end);
msgFrame:Hide()


local f = CreateFrame("Frame")



local function BuildDisplayList()
wipe(displayList);


	for k,v in spairs(IntToSound) do
table.insert(displayList,{id = k,str = v})
end


table.insert(displayList,{id = "",str = ""})
for k,v in pairs(StringToSound) do
table.insert(displayList,{id = k, str = v})
end

for i = 1,#displayList do
local patterns = {"%.ogg","%.mp3"}
 for p = 1,#patterns do
 displayList[i].str = displayList[i].str:gsub(patterns[p], "")
 end
displayList[i].str = displayList[i].str:gsub("_", " ")
displayList[i].str = displayList[i].str:gsub("-", " ")
end
end


for i = 1,#events do
f:RegisterEvent(events[i])
end
local currentHandle
f:SetScript("OnEvent", function(self, event, text)
local eventCheck = false
currentHandle = nil
for i = 1,#events do
if event == events[i] then
eventCheck = true
end
end
	if (eventCheck == true) then
		if StringToSound[tostring(text)] ~= nil then _,currentHandle = EmpirePlay(""..StringToSound[tostring(text)]) end
		if IntToSound[tonumber(text)] ~= nil then _,currentHandle = EmpirePlay(""..IntToSound[tonumber(text)]) end

		
	end
end)


local title = msgFrame:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
title:SetPoint("TOP",0,-10)
title:SetText("WoWofEmpires")


local scrollFrame = CreateFrame("ScrollFrame", nil, msgFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 3, -30)
scrollFrame:SetPoint("BOTTOMRIGHT", -27, 44)

local scrollChild = CreateFrame("Frame")
scrollFrame:SetScrollChild(scrollChild)
scrollChild:SetWidth(msgFrame:GetWidth()-18)
scrollChild:SetHeight(1) 

local footer = msgFrame:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
footer:SetPoint("BOTTOM",0,10)
footer:SetText("Right-click minimap button to stop sound.")

minibtn:SetScript("OnClick", function(self,button)
if button == "LeftButton" then
BuildDisplayList()

 local x, y = GetCursorPosition();
 msgFrame:SetPoint("TOPRIGHT",minibtn,-30,-30)
 
if listPopulated == false then

for i = 1,#displayList do

if displayList[i].id ~= "" then
playbtn = CreateFrame("Button",nil,scrollChild,"UIDropDownMenuButtonTemplate")
playbtn:SetPoint("LEFT")
playbtn:SetSize(10,10)
playbtn:SetPoint("TOPLEFT",0,0-(i*10))
playbtn:SetScript("OnClick", function(self,button)

if UnitInParty("player") then
SendChatMessage(displayList[i].id ,"PARTY");
else
SendChatMessage(displayList[i].id ,"SAY");
end
end)
end
local body = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormalSmall")
body:SetPoint("TOP", 0, 0)
body:SetJustifyH("LEFT")
body:SetJustifyV("TOP")
body:SetTextColor(1,1,1,1)
if displayList[i].id ~= "" then

body:SetText("["..displayList[i].id.."] - "..displayList[i].str)

end
body:SetPoint("TOPLEFT",18,0-(i*10))
body:SetPoint("TOPRIGHT",-12,-25-(i*10))
end
listPopulated = true
end

if msgFrame:IsVisible() then
minibtn:SetNormalTexture("Interface/COMMON/Indicator-Yellow.png")
minibtn:SetPushedTexture("Interface/COMMON/Indicator-Yellow.png")
minibtn:SetHighlightTexture("Interface/COMMON/Indicator-Yellow.png")

msgFrame:Hide()

 else 

minibtn:SetNormalTexture("Interface/COMMON/Indicator-Green.png")
minibtn:SetPushedTexture("Interface/COMMON/Indicator-Green.png")
minibtn:SetHighlightTexture("Interface/COMMON/Indicator-Green.png")

msgFrame:Show() end
end
if button == "RightButton" then

StopSound(currentHandle,500)

end
end)
local levelup = CreateFrame("Frame")
levelup:RegisterEvent("PLAYER_LEVEL_UP")
levelup:SetScript("OnEvent", function(self, event)
if UnitInParty("player") then
SendChatMessage("snoop","PARTY");
else
--auto sending chat messages to SAY requires HW input so using emote for now.
SendChatMessage("snoop", "EMOTE");
end
end)




--[[ DEJV AI KÅÅD ]]--
-- First, we define a function that will check if our own character's health
-- is below 30% and print "18" in party chat if it is.
local shouldRun = true
local function checkHealth()
  local healthPercentage = UnitHealth("player") / UnitHealthMax("player")
  
  if healthPercentage >= 0.3 then 
    shouldRun = true
  end
  if healthPercentage < 0.3 and shouldRun == true then
  if UnitInParty("player") == true then
SendChatMessage("18", "PARTY")
end
    
    -- prevent spam
    shouldRun = false
  end
end

-- Next, we create an event listener that will call our checkHealth function
-- whenever our own character's health changes.
local frame = CreateFrame("FRAME")
frame:RegisterEvent("UNIT_HEALTH")
frame:SetScript("OnEvent", function(self, event, unit)
if unit == "player" then
  checkHealth()
  end
end)