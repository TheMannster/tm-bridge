--[[
    Resource Initialization Module
    --------------------------------
    This module initializes and loads shared data (Items, Vehicles, Jobs, Gangs) from the
    various frameworks/inventory systems (OX, QB, ESX, etc.). It also corrects export names,
    caches framework exports into simple variables, and prints debug information if enabled.
]]

-------------------------------------------------------------
-- Global Variable Initialization
-------------------------------------------------------------
Items, Vehicles, Jobs, Gangs, Core = {}, nil, nil, nil, nil

-------------------------------------------------------------
-- Correct QB Inventory Export
-------------------------------------------------------------
-- Correct ps-invetory to ls-inventory if somehow you still have that
Exports.PSInv = isStarted("lj-inventory") and "lj-inventory" or Exports.PSInv

-------------------------------------------------------------
-- Framework Exports and Inventory Identifiers
-------------------------------------------------------------
OXLibExport, QBXExport, QBExport, ESXExport, OXCoreExport =
    Exports.OXLibExport or "",
    Exports.QBXExport or "",
    Exports.QBExport or "",
    Exports.ESXExport or "",
    Exports.OXCoreExport or ""

OXInv, QBInv, PSInv, QSInv, CoreInv, CodeMInv, OrigenInv, TgiannInv =
    Exports.OXInv or "",
    Exports.QBInv or "",
    Exports.PSInv or "",
    Exports.QSInv or "",
    Exports.CoreInv or "",
    Exports.CodeMInv or "",
    Exports.OrigenInv or "",
    Exports.TgiannInv or ""

RSGExport, RSGInv =
    Exports.RSGExport or "",
    Exports.RSGInv or ""

QBMenuExport = Exports.QBMenuExport or ""
QBTargetExport, OXTargetExport = Exports.QBTargetExport or "", Exports.OXTargetExport or ""

-------------------------------------------------------------
-- Debug: Print Found Exports
-------------------------------------------------------------
-- Print a list of all exports that are currently started (if debugMode is enabled).
for _, v in pairs(Exports) do
    if isStarted(v) then
        debugPrint("^6Bridge^7: '^3"..v.."^7' export found")
    end
end

OxPlayer = nil
if isStarted(OXCoreExport) then
    if not isServer() then
        OxPlayer = Ox.GetPlayer()
    end
end

-------------------------------------------------------------
-- Resource Variables for Items, Jobs, and Vehicles
-------------------------------------------------------------
local itemResource, jobResource, vehResource = "", "", ""

-------------------------------------------------------------
-- Loading Items
-------------------------------------------------------------
-- Load and compile shared items from the detected inventory system.
if isStarted(OXInv) then
    itemResource = OXInv
    Items = exports[OXInv]:Items()
    for k, v in pairs(Items) do
        if v.client and v.client.image then
            Items[k].image = (v.client.image):gsub("nui://"..OXInv.."/web/images/", "")
        else
            Items[k].image = k..".png"
        end
        Items[k].hunger = v.client and v.client.hunger or nil
        Items[k].thirst = v.client and v.client.thirst or nil
    end

elseif isStarted(QBExport) then
    itemResource = QBExport
    Core = Core or exports[QBExport]:GetCoreObject()
    Items = Core and Core.Shared.Items or nil
    CreateThread(function()
        while not Items or not next(Items) do
            Items = exports[QBExport]:GetCoreObject().Shared.Items
            Wait(1000)
        end
    end)
    if isStarted(QBExport) and not isStarted(QBXExport) then
        RegisterNetEvent('QBCore:Client:UpdateObject', function()
            Core = Core or exports[QBExport]:GetCoreObject()
            Items = Core and Core.Shared.Items or nil
        end)
    end

