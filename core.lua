local ADDON_NAME, WoWofEmpires = ...
WoWofEmpires = WoWofEmpires or {}

local Config = WoWofEmpires.Config or {}
local Utils = WoWofEmpires.Utils or {}

local defaults = {
    disabledList = {},
    vendorGrey = false,
    repair = false,
    autoInv = false,
    Bagspace = false,
}

local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        WoWofEmpires.Initialize()
    end
end)

function WoWofEmpires.Initialize()
    WoWofEmpiresDB = WoWofEmpiresDB or {}
    for k, v in pairs(defaults) do
        if WoWofEmpiresDB[k] == nil then
            if type(v) == "table" then
                WoWofEmpiresDB[k] = CopyTable(v)
            else
                WoWofEmpiresDB[k] = v
            end
        end
    end
    
    WoWofEmpires.UI.CreateMainFrame()
    WoWofEmpires.UI.CreateMinimapButton()
    WoWofEmpires.UI.CreateBagSearch()
end

WoWofEmpires.UI = {}

function WoWofEmpires.UI.SetMinimapButtonState(isOpen)
    local button = WoWofEmpires.UI.minimapButton
    if not button then
        return
    end
    local texture
    if isOpen then
        texture = "Interface/COMMON/Indicator-Green.png"
    else
        texture = "Interface/COMMON/Indicator-Yellow.png"
    end
    button:SetNormalTexture(texture)
    button:SetPushedTexture(texture)
    button:SetHighlightTexture(texture)
end

function WoWofEmpires.UI.CreateMinimapButton()
    local minibtn = CreateFrame("Button", nil, Minimap)
    minibtn:SetFrameLevel(8)
    minibtn:SetSize(32, 32)
    minibtn:SetMovable(true)
    
    minibtn:SetNormalTexture("Interface/COMMON/Indicator-Yellow.png")
    minibtn:SetPushedTexture("Interface/COMMON/Indicator-Yellow.png")
    minibtn:SetHighlightTexture("Interface/COMMON/Indicator-Yellow.png")
    
    local myIconPos = 0
    
    local function UpdateMapBtn()
        local Xpoa, Ypoa = GetCursorPosition()
        local Xmin, Ymin = Minimap:GetLeft(), Minimap:GetBottom()
        Xpoa = Xmin - Xpoa / Minimap:GetEffectiveScale() + 70
        Ypoa = Ypoa / Minimap:GetEffectiveScale() - Ymin - 70
        myIconPos = math.deg(math.atan2(Ypoa, Xpoa))
        minibtn:ClearAllPoints()
        minibtn:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 52 - (80 * cos(myIconPos)), (80 * sin(myIconPos)) - 52)
    end
    
    minibtn:RegisterForDrag("LeftButton")
    minibtn:SetScript("OnDragStart", function()
        minibtn:StartMoving()
        minibtn:SetScript("OnUpdate", UpdateMapBtn)
    end)
    
    minibtn:RegisterForClicks("AnyUp")
    minibtn:SetScript("OnDragStop", function()
        minibtn:StopMovingOrSizing()
        minibtn:SetScript("OnUpdate", nil)
        UpdateMapBtn()
    end)
    
    minibtn:ClearAllPoints()
    minibtn:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 52 - (80 * cos(myIconPos)), (80 * sin(myIconPos)) - 52)
    
    minibtn:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            WoWofEmpires.UI.ToggleMainFrame()
        elseif button == "RightButton" then
            WoWofEmpires.Chat.StopLastSounds()
        end
    end)
    
    WoWofEmpires.UI.minimapButton = minibtn
end

