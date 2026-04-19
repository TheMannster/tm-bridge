--==============================================================================
--  tm-bridge :: config.lua
--  Single source of truth.  Loaded BEFORE every shared/ module.
--
--  In normal use you only need to flip DebugMode.  Auto-detection handles
--  every other system.  Use the System.* keys only when you need to force
--  a specific backend.
--==============================================================================

Config = Config or {}

--------------------------------------------------------------------------------
-- General
--------------------------------------------------------------------------------
Config.ResourceName = GetCurrentResourceName()
Config.DebugMode    = false        -- set true while developing

--------------------------------------------------------------------------------
-- Version check toggle.  The repo / branch are hard-coded in
-- server/versioncheck.lua so they never go stale relative to the codebase.
--------------------------------------------------------------------------------
Config.VersionCheck = true

--------------------------------------------------------------------------------
-- Framework / system overrides
--   Leave nil to auto-detect.
--   Framework values   :  'qbcore' | 'qbox' | 'esx' | 'oxcore' | 'rsg' | 'standalone'
--   Inventory values   :  'ox' | 'qb' | 'qbold' | 'ps' | 'qs' | 'codem' | 'origen' | 'tgiann' | 'core' | 'rsg' | 'framework'
--   Notify values      :  'ox' | 'okok' | 'qb' | 'esx' | 'rsg' | 'gta'
--   Menu values        :  'ox' | 'qb' | 'war' | 'gta'
--   Input values       :  'ox' | 'qb' | 'esx' | 'gta'
--   Progress values    :  'ox' | 'qb' | 'esx' | 'rdr3' | 'gta'
--   Skill values       :  'ox' | 'qb' | 'gta'
--   DrawText values    :  'ox' | 'qb' | 'esx' | 'rdr3' | 'gta'
--   Target values      :  'ox' | 'qb' | 'none'
--   Zone values        :  'ox' | 'poly' | 'none'
--   Bank values        :  'renewed' | 'fd' | 'qb' | 'okok' | 'framework'
--------------------------------------------------------------------------------
Config.FrameworkOverride = nil

Config.System = {
    Notify    = nil,
    Menu      = nil,
    Input     = nil,
    Inventory = nil,
    Progress  = nil,
    Skill     = nil,
    DrawText  = nil,
    Target    = nil,
    Zone      = nil,
    Bank      = nil,
    DontUseTarget = false,
}

--------------------------------------------------------------------------------
-- Crafting / rewards (defaults the per-recipe specs can override)
--------------------------------------------------------------------------------
Config.Crafting = {
    showItemBox = true,
}

Config.Rewards = {
    DefaultPool = nil, -- e.g. { { item = 'gold', amount = 1, chance = 5 }, ... }
}
