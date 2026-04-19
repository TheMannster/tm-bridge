--==============================================================================
--  tm-bridge :: shared/target.lua
--  TM.Target -- ox_target / qb-target wrapper with a 3D drawText fallback for
--  "no target system installed" servers.
--
--  Spec format used everywhere:
--      spec = {
--          id      = 'unique_string',           -- key used to remove later
--          icon    = 'fa-solid fa-coffee',
--          label   = 'Drink coffee',
--          item    = 'coffee_cup' (optional),
--          job     = { 'police', 'sheriff' } | string (optional),
--          gang    = '...' (optional),
--          distance = 2.0,
--          onSelect = function(entity / coords) end,
--          canInteract = function(entity, distance) return bool end (optional),
--      }
--==============================================================================

TM.Target = {}

if TM.Server then return end

local function toOxOption(spec)
    return {
        name      = spec.id,
        label     = spec.label,
        icon      = spec.icon,
        items     = spec.item,
        groups    = spec.job or spec.gang,
        distance  = spec.distance or 2.0,
        canInteract = spec.canInteract,
        onSelect  = function(data) if spec.onSelect then spec.onSelect(data.entity or data.coords) end end,
    }
end

local function toQbOption(spec)
    return {
        type      = 'client',
        action    = function(entity) if spec.onSelect then spec.onSelect(entity) end end,
        icon      = spec.icon,
        label     = spec.label,
        item      = spec.item,
        job       = type(spec.job) == 'table' and spec.job[1] or spec.job,
        gang      = spec.gang,
        canInteract = spec.canInteract,
    }
end

--------------------------------------------------------------------------------
-- Fallback: simple 3D text + key press loop indexed by id
--------------------------------------------------------------------------------
local fallback = {}

local function startFallbackLoop()
    if fallback._running then return end
    fallback._running = true
    CreateThread(function()
        while fallback._running do
            local sleep = 750
            local ped = PlayerPedId()
            local pcoords = GetEntityCoords(ped)
            for _, e in pairs(fallback) do
                if type(e) == 'table' and e.coords then
                    local d = #(pcoords - e.coords)
                    if d < (e.distance or 2.0) then
                        sleep = 0
                        TM.Text.Draw3D(e.coords + vector3(0, 0, 1.0), '[E] ' .. (e.label or ''))
                        if IsControlJustPressed(0, 38) then
                            if e.onSelect then e.onSelect(e.entity or e.coords) end
                        end
                    end
                end
            end
            Wait(sleep)
        end
    end)
end

local function addFallback(spec, coords, entity)
    fallback[spec.id] = {
        coords = coords, entity = entity,
        label = spec.label, distance = spec.distance, onSelect = spec.onSelect,
    }
    startFallbackLoop()
end

local function removeFallback(id)
    fallback[id] = nil
end

--------------------------------------------------------------------------------
-- Public: AddEntity
--------------------------------------------------------------------------------
function TM.Target.AddEntity(entity, spec)
    if TM.Systems.Target == 'ox' and TM.HasResource(TM.Exports.oxTarget) then
        return exports[TM.Exports.oxTarget]:addLocalEntity(entity, { toOxOption(spec) })
    end
    if TM.Systems.Target == 'qb' and TM.HasResource(TM.Exports.qbTarget) then
        return exports[TM.Exports.qbTarget]:AddTargetEntity(entity, {
            options = { toQbOption(spec) }, distance = spec.distance or 2.0,
        })
    end
    addFallback(spec, GetEntityCoords(entity), entity)
end

function TM.Target.AddBox(spec)
    spec.coords = vector3(spec.coords.x, spec.coords.y, spec.coords.z)
    if TM.Systems.Target == 'ox' and TM.HasResource(TM.Exports.oxTarget) then
        return exports[TM.Exports.oxTarget]:addBoxZone({
            name = spec.id, coords = spec.coords, size = spec.size or vector3(1, 1, 1),
            rotation = spec.rotation or 0, debug = Config and Config.DebugMode,
            options = { toOxOption(spec) },
        })
    end
    if TM.Systems.Target == 'qb' and TM.HasResource(TM.Exports.qbTarget) then
        return exports[TM.Exports.qbTarget]:AddBoxZone(spec.id, spec.coords,
            (spec.size and spec.size.x) or 1.0, (spec.size and spec.size.y) or 1.0, {
                name = spec.id, debugPoly = Config and Config.DebugMode,
                minZ = spec.coords.z - 1.0, maxZ = spec.coords.z + 1.0,
                heading = spec.rotation or 0,
            }, { options = { toQbOption(spec) }, distance = spec.distance or 2.0 })
    end
    addFallback(spec, spec.coords)
end

function TM.Target.AddSphere(spec)
    spec.coords = vector3(spec.coords.x, spec.coords.y, spec.coords.z)
    if TM.Systems.Target == 'ox' and TM.HasResource(TM.Exports.oxTarget) then
        return exports[TM.Exports.oxTarget]:addSphereZone({
            name = spec.id, coords = spec.coords, radius = spec.radius or 1.0,
            debug = Config and Config.DebugMode, options = { toOxOption(spec) },
        })
    end
    if TM.Systems.Target == 'qb' and TM.HasResource(TM.Exports.qbTarget) then
        return exports[TM.Exports.qbTarget]:AddCircleZone(spec.id, spec.coords,
            spec.radius or 1.0, { name = spec.id, debugPoly = Config and Config.DebugMode },
            { options = { toQbOption(spec) }, distance = spec.distance or 2.0 })
    end
    addFallback(spec, spec.coords)
end

function TM.Target.AddModel(model, spec)
    if TM.Systems.Target == 'ox' and TM.HasResource(TM.Exports.oxTarget) then
        return exports[TM.Exports.oxTarget]:addModel(model, { toOxOption(spec) })
    end
    if TM.Systems.Target == 'qb' and TM.HasResource(TM.Exports.qbTarget) then
        return exports[TM.Exports.qbTarget]:AddTargetModel(model, {
            options = { toQbOption(spec) }, distance = spec.distance or 2.0,
        })
    end
    TM.Log.warn('TM.Target.AddModel called without ox_target/qb-target; ignored')
end

--------------------------------------------------------------------------------
-- Remove
--------------------------------------------------------------------------------
function TM.Target.Remove(id)
    if TM.HasResource(TM.Exports.oxTarget) then
        pcall(function() exports[TM.Exports.oxTarget]:removeZone(id) end)
        pcall(function() exports[TM.Exports.oxTarget]:removeOption(id) end)
    end
    if TM.HasResource(TM.Exports.qbTarget) then
        pcall(function() exports[TM.Exports.qbTarget]:RemoveZone(id) end)
        pcall(function() exports[TM.Exports.qbTarget]:RemoveTargetEntity(id) end)
    end
    removeFallback(id)
end

function TM.Target.RemoveEntity(entity, id)
    if TM.HasResource(TM.Exports.oxTarget) then
        pcall(function() exports[TM.Exports.oxTarget]:removeLocalEntity(entity, id) end)
    end
    if TM.HasResource(TM.Exports.qbTarget) then
        pcall(function() exports[TM.Exports.qbTarget]:RemoveTargetEntity(entity, id) end)
    end
    removeFallback(id)
end

function TM.Target.RemoveModel(model, id)
    if TM.HasResource(TM.Exports.oxTarget) then
        pcall(function() exports[TM.Exports.oxTarget]:removeModel(model, id) end)
    end
    if TM.HasResource(TM.Exports.qbTarget) then
        pcall(function() exports[TM.Exports.qbTarget]:RemoveTargetModel(model, id) end)
    end
end
