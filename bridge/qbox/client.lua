-- Function to notify player
function NotifyQBox(msg, type, notificationType)
    if notificationType == "ox" and exports.ox_lib then
        local oxType = type
        if type == "error" then oxType = "error"
        elseif type == "success" then oxType = "success"
        elseif type == "police" then oxType = "inform" end
        exports.ox_lib:notify({ description = msg, type = oxType })
    else
        TriggerEvent('Qbox:Notify', msg, type)
    end
end

-- Function to get player data
function GetPlayerQBox()
    return exports.qbx_core:GetPlayerData()
end 