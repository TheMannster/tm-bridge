--[[
    Player & Resource Event Utility Functions
    -------------------------------------------
    This module provides functions to:
      • Execute code when the player character is loaded or unloaded.
      • Execute code on resource start and stop.
      • Wait for the player to be logged in before proceeding.
]]

-------------------------------------------------------------
-- Player Loaded and Unloaded Events
-------------------------------------------------------------

--- Executes a function when the player character is loaded.
--- If onStart is true, the function will also run on resource start (after ensuring the player is logged in).
---
--- @param func function The function to execute when the player is loaded.
--- @param onStart boolean (optional) If true, also execute on resource start. Default is false.
--- @usage
--- ```lua
--- onPlayerLoaded(function()
---     print("Player logged in")
---     -- Your initialization code here.
--- end, true)
--- ```
function onPlayerLoaded(func, onStart)
    local onPlayerFramework = ""
    local loaded = false

    if onStart then
        onResourceStart(function()
            if not waitForLogin() then return end

            loaded = true
            debugPrint("^6Bridge^7: ^3onResourceStart^7()^2 executed through ^3onPlayerLoaded^7()")
            Wait(2000)
            func()
        end, true)
    end

    if not loaded then
        local tempFunc = function()
            Wait(2000)
            debugPrint("^6Bridge^7: ^2Executing onPlayerLoaded")
            func()
        end

        -- Corrected logic based on Config.Framework set by starter.lua
        if Config.Framework == "QBCore" and Utils.Helpers.isStarted(Exports.QBFrameWork) then
            onPlayerFramework = Exports.QBFrameWork
            AddEventHandler('QBCore:Client:OnPlayerLoaded', tempFunc)
        elseif Config.Framework == "QBox" and Utils.Helpers.isStarted(Exports.QBXFrameWork) then
            onPlayerFramework = Exports.QBXFrameWork
            AddEventHandler('QBCore:Client:OnPlayerLoaded', tempFunc) -- Assuming QBox uses QBCore event or has its own like 'QBox:Client:OnPlayerLoaded'
        elseif Config.Framework == "ESX" and Utils.Helpers.isStarted(Exports.ESXFrameWork) then
            onPlayerFramework = Exports.ESXFrameWork
            AddEventHandler('esx:playerLoaded', function()
                if waitForSharedLoad() then
                    if Utils.Helpers.isStarted(Exports.ESXFrameWork) then Wait(11000) end
                    tempFunc()
                end
            end)
        elseif Config.Framework == "OX Core" and Utils.Helpers.isStarted(Exports.OXCoreFrameWork) then
            onPlayerFramework = Exports.OXCoreFrameWork
            AddEventHandler('ox:playerLoaded', tempFunc)
        elseif Config.Framework == "RSG Core" and Utils.Helpers.isStarted(Exports.RSGFrameWork) then -- For RedM
            onPlayerFramework = Exports.RSGFrameWork
            AddEventHandler('RSGCore:Client:OnPlayerLoaded', tempFunc)
        end

        if onPlayerFramework ~= "" then
            debugPrint("^6Bridge^7: ^2Registering ^3onPlayerLoaded^7()^2 with ^3" .. onPlayerFramework.."^7")
        else
            print("^4ERROR^7: No supported core detected for onPlayerLoaded. Config.Framework: " .. tostring(Config.Framework))
        end
    end
end

--- Executes a function when the player character is unloaded.
--- @param func function The function to execute when the player unloads.
--- @usage
--- ```lua
--- onPlayerUnload(function()
---     print("Player has logged out of their character")
---     -- Your cleanup code here.
--- end)
--- ```
function onPlayerUnload(func)
    AddEventHandler('QBCore:Client:OnPlayerUnload', function() func() end)
    AddEventHandler('ox:playerLogout', function() func() end)
    AddEventHandler('RSGCore:Client:OnPlayerUnload', function() func() end)

    --AddEventHandler('esx:playerLogout', function() func() end)
    -- ^ Only server side for now, need a way to send it to client if not already available
end

-------------------------------------------------------------
-- Resource Start and Stop Events
-------------------------------------------------------------

--- Executes a function when the resource starts.
--- @param func function The function to execute.
--- @param thisScript boolean (optional) If true, only runs when this resource starts (default true).
--- @usage
--- ```lua
--- onResourceStart(function()
---     print("Script ensured")
---     -- Initialization code on resource start.
--- end, true)
--- ```
function onResourceStart(func, thisScript)
    debugPrint("^6Bridge^7: ^2Registering ^3onResourceStart^7()")
    AddEventHandler('onResourceStart', function(resourceName)
        if Utils.Helpers.getScript() == resourceName and (thisScript or true) then
            if waitForSharedLoad() then
                debugPrint("^6Bridge^7: ^2Shared Load Detected^7.")
                if Utils.Helpers.isStarted(ESXExport) then Wait(10000) end
                func()
            end
        end
    end)
end

--- Executes a function when the resource stops.
--- @param func function The function to execute.
--- @param thisScript boolean (optional) If true, only runs when this resource stops (default true).
--- @usage
--- ```lua
--- onResourceStop(function()
---     -- Cleanup code here.
--- end, true)
--- ```
function onResourceStop(func, thisScript)
    debugPrint("^6Bridge^7: ^2Registering ^3onResourceStop^7()")
    AddEventHandler('onResourceStop', function(resourceName)
        if Utils.Helpers.getScript() == resourceName and (thisScript or true) then
            func()
        end
    end)
end

-------------------------------------------------------------
-- Wait for Login
-------------------------------------------------------------

--- Blocks execution until the player is logged in.
--- @usage
--- waitForLogin()
function waitForLogin()
    local timeout = 10000  -- 10 seconds in milliseconds
    local startTime = GetGameTimer()
    local loggedIn = false

    if Utils.Helpers.isStarted(ESXExport) then
        while (GetGameTimer() - startTime) < timeout do
            local playerData = ESX.GetPlayerData()
            if playerData and playerData.job then
                loggedIn = true
                break
            end
            Wait(100)
        end
    elseif Utils.Helpers.isStarted(OXCoreExport) then
        if OxPlayer["stateId"] then
            loggedIn = true
        end
        while not OxPlayer["stateId"] do
            Wait(1000)
            debugPrint("Waiting for stateId to class as logged in")
            if OxPlayer.get["stateId"] then
                loggedIn = true
                break
            end
        end
    else
        -- For other frameworks, use LocalPlayer.state.isLoggedIn.
        while not LocalPlayer.state.isLoggedIn and (GetGameTimer() - startTime) < timeout do
            Wait(100)
        end
        loggedIn = LocalPlayer.state.isLoggedIn
    end

    if not loggedIn then
        print("^4Error^7: ^2Timeout reached while waiting for player login^7.")
        return false
    else
        debugPrint("^6Bridge^7: ^2Player Login Detected^7.")
        return true
    end
end

function waitForSharedLoad()
    local timeout = 100000  -- 10 seconds in milliseconds
    local startTime = GetGameTimer()
    local loaded = true
    while ((not Jobs or not next(Jobs)) and (not Items or not next(Items)) and (not Vehicles or not next(Vehicles))) and (GetGameTimer() - startTime) < timeout do
        Wait(1000)
        debugPrint("Waiting for Jobs, Items, and Vehicles to be loaded")
        if Jobs and Items and Vehicles then
            print("^6Bridge^7: ^2Jobs, Items, and Vehicles Loaded^7.")
            loaded = true
            break
        end
    end
    if not loaded then
        print("^4Error^7: ^2Timeout reached while waiting for shared load^7.")
        return false
    else
        return true
    end
end