local highestPortraitIndex = 5


local defaultPortraitIndex = 0




local TPortraitBase = "Interface\\AddOns\\CustomPlayerPortrait\\Portraits\\"
local TPortrait = "Interface\\AddOns\\CustomPlayerPortrait\\Portraits\\1"


local function UpdateMicroButtonPortrait ()
	if MicroButtonPortrait then
		SetPortraitTexture (MicroButtonPortrait, 'player')
	end
end


local function UpdatePaperDollPortrait ()
	if PaperDollSidebarTab1 and PaperDollSidebarTab1.Icon then
		SetPortraitTexture (PaperDollSidebarTab1.Icon, 'player')
	end
end


local function UpdateDressUpPortrait ()
	if DressUpFramePortrait then
		SetPortraitTexture (DressUpFramePortrait, 'player')
	end
end


local function UpdatePortraits ()
	SetPortraitTexture (PlayerPortrait, PlayerFrame.unit)
	SetPortraitTexture (TargetFramePortrait, TargetFrame.unit)
	if PartyMemberFrame1 then
	SetPortraitTexture (PartyMemberFrame1Portrait, PartyMemberFrame1.unit)
	end
	if PartyMemberFrame2 then
	SetPortraitTexture (PartyMemberFrame2Portrait, PartyMemberFrame2.unit)
	end
	if PartyMemberFrame3 then
	SetPortraitTexture (PartyMemberFrame3Portrait, PartyMemberFrame3.unit)
	end
	if PartyMemberFrame4 then
	SetPortraitTexture (PartyMemberFrame4Portrait, PartyMemberFrame4.unit)
	end
	if TargetFrame.totFrame and TargetFrame.totFrame.unit then
	 	SetPortraitTexture (TargetFrameToTPortrait, TargetFrame.totFrame.unit)
	end
 	
	UpdateMicroButtonPortrait ()
	UpdatePaperDollPortrait ()
	UpdateDressUpPortrait ()
end


local function PlayerFrame_OnMouseWheel (self, direction)
	if direction > 0 then
		if savedPortraitIndex == highestPortraitIndex then
			savedPortraitIndex = 0
		else
			savedPortraitIndex = savedPortraitIndex + 1
		end
	elseif direction < 0 then
		if savedPortraitIndex == 0 then
			savedPortraitIndex = highestPortraitIndex
		else
			savedPortraitIndex = savedPortraitIndex - 1
		end
	end
	if savedPortraitIndex > 0 then
		TPortrait = TPortraitBase .. savedPortraitIndex
	end
	UpdatePortraits ()
end

local function PartyMemberFrame1_OnMouseWheel (self, direction)
for i = 1,#PortraitKungarna do
if UnitName("party1") == PortraitKungarna[i].name then
if direction > 0 and PortraitKungarna[i].index < highestPortraitIndex then
PortraitKungarna[i].index = PortraitKungarna[i].index+1
local TPortrait = TPortraitBase .. PortraitKungarna[i].index
end
if direction < 0 and PortraitKungarna[i].index > 0 then
PortraitKungarna[i].index = PortraitKungarna[i].index-1
end
end
UpdatePortraits ()
end

