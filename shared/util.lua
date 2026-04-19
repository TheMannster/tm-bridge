--==============================================================================
--  tm-bridge :: shared/util.lua
--  Generic helpers: tables, math, formatting, crypto/keys, vectors, raycasts,
--  and small debug-drawing utilities.  No framework dependencies.
--==============================================================================

TM.Util = {}

--==============================================================================
-- TABLE helpers
--==============================================================================
TM.Util.Table = {}

function TM.Util.Table.count(t)
    if type(t) ~= 'table' then return 0 end
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

function TM.Util.Table.keys(t)
    local out = {}
    for k in pairs(t or {}) do out[#out + 1] = k end
    return out
end

function TM.Util.Table.values(t)
    local out = {}
    for _, v in pairs(t or {}) do out[#out + 1] = v end
    return out
end

function TM.Util.Table.sortedPairs(t, comp)
    local keys = TM.Util.Table.keys(t)
    table.sort(keys, comp)
    local i = 0
    return function()
        i = i + 1
        local k = keys[i]
        if k ~= nil then return k, t[k] end
    end
end

function TM.Util.Table.deepCopy(orig)
    if type(orig) ~= 'table' then return orig end
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = TM.Util.Table.deepCopy(v)
    end
    return copy
end

function TM.Util.Table.merge(a, b)
    a = a or {}
    for k, v in pairs(b or {}) do a[k] = v end
    return a
end

function TM.Util.Table.contains(t, value)
    for _, v in pairs(t or {}) do
        if v == value then return true end
    end
    return false
end

--==============================================================================
-- MATH helpers
--==============================================================================
TM.Util.Math = {}

function TM.Util.Math.round(num, places)
    local mult = 10 ^ (places or 0)
    return math.floor(num * mult + 0.5) / mult
end

function TM.Util.Math.clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

function TM.Util.Math.distance2(a, b)
    return #(vector3(a.x or a[1], a.y or a[2], 0.0) - vector3(b.x or b[1], b.y or b[2], 0.0))
end

function TM.Util.Math.distance3(a, b)
    return #(vector3(a.x or a[1], a.y or a[2], a.z or a[3]) - vector3(b.x or b[1], b.y or b[2], b.z or b[3]))
end

function TM.Util.Math.rotationToDirection(rotation)
    local z = math.rad(rotation.z)
    local x = math.rad(rotation.x)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

--==============================================================================
-- FORMAT helpers
--==============================================================================
TM.Util.Format = {}

function TM.Util.Format.number(n)
    n = tonumber(n) or 0
    local int, dec = tostring(n):match('^(%-?%d+)(%.?%d*)$')
    if not int then return tostring(n) end
    int = int:reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')
    return int .. (dec or '')
end

function TM.Util.Format.money(amount, prefix)
    return (prefix or '$') .. TM.Util.Format.number(amount)
end

function TM.Util.Format.coords(c)
    if not c then return 'nil' end
    return ('%.2f, %.2f, %.2f'):format(c.x or c[1], c.y or c[2], c.z or c[3])
end

function TM.Util.Format.timeShort(seconds)
    seconds = math.max(0, math.floor(seconds))
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return ('%02d:%02d'):format(m, s)
end

function TM.Util.Format.titleCase(str)
    return (tostring(str or ''):gsub('(%a)([%w_\']*)', function(f, r)
        return f:upper() .. r:lower()
    end))
end

--==============================================================================
-- CRYPTO / random
--==============================================================================
TM.Util.Crypto = {}

local seeded = false
local function seedOnce()
    if seeded then return end
    math.randomseed(GetGameTimer() + (TM.Server and 1 or 9000))
    seeded = true
end

local CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'

function TM.Util.Crypto.Key(length)
    seedOnce()
    length = length or 24
    local buf = {}
    for i = 1, length do
        local r = math.random(1, #CHARS)
        buf[i] = CHARS:sub(r, r)
    end
    return table.concat(buf)
end

function TM.Util.Crypto.Uuid()
    seedOnce()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return (template:gsub('[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return ('%x'):format(v)
    end))
end

function TM.Util.Crypto.Random(min, max)
    seedOnce()
    return math.random(min, max)
end

--==============================================================================
-- DEBUG drawing (client only)
--==============================================================================
TM.Util.Debug = {}

if TM.Client then
    function TM.Util.Debug.Sphere(coords, radius, colour)
        if not Config or not Config.DebugMode then return end
        local r, g, b, a = 0, 200, 255, 100
        if colour then r, g, b, a = colour[1] or r, colour[2] or g, colour[3] or b, colour[4] or a end
        DrawMarker(28, coords.x, coords.y, coords.z, 0, 0, 0, 0, 0, 0,
            radius, radius, radius, r, g, b, a, false, false, 2, false, nil, nil, false)
    end

    function TM.Util.Debug.Line(from, to, colour)
        if not Config or not Config.DebugMode then return end
        local r, g, b = 255, 0, 0
        if colour then r, g, b = colour[1] or r, colour[2] or g, colour[3] or b end
        DrawLine(from.x, from.y, from.z, to.x, to.y, to.z, r, g, b, 255)
    end
end

--==============================================================================
-- RAYCAST (client only)
--==============================================================================
TM.Util.Raycast = {}

if TM.Client then
    function TM.Util.Raycast.FromCamera(distance, flags)
        local cam = GetGameplayCamCoord()
        local dir = TM.Util.Math.rotationToDirection(GetGameplayCamRot(2))
        local dest = cam + dir * (distance or 25.0)
        local ray = StartShapeTestRay(cam, dest, flags or -1, PlayerPedId(), 0)
        local _, hit, endCoords, surface, entity = GetShapeTestResult(ray)
        return { hit = hit == 1, coords = endCoords, surface = surface, entity = entity }
    end

    function TM.Util.Raycast.GroundMaterial(coords)
        local cx = (coords and coords.x) or 0
        local cy = (coords and coords.y) or 0
        local cz = (coords and coords.z) or 0
        local ignore = TM.Server and 0 or PlayerPedId()
        local ray = StartShapeTestRay(cx, cy, cz + 1.0, cx, cy, cz - 2.0, -1, ignore, 0)
        local _, _, _, surface = GetShapeTestResult(ray)
        return surface
    end
end
