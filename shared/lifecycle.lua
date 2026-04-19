--==============================================================================
--  tm-bridge :: shared/lifecycle.lua
--  Lightweight hook helpers for resource and player lifecycle events so script
--  authors don't have to hand-roll AddEventHandler boilerplate.
--==============================================================================

TM.Resource = {}

--------------------------------------------------------------------------------
-- Resource start / stop hooks
--------------------------------------------------------------------------------
function TM.Resource.OnStart(target, cb)
    if type(target) == 'function' then cb, target = target, TM.Resource end
    AddEventHandler('onResourceStart', function(name)
        if target ~= TM.Resource and name ~= target then return end
        if target == TM.Resource and name ~= TM.Resource then return end
        cb(name)
    end)
end

function TM.Resource.OnStop(target, cb)
    if type(target) == 'function' then cb, target = target, TM.Resource end
    AddEventHandler('onResourceStop', function(name)
        if target ~= TM.Resource and name ~= target then return end
        if target == TM.Resource and name ~= TM.Resource then return end
        cb(name)
    end)
end

--------------------------------------------------------------------------------
-- Player loaded hook (client only).  Fires immediately if already loaded.
--------------------------------------------------------------------------------
TM.Resource._loadedCallbacks = {}
TM.Resource._isLoaded = false

if TM.Client then
    function TM.Resource.IsPlayerLoaded()
        return TM.Resource._isLoaded
    end

    function TM.Resource.OnPlayerLoaded(cb)
        if TM.Resource._isLoaded then cb() return end
        table.insert(TM.Resource._loadedCallbacks, cb)
    end

    local function fire()
        TM.Resource._isLoaded = true
        for _, cb in ipairs(TM.Resource._loadedCallbacks) do
            local ok, err = pcall(cb)
            if not ok then TM.Log.err('OnPlayerLoaded callback failed: ' .. tostring(err)) end
        end
        TM.Resource._loadedCallbacks = {}
    end

    -- Universal events (one of these will land for whichever framework is active)
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded',  fire)
    RegisterNetEvent('qbx_core:client:playerLoaded',  fire)
    RegisterNetEvent('esx:playerLoaded',              fire)
    RegisterNetEvent('ox:playerLoaded',               fire)
    RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', fire)

    -- If the resource starts mid-session (e.g. ensure tm-bridge), assume loaded
    -- after a brief delay so OnPlayerLoaded callbacks aren't lost forever.
    CreateThread(function()
        Wait(2500)
        if TM.Resource._isLoaded then return end
        if NetworkIsPlayerActive(PlayerId()) and not IsEntityDead(PlayerPedId()) then
            fire()
        end
    end)
end

--------------------------------------------------------------------------------
-- Async sleep helper that returns when the predicate is true (or timeout hit).
--------------------------------------------------------------------------------
function TM.Resource.WaitFor(predicate, timeoutMs)
    timeoutMs = timeoutMs or 10000
    local deadline = GetGameTimer() + timeoutMs
    while GetGameTimer() < deadline do
        if predicate() then return true end
        Wait(50)
    end
    return false
end
