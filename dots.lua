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
local plates = {} -- [nameplate unit] = its overlay, for the enemy nameplates on screen

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

-- started: when the DoT was cast (default now), for groupmates' DoTs matched a moment late.
local function AddDot(mob, owner, total, duration, started)
	local now = GetTime()
	for key, list in pairs(dots) do -- drop expired DoTs on every mob while we're here
		for who, dot in pairs(list) do
			if dot.ends <= now then list[who] = nil end
		end
		if next(list) == nil then dots[key] = nil end
	end
	dots[mob] = dots[mob] or {}
	dots[mob][owner] = { total = total, duration = duration, ends = (started or now) + duration }
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

-- "40 Fire damage over 15 sec" -> 40, Fire's school mask, 15. Not DoTs on your target, though the
-- wording matches (checked against every Forever damage tooltip): area spells, Renew ("Heals the
-- target of 222 damage over 15 sec"), weapon poisons ("Coats a weapon...") and Immolation Trap.
local function ParseDot(spellID)
	local text = C_Spell.GetSpellDescription(spellID)
	if not text or issecretvalue(text) or text:find("^Heals") or text:find("^Coats a weapon") or text:find("trap") then return end
	if text:find("area") or text:find("all enemies") or text:find("nearby") then return end
	local amount, school, duration = text:match("(%d+) (%a*) ?damage over (%d+) sec")
	if amount then return tonumber(amount), SCHOOL_MASK[school] or 1, tonumber(duration) end
end

------------------------------------------------------------------------
-- Your casts
------------------------------------------------------------------------
-- A player's raw threat on a mob, or nil when they're not on its threat list (or it's hidden).
-- The server sends every client the same numbers, so it can tell mobs apart across clients.
local function ThreatOf(unit, mobUnit)
	local _, _, _, _, threat = UnitDetailedThreatSituation(unit, mobUnit)
	if threat ~= nil and not issecretvalue(threat) then return threat end
end

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
		-- Your threat on the mob lets groupmates find it on their screens (-1: not on its list yet).
		local threat = MobKey("target") == mob and ThreatOf("player", "target") or -1
		ns.SendToGroup(("dot:%s:%d:%d:%d:%d"):format(mob, spellID, total, duration, threat))
	end
end, "player")

-- Channels (Mind Flay, Drain Soul, Starshards) aren't DoTs. The cast check above skips them when the
-- channel has already started; if the channel start comes after the cast event, take it back here.
ns.On("UNIT_SPELLCAST_CHANNEL_START", function(_, _, _, spellID)
	if issecretvalue(spellID) or not lastCast or lastCast.spellID ~= spellID then return end
	RemoveDot(lastCast.mob, "me:" .. spellID)
	if lastCast.mob ~= "target" then
		ns.SendToGroup(("undot:%s:%d"):format(lastCast.mob, spellID))
	end
	lastCast = nil
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
-- Forever gives every player their own IDs for mobs (the same mob showed different IDs on two
-- clients), so a groupmate's "Corruption on <their ID>" can't be looked up directly. Which of your
-- mobs it is gets worked out from what both clients see, best signal first:
--   1. threat: the message carries their threat on the mob; the mob where their threat (readable
--      on your side, same number as on theirs) has that value is theirs.
--   2. threat list: on a fresh mob they had no threat yet; the mob whose threat list they join as
--      the message arrives is theirs.
--   3. debuffs: the mob where a debuff that isn't yours appears as the message arrives. Anyone's
--      debuff counts, so it's the weakest; with two candidates their current target decides.
-- A match is remembered for their later messages about that mob (recasts, misses). Only mobs with
-- a nameplate on your screen, or your target, can be matched.
local MATCH_WINDOW = 1 -- seconds between their message and what you see happen
local THREAT_TOLERANCE = 0.15 -- their threat moves a little between their measurement and yours
local aliases = {} -- [their mob ID] = your key for that mob
local auraIDs = {} -- [unit] = set of its debuff instance numbers last seen
local onThreatList = {} -- [unit] = set of groupmates on its threat list
local fresh = {} -- debuffs that just appeared and aren't yours: { mob, time, used }
local joined = {} -- groupmates who just joined a mob's threat list: { mob, who, time, used }
local pending = {} -- their DoTs waiting for a match: { theirs, who, owner, total, duration, threat, time }
local matchLog = {} -- last few matching decisions, for /woe dots

local function Log(text)
	table.insert(matchLog, ("%.1f %s"):format(GetTime(), text))
	if #matchLog > 6 then table.remove(matchLog, 1) end
end

-- Your groupmates as { unit = "party1", name = "First Last" } (the name as their messages carry it).
local function GroupMembers()
	local members, raid = {}, IsInRaid()
	local me = NameUtil.GetUnmodifiedUnitFullName("player")
	for i = 1, raid and GetNumGroupMembers() or GetNumSubgroupMembers() do
		local unit = (raid and "raid" or "party") .. i
		local ok, name = pcall(NameUtil.GetUnmodifiedUnitFullName, unit)
		if ok and name and not issecretvalue(name) and name ~= me then
			table.insert(members, { unit = unit, name = name })
		end
	end
	return members
end

local function GroupUnit(name)
	for _, member in ipairs(GroupMembers()) do
		if member.name == name then return member.unit end
	end
end

local function MobUnits()
	local units = { "target" }
	for unit in pairs(plates) do table.insert(units, unit) end
	return units
end

-- 1: the mob where their threat is close to what they reported, and clearly closer than any other.
local function MatchByThreat(p)
	if not p.threat or p.threat < 0 then return end
	local unit = GroupUnit(p.who)
	if not unit then return end
	local best, bestErr, secondErr, seen = nil, nil, nil, {}
	for _, mobUnit in ipairs(MobUnits()) do
		local mob = MobKey(mobUnit)
		local threat = mob and not seen[mob] and ThreatOf(unit, mobUnit)
		if threat then
			seen[mob] = true
			local err = math.abs(threat - p.threat) / math.max(p.threat, threat, 100)
			if not bestErr or err < bestErr then
				best, secondErr, bestErr = mob, bestErr, err
			elseif not secondErr or err < secondErr then
				secondErr = err
			end
		end
	end
	if best and bestErr <= THREAT_TOLERANCE and (not secondErr or secondErr > 2 * bestErr + 0.05) then return best end
end

-- The mobs with an unused event within the window of the message (only theirs, if who is given).
local function Candidates(events, p, who)
	local mobs, count = {}, 0
	for _, event in ipairs(events) do
		if not event.used and (not who or event.who == who) and math.abs(event.time - p.time) <= MATCH_WINDOW
			and not mobs[event.mob] then
			mobs[event.mob] = event
			count = count + 1
		end
	end
	return mobs, count
end

local function TryMatch()
	local now = GetTime()
	for i = #pending, 1, -1 do
		local p = pending[i]
		local mob, how = MatchByThreat(p), "threat"
		if not mob then -- 2
			local mobs, count = Candidates(joined, p, p.who)
			if count == 1 then
				mob, how = next(mobs), "joining the threat list"
				mobs[mob].used = true
			end
		end
		if not mob then -- 3
			local mobs, count = Candidates(fresh, p)
			if count == 1 then
				mob = next(mobs)
			elseif count > 1 then
				local unit = GroupUnit(p.who)
				local theirTarget = unit and MobKey(unit .. "target")
				if theirTarget and mobs[theirTarget] then mob = theirTarget end
			end
			if mob then
				mobs[mob].used = true
				how = ("a new debuff (%d candidate%s)"):format(count, count > 1 and "s" or "")
			end
		end
		if mob then
			if mob ~= "target" then aliases[p.theirs] = mob end -- "target" moves with your target
			AddDot(mob, p.owner, p.total, p.duration, p.time)
			Log(("matched %s's %s by %s"):format(p.who, p.owner:match("%d+$"), how))
			table.remove(pending, i)
		elseif now - p.time > MATCH_WINDOW then
			Log(("no match for %s's %s"):format(p.who, p.owner:match("%d+$")))
			table.remove(pending, i)
		end
	end
	for _, events in ipairs({ fresh, joined }) do
		for i = #events, 1, -1 do
			if now - events[i].time > 3 * MATCH_WINDOW then table.remove(events, i) end
		end
	end
end

-- Notes groupmates who weren't on the unit's threat list before. quiet: just learn who's on it.
local function ScanThreat(unit, quiet)
	local before, now, any = onThreatList[unit] or {}, {}, false
	for _, member in ipairs(GroupMembers()) do
		if ThreatOf(member.unit, unit) then
			now[member.name] = true
			local mob = not quiet and not before[member.name] and MobKey(unit)
			if mob then
				table.insert(joined, { mob = mob, who = member.name, time = GetTime() })
				any = true
			end
		end
	end
	onThreatList[unit] = now
	if any then TryMatch() end
end

-- Notes debuffs on the unit that weren't there before and aren't yours. quiet: just learn what's
-- there (a nameplate that just appeared, a new target).
local function ScanAuras(unit, quiet)
	local ok, ids = pcall(C_UnitAuras.GetUnitAuraInstanceIDs, unit, "HARMFUL")
	if not ok or type(ids) ~= "table" or issecretvalue(ids) then return end
	local before, now, appeared = auraIDs[unit] or {}, {}, false
	for _, id in ipairs(ids) do
		if not issecretvalue(id) then
			now[id] = true
			if not quiet and not before[id] then
				local okFilter, notMine = pcall(C_UnitAuras.IsAuraFilteredOutByInstanceID, unit, id, "HARMFUL|PLAYER")
				if okFilter and not issecretvalue(notMine) and notMine then appeared = true end
			end
		end
	end
	auraIDs[unit] = now
	local mob = appeared and MobKey(unit)
	if mob then
		table.insert(fresh, { mob = mob, time = GetTime() })
		TryMatch()
	end
end

-- Its own frame: core.lua's UNIT_AURA handler only listens to the target.
local watcher = CreateFrame("Frame")
watcher:RegisterEvent("UNIT_AURA")
watcher:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
watcher:SetScript("OnEvent", function(_, event, unit)
	if unit ~= "target" and not plates[unit] then return end
	if event == "UNIT_AURA" then ScanAuras(unit) else ScanThreat(unit) end
end)
ns.On("PLAYER_TARGET_CHANGED", function()
	ScanAuras("target", true)
	ScanThreat("target", true)
end)
ns.On("PLAYER_REGEN_ENABLED", function() -- a fight's matches end with it
	wipe(aliases)
	wipe(fresh)
	wipe(joined)
end)

-- Their ID is used as-is if a mob you can see has it (in case IDs ever do match).
local function Seen(theirs)
	if MobKey("target") == theirs then return true end
	for unit in pairs(plates) do
		if MobKey(unit) == theirs then return true end
	end
end

ns.On("CHAT_MSG_ADDON", function(_, prefix, text, _, sender)
	if issecretvalue(prefix) or issecretvalue(text) or issecretvalue(sender) then return end
	if prefix ~= ns.PREFIX or ns.IsMe(sender) then return end
	local who = Ambiguate(sender, "short")
	-- The threat field is new; older versions send the message without it.
	local theirs, spellID, total, duration, threat = text:match("^dot:([^:]+):(%d+):(%d+):(%d+):?(%-?%d*)$")
	if theirs then
		local owner = who .. ":" .. spellID
		local mob = aliases[theirs] or (Seen(theirs) and theirs)
		if mob then
			AddDot(mob, owner, tonumber(total), tonumber(duration))
		else
			table.insert(pending, { theirs = theirs, who = who, owner = owner, total = tonumber(total),
				duration = tonumber(duration), threat = tonumber(threat), time = GetTime() })
			TryMatch()
		end
		return
	end
	theirs, spellID = text:match("^undot:([^:]+):(%d+)$")
	if theirs then
		local owner = who .. ":" .. spellID
		RemoveDot(aliases[theirs] or theirs, owner)
		for i = #pending, 1, -1 do
			if pending[i].theirs == theirs and pending[i].owner == owner then table.remove(pending, i) end
		end
	end
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

-- Target frame. Its parts are drawn over its own health bar, and it's a "toplevel" frame that WoW
-- raises above its strata whenever it's shown or clicked, so matching its level isn't enough. The
-- overlay sits on UIParent one whole strata above the target frame's highest part (LOW -> MEDIUM),
-- at the bottom of that strata so open windows still cover it. Hidden strata values are skipped.
local STRATA_ORDER = { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP" }
local target

local function RaiseAboveTargetFrame()
	local top = STRATA_RANK.LOW
	local function Visit(frame, depth)
		local strata = frame:GetFrameStrata()
		if frame:IsShown() and not issecretvalue(strata) and STRATA_RANK[strata] then
			top = math.max(top, STRATA_RANK[strata])
		end
		if depth < 6 then
			for _, child in ipairs({ frame:GetChildren() }) do Visit(child, depth + 1) end
		end
	end
	Visit(TargetFrame, 0)
	SetLayer(target, STRATA_ORDER[math.min(top + 1, #STRATA_ORDER)], 0)
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
	ScanAuras(unit, true) -- debuffs and threat already on it aren't new
	ScanThreat(unit, true)
end)

ns.On("NAME_PLATE_UNIT_REMOVED", function(_, unit)
	auraIDs[unit] = nil
	onThreatList[unit] = nil
	if plates[unit] then
		plates[unit].clip:Hide()
		plates[unit] = nil
	end
end)

local testUntil -- /woe dots paints fixed values on the target frame until this time
local raisedAt = 0

local function Refresh()
	if #pending > 0 then TryMatch() end -- lets unmatched messages expire
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
	-- Mob IDs shortened to their last three parts: zone copy, creature type, the individual mob.
	local function Short(id)
		if not id then return "none" end
		if issecretvalue(id) then return "hidden" end
		return id:match("%-(%d+%-%d+%-%x+)$") or id
	end
	local now = GetTime()
	ns.Print(("Target %s, remaining DoT damage %d"):format(Short(MobKey()), RemainingOn("target")))
	ns.Print("Tracked DoTs (yours and your group's):")
	for mob, list in pairs(dots) do
		for owner, dot in pairs(list) do
			ns.Print(("  %s on %s: %d over %ds, %.1fs left"):format(owner, Short(mob), dot.total, dot.duration, dot.ends - now))
		end
	end
	ns.Print("Enemy nameplates on screen:")
	for unit in pairs(plates) do
		ns.Print(("  %s: %s, remaining DoT damage %d"):format(unit, Short(MobKey(unit) or UnitGUID(unit)), RemainingOn(unit)))
	end
	local matched = 0
	for _ in pairs(aliases) do matched = matched + 1 end
	ns.Print(("Groupmates' mobs matched this fight: %d, messages waiting: %d. Recent matching:"):format(matched, #pending))
	for _, line in ipairs(matchLog) do ns.Print("  " .. line) end
	if not target then return ns.Print("Target frame overlay wasn't created.") end
	ns.Print(("Target overlay shown %s, visible %s, strata %s, level %s"):format(Show(target.clip:IsShown()),
		Show(target.clip:IsVisible()), Show(target.marker:GetFrameStrata()), Show(target.marker:GetFrameLevel())))
	-- Screen positions, to rule out the overlay sitting somewhere other than on the bar.
	local function Rect(frame)
		local ok, text = pcall(function()
			local s = frame:GetEffectiveScale()
			return ("%.0f,%.0f %.0fx%.0f"):format(frame:GetLeft() * s, frame:GetBottom() * s, frame:GetWidth() * s, frame:GetHeight() * s)
		end)
		return ok and text or "hidden"
	end
	ns.Print(("Health bar at %s, overlay at %s"):format(Rect(target.bar), Rect(target.clip)))
	ns.Print("Painting a test overlay on the target frame for 5 seconds...")
	testUntil = GetTime() + 5
end

ns.On("PLAYER_LOGIN", function()
	local ok, err = pcall(CreateTargetOverlay)
	if not ok then Report(err) end
	C_Timer.NewTicker(0.1, Refresh)
end)
