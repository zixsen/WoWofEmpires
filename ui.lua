-- Main window (/woe or the minimap button) and the minimap button.
local addonName, ns = ...

local ICON = "Interface\\Icons\\INV_Helmet_08"
local ROW_HEIGHT = 20

local window -- built on first open, after saved variables are loaded

local function SortedKeys(t)
	local keys = {}
	for key in pairs(t) do table.insert(keys, key) end
	table.sort(keys)
	return keys
end

local function CreateHeader(parent, x, y, text)
	local header = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	header:SetPoint("TOPLEFT", x, y)
	header:SetText(text)
end

------------------------------------------------------------------------
-- Sounds tab: one row per sound. Click plays it for the group, right-click mutes it.
------------------------------------------------------------------------
local function UpdateRow(row)
	local muted = ns.IsMuted(row.key)
	row.icon:SetAtlas(muted and "voicechat-icon-speaker-mute" or "voicechat-icon-speaker")
	row.trigger:SetFontObject(muted and GameFontDisable or GameFontNormal)
	row.label:SetFontObject(muted and GameFontDisable or GameFontHighlight)
end

local function CreateRow(parent, y, key)
	local row = CreateFrame("Button", nil, parent)
	row.key = key
	row:SetHeight(ROW_HEIGHT)
	row:SetPoint("TOPLEFT", 0, y)
	row:SetPoint("RIGHT")
	row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(14, 14)
	row.icon:SetPoint("LEFT", 6, 0)

	row.trigger = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	row.trigger:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
	row.trigger:SetWidth(84)
	row.trigger:SetJustifyH("LEFT")
	row.trigger:SetText(key)

	row.label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	row.label:SetPoint("LEFT", row.trigger, "RIGHT", 4, 0)
	row.label:SetPoint("RIGHT", -6, 0)
	row.label:SetJustifyH("LEFT")
	row.label:SetWordWrap(false)
	row.label:SetText(ns.LabelFor(ns.SoundFor(key)))

	row:SetScript("OnClick", function(self, button)
		if button == "RightButton" then
			ns.SetMuted(key, not ns.IsMuted(key))
			UpdateRow(self)
		elseif not ns.IsMuted(key) then
			ns.Broadcast(key)
		end
	end)
	UpdateRow(row)
end

local function BuildSoundsPage(page)
	local scroll = CreateFrame("ScrollFrame", nil, page, "ScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 4, -6)
	scroll:SetPoint("BOTTOMRIGHT", -26, 6)

	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(1, 1)
	scroll:SetScrollChild(content)
	scroll:HookScript("OnSizeChanged", function(_, width) content:SetWidth(width) end)

	local y = -6
	for _, section in ipairs({ { "Age of Empires taunts", ns.taunts }, { "Sound bites", ns.words } }) do
		CreateHeader(content, 8, y, section[1])
		y = y - 26
		for _, key in ipairs(SortedKeys(section[2])) do
			CreateRow(content, y, key)
			y = y - ROW_HEIGHT
		end
		y = y - 12
	end
	content:SetHeight(-y)
end

------------------------------------------------------------------------
-- Settings tab
------------------------------------------------------------------------
local function CreateCheckbox(parent, y, text, get, set)
	local box = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	box:SetSize(26, 26)
	box:SetPoint("TOPLEFT", 12, y)
	box.text:SetFontObject(GameFontHighlight)
	box.text:SetText(text)
	box:HookScript("OnShow", function(self) self:SetChecked(get()) end)
	box:HookScript("OnClick", function(self) set(self:GetChecked()) end)
end

local function SavedOption(key)
	return function() return ns.db[key] end, function(value) ns.db[key] = value end
end

local function BuildSettingsPage(page)
	CreateHeader(page, 16, -12, "Automation")
	CreateCheckbox(page, -36, "Sell grey items at vendors", SavedOption("vendorGrey"))
	CreateCheckbox(page, -62, "Repair gear at vendors", SavedOption("repair"))
	CreateCheckbox(page, -88, "Accept group invites from friends", SavedOption("autoInv"))
	CreateCheckbox(page, -114, "Show free bag slots on the backpack",
		function() return C_CVar.GetCVarBool("displayFreeBagSlots") end,
		function(on) C_CVar.SetCVar("displayFreeBagSlots", on and "1" or "0") end)

	CreateHeader(page, 16, -160, "Volume")
	local note = page:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	note:SetPoint("TOPLEFT", 16, -182)
	note:SetText("Sounds play on the game's Dialog channel.")

	local slider = CreateFrame("Frame", nil, page, "MinimalSliderWithSteppersTemplate")
	slider:SetPoint("TOPLEFT", 12, -198)
	slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
		C_CVar.SetCVar("Sound_DialogVolume", value)
	end, slider)

	local function Percent(value) return math.floor(value * 100 + 0.5) .. "%" end
	page:HookScript("OnShow", function()
		local volume = tonumber(C_CVar.GetCVar("Sound_DialogVolume")) or 1
		slider:Init(volume, 0, 1, 20, { [MinimalSliderWithSteppersMixin.Label.Right] = Percent })
	end)
end

