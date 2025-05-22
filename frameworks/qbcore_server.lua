if Config.Framework ~= Config.Frameworks[Exports.QBFrameWork].name then return end -- Changed for consistency

-- Initialize QBCore object if it hasn't been by starter.lua yet
if not QBCore then
    if exports[Exports.QBFrameWork] then
        QBCore = exports[Exports.QBFrameWork]:GetCoreObject()
        DebugPrint("QBCore Core Object re-initialized in qbcore_server.lua.")
    else
        DebugPrint("QBCore ('" .. Exports.QBFrameWork .. "') not available in qbcore_server.lua.", "ERROR")
        return
    end
end

FrameworkFuncs[Config.Frameworks[Exports.QBFrameWork].name] = FrameworkFuncs[Config.Frameworks[Exports.QBFrameWork].name] or {}
FrameworkFuncs[Config.Frameworks[Exports.QBFrameWork].name].Server = {}

local QBServer = {}

--- QBCore: Get player by source
function QBServer.GetPlayer(src)
    if Config.System and Config.System.ServerDebugMode then
        print(string.format("--- QBServer.GetPlayer DEBUG --- Attempting to get player for source: %s", tostring(src)))
        print(string.format("--- QBServer.GetPlayer DEBUG --- QBCore object type: %s", type(QBCore)))
        if QBCore and QBCore.Functions then
            print(string.format("--- QBServer.GetPlayer DEBUG --- QBCore.Functions.GetPlayer type: %s", type(QBCore.Functions.GetPlayer)))
        else
            print("--- QBServer.GetPlayer DEBUG --- QBCore.Functions is nil or QBCore is nil")
        end
    end
    if not QBCore then 
        if Config.System and Config.System.ServerDebugMode then
            print("--- QBServer.GetPlayer ERROR --- QBCore object is not initialized!")
        end
        DebugPrint("QBCore not initialized in qbcore_server.GetPlayer", "ERROR"); 
        return nil 
    end
    if not QBCore.Functions or not QBCore.Functions.GetPlayer then
        if Config.System and Config.System.ServerDebugMode then
            print("--- QBServer.GetPlayer ERROR --- QBCore.Functions.GetPlayer is not available!")
        end
        return nil
    end
    local playerObject = QBCore.Functions.GetPlayer(src)
    if Config.System and Config.System.ServerDebugMode then
        print(string.format("--- QBServer.GetPlayer DEBUG --- QBCore.Functions.GetPlayer(%s) returned object of type: %s", tostring(src), type(playerObject)))
        if playerObject == nil then
            print(string.format("--- QBServer.GetPlayer WARN --- QBCore.Functions.GetPlayer(%s) returned nil.", tostring(src)))
        end
    end
    return playerObject
end

--- QBCore: Get all players table (keys are server IDs)
function QBServer.GetPlayers()
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_server.GetPlayers", "ERROR"); return {} end
    return QBCore.Functions.GetPlayers()
end

--- QBCore: Get player table by specific criteria (e.g., job, gang)
--- @param key string: The key to search for (e.g., "job", "gang")
--- @param value string: The value to match
--- @return table: A table of player objects matching the criteria
function QBServer.GetPlayersBy(key, value)
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_server.GetPlayersBy", "ERROR"); return {} end
    return QBCore.Functions.GetPlayers(key, value) -- QBCore.Functions.GetPlayers can take args to filter
end

--- QBCore: Add money to player
function QBServer.AddMoney(src, type, amount, reason)
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_server.AddMoney", "ERROR"); return false end
    local Player = QBServer.GetPlayer(src)
    if Player then
        return Player.Functions.AddMoney(type, amount, reason)
    end
    return false
end

--- QBCore: Remove money from player
function QBServer.RemoveMoney(src, type, amount, reason)
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_server.RemoveMoney", "ERROR"); return false end
    local Player = QBServer.GetPlayer(src)
    if Player then
        return Player.Functions.RemoveMoney(type, amount, reason)
    end
    return false
end

--- QBCore: Set player's money for a specific account type
function QBServer.SetMoney(src, type, amount, reason)
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_server.SetMoney", "ERROR"); return false end
    local Player = QBServer.GetPlayer(src)
    if Player then
        return Player.Functions.SetMoney(type, amount, reason)
    end
    return false
end

