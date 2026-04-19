--==============================================================================
--  tm-bridge :: shared/player.lua
--  TM.Player -- thin cross-framework wrapper around player data lookups.
--  Both client and server may call most functions; the server flavour expects
--  a server id, the client one operates on the local player.
--==============================================================================

TM.Player = {}

--------------------------------------------------------------------------------
-- Internal: fetch the framework's "player object" for src
--------------------------------------------------------------------------------
local function fwGetPlayer(src)
    local fw = TM.Framework.name
    local obj = TM.Framework.Object()
    if not obj then return nil end

    if fw == 'qbcore' or fw == 'qbox' then
        if TM.Server then return obj.Functions and obj.Functions.GetPlayer and obj.Functions.GetPlayer(src) end
        return obj.Functions and obj.Functions.GetPlayerData and obj.Functions.GetPlayerData()
    end
    if fw == 'esx' then
        if TM.Server then return obj.GetPlayerFromId and obj.GetPlayerFromId(src) end
        return obj.GetPlayerData and obj.GetPlayerData()
    end
    if fw == 'oxcore' then
        if TM.Server then return obj:GetPlayer(src) end
        return obj.GetPlayerData and obj.GetPlayerData() or nil
    end
    if fw == 'rsg' then
        if TM.Server then return obj.Functions and obj.Functions.GetPlayer and obj.Functions.GetPlayer(src) end
        return obj.Functions and obj.Functions.GetPlayerData and obj.Functions.GetPlayerData()
    end
    return nil
end

--------------------------------------------------------------------------------
-- Public: raw player object (escape hatch)
--------------------------------------------------------------------------------
function TM.Player.Get(src)
    return fwGetPlayer(src)
end

--------------------------------------------------------------------------------
-- Normalised data table.  Always returns the same keys regardless of framework.
--   { source, citizenid, name, job = { name, label, grade, onduty, isboss },
--     gang = {...}, money = { cash, bank }, charinfo = { firstname, lastname, ... } }
--------------------------------------------------------------------------------
function TM.Player.Data(src)
    local p = fwGetPlayer(src)
    if not p then return nil end
    local fw = TM.Framework.name

    local out = { source = src or (TM.Client and GetPlayerServerId(PlayerId())) }

    if fw == 'qbcore' or fw == 'qbox' or fw == 'rsg' then
        local d = p.PlayerData or p
        out.citizenid = d.citizenid
        out.name      = (d.charinfo and (d.charinfo.firstname .. ' ' .. d.charinfo.lastname)) or d.name
        out.charinfo  = d.charinfo
        out.money     = { cash = d.money and d.money.cash or 0, bank = d.money and d.money.bank or 0 }
        out.job       = d.job and { name = d.job.name, label = d.job.label,
                                    grade = d.job.grade and d.job.grade.level or 0,
                                    onduty = d.job.onduty, isboss = d.job.isboss }
        out.gang      = d.gang and { name = d.gang.name, label = d.gang.label,
                                     grade = d.gang.grade and d.gang.grade.level or 0,
                                     isboss = d.gang.isboss }
    elseif fw == 'esx' then
        out.citizenid = p.identifier
        out.name      = p.getName and p:getName() or (p.name or '')
        out.money     = { cash = (p.getMoney and p:getMoney()) or 0,
                          bank = (p.getAccount and p:getAccount('bank') and p:getAccount('bank').money) or 0 }
        out.job       = p.job and { name = p.job.name, label = p.job.label, grade = p.job.grade, onduty = true }
    elseif fw == 'oxcore' then
        out.citizenid = p.charId or p.userId
        out.name      = p.firstName and (p.firstName .. ' ' .. (p.lastName or '')) or p.name
        out.money     = { cash = (exports.ox_inventory and exports.ox_inventory:GetItemCount(src, 'money')) or 0 }
        out.job       = p.get and { name = p:get('group') } or nil
    end

    return out
end

--------------------------------------------------------------------------------
-- Identifier (citizenid / identifier / charId)
--------------------------------------------------------------------------------
function TM.Player.Identifier(src)
    local d = TM.Player.Data(src)
    return d and d.citizenid or nil
end

--------------------------------------------------------------------------------
-- Login helpers
--------------------------------------------------------------------------------
function TM.Player.IsLoggedIn(src)
    if TM.Client then return TM.Resource.IsPlayerLoaded() end
    return TM.Player.Get(src) ~= nil
end

--------------------------------------------------------------------------------
-- Client-only convenience helpers
--------------------------------------------------------------------------------
if TM.Client then
    function TM.Player.Ped()      return PlayerPedId() end
    function TM.Player.Coords()   return GetEntityCoords(PlayerPedId()) end
    function TM.Player.Heading()  return GetEntityHeading(PlayerPedId()) end
    function TM.Player.Vehicle(includeLastVeh)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 then return veh end
        if includeLastVeh then return GetVehiclePedIsIn(ped, true) end
        return 0
    end
    function TM.Player.IsInVehicle()       return TM.Player.Vehicle() ~= 0 end
    function TM.Player.IsInWater()         return IsEntityInWater(PlayerPedId()) end
    function TM.Player.NearbyPlayers(radius)
        radius = radius or 5.0
        local me = PlayerPedId()
        local mc = GetEntityCoords(me)
        local out = {}
        for _, pid in ipairs(GetActivePlayers()) do
            local ped = GetPlayerPed(pid)
            if ped ~= me and DoesEntityExist(ped) then
                local d = #(GetEntityCoords(ped) - mc)
                if d <= radius then
                    out[#out + 1] = { id = pid, server = GetPlayerServerId(pid), ped = ped, distance = d }
                end
            end
        end
        return out
    end
end

--------------------------------------------------------------------------------
-- Server-only convenience helpers
--------------------------------------------------------------------------------
if TM.Server then
    function TM.Player.Source(citizenid)
        for _, src in ipairs(GetPlayers()) do
            local d = TM.Player.Data(tonumber(src))
            if d and d.citizenid == citizenid then return tonumber(src) end
        end
        return nil
    end

    function TM.Player.All()
        local out = {}
        for _, src in ipairs(GetPlayers()) do
            local d = TM.Player.Data(tonumber(src))
            if d then out[#out + 1] = d end
        end
        return out
    end

    function TM.Player.NearbyPlayers(coords, radius)
        radius = radius or 5.0
        local out = {}
        for _, src in ipairs(GetPlayers()) do
            local ped = GetPlayerPed(src)
            if DoesEntityExist(ped) then
                local d = #(GetEntityCoords(ped) - coords)
                if d <= radius then
                    out[#out + 1] = { source = tonumber(src), distance = d, coords = GetEntityCoords(ped) }
                end
            end
        end
        return out
    end
end
