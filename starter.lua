local sharedPath = '@' .. Config.ResourceName .. '/config.lua'

local function InitializeFrameworkObjects(fwName)
    if fwName == Config.Frameworks[Exports.QBFrameWork].name and exports[Exports.QBFrameWork] then -- Check against actual fwName from Config.Frameworks
        QBCore = exports[Exports.QBFrameWork]:GetCoreObject()
        if QBCore then
            DebugPrint("^3QBCore Core Object initialized.", "INFO")
        else
            DebugPrint("Failed to initialize QBCore Core Object.", "ERROR")
        end
    elseif fwName == Config.Frameworks[Exports.ESXFrameWork].name and exports[Exports.ESXFrameWork] then
        ESX = exports[Exports.ESXFrameWork]:getSharedObject()
        if ESX then
            DebugPrint("^3ESX Shared Object initialized.", "INFO")
        else
            DebugPrint("Failed to initialize ESX Shared Object.", "ERROR")
        end
    elseif fwName == Config.Frameworks[Exports.OXCoreFrameWork].name and exports[Exports.OXCoreFrameWork] then
        -- Assuming ox_core might not have a single global object like QBCore/ESX
        -- but its presence is confirmed by isStarted. Utils.isStarted can be used by modules.
        DebugPrint("^3OX Core detected. Modules should use exports.ox_core directly or via Utils.isStarted.", "INFO")
    elseif fwName == Config.Frameworks[Exports.QBXFrameWork].name and exports[Exports.QBXFrameWork] then
        QBCore = exports[Exports.QBXFrameWork]:GetCoreObject() -- Or appropriate QBox way to get core
        if QBCore then -- Assuming QBox provides a similar GetCoreObject or it's handled like OX Core
            DebugPrint("^3QBox Core Object initialized.", "INFO")
        else
            DebugPrint("Failed to initialize QBox Core Object or uses direct exports.", "WARN")
        end
    elseif fwName == Config.Frameworks['standalone'].name then
        DebugPrint("Standalone mode initialized. Framework-specific objects (QBCore, ESX) will not be available.", "INFO")
    -- Add initializers for other frameworks like RSG Core here if needed
    end
end

local function DetectFramework()
    if Config.FrameworkOverride then
        if Config.Frameworks[Config.FrameworkOverride] then
            Config.Framework = Config.Frameworks[Config.FrameworkOverride].name -- Store the proper name
            DebugPrint(string.format("^3Framework Override: %s (%s)", Config.Framework, Config.FrameworkOverride), "INFO")
            InitializeFrameworkObjects(Config.Framework)
        else
            DebugPrint(string.format("Invalid FrameworkOverride: %s. Falling back to auto-detection.", Config.FrameworkOverride), "ERROR")
            Config.FrameworkOverride = nil -- Clear invalid override
        end
    end

    if not Config.Framework then -- Proceed with auto-detection if no valid override
        for fwKey, fwData in pairs(Config.Frameworks) do
            if fwKey ~= 'standalone' then
                local checkFunc = IsDuplicityVersion() and fwData.isServer or fwData.isClient
                if checkFunc and checkFunc() then
                    Config.Framework = fwData.name -- Store the proper name
                    DebugPrint(string.format("^3Auto-Detected Framework: %s (%s)", Config.Framework, fwKey), "INFO")
                    InitializeFrameworkObjects(Config.Framework)
                    break
                end
            end -- Closes if fwKey ~= 'standalone'
        end
    end

    if not Config.Framework then
        -- If no other framework detected, and standalone is allowed or forced, use it.
        if Config.FrameworkOverride == 'standalone' or not Config.FrameworkOverride then -- Allow standalone if no override or override is standalone
            Config.Framework = Config.Frameworks['standalone'].name
            DebugPrint(string.format("No specific framework detected/overridden. Using: %s", Config.Framework), "INFO")
            InitializeFrameworkObjects(Config.Framework)
        else
            DebugPrint("No compatible framework detected or overridden. Bridge may not function correctly.", "WARN")
        end
    end
end

