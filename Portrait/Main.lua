local highestPortraitIndex = 6


local defaultPortraitIndex = 0




local TPortraitBase = "Interface\\AddOns\\WoWofEmpires\\Portrait\\Portraits\\"
local TPortrait = TPortraitBase .. "1"


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


-- Forever uses the retail unit frames: party frames live at PartyFrame.MemberFrame1-4
-- and every unit frame keeps its portrait texture in .portrait.
local function PartyMemberFrame (i)
	return PartyFrame and PartyFrame["MemberFrame" .. i]
end


local function UpdatePortraits ()
	local frames = { PlayerFrame, TargetFrame, TargetFrame.totFrame }
	for i = 1, 4 do
		frames[#frames + 1] = PartyMemberFrame (i)
	end
	for _, frame in pairs (frames) do
		if frame.portrait and frame.unit then
			SetPortraitTexture (frame.portrait, frame.unit)
		end
	end
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


local function PartyMemberFrame_OnMouseWheel (self, direction)
	local name = self.unit and UnitName (self.unit)
	if not name or issecretvalue (name) then return end
	for i = 1, #PortraitKungarna do
		local p = PortraitKungarna[i]
		if p.name == name then
			p.index = math.max (0, math.min (highestPortraitIndex, p.index + direction))
		end
	end
	UpdatePortraits ()
end


-- Unit identity can be a secret value in restricted content; skip instead of erroring.
local function Hook_SetPortraitTexture (portrait, unit)
	if not portrait or not unit or not savedPortraitIndex or not PortraitKungarna then return end
	local isPlayer = UnitIsUnit (unit, 'player')
	if issecretvalue (isPlayer) then return end
	if isPlayer then
		if savedPortraitIndex > 0 then
			portrait:SetTexture (TPortrait)
		end
		return
	end
	local name = UnitName (unit)
	if issecretvalue (name) then return end
	for i = 1, #PortraitKungarna do
		local p = PortraitKungarna[i]
		if p.name == name and p.index > 0 then
			portrait:SetTexture (TPortraitBase .. p.index)
			return
		end
	end
end


function CustomPlayerPortraitFrame_OnEvent (self, event, ...)
	if event == 'PLAYER_ENTERING_WORLD' then
		UpdatePortraits ()
	elseif event == 'ADDON_LOADED' then
		local name = ...
		if name ~= "WoWofEmpires" then return end
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
{name = "Wubbidubbi", index = 6},
{name = "Lafafa", index = 1},
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
	PlayerFrame:HookScript ('OnMouseWheel', PlayerFrame_OnMouseWheel)
	for i = 1, 4 do
		local frame = PartyMemberFrame (i)
		if frame then
			frame:EnableMouseWheel (true)
			frame:HookScript ('OnMouseWheel', PartyMemberFrame_OnMouseWheel)
		end
	end

	self:RegisterEvent 'ADDON_LOADED'
	self:RegisterEvent 'PLAYER_ENTERING_WORLD'

end