--- QBCore: Get player money
function QBServer.GetMoney(src, type)
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_server.GetMoney", "ERROR"); return 0 end
    local Player = QBServer.GetPlayer(src)
    if Player then
        if Player.PlayerData.money[type] ~= nil then
            return Player.PlayerData.money[type]
        else
            DebugPrint(string.format("QBServer.GetMoney: Money type '%s' not found for player %s.", type, src), "WARN")
            return 0
        end
    end
    return 0
end

--- QBCore: Check if player has an item (server-side)
function QBServer.HasItem(src, item, amount) -- Renamed from HasRequiredItem for consistency and added amount
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_server.HasItem", "ERROR"); return false end
    local Player = QBServer.GetPlayer(src)
    if Player and Player.Functions.HasItem then
        return Player.Functions.HasItem(item, amount) -- amount is optional in QBCore's HasItem, defaults to 1
    end
    return false
end

--- QBCore: Add item to player's inventory
function QBServer.AddItem(src, item, amount, slot, info, ignoreWeight)
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_server.AddItem", "ERROR"); return false end
    local Player = QBServer.GetPlayer(src)
    if Player then
        return Player.Functions.AddItem(item, amount, slot, info, ignoreWeight) -- ignoreWeight added as some versions support it
    end
    return false
end

--- QBCore: Remove item from player's inventory
function QBServer.RemoveItem(src, item, amount, slot)
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_server.RemoveItem", "ERROR"); return false end
    local Player = QBServer.GetPlayer(src)
    if Player then
        return Player.Functions.RemoveItem(item, amount, slot)
    end
    return false
end

--- QBCore: Get Player Job Information
function QBServer.GetJob(src)
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_server.GetJob", "ERROR"); return nil end
    local Player = QBServer.GetPlayer(src)
    if Player then
        return Player.PlayerData.job
    end
    return nil
end

--- QBCore: Set Player Job
function QBServer.SetJob(src, job, grade)
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_server.SetJob", "ERROR"); return false end
    local Player = QBServer.GetPlayer(src)
    if Player then
        Player.Functions.SetJob(job, grade)
        return true
    end
    return false
end

--- QBCore: Get Player Gang Information
function QBServer.GetGang(src)
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_server.GetGang", "ERROR"); return nil end
    local Player = QBServer.GetPlayer(src)
    if Player then
        return Player.PlayerData.gang
    end
    return nil
end

--- QBCore: Set Player Gang
function QBServer.SetGang(src, gang, grade)
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_server.SetGang", "ERROR"); return false end
    local Player = QBServer.GetPlayer(src)
    if Player then
        Player.Functions.SetGang(gang, grade)
        return true
    end
    return false
end

--- QBCore: Get Player Identifier (e.g., license, steam, discord, ip)
function QBServer.GetIdentifier(src, type)
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_server.GetIdentifier", "ERROR"); return nil end
    local Player = QBServer.GetPlayer(src)
    if Player then
        if type == 'license' then return Player.PlayerData.license end
        -- For other identifiers, QBCore might store them in PlayerData.identifiers or need specific function calls
        -- This is a basic version; more complex identifier retrieval might be needed.
        -- local identifiers = QBCore.Functions.GetPlayerIdentifiers(src) or Player.PlayerData.identifiers
        -- if identifiers and identifiers[type] then return identifiers[type] end
        if Player.PlayerData[type] then return Player.PlayerData[type] end -- common for citizenid
        DebugPrint(string.format("QBServer.GetIdentifier: Identifier type '%s' not directly found for player %s. May need specific QBCore logic.", type, src), "WARN")
    end
    return nil
end

--- QBCore: Register Server Callback (wrapper around existing createCallback or QBCore specific)
--- Note: tm-bridge/shared/callback.lua already provides createCallback that handles QBCore.
--- This is a direct wrapper for consistency if preferred.
function QBServer.RegisterServerCallback(name, cb)
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_server.RegisterServerCallback", "ERROR"); return end
    QBCore.Functions.CreateCallback(name, function(source, callback, ...)
        local result = cb(source, ...)
        callback(result)
    end)
end

--- QBCore: Player logging (if QBCore has a specific logging system to tap into)
function QBServer.Log(source, logName, title, color, message)
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_server.Log", "ERROR"); return end
    -- This is a placeholder. QBCore logging often involves triggering an event or using a specific function.
    -- Example: TriggerEvent('qb-logs:server:CreateLog', logName, title, color, message, source) or similar.
    -- Consult your QBCore logging script for the correct method.
    DebugPrint(string.format("[QBCore Log Placeholder] Source: %s, Log: %s, Title: %s, Message: %s", source, logName, title, message), "INFO")
    -- A generic server print as a fallback:
    print(string.format("LOG [%s] Player %s: %s - %s", logName, source, title, message))
