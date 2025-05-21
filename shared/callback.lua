--- Registers a callback function with the appropriate framework.
---
--- This function checks which framework is started (e.g., OX, QB, ESX) and registers the callback accordingly.
--- It adapts the callback function to match the expected signature for the framework.
---
---@param callbackName string The name of the callback to register.
---@param funct function The function to be called when the callback is triggered.
---
---@usage
--- ```lua
--- local table = { ["info"] = "HI" }
--- createCallback('myCallback', function(source, ...)
---     return table
--- end)
---
--- createCallback("callback:checkVehicleOwned", function(source, plate)
--- 	local result = isVehicleOwned(plate)
--- 	if result then
---         return true
---      else
---         return false
---     end
--- end)
--- ```
function createCallback(callbackName, funct)
    if isServer() then
        debugPrint("^6Bridge^7: ^3Registering callback^7:", callbackName)
        if isStarted(OXLibExport) then
            lib.callback.register(callbackName, funct)
        else
            local adaptedFunction = function(source, cb, ...)
                local result = funct(source, ...)
                cb(result)
            end

            if isStarted(QBExport) then
                Core = Core or exports[QBExport]:GetCoreObject()
                Core.Functions.CreateCallback(callbackName, adaptedFunction)
            elseif isStarted(ESXExport) then
                ESX.RegisterServerCallback(callbackName, adaptedFunction)
            else
                print("^6Bridge^7: ^1ERROR^7: ^3Can't find any script to register callback with", callbackName)
            end
        end
    end
end

--- Triggers a server callback and returns the result.
---
--- This function triggers a server callback using the appropriate framework's method and awaits the result.
---
---@param callbackName string The name of the callback to trigger.
---@param ... any Additional arguments to pass to the callback.
---
---@return any any The result returned by the callback function.
---
---@usage
--- ```lua
--- local result = triggerCallback('myCallback')
--- jsonPrint(result)
---
--- local result = triggerCallback("callback:checkVehicleOwned", plate)
--- print(result)
--- ```
function triggerCallback(callbackName, ...)
    local result = nil
    debugPrint("^6Bridge^7: ^3Triggering callback^7:", callbackName)
    if isStarted(OXLibExport) then
        result = lib.callback.await(callbackName, false, ...)
    elseif isStarted(QBExport) then
        local p = promise.new()
        Core.Functions.TriggerCallback(callbackName, function(cbResult)
            p:resolve(cbResult)
        end, ...)
        result = Citizen.Await(p)
        Wait(10)
    elseif isStarted(ESXExport) then
        local p = promise.new()
        ESX.TriggerServerCallback(callbackName, function(cbResult)
            p:resolve(cbResult)
        end, ...)
        result = Citizen.Await(p)
    else
        print("^6Bridge^7: ^1ERROR^7: ^3Can't find any script to trigger callback with", callbackName)
    end
    return result
end