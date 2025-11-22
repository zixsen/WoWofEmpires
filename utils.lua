local ADDON_NAME, WoWofEmpires = ...
WoWofEmpires = WoWofEmpires or {}
WoWofEmpires.Utils = WoWofEmpires.Utils or {}

function WoWofEmpires.Utils.spairs(t, order)
    local keys = {}
    for k in pairs(t) do
        keys[#keys+1] = k
    end
    
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end
    
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function WoWofEmpires.Utils.tContain(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function WoWofEmpires.Utils.IsFriend(name)
    for i = 1, C_FriendList.GetNumFriends() do
        local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
        if friendInfo.name == name then
            return true
        end
    end
    return false
end

function WoWofEmpires.Utils.IsBnetFriend(name)
    for i = 1, BNGetNumFriends() do
        local friendInfo = select(5, BNGetFriendInfo(i))
        if friendInfo == name then
            return true
        end
    end
    return false
end

function WoWofEmpires.Utils.inPublicParty()
    local partyRoster = GetHomePartyInfo()
    if not partyRoster or #partyRoster == 0 then
        return false
    end
    for i = 1, #partyRoster do
        if not WoWofEmpires.Config.TEH_SQUAD[partyRoster[i]] then
            return true
        end
    end
    return false
end
