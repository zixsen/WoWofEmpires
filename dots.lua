-- DoT kill marker: shows on the target frame and on enemy nameplates whether the DoTs on a mob
-- (yours, plus those of groupmates running this addon) will finish it off.
--
-- Forever hides target health and auras from addons, so this never decides "will it die" itself.
-- Instead the end of the green health is painted purple for the damage the DoTs still have to deal,
-- through status bars fed the target's (hidden) health and max health: they can draw hidden values
-- (idea from DoesItDie by swirllyman, MIT). No red left = the target dies.
--
-- The red's end (the health once the DoTs are done) must not move when a DoT ticks: the tick takes
-- the same off the health and off the damage still to come. Forever hides tick amounts, but they can
-- still be drawn: each tick's real (hidden) amount, as Forever reports it (UNIT_COMBAT), is chained
-- into the purple as one more bar, so the edge is health + the ticks so far - the DoTs' whole damage,
-- and a tick adds to the chain exactly what it takes off the health, in the same frame. Only other
-- damage moves the edge. Which hit was your tick: see "Ticks" below.
--
-- Priests can also see when a mob is in Shadow Word: Death range: the green turns gold, on the
-- target frame and enemy nameplates, once one cast kills.
local addonName, ns = ...

ns.defaults.dotMarker = false -- off until turned on in Settings; DoTs are shared with the group either way
ns.defaults.dotPlatesOnly = false -- the purple on nameplates only, not on the target frame
ns.defaults.swdMarker = false
ns.defaults.dotLines = {} -- [spellID] = whether its ticks show up in your combat log (learned, see the hit matching)

local TICK = 3 -- most DoTs tick every 3 sec; the rest are close enough
local SCHOOL_MASK = { Holy = 2, Fire = 4, Nature = 8, Frost = 16, Shadow = 32, Arcane = 64 }
local AVOIDED = { MISS = true, RESIST = true, IMMUNE = true, DODGE = true, PARRY = true, EVADE = true }

-- dots[mob][owner] = { total, duration, ends }. mob is a GUID, or "target" where Forever hides GUIDs
-- (instances): then only your own DoTs on your current target are tracked. owner is "me:<spellID>"
-- or "<groupmate>:<spellID>".
local dots = {}
local plates = {} -- [nameplate unit] = its overlay, for the enemy nameplates on screen

local function Hostile(unit)
	local hostile = UnitCanAttack("player", unit)
	return not issecretvalue(hostile) and hostile
end

-- The key DoTs are kept under for a hostile unit (default: your target). Without GUIDs only the
-- target has one, so a nameplate only finds DoTs there if it's your target's.
local function MobKey(unit)
	unit = unit or "target"
	if not UnitExists(unit) or not Hostile(unit) then return nil end
	local guid = UnitGUID(unit)
	if guid and not issecretvalue(guid) then return guid end
	if unit == "target" then return "target" end
	local isTarget = UnitIsUnit(unit, "target")
	if not issecretvalue(isTarget) and isTarget then return "target" end
end

-- Ticks: one every TICK sec after the cast, each reported by UNIT_COMBAT on your target and the
-- nameplates on screen, the moment it lands, with its school (not its amount, which is hidden). A
-- hit counts as a DoT's tick when it's in the DoT's school, within a window of its next tick (the
-- rhythm follows the ticks seen), and, for a DoT whose ticks show up in your combat log, arrives in
-- the same frame as a combat log line (see the hit matching further down). A tick nobody saw (the
-- mob out of sight) counts as landed TICK_SEEN after it was due, with an estimated amount.
-- dot.landed = ticks landed; dot.amounts = their amounts (hidden, or estimated for unseen ones);
-- dot.firstTick = the first ordinary tick's amount, the size of the ticks still to come;
-- dot.seenAt, dot.seenTick = when the last tick seen landed, and which;
-- dot.unsure = the last tick booked, until its window closes (see the hit matching).
local TICK_SEEN = 0.3 -- before any tick was seen: the first tick lands ~0.1 sec off the cast's rhythm
local TICK_SEEN_SYNCED = 0.15 -- once one was seen, the rest land on its rhythm

local function TickCount(dot)
	return math.max(1, math.floor(dot.duration / TICK + 0.5))
end

-- The size of one tick: the first real one once seen (hidden), else the tooltip's share.
local function TickSize(dot)
	return dot.firstTick or dot.total / TickCount(dot)
end

