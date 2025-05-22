--[[
    Notifications Module
    ----------------------
    This module provides a unified interface for displaying notifications using various
    notification systems. The active system is determined by Config.Notify setting (not Config.System.Notify).

    Supported systems include:
      • okok
      • qb (uses QBCore framework functions, can also leverage ox_lib via QBClient.Notify)
      • ox (uses ox_lib directly)
      • gta (default)
      • esx (uses ESX framework functions)
]]

--- Displays notifications to the player using the configured notification system.
---
--- Supports multiple notification systems based on Config.Notify. Can be triggered from both
--- client and server contexts.
---
--- @param title string|nil The notification title (optional for some systems).
--- @param message string The main message content.
--- @param type string The notification type ("success", "error", "info", "warning", "primary", "cancel" etc.).
--- @param src number|nil Optional server ID; if provided, the notification is sent to that player.
--- @param duration number|nil Optional duration for the notification (some systems use a default).
function triggerNotify(title, message, type, src, duration)
    local fwNameQB = Config.Frameworks[Exports.QBFrameWork].name
    local fwNameESX = Config.Frameworks[Exports.ESXFrameWork].name

    if Config.Notify == "okok" then
        if not Utils.Helpers.isStarted(Exports.OkOkNotify) then DebugPrint("OkOkNotify not started.", "WARN"); return end
        if not src then
            TriggerEvent(Exports.OkOkNotify..':Alert', title, message, duration or 6000, type)
        else
            TriggerClientEvent(Exports.OkOkNotify..':Alert', src, title, message, duration or 6000, type)
        end
    elseif Config.Notify == "qb" then
        if not QBCore and not FrameworkFuncs[fwNameQB] then DebugPrint("QBCore or its FrameworkFuncs not available for Notify.", "ERROR"); return end
        if not src then -- Client-side for self
            if FrameworkFuncs[fwNameQB] and FrameworkFuncs[fwNameQB].Client and FrameworkFuncs[fwNameQB].Client.Notify then
                -- QBClient.Notify in framework file handles if ox_lib should be used based on Config.Notify being 'ox' or actual QBCore.Functions.Notify
                FrameworkFuncs[fwNameQB].Client.Notify(message, type, Config.Notify, duration) -- Pass Config.Notify to allow internal logic for ox_lib
            else
                DebugPrint("QBCore Client.Notify FrameworkFunc not found. Falling back to event.", "WARN")
                TriggerEvent("QBCore:Notify", message, type, duration)
            end
        else -- Server-side or client-to-client via server
            if FrameworkFuncs[fwNameQB] and FrameworkFuncs[fwNameQB].Server and FrameworkFuncs[fwNameQB].Server.NotifyPlayer then
                FrameworkFuncs[fwNameQB].Server.NotifyPlayer(src, message, type, duration)
            else
                DebugPrint("QBCore Server.NotifyPlayer FrameworkFunc not found. Falling back to event.", "WARN")
                TriggerClientEvent("QBCore:Notify", src, message, type, duration)
            end
        end
    elseif Config.Notify == "ox" then
        if not Utils.Helpers.isStarted(Exports.OXLib) then DebugPrint("ox_lib not started for Notify.", "ERROR"); return end
        local oxType = type
        if type == "cancel" then oxType = "error" end -- Map 'cancel' to 'error' for ox_lib
        -- Ensure other types are mapped or passed directly if valid for ox_lib
        if oxType ~= "error" and oxType ~= "success" and oxType ~= "warning" and oxType ~= "info" and oxType ~= "primary" then
            oxType = "inform" -- A general default for ox_lib if type is not standard
        end

        local notifData = { title = title, description = message, type = oxType }
        if duration then notifData.duration = duration end

        if not src then
            exports[Exports.OXLib]:notify(notifData)
        else
            -- For sending to a specific player with ox_lib when on the server,
            -- ox_lib usually requires this to be done from the server context directly.
            -- If this triggerNotify is called server-side with a `src`, this is fine.
            -- If called client-side with a `src`, it should ideally go through a server event
            -- that then calls exports[Exports.OXLib]:notify on the server with the target player.
            -- For now, assuming direct TriggerClientEvent if on server, or relies on server event if called client-side with src.
            -- A robust bridge might have Bridge.NotifyPlayer(src, ...) that handles this dispatch.
            TriggerClientEvent(Config.ResourceName .. ':ExternalPlayerNotify', src, Config.Notify, {notifData=notifData})
            -- exports[Exports.OXLib]:notify(notifData, src) -- This is if ox_lib supports a src/id directly in its server-side notify
        end
    elseif Config.Notify == "gta" then
        -- Assuming "jim-gtaui" is a custom NUI solution preferred over natives
        if Utils.Helpers.isStarted("jim-gtaui") then -- This should be a Config entry if it's a common alternative
            if not src then
                TriggerEvent("jim-gtaui:Notify", title, message, type, duration)
            else
                TriggerClientEvent("jim-gtaui:Notify", src, title, message, type, duration)
            end
        else -- Fallback to native GTA notifications / existing DisplayGTANotify event
            if not src then
                TriggerEvent(Config.ResourceName..":DisplayGTANotify", title, message, type, duration)
            else
                TriggerClientEvent(Config.ResourceName..":DisplayGTANotify", src, title, message, type, duration)
            end
        end
    elseif Config.Notify == "esx" then
        if not ESX and not FrameworkFuncs[fwNameESX] then DebugPrint("ESX or its FrameworkFuncs not available for Notify.", "ERROR"); return end
        if not src then -- Client-side for self
            if FrameworkFuncs[fwNameESX] and FrameworkFuncs[fwNameESX].Client and FrameworkFuncs[fwNameESX].Client.ShowNotification then
                FrameworkFuncs[fwNameESX].Client.ShowNotification(message, type, duration)
            else
                DebugPrint("ESX Client.ShowNotification FrameworkFunc not found. Falling back to export.", "WARN")
                if exports[Exports.ESXFrameWork] and exports[Exports.ESXFrameWork].ShowNotification then
                    exports[Exports.ESXFrameWork]:ShowNotification(message, type, duration)
                else
                    DebugPrint("ESX direct export ShowNotification not found.", "ERROR")
                end
            end
        else -- Server-side or client-to-client via server
            if FrameworkFuncs[fwNameESX] and FrameworkFuncs[fwNameESX].Server and FrameworkFuncs[fwNameESX].Server.ShowNotificationToPlayer then
                FrameworkFuncs[fwNameESX].Server.ShowNotificationToPlayer(src, message, type, duration)
            else
                DebugPrint("ESX Server.ShowNotificationToPlayer FrameworkFunc not found. Falling back to event.", "WARN")
                TriggerClientEvent(Config.ResourceName .. ':DisplayESXNotify', src, type, message, duration)
            end
        end
    elseif Config.Notify == "red" then -- RedM specific (Placeholder)
        if Utils.Helpers.isStarted("jim-redui") then -- This should be a Config entry
            if not src then
                TriggerEvent("jim-redui:Notify", title, message, type, duration)
            else
                TriggerClientEvent("jim-redui:Notify", src, title, message, type, duration)
            end
        else
            DebugPrint("jim-redui not started for RedM notifications.", "WARN")
        end
    else
        DebugPrint("Unknown Config.Notify system: " .. tostring(Config.Notify or "nil"), "WARN")
    end
