-- Unlock Window / Lock Window for the main chat window, like before Edit Mode took it over. With the
-- option on, the General tab's menu gets Unlock Window; unlocked, dragging the General tab moves the
-- window and the corner button resizes it, until you lock it (or enter Edit Mode).
--
-- Where you put it is saved by the addon, not in your Edit Mode layout: Edit Mode's own functions are
-- never called (from an addon they would taint Edit Mode, and with it the action bars). Instead the
-- spot is put back whenever Edit Mode places the window. Moving or resizing the window in Edit Mode
-- drops the spot, so Edit Mode's place counts again.
local addonName, ns = ...

ns.defaults.chatLock = false
-- ns.db.chatSpot = { left, bottom, width, height }: where you put the main chat window

local chat = ChatFrame1
if not (chat and chat.ApplySystemAnchor) then return end -- no Edit Mode: Blizzard's own Lock Window is there

local unlocked = false

-- Edit Mode replaced the window's SetPoint/ClearAllPoints with its own; the originals are kept as *Base.
-- Not while Edit Mode is open: there the window is Edit Mode's to move.
local function Place()
	local spot = ns.db and ns.db.chatLock and ns.db.chatSpot
	if not spot or EditModeManagerFrame:IsEditModeActive() then return end
	chat:ClearAllPointsBase()
	chat:SetPointBase("BOTTOMLEFT", UIParent, "BOTTOMLEFT", spot[1], spot[2])
	chat:SetSize(spot[3], spot[4])
end

local function Save()
	ns.db.chatSpot = { chat:GetLeft(), chat:GetBottom(), chat:GetWidth(), chat:GetHeight() }
	Place()
end

-- Blizzard hides the main window's resize button (FCF_UpdateResizeButton); shown again while unlocked.
local function ShowResize()
	chat.ResizeButton:SetShown(unlocked and not chat.isUninteractable)
	FCF_UpdateScrollbarAnchors(chat)
end

function ns.ResetChatLock()
	unlocked = false
	ns.db.chatSpot = nil -- Edit Mode's place again from the next reload
	ShowResize()
end

-- After the whole of UpdateSystem: in the middle of it Edit Mode reads the window's spot back, and
-- would take ours into its layout as an unsaved change.
hooksecurefunc(chat, "UpdateSystem", Place)
ns.On("PLAYER_ENTERING_WORLD", Place)

local function Forget() ns.db.chatSpot = nil end
hooksecurefunc(chat, "OnDragStop", Forget)
hooksecurefunc(chat, "EditMode_OnResized", Forget)
hooksecurefunc(chat, "ResetToDefaultPosition", Forget)
-- ponytail: Edit Mode's width/height sliders don't drop the spot; its size comes back on exit.

EventRegistry:RegisterCallback("EditMode.Enter", function()
	unlocked = false
	ShowResize()
end, ns)
EventRegistry:RegisterCallback("EditMode.Exit", Place, ns)

hooksecurefunc("FCF_UpdateResizeButton", function(frame)
	if frame == chat then ShowResize() end
end)

-- Blizzard's tab drag does nothing for the main window; the move is added after it.
local moving = false
ChatFrame1Tab:HookScript("OnDragStart", function()
	if not unlocked then return end
	moving = true
	chat:SetMovable(true) -- Edit Mode turns this off when it's done with the window
	chat:StartMoving()
end)
local function Stop()
	if not moving then return end
	moving = false
	chat:StopMovingOrSizing()
	Save()
end
ChatFrame1Tab:HookScript("OnDragStop", Stop)
ChatFrame1Tab:HookScript("OnMouseUp", Stop)
chat.ResizeButton:HookScript("OnMouseUp", function()
	if unlocked then Save() end
end)

Menu.ModifyMenu("MENU_FCF_TAB", function(owner, root)
	if not ns.db.chatLock or owner:GetID() ~= 1 or EditModeManagerFrame:IsEditModeActive() then return end
	root:Insert(MenuUtil.CreateButton(unlocked and LOCK_WINDOW or UNLOCK_WINDOW, function()
		unlocked = not unlocked
		ShowResize()
	end), 1)
end)