-- When the DoT's next tick is due, and how far off a hit may be to count as it.
local function NextTick(dot)
	if dot.seenAt then return dot.seenAt + (dot.landed - dot.seenTick + 1) * TICK, TICK_SEEN_SYNCED end
	return dot.ends - dot.duration + (dot.landed + 1) * TICK, TICK_SEEN
end

-- Damage still to come, as a plain estimate (the purple itself uses the real amounts): the ticks
-- that haven't landed times the tooltip's share.
local function Remaining(dot, now)
	local u = dot.unsure
	if u and now > u.till then -- its window closed with nothing to doubt it: the tick was the tick
		if u.first and not dot.firstTick then dot.firstTick = u.first end
		if u.crit then dot.amounts[u.index] = TickSize(dot) end -- a tick, plus extra damage
		dot.unsure = nil
	end
	local ticks = TickCount(dot)
	while dot.landed < ticks do -- ticks nobody saw land count once they're overdue
		local due, window = NextTick(dot)
		if now <= due + window then break end
		dot.landed = dot.landed + 1
		table.insert(dot.amounts, TickSize(dot))
	end
	return dot.total * (ticks - dot.landed) / ticks
end

-- Whether a DoT still counts toward the purple: while it runs, or another DoT of its school on the
-- mob does. Two DoTs of one school ticking together can't always be told apart, so a tick may be
-- booked to the other one; their real amounts only add up right as a group, so a finished one stays
-- in until its whole group is done.
local function Counts(list, dot, now)
	for _, other in pairs(list) do
		if other.school == dot.school and Remaining(other, now) > 0 then return true end
	end
	return false
end

-- started: when the DoT was cast (default now), for groupmates' DoTs matched a moment late.
-- owner ends in the spell ID ("me:589", "Name:589"); the hit matching looks its school up from it.
local function AddDot(mob, owner, total, duration, started)
	local now = GetTime()
	for key, list in pairs(dots) do -- drop finished DoTs on every mob while we're here
		for who, dot in pairs(list) do
			if not Counts(list, dot, now) then list[who] = nil end
		end
		if next(list) == nil then dots[key] = nil end
	end
	dots[mob] = dots[mob] or {}
	dots[mob][owner] = { total = total, duration = duration, ends = (started or now) + duration,
		spellID = tonumber(owner:match("%d+$")), mine = owner:find("^me:") ~= nil, landed = 0, amounts = {} }
end

local function RemoveDot(mob, owner)
	if dots[mob] then dots[mob][owner] = nil end
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

-- /woe dots trace (again to stop): prints each DoT you cast and every change to your target's health
-- with the DoT damage counted as still to come right then, timed from when the trace started.
local traceFrom
function ns.DotsTrace()
	traceFrom = not traceFrom and GetTime() or nil
	ns.Print(traceFrom and "DoT trace on. /woe dots trace again to stop." or "DoT trace off.")
end

local function Trace(text)
	if traceFrom then ns.Print(("%.3f %s"):format(GetTime() - traceFrom, text)) end -- same time = same frame
end

-- Your target, or the nameplate showing it (the trace follows both).
local function IsTarget(unit)
	if unit == "target" then return true end
	local same = UnitIsUnit(unit, "target")
	return not issecretvalue(same) and same
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
local castAt = {} -- [mob] = when your last spell at it went off, for the hit matching
local lastCast -- for taking back a resisted or missed DoT

ns.On("UNIT_SPELLCAST_SENT", function(_, _, _, castGUID)
	if not issecretvalue(castGUID) then sentTarget[castGUID] = MobKey() end
end, "player")

