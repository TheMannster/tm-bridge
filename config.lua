Config = {}
Config.Framework = nil -- Will be 'qb-core', 'qbox', 'esx', 'ox_core', 'rsg-core' etc.
Config.ResourceName = GetCurrentResourceName()
Config.DebugMode = true -- Set to true for verbose debug prints, false for production

-- Override Settings: Server owners can manually set these if auto-detection is problematic.
-- These values are read by starter.lua. If a value is set here (not nil),
-- it will be used directly, bypassing auto-detection for that specific system.
-- Set to nil or comment out to use auto-detection.
Config.FrameworkOverride = nil -- e.g., 'qb-core', 'esx', 'ox_core', 'standalone'
Config.InventorySystemOverride = nil -- e.g., 'ox_inventory', 'qb-inventory', 'ps-inventory'
Config.MenuSystemOverride = nil -- e.g., 'ox', 'qb', 'gta', 'esx'
Config.NotifySystemOverride = nil -- e.g., 'ox', 'qb', 'gta', 'esx', 'okok'
Config.ProgressBarSystemOverride = nil -- e.g., 'ox', 'qb', 'gta', 'esx'
Config.DrawTextSystemOverride = nil -- e.g., 'ox', 'qb', 'gta', 'esx'
Config.SkillCheckSystemOverride = nil -- e.g., 'ox', 'qb', 'gta'
Config.TargetSystemOverride = nil -- e.g., 'ox_target', 'qb-target', or 'none' to use DrawText3D (set Config.DontUseTarget = true for 'none')
Config.DontUseTarget = false -- Set to true if TargetSystemOverride is 'none' or if no target system is desired

-- Standardized Export Names for commonly used resources
Exports = {
    QBFrameWork = "qb-core", -- Standard QBCore
    QBXFrameWork = "qbx_core", -- QBCore with QBox specifics
    ESXFrameWork = "es_extended", -- Standard ESX
    OXCoreFrameWork = "ox_core", -- OX Core framework

    OXInv = "ox_inventory",
    QBInv = "qb-inventory",
    PSInv = "ps-inventory",
    QSInv = "qs-inventory",
    CoreInv = "core_inventory", -- Another common name for qb-inventory style
    CodeMInv = "codem-inventory",
    TgiannInv = "tgiann-inventory",
    ChezzaInv = "chezz-inventory",

    OXLib = "ox_lib",

    QBMenu = "qb-menu",
    WarMenu = "warmenu", -- GTA Native Menu often wrapped by warmenu

    QBTarget = "qb-target",
    OXTarget = "ox_target",

    -- Notification Systems (examples, shared/notify.lua has more)
    OkOkNotify = "okokNotify",

    -- RedM Specific (if ever adapted)
    RSGFrameWork = "rsg-core",
    RSGInv = "rsg-inventory"
}

Config.Frameworks = {
    ['standalone'] = { -- Added Standalone
        name = "Standalone",
        isServer = function() return true end, -- Always true as a fallback or explicit choice
        isClient = function() return true end, -- Always true as a fallback or explicit choice
    },
    ['qb-core'] = {
        name = "QBCore",
        isServer = function() return GetResourceState('qb-core') == 'started' and exports['qb-core'] and exports['qb-core'].GetCoreObject ~= nil end,
        isClient = function() return GetResourceState('qb-core') == 'started' and exports['qb-core'] and exports['qb-core'].GetCoreObject ~= nil end,
    },
    ['qbox'] = {
        name = "QBox",
        isServer = function() return GetResourceState('qbx_core') == 'started' and exports.qbx_core and exports.qbx_core.GetPlayer ~= nil end,
        isClient = function() return GetResourceState('qbx_core') == 'started' and exports.qbx_core and exports.qbx_core.GetPlayerData ~= nil end,
    },
    ['esx'] = {
        name = "ESX (Legacy & ox_lib/ox_inventory dependent)",
        isServer = function() 
            return GetResourceState('es_extended') == 'started' and exports.es_extended and exports.es_extended.getSharedObject ~= nil and 
                   GetResourceState('ox_lib') == 'started' and GetResourceState('ox_inventory') == 'started' -- As per jim_bridge, ESX support has ox dependencies
        end,
        isClient = function() 
            return GetResourceState('es_extended') == 'started' and exports.es_extended and exports.es_extended.getSharedObject ~= nil and 
                   GetResourceState('ox_lib') == 'started' and GetResourceState('ox_inventory') == 'started'
        end,
    },
    ['ox_core'] = {
        name = "OX Core",
        isServer = function() return GetResourceState('ox_core') == 'started' and exports.ox_core ~= nil end, -- Adjust with actual ox_core export check
        isClient = function() return GetResourceState('ox_core') == 'started' and exports.ox_core ~= nil end, -- Adjust with actual ox_core export check
    },
    ['rsg-core'] = { -- For RedM
        name = "RSG Core (RedM)",
        isServer = function() return GetResourceState('rsg-core') == 'started' and exports['rsg-core'] ~= nil end, -- Adjust with actual rsg-core export check
        isClient = function() return GetResourceState('rsg-core') == 'started' and exports['rsg-core'] ~= nil end, -- Adjust with actual rsg-core export check
    }
}

-- Global Core objects placeholder (ESX, QBCore etc.)
ESX = nil
QBCore = nil 
-- Other framework objects can be added here (e.g., RSGCore, OXCore)

-- Placeholders for detected/overridden systems (populated by starter.lua or shared files)
-- These variables will hold the EFFECTIVE system names that the bridge will use.
-- They are populated by starter.lua based on auto-detection or the override settings above.
-- Do NOT modify these directly; use the override settings if manual configuration is needed.
Config.Inventory = nil -- Detected/Overridden Inventory system name (e.g., Exports.OXInv)
Config.Menu = nil      -- Detected/Overridden Menu system name (e.g., 'ox', 'qb')
Config.Notify = nil    -- Detected/Overridden Notify system name (e.g., 'ox', 'qb')
Config.ProgressBar = nil -- Detected/Overridden Progress Bar system name
Config.DrawText = nil    -- Detected/Overridden Draw Text system name
Config.SkillCheck = nil  -- Detected/Overridden Skill Check system name
Config.UseTarget = true -- Detected/Overridden Target system choice (true for ox/qb-target, false for DrawText3D)

-- Global Framework Functions placeholder, populated by framework-specific files
FrameworkFuncs = {}

-- Global Bridge API placeholder, populated by bridge_client/server.lua
Bridge = {}

-- Shared utilities placeholder, to be populated by shared files
Utils = {}
Utils.Helpers = {} -- Specifically for helpers.lua functions

-- Debug printing utility
function DebugPrint(msg, level)
    if not Config.DebugMode and level ~= "ERROR" and level ~= "FATAL" then return end
    local type = level or "INFO"
    print(string.format("^5[%s]^7 [%s] (%s) %s", Config.ResourceName, type, Config.Framework or "No Framework", msg))
end

-- Simplified print for general messages not tied to debug mode
function Print(msg)
    print(string.format("^5[%s]^7 %s", Config.ResourceName, msg))
end 