------------------------------------------------------------------------
-- Party tab
------------------------------------------------------------------------
local function BuildPartyPage(page)
	CreateHeader(page, 16, -12, "Your group")

	local list = page:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	list:SetPoint("TOPLEFT", 16, -40)
	list:SetJustifyH("LEFT")
	list:SetSpacing(4)

	local hint = page:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	hint:SetPoint("BOTTOMLEFT", 16, 12)
	hint:SetPoint("BOTTOMRIGHT", -16, 12)
	hint:SetJustifyH("LEFT")
	hint:SetText("Scroll the mouse wheel over your portrait or a party member's portrait to give it a custom picture.")

	local function Refresh()
		local lines = {}
		for i = 1, GetNumSubgroupMembers() do
			local name = UnitName("party" .. i)
			if name and not issecretvalue(name) then
				local portrait = ns.db.friendPortraits[name]
				if portrait and portrait > 0 then
					name = name .. "  |cff888888portrait " .. portrait .. "|r"
				end
				table.insert(lines, name)
			end
		end
		list:SetText(#lines > 0 and table.concat(lines, "\n") or "|cff888888You're not in a group.|r")
	end

	page:SetScript("OnShow", Refresh)
	ns.On("GROUP_ROSTER_UPDATE", function()
		if page:IsVisible() then Refresh() end
	end)
end

------------------------------------------------------------------------
-- Window
------------------------------------------------------------------------
local TABS = {
	{ "Sounds", BuildSoundsPage },
	{ "Settings", BuildSettingsPage },
	{ "Party", BuildPartyPage },
}

local function SelectTab(index)
	PanelTemplates_SetTab(window, index)
	for i, page in ipairs(window.pages) do
		page:SetShown(i == index)
	end
end

local function CreateWindow()
	window = CreateFrame("Frame", "WoWofEmpiresFrame", UIParent, "ButtonFrameTemplate")
	window:Hide()
	window:SetSize(360, 500)
	window:SetPoint("CENTER")
	window:SetToplevel(true)
	window:SetClampedToScreen(true)
	window:SetMovable(true)
	window:EnableMouse(true)
	window:RegisterForDrag("LeftButton")
	window:SetScript("OnDragStart", window.StartMoving)
	window:SetScript("OnDragStop", window.StopMovingOrSizing)
	window:HookScript("OnShow", function() PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN) end)
	window:HookScript("OnHide", function() PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE) end)
	window:SetTitle("WoW of Empires")
	window:SetPortraitToAsset(ICON)
	tinsert(UISpecialFrames, window:GetName()) -- Escape closes it

	window.pages = {}
	for i, tab in ipairs(TABS) do
		local page = CreateFrame("Frame", nil, window.Inset)
		page:SetAllPoints()
		tab[2](page)
		window.pages[i] = page

		local button = CreateFrame("Button", nil, window, "PanelTabButtonTemplate")
		button:SetText(tab[1])
		if i == 1 then
			button:SetPoint("TOPLEFT", window, "BOTTOMLEFT", 12, 2)
		else
			button:SetPoint("TOPLEFT", window.Tabs[i - 1], "TOPRIGHT", 3, 0)
		end
		button:SetScript("OnClick", function()
			PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
			SelectTab(i)
		end)
	end
	PanelTemplates_SetNumTabs(window, #TABS)

	local stop = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
	stop:SetSize(110, 22)
	stop:SetPoint("BOTTOMRIGHT", -6, 3)
	stop:SetText("Stop sounds")
	stop:SetScript("OnClick", ns.StopRecentSounds)

	local hint = window:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	hint:SetPoint("BOTTOMLEFT", 12, 9)
	hint:SetText("Click: play for your group.  Right-click: mute.")

	SelectTab(1)
end

function ns.ToggleWindow()
	if not window then CreateWindow() end
	window:SetShown(not window:IsShown())
end

-- /woe opens the window. /woe levelup [level] fakes a level-up through the real level-up code
-- (Snoop for you, the announcement for everyone else with the addon), for testing.
SLASH_WOWOFEMPIRES1 = "/woe"
SlashCmdList.WOWOFEMPIRES = function(msg)
	local level = msg:match("^levelup%s*(%d*)$")
	if level then
		ns.Fire("PLAYER_LEVEL_UP", tonumber(level) or UnitLevel("player") + 1)
	else
		ns.ToggleWindow()
	end
end

------------------------------------------------------------------------
-- Minimap button: click opens, right-click stops sounds, drag moves it around the minimap.
------------------------------------------------------------------------
local function PlaceOnMinimap(button)
	local angle = math.rad(ns.db.minimapAngle)
	local radius = Minimap:GetWidth() / 2 + 10
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function FollowCursor(button)
	local centerX, centerY = Minimap:GetCenter()
	local cursorX, cursorY = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale()
	ns.db.minimapAngle = math.deg(math.atan2(cursorY / scale - centerY, cursorX / scale - centerX))
	PlaceOnMinimap(button)
end

local function CreateMinimapButton()
	local button = CreateFrame("Button", "WoWofEmpiresMinimapButton", Minimap)
	button:SetSize(31, 31)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(8)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")
	button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	local background = button:CreateTexture(nil, "BACKGROUND")
	background:SetSize(20, 20)
	background:SetPoint("TOPLEFT", 7, -5)
	background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetSize(17, 17)
	icon:SetPoint("TOPLEFT", 7, -6)
	icon:SetTexture(ICON)
	icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)

	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetSize(53, 53)
	border:SetPoint("TOPLEFT")
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

	button:SetScript("OnClick", function(_, mouseButton)
		if mouseButton == "RightButton" then
			ns.StopRecentSounds()
		else
			ns.ToggleWindow()
		end
	end)
	button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", FollowCursor) end)
	button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip_SetTitle(GameTooltip, "WoW of Empires")
		GameTooltip:AddLine("Click to open, right-click to stop sounds.", 1, 1, 1)
		GameTooltip:AddLine("Drag to move. /woe also opens it.", 0.6, 0.6, 0.6)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", GameTooltip_Hide)

	PlaceOnMinimap(button)
end

ns.On("PLAYER_LOGIN", CreateMinimapButton)
