-- DoT kill marker: shows on the target frame and on enemy nameplates whether the DoTs on a mob
-- (yours, plus those of groupmates running this addon) will finish it off.
--
-- Forever hides target health and auras from addons, so this never decides "will it die" itself.
-- Instead the end of the green health is painted purple for the damage the DoTs still have to deal:
-- a status bar as wide as the health bar, its right edge pinned to the end of the green, filling
-- leftwards with max = the target's (hidden) max health and value = remaining DoT damage. Status bars
-- can draw hidden values (idea from DoesItDie by swirllyman, MIT). No green left = the target dies.
--
-- Remaining damage is estimated from each DoT's tooltip ("40 Fire damage over 15 sec") and the time
-- since it was cast.
-- ponytail: tooltips leave out spell power, so estimates run low (it shows a kill late, never early).
-- Learning real tick sizes (as DoesItDie does) is the upgrade if that matters.
local addonName, ns = ...

ns.defaults.dotMarker = false -- off until turned on in Settings; DoTs are shared with the group either way

local TICK = 3 -- most DoTs tick every 3 sec; the rest are close enough
local SCHOOL_MASK = { Holy = 2, Fire = 4, Nature = 8, Frost = 16, Shadow = 32, Arcane = 64 }
local AVOIDED = { MISS = true, RESIST = true, IMMUNE = true, DODGE = true, PARRY = true, EVADE = true }

-- dots[mob][owner] = { total, duration, ends }. mob is a GUID, or "target" where Forever hides GUIDs
-- (instances): then only your own DoTs on your current target are tracked. owner is "me:<spellID>"
-- or "<groupmate>:<spellID>".
local dots = {}

-- The key DoTs are kept under for a hostile unit (default: your target). Without GUIDs only the
-- target has one, so a nameplate only finds DoTs there if it's your target's.
local function MobKey(unit)
	unit = unit or "target"
	if not UnitExists(unit) then return nil end
	local hostile = UnitCanAttack("player", unit)
	if issecretvalue(hostile) or not hostile then return nil end
	local guid = UnitGUID(unit)
	if guid and not issecretvalue(guid) then return guid end
	if unit == "target" then return "target" end
	local isTarget = UnitIsUnit(unit, "target")
	if not issecretvalue(isTarget) and isTarget then return "target" end
end

local function AddDot(mob, owner, total, duration)
	local now = GetTime()
	for key, list in pairs(dots) do -- drop expired DoTs on every mob while we're here
		for who, dot in pairs(list) do
			if dot.ends <= now then list[who] = nil end
		end
		if next(list) == nil then dots[key] = nil end
	end
	dots[mob] = dots[mob] or {}
	dots[mob][owner] = { total = total, duration = duration, ends = now + duration }
end

local function RemoveDot(mob, owner)
	if dots[mob] then dots[mob][owner] = nil end
end

-- Damage still to come: whole ticks left times the damage per tick.
local function Remaining(dot, now)
	local left = dot.ends - now
	if left <= 0 then return 0 end
	local ticks = math.max(1, math.floor(dot.duration / TICK + 0.5))
	return dot.total * math.min(ticks, math.ceil(left / TICK)) / ticks
end

local function RemainingOn(unit)
	local mob = MobKey(unit)
	if not mob or not dots[mob] then return 0 end
	local now, damage = GetTime(), 0
	for _, dot in pairs(dots[mob]) do
		damage = damage + Remaining(dot, now)
	end
	return damage
end

-- "40 Fire damage over 15 sec" -> 40, Fire's school mask, 15. Area spells aren't single-target DoTs.
local function ParseDot(spellID)
	local text = C_Spell.GetSpellDescription(spellID)
	if not text or issecretvalue(text) or text:find("area") or text:find("all enemies") or text:find("nearby") then return end
	local amount, school, duration = text:match("(%d+) (%a*) ?damage over (%d+) sec")
	if amount then return tonumber(amount), SCHOOL_MASK[school] or 1, tonumber(duration) end
end

------------------------------------------------------------------------
-- Your casts
------------------------------------------------------------------------
-- The DoT belongs to the mob targeted when the cast started: by the time an instant lands you may
-- have tabbed to the next one.
local sentTarget = {}
local lastCast -- for taking back a resisted or missed DoT

ns.On("UNIT_SPELLCAST_SENT", function(_, _, _, castGUID)
	if not issecretvalue(castGUID) then sentTarget[castGUID] = MobKey() end
end, "player")

ns.On("UNIT_SPELLCAST_SUCCEEDED", function(_, _, castGUID, spellID)
	if issecretvalue(castGUID) or issecretvalue(spellID) then return end
	local mob = sentTarget[castGUID]
	sentTarget[castGUID] = nil
	if not mob then return end
	-- Tracked and shared even with your own marker off, for groupmates who have theirs on.
	local channeled = select(8, UnitChannelInfo("player"))
	if channeled and not issecretvalue(channeled) and channeled == spellID then return end -- Mind Flay isn't a DoT
	local total, school, duration = ParseDot(spellID)
	if not total then return end
	AddDot(mob, "me:" .. spellID, total, duration)
	lastCast = { mob = mob, spellID = spellID, school = school, time = GetTime() }
	if mob ~= "target" then
		ns.SendToGroup(("dot:%s:%d:%d:%d"):format(mob, spellID, total, duration))
	end
end, "player")

