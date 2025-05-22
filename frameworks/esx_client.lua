if Config.Framework ~= Config.Frameworks['esx'].name then return end

-- Initialize ESX object if it hasn't been by starter.lua yet (should be, but good practice)
if not ESX then
    if exports.es_extended then 
        ESX = exports.es_extended:getSharedObject()
        DebugPrint("ESX Shared Object re-initialized in esx_client.lua.")
    else
        DebugPrint("ESX (es_extended) not available in esx_client.lua.", "ERROR")
        return
    end
end

FrameworkFuncs[Config.Frameworks[Exports.ESXFrameWork].name] = FrameworkFuncs[Config.Frameworks[Exports.ESXFrameWork].name] or {}
FrameworkFuncs[Config.Frameworks[Exports.ESXFrameWork].name].Client = {}

local ESXClient = {}

--- Get Player Data (Client-side)
function ESXClient.GetPlayerData()
    return ESX.GetPlayerData()
end

--- Show Notification (Client-side)
-- Note: tm-bridge's shared/notify.lua already handles ESX notifications if Config.Notify is 'esx'.
-- This function provides a direct way if a script specifically wants to use ESX notifications via FrameworkFuncs.
function ESXClient.ShowNotification(message, type, duration)
    if exports.esx_notify and exports.esx_notify.Notify then
        exports.esx_notify:Notify(type or 'inform', duration or 4000, message)
    elseif ESX.ShowNotification then -- Fallback to core ESX notification if esx_notify is not present
        ESX.ShowNotification(message)
        DebugPrint("Used ESX.ShowNotification as esx_notify was not found.", "WARN")
    else
        DebugPrint("No ESX notification function found (esx_notify or ESX.ShowNotification).", "ERROR")
    end
end

--- Trigger Server Callback (Client-side)
function ESXClient.TriggerServerCallback(callbackName, ...)
    local args = {...}
    local p = promise.new()
    ESX.TriggerServerCallback(callbackName, function(result)
        p:resolve(result)
    end, table.unpack(args))
    return Citizen.Await(p)
end

--- Get Player Job (Client-side)
function ESXClient.GetPlayerJob()
    local playerData = ESX.GetPlayerData()
    return playerData and playerData.job or nil
end

--- Get Player Gang (Client-side)
function ESXClient.GetPlayerGang()
    local playerData = ESX.GetPlayerData()
    return playerData and playerData.gang or nil
end

--- Create Progress Bar (Client-side)
-- This mirrors the structure from jim_bridge's make/progressBars.lua for ESX
function ESXClient.ProgressBar(label, time, options)
    options = options or {}
    ESX.Progressbar(label, time, {
        FreezePlayer = options.freezePlayer or true,
        animation = {
            type = options.animType, -- e.g., "scenario", "anim"
            dict = options.animDict,
            scenario = options.scenarioName,
            anim = options.animName, -- if type is "anim"
            flag = options.animFlag
        },
        onFinish = options.onFinish or function() end,
        onCancel = options.onCancel or function() end
    })
end

--- ESX: Open Shop (Client-side)
function ESXClient.OpenShop(shopData) -- shopData is expected to be a table, e.g., { shop = "shop_id", items = {...}, ... }
    if not ESX then DebugPrint("ESXClient.OpenShop: ESX not initialized.", "ERROR"); return end

    local shopId = type(shopData) == 'table' and shopData.shop or shopData -- Allow passing shopId string or full table

    if Config.Inventory == Exports.OXInv and Utils.Helpers.isStarted(Exports.OXInv) and exports[Exports.OXInv].openInventory then
        DebugPrint(string.format("ESXClient.OpenShop: Opening shop \'%s\' via ox_inventory.", shopId))
        exports[Exports.OXInv]:openInventory('shop', { type = shopId, items = shopData.items }) -- Pass items if available in shopData for ox_inv
    elseif exports.esx_menu_default and exports.esx_menu_default.Open then 
        -- This is a conceptual fallback if a generic ESX menu is used for shops.
        -- The actual implementation would depend heavily on how shops are structured in such a setup.
        -- Typically, shop items would be fetched from the server or a config.
        DebugPrint(string.format("ESXClient.OpenShop: Opening shop \'%s\' via esx_menu_default (conceptual). Requires specific shop setup.", shopId), "INFO")
        -- Example: local shopItems = ESXClient.TriggerServerCallback('your_script:getShopItems', shopId)
        -- Then build and open the menu with shopItems.
        -- ESX.UI.Menu.Open('default', GetCurrentResourceName(), shopId, {elements = ...}, function(data, menu) ... end, function(data,menu) menu.close() end)
        ESX.ShowNotification("Shop opening with esx_menu_default is not fully implemented in bridge.")
    else
        DebugPrint(string.format("ESXClient.OpenShop: No primary shop opening method found for ESX (ox_inventory or esx_menu_default). Shop ID: %s", shopId), "WARN")
        ESX.ShowNotification("This shop is not configured for ESX.")
    end
