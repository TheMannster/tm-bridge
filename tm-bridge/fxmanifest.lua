fx_version 'cerulean'
game 'gta5'

author 'TheMannster'
description 'Framework Bridge for TM Scripts'
version '1.0.0'

client_scripts {
    'bridge/qbcore/client.lua',
    'bridge/qbox/client.lua'
}

server_scripts {
    'bridge/qbcore/server.lua',
    'bridge/qbox/server.lua'
}

exports {
    'HasRequiredItemQBCore',
    'NotifyQBCore',
    'GetPlayerQBCore',
    'HasRequiredItemQBox',
    'NotifyQBox',
    'GetPlayerQBox'
}

server_exports {
    'GetPlayerQBCore',
    'GetPlayersQBCore',
    'AddMoneyQBCore',
    'RemoveMoneyQBCore',
    'GetMoneyQBCore',
    'HasRequiredItemQBCore',
    'GetPlayerQBox',
    'GetPlayersQBox',
    'AddMoneyQBox',
    'RemoveMoneyQBox',
    'GetMoneyQBox',
    'HasRequiredItemQBox'
}

lua54 'yes' 