end

-------------------------------------------------------------
-- Client-Side Event Handlers for Targeted Notifications
-------------------------------------------------------------

-- This event is for ox_lib when a server-side (or other client) call needs to show a notification to this specific client
RegisterNetEvent(Config.ResourceName .. ':ExternalPlayerNotify', function(system, data)
    if system == "ox" and Utils.Helpers.isStarted(Exports.OXLib) then
        exports[Exports.OXLib]:notify(data.notifData)
    end
    -- Can extend for other systems if needed
end)


-- ESX Notifications: Client event to display notification, called by server-side ShowNotificationToPlayer
RegisterNetEvent(Config.ResourceName..":DisplayESXNotify", function(type, text, duration)
    local fwNameESX = Config.Frameworks[Exports.ESXFrameWork].name
    if FrameworkFuncs[fwNameESX] and FrameworkFuncs[fwNameESX].Client and FrameworkFuncs[fwNameESX].Client.ShowNotification then
        FrameworkFuncs[fwNameESX].Client.ShowNotification(text, type, duration)
    elseif exports[Exports.ESXFrameWork] and exports[Exports.ESXFrameWork].ShowNotification then
        exports[Exports.ESXFrameWork]:ShowNotification(text, type, duration)
    elseif exports["esx_notify"] and exports["esx_notify"].Notify then -- Fallback to older direct export if available
         exports["esx_notify"]:Notify(type, duration or 4000, text)
    else
        DebugPrint("ESX notification system (Client.ShowNotification, direct export, or esx_notify) not found for DisplayESXNotify.", "ERROR")
    end
end)

-- GTA-style Notifications: Client event to display native GTA notification
RegisterNetEvent(Config.ResourceName..":DisplayGTANotify", function(title, text, type, duration) -- Added type and duration for potential use
    -- The iconTable logic might need to be adapted if `Loc` is not available here or if icons depend on type
    local icon = "CHAR_DEFAULT" -- Default icon
    -- Example: if type == "error" then icon = "CHAR_BLOCKED" end 
    -- Example: if title and iconTable and iconTable[title] then icon = iconTable[title] end

    -- Native GTA notifications don't have a type param in EndTextCommandThefeedPostMessagetext directly
    -- Type could be used to change icon or message prefix if desired.
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(text) -- Using SubstringPlayerName as it's common, can be SubstringKeyboardDisplay
    EndTextCommandThefeedPostMessagetext(icon, icon, true, 1, title or "", "", duration or 5000) -- Using duration if provided
    EndTextCommandThefeedPostTicker(false, true) -- Second param to true to make it appear instantly
end)

DebugPrint("shared/notify.lua loaded and refactored for FrameworkFuncs")