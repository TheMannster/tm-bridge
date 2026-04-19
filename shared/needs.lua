--==============================================================================
--  tm-bridge :: shared/needs.lua
--  TM.Needs -- hunger / thirst / stress helpers (server side).
--  Internally writes to metadata for QB-style frameworks and via setHunger/
--  setThirst exports for ESX equivalents.
--==============================================================================

TM.Needs = {}

if TM.Client then
    function TM.Needs.Get(key)
        local d = TM.Player.Data()
        if not d then return 0 end
        if d.charinfo and d.charinfo[key] then return d.charinfo[key] end
        local meta = (d.metadata or {})
        return meta[key] or 0
    end
    return
end

local function clamp(v) return math.max(0, math.min(100, v)) end

function TM.Needs.Set(src, key, value)
    if TM.Framework.name == 'qbcore' or TM.Framework.name == 'qbox' or TM.Framework.name == 'rsg' then
        TriggerClientEvent('hud:client:UpdateNeeds', src, clamp(value), clamp(value)) -- best-effort hud refresh
        return TM.Meta.Set(src, key, clamp(value))
    end
    if TM.Framework.name == 'esx' then
        if key == 'hunger' then
            TriggerClientEvent('esx_status:set', src, 'hunger', clamp(value) * 10000)
        elseif key == 'thirst' then
            TriggerClientEvent('esx_status:set', src, 'thirst', clamp(value) * 10000)
        end
        return true
    end
end

function TM.Needs.Add(src, key, delta)
    local cur = (TM.Meta.Get(src, key) or 0)
    return TM.Needs.Set(src, key, cur + delta)
end

function TM.Needs.Hunger(src, value) return TM.Needs.Set(src, 'hunger', value) end
function TM.Needs.Thirst(src, value) return TM.Needs.Set(src, 'thirst', value) end
function TM.Needs.Stress(src, value) return TM.Needs.Set(src, 'stress', value) end
