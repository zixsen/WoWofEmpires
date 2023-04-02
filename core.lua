WoWofEmpires = {}
local frame = CreateFrame("Frame")
-- trigger event with /reloadui or /rl
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(this, event, ...)
    WoWofEmpires[event](WoWofEmpires, ...)
end)

function WoWofEmpires:PLAYER_LOGIN()

       if not WoWofEmpiresDB then
	   WoWofEmpiresDB = {
	   disabledList = {
	   
	   },
	   }
	   WoWofEmpiresDB.vendorGrey = false
	   WoWofEmpiresDB.repair = false
	   WoWofEmpiresDB.autoInv = false
	   WoWofEmpiresDB.Bagspace = false

	   
    end

end





local soundFolder = "Interface\\AddOns\\WoWofEmpires\\sound\\"
local textureFolder = "Interface\\AddOns\\WoWofEmpires\\texture\\"

function EmpirePlay(sound)
return PlaySoundFile(soundFolder..""..sound,"Dialog")
end
function EmpireSay(text)
return C_VoiceChat.SpeakText(0, text, Enum.VoiceTtsDestination.LocalPlayback, 0, 100)
end
function EmpireWhisper(message)
for i = 1,C_FriendList.GetNumWhoResults() do 
local name = C_FriendList.GetWhoInfo(i).fullName
SendChatMessage(message, "WHISPER", nil, name)
end
end


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
["yeboi"] = "heheyeahboy.ogg",
["anton"] = "anton.mp3",
["zzz"] = "zzz.ogg",
["gay"] = "hah-gay.mp3",
["huuu"] = "huuuuuuu.mp3",
["fake news"] = "fake-news-great.mp3",
["fast"] = "im-fast-as-fuck-boii-2.mp3",
["snoop"] = "snoop dogg.mp3",
["wow"] = "wow.ogg",
["hype"] = "Zulp Hype.ogg",
["bitconnect"] = "Bitconnect.ogg",
["hehehey"] = "heheheey.ogg",
["nonono"] = "mmhmmhnonono.ogg",
["wassawassa"] = "wasa-wasa-wasa-wassup.ogg",
["whaat"] = "whaaat.ogg",
["whatsup"] = "wowwowWhatsUp.ogg",
["run"] = "run.ogg",
["whyrun"] = "Why are you running.ogg",
["maths"] = "Quick maths.ogg",
["skrra"] = "Skrra.ogg",
["stats"] = "Check the statistacs.ogg",
}


local TEH_SQUAD = {
["Addons"] = true,
["Krasslig"] = true,
["Moffegreven"] = true,
}
local listPopulated = false
local displayList = {}



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

