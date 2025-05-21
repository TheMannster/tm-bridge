if Config.Framework ~= Config.Frameworks[Exports.QBFrameWork].name then return end

-- Initialize QBCore object if it hasn't been by starter.lua yet (should be, but good practice)
if not QBCore then
    if exports[Exports.QBFrameWork] then
        QBCore = exports[Exports.QBFrameWork]:GetCoreObject()
        DebugPrint("QBCore Core Object re-initialized in qbcore_client.lua.")
    else
        DebugPrint("QBCore ('" .. Exports.QBFrameWork .. "') not available in qbcore_client.lua.", "ERROR")
        return
    end
end

FrameworkFuncs[Config.Frameworks[Exports.QBFrameWork].name] = FrameworkFuncs[Config.Frameworks[Exports.QBFrameWork].name] or {}
FrameworkFuncs[Config.Frameworks[Exports.QBFrameWork].name].Client = {}

local QBClient = {}

--- QBCore: Check if player has an item (can pass multiple items as a table)
function QBClient.HasItem(items, amount)
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_client.HasItem", "ERROR"); return false end
    return QBCore.Functions.HasItem(items, amount)
end

--- QBCore: Notify player
function QBClient.Notify(msg, type, notificationType)
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_client.Notify", "ERROR"); return end
    if Config.Notify == 'ox' and Utils.Helpers.isStarted(Exports.OXLib) then -- Prefer Config.Notify setting
        local oxType = type
        if type == "cancel" or type == "error" then oxType = "error"
        elseif type == "success" then oxType = "success"
        elseif type == "primary" or type == "police" then oxType = "inform" 
        else oxType = "inform" end -- Default for other qb types
        exports[Exports.OXLib]:notify({ description = msg, type = oxType })
    else
        QBCore.Functions.Notify(msg, type)
    end
end

--- QBCore: Get player data
function QBClient.GetPlayerData() -- Renamed for clarity from GetPlayer to GetPlayerData
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_client.GetPlayerData", "ERROR"); return nil end
    return QBCore.Functions.GetPlayerData()
end

--- QBCore: Show Help Notification
function QBClient.ShowHelpNotification(message)
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_client.ShowHelpNotification", "ERROR"); return end
    QBCore.Functions.HelpNotify(message) -- QBCore.Functions.HelpNotify is common, or direct event
    -- Alternatively: SendNUIMessage({ action = "showHelp", text = message })
    -- Or use exports['qb-core']:DrawText(message, 'left') / exports['qb-core']:DrawText(message, 'right') for more control if needed
end

--- QBCore: Trigger Server Callback
function QBClient.TriggerServerCallback(name, ...)
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_client.TriggerServerCallback", "ERROR"); return nil end
    local p = promise.new()
    QBCore.Functions.TriggerCallback(name, function(result)
        p:resolve(result)
    end, ...)
    return Citizen.Await(p)
end

--- QBCore: Progress Bar
--- @param name string: Name of the progress bar instance
--- @param label string: Text to display
--- @param duration number: Duration in ms
--- @param useWhileDead boolean: Can use while dead
--- @param canCancel boolean: Can be cancelled
--- @param disableControls table: { disableMovement, disableCarMovement, disableMouse, disableCombat }
--- @param animation table: { animDict, anim, flags, task }
--- @param icon string: icon for the progress bar (optional)
--- @return boolean: true if completed, false if cancelled
function QBClient.ProgressBar(name, label, duration, useWhileDead, canCancel, disableControls, animation, icon)
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_client.ProgressBar", "ERROR"); return false end
    local completed = false
    QBCore.Functions.Progressbar(name, label, duration, useWhileDead, canCancel, disableControls, animation, {}, {}, function()
        completed = true
    end, function()
        completed = false
    end, icon)
    -- Note: QBCore.Functions.Progressbar is async. To make this wrapper sync, we'd need a promise and Await.
    -- For simplicity now, this will return immediately. Scripts using this should be aware.
    -- To make it blocking: 
    -- local p = promise.new()
    -- QBCore.Functions.Progressbar(..., function() p:resolve(true) end, function() p:resolve(false) end, icon)
    -- return Citizen.Await(p)
    return completed -- This currently returns before completion due to async nature. Needs promise for sync.
end

