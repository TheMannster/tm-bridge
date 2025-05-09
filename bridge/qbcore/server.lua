QBCore = exports['qb-core']:GetCoreObject()

-- Function to get player by source
function GetPlayerQBCore(src)
    return QBCore.Functions.GetPlayer(src)
end

-- Function to get all players
function GetPlayersQBCore()
    return QBCore.Functions.GetQBPlayers()
end

-- Function to add money to player
function AddMoneyQBCore(src, type, amount)
    local Player = GetPlayerQBCore(src)
    if Player then
        return Player.Functions.AddMoney(type, amount)
    end
    return false
end

-- Function to remove money from player
function RemoveMoneyQBCore(src, type, amount)
    local Player = GetPlayerQBCore(src)
    if Player then
        return Player.Functions.RemoveMoney(type, amount)
    end
    return false
end

-- Function to get player money
function GetMoneyQBCore(src, type)
    local Player = GetPlayerQBCore(src)
    if Player then
        return Player.PlayerData.money[type]
    end
    return 0
end

function HasRequiredItemQBCore(item, src)
    local Player = GetPlayerQBCore(src)
    if Player and Player.Functions.HasItem then
        return Player.Functions.HasItem(item)
    end
    return false
end 