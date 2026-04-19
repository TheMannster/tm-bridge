--==============================================================================
--  tm-bridge :: shared/data.lua
--  Pulls Items / Vehicles / Jobs / Gangs from the active framework into a
--  unified TM.Data table.  Files needing those tables can read TM.Data.Items
--  etc instead of hand-rolled loaders.
--==============================================================================

TM.Data = {
    Items    = {},
    Vehicles = {},
    Jobs     = {},
    Gangs    = {},
}

local function safe(fn)
    local ok, val = pcall(fn)
    return ok and val or nil
end

local function loadFromFramework()
    local fw = TM.Framework.name
    local obj = TM.Framework.Object()
    if not obj then return end

    if fw == 'qbcore' or fw == 'qbox' then
        TM.Data.Items    = safe(function() return obj.Shared and obj.Shared.Items    end) or {}
        TM.Data.Vehicles = safe(function() return obj.Shared and obj.Shared.Vehicles end) or {}
        TM.Data.Jobs     = safe(function() return obj.Shared and obj.Shared.Jobs     end) or {}
        TM.Data.Gangs    = safe(function() return obj.Shared and obj.Shared.Gangs    end) or {}
    elseif fw == 'esx' then
        TM.Data.Items    = safe(function() return obj.GetItems and obj.GetItems() end)
                        or safe(function() return obj.Items end) or {}
        TM.Data.Jobs     = safe(function() return obj.GetJobs and obj.GetJobs() end)
                        or safe(function() return obj.Jobs end) or {}
    elseif fw == 'oxcore' then
        TM.Data.Items = safe(function() return exports[TM.Exports.invOX]:Items() end) or {}
    elseif fw == 'rsg' then
        TM.Data.Items    = safe(function() return obj.Shared and obj.Shared.Items    end) or {}
        TM.Data.Jobs     = safe(function() return obj.Shared and obj.Shared.Jobs     end) or {}
        TM.Data.Gangs    = safe(function() return obj.Shared and obj.Shared.Gangs    end) or {}
        TM.Data.Vehicles = safe(function() return obj.Shared and obj.Shared.Vehicles end) or {}
    end

    -- ox_inventory items override (most accurate item table when present)
    if TM.HasResource(TM.Exports.invOX) then
        local oxItems = safe(function() return exports[TM.Exports.invOX]:Items() end)
        if oxItems and next(oxItems) then TM.Data.Items = oxItems end
    end
end

loadFromFramework()

local function count(t) local n = 0 for _ in pairs(t or {}) do n = n + 1 end return n end

TM.Log.debug(('data loaded: items=%d vehicles=%d jobs=%d gangs=%d'):format(
    count(TM.Data.Items), count(TM.Data.Vehicles), count(TM.Data.Jobs), count(TM.Data.Gangs)))
