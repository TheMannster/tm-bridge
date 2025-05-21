if Config.Framework ~= 'qbox' then return end

FrameworkFuncs['qbox'] = FrameworkFuncs['qbox'] or {}
FrameworkFuncs['qbox'].Server = {}

local QBoxServer = {}

--- QBox: Get player by source
function QBoxServer.GetPlayer(src)
    if not exports.qbx_core then DebugPrint("qbx_core not found in qbox_server.GetPlayer", "ERROR"); return nil end
    return exports.qbx_core:GetPlayer(src)
end

--- QBox: Get all players
function QBoxServer.GetPlayers()
    return GetPlayers() -- Use native FiveM function
end

--- QBox: Add money to player
function QBoxServer.AddMoney(src, type, amount)
    if not exports.qbx_core then DebugPrint("qbx_core not found in qbox_server.AddMoney", "ERROR"); return false end
    local Player = QBoxServer.GetPlayer(src)
    if Player and Player.Functions and Player.Functions.AddMoney then
        return Player.Functions.AddMoney(type, amount)
    end
    DebugPrint("Failed to add money for player " .. src .. " in QBox.", "WARN")
    return false
end

--- QBox: Remove money from player
function QBoxServer.RemoveMoney(src, type, amount)
    if not exports.qbx_core then DebugPrint("qbx_core not found in qbox_server.RemoveMoney", "ERROR"); return false end
    local Player = QBoxServer.GetPlayer(src)
    if Player and Player.Functions and Player.Functions.RemoveMoney then
        return Player.Functions.RemoveMoney(type, amount)
    end
    DebugPrint("Failed to remove money for player " .. src .. " in QBox.", "WARN")
    return false
end

--- QBox: Get player money
function QBoxServer.GetMoney(src, type)
    if not exports.qbx_core then DebugPrint("qbx_core not found in qbox_server.GetMoney", "ERROR"); return 0 end
    local Player = QBoxServer.GetPlayer(src)
    if Player and Player.PlayerData and Player.PlayerData.money and Player.PlayerData.money[type] then
        return Player.PlayerData.money[type]
    end
    return 0
end

--- QBox: Check if player has an item (server-side)
function QBoxServer.HasRequiredItem(item, src)
    if not exports.qbx_core then DebugPrint("qbx_core not found in qbox_server.HasRequiredItem", "ERROR"); return false end
    local Player = QBoxServer.GetPlayer(src)
    if Player and Player.PlayerData and Player.PlayerData.items then
        for _, v in pairs(Player.PlayerData.items) do
            if v and v.name == item and v.count and v.count > 0 then
                return true
            end
        end
    end
    return false
end

-- Callback for client-side HasRequiredItem
if exports.ox_lib and exports.ox_lib.RegisterServerCallback then
    exports.ox_lib:RegisterServerCallback(Config.ResourceName .. ':HasRequiredItem', function(source, item)
        return QBoxServer.HasRequiredItem(item, source)
    end)
    DebugPrint("QBox HasRequiredItem callback registered using ox_lib.")
else
    DebugPrint("ox_lib not found for QBox HasRequiredItem server callback. Client-side item check might not work as expected.", "WARN")
    -- Fallback: If QBCore exists and QBCore style callbacks are expected (as seen in original script), provide that.
    -- This part is a bit tricky because the original qbox_server.lua had a QBCore.Functions.CreateCallback.
    -- If that specific behavior is needed for some TM Scripts, it needs careful consideration.
    -- For a pure QBox bridge, this might not be necessary if ox_lib or a similar QBox-native callback system is preferred.
    if QBCore and QBCore.Functions.CreateCallback then
        QBCore.Functions.CreateCallback(Config.ResourceName .. ':HasRequiredItemQBox', function(source, cb, item) -- Note the old name
            local hasItem = QBoxServer.HasRequiredItem(item, source)
            cb(hasItem)
        end)
        DebugPrint("Registered tm-bridge:HasRequiredItemQBox callback via QBCore.Functions.CreateCallback as a fallback.", "INFO")
    end
end

FrameworkFuncs['qbox'].Server = QBoxServer
DebugPrint("QBox Server Functions Initialized.") 