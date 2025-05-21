fx_version 'cerulean'
game 'gta5' -- Specify 'gta5' or 'rdr3' for RedM if RSG is primary

author 'TheMannster'
description 'Comprehensive Framework Bridge for TM Scripts with auto-detection and utilities, inspired by jim_bridge.'
version '2.0.0' -- This should match version.txt

lua54 'yes'

-- Specify game type for conditional loading if supporting both GTA5 and RedM simultaneously in one manifest
-- games { 'gta5', 'rdr3' }

files {
    'config.lua', -- Ensure config.lua is loaded first
    'shared/*.lua',
    'shared/make/*.lua',
    'shared/scaleforms/*.lua'
    -- Add other specific shared files or patterns if needed, e.g., 'shared/scaleforms/*.lua'
}

shared_scripts {
    -- This block can be kept empty if starter.lua handles loading of all files specified in the 'files' block.
    -- Alternatively, specific scripts that MUST be loaded by fxmanifest globally before starter.lua runs can be listed here.
    -- For now, assuming starter.lua in client_scripts and server_scripts handles shared file loading logic.
}

client_scripts {
    'starter.lua',
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
}

server_scripts {
    '_versioncheck.lua',
    'starter.lua',
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
-- dependencies {
-- 'ox_lib'
-- } 