elseif isStarted(ESXExport) then
    itemResource = ESXExport
    CreateThread(function()
        if isServer() then
            Items = ESX.GetItems()
            while not createCallback do Wait(100) end
            createCallback(getScript()..":getItems", function(source)
                return Items
            end)
        end
        if not isServer() then
            Items = triggerCallback(getScript()..":getItems")
            debugPrint("^6Bridge^7: ^2Loading ^6"..countTable(Items).." ^3Items^2 from ^7"..itemResource)
        end
    end)

elseif isStarted(RSGExport) then
    itemResource = RSGExport
    Core = Core or exports[RSGExport]:GetCoreObject()
    Items = Core and Core.Shared.Items or nil
    RegisterNetEvent('RSGCore:Client:UpdateObject', function()
        Core = Core or exports[RSGExport]:GetCoreObject()
        Items = Core and Core.Shared.Items or nil
    end)

end

if itemResource == nil then
    print("^4ERROR^7: ^2No Item info detected ^7- ^2Check ^3starter^1.^2lua^7")
else
    while not Items do Wait(100) end
    debugPrint("^6Bridge^7: ^2Loading ^6"..countTable(Items).." ^3Items^2 from ^7"..itemResource)
end


-------------------------------------------------------------
-- Loading Vehicles
-------------------------------------------------------------
-- Compile vehicles from the detected frameworks into a unified table.
if isStarted(QBXExport) or isStarted(QBExport) then
    vehResource = QBExport
    Core = Core or exports[QBExport]:GetCoreObject()
    Vehicles = Core and Core.Shared.Vehicles
    if isStarted(QBExport) and not isStarted(QBXExport) then
        RegisterNetEvent('QBCore:Client:UpdateObject', function()
            Core = Core or exports[QBExport]:GetCoreObject()
            Vehicles = Core and Core.Shared.Vehicles
        end)
    end

elseif isStarted(OXCoreExport) then
    vehResource = OXCoreExport
    Vehicles = {}
    for k, v in pairs(Ox.GetVehicleData()) do
        Vehicles[k] = { model = k, hash = GetHashKey(k), price = v.price, name = v.name, brand = v.make }
    end

elseif isStarted(ESXExport) then
    vehResource = ESXExport
    CreateThread(function()
        if isServer() then
            createCallback(getScript()..":getVehiclesPrices", function(source)
                return Vehicles
            end)
            while not MySQL do Wait(2000) print("^1Waiting for MySQL to exist") end
            Vehicles = MySQL.query.await('SELECT model, price, name FROM vehicles')
        end
        if not isServer() then
            --while not triggerCallback do print("waiting") Wait(100) end
            local TempVehicles = triggerCallback(getScript()..":getVehiclesPrices")
            for _, v in pairs(TempVehicles) do
                Vehicles = Vehicles or {}
                Vehicles[v.model] = {
                    model = v.model,
                    hash = GetHashKey(v.model),
                    price = v.price,
                    name = v.name,
                    brand = GetMakeNameFromVehicleModel(v.model):lower():gsub("^%l", string.upper)
                }
            end
        end
    end)

elseif isStarted(RSGExport) then
    vehResource = RSGExport
    Core = Core or exports[RSGExport]:GetCoreObject()
    Vehicles = Core and Core.Shared.Vehicles
    RegisterNetEvent('RSGCore:Client:UpdateObject', function()
        Core = Core or exports[RSGExport]:GetCoreObject()
        Vehicles = Core and Core.Shared.Vehicles
    end)
end
if vehResource == nil then
    print("^4ERROR^7: ^2No Vehicle info detected ^7- ^2Check ^3starter^1.^2lua^7")
else
    while not Vehicles do Wait(1000) end
    debugPrint("^6Bridge^7: ^2Loading ^6"..countTable(Vehicles).." ^3Vehicles^2 from ^7"..vehResource)
end

-------------------------------------------------------------
-- Loading Jobs and Gangs
-------------------------------------------------------------
-- Compile jobs and gangs from the detected framework.
if isStarted(QBXExport) then
    jobResource = QBXExport
    Core = Core or exports[QBExport]:GetCoreObject()
    Jobs, Gangs = exports[QBXExport]:GetJobs(), exports[QBXExport]:GetGangs()