end
local function PartyMemberFrame2_OnMouseWheel (self, direction)
for i = 1,#PortraitKungarna do
if UnitName("party2") == PortraitKungarna[i].name then
if direction > 0 and PortraitKungarna[i].index < highestPortraitIndex then
PortraitKungarna[i].index = PortraitKungarna[i].index+1
local TPortrait = TPortraitBase .. PortraitKungarna[i].index
end
if direction < 0 and PortraitKungarna[i].index > 0 then
PortraitKungarna[i].index = PortraitKungarna[i].index-1
end
end
UpdatePortraits ()
end
end
local function PartyMemberFrame3_OnMouseWheel (self, direction)
for i = 1,#PortraitKungarna do
if UnitName("party3") == PortraitKungarna[i].name then
if direction > 0 and PortraitKungarna[i].index < highestPortraitIndex then
PortraitKungarna[i].index = PortraitKungarna[i].index+1
local TPortrait = TPortraitBase .. PortraitKungarna[i].index
end
if direction < 0 and PortraitKungarna[i].index > 0 then
PortraitKungarna[i].index = PortraitKungarna[i].index-1
end
end
UpdatePortraits ()
end
end
local function PartyMemberFrame4_OnMouseWheel (self, direction)
for i = 1,#PortraitKungarna do
if UnitName("party4") == PortraitKungarna[i].name then
if direction > 0 and PortraitKungarna[i].index < highestPortraitIndex then
PortraitKungarna[i].index = PortraitKungarna[i].index+1
local TPortrait = TPortraitBase .. PortraitKungarna[i].index
end
if direction < 0 and PortraitKungarna[i].index > 0 then
PortraitKungarna[i].index = PortraitKungarna[i].index-1
end
end
UpdatePortraits ()
end
end


local function Hook_SetPortraitTexture (portrait, unit)

	if UnitIsUnit (unit, 'player') and portrait and (savedPortraitIndex > 0) then
		portrait:SetTexture (TPortrait)
else
local partyUnit
for i = 1,#PortraitKungarna do 

local partyMembers = GetNumGroupMembers()-1
if partyMembers < 5 then
for p = 1,partyMembers do
if UnitName("party"..p) == PortraitKungarna[i].name then
partyUnit = "party"..p
	if UnitIsUnit (unit, partyUnit) and portrait then
local TPortrait2 = TPortraitBase .. PortraitKungarna[i].index
		portrait:SetTexture(TPortrait2)

end
end
end
end

if partyMembers >= 5 then
for p = 1,partyMembers do
if UnitName("raid"..p) == PortraitKungarna[i].name then
partyUnit = "raid"..p
	if UnitIsUnit (unit, partyUnit) and portrait then
local TPortrait2 = TPortraitBase .. PortraitKungarna[i].index
		portrait:SetTexture (TPortrait2)
end

end
end



end
end


	end

end


function CustomPlayerPortraitFrame_OnEvent (self, event, ...)
	if event == 'PLAYER_ENTERING_WORLD' then
		UpdatePortraits ()
	elseif event == 'ADDON_LOADED' then
		local name = ...
		if not name == "CustomPlayerPortrait" then return end
		if not savedPortraitIndex then
			savedPortraitIndex = defaultPortraitIndex
		end
		if savedPortraitIndex < 0 then
			savedPortraitIndex = 0
		elseif savedPortraitIndex > highestPortraitIndex then
			savedPortraitIndex = highestPortraitIndex
		end
		if not PortraitKungarna then
 PortraitKungarna = {
{name = "Addons", index = 3},
{name = "Krasslig", index = 2},
{name = "Moffegreven", index = 1},
{name = "Enticed", index = 4},
{name = "Koettpangmos", index = 5},
}
		end
		TPortrait = TPortraitBase .. savedPortraitIndex
		self:UnregisterEvent 'ADDON_LOADED'
	end
end
local f = CreateFrame("Frame")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:SetScript("OnEvent",function()
UpdatePortraits()
end)
function CustomPlayerPortraitFrame_OnLoad (self)
	hooksecurefunc ('SetPortraitTexture', Hook_SetPortraitTexture)
	PlayerFrame:EnableMouseWheel (true)
	PlayerFrame:SetScript ('OnMouseWheel', PlayerFrame_OnMouseWheel)
PartyMemberFrame1:SetScript ('OnMouseWheel', PartyMemberFrame1_OnMouseWheel)
PartyMemberFrame2:SetScript ('OnMouseWheel', PartyMemberFrame2_OnMouseWheel)
PartyMemberFrame3:SetScript ('OnMouseWheel', PartyMemberFrame3_OnMouseWheel)
PartyMemberFrame4:SetScript ('OnMouseWheel', PartyMemberFrame4_OnMouseWheel)

	self:RegisterEvent 'ADDON_LOADED'
	self:RegisterEvent 'PLAYER_ENTERING_WORLD'
	
end