function tContain(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end
-- When the frame is shown, reset the update timer



local f = CreateFrame("Frame")
f:RegisterEvent("MERCHANT_SHOW")
f:SetScript("OnEvent", function()
if WoWofEmpiresDB.vendorGrey == true then
local totPrice = 0
local totItems = 0
local ilinkstr = ""
for b = 0,4 do 
for s = 0,GetContainerNumSlots(b) do
local ilink = GetContainerItemLink(b, s)
if ilink ~= nil then
local _,_,qual, _,_,_,_,_,_,_,price = GetItemInfo(ilink)
if qual == 0 then
UseContainerItem(b,s)
totPrice = totPrice+price
totItems = totItems+1
end
end
end
end
if totPrice > 0 then print("Sold "..totItems.."x item(s) for: "..GetCoinTextureString(totPrice)) end
end
if WoWofEmpiresDB.repair and CanMerchantRepair() then
local repairAllCost, canRepair = GetRepairAllCost()
if canRepair then
RepairAllItems()
print("Repaired all items for: "..GetCoinTextureString(repairAllCost))
end
end
end)


local f = CreateFrame("Frame")
local function IsFriend(name)
for i = 1,C_FriendList.GetNumFriends() do
local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
if friendInfo.name == name then return true
else
return false
end
end
end

function IsBnetFriend(name)
for i = 1,BNGetNumFriends() do
local friendInfo = select(5,BNGetFriendInfo(i))
print(friendInfo)
if friendInfo == name then return true
else
return false
end
end
end


f:RegisterEvent("PARTY_INVITE_REQUEST")
f:SetScript("OnEvent", function(self,event,name)
C_FriendList.ShowFriends()
if (IsFriend(name) or IsBnetFriend(name)) and WoWofEmpiresDB.autoInv then
for i = 1,STATICPOPUP_NUMDIALOGS do
local staticpopup = _G["StaticPopup"..i]
if staticpopup:IsVisible() and staticpopup.which == "PARTY_INVITE" then
StaticPopup_OnClick(staticpopup, 1)
end
end
end


end)

local f = CreateFrame("Frame")
f.shouldOOR = true
f.counter = 0
f:RegisterEvent("UI_ERROR_MESSAGE")
f:SetScript("OnEvent", function(self,event,id,str)
if id == 363 and tonumber((GetCVar("Sound_EnableErrorSpeech"))) > 0 then
SetCVar("Sound_EnableErrorSpeech","0")
if str == "Out of range." and f.shouldOOR then
if f.counter > 1 then f.counter = 0 end
f.counter = f.counter + 1
EmpirePlay("Too_far_away"..f.counter..".ogg")
f.shouldOOR = false
C_Timer.After(1, function()
f.shouldOOR = true 
SetCVar("Sound_EnableErrorSpeech","1")
end)
end

end
end)



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
local targetName = UnitName("target") or "noTarget"
if subevent == "SPELL_AURA_APPLIED" and spellName == "Mind Control" and destName == playerName then
EmpirePlay("Ingemar-Franko.mp3")
end

if subevent == "SPELL_AURA_APPLIED" and (spellName == "Web" and destName == targetName) then
EmpirePlay("spindelnat.ogg")
--print(targetName)
end

if subevent == "SPELL_AURA_BROKEN_SPELL" then
local timestamp,subevent,hideCaster,sourceGUID,sourceName,SourceFlags,SourceRaidFlags,destGUID,destName,destFlags,destRaidFlags,spellID,spellName,_,spellType,extraSpellId,extraSpellName,extraSchool,auraType = CombatLogGetCurrentEventInfo()
print(spellName.." broken by: "..sourceName.." on: "..destName)
end


if subevent == "SPELL_CAST_SUCCESS" then
if spellName == "Death Coil" and destName == playerName then
EmpirePlay("vemvare.ogg")
end
if spellName == "Blink" and TEH_SQUAD[sourceName] then
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
local itemSoundHandle = 1
local LootFrame = CreateFrame("Frame")
LootFrame:RegisterEvent("START_LOOT_ROLL")
LootFrame:SetScript("OnEvent", function(_, _, id)
if not id then return end
local texture, name, count, quality = GetLootRollItemInfo(id)
local rollLink = GetLootRollItemLink(id)
local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType,
itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice =
    GetItemInfo(rollLink)
	if itemEquipLoc == "INVTYPE_FINGER" then
	StopSound(itemSoundHandle)
	_,itemSoundHandle = EmpirePlay("welkenring.ogg")
	elseif quality > 2 then
	EmpirePlay("Sopahit.ogg")
	end
end)





local minibtn = CreateFrame("Button", nil, Minimap)
minibtn:SetFrameLevel(8)
minibtn:SetSize(32,32)
minibtn:SetMovable(true)
  
minibtn:SetNormalTexture("Interface/COMMON/Indicator-Yellow.png")
minibtn:SetPushedTexture("Interface/COMMON/Indicator-Yellow.png")
minibtn:SetHighlightTexture("Interface/COMMON/Indicator-Yellow.png")
--[[
local imgFrame = CreateFrame("FRAME", nil, UIParent,BackdropTemplateMixin and "BackdropTemplate") 
local backdropInfo =
{
bgFile = textureFolder.."NewProject2.tga",
--edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
tile = true,
tileEdge = false,
tileSize = 500,
edgeSize = 8,
insets = { left = 1, right = 1, top = 1, bottom = 1 },
}
--local imgFrame = CreateFrame("Frame")
imgFrame:SetWidth(525)
imgFrame:SetHeight(525)

imgFrame:SetPoint("CENTER",UIParent,"Center")

--imgFrame.texture = imgFrame:CreateTexture("IMG_TEXTURE","BACKGROUND")
--imgFrame.texture:SetPoint("TOPLEFT")
--imgFrame.texture:SetTexture(textureFolder.."test.tga")
-- imgFrame:Show()

local frame = CreateFrame("Frame")

-- The minimum number of seconds between each update
local ONUPDATE_INTERVAL = 0.04

-- The number of seconds since the last update
local TimeSinceLastUpdate = 0
frame:SetScript("OnUpdate", function(self, elapsed)
	TimeSinceLastUpdate = TimeSinceLastUpdate + elapsed
	if TimeSinceLastUpdate >= ONUPDATE_INTERVAL then
		TimeSinceLastUpdate = 0
		local cameraZoom = GetCameraZoom()
		local bginfo = backdropInfo
		local factor = 25
		bginfo.tileSize = 500-(cameraZoom*factor)
print(bginfo.tileSize)
imgFrame:SetBackdrop(bginfo)
imgFrame:SetWidth(510-(cameraZoom*factor))
imgFrame:SetHeight(510-(cameraZoom*factor))

imgFrame:ApplyBackdrop()
local a = math.random(-5,5)
local b = math.random(-5,5)
imgFrame:SetPoint("CENTER",UIParent,"Center",a,b)
imgFrame:Show()
imgFrame:Hide()
		-- Do stuff
	end
end)

-- When the frame is shown, reset the update timer
frame:SetScript("OnShow", function(self)
	TimeSinceLastUpdate = 0
end)
]]--


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
msgFrame:SetBackdropColor(255/255,240/255,179/255,0.7);
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
msgFrame.close:SetPoint("TOPRIGHT",5,25);
msgFrame.close:SetScript("OnClick",function(self,button,down) msgFrame:Hide()
minibtn:SetNormalTexture("Interface/COMMON/Indicator-Yellow.png")
minibtn:SetPushedTexture("Interface/COMMON/Indicator-Yellow.png")
minibtn:SetHighlightTexture("Interface/COMMON/Indicator-Yellow.png")
 end);
 msgFrame.close:EnableKeyboard(true);
msgFrame.close:SetScript("OnKeyDown",function(self,button,down) 
if button == "ESCAPE" then
msgFrame.close:SetPropagateKeyboardInput(false)
msgFrame:Hide()
minibtn:SetNormalTexture("Interface/COMMON/Indicator-Yellow.png")
minibtn:SetPushedTexture("Interface/COMMON/Indicator-Yellow.png")
minibtn:SetHighlightTexture("Interface/COMMON/Indicator-Yellow.png")
else
 msgFrame.close:SetPropagateKeyboardInput(true)
end
 end);
 
 
msgFrame:Hide()

local frame = CreateFrame("Frame")
local ONUPDATE_INTERVAL = 0.05
local TimeSinceLastUpdate = 0
frame:SetScript("OnUpdate", function(self, elapsed)
TimeSinceLastUpdate = TimeSinceLastUpdate + elapsed
if TimeSinceLastUpdate >= ONUPDATE_INTERVAL then
if msgFrame:IsVisible() then

if msgFrame:GetWidth() < 350 then
msgFrame:SetWidth(TimeSinceLastUpdate*1000)
else
msgFrame:SetWidth(350)
end
if msgFrame:GetHeight() < 400 then
msgFrame:SetHeight(TimeSinceLastUpdate*1000)
else
msgFrame:SetHeight(400)
end
end
end
end)


msgFrame:SetScript("OnShow", function(self)
TimeSinceLastUpdate = 0
msgFrame:SetWidth(1)
msgFrame:SetHeight(1)
end)
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
local lastFiveSounds = {}

for i = 1,#events do
f:RegisterEvent(events[i])
end
local currentHandle
f:SetScript("OnEvent", function(self, event, text,sender)
local fplayerName = GetUnitName("player")
local fplayerName = playerName.."-"..GetRealmName()
local eventCheck = false
currentHandle = nil
for i = 1,#events do
if event == events[i] then
eventCheck = true
end
end
if eventCheck == true then
local ttsSTR = string.sub(text,1,4)
if ttsSTR == "tts:" then
local newText = text:sub(string.len(ttsSTR))
EmpireSay(newText)
end


local spamSTR = string.sub(text,1,5)
if spamSTR == "spam:" and sender == fplayerName then
local newText = text:sub(string.len(spamSTR))
EmpireWhisper(newText)
end

end
	if (eventCheck == true and not (WoWofEmpiresDB.disabledList[text] or WoWofEmpiresDB.disabledList[tonumber(text)])) then
		if StringToSound[tostring(string.lower(text))] ~= nil then _,currentHandle = EmpirePlay(""..StringToSound[tostring(string.lower(text))]) end
		if IntToSound[tonumber(text)] ~= nil then _,currentHandle = EmpirePlay(""..IntToSound[tonumber(text)]) end
if #lastFiveSounds > 4 then
table.remove(lastFiveSounds,1)
end
table.insert(lastFiveSounds,currentHandle)
	end
end)


local title = msgFrame:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
title:SetPoint("TOP",0,-10)
title:SetText("WoWofEmpires")


local scrollFrame = CreateFrame("ScrollFrame", nil, msgFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 3, -30)
scrollFrame:SetPoint("BOTTOMRIGHT", -27, 44)
local scrollFrame2 = CreateFrame("ScrollFrame", nil, msgFrame, "UIPanelScrollFrameTemplate")
scrollFrame2:SetPoint("TOPLEFT", 3, -30)
scrollFrame2:SetPoint("BOTTOMRIGHT", -27, 44)
scrollFrame2:Hide()
local scrollChild = CreateFrame("Frame")
scrollFrame:SetScrollChild(scrollChild)
scrollChild:SetWidth(msgFrame:GetWidth()-18)
scrollChild:SetHeight(1) 

local scrollChild2 = CreateFrame("Frame")
scrollFrame2:SetScrollChild(scrollChild2)
scrollChild2:SetWidth(msgFrame:GetWidth()-18)
scrollChild2:SetHeight(1) 

-- for i = 1,45 do 
-- local body2 = scrollChild2:CreateFontString("ARTWORK", nil, "GameFontNormalSmall")
-- body2:SetPoint("TOPLEFT", 5, 1-i*10)
-- body2:SetJustifyH("LEFT")
-- body2:SetJustifyV("TOP")
-- body2:SetTextColor(1,1,1,1)
-- body2:SetText("aa"..i)
-- end
local cbVendorGrey = CreateFrame("CheckButton", "vendorgrey_CBname", scrollChild2, "ChatConfigCheckButtonTemplate");
cbVendorGrey:SetSize(20,20)
cbVendorGrey:SetPoint("TOPLEFT")
vendorgrey_CBnameText:SetText("Auto vendor greys");

cbVendorGrey:SetScript("OnClick", 
  function()
  WoWofEmpiresDB.vendorGrey = cbVendorGrey:GetChecked() 
  end)
  
  local cbRepair = CreateFrame("CheckButton", "repair_CBname", scrollChild2, "ChatConfigCheckButtonTemplate");
  cbRepair:SetSize(20,20)
cbRepair:SetPoint("TOPLEFT",0,-16*1)
repair_CBnameText:SetText("Auto repair");

cbRepair:SetScript("OnClick", 
  function()
  WoWofEmpiresDB.repair = cbRepair:GetChecked() 
  end)
  
    local cbAutoInv = CreateFrame("CheckButton", "autoinv_CBname", scrollChild2, "ChatConfigCheckButtonTemplate");
  cbAutoInv:SetSize(20,20)
cbAutoInv:SetPoint("TOPLEFT",0,-16*2)
autoinv_CBnameText:SetText("Auto-Accept group (from friends)");

cbAutoInv:SetScript("OnClick", 
  function()
  WoWofEmpiresDB.autoInv = cbAutoInv:GetChecked() 
  end)
  
  
  local bagspaceframe = CreateFrame("Frame")
  bagspaceframe:SetFrameStrata("TOOLTIP")
 local bagspacetext = bagspaceframe:CreateFontString("OVERLAY",nil,"GameFontNormal")
 bagspacetext:SetShadowColor(0, 0, 0,1)
bagspacetext:SetShadowOffset(2, -2)
bagspacetext:SetScale(1.2)
 bagspacetext:SetPoint("CENTER",MainMenuBarBackpackButton,0,-3)
--bagspacetext:SetTextColor(1,1,1,1)
local f = CreateFrame("Frame")
f:RegisterEvent("BAG_UPDATE")
f:SetScript("OnEvent",function()
local bgspace = 0
for i = 0,4 do
local numberOfFreeSlots,bagType = GetContainerNumFreeSlots(i)
local bagName = GetBagName(i)
if bagName ~= nil and not (bagName:find("Soul") or bagName:find("Felcloth")) then
bgspace = bgspace + numberOfFreeSlots
end
end
if bgspace <= 3 then
bagspacetext:SetTextColor(1,0,0,1)
else
bagspacetext:SetTextColor(1,1,1,1)
end
bagspacetext:SetText("["..bgspace.."]")
  if WoWofEmpiresDB ~= nil and WoWofEmpiresDB.Bagspace then
  bagspacetext:Show()
  else
  bagspacetext:Hide()
  end
  
end)

local cbBagspace = CreateFrame("CheckButton", "Bagspace_CBname", scrollChild2, "ChatConfigCheckButtonTemplate");
cbBagspace:SetSize(20,20)
cbBagspace:SetPoint("TOPLEFT",0,-16*3)
Bagspace_CBnameText:SetText("Show bagspace on first bag.");

cbBagspace:SetScript("OnClick", 
  function()
  WoWofEmpiresDB.Bagspace = cbBagspace:GetChecked()
  if WoWofEmpiresDB.Bagspace then
  bagspacetext:Show()
  else
  bagspacetext:Hide()
  end
  end)

  
local footer = msgFrame:CreateFontString("ARTWORK", nil, "GameFontNormal")
footer:SetPoint("BOTTOMLEFT",5,22)
footer:SetText("Volume:")
local footer2 = msgFrame:CreateFontString("ARTWORK", nil, "GameFontNormal")
footer2:SetPoint("BOTTOMRIGHT",-7,7)
footer2:SetText("Right-click minimap\nbutton to stop\nlast sounds.")
local header1 = CreateFrame("BUTTON",nil,msgFrame,"TabButtonTemplate")
header1:SetPoint("TOPLEFT",0,33)
--PanelTemplates_TabResize(2, header1, 25, 25)

header1:SetText("Main")
PanelTemplates_TabResize(header1, 0,75)
header1:SetScript("OnClick", function(self,button)
scrollFrame:Show()
scrollFrame2:Hide()
end)

local header2 = CreateFrame("BUTTON",nil,msgFrame,"TabButtonTemplate")
header2:SetPoint("TOPLEFT",75,33)
--PanelTemplates_TabResize(2, header2, 25, 25)

header2:SetText("QoL")
PanelTemplates_TabResize(header2, 0,75)
header2:SetScript("OnClick", function(self,button)
scrollFrame:Hide()
cbVendorGrey:SetChecked(WoWofEmpiresDB.vendorGrey) 
cbRepair:SetChecked(WoWofEmpiresDB.repair) 
cbAutoInv:SetChecked(WoWofEmpiresDB.autoInv) 
cbBagspace:SetChecked(WoWofEmpiresDB.Bagspace) 
scrollFrame2:Show()
end)

local slider1 = CreateFrame("Slider", nil, msgFrame, "OptionsSliderTemplate")
local footerwidth = footer:GetStringWidth()
slider1:SetPoint("BOTTOMLEFT", footerwidth+15,18)
slider1:SetMinMaxValues(0,1)
local VolumeValue = tonumber(GetCVar("Sound_DialogVolume"))
slider1:SetValue(VolumeValue)
slider1:SetValueStep(0.01)
slider1:SetObeyStepOnDrag(true)
slider1:SetScript("OnValueChanged", function(self,value,userInput)
tonumber(SetCVar("Sound_DialogVolume",value))
end)
minibtn:SetScript("OnClick", function(self,button)
if button == "LeftButton" then
BuildDisplayList()

 local x, y = GetCursorPosition();
 msgFrame:SetPoint("TOPRIGHT",minibtn,-30,-30)
 
if listPopulated == false then

for i = 1,#displayList do

if displayList[i].id ~= "" then

--if WoWofEmpiresDB.disabledList[displayList[i].id] == true then
local playbtn = CreateFrame("Button",nil,scrollChild)
if WoWofEmpiresDB.disabledList[displayList[i].id] ~= true then
playbtn:SetNormalTexture("Interface/COMMON/Indicator-Yellow.png")
playbtn:SetPushedTexture("Interface/COMMON/Indicator-Yellow.png")
playbtn:SetHighlightTexture("Interface/COMMON/Indicator-Yellow.png")
else
playbtn:SetNormalTexture("Interface/COMMON/Indicator-Red.png")
playbtn:SetPushedTexture("Interface/COMMON/Indicator-Red.png")
playbtn:SetHighlightTexture("Interface/COMMON/Indicator-Red.png")
end
playbtn:RegisterForClicks("AnyUp")
playbtn:SetPoint("LEFT")
playbtn:SetSize(14,14)
playbtn:SetPoint("TOPLEFT",0,0-(i*10))
playbtn:SetScript("OnClick", function(self,button)
if button == "RightButton" then
if WoWofEmpiresDB.disabledList[displayList[i].id] ~= true then
WoWofEmpiresDB.disabledList[displayList[i].id] = true
playbtn:SetNormalTexture("Interface/COMMON/Indicator-Red.png")
playbtn:SetPushedTexture("Interface/COMMON/Indicator-Red.png")
playbtn:SetHighlightTexture("Interface/COMMON/Indicator-Red.png")

else
WoWofEmpiresDB.disabledList[displayList[i].id] = nil
playbtn:SetNormalTexture("Interface/COMMON/Indicator-Yellow.png")
playbtn:SetPushedTexture("Interface/COMMON/Indicator-Yellow.png")
playbtn:SetHighlightTexture("Interface/COMMON/Indicator-Yellow.png")

end

else
if WoWofEmpiresDB.disabledList[displayList[i].id] ~= true then
if UnitInParty("player")  then
SendChatMessage(displayList[i].id ,"PARTY");
else
SendChatMessage(displayList[i].id ,"SAY");
end
end

end
end)
--else
--local playbtn = CreateFrame("Button",nil,scrollChild)
--playbtn:SetNormalTexture("Interface/COMMON/Indicator-Yellow.png")
--playbtn:SetPushedTexture("Interface/COMMON/Indicator-Yellow.png")
--playbtn:SetHighlightTexture("Interface/COMMON/Indicator-Yellow.png")
--playbtn:RegisterForClicks("AnyUp")
--playbtn:SetPoint("LEFT")
--playbtn:SetSize(14,14)
--playbtn:SetPoint("TOPLEFT",0,0-(i*10))
--playbtn:SetScript("OnClick", function(self,button)


--end)
--end
--playbtn = CreateFrame("Button",nil,scrollChild,"UIDropDownMenuButtonTemplate")

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
if button == "RightButton" and currentHandle ~= nil then
for i = 1,#lastFiveSounds do
StopSound(lastFiveSounds[i],500)
end
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



local editFrame = CreateFrame("EditBox", nil, ContainerFrame1, "BagSearchBoxTemplate");
editFrame:SetPoint("TOP", ContainerFrame1, "TOP");
editFrame:SetWidth(126);
editFrame:SetHeight(18);
editFrame:SetMaxLetters(15);
hooksecurefunc("ContainerFrame_Update", function( self )
	if self:GetID() == 0 then
		editFrame:SetParent(self)
		editFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 55, -29)
		editFrame.anchorBag = self
		editFrame:Show()
	elseif editFrame.anchorBag == self then
		editFrame:ClearAllPoints()
		editFrame:Hide()
		editFrame.anchorBag = nil
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
frame:RegisterEvent("UNIT_HEALTH_FREQUENT")
frame:SetScript("OnEvent", function(self, event, unit)
if unit == "player" then
  checkHealth()
  end
end)