elseif isStarted(OXCoreExport) then
    jobResource = OXExport
    CreateThread(function()
        if isServer() then
            createCallback(getScript()..":getOxGroups", function(source)
                Jobs = MySQL.query.await('SELECT * FROM `ox_groups`')
                return Jobs
            end)
        else
            local TempJobs = triggerCallback(getScript()..":getOxGroups")
            Jobs = {}
            for k, v in pairs(TempJobs) do
                local grades = {}
                --for i = 1, #v.grades do
                --    grades[i] = { name = v.grades[i], isboss = (i == #v.grades) }
                --end
                Jobs[v.name] = { label = v.label, grades = grades }
            end
            Gangs = Jobs
        end
    end)

elseif isStarted(QBExport) then
    jobResource = QBExport
    Core = Core or exports[QBExport]:GetCoreObject()
    Jobs, Gangs = Core.Shared.Jobs, Core.Shared.Gangs
    if isStarted(QBExport) and not isStarted(QBXExport) then
        RegisterNetEvent('QBCore:Client:UpdateObject', function()
            Core = exports[QBExport]:GetCoreObject()
            Jobs, Gangs = Core.Shared.Jobs, Core.Shared.Gangs
        end)
    end

elseif isStarted(ESXExport) then
    jobResource = ESXExport
    if isServer() then
        -- If server, create callback to get jobs
        createCallback(getScript()..":getESXJobs", function(source)
            return Jobs
        end)
        -- Populate jobs table with ESX.GetJobs()
        Jobs = ESX.GetJobs()
        --jsonPrint(Jobs)
        --If retreived jobs is empty, wait for ESX to load
        while countTable(Jobs) == 0 do
            Jobs = ESX.GetJobs()
            Wait(100)
        end
        -- Organise into a table the script can use
        for Role, Grades in pairs(Jobs) do

            -- Check for "Boss" in name of grades
            for grade, info in pairs(Grades.grades) do
                --print(grade)
                --jsonPrint(info)

                if info.label then
                    --print(info)
                    if info.label:find("boss") or info.label:find("Boss") then
                        --print("Found Boss label for:", Grades.label)
                        Jobs[Role].grades[grade].isBoss = true
                        goto continue
                    end
                end
            end

            -- If no roles with "boss" in the name, revert to max grade

            -- Count grades
            local count = countTable(Grades.grades)
            Jobs[Role].grades[tostring(count-1)].isBoss = true
            --print(Grades.label.." Grade: "..count.." is Boss")
            ::continue::
        end
        -- ESX Default doesn't have gangs, so copy jobs to gangs
        Gangs = Jobs
    end
    -- If client side, trigger callback to get jobs
    if not isServer() then
        Jobs = triggerCallback(getScript()..":getESXJobs")
        Gangs = Jobs
    end

elseif isStarted(RSGExport) then
    jobResource = RSGExport
    Core = Core or exports[RSGExport]:GetCoreObject()
    Jobs, Gangs = Core.Shared.Jobs, Core.Shared.Gangs
    RegisterNetEvent('RSGCore:Client:UpdateObject', function()
        Core = exports[RSGExport]:GetCoreObject()
        Jobs, Gangs = Core.Shared.Jobs, Core.Shared.Gangs
    end)
end

if jobResource == nil then
    print("^4ERROR^7: ^2No Vehicle info detected ^7- ^2Check ^3starter^1.^2lua^7")
else
    while not Jobs do Wait(1000) end
    debugPrint("^6Bridge^7: ^2Loading ^6"..countTable(Jobs).." ^3Jobs^2 from ^7"..jobResource)
    debugPrint("^6Bridge^7: ^2Loading ^6"..countTable(Gangs).." ^3Gangs^2 from ^7"..jobResource)
end