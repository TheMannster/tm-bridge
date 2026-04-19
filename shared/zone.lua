--==============================================================================
--  tm-bridge :: shared/zone.lua
--  TM.Zone -- thin polygon / sphere zone helper.  Uses ox_lib zones first and
--  falls back to PolyZone if ox_lib isn't present.  Returns the zone handle
--  for later removal via TM.Zone.Remove(handle).
--==============================================================================

TM.Zone = {}

if TM.Server then return end

local function asVec3(p)
    if type(p) == 'vector3' then return p end
    return vector3(p.x or p[1], p.y or p[2], p.z or p[3] or 0.0)
end

--------------------------------------------------------------------------------
-- Polygon
--------------------------------------------------------------------------------
function TM.Zone.Poly(opts)
    opts = opts or {}
    local sys = TM.Systems.Zone

    if sys == 'ox' and lib and lib.zones then
        local pts = {}
        for i, p in ipairs(opts.points or {}) do pts[i] = asVec3(p) end
        return lib.zones.poly({
            name = opts.id, points = pts,
            thickness = opts.thickness or 4.0, debug = opts.debug or (Config and Config.DebugMode),
            onEnter = opts.onEnter, onExit = opts.onExit, inside = opts.inside,
        })
    end

    if sys == 'poly' and TM.HasResource(TM.Exports.polyZone) then
        local zone = PolyZone:Create(opts.points or {}, {
            name = opts.id, debugPoly = opts.debug or (Config and Config.DebugMode),
            minZ = opts.minZ, maxZ = opts.maxZ,
        })
        zone:onPlayerInOut(function(isInside)
            if isInside and opts.onEnter then opts.onEnter() end
            if not isInside and opts.onExit then opts.onExit() end
        end)
        return zone
    end

    TM.Log.warn('TM.Zone.Poly: no zone backend; opts ignored: ' .. tostring(opts.id))
    return nil
end

--------------------------------------------------------------------------------
-- Sphere
--------------------------------------------------------------------------------
function TM.Zone.Sphere(opts)
    opts = opts or {}
    local sys = TM.Systems.Zone

    if sys == 'ox' and lib and lib.zones then
        return lib.zones.sphere({
            coords = asVec3(opts.coords), radius = opts.radius or 1.5,
            debug = opts.debug or (Config and Config.DebugMode),
            onEnter = opts.onEnter, onExit = opts.onExit, inside = opts.inside,
        })
    end

    if sys == 'poly' and TM.HasResource(TM.Exports.polyZone) then
        local zone = CircleZone:Create(asVec3(opts.coords), opts.radius or 1.5, {
            name = opts.id, debugPoly = opts.debug or (Config and Config.DebugMode),
        })
        zone:onPlayerInOut(function(isInside)
            if isInside and opts.onEnter then opts.onEnter() end
            if not isInside and opts.onExit then opts.onExit() end
        end)
        return zone
    end
    return nil
end

--------------------------------------------------------------------------------
-- Box (alias to ox_lib box zone, falls back to sphere)
--------------------------------------------------------------------------------
function TM.Zone.Box(opts)
    opts = opts or {}
    if lib and lib.zones then
        return lib.zones.box({
            coords = asVec3(opts.coords),
            size = asVec3(opts.size or vector3(1, 1, 1)),
            rotation = opts.rotation or 0.0,
            debug = opts.debug or (Config and Config.DebugMode),
            onEnter = opts.onEnter, onExit = opts.onExit, inside = opts.inside,
        })
    end
    return TM.Zone.Sphere({
        coords = opts.coords, radius = (opts.size and opts.size.x) or 2.0,
        onEnter = opts.onEnter, onExit = opts.onExit,
    })
end

--------------------------------------------------------------------------------
-- Remove
--------------------------------------------------------------------------------
function TM.Zone.Remove(handle)
    if not handle then return end
    if handle.remove then handle:remove() return end
    if handle.destroy then handle:destroy() return end
end
