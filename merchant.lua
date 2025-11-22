local ADDON_NAME, WoWofEmpires = ...
WoWofEmpires = WoWofEmpires or {}
WoWofEmpires.Merchant = WoWofEmpires.Merchant or {}

local merchantFrame = CreateFrame("Frame")
merchantFrame:RegisterEvent("MERCHANT_SHOW")
merchantFrame:SetScript("OnEvent", function()
    if WoWofEmpiresDB.vendorGrey == true then
        local totPrice = 0
        local totItems = 0
        for b = 0, 4 do
            for s = 0, C_Container.GetContainerNumSlots(b) do
                local ilink = C_Container.GetContainerItemInfo(b, s)
                if ilink ~= nil then
                    local _, _, qual, _, _, _, _, _, _, _, price = GetItemInfo(ilink.hyperlink)
                    if qual == 0 then
                        C_Container.UseContainerItem(b, s)
                        totPrice = totPrice + (price * ilink.stackCount)
                        totItems = totItems + (1 * ilink.stackCount)
                    end
                end
            end
        end
        if totPrice > 0 then
            print("Sold " .. totItems .. "x item(s) for: " .. GetCoinTextureString(totPrice))
        end
    end
    
    if WoWofEmpiresDB.repair and CanMerchantRepair() then
        local repairAllCost, canRepair = GetRepairAllCost()
        if canRepair then
            RepairAllItems()
            print("Repaired all items for: " .. GetCoinTextureString(repairAllCost))
        end
    end
end)