-- A miss/resist/immune in the DoT's school right after casting it means it never landed.
-- ponytail: for physical DoTs (Rend, Rake) a white swing missing at that moment looks the same.
ns.On("UNIT_COMBAT", function(_, _, action, _, _, schoolMask)
	if not lastCast or issecretvalue(action) or issecretvalue(schoolMask) or not AVOIDED[action] then return end
	if GetTime() - lastCast.time > 1 or schoolMask ~= lastCast.school or MobKey() ~= lastCast.mob then return end
	RemoveDot(lastCast.mob, "me:" .. lastCast.spellID)
	if lastCast.mob ~= "target" then
		ns.SendToGroup(("undot:%s:%d"):format(lastCast.mob, lastCast.spellID))
	end
	lastCast = nil
end, "target")

-- Without GUIDs, "target" means whatever you're targeting now.
ns.On("PLAYER_TARGET_CHANGED", function() dots.target = nil end)

------------------------------------------------------------------------
-- Groupmates' casts (addon messages; Forever blocks these during boss fights)
------------------------------------------------------------------------
ns.On("CHAT_MSG_ADDON", function(_, prefix, text, _, sender)
	if issecretvalue(prefix) or issecretvalue(text) or issecretvalue(sender) then return end
	if prefix ~= ns.PREFIX or ns.IsMe(sender) then return end
	local who = Ambiguate(sender, "short")
	local mob, spellID, total, duration = text:match("^dot:([^:]+):(%d+):(%d+):(%d+)$")
	if mob then
		AddDot(mob, who .. ":" .. spellID, tonumber(total), tonumber(duration))
		return
	end
	mob, spellID = text:match("^undot:([^:]+):(%d+)$")
	if mob then RemoveDot(mob, who .. ":" .. spellID) end
end)

------------------------------------------------------------------------
-- Display: the target frame and enemy nameplates
------------------------------------------------------------------------
local WHITE = "Interface\\Buttons\\WHITE8X8"
local STRATA_RANK = { BACKGROUND = 1, LOW = 2, MEDIUM = 3, HIGH = 4, DIALOG = 5, FULLSCREEN = 6, FULLSCREEN_DIALOG = 7, TOOLTIP = 8 }

-- Errors here would otherwise be invisible (Lua errors are off by default), so say it once in chat.
local reported
local function Report(err)
	if reported then return end
	reported = true
	ns.Print("DoT overlay error, please report: " .. tostring(err))
end

-- One overlay over a health bar: a clip frame (keeps the purple inside the bar when the DoTs
-- out-damage what's left) holding an invisible copy of the bar (mirror, whose fill ends where the
-- green ends; Forever won't let addon frames hang off Blizzard's own fill) and the purple (marker).
local function CreateOverlay(parent)
	local o = {}
	o.clip = CreateFrame("Frame", nil, parent)
	o.clip:SetClipsChildren(true)
	o.clip:Hide()

	o.mirror = CreateFrame("StatusBar", nil, o.clip)
	o.mirror:SetAllPoints()
	o.mirror:SetStatusBarTexture(WHITE)
	o.mirror:SetStatusBarColor(0, 0, 0, 0)

	local greenEnd = o.mirror:GetStatusBarTexture()
	o.marker = CreateFrame("StatusBar", nil, o.clip)
	o.marker:SetPoint("TOPRIGHT", greenEnd, "TOPRIGHT")
	o.marker:SetPoint("BOTTOMRIGHT", greenEnd, "BOTTOMRIGHT")
	o.marker:SetReverseFill(true)
	o.marker:SetStatusBarTexture(WHITE)
	o.marker:SetStatusBarColor(0.62, 0.2, 1, 0.8)

	-- A thin line where the health will end once the DoTs are done.
	local edge = o.marker:CreateTexture(nil, "OVERLAY")
	edge:SetColorTexture(1, 1, 1, 0.9)
	edge:SetWidth(1)
	edge:SetPoint("TOPLEFT", o.marker:GetStatusBarTexture(), "TOPLEFT")
	edge:SetPoint("BOTTOMLEFT", o.marker:GetStatusBarTexture(), "BOTTOMLEFT")
	return o
end

local function Attach(o, bar)
	o.bar = bar
	o.clip:ClearAllPoints()
	o.clip:SetAllPoints(bar)
end

-- strata nil keeps the parent's.
local function SetLayer(o, strata, level)
	for i, frame in ipairs({ o.clip, o.mirror, o.marker }) do
		if strata then frame:SetFrameStrata(strata) end
		frame:SetFrameLevel(level + i)
	end
end

-- Paints the damage still to come on the unit's bar, or hides the overlay. min/max/value can be
-- hidden values: status bars draw them without the addon ever reading them.
local function Paint(o, health, max, damage)
	o.marker:SetWidth(o.clip:GetWidth()) -- the whole bar's width is the mob's max health
	o.mirror:SetMinMaxValues(0, max)
	o.mirror:SetValue(health)
	o.marker:SetMinMaxValues(0, max)
	o.marker:SetValue(damage)
	o.clip:Show()
