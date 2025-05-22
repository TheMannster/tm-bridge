if Config.Framework ~= Config.Frameworks['esx'].name then return end

-- Initialize ESX object if it hasn't been by starter.lua yet (should be, but good practice)
if not ESX then
    if exports.es_extended then 
        ESX = exports.es_extended:getSharedObject()
        DebugPrint("ESX Shared Object re-initialized in esx_server.lua.")
    else
        DebugPrint("ESX (es_extended) not available in esx_server.lua.", "ERROR")
        return
    end
end

FrameworkFuncs['esx'] = FrameworkFuncs['esx'] or {}
FrameworkFuncs['esx'].Server = {}

local ESXServer = {}

--- Get Player Object (Server-side)
function ESXServer.GetPlayer(source)
    return ESX.GetPlayerFromId(source)
end

--- Get Player Name (Server-side)
function ESXServer.GetPlayerName(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    return xPlayer and xPlayer.getName() or "Unknown"
end

--- Add Money (Server-side)
function ESXServer.AddMoney(source, accountType, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then DebugPrint("ESXServer.AddMoney: Player not found: " .. tostring(source), "ERROR") return end
    
    if accountType == 'cash' or accountType == 'money' then
        xPlayer.addMoney(amount)
    elseif accountType == 'bank' then
        xPlayer.addAccountMoney('bank', amount)
    -- TODO: Add other account types if ESX supports them (e.g., 'black_money')
    else
        DebugPrint(string.format("ESXServer.AddMoney: Unknown account type '%s' for player %s.", accountType, source), "WARN")
    end
end

--- Remove Money (Server-side)
function ESXServer.RemoveMoney(source, accountType, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then DebugPrint("ESXServer.RemoveMoney: Player not found: " .. tostring(source), "ERROR") return end

    if accountType == 'cash' or accountType == 'money' then
        xPlayer.removeMoney(amount)
    elseif accountType == 'bank' then
        xPlayer.removeAccountMoney('bank', amount)
    -- TODO: Add other account types
    else
        DebugPrint(string.format("ESXServer.RemoveMoney: Unknown account type '%s' for player %s.", accountType, source), "WARN")
    end
end

--- Get Money (Server-side)
function ESXServer.GetMoney(source, accountType)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then DebugPrint("ESXServer.GetMoney: Player not found: " .. tostring(source), "ERROR") return 0 end

    if accountType == 'cash' or accountType == 'money' then
        return xPlayer.getMoney()
    elseif accountType == 'bank' then
        local account = xPlayer.getAccount('bank')
        return account and account.money or 0
    -- TODO: Add other account types
    else
        DebugPrint(string.format("ESXServer.GetMoney: Unknown account type '%s' for player %s.", accountType, source), "WARN")
        return 0
    end
end

--- Add Item (Server-side)
function ESXServer.AddItem(source, itemName, count, metadata)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then DebugPrint("ESXServer.AddItem: Player not found: " .. tostring(source), "ERROR") return end
    -- ESX addInventoryItem doesn't directly support metadata in the same way as some other frameworks.
    -- Metadata (like durability) is often handled by custom logic or specific inventory add-ons.
    xPlayer.addInventoryItem(itemName, count)
    if metadata then
        DebugPrint(string.format("ESXServer.AddItem: Metadata for item '%s' (player %s) was provided but ESX addInventoryItem doesn\'t natively support it. Implement custom handling if needed.", itemName, source), "INFO")
    end
end

--- Remove Item (Server-side)
function ESXServer.RemoveItem(source, itemName, count, slot) -- slot might not be used by core ESX remove
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then DebugPrint("ESXServer.RemoveItem: Player not found: " .. tostring(source), "ERROR") return end
    xPlayer.removeInventoryItem(itemName, count)
    if slot then
        DebugPrint(string.format("ESXServer.RemoveItem: Slot '%s' for item '%s' (player %s) was provided but ESX removeInventoryItem doesn\'t natively use it.", slot, itemName, source), "INFO")
    end
end

--- Check if player has item (Server-side)
function ESXServer.HasItem(source, itemName, count)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then DebugPrint("ESXServer.HasItem: Player not found: " .. tostring(source), "ERROR") return false end
    local item = xPlayer.getInventoryItem(itemName)
    return item and item.count >= (count or 1)
end

--- Register Usable Item (Server-side)
function ESXServer.RegisterUsableItem(itemName, callback)
    ESX.RegisterUsableItem(itemName, callback) -- Callback directly receives (source)
end

--- Register Server Callback
function ESXServer.RegisterCallback(callbackName, handlerFunction)
    ESX.RegisterServerCallback(callbackName, function(source, cb, ...)
        local result = handlerFunction(source, ...)
        cb(result)
    end)
end

--- Get Player Job (Server-side)
function ESXServer.GetPlayerJob(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    return xPlayer and xPlayer.job or nil
end

--- Set Player Job (Server-side)
function ESXServer.SetPlayerJob(source, jobName, grade)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        xPlayer.setJob(jobName, grade or 0)
    else
        DebugPrint("ESXServer.SetPlayerJob: Player not found: " .. tostring(source), "ERROR")
    end
end

--- Set Player Status (e.g., hunger, thirst) (Server-side)
-- This triggers a client event that ESX default status scripts listen to.
function ESXServer.SetPlayerStatus(source, statusName, value)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        -- ESX typically uses esx_status:add for hunger/thirst, which expects a value to add/remove, not set directly.
        -- If value is a direct percentage (0-100), you might need to calculate difference or use a different event/method if available.
        -- For simplicity, this example directly calls 'esx_status:set', assuming such an event exists or is custom.
        -- A more common pattern is to get current, calculate diff, then use 'add'.
        -- Or, for needs like hunger/thirst, often the value is 0-1000000.
        -- Let's assume value is 0-1000000 as per jim_bridge's ConsumeSuccess for ESX
        if statusName == 'hunger' or statusName == 'thirst' then
             TriggerClientEvent('esx_status:set', source, statusName, value) -- value should be 0-1000000
        else
            DebugPrint(string.format("ESXServer.SetPlayerStatus: Status '%s' not directly handled for ESX. Implement custom logic.", statusName), "WARN")
        end
    else
        DebugPrint("ESXServer.SetPlayerStatus: Player not found: " .. tostring(source), "ERROR")
    end
end

-- TODO: Add more ESX specific server functions (e.g., GetPlayerGang, SetPlayerGang, GetMetadata, SetMetadata)

--- ESX: Open Shop (Server-side, typically for inventories that need a server trigger)
-- ESX with ox_inventory usually opens shops client-side via exports[Exports.OXInv]:openInventory('shop', { type = data.shop })
-- This function is a placeholder or for ESX setups that DO require a server-side trigger for specific shop types.
function ESXServer.OpenShop(source, shopData)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then DebugPrint("ESXServer.OpenShop: Player not found: " .. tostring(source), "ERROR"); return end

    -- Example: If using a custom event or a non-standard ESX shop system that needs a server trigger
    -- TriggerClientEvent('custom_esx_shop:open', source, shopData.name, shopData.items)
    DebugPrint(string.format("ESXServer.OpenShop: Called for player %s, shop \'%s\'. ESX typically handles shops client-side or via ox_inventory. Ensure your setup matches.", source, shopData.name or 'unknown'), "INFO")
    -- If your ESX setup uses a specific server-side export for opening shops (less common), call it here.
    -- For example: exports.some_shop_script:OpenPlayerShop(source, shopData.name, shopData.items)
end

--- ESX: Register Shop (Server-side)
-- This is primarily for ox_inventory when used with ESX.
function ESXServer.RegisterShop(name, label, items, society)
    if Utils.Helpers.isStarted(Exports.OXInv) then
        DebugPrint(string.format("ESXServer.RegisterShop: Registering shop \'%s\' with ox_inventory.", name))
        exports[Exports.OXInv]:RegisterShop(name, {
            name = label,
            inventory = items, -- these are the items the shop SELLS
            society = society, -- optional for society shops
            groups = nil, -- optional: { [jobName] = gradeLevel, ... } to restrict access
            slots = 50, -- optional: number of slots in the shop inventory display
            weight = 1000000 -- optional: max weight for the shop display
        })
    else
        DebugPrint(string.format("ESXServer.RegisterShop: Attempted to register shop \'%s\' but ox_inventory is not started. ESX shop registration usually relies on it.", name), "WARN")
    end
end

--- ESX: Show Notification to a specific player (Server-side)
function ESXServer.ShowNotificationToPlayer(playerId, message, type, duration)
    if not ESX then DebugPrint("ESX not initialized in ESXServer.ShowNotificationToPlayer", "ERROR"); return end
    -- ESX commonly uses TriggerClientEvent to send a notification to a specific client.
    -- The client would then use its local ESX.ShowNotification or a registered event.
    -- We have `tm-bridge/shared/notify.lua` which registers `:DisplayESXNotify` for this.
    TriggerClientEvent(Config.ResourceName .. ':DisplayESXNotify', playerId, type, message, duration or 4000) 
    DebugPrint(string.format("ESXServer.ShowNotificationToPlayer: Sent to %s - Msg: %s, Type: %s", playerId, message, type))
end

FrameworkFuncs['esx'].Server = ESXServer
DebugPrint("ESX Server Functions Initialized.") 