end

--- ESX: Check if player has item (Client-side)
-- Note: For ESX, client-side item checks are often less reliable for critical logic due to inventory data sync.
-- Server-side checks (ESXServer.HasItem) are preferred for transaction validation.
-- This function checks loaded player data, which might not always be up-to-date for all inventory systems.
function ESXClient.HasItem(itemName, count)
    if not ESX then DebugPrint("ESXClient.HasItem: ESX not initialized.", "ERROR"); return false end
    local playerData = ESX.GetPlayerData()
    if not playerData or not playerData.inventory then 
        DebugPrint("ESXClient.HasItem: Player data or inventory not available.", "WARN"); 
        return false 
    end

    local itemCount = 0
    for _, item in pairs(playerData.inventory) do
        if item.name == itemName then
            itemCount = itemCount + (item.count or 0)
        end
    end
    return itemCount >= (count or 1)
end

--- ESX: Show Input Dialog (Client-side)
-- This wraps the basic ESX UI Menu dialog for input.
function ESXClient.ShowInputDialog(title, opts)
    if not ESX or not ESX.UI or not ESX.UI.Menu or not ESX.UI.Menu.Open then
        DebugPrint("ESXClient.ShowInputDialog: ESX UI Menu not available.", "ERROR")
        return nil
    end

    local results = {}
    local completedInputs = 0
    local totalInputs = #opts

    local function requestInput(index)
        if index > totalInputs then
            -- All inputs collected, need a way to return results to the caller of ShowInputDialog
            -- This is tricky because ESX.UI.Menu.Open is async with callbacks.
            -- The original input.lua handled this by blocking with `while value == nil do Wait(0) end` PER input.
            -- To make this function genuinely usable and awaitable, it would need a promise wrapper around the whole sequence.
            -- For now, we will replicate the blocking behavior for each input to match original `input.lua` flow.
            -- A true async version would return a promise immediately and resolve it once all inputs are done.
            return
        end

        local opt = opts[index]
        local prompt = opt.text or opt.label or "Enter value"
        if (opt.type == "radio" or opt.type == "select") and opt.options then
            local choices = ""
            for j, choice in ipairs(opt.options) do
                choices = choices .. choice.text .. " (" .. tostring(choice.value) .. ")"
                if j < #opt.options then choices = choices .. ", " end
            end
            prompt = prompt .. " [" .. choices .. "]"
        elseif opt.type == "number" then
            prompt = prompt .. " (number between " .. tostring(opt.min or "any") .. " and " .. tostring(opt.max or "any") .. ")"
        end

        local valueHolder = { value = nil } -- Use a table to pass by reference effectively

        ESX.UI.Menu.Open('dialog', Config.ResourceName, 'input_' .. index, 
            { title = prompt }, 
            function(data, menu) 
                valueHolder.value = data.value
                menu.close()
            end, 
            function(data, menu) 
                valueHolder.value = nil -- Mark as cancelled or closed without submission
                menu.close()
            end
        )

        while valueHolder.value == nil and opts[index] -- Check opts[index] in case it was removed/cancelled from outside somehow
        do 
            Citizen.Wait(0) 
        end
        
        if valueHolder.value == nil then -- Input was cancelled
             DebugPrint("ESX Input Dialog cancelled by user for prompt: " .. prompt, "INFO")
             return nil -- Signal cancellation for the whole dialog
        end

        local finalValue = valueHolder.value
        if opt.type == "number" then 
            finalValue = tonumber(finalValue)
            if opt.min and finalValue < opt.min then finalValue = opt.min end
            if opt.max and finalValue > opt.max then finalValue = opt.max end
        end
        results[opt.name or index] = finalValue
        
        -- Proceed to the next input
        local nextResult = requestInput(index + 1)
        if nextResult == nil and index + 1 <= totalInputs then -- If a subsequent input was cancelled
            return nil
        end
    end

    -- Start the chain of inputs
    requestInput(1)

    -- Check if all inputs were gathered or if it was cancelled
    if #results < totalInputs and totalInputs > 0 then  -- A bit simplistic, relies on name/index population
        local allNamed = true
        for _, opt_check in ipairs(opts) do
            if not results[opt_check.name] then allNamed = false; break end
        end
        if not allNamed and #results < totalInputs then -- if not all inputs have names, rely on count
            return nil -- Indicates cancellation or incomplete input
        end
    end

    return results
end

-- TODO: Add more ESX specific client functions as needed, e.g., for inventory, money, status updates (triggering server events for them)

FrameworkFuncs[Config.Frameworks[Exports.ESXFrameWork].name].Client = ESXClient
DebugPrint("ESX Client Functions Initialized.") 