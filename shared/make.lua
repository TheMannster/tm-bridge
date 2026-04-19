--==============================================================================
--  tm-bridge :: shared/make.lua
--  TM.Make.* -- factories for runtime entities (peds, props, vehicles, blips,
--  cameras), each with a "distance-spawned" variant that automatically deletes
--  itself when the player walks away.
--==============================================================================

TM.Make = {}

if TM.Server then return end

--==============================================================================
-- PED
--   spec = { model, coords, heading=0, scenario=nil, animDict=nil, animName=nil,
--            invincible=true, freeze=true, blockEvents=true, scale=nil }
--==============================================================================
function TM.Make.Ped(spec)
    spec = spec or {}
    if not TM.Asset.Model(spec.model) then return 0 end
    local model = type(spec.model) == 'string' and joaat(spec.model) or spec.model
    local c = spec.coords
    local ped = CreatePed(0, model, c.x, c.y, c.z - 1.0, spec.heading or 0.0, false, false)
    if spec.invincible ~= false then SetEntityInvincible(ped, true) end
    if spec.freeze     ~= false then FreezeEntityPosition(ped, true) end
    if spec.blockEvents ~= false then SetBlockingOfNonTemporaryEvents(ped, true) end
    if spec.scale then TM.Entity.SetScale(ped, spec.scale) end
    if spec.scenario then TaskStartScenarioInPlace(ped, spec.scenario, 0, true) end
    if spec.animDict and spec.animName then
        TM.Anim.Play({ ped = ped, dict = spec.animDict, name = spec.animName, flag = 49 })
    end
    TM.Asset.UnloadModel(model)
    return ped
end

--  Distance-aware ped: spawns when the player is within `radius`, deletes when
--  they leave 1.5x that radius.  Returns a handle with :destroy().
function TM.Make.DistPed(spec)
    spec = spec or {}
    local radius = spec.radius or 50.0
    local handle = { ped = 0, alive = true }

    CreateThread(function()
        while handle.alive do
            local d = #(GetEntityCoords(PlayerPedId()) - spec.coords)
            if d <= radius and handle.ped == 0 then handle.ped = TM.Make.Ped(spec) end
            if d > radius * 1.5 and handle.ped ~= 0 then DeleteEntity(handle.ped); handle.ped = 0 end
            Wait(handle.ped == 0 and 1500 or 5000)
        end
        if handle.ped ~= 0 then DeleteEntity(handle.ped) end
    end)

    function handle:destroy() handle.alive = false end
    return handle
end

--==============================================================================
-- PROP
--==============================================================================
function TM.Make.Prop(spec)
    spec = spec or {}
    if not TM.Asset.Model(spec.model) then return 0 end
    local model = type(spec.model) == 'string' and joaat(spec.model) or spec.model
    local c = spec.coords
    local obj = CreateObject(model, c.x, c.y, c.z, spec.networked == true, false, false)
    SetEntityHeading(obj, spec.heading or 0.0)
    if spec.placeOnGround then PlaceObjectOnGroundProperly(obj) end
    if spec.freeze ~= false then FreezeEntityPosition(obj, true) end
    if spec.scale then TM.Entity.SetScale(obj, spec.scale) end
    TM.Asset.UnloadModel(model)
    return obj
end

function TM.Make.DistProp(spec)
    spec = spec or {}
    local radius = spec.radius or 50.0
    local handle = { obj = 0, alive = true }
    CreateThread(function()
        while handle.alive do
            local d = #(GetEntityCoords(PlayerPedId()) - spec.coords)
            if d <= radius and handle.obj == 0 then handle.obj = TM.Make.Prop(spec) end
            if d > radius * 1.5 and handle.obj ~= 0 then DeleteEntity(handle.obj); handle.obj = 0 end
            Wait(handle.obj == 0 and 1500 or 5000)
        end
        if handle.obj ~= 0 then DeleteEntity(handle.obj) end
    end)
    function handle:destroy() handle.alive = false end
    return handle
