--==============================================================================
--  tm-bridge :: shared/auth.lua
--  TM.Auth -- single-use, time-limited tokens used to gate sensitive server
--  events (item spawning, stash opening, shop access, etc).  Defends against
--  trivial replay/dup attacks.
--==============================================================================

TM.Auth = {}

if TM.Server then
    --------------------------------------------------------------------------------
    -- Token storage:  tokens[src][purpose] = { token, expires }
    --------------------------------------------------------------------------------
    local tokens = {}

    --  Issue a one-shot token to a player for a particular purpose.
    function TM.Auth.Issue(src, purpose, ttlMs)
        ttlMs = ttlMs or 30000
        tokens[src] = tokens[src] or {}
        local t = TM.Util.Crypto.Key(28)
        tokens[src][purpose] = { token = t, expires = GetGameTimer() + ttlMs }
        return t
    end

    --  Verify (and consume on success) a token.
    function TM.Auth.Verify(src, purpose, token, opts)
        opts = opts or {}
        local bag = tokens[src] and tokens[src][purpose]
        if not bag or bag.token ~= token then
            TM.Log.warn(('auth: invalid token from src=%s purpose=%s'):format(src, purpose))
            if opts.kick then
                DropPlayer(src, 'tm-bridge :: invalid auth token (' .. purpose .. ')')
            end
            return false
        end
        if GetGameTimer() > bag.expires then
            tokens[src][purpose] = nil
            return false
        end
        if opts.consume ~= false then
            tokens[src][purpose] = nil
        end
        return true
    end

    AddEventHandler('playerDropped', function() tokens[source] = nil end)

    --  Convenience: build the network event names tm-bridge registers internally.
    function TM.Auth.RegisterEndpoint(eventName, purpose, handler)
        RegisterNetEvent(eventName, function(token, ...)
            local src = source
            if not TM.Auth.Verify(src, purpose, token) then return end
            handler(src, ...)
        end)
    end
else
    --  Client side: cache the most recent token per purpose so we can replay it.
    local cache = {}

    function TM.Auth.Store(purpose, token) cache[purpose] = token end
    function TM.Auth.Token(purpose)        return cache[purpose] end

    --  Request a token from the server (round-trip via TM.Callback).
    function TM.Auth.Request(purpose, ttlMs)
        local token = TM.Callback.Trigger(TM.Resource .. ':auth:issue', purpose, ttlMs)
        if token then cache[purpose] = token end
        return token
    end
end

--------------------------------------------------------------------------------
-- Server-side callback for clients to fetch tokens
--------------------------------------------------------------------------------
if TM.Server then
    CreateThread(function()
        Wait(500) -- ensure TM.Callback is ready
        TM.Callback.Register(TM.Resource .. ':auth:issue', function(src, purpose, ttlMs)
            return TM.Auth.Issue(src, purpose, ttlMs)
        end)
    end)
end