function WoWofEmpires.UI.CreateMainFrame()
    local msgFrame = CreateFrame("FRAME", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
    local backdropInfo = {
        bgFile = "Interface\\QuestFrame\\QuestBG",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileEdge = true,
        tileSize = 550,
        edgeSize = 8,
        insets = {left = 1, right = 1, top = 1, bottom = 1},
    }
    
    msgFrame:SetWidth(350)
    msgFrame:SetHeight(400)
    msgFrame:SetBackdrop(backdropInfo)
    msgFrame:SetBackdropColor(255/255, 240/255, 179/255, 0.7)
    msgFrame:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)
    msgFrame:SetMovable(true)
    msgFrame:EnableMouse(true)
    msgFrame:SetToplevel(true)
    msgFrame:SetClampedToScreen(true)
    msgFrame:SetPoint("CENTER")
    msgFrame:SetFrameStrata("TOOLTIP")
    
    msgFrame.close = CreateFrame("Button", nil, msgFrame, "UIPanelCloseButton")
    msgFrame.close:SetPoint("TOPRIGHT", 5, 25)
    msgFrame.close:SetScript("OnClick", function(self, button, down)
        msgFrame:Hide()
    end)
    msgFrame.close:EnableKeyboard(true)
    msgFrame.close:SetScript("OnKeyDown", function(self, button, down)
        if button == "ESCAPE" then
            msgFrame.close:SetPropagateKeyboardInput(false)
            msgFrame:Hide()
        else
            msgFrame.close:SetPropagateKeyboardInput(true)
        end
    end)
    
    local animFrame = CreateFrame("Frame")
    local ONUPDATE_INTERVAL = 0.05
    local TimeSinceLastUpdate = 0
    animFrame:SetScript("OnUpdate", function(self, elapsed)
        TimeSinceLastUpdate = TimeSinceLastUpdate + elapsed
        if TimeSinceLastUpdate >= ONUPDATE_INTERVAL then
            if msgFrame:IsVisible() then
                if msgFrame:GetWidth() < 350 then
                    msgFrame:SetWidth(TimeSinceLastUpdate * 1000)
                else
                    msgFrame:SetWidth(350)
                end
                if msgFrame:GetHeight() < 400 then
                    msgFrame:SetHeight(TimeSinceLastUpdate * 1000)
                else
                    msgFrame:SetHeight(400)
                end
            end
        end
    end)
    
    msgFrame:SetScript("OnShow", function(self)
        TimeSinceLastUpdate = 0
        msgFrame:SetWidth(1)
        msgFrame:SetHeight(1)
        WoWofEmpires.UI.SetMinimapButtonState(true)
    end)
    msgFrame:SetScript("OnHide", function()
        WoWofEmpires.UI.SetMinimapButtonState(false)
    end)
    
    msgFrame:Hide()
    
    local title = msgFrame:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("WoWofEmpires")
    
    WoWofEmpires.UI.CreateTabs(msgFrame)
    WoWofEmpires.UI.CreateVolumeSlider(msgFrame)
    WoWofEmpires.UI.mainFrame = msgFrame
end

function WoWofEmpires.UI.CreateTabs(msgFrame)
    local scrollFrame = CreateFrame("ScrollFrame", nil, msgFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 3, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -27, 44)
    
    local scrollFrame2 = CreateFrame("ScrollFrame", nil, msgFrame, "UIPanelScrollFrameTemplate")
    scrollFrame2:SetPoint("TOPLEFT", 3, -30)
    scrollFrame2:SetPoint("BOTTOMRIGHT", -27, 44)
    scrollFrame2:Hide()
    
    local scrollFrame3 = CreateFrame("ScrollFrame", nil, msgFrame, "UIPanelScrollFrameTemplate")
    scrollFrame3:SetPoint("TOPLEFT", 3, -30)
    scrollFrame3:SetPoint("BOTTOMRIGHT", -27, 44)
    scrollFrame3:Hide()
    
    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetWidth(msgFrame:GetWidth() - 18)
    scrollChild:SetHeight(1)
    
    local scrollChild2 = CreateFrame("Frame")
    scrollFrame2:SetScrollChild(scrollChild2)
    scrollChild2:SetWidth(msgFrame:GetWidth() - 18)
    scrollChild2:SetHeight(1)
    
    local scrollChild3 = CreateFrame("Frame")
    scrollFrame3:SetScrollChild(scrollChild3)
    scrollChild3:SetWidth(msgFrame:GetWidth() - 18)
    scrollChild3:SetHeight(1)
    
    WoWofEmpires.UI.CreateSoundList(scrollChild)
    WoWofEmpires.UI.CreateQoLOptions(scrollChild2)
    WoWofEmpires.UI.CreatePartyList(scrollChild3)
    
    local header1 = CreateFrame("BUTTON", nil, msgFrame, "TabButtonTemplate")
    header1:SetPoint("TOPLEFT", 0, 33)
    header1:SetText("Main")
    PanelTemplates_TabResize(header1, 0, 75)
    header1:SetScript("OnClick", function(self, button)
        scrollFrame:Show()
        scrollFrame2:Hide()
        scrollFrame3:Hide()
    end)
    
    local header2 = CreateFrame("BUTTON", nil, msgFrame, "TabButtonTemplate")
    header2:SetPoint("TOPLEFT", 75, 33)
    header2:SetText("QoL")
    PanelTemplates_TabResize(header2, 0, 75)
    header2:SetScript("OnClick", function(self, button)
        scrollFrame:Hide()
        scrollFrame3:Hide()
        scrollFrame2:Show()
    end)
    
    local header3 = CreateFrame("BUTTON", nil, msgFrame, "TabButtonTemplate")
    header3:SetPoint("TOPLEFT", 150, 33)
    header3:SetText("Party")
    PanelTemplates_TabResize(header3, 0, 75)
    header3:SetScript("OnClick", function(self, button)
        scrollFrame2:Hide()
        scrollFrame:Hide()
        scrollFrame3:Show()
    end)