end

--- QBCore: Open Shop (Server-side)
-- This function is used when an inventory system like qb-inventory needs a server-side trigger to open a shop.
function QBServer.OpenShop(source, shopData)
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_server.OpenShop", "ERROR"); return end
    local Player = QBServer.GetPlayer(source)
    if not Player then DebugPrint("QBServer.OpenShop: Player not found: " .. tostring(source), "ERROR"); return end

    if Config.Inventory == Exports.QBInv and exports[Exports.QBInv] and exports[Exports.QBInv].OpenShop then
        -- The actual arguments for OpenShop can vary based on the qb-inventory version or other inventory scripts.
        -- This is a common pattern. `shopData` might contain `name`, `label`, `items`, `slots` etc.
        -- It is assumed that shopData is the `shop` identifier/name used in `RegisterShop` or the full table as expected by the inventory.
        exports[Exports.QBInv]:OpenShop(source, shopData) 
        DebugPrint(string.format("QBServer.OpenShop: Called exports.%s:OpenShop for player %s, shop data: %s", Exports.QBInv, source, shopData), "INFO")
    elseif Config.Inventory == Exports.PSInv and exports[Exports.PSInv] and exports[Exports.PSInv].OpenShop then
         exports[Exports.PSInv]:OpenShop(source, shopData)
         DebugPrint(string.format("QBServer.OpenShop: Called exports.%s:OpenShop for player %s, shop data: %s", Exports.PSInv, source, shopData), "INFO")
    -- Add other qb-like inventory systems here if they have a similar server-side OpenShop export
    else
        DebugPrint(string.format("QBServer.OpenShop: No compatible QBCore inventory system (QBInv, PSInv) with OpenShop export found or Config.Inventory ('%s') mismatch for player %s.", Config.Inventory or 'nil', source), "WARN")
    end
end

--- QBCore: Register Shop (Server-side)
function QBServer.RegisterShop(name, label, items, society)
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_server.RegisterShop", "ERROR"); return end

    local shopConfig = {
        name = name,
        label = label,
        slots = #items + 20, -- Example: item count + buffer, adjust as needed
        items = items,       -- These are the items the shop SELLS
        society = society    -- Optional: for society-managed shops
    }

    if Config.Inventory == Exports.QBInv and exports[Exports.QBInv] and exports[Exports.QBInv].CreateShop then
        exports[Exports.QBInv]:CreateShop(shopConfig)
        DebugPrint(string.format("QBServer.RegisterShop: Registered shop \'%s\' with %s.", name, Exports.QBInv))
    elseif Config.Inventory == Exports.PSInv and exports[Exports.PSInv] and exports[Exports.PSInv].CreateShop then
        exports[Exports.PSInv]:CreateShop(shopConfig)
        DebugPrint(string.format("QBServer.RegisterShop: Registered shop \'%s\' with %s.", name, Exports.PSInv))
    -- Add other qb-like inventory systems here if they have a similar CreateShop export
    else
        DebugPrint(string.format("QBServer.RegisterShop: No compatible QBCore inventory system (QBInv, PSInv) with CreateShop export found or Config.Inventory ('%s') mismatch for shop \'%s\'.", Config.Inventory or 'nil', name), "WARN")
    end
end

--- QBCore: Send notification to a specific player
function QBServer.NotifyPlayer(src, message, type, duration)
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_server.NotifyPlayer", "ERROR"); return end
    -- QBCore typically handles client notifications by triggering a client event.
    -- The client-side QBCore:Notify event is usually sufficient.
    -- If direct player object notification is needed and available:
    -- local Player = QBServer.GetPlayer(src)
    -- if Player then Player.Functions.Notify(message, type, duration) end
    -- However, more commonly, you trigger the client event that the client listens to.
    TriggerClientEvent("QBCore:Notify", src, message, type, duration)
    DebugPrint(string.format("QBServer.NotifyPlayer: Sent to %s - Msg: %s, Type: %s", src, message, type))
end

FrameworkFuncs[Config.Frameworks[Exports.QBFrameWork].name].Server = QBServer
DebugPrint("QBCore Server Functions Initialized.") 