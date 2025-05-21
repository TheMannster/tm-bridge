local sharedPath = '@' .. Config.ResourceName .. '/config.lua'

local function InitializeFrameworkObjects(fwName)
    if fwName == Config.Frameworks[Exports.QBFrameWork].name and exports[Exports.QBFrameWork] then -- Check against actual fwName from Config.Frameworks
        QBCore = exports[Exports.QBFrameWork]:GetCoreObject()
        if QBCore then
            DebugPrint("QBCore Core Object initialized.")
        else
            DebugPrint("Failed to initialize QBCore Core Object.", "ERROR")
        end
    elseif fwName == Config.Frameworks[Exports.ESXFrameWork].name and exports[Exports.ESXFrameWork] then
        ESX = exports[Exports.ESXFrameWork]:getSharedObject()
        if ESX then
            DebugPrint("ESX Shared Object initialized.")
        else
            DebugPrint("Failed to initialize ESX Shared Object.", "ERROR")
        end
    elseif fwName == Config.Frameworks[Exports.OXCoreFrameWork].name and exports[Exports.OXCoreFrameWork] then
        -- Assuming ox_core might not have a single global object like QBCore/ESX
        -- but its presence is confirmed by isStarted. Utils.isStarted can be used by modules.
        DebugPrint("OX Core detected. Modules should use exports.ox_core directly or via Utils.isStarted.")
    elseif fwName == Config.Frameworks[Exports.QBXFrameWork].name and exports[Exports.QBXFrameWork] then
        QBCore = exports[Exports.QBXFrameWork]:GetCoreObject() -- Or appropriate QBox way to get core
        if QBCore then -- Assuming QBox provides a similar GetCoreObject or it's handled like OX Core
            DebugPrint("QBox Core Object initialized.")
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
            DebugPrint(string.format("Framework Override: %s (%s)", Config.Framework, Config.FrameworkOverride))
            InitializeFrameworkObjects(Config.Framework)
        else
            DebugPrint(string.format("Invalid FrameworkOverride: %s. Falling back to auto-detection.", Config.FrameworkOverride), "ERROR")
            Config.FrameworkOverride = nil -- Clear invalid override
        end
    end

    if not Config.Framework then -- Proceed with auto-detection if no valid override
        for fwKey, fwData in pairs(Config.Frameworks) do
            if fwKey == 'standalone' then goto continue end -- Skip standalone in initial auto-detect loop, handle as fallback
            local checkFunc = IsDuplicityVersion() and fwData.isServer or fwData.isClient
            if checkFunc and checkFunc() then
                Config.Framework = fwData.name -- Store the proper name
                DebugPrint(string.format("Auto-Detected Framework: %s (%s)", Config.Framework, fwKey))
                InitializeFrameworkObjects(Config.Framework)
                break
            end
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
        DebugPrint(string.format("%s Override: %s", systemNameSingular, actualSystemName))
    else
        actualSystemName = autoDetectFunc()
        if actualSystemName then
            DebugPrint(string.format("Auto-Detected %s: %s", systemNameSingular, actualSystemName))
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

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == Config.ResourceName then
        DetectFramework() -- Detects/sets Config.Framework and initializes QBCore/ESX objects
        -- Utils.Helpers should be available after helpers.lua is loaded by LoadSharedFiles
        -- However, we need isStarted for AutoDetectSystems, so we call LoadSharedFiles first.
        LoadSharedFiles() 
        AutoDetectSystems() -- Detects/sets Config.Menu, Config.Notify etc.

        DebugPrint(string.format("Final effective framework: %s", Config.Framework or "None"))
        DebugPrint(string.format("Final effective menu system: %s", Config.Menu or "None"))
        DebugPrint(string.format("Final effective notify system: %s", Config.Notify or "None"))
        DebugPrint(string.format("Final effective inventory system: %s", Config.Inventory or "None"))
        DebugPrint(string.format("Final effective progress bar system: %s", Config.ProgressBar or "None"))
        DebugPrint(string.format("Final effective draw text system: %s", Config.DrawText or "None"))
        DebugPrint(string.format("Final effective skill check system: %s", Config.SkillCheck or "None"))
        DebugPrint(string.format("Final effective target system: %s (DontUseTarget: %s)", Config.Target or "None", tostring(Config.DontUseTarget)))

    end
end)

-- Function to load shared files (assuming this is already defined or will be kept from previous steps)
function LoadSharedFiles()
    local sharedFiles = {
        'shared/helpers.lua', -- Must be loaded first for Utils.Helpers
        'shared/loaders.lua', -- For Utils.Loaders asset management
        'shared/_loaders.lua', -- For event handlers and initial load orchestration
        'shared/callback.lua',
        'shared/crafting.lua',
        'shared/drawText.lua',
        'shared/effects.lua',
        'shared/input.lua',
        'shared/notify.lua',
        'shared/phones.lua',
        'shared/shops.lua',
        'shared/targets.lua',
        'shared/zones.lua',
        'shared/make/cameras.lua',
        'shared/make/makePed.lua',
        'shared/make/makeVeh.lua'
    }

    for _, filePath in ipairs(sharedFiles) do
        local status, err = pcall(function()
            local fullPath = '@' .. Config.ResourceName .. '/' .. filePath
            if Config.DebugMode then
                DebugPrint("Loading shared file: " .. filePath, "INFO")
            end
            local chunk, loadErr = loadfile(fullPath)
            if not chunk then
                error(string.format("Failed to load chunk for %s: %s", filePath, loadErr))
            end
            local success, runErr = pcall(chunk)
            if not success then
                error(string.format("Failed to run %s: %s", filePath, runErr))
            end
        end)
        if not status then
            DebugPrint(string.format("Critical error loading shared file %s: %s. Bridge may not function correctly.", filePath, err), "FATAL")
        end
    end
end


-- Ensure Config.Framework is set on resource restart/late start scenarios
Citizen.CreateThread(function()
    Citizen.Wait(2500) -- Adjusted wait time to allow for shared files and systems to settle
    if not Config.Framework then
        DebugPrint("Re-checking for framework after initial load delay...")
        DetectFramework()
        if not Config.Framework then
             DebugPrint("No compatible framework detected after late check. Bridge functionality will be limited.", "WARN")
        end
    end
    if not Config.Menu then -- Also re-check other systems if not populated
        DebugPrint("Re-checking for other systems after initial load delay...")
        if Utils.Helpers and Utils.Helpers.isStarted then -- Make sure helpers are loaded
            AutoDetectSystems()
        else
            DebugPrint("Cannot re-check systems, Utils.Helpers not available. Shared files might not have loaded.", "ERROR")
        end
    end
end) 