end

function WoWofEmpires.UI.BuildDisplayList()
    local displayList = {}
    local displayList2 = {}
    
    for k, v in WoWofEmpires.Utils.spairs(WoWofEmpires.Config.IntToSound) do
        table.insert(displayList, {id = k, str = v})
    end
    
    table.insert(displayList, {id = "", str = ""})
    
    for k, v in pairs(WoWofEmpires.Config.StringToSound) do
        table.insert(displayList2, {id = k, str = v})
    end
    
    local patterns = {"%.ogg", "%.mp3"}
    for i = 1, #displayList do
        for p = 1, #patterns do
            displayList[i].str = displayList[i].str:gsub(patterns[p], "")
        end
        displayList[i].str = displayList[i].str:gsub("_", " ")
        displayList[i].str = displayList[i].str:gsub("-", " ")
    end
    
    for i = 1, #displayList2 do
        for p = 1, #patterns do
            displayList2[i].str = displayList2[i].str:gsub(patterns[p], "")
        end
        displayList2[i].str = displayList2[i].str:gsub("_", " ")
        displayList2[i].str = displayList2[i].str:gsub("-", " ")
    end
    
    table.sort(displayList2, function(a, b) return tostring(a.id) < tostring(b.id) end)
    
    return displayList, displayList2
end

function WoWofEmpires.UI.CreateSoundButton(scrollChild, displayItem, i, offset)
    offset = offset or 0
    
    if displayItem.id == "" then return end
    
    local playbtn = CreateFrame("Button", nil, scrollChild)
    if WoWofEmpiresDB.disabledList[displayItem.id] ~= true then
        playbtn:SetNormalTexture("Interface/COMMON/Indicator-Yellow.png")
        playbtn:SetPushedTexture("Interface/COMMON/Indicator-Yellow.png")
        playbtn:SetHighlightTexture("Interface/COMMON/Indicator-Yellow.png")
    else
        playbtn:SetNormalTexture("Interface/COMMON/Indicator-Red.png")
        playbtn:SetPushedTexture("Interface/COMMON/Indicator-Red.png")
        playbtn:SetHighlightTexture("Interface/COMMON/Indicator-Red.png")
    end
    
    playbtn:RegisterForClicks("AnyUp")
    playbtn:SetPoint("LEFT")
    playbtn:SetSize(14, 14)
    playbtn:SetPoint("TOPLEFT", 0, 0 - ((i + offset) * 10))
    
    playbtn:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            if WoWofEmpiresDB.disabledList[displayItem.id] ~= true then
                WoWofEmpiresDB.disabledList[displayItem.id] = true
                playbtn:SetNormalTexture("Interface/COMMON/Indicator-Red.png")
                playbtn:SetPushedTexture("Interface/COMMON/Indicator-Red.png")
                playbtn:SetHighlightTexture("Interface/COMMON/Indicator-Red.png")
            else
                WoWofEmpiresDB.disabledList[displayItem.id] = nil
                playbtn:SetNormalTexture("Interface/COMMON/Indicator-Yellow.png")
                playbtn:SetPushedTexture("Interface/COMMON/Indicator-Yellow.png")
                playbtn:SetHighlightTexture("Interface/COMMON/Indicator-Yellow.png")
            end
        else
            if WoWofEmpiresDB.disabledList[displayItem.id] ~= true then
                local chatCommand = type(displayItem.id) == "string" and displayItem.id or tostring(displayItem.id)
                if UnitInParty("player") then
                    SendChatMessage(chatCommand, "PARTY")
                else
                    SendChatMessage(chatCommand, "SAY")
                end
            end
        end
    end)
    
    local body = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormalSmall")
    body:SetPoint("TOP", 0, 0)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetTextColor(1, 1, 1, 1)
    body:SetText("[" .. displayItem.id .. "] - " .. displayItem.str)
    body:SetPoint("TOPLEFT", 18, 0 - ((i + offset) * 10))
    body:SetPoint("TOPRIGHT", -12, -25 - ((i + offset) * 10))
