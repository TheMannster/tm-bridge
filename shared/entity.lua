--==============================================================================
--  tm-bridge :: shared/entity.lua
--  TM.Entity -- generic entity helpers: scaling, facing, grounding, dimensions,
--  DUI textures.
--==============================================================================

TM.Entity = {}
TM.DUI    = {}

if TM.Server then
    -- Server doesn't get DUI / scaling helpers, only stub out the namespace
    return
end

--------------------------------------------------------------------------------
-- Scaling
--   Sets the visual scale of an entity using SetEntityScale (works on objects,
--   peds, and vehicles in GTAV+RDR3).
--------------------------------------------------------------------------------
function TM.Entity.SetScale(entity, scale)
    if not DoesEntityExist(entity) then return false end
    SetEntityScale(entity, scale, scale, scale)
    return true
end

function TM.Entity.ResetScale(entity)
    return TM.Entity.SetScale(entity, 1.0)
end

--------------------------------------------------------------------------------
-- Forward / facing
--------------------------------------------------------------------------------
function TM.Entity.Forward(entity, distance)
    distance = distance or 1.0
    return GetOffsetFromEntityInWorldCoords(entity, 0.0, distance, 0.0)
end

--------------------------------------------------------------------------------
-- Ground material under a coord
--------------------------------------------------------------------------------
function TM.Entity.GroundMaterial(coords)
    return TM.Util.Raycast.GroundMaterial(coords)
end

--------------------------------------------------------------------------------
-- Bounding-box size of any model (returns vector3 dimensions)
--------------------------------------------------------------------------------
function TM.Entity.ModelDimensions(model)
    if type(model) == 'string' then model = joaat(model) end
    local min, max = GetModelDimensions(model)
    return max - min, min, max
end

--------------------------------------------------------------------------------
-- Look at a coord (steers the player ped's heading toward a point)
--------------------------------------------------------------------------------
function TM.Entity.FacePoint(entity, coords)
    if not DoesEntityExist(entity) then return end
    local pos = GetEntityCoords(entity)
    local heading = math.deg(math.atan2(coords.y - pos.y, coords.x - pos.x)) - 90.0
    SetEntityHeading(entity, (heading + 360.0) % 360.0)
end

--==============================================================================
-- TM.DUI -- create a runtime DUI texture replacement for an entity.
--   id     = unique key
--   url    = image url
--   width  = px (default 1024)
--   height = px (default 1024)
--   txdName / txnName = override texture dictionary / name (rare)
--   Returns an opaque handle: { id, dui, txd, txn, replace, destroy }
--==============================================================================
local duis = {}

function TM.DUI.Create(opts)
    opts = opts or {}
    if not opts.id or not opts.url then
        TM.Log.warn('TM.DUI.Create requires { id, url }')
        return nil
    end
    if duis[opts.id] then duis[opts.id]:destroy() end

    local handle = {}
    handle.id     = opts.id
    handle.txd    = opts.txdName or ('tm_dui_' .. opts.id)
    handle.txn    = opts.txnName or 'preview'
    handle.width  = opts.width or 1024
    handle.height = opts.height or 1024
    handle.dui    = CreateDui(opts.url, handle.width, handle.height)
    handle.txd_h  = CreateRuntimeTxd(handle.txd)
    handle.dui_h  = GetDuiHandle(handle.dui)
    CreateRuntimeTextureFromDuiHandle(handle.txd_h, handle.txn, handle.dui_h)

    function handle.set(url) SetDuiUrl(handle.dui, url) end

    function handle.replaceModel(model)
        if type(model) == 'string' then model = joaat(model) end
        AddReplaceTexture('prop_screen_generic', 'prop_screen_generic', handle.txd, handle.txn)
        if model then
            AddReplaceTexture(GetLabelText(model) or '', '', handle.txd, handle.txn)
        end
    end

    function handle.destroy()
        if handle.dui then DestroyDui(handle.dui); handle.dui = nil end
        duis[handle.id] = nil
    end

    duis[opts.id] = handle
    return handle
end

function TM.DUI.Destroy(id)
    if duis[id] then duis[id].destroy() end
end

function TM.DUI.Set(id, url)
    if duis[id] then duis[id].set(url) end
end