ns.On("UNIT_SPELLCAST_SUCCEEDED", function(_, _, castGUID, spellID)
	if issecretvalue(castGUID) or issecretvalue(spellID) then return end
	local mob = sentTarget[castGUID]
	sentTarget[castGUID] = nil
	if not mob then return end
	castAt[mob] = GetTime()
	-- Tracked and shared even with your own marker off, for groupmates who have theirs on.
	local channeled = select(8, UnitChannelInfo("player"))
	if channeled and not issecretvalue(channeled) and channeled == spellID then return end -- Mind Flay isn't a DoT
	local total, school, duration = ParseDot(spellID)
	if not total then return end
	AddDot(mob, "me:" .. spellID, total, duration)
	Trace(("cast %s: %d over %d sec"):format(C_Spell.GetSpellName(spellID) or spellID, total, duration))
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
-- a nameplate on your screen, or your target, can be matched. A DoT on a mob you can't see yet (out
-- of nameplate range) waits until it runs out: the caster re-sends their threat on their DoT'd mobs
-- every few seconds, so it's matched by threat once the mob shows up on your screen.
local MATCH_WINDOW = 1 -- seconds between their message and what you see happen
local THREAT_TOLERANCE = 0.15 -- their threat moves a little between their measurement and yours
local SYNC_EVERY = 3 -- seconds between threat updates for your DoT'd mobs
local aliases = {} -- [their mob ID] = your key for that mob
local auraIDs = {} -- [unit] = set of its debuff instance numbers last seen
local onThreatList = {} -- [unit] = set of groupmates on its threat list
local fresh = {} -- debuffs that just appeared and aren't yours: { mob, time, used }
local joined = {} -- groupmates who just joined a mob's threat list: { mob, who, time, used }
-- Their DoTs waiting for a match: { theirs, who, owner, total, duration, threat, threatTime, time }
local pending = {}
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