local function DetermineSystem(systemNameSingular, systemNamePlural, overrideKey, autoDetectFunc, defaultValue)
    local actualSystemName = nil
    if Config[overrideKey] then
        actualSystemName = Config[overrideKey]
        DebugPrint(string.format("^3%s Override: %s^7", systemNameSingular, actualSystemName), "INFO")
    else
        actualSystemName = autoDetectFunc()
        if actualSystemName then
            DebugPrint(string.format("^3Auto-Detected %s: %s^7", systemNameSingular, actualSystemName), "INFO")
        else
            actualSystemName = defaultValue
            DebugPrint(string.format("No %s detected or overridden, defaulting to: %s", systemNameSingular, actualSystemName), "WARN")
        end
    end
    Config[systemNameSingular] = actualSystemName

    -- For target system, also update Config.DontUseTarget
    if systemNameSingular == 'Target' then
        Config.DontUseTarget = (actualSystemName == 'none') or Config.DontUseTarget
        if Config.DontUseTarget then
             DebugPrint("Target system is set to 'none' or DontUseTarget is true. Fallback DrawText3D will be used if enabled in targets.lua.", "INFO")
        end
    end
end

local function AutoDetectSystems()
    -- Menu System
    DetermineSystem('Menu', 'Menu Systems', 'MenuSystemOverride', function()
        if Utils.Helpers.isStarted(Exports.OXLib) then return 'ox' end
        if Utils.Helpers.isStarted(Exports.QBMenu) then return 'qb' end
        if Utils.Helpers.isStarted(Exports.WarMenu) then return 'gta' end -- GTA Native often uses warmenu
        -- ESX often relies on ox_lib or qb-menu for modern UIs, or its own basic menus
        if Config.Framework == Config.Frameworks[Exports.ESXFrameWork].name then return 'esx' end
        return 'gta' -- Default fallback
    end, 'gta')

    -- Notification System
    DetermineSystem('Notify', 'Notification Systems', 'NotifySystemOverride', function()
        if Utils.Helpers.isStarted(Exports.OXLib) then return 'ox' end
        if Utils.Helpers.isStarted(Exports.OkOkNotify) then return 'okok' end
        if Config.Framework == Config.Frameworks[Exports.QBFrameWork].name then return 'qb' end
        if Config.Framework == Config.Frameworks[Exports.ESXFrameWork].name then return 'esx' end
        return 'gta' -- Default fallback
    end, 'gta')

    -- Inventory System
    DetermineSystem('Inventory', 'Inventory Systems', 'InventorySystemOverride', function()
        if Utils.Helpers.isStarted(Exports.OXInv) then return Exports.OXInv end
        if Utils.Helpers.isStarted(Exports.QBInv) then return Exports.QBInv end
        if Utils.Helpers.isStarted(Exports.PSInv) then return Exports.PSInv end
        if Utils.Helpers.isStarted(Exports.QSInv) then return Exports.QSInv end
        if Utils.Helpers.isStarted(Exports.CoreInv) then return Exports.CoreInv end
        if Utils.Helpers.isStarted(Exports.CodeMInv) then return Exports.CodeMInv end
        if Utils.Helpers.isStarted(Exports.TgiannInv) then return Exports.TgiannInv end
        if Utils.Helpers.isStarted(Exports.ChezzaInv) then return Exports.ChezzaInv end
        if Config.Framework == Config.Frameworks[Exports.ESXFrameWork].name and Utils.Helpers.isStarted(Exports.OXInv) then return Exports.OXInv end -- ESX commonly uses ox_inventory
        return nil -- No clear default, dependent scripts must handle this
    end, nil)

    -- Progress Bar System
    DetermineSystem('ProgressBar', 'Progress Bar Systems', 'ProgressBarSystemOverride', function()
        if Utils.Helpers.isStarted(Exports.OXLib) then return 'ox' end
        -- qb-core has progressbar export, but often ox_lib is preferred if available
        if Config.Framework == Config.Frameworks[Exports.QBFrameWork].name and exports[Exports.QBFrameWork].ProgressBar then return 'qb' end
        if Config.Framework == Config.Frameworks[Exports.ESXFrameWork].name then return 'esx' end -- ESX might have its own or use ox_lib
        return 'gta' -- Fallback to a conceptual GTA-style progress (likely emulated)
    end, 'gta')

    -- DrawText System
    DetermineSystem('DrawText', 'DrawText Systems', 'DrawTextSystemOverride', function()
        if Utils.Helpers.isStarted(Exports.OXLib) then return 'ox' end
        if Config.Framework == Config.Frameworks[Exports.QBFrameWork].name then return 'qb' end
        if Config.Framework == Config.Frameworks[Exports.ESXFrameWork].name then return 'esx' end
        return 'gta' -- Default fallback
    end, 'gta')

    -- Skill Check System
    DetermineSystem('SkillCheck', 'Skill Check Systems', 'SkillCheckSystemOverride', function()
        if Utils.Helpers.isStarted(Exports.OXLib) then return 'ox' end -- OX Lib has skill checks
        -- QB might have qb-skillbar or similar, check specific export if known
        -- if Utils.Helpers.isStarted('qb-skillbar') then return 'qb-skillbar' end 
        return 'gta' -- Fallback (conceptual)
    end, 'gta')

    -- Target System
    DetermineSystem('Target', 'Target Systems', 'TargetSystemOverride', function()
        if Config.DontUseTarget then return 'none' end -- If DontUseTarget is true, force 'none'
        if Utils.Helpers.isStarted(Exports.OXTarget) then return Exports.OXTarget end
        if Utils.Helpers.isStarted(Exports.QBTarget) then return Exports.QBTarget end
        return 'none' -- Default to no specific target system, implies DrawText3D fallback in targets.lua
    end, 'none')
