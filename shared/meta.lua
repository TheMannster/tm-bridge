--==============================================================================
--  tm-bridge :: shared/meta.lua
--  TM.Meta.Get/Set -- normalised metadata accessor across frameworks.
--==============================================================================

TM.Meta = {}

local function getPlayerObj(src)
    return TM.Player.Get(src)
end

function TM.Meta.Get(src, key)
    local p = getPlayerObj(src)
    if not p then return nil end
    local fw = TM.Framework.name
    if fw == 'qbcore' or fw == 'qbox' or fw == 'rsg' then
        return p.PlayerData and p.PlayerData.metadata and p.PlayerData.metadata[key]
    end
    if fw == 'esx' then
        return (p.getMeta and p:getMeta(key)) or (p.metadata and p.metadata[key])
    end
    if fw == 'oxcore' then
        return p.get and p:get(key)
    end
end

function TM.Meta.Set(src, key, value)
    if TM.Client then return TM.Log.warn('TM.Meta.Set is server-only') end
    local p = getPlayerObj(src)
    if not p then return false end
    local fw = TM.Framework.name
    if fw == 'qbcore' or fw == 'qbox' or fw == 'rsg' then
        if p.Functions and p.Functions.SetMetaData then
            p.Functions.SetMetaData(key, value); return true
        end
    elseif fw == 'esx' then
        if p.setMeta then p:setMeta(key, value); return true end
    elseif fw == 'oxcore' then
        if p.set then p:set(key, value, true); return true end
    end
    return false
end
