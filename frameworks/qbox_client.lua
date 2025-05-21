if Config.Framework ~= 'qbox' then return end

FrameworkFuncs['qbox'] = FrameworkFuncs['qbox'] or {}
FrameworkFuncs['qbox'].Client = {}

local QBoxClient = {}

--- QBox: Notify player
function QBoxClient.Notify(msg, type, notificationType)
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

--- QBox: Get player data
function QBoxClient.GetPlayer()
    if not exports.qbx_core then DebugPrint("qbx_core not found in qbox_client.GetPlayer", "ERROR"); return nil end
    return exports.qbx_core:GetPlayerData()
end

--- QBox: Check if player has an item (client-side needs server call)
function QBoxClient.HasRequiredItem(item)
    -- For QBox, client-side item checks are typically not directly available.
    -- We need to trigger a server event and get a callback.
    -- This will be handled via a promise-like structure for a better API experience.
    if exports.ox_lib and exports.ox_lib.TriggerServerCallback then
         return Citizen.Await(exports.ox_lib:TriggerServerCallback(Config.ResourceName .. ':HasRequiredItem', item))
    else
        DebugPrint("ox_lib not found for QBox HasRequiredItem callback. Item check may not work as expected client-side.", "WARN")
        -- Fallback or alternative callback mechanism can be implemented here if ox_lib is not used.
        -- For now, returning false as a placeholder if no callback mechanism is found.
        return false
    end
end

FrameworkFuncs['qbox'].Client = QBoxClient
DebugPrint("QBox Client Functions Initialized.") 