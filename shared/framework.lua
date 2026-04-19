--==============================================================================
--  tm-bridge :: shared/framework.lua
--  Detects which framework is running.  Uses Config.FrameworkOverride if set,
--  otherwise auto-detects from started resources.  Stores the result on
--  TM.Framework so adapters can wire themselves up.
--==============================================================================

TM.Framework = {
    name      = 'standalone',  -- canonical name: qbcore | qbox | esx | oxcore | rsg | standalone
    object    = nil,           -- raw framework object (QBCore, ESX, Core, etc.)
    available = {},            -- list of detected framework keys (debug)
}

local function pick()
    if Config and Config.FrameworkOverride and Config.FrameworkOverride ~= '' then
        return Config.FrameworkOverride
    end

    if TM.HasResource(TM.Exports.qbox)   then return 'qbox'   end
    if TM.HasResource(TM.Exports.qbcore) then return 'qbcore' end
    if TM.HasResource(TM.Exports.esx)    then return 'esx'    end
    if TM.HasResource(TM.Exports.oxcore) then return 'oxcore' end
    if TM.HasResource(TM.Exports.rsg)    then return 'rsg'    end
    return 'standalone'
end

TM.Framework.name = pick()

table.insert(TM.Framework.available, TM.Framework.name)

--------------------------------------------------------------------------------
-- Resolve framework object once.  Subsequent .Object() calls return cache.
--------------------------------------------------------------------------------
function TM.Framework.Object()
    if TM.Framework.object then return TM.Framework.object end

    local name = TM.Framework.name
    local ok, obj
    if name == 'qbcore' then
        ok, obj = pcall(function() return exports[TM.Exports.qbcore]:GetCoreObject() end)
    elseif name == 'qbox' then
        ok, obj = pcall(function() return exports[TM.Exports.qbox]:GetCoreObject() end)
        if not ok or not obj then
            ok, obj = pcall(function() return exports[TM.Exports.qbox] end)
        end
    elseif name == 'esx' then
        if TM.Server then
            ok, obj = pcall(function() return exports[TM.Exports.esx]:getSharedObject() end)
        else
            ok, obj = pcall(function() return exports[TM.Exports.esx]:getSharedObject() end)
        end
    elseif name == 'oxcore' then
        ok, obj = pcall(function() return exports[TM.Exports.oxcore] end)
    elseif name == 'rsg' then
        ok, obj = pcall(function() return exports[TM.Exports.rsg]:GetCoreObject() end)
    end

    if ok then TM.Framework.object = obj end
    return TM.Framework.object
end

-- Trigger eager resolve so adapters can rely on .object being populated.
TM.Framework.Object()

TM.Log.debug(('framework = %s (object=%s)'):format(TM.Framework.name, tostring(TM.Framework.object ~= nil)))