end

-- Initialize systems immediately when starter.lua is loaded
DetectFramework()
AutoDetectSystems()
TriggerEvent(Config.ResourceName .. ':systemsDetected') -- Notify that systems are detected (server to clients)
-- TriggerClientEvent(Config.ResourceName .. ':systemsDetected', -1) -- REMOVED: Not available in shared script context and was causing error.

DebugPrint(string.format("^3Initial effective framework: %s^7", Config.Framework or "None"), "INFO")
DebugPrint(string.format("^3Initial effective menu system: %s^7", Config.Menu or "None"), "INFO")
DebugPrint(string.format("^3Initial effective notify system: %s^7", Config.Notify or "None"), "INFO")
DebugPrint(string.format("^3Initial effective inventory system: %s^7", Config.Inventory or "None"), "INFO")
DebugPrint(string.format("^3Initial effective progress bar system: %s^7", Config.ProgressBar or "None"), "INFO")
DebugPrint(string.format("^3Initial effective draw text system: %s^7", Config.DrawText or "None"), "INFO")
DebugPrint(string.format("^3Initial effective skill check system: %s^7", Config.SkillCheck or "None"), "INFO")
DebugPrint(string.format("^3Initial effective target system: %s (DontUseTarget: %s)^7", Config.Target or "None", tostring(Config.DontUseTarget)), "INFO")


AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == Config.ResourceName then
        -- Systems are already detected at the top level of this script.
        -- We might re-trigger the event for late joiners or specific reloads if necessary,
        -- but primary detection is done.
        DebugPrint("Resource started. Systems were detected on initial load of starter.lua.", "INFO")
        -- Optionally, re-trigger events if needed for other scripts listening to this on a fresh start
        -- TriggerEvent(Config.ResourceName .. ':systemsDetected')
        -- TriggerClientEvent(Config.ResourceName .. ':systemsDetected', -1)
    end
end)

-- Commented out LoadSharedFiles function from previous steps
-- function LoadSharedFiles()
-- ... existing code ...
-- end


-- Ensure Config.Framework is set on resource restart/late start scenarios
-- This delayed check might still be useful for rare edge cases or if another resource 
-- modifies environment causing a need to re-detect. 
-- However, the primary detection now happens on script load.
Citizen.CreateThread(function()
    Citizen.Wait(5000) -- Increased wait time, ensure all other scripts had a chance to load
    local recheckNeeded = false
    if not Config.Framework then
        DebugPrint("Re-checking for framework after DELAYED check...")
        DetectFramework()
        if not Config.Framework then
             DebugPrint("No compatible framework detected after DELAYED check. Bridge functionality will be limited.", "WARN")
        else
            recheckNeeded = true
        end
    end
    if not Config.Menu then -- Also re-check other systems if not populated
        DebugPrint("Re-checking for other systems after DELAYED check...")
        if Utils.Helpers and Utils.Helpers.isStarted then -- Make sure helpers are loaded
            AutoDetectSystems()
            recheckNeeded = true
        else
            DebugPrint("Cannot re-check systems (DELAYED), Utils.Helpers not available. Shared files might not have loaded.", "ERROR")
        end
    end

    if recheckNeeded then
        DebugPrint("Re-triggering systemsDetected event after DELAYED check and re-detection.", "INFO")
        TriggerEvent(Config.ResourceName .. ':systemsDetected')
        TriggerClientEvent(Config.ResourceName .. ':systemsDetected', -1)
        
        DebugPrint(string.format("^3DELAYED Check - Effective framework: %s^7", Config.Framework or "None"), "INFO")
        DebugPrint(string.format("^3DELAYED Check - Effective menu system: %s^7", Config.Menu or "None"), "INFO")
        -- Add other system prints if necessary
    end
end) 