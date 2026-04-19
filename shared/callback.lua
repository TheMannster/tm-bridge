--==============================================================================
--  tm-bridge :: shared/callback.lua
--  Unified server <-> client callback layer.  Server authors register, client
--  authors trigger.  Routes through ox_lib if present, otherwise framework
--  natives, otherwise a plain network-event implementation.
--==============================================================================

TM.Callback = {}

--  ox_lib is loaded into our env via '@ox_lib/init.lua' in fxmanifest, so
--  the `lib` global is available here when ox_lib is started.  We still
--  guard with both a resource check AND a `lib` truthiness check so a
--  half-loaded ox_lib can't crash us.
local hasOx = TM.HasResource(TM.Exports.oxLib) and lib and lib.callback ~= nil

--------------------------------------------------------------------------------
-- Internal fallback implementation (network events)
--------------------------------------------------------------------------------
local nativeHandlers = {}
local nativePending  = {}
local nativeId       = 0

if TM.Server then
    RegisterNetEvent(TM.Resource .. ':cb:request', function(name, token, ...)
        local src = source
        local handler = nativeHandlers[name]
        if not handler then
            TriggerClientEvent(TM.Resource .. ':cb:reply', src, token)
            return
        end
        local args = { ... }
        CreateThread(function()
            local result = { handler(src, table.unpack(args)) }
            TriggerClientEvent(TM.Resource .. ':cb:reply', src, token, table.unpack(result))
        end)
    end)
else
    RegisterNetEvent(TM.Resource .. ':cb:reply', function(token, ...)
        local cb = nativePending[token]
        if not cb then return end
        nativePending[token] = nil
        cb(...)
    end)
end

local function nextToken()
    nativeId = nativeId + 1
    return ('%s_%d_%d'):format(TM.Resource, GetGameTimer(), nativeId)
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------
function TM.Callback.Register(name, handler)
    if not TM.Server then
        return TM.Log.warn('TM.Callback.Register must be called server-side (' .. tostring(name) .. ')')
    end
    if hasOx then
        return lib.callback.register(name, handler)
    end
    nativeHandlers[name] = handler

    -- Compatibility: also expose to QBCore / ESX so older callers can hit it
    if TM.Framework.name == 'qbcore' or TM.Framework.name == 'qbox' then
        local obj = TM.Framework.Object()
        if obj and obj.Functions and obj.Functions.CreateCallback then
            obj.Functions.CreateCallback(name, function(src, cb, ...)
                cb(handler(src, ...))
            end)
        end
    elseif TM.Framework.name == 'esx' then
        local obj = TM.Framework.Object()
        if obj and obj.RegisterServerCallback then
            obj.RegisterServerCallback(name, function(src, cb, ...)
                cb(handler(src, ...))
            end)
        end
    end
end

--------------------------------------------------------------------------------
-- Trigger (client side, returns the result synchronously via promise.await)
--------------------------------------------------------------------------------
function TM.Callback.Trigger(name, ...)
    if TM.Server then
        return TM.Log.warn('TM.Callback.Trigger must be called client-side (' .. tostring(name) .. ')')
    end

    if hasOx then
        return lib.callback.await(name, false, ...)
    end

    local p = promise.new()
    local token = nextToken()
    nativePending[token] = function(...)
        p:resolve({ ... })
    end
    TriggerServerEvent(TM.Resource .. ':cb:request', name, token, ...)
    local res = Citizen.Await(p)
    return table.unpack(res)
end

--------------------------------------------------------------------------------
-- Async variant: pass a callback function instead of waiting
--------------------------------------------------------------------------------
function TM.Callback.TriggerAsync(name, cb, ...)
    if TM.Server then
        return TM.Log.warn('TM.Callback.TriggerAsync must be called client-side (' .. tostring(name) .. ')')
    end
    if hasOx then
        return lib.callback(name, false, cb, ...)
    end
    local token = nextToken()
    nativePending[token] = cb
    TriggerServerEvent(TM.Resource .. ':cb:request', name, token, ...)
end