-- "sync:<mob>=<threat>:<mob>=<threat>": your threat now on each mob (that you can see) with your
-- DoTs on it, for groupmates still waiting to match one.
-- ponytail: one message, so only as many mobs as fit in 255 characters (about five).
local function SyncThreat()
	if not IsInGroup() then return end
	local now, message, done = GetTime(), "sync", {}
	for _, unit in ipairs(MobUnits()) do
		local mob = MobKey(unit)
		if mob and mob ~= "target" and dots[mob] and not done[mob] then
			done[mob] = true
			for owner, dot in pairs(dots[mob]) do
				local threat = owner:find("^me:") and dot.ends > now and ThreatOf("player", unit)
				if threat then
					local entry = (":%s=%d"):format(mob, threat)
					if #message + #entry <= 255 then message = message .. entry end
					break
				end
			end
		end
	end
	if message ~= "sync" then ns.SendToGroup(message) end
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
		local mob, how = aliases[p.theirs], "an earlier match"
		-- 1, only right after they measured it: their threat keeps changing
		if not mob and now - p.threatTime <= MATCH_WINDOW then mob, how = MatchByThreat(p), "threat" end
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
		elseif now - p.time > p.duration then
			Log(("no match for %s's %s before it ran out"):format(p.who, p.owner:match("%d+$")))
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
watcher:RegisterEvent("UNIT_HEALTH")
watcher:SetScript("OnEvent", function(_, event, unit)
	if unit ~= "target" and not plates[unit] then return end
	if event == "UNIT_HEALTH" then
		if IsTarget(unit) then Trace(("health changed on %s, DoTs still to deal %d"):format(unit, RemainingOn(unit))) end
	elseif event == "UNIT_AURA" then
		ScanAuras(unit)
	else
		ScanThreat(unit)
	end
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
			for i = #pending, 1, -1 do -- a recast replaces the one still waiting
				if pending[i].theirs == theirs and pending[i].owner == owner then table.remove(pending, i) end
			end
			table.insert(pending, { theirs = theirs, who = who, owner = owner, total = tonumber(total),
				duration = tonumber(duration), threat = tonumber(threat), threatTime = GetTime(), time = GetTime() })
			TryMatch()
		end
		return
	end
	if text:find("^sync:") then
		for mob, threat in text:gmatch(":([^:=]+)=(%d+)") do
			for _, p in ipairs(pending) do
				if p.theirs == mob and p.who == who then p.threat, p.threatTime = tonumber(threat), GetTime() end
			end
		end
		if #pending > 0 then TryMatch() end
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
local FINE = 100 -- the purple's helper bars are drawn this many times smaller (see CreateOverlay)
local STRATA_RANK = { BACKGROUND = 1, LOW = 2, MEDIUM = 3, HIGH = 4, DIALOG = 5, FULLSCREEN = 6, FULLSCREEN_DIALOG = 7, TOOLTIP = 8 }

-- Errors here would otherwise be invisible (Lua errors are off by default), so say it once in chat.
local lastError -- also shown by /woe dots
local function Report(err)
	if not lastError then ns.Print("DoT overlay error, please report: " .. tostring(err)) end
	lastError = tostring(err)
end

-- Forever can hide whether a frame is shown (some target frame parts in dungeons); count that as shown.
local function Visible(region)
	local visible = region:IsVisible()
	return issecretvalue(visible) or visible
end

-- One overlay over a health bar: a clip frame (keeps the purple inside the bar when the DoTs
-- out-damage what's left) holding an invisible copy of the bar (mirror, whose fill ends where the
-- green ends; Forever won't let addon frames hang off Blizzard's own fill) and the purple (marker).
-- An invisible helper status bar: drawn at 1/FINE scale and not rounded to pixels.
local function Helper(bar)
	bar:SetScale(1 / FINE)
	bar:SetStatusBarTexture(WHITE)
	bar:SetStatusBarColor(0, 0, 0, 0)
	bar:GetStatusBarTexture():SetTexelSnappingBias(0)
	bar:GetStatusBarTexture():SetSnapToPixelGrid(false)
	return bar
end

local function CreateOverlay(parent)
	local o = {}
	o.clip = CreateFrame("Frame", nil, parent)
	o.clip:SetClipsChildren(true)
	o.clip:Hide()

	o.mirror = CreateFrame("StatusBar", nil, o.clip)
	o.mirror:SetAllPoints()
	o.mirror:SetStatusBarTexture(WHITE)
	o.mirror:SetStatusBarColor(0, 0, 0, 0)

	-- Everything below is drawn only over the green: cut off where the mirror's fill ends.
	o.green = CreateFrame("Frame", nil, o.clip)
	o.green:SetClipsChildren(true)
	o.green:SetPoint("TOPLEFT")
	o.green:SetPoint("BOTTOMRIGHT", o.mirror:GetStatusBarTexture(), "BOTTOMRIGHT")

	-- Shadow Word: Death: the green turns gold once health <= its damage. Hidden health can't be
	-- compared, so an invisible status bar (gate) does it: min 0, max damage + 1, value health,
	-- (damage + 1) bar widths wide and right-aligned with the bar. Above the damage its fill reaches
	-- the bar's right edge; at or below, the fill stops at least one bar width short (never at zero
	-- while the target lives). The gold runs from the end of that fill to the bar's right edge, cut
	-- off where the green ends: nothing above the damage, all the green at or below it.
	o.gate = CreateFrame("StatusBar", nil, o.clip)
	o.gate:SetPoint("TOPRIGHT")
	o.gate:SetPoint("BOTTOMRIGHT")
	o.gate:SetStatusBarTexture(WHITE)
	o.gate:SetStatusBarColor(0, 0, 0, 0)
	o.over = CreateFrame("Frame", nil, o.green) -- above the purple: one cast kills, whatever the DoTs do
	o.over:SetAllPoints(o.clip)
	o.gold = o.over:CreateTexture(nil, "ARTWORK")
	o.gold:SetColorTexture(1, 0.8, 0.1, 0.85)
	o.gold:SetPoint("TOPLEFT", o.gate:GetStatusBarTexture(), "TOPRIGHT")
	o.gold:SetPoint("BOTTOMRIGHT", o.clip, "BOTTOMRIGHT")

	-- The purple: from the red's end (the health once the DoTs are done) to the green's end, cut off
	-- where the green ends. The red's end is found by a chain of invisible helper bars (see Paint),
	-- starting from fine, a copy of the health bar. They're drawn at 1/FINE scale and not rounded to
	-- pixels, so only the purple's own edge gets rounded, once.
	o.fine = Helper(CreateFrame("StatusBar", nil, o.clip))
	o.fine:SetAllPoints()
	o.chain = {} -- the helper bars, made as needed

	o.marker = CreateFrame("Frame", nil, o.green)
	o.marker:SetAllPoints(o.clip)
	o.purple = o.marker:CreateTexture(nil, "ARTWORK")
	o.purple:SetColorTexture(0.62, 0.2, 1, 0.8)

	-- A thin line at the red's end.
	local edge = o.marker:CreateTexture(nil, "OVERLAY")
	edge:SetColorTexture(1, 1, 1, 0.9)
	edge:SetWidth(1)
	edge:SetPoint("TOPLEFT", o.purple, "TOPLEFT")
	edge:SetPoint("BOTTOMLEFT", o.purple, "BOTTOMLEFT")
	return o
end

local function Attach(o, bar)
	o.bar = bar
	o.clip:ClearAllPoints()
	o.clip:SetAllPoints(bar)
end

-- strata nil keeps the parent's.
local function SetLayer(o, strata, level)
	for i, frame in ipairs({ o.clip, o.mirror, o.gate, o.green, o.fine, o.marker, o.over }) do
		if strata then frame:SetFrameStrata(strata) end
		frame:SetFrameLevel(level + i)
	end
