QBCore = exports['qb-core']:GetCoreObject()

-- Function to get player by source
function GetPlayerQBox(src)
    return exports.qbx_core:GetPlayer(src)
end

-- Function to get all players
function GetPlayersQBox()
    return exports.qbx_core:GetPlayers()
end

-- Function to add money to player
function AddMoneyQBox(src, type, amount)
    local Player = GetPlayerQBox(src)
    if Player and Player.Functions and Player.Functions.AddMoney then
        return Player.Functions.AddMoney(type, amount)
    end
    return false
end

-- Function to remove money from player
function RemoveMoneyQBox(src, type, amount)
    local Player = GetPlayerQBox(src)
    if Player then
        return Player.Functions.RemoveMoney(type, amount)
    end
    return false
end

-- Function to get player money
function GetMoneyQBox(src, type)
    local Player = GetPlayerQBox(src)
    if Player then
        return Player.PlayerData.money[type]
    end
    return 0
end

function HasRequiredItemQBox(item, src)
    local Player = GetPlayerQBox(src)
    if Player and Player.PlayerData and Player.PlayerData.items then
        for _, v in pairs(Player.PlayerData.items) do
            if v and v.name == item and v.count and v.count > 0 then
                return true
            end
        end
    end
    return false
end

QBCore.Functions.CreateCallback('tm-bridge:HasRequiredItemQBox', function(source, cb, item)
    local hasItem = HasRequiredItemQBox(item, source)
    cb(hasItem)
end) 