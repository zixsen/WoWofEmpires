-- Shift/Ctrl/Alt-click on unit frames targets again, like before Forever added click casting.
--
-- Blizzard's unit frame click handler (SecureUnitButton_OnClick) now drops a "target" or "menu"
-- click when no click-casting binding exists for that exact button and modifiers. Plain left-click
-- is bound to Target by default; modified left-clicks are bound to nothing, so they do nothing.
-- Same workaround as Clique: those clicks get a "macro" action instead (only target/menu clicks
-- are dropped), and the macro clicks a small secure button of ours on the frame, which targets the
-- frame's unit. A modified click you did bind in Click Casting still runs that binding: Blizzard
-- checks bindings before it looks at these attributes.
local addonName, ns = ...

ns.defaults.modifierTarget = true

local MODIFIERS = { "shift-", "ctrl-", "alt-", "ctrl-shift-", "alt-shift-", "alt-ctrl-", "alt-ctrl-shift-" }
local proxies = {} -- [unit frame] = its target button
local proxyCount = 0 -- the buttons need names for /click
local queued = {} -- frames to update after combat (secure attributes can't change in combat)

-- Blizzard unit frames (and addon frames built the same way) set "*type1" to "target".
local function IsUnitButton(frame)
	local ok, forbidden = pcall(frame.IsForbidden, frame)
	if not ok or forbidden or not frame.GetAttribute then return false end
	local okAttr, action = pcall(frame.GetAttribute, frame, "*type1")
	return okAttr and action == "target"
end

local function Apply(frame)
	if not ns.db then return end -- the login sweep picks it up
	if InCombatLockdown() then
		queued[frame] = true
		return
	end
	local proxy = proxies[frame]
	if not proxy then
		proxyCount = proxyCount + 1
		proxy = CreateFrame("Button", "WoWofEmpiresTarget" .. proxyCount, frame, "SecureActionButtonTemplate")
		proxy:SetAttribute("type", "target")
		proxy:SetAttribute("useparent-unit", true)
		proxy:SetAttribute("useparent-unitsuffix", true) -- pet frames: unit "raid1" + suffix "pet"
		proxy:SetAttribute("useOnKeyDown", false) -- /click sends no "down", so fire on release
		proxy:RegisterForClicks("AnyUp")
		proxies[frame] = proxy
	end
	local on = ns.db.modifierTarget
	local macro = on and ("/click " .. proxy:GetName() .. " LeftButton") or nil
	for _, modifier in ipairs(MODIFIERS) do
		frame:SetAttribute(modifier .. "type1", on and "macro" or nil)
		frame:SetAttribute(modifier .. "macrotext1", macro)
	end
end

-- Settings checkbox: re-applies to every frame (or after combat, if in it).
function ns.UpdateModifierTarget()
	for frame in pairs(proxies) do Apply(frame) end
end

-- Frames that exist at login, then every unit frame Blizzard creates later (raid frames, arena).
ns.On("PLAYER_LOGIN", function()
	local frame = EnumerateFrames()
	while frame do
		if IsUnitButton(frame) then Apply(frame) end
		frame = EnumerateFrames(frame)
	end
end)

hooksecurefunc("SecureUnitButton_OnLoad", function(frame)
	if IsUnitButton(frame) then Apply(frame) end
end)

ns.On("PLAYER_REGEN_ENABLED", function()
	for frame in pairs(queued) do
		queued[frame] = nil
		Apply(frame)
	end
end)
