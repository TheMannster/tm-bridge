--- Returns the server-side functions for the detected framework.
local function GetFrameworkServer()
    if Config.Framework and FrameworkFuncs[Config.Framework] and FrameworkFuncs[Config.Framework].Server then
        return FrameworkFuncs[Config.Framework].Server
    end
    DebugPrint("Server framework functions not available for " .. (Config.Framework or "unknown framework"), "ERROR")
    return {}
end

--- Gets a player object by source.
--- @param src number The player's server ID.
--- @return table Player object.
function Bridge.GetPlayer(src)
    local fwServer = GetFrameworkServer()
    if fwServer.GetPlayer then
        return fwServer.GetPlayer(src)
    end
    DebugPrint("Bridge.GetPlayer not implemented for current framework", "WARN")
    return nil
end

--- Gets all connected players.
--- @return table A list of player objects.
function Bridge.GetPlayers()
    local fwServer = GetFrameworkServer()
    if fwServer.GetPlayers then
        return fwServer.GetPlayers()
    end
    DebugPrint("Bridge.GetPlayers not implemented for current framework", "WARN")
    return {}
end

--- Adds money to a player.
--- @param src number The player's server ID.
--- @param type string The type of money (e.g., "bank", "cash").
--- @param amount number The amount to add.
--- @return boolean True on success, false otherwise.
function Bridge.AddMoney(src, type, amount)
    local fwServer = GetFrameworkServer()
    if fwServer.AddMoney then
        return fwServer.AddMoney(src, type, amount)
    end
    DebugPrint("Bridge.AddMoney not implemented for current framework", "WARN")
    return false
end

--- Removes money from a player.
--- @param src number The player's server ID.
--- @param type string The type of money.
--- @param amount number The amount to remove.
--- @return boolean True on success, false otherwise.
function Bridge.RemoveMoney(src, type, amount)
    local fwServer = GetFrameworkServer()
    if fwServer.RemoveMoney then
        return fwServer.RemoveMoney(src, type, amount)
    end
    DebugPrint("Bridge.RemoveMoney not implemented for current framework", "WARN")
    return false
end

--- Gets a player's money.
--- @param src number The player's server ID.
--- @param type string The type of money.
--- @return number The amount of money, or 0 if not found.
function Bridge.GetMoney(src, type)
    local fwServer = GetFrameworkServer()
    if fwServer.GetMoney then
        return fwServer.GetMoney(src, type)
    end
    DebugPrint("Bridge.GetMoney not implemented for current framework", "WARN")
    return 0
end

--- Checks if a player has a required item.
--- @param item string The name of the item.
--- @param src number The player's server ID.
--- @return boolean True if the player has the item, false otherwise.
function Bridge.HasRequiredItem(item, src)
    local fwServer = GetFrameworkServer()
    if fwServer.HasRequiredItem then
        return fwServer.HasRequiredItem(item, src)
    end
    DebugPrint("Bridge.HasRequiredItem not implemented for current framework", "WARN")
    return false
end

-- Exported functions for other resources to use
exports('GetPlayer', Bridge.GetPlayer)
exports('GetPlayers', Bridge.GetPlayers)
exports('AddMoney', Bridge.AddMoney)
exports('RemoveMoney', Bridge.RemoveMoney)
exports('GetMoney', Bridge.GetMoney)
exports('HasRequiredItem', Bridge.HasRequiredItem)

DebugPrint("Server Bridge API initialized.") 