end

function TM.Make.DestroyProp(obj)
    if obj and obj ~= 0 and DoesEntityExist(obj) then DeleteEntity(obj) end
end

--==============================================================================
-- VEHICLE
--==============================================================================
function TM.Make.Vehicle(spec)
    spec = spec or {}
    if not TM.Asset.Model(spec.model) then return 0 end
    local model = type(spec.model) == 'string' and joaat(spec.model) or spec.model
    local c = spec.coords
    local veh = CreateVehicle(model, c.x, c.y, c.z, spec.heading or 0.0,
                              spec.networked ~= false, spec.scriptHost == true)
    if spec.plate then SetVehicleNumberPlateText(veh, spec.plate) end
    if spec.colour then SetVehicleColours(veh, spec.colour[1] or 0, spec.colour[2] or 0) end
    if spec.engineOff then SetVehicleEngineOn(veh, false, true, true) end
    TM.Asset.UnloadModel(model)
    return veh
end

function TM.Make.DistVehicle(spec)
    spec = spec or {}
    local radius = spec.radius or 100.0
    local handle = { veh = 0, alive = true }
    CreateThread(function()
        while handle.alive do
            local d = #(GetEntityCoords(PlayerPedId()) - spec.coords)
            if d <= radius and handle.veh == 0 then handle.veh = TM.Make.Vehicle(spec) end
            if d > radius * 1.5 and handle.veh ~= 0 then DeleteEntity(handle.veh); handle.veh = 0 end
            Wait(handle.veh == 0 and 2000 or 6000)
        end
        if handle.veh ~= 0 then DeleteEntity(handle.veh) end
    end)
    function handle:destroy() handle.alive = false end
    return handle
end

function TM.Make.DeleteVehicle(veh)
    if veh and veh ~= 0 and DoesEntityExist(veh) then
        SetEntityAsMissionEntity(veh, true, true)
        DeleteVehicle(veh)
    end
end

--==============================================================================
-- BLIP
--   spec = { coords, sprite=1, colour=2, scale=0.8, label='', shortRange=true }
--==============================================================================
function TM.Make.Blip(spec)
    spec = spec or {}
    local c = spec.coords
    local blip = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipSprite(blip, spec.sprite or 1)
    SetBlipColour(blip, spec.colour or 2)
    SetBlipScale(blip, spec.scale or 0.8)
    SetBlipAsShortRange(blip, spec.shortRange ~= false)
    if spec.label and spec.label ~= '' then
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(spec.label)
        EndTextCommandSetBlipName(blip)
    end
    return blip
end

function TM.Make.EntityBlip(entity, spec)
    spec = spec or {}
    local blip = AddBlipForEntity(entity)
    SetBlipSprite(blip, spec.sprite or 1)
    SetBlipColour(blip, spec.colour or 2)
    SetBlipScale(blip, spec.scale or 0.8)
    if spec.label and spec.label ~= '' then
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(spec.label)
        EndTextCommandSetBlipName(blip)
    end
    return blip
end

function TM.Make.RemoveBlip(blip)
    if blip and DoesBlipExist(blip) then RemoveBlip(blip) end
end

--==============================================================================
-- CAMERA -- temporary scripted cam, mainly for crafting / barber
--==============================================================================
TM.Make.Cam = {}

function TM.Make.Cam.Create(coords, lookAt, fov)
    local cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA',
        coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, fov or 50.0, false, 0)
    if lookAt then PointCamAtCoord(cam, lookAt.x, lookAt.y, lookAt.z) end
    return cam
end

function TM.Make.Cam.Start(cam, fadeMs)
    if not DoesCamExist(cam) then return end
    SetCamActive(cam, true)
    RenderScriptCams(true, true, fadeMs or 800, true, true)
end

function TM.Make.Cam.Stop(cam, fadeMs)
    RenderScriptCams(false, true, fadeMs or 800, true, true)
    if cam and DoesCamExist(cam) then DestroyCam(cam, false) end
end