end

function WoWofEmpires.UI.CreateSoundList(scrollChild)
    if WoWofEmpires.UI.listPopulated then return end
    
    local displayList, displayList2 = WoWofEmpires.UI.BuildDisplayList()
    
    for i = 1, #displayList do
        WoWofEmpires.UI.CreateSoundButton(scrollChild, displayList[i], i, 0)
    end
    
    local displayList2startPoint = #displayList
    for i = 1, #displayList2 do
        WoWofEmpires.UI.CreateSoundButton(scrollChild, displayList2[i], i, displayList2startPoint)
    end
    
    WoWofEmpires.UI.listPopulated = true
end

function WoWofEmpires.UI.CreateQoLOptions(scrollChild2)
    local cbVendorGrey = CreateFrame("CheckButton", "vendorgrey_CBname", scrollChild2, "ChatConfigCheckButtonTemplate")
    cbVendorGrey:SetSize(20, 20)
    cbVendorGrey:SetPoint("TOPLEFT")
    vendorgrey_CBnameText:SetText("Auto vendor greys")
    cbVendorGrey:SetScript("OnClick", function()
        WoWofEmpiresDB.vendorGrey = cbVendorGrey:GetChecked()
    end)
    cbVendorGrey:SetChecked(WoWofEmpiresDB.vendorGrey)
    
    local cbRepair = CreateFrame("CheckButton", "repair_CBname", scrollChild2, "ChatConfigCheckButtonTemplate")
    cbRepair:SetSize(20, 20)
    cbRepair:SetPoint("TOPLEFT", 0, -16 * 1)
    repair_CBnameText:SetText("Auto repair")
    cbRepair:SetScript("OnClick", function()
        WoWofEmpiresDB.repair = cbRepair:GetChecked()
    end)
    cbRepair:SetChecked(WoWofEmpiresDB.repair)
    
    local cbAutoInv = CreateFrame("CheckButton", "autoinv_CBname", scrollChild2, "ChatConfigCheckButtonTemplate")
    cbAutoInv:SetSize(20, 20)
    cbAutoInv:SetPoint("TOPLEFT", 0, -16 * 2)
    autoinv_CBnameText:SetText("Auto-Accept group (from friends)")
    cbAutoInv:SetScript("OnClick", function()
        WoWofEmpiresDB.autoInv = cbAutoInv:GetChecked()
    end)
    cbAutoInv:SetChecked(WoWofEmpiresDB.autoInv)
    
    WoWofEmpires.UI.CreateBagspaceOption(scrollChild2)
end