end

-- Paints the DoT damage still to come (purple) and Shadow Word: Death range (gold) on the unit's bar.
-- min/max/value can be hidden values: status bars draw them without the addon ever reading them.
-- parts: per DoT { ticks = how many it deals, tick = the size of one, amounts = the ticks landed }.
-- The red's end is worked out from the green's end without any sums in Lua: for each DoT, back by
-- its whole damage (a reverse-filled bar ticks bar-widths wide, filled to one tick), then forward by
-- each tick that landed (a bar per tick, filled to its real amount). A tick lowers the health and
-- lengthens the chain by the same amount, so the red's end stays exactly where it was.
local function Paint(o, health, max, parts, swd)
	-- The whole bar's width is the mob's max health. Kept from when it was last readable, in case
	-- Forever hides it.
	local width = o.clip:GetWidth()
	if issecretvalue(width) then width = o.width else o.width = width end
	o.mirror:SetMinMaxValues(0, max)
	o.mirror:SetValue(health)
	o.fine:SetMinMaxValues(0, max)
	o.fine:SetValue(health)

	local point, side, used = o.fine:GetStatusBarTexture(), "RIGHT", 0
	local function Step(back, ticks, value)
		used = used + 1
		local bar = o.chain[used]
		if not bar then
			bar = Helper(CreateFrame("StatusBar", nil, o.clip))
			o.chain[used] = bar
		end
		local from = back and "RIGHT" or "LEFT"
		bar:ClearAllPoints()
		bar:SetReverseFill(back)
		bar:SetPoint("TOP" .. from, point, "TOP" .. side)
		bar:SetPoint("BOTTOM" .. from, point, "BOTTOM" .. side)
		bar:SetWidth(width * FINE * ticks)
		bar:SetMinMaxValues(0, max)
		bar:SetValue(value)
		bar:Show()
		point, side = bar:GetStatusBarTexture(), back and "LEFT" or "RIGHT"
	end
	for _, part in ipairs(parts) do
		Step(true, part.ticks, part.tick)
		for _, amount in ipairs(part.amounts) do Step(false, 1, amount) end
	end
	for i = used + 1, #o.chain do o.chain[i]:Hide() end
	o.purple:ClearAllPoints()
	o.purple:SetPoint("TOPLEFT", point, "TOP" .. side)
	o.purple:SetPoint("BOTTOMRIGHT", o.mirror:GetStatusBarTexture(), "BOTTOMRIGHT")
	o.marker:SetShown(#parts > 0)
	o.gate:SetWidth(width * (swd + 1))
	o.gate:SetMinMaxValues(0, swd + 1)
	o.gate:SetValue(health)
	o.gold:SetShown(swd > 0)
	o.clip:Show()
end

-- Shadow Word: Death's damage from its tooltip (the low end of "450 to 522 Shadow damage"), 0 if you
-- don't know it. Read once a second: it changes as you level, and the text can load late.
local swdDamage, swdReadAt = 0, -1
local function SwdDamage()
	if GetTime() - swdReadAt < 1 then return swdDamage end
	swdReadAt, swdDamage = GetTime(), 0
	local info = C_Spell.GetSpellInfo("Shadow Word: Death")
	if not info or (IsPlayerSpell and not IsPlayerSpell(info.spellID)) then return 0 end
	local text = C_Spell.GetSpellDescription(info.spellID)
	if not text or issecretvalue(text) then return 0 end
	local amount = text:match("(%d[%d,]*) to %d[%d,]* %a* ?damage") or text:match("(%d[%d,]*) %a* ?damage")
	swdDamage = amount and tonumber((amount:gsub(",", ""))) or 0
	return swdDamage
end

local target -- the target frame's overlay

local function Update(o, unit)
	local dead = UnitIsDead(unit)
	local alive = not (not issecretvalue(dead) and dead)
	local damage = alive and ns.db.dotMarker and not (o == target and ns.db.dotPlatesOnly) and RemainingOn(unit) or 0
	local swd = alive and ns.db.swdMarker and Hostile(unit) and SwdDamage() or 0
	if (damage <= 0 and swd <= 0) or not Visible(o.bar) then return o.clip:Hide() end
	if traceFrom and damage ~= o.traced and IsTarget(unit) then
		o.traced = damage
		Trace(("purple on %s now about %d"):format(unit, damage))
	end
	local parts, now = {}, GetTime()
	if damage > 0 then
		local list = dots[MobKey(unit)] or {}
		for owner, dot in pairs(list) do
			if Counts(list, dot, now) then
				table.insert(parts, { owner = owner, ticks = TickCount(dot), tick = TickSize(dot), amounts = dot.amounts })
			end
		end
		table.sort(parts, function(a, b) return a.owner < b.owner end)
	end
	local ok, err = pcall(function() Paint(o, UnitHealth(unit), UnitHealthMax(unit), parts, swd) end)
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

local function RaiseAboveTargetFrame()
	local top = STRATA_RANK.LOW
	local function Visit(frame, depth)
		local shown, strata = frame:IsShown(), frame:GetFrameStrata()
		if (issecretvalue(shown) or shown) and not issecretvalue(strata) and STRATA_RANK[strata] then
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
		if Visible(target.bar) then -- gold to 50%, purple 50% to 80%
			Paint(target, 0.8, 1, { { ticks = 1, tick = 0.3, amounts = {} } }, 0.9)
		end
		return
	end
	Update(target, "target")
end

local function RefreshNow()
	local ok, err = pcall(Refresh)
	if not ok then Report(err) end
end

-- Which hit was your tick. Everything a frame brings is collected (events all run before the frame's
-- OnUpdate) and sorted out in OnUpdate, then the overlays are repainted before the frame is drawn:
--   hits     UNIT_COMBAT on your target and the nameplates on screen: school and moment, hidden amount
--   lines    combat log lines (COMBAT_LOG_MESSAGE, live ones): their text is locked, but each is one
--            event your combat log filter shows, in the same frame as the hit it's about
-- A hit is a DoT's tick when it's in the DoT's school, close to its next tick, and, for a spell whose
-- ticks show up in your combat log (learned per spell, see below), comes with a line. So for those,
-- other damage of the same school (a groupmate's spell, a shadow wand: neither puts a line in your
-- log) can't pass for the tick. Spells your filter doesn't log fall back on school and timing, which
-- is why the filter should show all your periodic damage (drain and leech too, for Devouring Plague).
-- Groupmates' DoTs go by school and timing too: their ticks aren't in your log.
-- The same hit is reported once per unit showing the mob (target, nameplate) and counts once; two
-- DoTs of one school ticking in the same instant are two hits through the same unit.
local LIVE_LINE = Enum.CombatLogMessageOrder and Enum.CombatLogMessageOrder.Newest or 0
local CLEAN = 0.5 -- a tick is clean when no other DoT of its school on the mob is due within this
local cleanEvidence, cleanStreak = {}, {} -- [spellID]: clean ticks in a row with a line (true) or without
local pendingHits, pendingLines, pendingPaint = {}, 0, false

local function NoFlag(flag)
	return flag == nil or issecretvalue(flag) or flag == ""
end

-- Whether the DoT's ticks show up in your combat log: learned for yours (nil until then); a
-- groupmate's never do with the usual filter, so theirs go by school and timing.
local function Lines(dot)
	if dot.mine then return ns.db.dotLines[dot.spellID] end
	return false
end

-- Whether one of your own spells may be landing on the mob right now: one went off at it within the
-- last second (travel time), you're channeling (Mind Flay ticks), or a cast is about to finish.
local function OwnHitNear(mob, now)
	if castAt[mob] and now - castAt[mob] <= 1 then return true end
	if UnitChannelInfo("player") then return true end
	local _, _, _, _, ends = UnitCastingInfo("player")
	if not ends then return false end
	return issecretvalue(ends) or ends / 1000 - now <= 0.2
end

local function MatchHits()
	local now, lines = GetTime(), pendingLines
	local hits, firstUnit, fed, schoolHits = {}, {}, {}, {}
	for _, h in ipairs(pendingHits) do
		local mob = MobKey(h.unit)
		if mob and dots[mob] then
			local key = mob .. ":" .. h.school .. ":" .. (NoFlag(h.flag) and "" or h.flag)
			firstUnit[key] = firstUnit[key] or h.unit
			if firstUnit[key] == h.unit then
				h.mob = mob
				table.insert(hits, h)
				schoolHits[mob .. ":" .. h.school] = (schoolHits[mob .. ":" .. h.school] or 0) + 1
				for _, dot in pairs(dots[mob]) do -- its school, from its tooltip, once
					if dot.school == nil then dot.school = select(2, ParseDot(dot.spellID)) or false end
				end
			end
		end
	end

	-- The DoT this hit can be the tick of: right school, near its next tick, not fed yet this frame,
	-- and allowed(dot).
	local function Candidate(h, allowed)
		local best, bestOwner, bestOff
		for owner, dot in pairs(dots[h.mob]) do
			if not fed[dot] and dot.school == h.school and allowed(dot) and Remaining(dot, now) > 0 then
				local due, window = NextTick(dot)
				local off = math.abs(now - due)
				if off <= window and (not bestOff or off < bestOff) then best, bestOwner, bestOff = dot, owner, off end
			end
		end
		return best, bestOwner
	end

	-- Every tick booked stays unsure until its window closes (it settles in Remaining). A hit of its
	-- school on the mob that turns out not to be a tick, inside that window (your Mind Blast or Mind
	-- Flay, a groupmate's spell), means the booked one may not have been the tick either: it's then
	-- booked at its estimated size, and so is any booking the doubted hit itself had pushed aside
	-- (u.after). Whichever way round they came, the red's end ends up where it belongs, and it only
	-- moves left on the way there. A crit settles at the tick size too: a tick plus extra damage.
	-- The size of the ticks to come counts once per tick still to come, so it's only taken from a tick
	-- that settles and is sure to be one: it came with a log line as the only hit of its school that
	-- frame, no other hit of its school came in its window, none of your own spells was landing, and
	-- it wasn't a crit or a resist.
	local function Land(h, dot, owner, how, confirmed)
		local due, window = NextTick(dot)
		local u = { index = #dot.amounts + 1, till = due + window, at = now, seenAt = dot.seenAt, seenTick = dot.seenTick,
			by = h, owner = owner, crit = not issecretvalue(h.flag) and h.flag == "CRITICAL" }
		if confirmed and not dot.firstTick and NoFlag(h.flag) and not OwnHitNear(h.mob, now) then u.first = h.amount end
		fed[dot], h.used, h.booked, dot.unsure = true, true, dot, u
		dot.landed = dot.landed + 1
		dot.seenAt, dot.seenTick = now, dot.landed
		table.insert(dot.amounts, h.amount)
		if IsTarget(h.unit) then
			Trace(("tick: %s %d/%d by %s%s"):format(owner, dot.landed, TickCount(dot), how,
				NoFlag(h.flag) and "" or ", " .. h.flag))
		end
	end

	-- Whether a spell's ticks come with a log line depends on your combat log filter, and is learned
	-- from clean ticks: the frame's only hit, with no other DoT of its school on the mob due or just
	-- ticked around then (two DoTs of one school ticking together can't be told apart), and none of
	-- your own spells landing (Mind Flay's ticks have lines too). Two clean ticks in a row agreeing
	-- settle it, so one stray line can't. Kept between sessions (ns.db.dotLines[spellID]).
	if #hits == 1 then
		local h = hits[1]
		local only, count = nil, 0
		for _, dot in pairs(dots[h.mob]) do
			if dot.school == h.school and Remaining(dot, now) > 0
				and (math.abs(now - NextTick(dot)) <= CLEAN or dot.seenAt and now - dot.seenAt <= CLEAN) then
				only, count = dot, count + 1
			end
		end
		if count == 1 and only.mine and only.spellID and not OwnHitNear(h.mob, now) then
			local due, window = NextTick(only)
			if math.abs(now - due) <= window then
				local kind = lines > 0
				local was, streak = cleanEvidence[only.spellID], cleanStreak[only.spellID] or 0
				streak = was == kind and streak + 1 or 1
				cleanEvidence[only.spellID], cleanStreak[only.spellID] = kind, streak
				if streak >= 2 and ns.db.dotLines[only.spellID] ~= kind then
					ns.db.dotLines[only.spellID] = kind
					Trace(("learned: spell %d's ticks %s in your combat log"):format(only.spellID, kind and "show up" or "don't show up"))
				end
			end
		end
	end

	-- Hits with a line go to spells that need one, then to ones not known yet, then the rest; hits
	-- without one never to spells that need one. So a hit of the same school that isn't your tick (a
	-- groupmate's spell, a shadow wand) can't pass for one of a spell that shows up in your log.
	local function Logged(value) return function(dot) return Lines(dot) == value end end
	for _, h in ipairs(hits) do
		if lines > 0 then
			local how, confirmed = "school, timing and a log line", schoolHits[h.mob .. ":" .. h.school] == 1
			local dot, owner = Candidate(h, Logged(true))
			if not dot then
				how, confirmed = "school and timing (log not known yet)", false
				dot, owner = Candidate(h, Logged(nil))
			end
			if not dot then
				how = "school and timing"
				dot, owner = Candidate(h, Logged(false))
			end
			if dot then
				lines = lines - 1
				Land(h, dot, owner, how, confirmed)
			end
		end
	end
	for _, h in ipairs(hits) do
		if not h.used then
			local dot, owner = Candidate(h, function(d) return Lines(d) ~= true end)
			if dot then Land(h, dot, owner, Lines(dot) == false and "school and timing" or "school and timing (log not known yet)", false) end
		end
	end

	-- The bookings each hit came inside the window of (see Land).
	local function Doubt(dot, u, loud)
		if u.done then return end
		u.done = true
		if dot.unsure == u then dot.unsure = nil end
		dot.amounts[u.index] = TickSize(dot)
		if dot.seenAt == u.at then dot.seenAt, dot.seenTick = u.seenAt, u.seenTick end -- no tick seen since
		if loud then Trace(("tick: %s %d/%d booked at its estimated size instead"):format(u.owner, u.index, TickCount(dot))) end
		for _, prior in ipairs(u.after or {}) do Doubt(prior.dot, prior.u, loud) end
	end
	for _, h in ipairs(hits) do
		local inside = {}
		for _, dot in pairs(dots[h.mob]) do
			local u = dot.unsure
			if u and u.by ~= h and dot.school == h.school and now <= u.till then
				u.first = nil
				table.insert(inside, { dot = dot, u = u })
			end
		end
		local u = h.used and h.booked.unsure
		if u and u.by == h then
			u.after = inside
			if #inside > 0 then u.first = nil end
		elseif not h.used then
			for _, prior in ipairs(inside) do Doubt(prior.dot, prior.u, IsTarget(h.unit)) end
			if IsTarget(h.unit) then
				Trace(("other hit: school %d%s"):format(h.school, NoFlag(h.flag) and "" or ", " .. h.flag))
			end
		end
	end
	if pendingLines > 0 and traceFrom then Trace(("%d combat log line%s"):format(pendingLines, pendingLines > 1 and "s" or "")) end
end

local hits = CreateFrame("Frame")
hits:RegisterEvent("UNIT_COMBAT")
hits:RegisterEvent("UNIT_HEALTH")
pcall(hits.RegisterEvent, hits, "COMBAT_LOG_MESSAGE")
hits:SetScript("OnEvent", function(_, event, a, b, c, d, e)
	if event == "COMBAT_LOG_MESSAGE" then
		if not issecretvalue(e) and e == LIVE_LINE then pendingLines = pendingLines + 1 end
		return
	end
	if a ~= "target" and not plates[a] then return end
	if event == "UNIT_COMBAT" then
		-- a = unit, b = action, c = flag, d = amount (hidden), e = school
		if not issecretvalue(b) and not issecretvalue(e) and b == "WOUND" then
			table.insert(pendingHits, { unit = a, flag = c, amount = d, school = e })
		end
	end
	pendingPaint = true
end)
hits:SetScript("OnUpdate", function()
	if #pendingHits > 0 then
		local ok, err = pcall(MatchHits)
		if not ok then Report(err) end
	end
	wipe(pendingHits)
	pendingLines = 0
	if pendingPaint then
		pendingPaint = false
		RefreshNow()
	end
end)

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
	ns.Print(("Shadow Word: Death damage %d (0: not known)"):format(SwdDamage()))
	if lastError then ns.Print("Last overlay error: " .. lastError) end
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
	C_Timer.NewTicker(0.1, function() -- an error here would otherwise stop the overlay silently
		local ok, err = pcall(Refresh)
		if not ok then Report(err) end
	end)
	C_Timer.NewTicker(SYNC_EVERY, SyncThreat)
	-- Blizzard stops combat log lines whenever the Combat Log tab is hidden; the hit matching needs
	-- them (they still go only to that tab, as they would with it open).
	C_Timer.NewTicker(1, function()
		if ns.db.dotMarker and not C_CombatLog.AreFilteredEventsEnabled() then
			pcall(C_CombatLog.SetFilteredEventsEnabled, true)
		end
	end)
end)