end

local function Update(o, unit)
	local dead = UnitIsDead(unit)
	local damage = ns.db.dotMarker and not (not issecretvalue(dead) and dead) and RemainingOn(unit) or 0
	if damage <= 0 or not o.bar:IsVisible() then return o.clip:Hide() end
	local ok, err = pcall(function() Paint(o, UnitHealth(unit), UnitHealthMax(unit), damage) end)
	if not ok then
		Report(err)
		o.clip:Hide()
	end
end

-- Target frame. Forever draws parts of the target frame over its own health bar, so the overlay sits
-- on UIParent above the frame's highest shown part (as DoesItDie does). Hidden layer values are skipped.
local target

local function RaiseAboveTargetFrame()
	local topStrata, topLevel = "BACKGROUND", 0
	local function Visit(frame, depth)
		local strata, level = frame:GetFrameStrata(), frame:GetFrameLevel()
		if frame:IsShown() and not issecretvalue(strata) and not issecretvalue(level) and STRATA_RANK[strata] then
			local rank, top = STRATA_RANK[strata], STRATA_RANK[topStrata]
			if rank > top or (rank == top and level > topLevel) then topStrata, topLevel = strata, level end
		end
		if depth < 6 then
			for _, child in ipairs({ frame:GetChildren() }) do Visit(child, depth + 1) end
		end
	end
	Visit(TargetFrame, 0)
	SetLayer(target, topStrata, topLevel)
end

local function CreateTargetOverlay()
	local main = TargetFrame.TargetFrameContent and TargetFrame.TargetFrameContent.TargetFrameContentMain
	local bar = main and main.HealthBarsContainer and main.HealthBarsContainer.HealthBar or TargetFrameHealthBar
	if not bar then return end
	target = CreateOverlay(UIParent)
	Attach(target, bar)
end

-- Nameplates: Blizzard reuses plate frames, so each gets one overlay, parented to the plate and a few
-- levels above its health bar. Plates Forever forbids to addons come back nil and are skipped.
local overlayByPlate = {}
local plates = {} -- [nameplate unit] = overlay, for the plates on screen

ns.On("NAME_PLATE_UNIT_ADDED", function(_, unit)
	local plate = C_NamePlate.GetNamePlateForUnit(unit)
	local bar = plate and plate.UnitFrame and plate.UnitFrame.healthBar
	if not bar then return end
	local o = overlayByPlate[plate]
	if not o then
		o = CreateOverlay(plate)
		overlayByPlate[plate] = o
	end
	Attach(o, bar)
	local level = bar:GetFrameLevel()
	SetLayer(o, nil, (issecretvalue(level) and 10 or level) + 5)
	plates[unit] = o
end)

ns.On("NAME_PLATE_UNIT_REMOVED", function(_, unit)
	if plates[unit] then
		plates[unit].clip:Hide()
		plates[unit] = nil
	end
end)

local testUntil -- /woe dots paints fixed values on the target frame until this time
local raisedAt = 0

local function Refresh()
	for unit, o in pairs(plates) do Update(o, unit) end
	if not target then return end
	-- Blizzard can re-layer the target frame at any time; check once a second.
	if GetTime() - raisedAt > 1 then
		raisedAt = GetTime()
		RaiseAboveTargetFrame()
	end
	if testUntil and GetTime() < testUntil then
		if target.bar:IsVisible() then Paint(target, 0.8, 1, 0.3) end -- purple from 50% to 80%
		return
	end
	Update(target, "target")
end

-- /woe dots: what's tracked on the target and how the overlay sits, then 5 seconds of fixed test
-- values on the target frame, to tell a drawing problem from a hidden-values one.
function ns.DotsDebug()
	local function Show(v) return issecretvalue(v) and "hidden" or tostring(v) end
	local mob = MobKey()
	ns.Print(("Target key %s, remaining DoT damage %d"):format(tostring(mob), RemainingOn("target")))
	for owner, dot in pairs(mob and dots[mob] or {}) do
		ns.Print(("  %s: %d over %ds, %.1fs left"):format(owner, dot.total, dot.duration, dot.ends - GetTime()))
	end
	local count = 0
	for _ in pairs(plates) do count = count + 1 end
	ns.Print(("Nameplates with an overlay: %d"):format(count))
	if not target then return ns.Print("Target frame overlay wasn't created.") end
	ns.Print(("Target overlay shown %s, visible %s, strata %s, level %s"):format(Show(target.clip:IsShown()),
		Show(target.clip:IsVisible()), Show(target.marker:GetFrameStrata()), Show(target.marker:GetFrameLevel())))
	ns.Print("Painting a test overlay on the target frame for 5 seconds...")
	testUntil = GetTime() + 5
end

ns.On("PLAYER_LOGIN", function()
	local ok, err = pcall(CreateTargetOverlay)
	if not ok then Report(err) end
	C_Timer.NewTicker(0.1, Refresh)
end)
