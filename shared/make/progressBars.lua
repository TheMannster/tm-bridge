local inProgress = false

--- Displays a progress bar using the configured progress bar system.
---
--- This function handles displaying a progress bar to the player using the specified progress bar system (e.g., ox, qb, esx, gta).
--- It supports shared progress bars between players, animations, camera effects, and more.
---
---@param data table A table containing the progress bar configuration.
--- - **label** (`string`): The text label to display on the progress bar.
--- - **time** (`number`): The duration of the progress bar in milliseconds.
--- - **dict** (`string`, optional): The animation dictionary to use.
--- - **anim** (`string`, optional): The animation name to play.
--- - **task** (`string`, optional): The task scenario to perform.
--- - **flag** (`number`, optional): The animation flag.
--- - **dead** (`boolean`, optional): Whether to allow the progress bar when the player is dead. Default is `false`.
--- - **cancel** (`boolean`, optional): Whether the progress bar can be canceled by the player. Default is `true`.
--- - **icon** (`string`, optional): The icon to display (for qb progress bar).
--- - **cam** (`number`, optional): The camera handle to use.
--- - **shared** (`table`, optional): Data for shared progress bars.
---   - **pid** (`number`): The player ID to share the progress bar with.
---   - **label** (`string`): The label to display on the shared progress bar.
---
--- @return boolean `true` if the progress bar completed successfully, or `false` if it was canceled.
---
---@usage
--- ```lua
--- local success = progressBar({
---     label = "Processing...",
---     time = 5000,
---     dict = "amb@world_human_hang_out_street@female_hold_arm@base",
---     anim = "base",
---     flag = 49,
---     cancel = true,
--- })
--- ```
function progressBar(data)
    local ped = PlayerPedId()
    if data.shared then
        debugPrint("^6Bridge^7: ^6Sharing progressBar to player^7: ^6"..data.shared.pid.."^7")
        storedPID = data.shared.pid
        TriggerServerEvent(getScript()..":server:sharedProg:Start", data)
    end
    local result = nil
    if data.cam then startTempCam(data.cam) end
    if Config.System.ProgressBar == "ox" then
        if exports[OXLibExport]:progressBar({
            duration = debugMode and 1000 or data.time,
            label = data.label,
            useWhileDead = data.dead or false,
			canCancel = data.cancel and data.cancel or true,
            anim = {
                dict = data.dict,
                clip = data.anim,
                flag = (data.flag == 8 and 32 or data.flag) or nil,
                scenario = data.task
            },
            disable = {
                combat = true
            },
        }) then
            result = true
        else
            result = false
        end

    elseif Config.System.ProgressBar == "qb" then
        Core.Functions.Progressbar("progbar",
            data.label,
            debugMode and 1000 or data.time,
            data.dead or false,
			data.cancel or true,
            { disableMovement = true, disableCarMovement = true, disableMouse = false, disableCombat = true },
            { animDict = data.dict, anim = data.anim, flags = data.flag or 32, task = data.task }, {}, {},
            function()
                result = true
            end, function()
                result = false
            end, data.icon)

    elseif Config.System.ProgressBar == "esx" then
        ESX.Progressbar(data.label, debugMode and 1000 or data.time, {
            FreezePlayer = true,
            animation = {
                type = data.anim,
                dict = data.dict,
                scenario = data.task,
            },
            onFinish = function()
                result = true
            end,
            onCancel = function()
                result = false
            end
        })

    elseif Config.System.ProgressBar == "red" then
        -- Currently only uses jim-redui if you choose this option
        if exports["jim-redui"]:progressBar({
            label = data.label,
            time = debugMode and 1000 or data.time,
            dict = data.dict,
            anim = data.anim,
            flag = data.flag or 32,
            task = data.task,
            cancel = true,
        }) then
            result = true
        else
            result = false
        end

    elseif Config.System.ProgressBar == "gta" then
        loadTextureDict("timerbars")
        if inProgress then return false end
        inProgress = true
        local wait = debugMode and 1000 or data.time
        local endTime = GetGameTimer() + wait
        local ped = PlayerPedId()

        -- Setup Animation/Task if specified
        if data.dict then
            playAnim(data.dict, data.anim, -1, data.flag or 32)
        elseif data.task then
            TaskStartScenarioInPlace(ped, data.task, -1, true)
        end

        -- Progress bar rendering loop
        CreateThread(function()
            while GetGameTimer() < endTime and inProgress do
                Wait(0)
                local elapsed = GetGameTimer()
                local percentage = ((elapsed - (endTime - wait)) / wait) * 100

                -- Convert to segmented progress (assuming 5 segments here)
                local segments = 5  -- Number of segments in the bar
                local segmentProgress = {}
                local progressPerSegment = 100 / segments

                for i = 1, segments do
                    local segmentStart = (i - 1) * progressPerSegment
                    local segmentEnd = i * progressPerSegment
                    if percentage >= segmentEnd then
                        segmentProgress[i] = 100
                    elseif percentage <= segmentStart then
                        segmentProgress[i] = 0
                    else
                        segmentProgress[i] = ((percentage - segmentStart) / progressPerSegment) * 100
                    end
                end

                percentage = percentage >= 100 and 100 or percentage
                -- Draw your segmented progress bar
                ShowGTAProgressBar(segmentProgress, data.label, ("%.0f%%"):format(percentage))

                -- Controls to disable during progress
                DisablePlayerFiring(ped, true)
                DisableControlAction(0, 25, true) -- Disable aim
                DisableControlAction(0, 21, true) -- Disable sprint
                DisableControlAction(0, 30, true) -- Disable move left/right
                DisableControlAction(0, 31, true) -- Disable move forward/back
                DisableControlAction(0, 36, true) -- Disable stealth

                if data.cancel and (IsControlJustReleased(0, 202) or IsControlJustReleased(0, 177) or IsControlJustReleased(0, 73)) then
                    inProgress = false
                end
            end
        end)

        -- Wait for completion or cancel
        while GetGameTimer() < endTime and inProgress do
            Wait(100)
        end

        -- Cleanup animations/tasks
        if data.dict then stopAnim(data.dict, data.anim, ped) end
        ClearPedTasks(ped)

        result = inProgress
        inProgress = false
    end

    while result == nil do Wait(10) end

    -- Cleanup
    FreezeEntityPosition(ped, false)
    lockInv(false)
    if data.cam then
        stopTempCam(data.cam)
    end
    if result == false and data.shared then
        debugPrint("^6Bridge^7: ^2Sending cancel to ^6"..storedPID.."^7")
        TriggerServerEvent(getScript().."server:sharedProg:cancel", storedPID)
    end
    storedPID = nil
    if result == false then
        currentToken = nil
        TriggerServerEvent(getScript()..":clearAuthToken")
    end
    if result == true and data.request then
        TriggerServerEvent(getScript()..":clearAuthToken")
        currentToken = triggerCallback(AuthEvent)
    end
    return result
