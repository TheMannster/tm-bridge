QBCore = exports['qb-core']:GetCoreObject()

-- Function to check if player has an item
function HasRequiredItemQBCore(item)
    return QBCore.Functions.HasItem(item)
end

-- Function to notify player
function NotifyQBCore(msg, type, notificationType)
    if notificationType == "ox" and exports.ox_lib then
        local oxType = type
        if type == "error" then oxType = "error"
        elseif type == "success" then oxType = "success"
        elseif type == "police" then oxType = "inform" end
        exports.ox_lib:notify({ description = msg, type = oxType })
    else
        QBCore.Functions.Notify(msg, type)
    end
end

-- Function to get player data
function GetPlayerQBCore()
    return QBCore.Functions.GetPlayerData()
end 