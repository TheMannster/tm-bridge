fx_version 'cerulean'
games { 'gta5', 'rdr3' }

name        'tm-bridge'
author      'TheMannster'
description 'Framework bridge + shared utilities for TM scripts (QBCore, QBox, ESX, OX Core, RSG, standalone).'
version     '3.0.0'

lua54 'yes'
use_experimental_fxv2_oal 'yes'

--==============================================================================
-- shared_scripts -- the order below IS the load order; it is grouped into:
--   core           bootstrap (logger, exports, framework + system detection,
--                  data tables, lifecycle hooks, generic util)
--   ui             player-facing helpers (callbacks, notify, text, menus,
--                  progress, skillcheck, input, command)
--   world          world / asset helpers (anim, target, zones, vehicles,
--                  entity scaling + DUI, effects, animals)
--   player         per-player state (player, money, job, metadata, needs,
--                  society)
--   inventory      auth tokens + item/inventory/stash/shop/crafting/rewards
--   misc           phone, factory helpers, scaleform helpers
--==============================================================================
shared_scripts {
    --  ox_lib provides the `lib` global used by callback / zones / menus / etc.
    --  Soft requirement: if ox_lib isn't installed the manifest line is skipped
    --  and the ox-backed branches fall back to natives where possible.
    '@ox_lib/init.lua',

    'config.lua',

    -- core
    'shared/core.lua',
    'shared/exports.lua',
    'shared/framework.lua',
    'shared/systems.lua',
    'shared/data.lua',
    'shared/lifecycle.lua',
    'shared/util.lua',

    -- ui
    'shared/callback.lua',
    'shared/notify.lua',
    'shared/text.lua',
    'shared/input.lua',
    'shared/menu.lua',
    'shared/progress.lua',
    'shared/skill.lua',
    'shared/command.lua',

    -- world
    'shared/asset.lua',
    'shared/anim.lua',
    'shared/target.lua',
    'shared/zone.lua',
    'shared/vehicle.lua',
    'shared/entity.lua',
    'shared/effects.lua',
    'shared/animal.lua',

    -- player
    'shared/player.lua',
    'shared/money.lua',
    'shared/job.lua',
    'shared/meta.lua',
    'shared/needs.lua',
    'shared/society.lua',

    -- inventory
    'shared/auth.lua',
    'shared/items.lua',
    'shared/inventory.lua',
    'shared/stash.lua',
    'shared/shop.lua',
    'shared/crafting.lua',
    'shared/rewards.lua',

    -- misc
    'shared/phone.lua',
    'shared/make.lua',
    'shared/scaleform.lua',
}

client_scripts {
    'bridge/client.lua',
}

server_scripts {
    'bridge/server.lua',
    'server/boot.lua',
    'server/versioncheck.lua',
}

--==============================================================================
-- Cross-resource exports.  Resource consumers can hit them via
--   exports['tm-bridge']:GetTM()      -> the live TM table
-- or named convenience exports listed below.
--==============================================================================
exports {
    'GetTM',
    'GetFramework', 'GetSystems',
    'IsPlayerLoaded', 'GetPlayerData',
    'Notify', 'HelpText',
    'Progress', 'Skill', 'Input', 'Menu',
    'TriggerCallback',
    'HasItem', 'CountItem', 'ItemImage',
    'GetVehicleProperties', 'SetVehicleProperties', 'ClosestVehicle',
    'OpenShop', 'OpenStash', 'OpenCrafting',
}

server_exports {
    'GetTM',
    'GetFramework', 'GetSystems',
    'GetPlayer', 'GetIdentifier', 'GetPlayerData',
    'HasItem', 'CountItem', 'AddItem', 'RemoveItem', 'RegisterUseable',
    'GetMoney', 'AddMoney', 'RemoveMoney', 'ChargeMoney',
    'GetSociety', 'AddSociety', 'RemoveSociety',
    'NotifyPlayer', 'PhoneMail',
    'RegisterCallback',
    'RegisterStash', 'RegisterShop', 'RegisterRecipe',
}

dependencies {
    '/server:7290',
    '/onesync',
}