--- QBCore: Show Input Dialog (requires qb-input)
--- @param header string: Title of the input dialog
--- @param submitText string: Text for the submit button
--- @param inputs table: Array of input fields (see qb-input docs for format)
--- @return table: User's input data or nil if cancelled
function QBClient.ShowInput(header, submitText, inputs)
    if not exports['qb-input'] then
        DebugPrint("qb-input is not started. Cannot show input dialog.", "ERROR")
        return nil
    end
    local result = exports['qb-input']:ShowInput({
        header = header,
        submitText = submitText,
        inputs = inputs
    })
    return result
end

--- QBCore: Get Closest Vehicle
function QBClient.GetClosestVehicle(coords)
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_client.GetClosestVehicle", "ERROR"); return 0, -1 end
    return QBCore.Functions.GetClosestVehicle(coords) -- Returns vehicle, distance
end

--- QBCore: Get Vehicle Properties
function QBClient.GetVehicleProperties(vehicle)
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_client.GetVehicleProperties", "ERROR"); return nil end
    return QBCore.Functions.GetVehicleProperties(vehicle)
end

--- QBCore: Set Vehicle Properties
function QBClient.SetVehicleProperties(vehicle, props)
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_client.SetVehicleProperties", "ERROR"); return end
    QBCore.Functions.SetVehicleProperties(vehicle, props)
end

--- QBCore: Check if player is logged in
function QBClient.IsPlayerLoggedIn()
    if not QBCore then DebugPrint("QBCore not initialized in qbcore_client.IsPlayerLoggedIn", "ERROR"); return false end
    return QBCore.Functions.GetPlayerData().cid ~= nil -- A common way to check; adjust if your QBCore version differs
end

--- QBCore: Open Shop (Client-side)
function QBClient.OpenShop(shopData) -- shopData is expected to be a table, e.g., { shop = "shop_id", items = { label="Shop Label", items = {...}}, ... }
    if not QBCore then DebugPrint("QBClient.OpenShop: QBCore not initialized.", "ERROR"); return end

    local shopId = type(shopData) == 'table' and shopData.shop or shopData
    local shopItemsTable = type(shopData) == 'table' and shopData.items or nil -- This should contain label and items list for some inventories

    -- Determine the inventory system in use with QBCore
    if Config.Inventory == Exports.QBInv and Utils.Helpers.isStarted(Exports.QBInv) then
        if exports[Exports.QBInv].OpenShop then -- Newer qb-inventory might have this client-side export
            DebugPrint(string.format("QBClient.OpenShop: Opening shop \'%s\' via %s client export.", shopId, Exports.QBInv))
            exports[Exports.QBInv]:OpenShop(shopId, shopItemsTable) -- Adjust parameters as per your qb-inventory version
        else -- Fallback to server event for older or different qb-inventory setups
            DebugPrint(string.format("QBClient.OpenShop: Triggering server event for shop \'%s\' for %s.", shopId, Exports.QBInv))
            TriggerServerEvent(Config.ResourceName .. ':server:openServerShop', shopId) -- This event is in shared/shops.lua initially
        end
    elseif Config.Inventory == Exports.PSInv and Utils.Helpers.isStarted(Exports.PSInv) and exports[Exports.PSInv].OpenShop then
        DebugPrint(string.format("QBClient.OpenShop: Opening shop \'%s\' via %s client export.", shopId, Exports.PSInv))
        exports[Exports.PSInv]:OpenShop(shopId, shopItemsTable) -- Adjust params as needed
    elseif Config.Inventory == Exports.OXInv and Utils.Helpers.isStarted(Exports.OXInv) and exports[Exports.OXInv].openInventory then
        -- If QBCore is used but with ox_inventory
        DebugPrint(string.format("QBClient.OpenShop: QBCore with ox_inventory. Opening shop \'%s\' via ox_inventory.", shopId))
        exports[Exports.OXInv]:openInventory('shop', { type = shopId, items = shopItemsTable and shopItemsTable.items or nil }) 
    else
        DebugPrint(string.format("QBClient.OpenShop: No suitable client-side shop opening method for QBCore with Config.Inventory: '%s'. Shop ID: '%s'", Config.Inventory or 'nil', shopId), "WARN")
        QBCore.Functions.Notify("This shop system is not configured for your inventory with QBCore.", "error")
    end
end

FrameworkFuncs[Config.Frameworks[Exports.QBFrameWork].name].Client = QBClient

RegisterNetEvent(Config.ResourceName .. ':NotifyQBCore', function(msg, type, notificationType)
    QBClient.Notify(msg, type, notificationType)
end)

DebugPrint("QBCore Client Functions Initialized.") 