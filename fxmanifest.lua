fx_version 'cerulean'
game 'gta5' -- Specify 'gta5' or 'rdr3' for RedM if RSG is primary

author 'TheMannster'
description 'Comprehensive Framework Bridge for TM Scripts with auto-detection and utilities, inspired by jim_bridge.'
version '2.1.0' -- This should match version.txt

lua54 'yes'

-- Specify game type for conditional loading if supporting both GTA5 and RedM simultaneously in one manifest
-- games { 'gta5', 'rdr3' }

files {
    -- These files are made available but not automatically loaded unless listed in shared/client/server scripts.
    -- We are explicitly loading them below, so this section can remain commented or used for non-Lua files if any.
    -- 'config.lua',
    -- 'shared/*.lua',
    -- 'shared/make/*.lua',
    -- 'shared/scaleforms/*.lua'
}

shared_scripts {
    'config.lua', -- Load config.lua globally first. Defines Config table structure.
    'shared/helpers.lua', -- Load helpers immediately after config. Defines Utils.Helpers.
    'starter.lua', -- starter.lua now runs its detections in shared context BEFORE other shared scripts.
    'shared/playerfunctions.lua', -- Ensure playerfunctions is loaded before other shared scripts that might use its functions.
    'shared/*.lua',
    'shared/make/*.lua',
    'shared/scaleforms/*.lua'
}

client_scripts {
    -- starter.lua is removed from here
    -- GTA5 Frameworks
    'frameworks/qbcore_client.lua',
    'frameworks/qbox_client.lua',
    'frameworks/esx_client.lua',
    'frameworks/ox_core_client.lua',
    -- RedM Frameworks
    'frameworks/rsg_client.lua',
    -- Standalone Fallback
    'frameworks/standalone_client.lua',
    'bridge_client.lua'
    -- Add client_init.lua if we create it
}

server_scripts {
    '_versioncheck.lua', -- This script seems to be server-only and does its own version check.
    -- starter.lua is removed from here
    -- GTA5 Frameworks
    'frameworks/qbcore_server.lua',
    'frameworks/qbox_server.lua',
    'frameworks/esx_server.lua',
    'frameworks/ox_core_server.lua',
    -- RedM Frameworks
    'frameworks/rsg_server.lua',
    -- Standalone Fallback
    'frameworks/standalone_server.lua',
    'bridge_server.lua'
}

exports {
    -- Core Bridge Exports
    'Notify',
    'GetPlayer',
    'HasRequiredItem',
}

server_exports {
    -- Core Bridge Exports
    'GetPlayer',
    'GetPlayers',
    'AddMoney',
    'RemoveMoney',
    'GetMoney',
    'HasRequiredItem',
    'CreateCallback',
    'TriggerCallback'
}

-- Optional: Define dependencies
dependencies {
    'ox_lib'
} 