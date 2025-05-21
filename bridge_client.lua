--- Returns the client-side functions for the detected framework.
local function GetFrameworkClient()
    if Config.Framework and FrameworkFuncs[Config.Framework] and FrameworkFuncs[Config.Framework].Client then
        return FrameworkFuncs[Config.Framework].Client
    end
    DebugPrint("Client framework functions not available for " .. (Config.Framework or "unknown framework"), "ERROR")
    return {}
end

--- Sends a notification to the player.
--- @param msg string The message to display.
--- @param type string The type of notification (e.g., "error", "success", "inform").
--- @param notificationType string (Optional) Specific notification system like "ox".
function Bridge.Notify(msg, type, notificationType)
    local fwClient = GetFrameworkClient()
    if fwClient.Notify then
        return fwClient.Notify(msg, type, notificationType)
    end
    -- Fallback or error if not implemented by framework
    DebugPrint("Bridge.Notify not implemented for current framework", "WARN")
end

--- Gets the player's data.
--- @return table Player data.
function Bridge.GetPlayer()
    local fwClient = GetFrameworkClient()
    if fwClient.GetPlayer then
        return fwClient.GetPlayer()
    end
    DebugPrint("Bridge.GetPlayer not implemented for current framework", "WARN")
    return nil
end

--- Checks if the player has a required item.
--- For QBox, this will make a server call if not handled client-side.
--- @param item string The name of the item.
--- @return boolean True if the player has the item, false otherwise.
function Bridge.HasRequiredItem(item)
    local fwClient = GetFrameworkClient()
    if fwClient.HasRequiredItem then
        return fwClient.HasRequiredItem(item)
    end
    DebugPrint("Bridge.HasRequiredItem not implemented for current framework", "WARN")
    return false
end

-- Exported functions for other resources to use
exports('Notify', Bridge.Notify)
exports('GetPlayer', Bridge.GetPlayer)
exports('HasRequiredItem', Bridge.HasRequiredItem)

DebugPrint("Client Bridge API initialized.") 