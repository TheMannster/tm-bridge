--==============================================================================
--  tm-bridge :: shared/notify.lua
--  Multi-system notification layer.  Server callers can target a specific
--  player; client callers pop the message locally.  Auto-routes between
--  ox_lib, okok, qb, esx, rsg, native GTA / RDR3.
--==============================================================================

TM.Notify = {}

local ICONS = { success = 'check', error = 'xmark', warn = 'triangle-exclamation', info = 'info' }

--------------------------------------------------------------------------------
-- Local pop (client-side only)
--------------------------------------------------------------------------------
local function popLocal(title, message, kind, duration)
    kind = kind or 'info'
    duration = duration or 5000
    local sys = TM.Systems.Notify

    if sys == 'ox' and TM.HasResource(TM.Exports.oxLib) then
        exports[TM.Exports.oxLib]:notify({
            title = title, description = message, type = kind, icon = ICONS[kind], duration = duration,
        })
        return
    end

    if sys == 'okok' and TM.HasResource(TM.Exports.okOk) then
        exports[TM.Exports.okOk]:Alert(title or 'Notification', message or '', duration, kind, true)
        return
    end

    if sys == 'qb' then
        local obj = TM.Framework.Object()
        if obj and obj.Functions and obj.Functions.Notify then
            obj.Functions.Notify((title and title .. ': ' or '') .. (message or ''), kind, duration)
            return
        end
    end

    if sys == 'esx' then
        local obj = TM.Framework.Object()
        if obj and obj.ShowNotification then
            obj.ShowNotification((title and ('^*' .. title .. '^r ') or '') .. (message or ''))
            return
        end
    end

    if sys == 'rsg' then
        local obj = TM.Framework.Object()
        if obj and obj.Functions and obj.Functions.Notify then
            obj.Functions.Notify(message or title or '', kind, duration)
            return
        end
    end

    -- Native fallback
    if TM.IsRedM then
        if Citizen.InvokeNative then
            local txt = (title and title .. ': ' or '') .. (message or '')
            Citizen.InvokeNative(0xFA233F8FE190CCB0, txt, false)
        end
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName((title and title .. ': ' or '') .. (message or ''))
        EndTextCommandThefeedPostTicker(false, true)
    end
end

--------------------------------------------------------------------------------
-- Network bridge (server <-> client)
--------------------------------------------------------------------------------
if TM.Client then
    RegisterNetEvent(TM.Resource .. ':notify:relay', function(title, message, kind, duration)
        popLocal(title, message, kind, duration)
    end)
end

if TM.Server then
    RegisterNetEvent(TM.Resource .. ':notify:request', function(target, title, message, kind, duration)
        local src = source
        if not target or target == 0 then target = src end
        TriggerClientEvent(TM.Resource .. ':notify:relay', target, title, message, kind, duration)
    end)
end

--------------------------------------------------------------------------------
-- Public
--------------------------------------------------------------------------------
function TM.Notify.Show(title, message, kind, duration)
    if TM.Server then
        return TM.Log.warn('TM.Notify.Show requires a target server-side; use TM.Notify.Send(src, ...)')
    end
    popLocal(title, message, kind, duration)
end

function TM.Notify.Send(src, title, message, kind, duration)
    if TM.Server then
        if not src or src == 0 then return TM.Log.warn('TM.Notify.Send called without a player source') end
        TriggerClientEvent(TM.Resource .. ':notify:relay', src, title, message, kind, duration)
    else
        TriggerServerEvent(TM.Resource .. ':notify:request', src or GetPlayerServerId(PlayerId()), title, message, kind, duration)
    end
end

function TM.Notify.Help(message, beep)
    if TM.Server then return end
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(message or '')
    EndTextCommandDisplayHelp(0, false, beep ~= false, -1)
end
