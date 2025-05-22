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
    if Utils.Helpers.isServer() then
        -- SERVER SIDE
        local actualQBExportName = nil
        local actualESXExportName = nil
        local actualOXLibExportName = Exports.OXLib -- This is straightforward

        if Config.Framework == "QBCore" then
            actualQBExportName = Exports.QBFrameWork
        elseif Config.Framework == "ESX" then
            actualESXExportName = Exports.ESXFrameWork
        elseif Config.Framework == "OX Core" then -- Assuming ox_core might use ox_lib for callbacks or has its own
             -- If OX Core has its own callback system different from ox_lib, this needs adjustment
             -- For now, we rely on the ox_lib check below primarily for ox_core if it uses ox_lib's callback reg.
        end

        if Config.System and Config.System.ServerDebugMode then
            print(string.format("[DEBUG SERVER createCallback] Registering: %s", callbackName))
            print(string.format("[DEBUG SERVER createCallback] Config.Framework: %s", tostring(Config.Framework)))
            print(string.format("[DEBUG SERVER createCallback] Derived QBExportName: %s, Derived ESXExportName: %s, Derived OXLibExportName: %s", tostring(actualQBExportName), tostring(actualESXExportName), tostring(actualOXLibExportName)))
            if actualQBExportName then print(string.format("[DEBUG SERVER createCallback] Utils.Helpers.isStarted(actualQBExportName)(\"%s\"): %s", actualQBExportName, Utils.Helpers.isStarted(actualQBExportName))) end
            if actualESXExportName then print(string.format("[DEBUG SERVER createCallback] Utils.Helpers.isStarted(actualESXExportName)(\"%s\"): %s", actualESXExportName, Utils.Helpers.isStarted(actualESXExportName))) end
            if actualOXLibExportName then print(string.format("[DEBUG SERVER createCallback] Utils.Helpers.isStarted(actualOXLibExportName)(\"%s\"): %s", actualOXLibExportName, Utils.Helpers.isStarted(actualOXLibExportName))) end
            print(string.format("[DEBUG SERVER createCallback] Core object (QBCore global): %s, ESX object (ESX global): %s", tostring(QBCore), tostring(ESX)))
            if QBCore and QBCore.Functions then print(string.format("[DEBUG SERVER createCallback] QBCore.Functions.CreateCallback exists: %s", tostring(QBCore.Functions.CreateCallback ~= nil))) end
            debugPrint("^6Bridge^7: ^3Registering callback^7:", callbackName) -- This uses DebugPrint which respects Config.DebugMode
            print(string.format("--- SERVER createCallback DEBUG --- For: %s, OXLibStarted: %s, lib exists: %s, lib.callback exists: %s, lib.callback.register exists: %s", callbackName, tostring(Utils.Helpers.isStarted(actualOXLibExportName)), tostring(lib ~= nil), tostring(lib and lib.callback ~= nil), tostring(lib and lib.callback and lib.callback.register ~= nil)))
        end
        
        if Utils.Helpers.isStarted(actualOXLibExportName) and lib and lib.callback and lib.callback.register then
            if Config.System and Config.System.ServerDebugMode then
                print(string.format("--- SERVER createCallback DEBUG --- Using ox_lib registration for: %s", callbackName))
            end
            lib.callback.register(callbackName, funct)
        else
            if Config.System and Config.System.ServerDebugMode then
                print(string.format("--- SERVER createCallback DEBUG --- ox_lib direct registration failed or not used for: %s. Falling back to QB/ESX style.", callbackName))
            end
            local adaptedFunction = function(source, cb, ...)
                local result = funct(source, ...)
                cb(result)
            end

            if actualQBExportName and Utils.Helpers.isStarted(actualQBExportName) then
                -- QBCore is initialized to the global QBCore by starter.lua
                if QBCore and QBCore.Functions and QBCore.Functions.CreateCallback then
                    QBCore.Functions.CreateCallback(callbackName, adaptedFunction)
                else
                    if Config.System and Config.System.ServerDebugMode then
                        print(string.format("^6Bridge^7: ^1ERROR^7: ^3QBCore CreateCallback not found or QBCore object issue for %s (QBCore global: %s, QBExport Started: %s)^7", callbackName, tostring(QBCore), Utils.Helpers.isStarted(actualQBExportName)))
                    end
                end
            elseif actualESXExportName and Utils.Helpers.isStarted(actualESXExportName) then
                -- ESX is initialized to the global ESX by starter.lua
                if ESX and ESX.RegisterServerCallback then
                    ESX.RegisterServerCallback(callbackName, adaptedFunction)
                else
                    if Config.System and Config.System.ServerDebugMode then
                        print(string.format("^6Bridge^7: ^1ERROR^7: ^3ESX RegisterServerCallback not found or ESX object issue for %s (ESX global: %s, ESXExport Started: %s)^7", callbackName, tostring(ESX), Utils.Helpers.isStarted(actualESXExportName)))
                    end
                end
            else
                if Config.System and Config.System.ServerDebugMode then
                    print(string.format("^6Bridge^7: ^1ERROR^7: ^3Can\'t find any script to register callback with (QB S:%s, ESX S:%s, OXLib S:%s)^7\t%s", 
                        tostring(actualQBExportName and Utils.Helpers.isStarted(actualQBExportName)), 
                        tostring(actualESXExportName and Utils.Helpers.isStarted(actualESXExportName)), 
                        tostring(actualOXLibExportName and Utils.Helpers.isStarted(actualOXLibExportName)), 
                        callbackName))
                end
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
    -- Wrap debugPrint with ClientDebugMode check
    if Config.System and Config.System.ClientDebugMode then
        debugPrint("^6Bridge^7: ^3Triggering callback^7:", callbackName)
        print(string.format("--- CLIENT triggerCallback DEBUG --- For: %s", callbackName))
        print(string.format("--- CLIENT triggerCallback DEBUG --- OXLibExport var value: '%s', QBExport var value: '%s'", tostring(OXLibExport), tostring(QBExport)))
    end

    local isOxLibStarted = Utils.Helpers.isStarted('ox_lib')
    local isQbCoreStarted = Utils.Helpers.isStarted('qb-core')
    local currentOxLib = nil -- This will hold exports.ox_lib if used
    local currentQbCore = nil
    local esxExportObject = nil

    if isOxLibStarted then
        currentOxLib = exports.ox_lib -- Still fetch it for the fallback direct export check
        if Config.System and Config.System.ClientDebugMode then
            print(string.format("--- CLIENT triggerCallback DEBUG --- ox_lib export object potentially fetched. Type: %s", type(currentOxLib)))
        end
    end

    if isQbCoreStarted then
        if exports['qb-core'] and type(exports['qb-core'].GetCoreObject) == 'function' then
            currentQbCore = exports['qb-core']:GetCoreObject()
            if Config.System and Config.System.ClientDebugMode then
                print(string.format("--- CLIENT triggerCallback DEBUG --- qb-core GetCoreObject fetched. Type: %s", type(currentQbCore)))
            end
        else
            if Config.System and Config.System.ClientDebugMode then
                print(string.format("--- CLIENT triggerCallback ERROR --- qb-core export or GetCoreObject function not found. isQbCoreStarted: %s", tostring(isQbCoreStarted)))
            end
            isQbCoreStarted = false
        end
    end

    if Utils.Helpers.isStarted(ESXExport) then
        esxExportObject = exports[ESXExport]
        if Config.System and Config.System.ClientDebugMode then
            print(string.format("--- CLIENT triggerCallback DEBUG --- es_extended export object fetched. Type: %s", type(esxExportObject)))
        end
    end

    -- Attempt ox_lib methods first
    if isOxLibStarted then
        -- Try global lib.callback.await (This is the primary and often only correct way for ox_lib awaitable callbacks)
        if lib and lib.callback and lib.callback.await and type(lib.callback.await) == 'function' then
            if Config.System and Config.System.ClientDebugMode then
                print(string.format("--- CLIENT triggerCallback DEBUG --- Attempting global lib.callback.await for: %s", callbackName))
            end
            local status, res_or_err = pcall(lib.callback.await, callbackName, false, ...)
            if status then
                if Config.System and Config.System.ClientDebugMode then
                    print(string.format("--- CLIENT triggerCallback SUCCESS --- via global lib.callback.await for: %s", callbackName))
                end
                return res_or_err
            else
                if Config.System and Config.System.ClientDebugMode then
                    print(string.format("^1--- CLIENT triggerCallback PFAIL --- global lib.callback.await for %s. Error: %s. Falling through to other frameworks.^7", callbackName, tostring(res_or_err)))
                end
            end
        else
            if Config.System and Config.System.ClientDebugMode then
                print(string.format("--- CLIENT triggerCallback INFO --- Global lib.callback.await not found or not a function for %s. Falling through to other frameworks.", callbackName))
            end
        end
    end

    -- If ox_lib attempts failed or ox_lib not started, try QBCore
    if isQbCoreStarted and currentQbCore and currentQbCore.Functions and currentQbCore.Functions.TriggerCallback then
        if Config.System and Config.System.ClientDebugMode then
            print(string.format("--- CLIENT triggerCallback DEBUG --- Using QBCore trigger for: %s", callbackName))
        end
        local p = promise.new()
        currentQbCore.Functions.TriggerCallback(callbackName, function(cbResult)
            p:resolve(cbResult)
        end, ...)
        return Citizen.Await(p)
    end

    -- If QBCore failed or not started, try ESX
    if esxExportObject and esxExportObject.TriggerServerCallback then
        if Config.System and Config.System.ClientDebugMode then
            print(string.format("--- CLIENT triggerCallback DEBUG --- Using ESX trigger for: %s", callbackName))
        end
        local p = promise.new()
        esxExportObject.TriggerServerCallback(callbackName, function(cbResult)
            p:resolve(cbResult)
        end, ...)
        return Citizen.Await(p)
    end

    -- All methods failed
    if Config.System and Config.System.ClientDebugMode then
        print(string.format("^6Bridge^7: ^1ERROR^7: ^3Can't find any script to trigger callback for %s. (OxGlobalLibUsable: %s, QbUsable: %s, EsxUsable: %s)^7",
            callbackName,
            tostring(isOxLibStarted and lib and lib.callback and lib.callback.await and type(lib.callback.await) == 'function'),
            tostring(isQbCoreStarted and currentQbCore and currentQbCore.Functions and currentQbCore.Functions.TriggerCallback),
            tostring(esxExportObject and esxExportObject.TriggerServerCallback)
        ))
    end
    return nil
end