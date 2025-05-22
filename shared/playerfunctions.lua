--[[
    Player Utility & Server Event Handlers Module
    ------------------------------------------------
    This module provides utility functions for:
      • Locking/unlocking the player's inventory.
      • Instantly turning or gradually turning the player to face a target.
      • Handling player needs (thirst and hunger) via server events.
      • Charging/funding players (money removal/addition).
      • Processing item consumption and applying effects.
      • Checking player job/gang roles and retrieving player information.
      • Getting active players near a coordinate.
]]

-------------------------------------------------------------
-- Player Movement
-------------------------------------------------------------

--- Instantly turns an entity to face a target (entity or coordinates) without animation.
---
--- @param ent number|nil The Ped to turn (defaults to player's Ped if nil).
--- @param ent2 number|vector3|nil The target entity or coordinates to face.
---
--- @usage
--- ```lua
--- instantLookEnt(nil, vector3(200.0, 300.0, 40.0))
--- instantLookEnt(ped1, ped2)
--- ```
function instantLookEnt(ent, ent2)
    local ped = ent or PlayerPedId()
    local p1 = GetEntityCoords(ped, true)
    local p2 = type(ent2) == "vector3" and ent2 or GetEntityCoords(ent2, true)

    local dx = p2.x - p1.x
    local dy = p2.y - p1.y
    local heading = GetHeadingFromVector_2d(dx, dy)

    debugPrint("^6Bridge^7: ^1Forced ^2Turning Player to^7: '^6"..formatCoord(p2).."^7'")
    SetEntityHeading(ped, heading)
end

--- Makes the player look towards a specific target with an animated turn.
---
--- If the player is not already facing the target (entity or coordinates), a turning animation is triggered.
---
--- @param entity number|vector3|vector4|nil The target to look at.
---
--- @usage
--- ```lua
--- lookEnt(vector3(200.0, 300.0, 40.0))
--- lookEnt(pedEntity)
--- ```
function lookEnt(entity)
    local ped = PlayerPedId()
    if entity then
        if type(entity) == "vector3" or type(entity) == "vector4" then
            if not IsPedHeadingTowardsPosition(ped, entity.xyz, 30.0) then
                TaskTurnPedToFaceCoord(ped, entity.xyz, 1500)
                debugPrint("^6Bridge^7: ^2Turning Player to^7: '^6"..formatCoord(entity).."^7'")
                Wait(1500)
            end
        else
            if DoesEntityExist(entity) then
                local entCoords = GetEntityCoords(entity)
                if not IsPedHeadingTowardsPosition(ped, entCoords, 30.0) then
                    TaskTurnPedToFaceCoord(ped, entCoords, 1500)
                    debugPrint("^6Bridge^7: ^2Turning Player to^7: '^6"..entity.."^7' - '"..formatCoord(entCoords).."^7'")
                    Wait(1500)
                end
            end
        end
    end
end

-------------------------------------------------------------
-- Server Event Handlers for Needs
-------------------------------------------------------------

--- Server event handler for urinal usage.
--- Decreases player's thirst by a random amount.
RegisterNetEvent(Utils.Helpers.getScript()..":server:Urinal", function()
    local src = source
    local Player = getPlayer(src)
    local thirstamt = math.random(10, 30)
    local thirst = Player.thirst - thirstamt
    setThirst(src, getPlayer(src).thirst - thirst)
end)

--- Server event handler for setting player needs (thirst or hunger).
---
--- @event
--- @param type string "thirst" or "hunger".
--- @param amount number New value to set.
RegisterNetEvent(Utils.Helpers.getScript()..":server:setNeed", function(needType, amount)
    local src = source
    if needType == "thirst" then
        setThirst(src, amount)
    elseif needType == "hunger" then
        setHunger(src, amount)
    end
end)

--- Sets the player's thirst level.
---
--- @param src number The player's server ID.
--- @param thirst number The new thirst level.
---
--- @usage
--- ```lua
--- setThirst(playerId, 80)
--- ```
function setThirst(src, thirst)
    if Utils.Helpers.isStarted(ESXExport) then
        TriggerClientEvent('esx_status:add', src, 'thirst', thirst)

    elseif Utils.Helpers.isStarted(QBExport) or Utils.Helpers.isStarted(QBXExport) then
        local Player = Core.Functions.GetPlayer(src)
        Player.Functions.SetMetaData('thirst', thirst)
        TriggerClientEvent("hud:client:UpdateNeeds", src, thirst, Player.PlayerData.metadata.thirst)

    elseif Utils.Helpers.isStarted(RSGExport) then
        local Player = Core.Functions.GetPlayer(src)
        Player.Functions.SetMetaData('thirst', thirst)
        TriggerClientEvent("hud:client:UpdateNeeds", src, thirst, Player.PlayerData.metadata.thirst)
    end
end

--- Sets the player's hunger level.
---
--- @param src number The player's server ID.
--- @param hunger number The new hunger level.
---
--- @usage
--- ```lua
--- setHunger(playerId, 60)
--- ```
function setHunger(src, hunger)
    if Utils.Helpers.isStarted(ESXExport) then
        TriggerClientEvent('esx_status:add', src, 'hunger', hunger)

    elseif Utils.Helpers.isStarted(QBExport) or Utils.Helpers.isStarted(QBXExport) then
        local Player = Core.Functions.GetPlayer(src)
        Player.Functions.SetMetaData('hunger', hunger)
        TriggerClientEvent("hud:client:UpdateNeeds", src, hunger, Player.PlayerData.metadata.hunger)

    elseif Utils.Helpers.isStarted(RSGExport) then
        local Player = Core.Functions.GetPlayer(src)
        Player.Functions.SetMetaData('hunger', hunger)
        TriggerClientEvent("hud:client:UpdateNeeds", src, hunger, Player.PlayerData.metadata.hunger)
    end
end

-------------------------------------------------------------
-- Economy Event Handlers
-------------------------------------------------------------

--- Charges a player by removing money from their account.
---
--- @param cost number The amount to charge.
--- @param type string "cash" or "bank".
--- @param newsrc number|nil Optional player ID; defaults to event source.
---
--- @usage
--- ```lua
--- chargePlayer(100, "cash", playerId)
--- ```
function chargePlayer(cost, moneyType, newsrc)
    local src = newsrc or source
    local fundResource = ""
    if cost < 0 then
        debugPrint("^1Error^7: ^7SRC: ^3"..src.." ^2Tried to charge a minus value^7", cost)
        return
    end
    if moneyType == "cash" then
        if Utils.Helpers.isStarted(OXInv) then fundResource = OXInv
            exports[OXInv]:RemoveItem(src, "money", cost)

        elseif Utils.Helpers.isStarted(QBExport) or Utils.Helpers.isStarted(QBXExport) then
            fundResource = QBExport
            Core.Functions.GetPlayer(src).Functions.RemoveMoney("cash", cost)

        elseif Utils.Helpers.isStarted(RSGExport) then
            fundResource = RSGExport
            Core.Functions.GetPlayer(src).Functions.RemoveMoney("cash", cost)

        elseif Utils.Helpers.isStarted(ESXExport) then
            fundResource = ESXExport
            ESX.GetPlayerFromId(src).removeMoney(cost, "")

        end
    elseif moneyType == "bank" then
        if Utils.Helpers.isStarted(QBExport) or Utils.Helpers.isStarted(QBXExport) then
            fundResource = QBExport
            Core.Functions.GetPlayer(src).Functions.RemoveMoney("bank", cost)

        elseif Utils.Helpers.isStarted(RSGExport) then
            fundResource = RSGExport
            Core.Functions.GetPlayer(src).Functions.RemoveMoney("bank", cost)

        elseif Utils.Helpers.isStarted(ESXExport) then
            fundResource = ESXExport
            ESX.GetPlayerFromId(src).removeMoney(cost, "")
        end
    end

    if fundResource == "" then
        print("Cannot charge player - check starter.lua")
    else
        debugPrint("^6Bridge^7: ^2Charging ^2Player^7: '^6"..cost.."^7'", moneyType, fundResource)
    end
end
RegisterNetEvent(Utils.Helpers.getScript()..":server:ChargePlayer", function(cost, moneyType, newsrc)
    debugPrint(GetInvokingResource())
	if GetInvokingResource() and GetInvokingResource() ~= Utils.Helpers.getScript() and GetInvokingResource() ~= "qb-core" then
        debugPrint("^1Error^7: ^1Possible exploit^7, ^1vital function was called from an external resource^7")
        return
    end
    chargePlayer(cost, moneyType, newsrc)
end)

--- Funds a player by adding money to their account.
---
--- @param fund number The amount to add.
--- @param type string "cash" or "bank".
--- @param newsrc number|nil Optional player ID; defaults to event source.
---
--- @usage
--- ```lua
--- fundPlayer(150, "cash", playerId)
--- ```
function fundPlayer(fund, moneyType, newsrc)
    local src = newsrc or source
    local fundResource = ""

    if moneyType == "cash" then
        if Utils.Helpers.isStarted(OXInv) then
            fundResource = OXInv
            exports[OXInv]:AddItem(src, "money", fund)

        elseif Utils.Helpers.isStarted(QBExport) or Utils.Helpers.isStarted(QBXExport) then
            fundResource = QBExport
            Core.Functions.GetPlayer(src).Functions.AddMoney("cash", fund)

        elseif Utils.Helpers.isStarted(RSGExport) then
            fundResource = RSGExport
            Core.Functions.GetPlayer(src).Functions.AddMoney("cash", fund)

        elseif Utils.Helpers.isStarted(ESXExport) then
            fundResource = ESXExport
            ESX.GetPlayerFromId(src).addMoney(fund, "")

        end
    elseif moneyType == "bank" then
        if Utils.Helpers.isStarted(QBExport) or Utils.Helpers.isStarted(QBXExport) then
            fundResource = QBExport
            Core.Functions.GetPlayer(src).Functions.AddMoney("bank", fund)

        elseif Utils.Helpers.isStarted(RSGExport) then
            fundResource = RSGExport
            Core.Functions.GetPlayer(src).Functions.AddMoney("bank", fund)

        elseif Utils.Helpers.isStarted(ESXExport) then
            fundResource = ESXExport
            ESX.GetPlayerFromId(src).addMoney(fund, "")
        end
    end

    if fundResource == "" then
        print("Cannot fund player - check starter.lua")
    else
        debugPrint("^6Bridge^7: ^2Funding Player: '^2"..fund.."^7'", moneyType, fundResource)
    end
end

-------------------------------------------------------------
-- Item Consumption & Effects
-------------------------------------------------------------

--- Handles successful consumption of an item.
---
--- Plays a consumption animation, removes the item, updates player needs, handles alcohol effects,
--- and checks for random rewards.
---
--- @param itemName string The name of the consumed item.
--- @param type string The category of the item (e.g., "alcohol").
--- @param data table Additional data (e.g., hunger and thirst values).
---
--- @usage
--- ```lua
--- -- Player consumes a health pack
--- ConsumeSuccess("health_pack", "health")
---
--- -- Player consumes an alcohol drink
--- ConsumeSuccess("beer", "alcohol")
--- ```
function ConsumeSuccess(itemName, type, data)
    local hunger = data and data.hunger or Items[itemName].hunger
    local thirst = data and data.thirst or Items[itemName].thirst

    ExecuteCommand("e c")
    removeItem(itemName, 1)

    if Utils.Helpers.isStarted(ESXExport) then
        if hunger then
            TriggerServerEvent(Utils.Helpers.getScript()..":server:setNeed", "hunger", tonumber(hunger) * 10000)
        end
        if thirst then
            TriggerServerEvent(Utils.Helpers.getScript()..":server:setNeed", "thirst", tonumber(thirst) * 10000)
        end
    else
        if hunger then
            TriggerServerEvent(Utils.Helpers.getScript()..":server:setNeed", "hunger", Core.Functions.GetPlayerData().metadata["hunger"] + tonumber(hunger))
        end
        if thirst then
            TriggerServerEvent(Utils.Helpers.getScript()..":server:setNeed", "thirst", Core.Functions.GetPlayerData().metadata["thirst"] + tonumber(thirst))
        end
    end

    if type == "alcohol" then
        alcoholCount = (alcoholCount or 0) + 1
        if alcoholCount > 1 and alcoholCount < 4 then
            TriggerEvent("evidence:client:SetStatus", "alcohol", 200)
        elseif alcoholCount >= 4 then
            TriggerEvent("evidence:client:SetStatus", "heavyalcohol", 200)
            AlienEffect()
        end
    end

    if Config.Reward then
        getRandomReward(itemName)
    end
end

-------------------------------------------------------------
-- Player Job & Information Utilities
-------------------------------------------------------------

--- Checks if a player has a specific job or gang (and optionally meets a minimum grade).
---
--- @param job string The job or gang name to check.
--- @param source number|nil Optional player source; if nil, checks current player.
--- @param grade number|nil Optional minimum grade level.
--- @return boolean, boolean boolean Returns true and duty status if the check passes; false otherwise.
---
--- @usage
--- ```lua
--- -- Check if the player has the 'police' job and is on duty
--- local hasPoliceJob, isOnDuty = hasJob("police")
--- if hasPoliceJob and isOnDuty then
---     -- Grant access to police-specific features
--- end
---
--- -- Check if a specific player has the 'gang_leader' job with at least grade 2
--- local hasGangLeaderJob, _ = hasJob("gang_leader", playerId, 2)
--- if hasGangLeaderJob then
---     -- Allow gang leader actions
--- end
--- ```
function hasJob(job, source, grade)
    local hasJobFlag, duty = false, true
    if source then
        local src = tonumber(source)
        if not src then 
            if Config.System and Config.System.ServerDebugMode then
                print(tostring(source).." is not a valid player source") 
            end
        end
        if Config.System and Config.System.ServerDebugMode then
            print(string.format("--- TM-BRIDGE: SERVER hasJob CALLED for source %s ---", tostring(src)))
            print(string.format("--- TM-BRIDGE: SERVER Config.Framework Type: %s, Value: %s ---", type(Config.Framework), tostring(Config.Framework)))
            print(string.format("--- TM-BRIDGE: SERVER Utils.Helpers.isStarted(QBExport)(\"%s\"): %s ---", Exports.QBFrameWork, tostring(Utils.Helpers.isStarted(Exports.QBFrameWork))))
            print(string.format("--- TM-BRIDGE: SERVER Utils.Helpers.isStarted(QBXExport)(\"%s\"): %s ---", Exports.QBXFrameWork, tostring(Utils.Helpers.isStarted(Exports.QBXFrameWork))))
            print(string.format("--- TM-BRIDGE: SERVER Utils.Helpers.isStarted(ESXExport)(\"%s\"): %s ---", Exports.ESXFrameWork, tostring(Utils.Helpers.isStarted(Exports.ESXFrameWork))))
        end

        if Utils.Helpers.isStarted(Exports.ESXFrameWork) then -- Check 1 (ESXExport is "es_extended")
            local info = ESX.GetPlayerFromId(src).job
            while not info do
                info = ESX.GetPlayerData(src).job
                Wait(100)
            end
            if info.name == job then hasJobFlag = true end

        elseif Utils.Helpers.isStarted(Exports.QBFrameWork) and not Utils.Helpers.isStarted(Exports.QBXFrameWork) then -- Check 4 (Target for QBCore)
            if Config.System and Config.System.ServerDebugMode then
                print("--- TM-BRIDGE: SERVER hasJob - ENTERING QBCore path ---")
            end
            if Core.Functions.GetPlayer then
                local player = Core.Functions.GetPlayer(src)
                if not player then 
                    if Config.System and Config.System.ServerDebugMode then
                        print("Player not found for src: "..src) 
                    end
                end
                local jobinfo = player.PlayerData.job
                if jobinfo.name == job then
                    hasJobFlag = true
                    duty = player.PlayerData.job.onduty
                    if grade and not (grade <= jobinfo.grade.level) then hasJobFlag = false end
                end
                local ganginfo = player.PlayerData.gang
                if ganginfo.name == job then
                    hasJobFlag = true
                    if grade and not (grade <= ganginfo.grade.level) then hasJobFlag = false end
                end
            else
                -- This else is for the Core.Functions.GetPlayer check, not a framework detection failure
            end

        elseif Utils.Helpers.isStarted(Exports.RSGFrameWork) then -- Check 5
            if Config.System and Config.System.ServerDebugMode then
                print("--- TM-BRIDGE: SERVER hasJob - ENTERING RSG Core path ---")
            end
            if Core.Functions.GetPlayer then
                local player = Core.Functions.GetPlayer(src)
                if not player then 
                    if Config.System and Config.System.ServerDebugMode then
                        print("Player not found for src: "..src) 
                    end
                end
                local jobinfo = player.PlayerData.job
                if jobinfo.name == job then
                    hasJobFlag = true
                    duty = player.PlayerData.job.onduty
                    if grade and not (grade <= jobinfo.grade.level) then hasJobFlag = false end
                end
                local ganginfo = player.PlayerData.gang
                if ganginfo.name == job then
                    hasJobFlag = true
                    if grade and not (grade <= ganginfo.grade.level) then hasJobFlag = false end
                end
            else
                local jobinfo = exports[RSGExport]:GetPlayer(src).PlayerData.job
                if jobinfo.name == job then
                    hasJobFlag = true
                    duty = exports[RSGExport]:GetPlayer(src).PlayerData.job.onduty
                    if grade and not (grade <= jobinfo.grade.level) then hasJobFlag = false end
                end
                local ganginfo = exports[RSGExport]:GetPlayer(src).PlayerData.gang
                if ganginfo.name == job then
                    hasJobFlag = true
                    if grade and not (grade <= ganginfo.grade.level) then hasJobFlag = false end
                end
            end

        elseif Utils.Helpers.isStarted(OXCoreExport) then
            local chunk = assert(load(LoadResourceFile('ox_core', ('imports/%s.lua'):format('server')), ('@@ox_core/%s'):format(file)))
            chunk()
            local player = Ox.GetPlayer(src)
            for k, v in pairs(player.getGroups()) do
                if k == job then hasJobFlag = true end
            end

        elseif Utils.Helpers.isStarted(QBXExport) then
            local jobinfo = exports[QBXExport]:GetPlayer(src).PlayerData.job
            if jobinfo.name == job then
                hasJobFlag = true
                duty = exports[QBXExport]:GetPlayer(src).PlayerData.job.onduty
                if grade and not (grade <= jobinfo.grade.level) then hasJobFlag = false end
            end
            local ganginfo = exports[QBXExport]:GetPlayer(src).PlayerData.gang
            if ganginfo.name == job then
                hasJobFlag = true
                if grade and not (grade <= ganginfo.grade.level) then hasJobFlag = false end
            end

        elseif Utils.Helpers.isStarted(QBExport) and not Utils.Helpers.isStarted(QBXExport) then
            if Core.Functions.GetPlayer then
                local player = Core.Functions.GetPlayer(src)
                if not player then print("Player not found for src: "..src) end
                local jobinfo = player.PlayerData.job
                if jobinfo.name == job then
                    hasJobFlag = true
                    duty = player.PlayerData.job.onduty
                    if grade and not (grade <= jobinfo.grade.level) then hasJobFlag = false end
                end
                local ganginfo = player.PlayerData.gang
                if ganginfo.name == job then
                    hasJobFlag = true
                    if grade and not (grade <= ganginfo.grade.level) then hasJobFlag = false end
                end
            else
                local jobinfo = exports[QBExport]:GetPlayer(src).PlayerData.job
                if jobinfo.name == job then
                    hasJobFlag = true
                    duty = exports[QBExport]:GetPlayer(src).PlayerData.job.onduty
                    if grade and not (grade <= jobinfo.grade.level) then hasJobFlag = false end
                end
                local ganginfo = exports[QBExport]:GetPlayer(src).PlayerData.gang
                if ganginfo.name == job then
                    hasJobFlag = true
                    if grade and not (grade <= ganginfo.grade.level) then hasJobFlag = false end
                end
            end
        else
            if Config.System and Config.System.ServerDebugMode then
                print("--- TM-BRIDGE: SERVER hasJob - FALLING INTO FINAL ELSE (No Core Detected) ---")
                print("^4ERROR^7: ^2No Core detected for hasJob ^7- ^2Check ^3starter^1.^2lua^7") -- SERVER ERROR
            end
        end
    else
        -- Client-side check.
        if Config.System and Config.System.ClientDebugMode then
            print("--- TM-BRIDGE: ENTERING hasJob CLIENT CHECK ---") -- New simple print
            -- print(string.format("[DEBUG CLIENT hasJob] Called with job: %s, grade: %s", tostring(job), tostring(grade)))
            -- print(string.format("[DEBUG CLIENT hasJob] Type of Config.Framework: %s, Value: %s", type(Config.Framework), tostring(Config.Framework)))
        end

        if Config.Framework == "QBCore" and Utils.Helpers.isStarted(Exports.QBFrameWork) then
            if Config.System and Config.System.ClientDebugMode then
                print(string.format("[DEBUG CLIENT hasJob] QBCore path. QBCore global: %s", tostring(QBCore)))
            end
            if QBCore and QBCore.Functions and QBCore.Functions.GetPlayerData then
                local info = QBCore.Functions.GetPlayerData() -- Use the global QBCore object
                if Config.System and Config.System.ClientDebugMode then
                    print(string.format("[DEBUG CLIENT hasJob] QBCore PlayerData: %s", info and "table" or "nil"))
                end
                if info and info.job and info.job.name == job then
                    hasJobFlag = true
                    duty = info.job.onduty
                    if grade and not (grade <= info.job.grade.level) then hasJobFlag = false end
                    if Config.System and Config.System.ClientDebugMode then
                        print(string.format("[DEBUG CLIENT hasJob] QBCore job match: %s, duty: %s, grade met: %s", tostring(hasJobFlag), tostring(duty), tostring(not (grade and not (grade <= info.job.grade.level)))))
                    end
                end
                if info and info.gang and info.gang.name == job then -- Check gang as well
                    hasJobFlag = true -- No separate duty for gang generally in QBCore, or handled by job.onduty
                    if grade and not (grade <= info.gang.grade.level) then hasJobFlag = false end
                    if Config.System and Config.System.ClientDebugMode then
                        print(string.format("[DEBUG CLIENT hasJob] QBCore gang match: %s, grade met: %s", tostring(hasJobFlag), tostring(not (grade and not (grade <= info.gang.grade.level)))))
                    end
                end
            else
                 if Config.System and Config.System.ClientDebugMode then
                     print("[DEBUG CLIENT hasJob] QBCore global or QBCore.Functions.GetPlayerData is nil.")
                 end
            end
        elseif Config.Framework == "ESX" and Utils.Helpers.isStarted(Exports.ESXFrameWork) and ESX ~= nil then
            if Config.System and Config.System.ClientDebugMode then
                print(string.format("[DEBUG CLIENT hasJob] ESX path. ESX global: %s", tostring(ESX)))
            end
            if ESX.GetPlayerData then 
                local info = ESX.GetPlayerData().job
                if Config.System and Config.System.ClientDebugMode then
                    print(string.format("[DEBUG CLIENT hasJob] ESX PlayerData Job: %s", info and "table" or "nil"))
                end
                -- ... (rest of ESX client logic, ensure ESX.GetPlayerData() is safe) ...
                while not info do info = ESX.GetPlayerData().job Wait(100) end
                if info.name == job then hasJobFlag = true end
            else
                if Config.System and Config.System.ClientDebugMode then
                    print("[DEBUG CLIENT hasJob] ESX.GetPlayerData is nil.")
                end
            end
        elseif Config.Framework == "OX Core" and Utils.Helpers.isStarted(Exports.OXCoreFrameWork) then
            -- Add OX Core specific client logic if needed, similar to QBCore/ESX
            if Config.System and Config.System.ClientDebugMode then
                print("[DEBUG CLIENT hasJob] OX Core path - Not fully implemented in this debug patch.")
            end
        elseif Config.Framework == "QBox" and Utils.Helpers.isStarted(Exports.QBXFrameWork) then
             if Config.System and Config.System.ClientDebugMode then
                 print(string.format("[DEBUG CLIENT hasJob] QBox path. QBCore global (used by QBox): %s", tostring(QBCore)))
             end
            if QBCore and QBCore.Functions and QBCore.Functions.GetPlayerData then -- QBox might reuse QBCore global or have its own `exports.qbx_core:GetPlayerData()`
                local info = QBCore.Functions.GetPlayerData() 
                -- ... (similar logic as QBCore) ...
            else
                if Config.System and Config.System.ClientDebugMode then
                    print("[DEBUG CLIENT hasJob] QBox: QBCore global or GetPlayerData is nil.")
                end
            end
        elseif Config.Framework == "RSG Core" and Utils.Helpers.isStarted(Exports.RSGFrameWork) then
            if Config.System and Config.System.ClientDebugMode then
                print("[DEBUG CLIENT hasJob] RSG Core path - Not fully implemented in this debug patch.")
            end
        else
            if Config.System and Config.System.ClientDebugMode then
                print("^4ERROR^7: ^2No Core detected for hasJob ^7- ^2Check ^3starter^1.^2lua^7")
                print(string.format("[DEBUG CLIENT hasJob] Failed all framework checks. Config.Framework: %s, QB Started: %s, ESX Started: %s, OX Started: %s, QBox Started: %s, RSG Started: %s", 
                    tostring(Config.Framework), 
                    tostring(Utils.Helpers.isStarted(Exports.QBFrameWork)), 
                    tostring(Utils.Helpers.isStarted(Exports.ESXFrameWork)),
                    tostring(Utils.Helpers.isStarted(Exports.OXCoreFrameWork)),
                    tostring(Utils.Helpers.isStarted(Exports.QBXFrameWork)),
                    tostring(Utils.Helpers.isStarted(Exports.RSGFrameWork))
                ))
            end
        end
    end
    return hasJobFlag, duty
end

--- Retrieves basic player information (name, cash, bank, job, etc.) based on the active core/inventory system.
---
--- Can be called server-side (passing a player source) or client-side (for current player).
---
--- @param source number|nil Optional player server ID.
--- @return table A table containing player details.
---
--- @usage
--- ```lua
--- -- Get information for a specific player
--- local playerInfo = getPlayer(playerId)
--- print(playerInfo.name, playerInfo.cash, playerInfo.bank)
---
--- -- Get information for the current player (client-side)
--- local myInfo = getPlayer()
--- print(myInfo.name, myInfo.cash, myInfo.bank)
--- ```
function getPlayer(source)
    local Player = {}
    if Config.System and Config.System.ServerDebugMode and source then -- Added source check for server context print
        debugPrint("^6Bridge^7: ^2Getting ^3Player^2 info^7") -- This is a general debugPrint, might be okay or also server-conditional
    end

    if source then
        local src = tonumber(source)
        if Utils.Helpers.isStarted(ESXExport) then
            local info = ESX.GetPlayerFromId(src)
            Player = {
                name = info.getName(),
                cash = info.getMoney(),
                bank = info.getAccount("bank").money,

                firstname = info.variables.firstName,
                lastname = info.variables.lastName,

                source = info.source,
                job = info.job.name,
                --jobBoss = info.job.isboss,
                --gang = info.gang.name,
                --gangBoss = info.gang.isboss,
                onDuty = info.job.onDuty,
                --account = info.charinfo.account,
                citizenId = info.identifier,
            }

        elseif Utils.Helpers.isStarted(OXCoreExport) then
            local file = ('imports/%s.lua'):format('server')
            local import = LoadResourceFile('ox_core', file)
            local chunk = assert(load(import, ('@@ox_core/%s'):format(file)))
            chunk()
            local player = Ox.GetPlayer(src)
            Player = {
                firstname = player.firstName,
                lastname = player.lastName  ,
                name = ('%s %s'):format(player.firstName, player.lastName),
                cash = exports[OXInv]:Search(src, 'count', "money"),
                bank = 0,
                source = src,
                --job = OxPlayer.getGroups(),
                --jobBoss = info.job.isboss,
                --gang = OxPlayer.getGroups(),
                --gangBoss = info.gang.isboss,
                --onDuty = info.job.onduty,
                --account = info.charinfo.account,
                citizenId = player.stateId,

            }
        elseif Utils.Helpers.isStarted(QBXExport) then
            local info = exports[QBXExport]:GetPlayer(src)
            Player = {
                firstname = info.PlayerData.charinfo.firstname,
                lastname = info.PlayerData.charinfo.lastname,
                name = info.PlayerData.charinfo.firstname.." "..info.PlayerData.charinfo.lastname,
                cash = exports[OXInv]:Search(src, 'count', "money"),
                bank = info.Functions.GetMoney("bank"),
                source = info.PlayerData.source,
                job = info.PlayerData.job.name,
                jobBoss = info.PlayerData.job.isboss,
                jobInfo = info.PlayerData.job,
                gang = info.PlayerData.gang.name,
                gangInfo = info.PlayerData.gang,
                gangBoss = info.PlayerData.gang.isboss,
                onDuty = info.PlayerData.job.onduty,
                account = info.PlayerData.charinfo.account,
                citizenId = info.PlayerData.citizenid,
                isDead = info.PlayerData.metadata["isdead"],
                isDown = info.PlayerData.metadata["inlaststand"],
                charInfo = info.charinfo,
            }
        elseif Config.Framework == "QBCore" and Utils.Helpers.isStarted(Exports.QBFrameWork) and not Utils.Helpers.isStarted(Exports.QBXFrameWork) then
            if Config.System and Config.System.ClientDebugMode then
                print("--- TM-BRIDGE: getPlayer CLIENT - ENTERING CORRECTED QBCore LOGIC BLOCK ---")
            end
            if QBCore and QBCore.Functions and QBCore.Functions.GetPlayerData then
                local info = QBCore.Functions.GetPlayerData() -- Direct synchronous call
                if Config.System and Config.System.ClientDebugMode then
                    print(string.format("--- TM-BRIDGE: getPlayer CLIENT (QBCore) - Synchronous GetPlayerData() returned: %s ---", info and type(info) or "nil"))
                end
                if info then
                    Player = {
                        firstname = info.charinfo.firstname,
                        lastname = info.charinfo.lastname,
                        name = info.charinfo.firstname.." "..info.charinfo.lastname,
                        cash = info.money["cash"],
                        bank = info.money["bank"],
                        source = info.source, 
                        job = info.job.name,
                        jobBoss = info.job.isboss,
                        jobInfo = info.job,
                        gang = info.gang.name,
                        gangBoss = info.gang.isboss,
                        gangInfo = info.gang,
                        onDuty = info.job.onduty,
                        account = info.charinfo.account,
                        citizenId = info.citizenid,
                        isDead = info.metadata["isdead"],
                        isDown = info.metadata["inlaststand"],
                        charInfo = info.charinfo,
                    }
                else
                    if Config.System and Config.System.ClientDebugMode then
                        print("--- TM-BRIDGE: getPlayer CLIENT (QBCore) - Synchronous GetPlayerData() returned nil. Player table not populated. ---")
                    end
                end
            else
                if Config.System and Config.System.ClientDebugMode then
                    print("--- TM-BRIDGE: getPlayer CLIENT (QBCore) - QBCore global or QBCore.Functions.GetPlayerData is nil. Player table not populated. ---")
                end
            end
        elseif Utils.Helpers.isStarted(RSGExport) then
            if Core.Functions.GetPlayer then
                local info = Core.Functions.GetPlayer(src).PlayerData
                Player = {
                    firstname = info.charinfo.firstname,
                    lastname = info.charinfo.lastname,
                    name = info.charinfo.firstname.." "..info.charinfo.lastname,
                    cash = info.money["cash"],
                    bank = info.money["bank"],
                    source = info.source,
                    job = info.job.name,
                    jobBoss = info.job.isboss,
                    jobInfo = info.job,
                    gang = info.gang.name,
                    gangBoss = info.gang.isboss,
                    gangInfo = info.gang,
                    onDuty = info.job.onduty,
                    account = info.charinfo.account,
                    citizenId = info.citizenid,
                    isDead = info.metadata["isdead"],
                    isDown = info.metadata["inlaststand"],
                    charInfo = info.charinfo,
                }
            end
        else
            if Config.System and Config.System.ServerDebugMode then
                print("^4ERROR^7: ^2No Core detected for getPlayer() - Check starter.lua")
            end
        end
    else
        -- Client-side: Get current player info.
        if Config.System and Config.System.ClientDebugMode then
            print("--- TM-BRIDGE: ENTERING getPlayer CLIENT ---")
            print(string.format("--- DEBUG: getPlayer CLIENT - Config.Framework: %s (Type: %s) ---", tostring(Config.Framework), type(Config.Framework)))
            print(string.format("--- DEBUG: getPlayer CLIENT - Exports.QBFrameWork: %s, Started: %s ---", tostring(Exports.QBFrameWork), tostring(Utils.Helpers.isStarted(Exports.QBFrameWork))))
            print(string.format("--- DEBUG: getPlayer CLIENT - Exports.QBXFrameWork: %s, Started: %s ---", tostring(Exports.QBXFrameWork), tostring(Utils.Helpers.isStarted(Exports.QBXFrameWork))))
            print(string.format("--- DEBUG: getPlayer CLIENT - Exports.ESXFrameWork: %s, Started: %s, ESX global: %s ---", tostring(Exports.ESXFrameWork), tostring(Utils.Helpers.isStarted(Exports.ESXFrameWork)), tostring(ESX)))
            print(string.format("--- DEBUG: getPlayer CLIENT - Exports.OXCoreFrameWork: %s, Started: %s, OxPlayer global: %s ---", tostring(Exports.OXCoreFrameWork), tostring(Utils.Helpers.isStarted(Exports.OXCoreFrameWork)), tostring(OxPlayer)))
            print(string.format("--- DEBUG: getPlayer CLIENT - Exports.RSGFrameWork: %s, Started: %s ---", tostring(Exports.RSGFrameWork), tostring(Utils.Helpers.isStarted(Exports.RSGFrameWork))))
            if QBCore and QBCore.Functions then
                print(string.format("--- DEBUG: getPlayer CLIENT - QBCore.Functions.GetPlayerData exists: %s ---", tostring(QBCore.Functions.GetPlayerData ~= nil)))
            else
                print(string.format("--- DEBUG: getPlayer CLIENT - QBCore global or QBCore.Functions is nil. QBCore: %s ---", tostring(QBCore)))
            end
        end

        if Utils.Helpers.isStarted(ESXExport) and ESX ~= nil then
            local info = ESX.GetPlayerData()
            local cash, bank = 0, 0
            for k, v in pairs(info.accounts) do
                if v.name == "money" then cash = v.money end
                if v.name == "bank" then bank = v.money end
            end
            Player = {
                firstname = info.firstName,
                lastname = info.lastName,
                name = info.firstName.." "..info.lastName,
                cash = cash,
                bank = bank,
                source = GetPlayerServerId(PlayerId()),
                job = info.job.name,
                --jobBoss = info.job.isboss,
                --gang = info.gang.name,
                --gangBoss = info.gang.isboss,
                onDuty = info.job.onDuty,
                --account = info.charinfo.account,
                citizenId = info.identifier,
                isDead = IsEntityDead(PlayerPedId()),
                isDown = IsPedDeadOrDying(PlayerPedId(), true)
            }
        elseif Utils.Helpers.isStarted(OXCoreExport) then
            Player = {
                firstname = OxPlayer.get("firstName"),
                lastname = OxPlayer.get("lastName"),
                name = OxPlayer.get("firstName").." "..OxPlayer.get("lastName"),
                cash = exports[OXInv]:Search('count', "money"),
                bank = 0,
                source = GetPlayerServerId(PlayerId()),
                job = OxPlayer.getGroups(),
                --jobBoss = info.job.isboss,
                gang = OxPlayer.getGroups(),
                --gangBoss = info.gang.isboss,
                --onDuty = info.job.onduty,
                --account = info.charinfo.account,
                citizenId = OxPlayer.userId,
                isDead = IsEntityDead(PlayerPedId()),
                isDown = IsPedDeadOrDying(PlayerPedId(), true)
            }
        elseif Utils.Helpers.isStarted(QBXExport) then
            local info = exports[QBXExport]:GetPlayerData()
            Player = {
                firstname = info.charinfo.firstname,
                lastname = info.charinfo.lastname,
                name = info.charinfo.firstname.." "..info.charinfo.lastname,
                cash = info.money["cash"],
                bank = info.money["bank"],
                source = info.source,
                job = info.job.name,
                jobBoss = info.job.isboss,
                jobInfo = info.job,
                gang = info.gang.name,
                gangBoss = info.gang.isboss,
                gangInfo = info.gang,
                onDuty = info.job.onduty,
                account = info.charinfo.account,
                citizenId = info.citizenid,
                isDead = info.metadata["isdead"],
                isDown = info.metadata["inlaststand"],
                charInfo = info.charinfo,
            }
        elseif Config.Framework == "QBCore" and Utils.Helpers.isStarted(Exports.QBFrameWork) and not Utils.Helpers.isStarted(Exports.QBXFrameWork) then
            if Config.System and Config.System.ClientDebugMode then
                print("--- TM-BRIDGE: getPlayer CLIENT - ENTERING CORRECTED QBCore LOGIC BLOCK ---")
            end
            if QBCore and QBCore.Functions and QBCore.Functions.GetPlayerData then
                local info = QBCore.Functions.GetPlayerData() -- Direct synchronous call
                if Config.System and Config.System.ClientDebugMode then
                    print(string.format("--- TM-BRIDGE: getPlayer CLIENT (QBCore) - Synchronous GetPlayerData() returned: %s ---", info and type(info) or "nil"))
                end
                if info then
                    Player = {
                        firstname = info.charinfo.firstname,
                        lastname = info.charinfo.lastname,
                        name = info.charinfo.firstname.." "..info.charinfo.lastname,
                        cash = info.money["cash"],
                        bank = info.money["bank"],
                        source = info.source, 
                        job = info.job.name,
                        jobBoss = info.job.isboss,
                        jobInfo = info.job,
                        gang = info.gang.name,
                        gangBoss = info.gang.isboss,
                        gangInfo = info.gang,
                        onDuty = info.job.onduty,
                        account = info.charinfo.account,
                        citizenId = info.citizenid,
                        isDead = info.metadata["isdead"],
                        isDown = info.metadata["inlaststand"],
                        charInfo = info.charinfo,
                    }
                else
                    if Config.System and Config.System.ClientDebugMode then
                        print("--- TM-BRIDGE: getPlayer CLIENT (QBCore) - Synchronous GetPlayerData() returned nil. Player table not populated. ---")
                    end
                end
            else
                if Config.System and Config.System.ClientDebugMode then
                    print("--- TM-BRIDGE: getPlayer CLIENT (QBCore) - QBCore global or QBCore.Functions.GetPlayerData is nil. Player table not populated. ---")
                end
            end
        elseif Utils.Helpers.isStarted(RSGExport) then
            local info = nil
            Core.Functions.GetPlayerData(function(PlayerData) info = PlayerData end)
            Player = {
                firstname = info.charinfo.firstname,
                lastname = info.charinfo.lastname,
                name = info.charinfo.firstname.." "..info.charinfo.lastname,
                cash = info.money["cash"],
                bank = info.money["bank"],
                source = info.source,
                job = info.job.name,
                jobBoss = info.job.isboss,
                jobInfo = info.job,
                gang = info.gang.name,
                gangBoss = info.gang.isboss,
                gangInfo = info.gang,
                onDuty = info.job.onduty,
                account = info.charinfo.account,
                citizenId = info.citizenid,
                isDead = info.metadata["isdead"],
                isDown = info.metadata["inlaststand"],
                charInfo = info.charinfo,
            }
        else
            if Config.System and Config.System.ServerDebugMode then
                print("^4ERROR^7: ^2No Core detected for getPlayer (CLIENT) ^7- ^2Check ^3starter^1.^2lua^7")
            end
        end
    end
    return Player
end

--- Retrieves all active players within a given radius from the specified coordinates.
---
--- @param coords vector3 The reference coordinates.
--- @param radius number The radius within which to find players.
--- @return table table An array of player IDs.
---
--- @usage
--- ```lua
--- local nearbyPlayers = GetPlayersFromCoords(vector3(100, 200, 30), 20)
--- ```
function GetPlayersFromCoords(coords, radius)
    local players = {}
    for _, playerId in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(playerId)
        if ped and DoesEntityExist(ped) then
            local playerCoords = GetEntityCoords(ped)
            if #(coords - playerCoords) <= radius then
                players[#players + 1] = playerId
            end
        end
    end
    return players
end

-- Server-side event to handle player data requests from the client.
if Utils.Helpers.isServer() then
    RegisterNetEvent(Utils.Helpers.getScript() .. ":server:getPlayerData", function(targetPlayerId)
        local src = source
        local data = GetPlayer(targetPlayerId or src)
        TriggerClientEvent(Utils.Helpers.getScript() .. ":client:playerData", src, data)
    end)
end