end

function ShowGTAProgressBar(currentProg, title, level)
    local loc = vec2(0.37, 0.90)
    local size = vec2(0.3, 0.03)

    -- Draw background box
    DrawSprite("timerbars", "all_black_bg", loc.x +0.028, loc.y-0.01, 0.15, 0.07, 0.0, 255, 255, 255, 255)
    DrawSprite("timerbars", "all_black_bg", loc.x +0.170, loc.y-0.01, 0.15, 0.07, 180.0, 255, 255, 255, 255)

    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(0.35, 0.35)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(title)
    DrawText(loc.x - size.x / 4 + 0.074, loc.y - 0.034)  -- Adjust text position

    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(0.35, 0.25)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry("STRING")
    AddTextComponentString(level)
    DrawText(loc.x - size.x / 4 + 0.246, loc.y - 0.030)  -- Right-aligned additional text

    local segmentWidth = (size.x + 0.05) / (#currentProg * 2)  -- Divide the total width by 18 (9 segments * 2 gaps for each)
    local gap = segmentWidth / #currentProg  -- Smaller gap between segments

    for i = 1, #currentProg do
        local segmentX = (loc.x - size.x / 4 ) + 0.075 + (i - 1) * (segmentWidth + gap)
        local fillPercentage = currentProg[i]
        local progressBarWidth = segmentWidth * (fillPercentage / 100)

        -- Semi-transparent background for each segment
        DrawRect(segmentX + segmentWidth / 2, loc.y, segmentWidth, size.y / 3.4, 100, 100, 100, 255)

        -- Filling progress for each segment
        if progressBarWidth > 0 then
            DrawRect(segmentX + progressBarWidth / 2, loc.y, progressBarWidth, size.y / 3.4, 93, 182, 229, 255)  -- Blue progress
        end
    end
end

--- Stops the current progress bar.
---
--- This function cancels the progress bar based on the configured progress bar system, handling any necessary cleanup.
function stopProgressBar()
    if Config.System.ProgressBar == "ox" then
        exports[OXLibExport]:cancelProgress()
    elseif Config.System.ProgressBar == "qb" then
        TriggerEvent("progressbar:client:cancel")
    elseif Config.System.ProgressBar == "gta" then
        inProgress = false
    end
end

-- System to handle sending/sharing progress bars between players --
-- For example, healing someone --

local storedPID = nil

--- Server event handler for starting a shared progress bar.
--- This event is triggered when a player wants to start a progress bar on another player.
--- It adjusts the data to prevent loops and sends the data to the target client.
RegisterNetEvent(getScript()..":server:sharedProg:Start", function(data)
    local pid = data.shared.pid     -- Get player ID from the client
    data.label = data.shared.label  -- Set progress bar label to the shared label
    data.cancel = false             -- Make it so it can't be canceled
    data.dead = true                -- Allow progress bar even if player is dead
    data.shared = nil               -- Remove shared info to prevent loops
    data.anim = nil                 -- Remove animation so players don't share it
    debugPrint("^6Bridge^7: ^6"..source.." ^2is sending shared progressBar to player^7, ^6"..pid.."^7")
    TriggerClientEvent(getScript()..":client:sharedProg:Start", pid, data)
end)

--- Client event handler for starting a shared progress bar.
--- This event is triggered when the server wants the client to start a shared progress bar.
RegisterNetEvent(getScript()..":client:sharedProg:Start", function(data)
    debugPrint("^6Bridge^7: ^2You have been sent a progressBar^7")
    progressBar(data)
end)

--- Server event handler for canceling a shared progress bar.
--- This event is triggered when a progress bar is canceled and the server needs to notify the other player.
RegisterNetEvent(getScript()..":server:sharedProg:Cancel", function(pid)
    debugPrint("^6Bridge^7: ^2Sending cancel progressBar to ^6"..pid.."^7")
    TriggerClientEvent(getScript()..":client:sharedProg:Cancel", pid)
end)

--- Client event handler for canceling a shared progress bar.
--- This event is triggered when the server wants the client to cancel a shared progress bar.
RegisterNetEvent(getScript()..":client:sharedProg:Cancel", function()
    debugPrint("^6Bridge^7: ^2Receiving cancel progressBar^7")
    stopProgressBar()
end)