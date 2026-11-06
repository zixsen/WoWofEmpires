-- Custom portraits, based on "Custom Player Portrait" by Felforit (MIT, see Portrait/Legal/License.txt).
-- Scroll the mouse wheel over your own portrait or a party member's portrait to cycle through
-- Portrait/Portraits/1-6.tga. 0 means the normal portrait.
local addonName, ns = ...

local PORTRAIT_PATH = "Interface\\AddOns\\WoWofEmpires\\Portrait\\Portraits\\"
local PORTRAIT_COUNT = 6

ns.defaults.portraitIndex = 0
ns.defaults.friendPortraits = {
	Addons = 3, Krasslig = 2, Moffegreven = 1, Enticed = 4, Koettpangmos = 5, Wubbidubbi = 6, Lafafa = 1,
}

-- Unit identity can be a secret value in restricted content; fall back to the normal portrait.
local function PortraitIndexFor(unit)
	local isPlayer = UnitIsUnit(unit, "player")
	if issecretvalue(isPlayer) then return 0 end
	if isPlayer then return ns.db.portraitIndex end
	local name = UnitName(unit)
	if not name or issecretvalue(name) then return 0 end
	return ns.db.friendPortraits[name] or 0
end

-- Blizzard draws every unit frame portrait with SetPortraitTexture; swap ours in right after.
hooksecurefunc("SetPortraitTexture", function(texture, unit)
	if not ns.db or not texture or not unit then return end
	local index = PortraitIndexFor(unit)
	if index > 0 then
		texture:SetTexture(PORTRAIT_PATH .. index)
	end
end)

local function PartyMemberFrame(i)
	return PartyFrame and PartyFrame["MemberFrame" .. i]
end

local function RefreshPortraits()
	local frames = { PlayerFrame, TargetFrame, TargetFrame.totFrame }
	for i = 1, 4 do
		frames[#frames + 1] = PartyMemberFrame(i)
	end
	for _, frame in pairs(frames) do
		if frame.portrait and frame.unit then
			SetPortraitTexture(frame.portrait, frame.unit)
		end
	end
end

local function NextIndex(index, direction)
	return (index + direction) % (PORTRAIT_COUNT + 1)
end

PlayerFrame:EnableMouseWheel(true)
PlayerFrame:HookScript("OnMouseWheel", function(_, direction)
	ns.db.portraitIndex = NextIndex(ns.db.portraitIndex, direction)
	RefreshPortraits()
end)

for i = 1, 4 do
	local frame = PartyMemberFrame(i)
	if frame then
		frame:EnableMouseWheel(true)
		frame:HookScript("OnMouseWheel", function(self, direction)
			local name = self.unit and UnitName(self.unit)
			if not name or issecretvalue(name) then return end
			ns.db.friendPortraits[name] = NextIndex(ns.db.friendPortraits[name] or 0, direction)
			RefreshPortraits()
		end)
	end
end

ns.On("PLAYER_ENTERING_WORLD", RefreshPortraits)
ns.On("GROUP_ROSTER_UPDATE", RefreshPortraits)