function WoWofEmpires.UI.CreateBagspaceOption(scrollChild2)
    local bagspaceframe = CreateFrame("Frame")
    bagspaceframe:SetFrameStrata("TOOLTIP")
    local bagspacetext = bagspaceframe:CreateFontString("OVERLAY", nil, "GameFontNormal")
    bagspacetext:SetShadowColor(0, 0, 0, 1)
    bagspacetext:SetShadowOffset(2, -2)
    bagspacetext:SetScale(1.2)
    bagspacetext:SetPoint("CENTER", MainMenuBarBackpackButton, 0, -3)
    
    local function UpdateBagspaceDisplay()
        local bgspace = 0
        for i = 0, 4 do
            local numberOfFreeSlots, bagType = C_Container.GetContainerNumFreeSlots(i)
            local bagName = C_Container.GetBagName(i)
            if bagName ~= nil and not (bagName:find("Soul") or bagName:find("Felcloth")) then
                bgspace = bgspace + numberOfFreeSlots
            end
        end
        if bgspace <= 3 then
            bagspacetext:SetTextColor(1, 0, 0, 1)
        else
            bagspacetext:SetTextColor(1, 1, 1, 1)
        end
        bagspacetext:SetText("[" .. bgspace .. "]")
        if WoWofEmpiresDB ~= nil and WoWofEmpiresDB.Bagspace then
            bagspacetext:Show()
        else
            bagspacetext:Hide()
        end
    end
    
    local bagUpdateFrame = CreateFrame("Frame")
    bagUpdateFrame:RegisterEvent("BAG_UPDATE")
    bagUpdateFrame:SetScript("OnEvent", UpdateBagspaceDisplay)
    UpdateBagspaceDisplay()
    
    local cbBagspace = CreateFrame("CheckButton", "Bagspace_CBname", scrollChild2, "ChatConfigCheckButtonTemplate")
    cbBagspace:SetSize(20, 20)
    cbBagspace:SetPoint("TOPLEFT", 0, -16 * 3)
    Bagspace_CBnameText:SetText("Show bagspace on first bag.")
    cbBagspace:SetScript("OnClick", function()
        WoWofEmpiresDB.Bagspace = cbBagspace:GetChecked()
        UpdateBagspaceDisplay()
    end)
    cbBagspace:SetChecked(WoWofEmpiresDB.Bagspace)
end

function WoWofEmpires.UI.CreatePartyList(scrollChild3)
    local myparty = GetHomePartyInfo()
    if myparty ~= nil then
        for i = 1, #myparty do
            local body3 = scrollChild3:CreateFontString("ARTWORK", nil, "GameFontNormalSmall")
            body3:SetPoint("TOPLEFT", 15, 1 - i * 10)
            body3:SetJustifyH("LEFT")
            body3:SetJustifyV("TOP")
            body3:SetTextColor(1, 1, 1, 1)
            body3:SetText(myparty[i])
        end
    end
end

function WoWofEmpires.UI.CreateVolumeSlider(msgFrame)
    local footer = msgFrame:CreateFontString("ARTWORK", nil, "GameFontNormal")
    footer:SetPoint("BOTTOMLEFT", 5, 22)
    footer:SetText("Volume:")
    
    local footer2 = msgFrame:CreateFontString("ARTWORK", nil, "GameFontNormal")
    footer2:SetPoint("BOTTOMRIGHT", -7, 7)
    footer2:SetText("Right-click minimap\nbutton to stop\nlast sounds.")
    
    local slider1 = CreateFrame("Slider", nil, msgFrame, "OptionsSliderTemplate")
    local footerwidth = footer:GetStringWidth()
    slider1:SetPoint("BOTTOMLEFT", footerwidth + 15, 18)
    slider1:SetMinMaxValues(0, 1)
    local VolumeValue = tonumber(GetCVar("Sound_DialogVolume"))
    slider1:SetValue(VolumeValue)
    slider1:SetValueStep(0.01)
    slider1:SetObeyStepOnDrag(true)
    slider1:SetScript("OnValueChanged", function(self, value, userInput)
        tonumber(SetCVar("Sound_DialogVolume", value))
    end)
end

function WoWofEmpires.UI.ToggleMainFrame()
    local msgFrame = WoWofEmpires.UI.mainFrame
    if msgFrame:IsVisible() then
        msgFrame:Hide()
    else
        msgFrame:Show()
    end
end

function WoWofEmpires.UI.CreateBagSearch()
    local editFrame = CreateFrame("EditBox", nil, ContainerFrame1, "BagSearchBoxTemplate")
    editFrame:SetPoint("TOP", ContainerFrame1, "TOP")
    editFrame:SetWidth(126)
    editFrame:SetHeight(18)
    editFrame:SetMaxLetters(15)
    
    hooksecurefunc("ContainerFrame_Update", function(self)
        if self:GetID() == 0 then
            editFrame:SetParent(self)
            editFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 55, -29)
            editFrame.anchorBag = self
            editFrame:Show()
        elseif editFrame.anchorBag == self then
            editFrame:ClearAllPoints()
            editFrame:Hide()
            editFrame.anchorBag = nil
        end
    end)
end
