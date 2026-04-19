--==============================================================================
--  tm-bridge :: shared/vehicle.lua
--  TM.Vehicle -- closest lookup, properties, plate, network ownership push.
--  Uses ox_lib's GetVehicleProperties when available, otherwise the framework's
--  built-in helpers.
--==============================================================================

TM.Vehicle = {}

if TM.Server then return end

--------------------------------------------------------------------------------
-- Closest vehicle to a coord (or to the player if omitted)
--------------------------------------------------------------------------------
function TM.Vehicle.Closest(coords, radius)
    coords = coords or GetEntityCoords(PlayerPedId())
    radius = radius or 5.0
    local handle, entity = FindFirstVehicle()
    local best, bestDist = 0, radius
    repeat
        local pos = GetEntityCoords(entity)
        local d = #(pos - coords)
        if d < bestDist then best, bestDist = entity, d end
        local ok, next = FindNextVehicle(handle)
        if not ok then break end
        entity = next
    until false
    EndFindVehicle(handle)
    return best, bestDist
end

--------------------------------------------------------------------------------
-- Plate (trimmed)
--------------------------------------------------------------------------------
function TM.Vehicle.Plate(vehicle)
    if not DoesEntityExist(vehicle) then return nil end
    return (GetVehicleNumberPlateText(vehicle) or ''):gsub('%s+', '')
end

--------------------------------------------------------------------------------
-- Properties get/set (ox_lib first, then qb/esx natives)
--------------------------------------------------------------------------------
function TM.Vehicle.GetProperties(vehicle)
    if TM.HasResource(TM.Exports.oxLib) then
        return exports[TM.Exports.oxLib]:GetVehicleProperties(vehicle)
    end
    if TM.Framework.name == 'qbcore' or TM.Framework.name == 'qbox' then
        local QB = TM.Framework.Object()
        if QB and QB.Functions and QB.Functions.GetVehicleProperties then
            return QB.Functions.GetVehicleProperties(vehicle)
        end
    end
    if TM.Framework.name == 'esx' then
        local ESX = TM.Framework.Object()
        if ESX and ESX.Game and ESX.Game.GetVehicleProperties then
            return ESX.Game.GetVehicleProperties(vehicle)
        end
    end
    return nil
end

function TM.Vehicle.SetProperties(vehicle, props)
    if not props then return end
    if TM.HasResource(TM.Exports.oxLib) then
        return exports[TM.Exports.oxLib]:SetVehicleProperties(vehicle, props)
    end
    if TM.Framework.name == 'qbcore' or TM.Framework.name == 'qbox' then
        local QB = TM.Framework.Object()
        if QB and QB.Functions and QB.Functions.SetVehicleProperties then
            return QB.Functions.SetVehicleProperties(vehicle, props)
        end
    end
    if TM.Framework.name == 'esx' then
        local ESX = TM.Framework.Object()
        if ESX and ESX.Game and ESX.Game.SetVehicleProperties then
            return ESX.Game.SetVehicleProperties(vehicle, props)
        end
    end
end

--------------------------------------------------------------------------------
-- Push net control (force the local client to take ownership of the entity)
--------------------------------------------------------------------------------
function TM.Vehicle.RequestControl(entity, timeoutMs)
    if NetworkHasControlOfEntity(entity) then return true end
    timeoutMs = timeoutMs or 1500
    local deadline = GetGameTimer() + timeoutMs
    while not NetworkHasControlOfEntity(entity) do
        NetworkRequestControlOfEntity(entity)
        Wait(50)
        if GetGameTimer() > deadline then return false end
    end
    return true
end

--------------------------------------------------------------------------------
-- Quick info dump (used by /carinfo style commands)
--------------------------------------------------------------------------------
function TM.Vehicle.Info(vehicle)
    if not DoesEntityExist(vehicle) then return nil end
    return {
        plate    = TM.Vehicle.Plate(vehicle),
        model    = GetEntityModel(vehicle),
        netId    = NetworkGetNetworkIdFromEntity(vehicle),
        coords   = GetEntityCoords(vehicle),
        heading  = GetEntityHeading(vehicle),
        engine   = GetVehicleEngineHealth(vehicle),
        body     = GetVehicleBodyHealth(vehicle),
        fuel     = GetVehicleFuelLevel(vehicle),
    }
end
