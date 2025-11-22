local highestPortraitIndex = 6
local defaultPortraitIndex = 0

local TPortraitBase = "Interface\\AddOns\\WoWofEmpires\\Portrait\\Portraits\\"
local TPortrait = "Interface\\AddOns\\WoWofEmpires\\Portrait\\Portraits\\1"

local function UpdateMicroButtonPortrait()
	if MicroButtonPortrait then
		SetPortraitTexture(MicroButtonPortrait, 'player')
	end
end

local function UpdatePaperDollPortrait()
	if PaperDollSidebarTab1 and PaperDollSidebarTab1.Icon then
		SetPortraitTexture(PaperDollSidebarTab1.Icon, 'player')
	end
end

local function UpdateDressUpPortrait()
	if DressUpFramePortrait then
		SetPortraitTexture(DressUpFramePortrait, 'player')
	end
end

local function UpdatePortraits()
	SetPortraitTexture(PlayerPortrait, PlayerFrame.unit)
	SetPortraitTexture(TargetFramePortrait, TargetFrame.unit)
	
	if PartyMemberFrame1 then
		SetPortraitTexture(PartyMemberFrame1Portrait, PartyMemberFrame1.unit)
	end
	if PartyMemberFrame2 then
		SetPortraitTexture(PartyMemberFrame2Portrait, PartyMemberFrame2.unit)
	end
	if PartyMemberFrame3 then
		SetPortraitTexture(PartyMemberFrame3Portrait, PartyMemberFrame3.unit)
	end
	if PartyMemberFrame4 then
		SetPortraitTexture(PartyMemberFrame4Portrait, PartyMemberFrame4.unit)
	end
	if TargetFrame.totFrame and TargetFrame.totFrame.unit then
		SetPortraitTexture(TargetFrameToTPortrait, TargetFrame.totFrame.unit)
	end
	
	UpdateMicroButtonPortrait()
	UpdatePaperDollPortrait()
	UpdateDressUpPortrait()
end

local function PlayerFrame_OnMouseWheel(self, direction)
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
	UpdatePortraits()
end

local function PartyMemberFrame_OnMouseWheel(partySlot)
	return function(self, direction)
		for i = 1, #PortraitKungarna do
			if UnitName(partySlot) == PortraitKungarna[i].name then
				if direction > 0 and PortraitKungarna[i].index < highestPortraitIndex then
					PortraitKungarna[i].index = PortraitKungarna[i].index + 1
				end
				if direction < 0 and PortraitKungarna[i].index > 0 then
					PortraitKungarna[i].index = PortraitKungarna[i].index - 1
				end
			end
		end
		UpdatePortraits()
	end
end

local function Hook_SetPortraitTexture(portrait, unit)
	if UnitIsUnit(unit, 'player') and portrait and (savedPortraitIndex > 0) then
		portrait:SetTexture(TPortrait)
	else
		local partyUnit
		for i = 1, #PortraitKungarna do
			local partyMembers = GetNumGroupMembers() - 1
			if partyMembers < 5 then
				for p = 1, partyMembers do
					if UnitName("party" .. p) == PortraitKungarna[i].name then
						partyUnit = "party" .. p
						if UnitIsUnit(unit, partyUnit) and portrait then
							local TPortrait2 = TPortraitBase .. PortraitKungarna[i].index
							portrait:SetTexture(TPortrait2)
						end
					end
				end
			end
			
			if partyMembers >= 5 then
				for p = 1, partyMembers do
					if UnitName("raid" .. p) == PortraitKungarna[i].name then
						partyUnit = "raid" .. p
						if UnitIsUnit(unit, partyUnit) and portrait then
							local TPortrait2 = TPortraitBase .. PortraitKungarna[i].index
							portrait:SetTexture(TPortrait2)
						end
					end
				end
			end
		end
	end
end

function CustomPlayerPortraitFrame_OnEvent(self, event, ...)
	if event == 'PLAYER_ENTERING_WORLD' then
		UpdatePortraits()
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
				{name = "Wubbidubbi", index = 6},
				{name = "Lafafa", index = 1},
			}
		end
		TPortrait = TPortraitBase .. savedPortraitIndex
		self:UnregisterEvent('ADDON_LOADED')
	end
end

local groupFrame = CreateFrame("Frame")
groupFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
groupFrame:SetScript("OnEvent", function()
	UpdatePortraits()
end)

function CustomPlayerPortraitFrame_OnLoad(self)
	hooksecurefunc('SetPortraitTexture', Hook_SetPortraitTexture)
	PlayerFrame:EnableMouseWheel(true)
	PlayerFrame:SetScript('OnMouseWheel', PlayerFrame_OnMouseWheel)
	PartyMemberFrame1:SetScript('OnMouseWheel', PartyMemberFrame_OnMouseWheel("party1"))
	PartyMemberFrame2:SetScript('OnMouseWheel', PartyMemberFrame_OnMouseWheel("party2"))
	PartyMemberFrame3:SetScript('OnMouseWheel', PartyMemberFrame_OnMouseWheel("party3"))
	PartyMemberFrame4:SetScript('OnMouseWheel', PartyMemberFrame_OnMouseWheel("party4"))
	
	self:RegisterEvent('ADDON_LOADED')
	self:RegisterEvent('PLAYER_ENTERING_WORLD')
end
