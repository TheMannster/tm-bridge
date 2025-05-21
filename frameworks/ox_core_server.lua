if Config.Framework ~= Config.Frameworks[Exports.OXCoreFrameWork].name then return end

-- Ensure ox_lib is available for some functions like callbacks
local oxLibReady = Utils.Helpers.isStarted(Exports.OXLib)
if not oxLibReady then
    DebugPrint("ox_lib not started. Some OX Core server functions (like RegisterCallback) might not work as expected or fall back to other methods.", "WARN")
end

FrameworkFuncs[Config.Frameworks[Exports.OXCoreFrameWork].name] = FrameworkFuncs[Config.Frameworks[Exports.OXCoreFrameWork].name] or {}
FrameworkFuncs[Config.Frameworks[Exports.OXCoreFrameWork].name].Server = {}

local OXCoreServer = {}

--- Get Player Object (Server-side)
function OXCoreServer.GetPlayer(source)
    if not exports[Exports.OXCoreFrameWork] then
        DebugPrint("OXCoreServer.GetPlayer: OX Core export not available.", "ERROR")
        return nil
    end
    return exports[Exports.OXCoreFrameWork]:GetPlayer(source)
end

--- Get Player Name (Server-side)
function OXCoreServer.GetPlayerName(source)
    local player = OXCoreServer.GetPlayer(source)
    return player and player.name or "Unknown"
end

--- Get Player Identifier (e.g., license, steam, discord, etc.)
-- OX Core typically uses stateId or charId as primary identifiers internally.
-- This function might need adjustment based on which specific identifier is desired.
function OXCoreServer.GetPlayerIdentifier(source, idType) -- idType e.g., 'license', 'steam', 'discord'
    local player = OXCoreServer.GetPlayer(source)
    if not player then return nil end
    -- Accessing identifiers: player.charId, player.userId (server id), player.stateId (license for ox_core)
    -- player.identifiers might be a table if ox_core stores them that way (less common)
    if idType == 'stateid' or idType == 'license' then 
        return player.stateId -- Often the primary hardware/game identifier
    elseif idType == 'charid' then
        return player.charId -- Character specific ID
    elseif idType == 'userid' then
        return player.userId -- Server ID
    end
    -- For other identifiers, ox_core might not store them directly on the player object by default.
    -- You might need to query a database or another resource that links ox_core charId to other ids.
    DebugPrint(string.format("OXCoreServer.GetPlayerIdentifier: Identifier type '%s' not directly available or standard on OX Player object.", idType), "INFO")
    return player.stateId -- Default to stateId if specific type not found
end


--- Get Player Groups (Jobs/Gangs) (Server-side)
function OXCoreServer.GetPlayerGroups(source)
    local player = OXCoreServer.GetPlayer(source)
    return player and player:getGroups() or {}
end

--- Check if Player Has Group (Job/Gang) (Server-side)
function OXCoreServer.HasPlayerGroup(source, groupName, minGradeNameOrNumber) -- minGrade can be name or numeric level
    local player = OXCoreServer.GetPlayer(source)
    if not player then return false end
    return player:hasGroup(groupName, minGradeNameOrNumber) -- ox_core player:hasGroup should handle this
end

--- Add Player to Group (Job/Gang) (Server-side)
function OXCoreServer.AddPlayerGroup(source, groupName, gradeName)
    local player = OXCoreServer.GetPlayer(source)
    if not player then 
        DebugPrint("OXCoreServer.AddPlayerGroup: Player not found: " .. tostring(source), "ERROR")
        return false 
    end
    -- Assuming player object from Ox.GetPlayer(source) has an :addGroup method
    -- The exact method might vary based on ox_core version (e.g., player:setGroup, player:updateGroup)
    -- Standard is often player:addGroup(groupName, gradeName)
    if player.addGroup then
        return player:addGroup(groupName, gradeName)
    elseif exports[Exports.OXCoreFrameWork].SetGroup then -- Fallback to direct export if player method missing
        return exports[Exports.OXCoreFrameWork]:SetGroup(player.charId, groupName, gradeName) -- charId is often used
    else
         DebugPrint(string.format("OXCoreServer.AddPlayerGroup: Could not find a method to add group '%s' for player %s.", groupName, source), "ERROR")
        return false
    end
end

--- Remove Player from Group (Job/Gang) (Server-side)
function OXCoreServer.RemovePlayerGroup(source, groupName)
    local player = OXCoreServer.GetPlayer(source)
    if not player then 
        DebugPrint("OXCoreServer.RemovePlayerGroup: Player not found: " .. tostring(source), "ERROR")
        return false 
    end
    if player.removeGroup then
        return player:removeGroup(groupName)
    elseif exports[Exports.OXCoreFrameWork].RemoveGroup then
        return exports[Exports.OXCoreFrameWork]:RemoveGroup(player.charId, groupName)
    else
        DebugPrint(string.format("OXCoreServer.RemovePlayerGroup: Could not find a method to remove group '%s' for player %s.", groupName, source), "ERROR")
        return false
    end
end

--- Get Player Metadata (Server-side)
function OXCoreServer.GetMetadata(source, key)
    local player = OXCoreServer.GetPlayer(source)
    return player and player:get(key) or nil
end

--- Set Player Metadata (Server-side)
function OXCoreServer.SetMetadata(source, key, value)
    local player = OXCoreServer.GetPlayer(source)
    if player then
        return player:set(key, value)
    end
    return false
end

--- Register Server Callback
function OXCoreServer.RegisterCallback(callbackName, handlerFunction)
    if oxLibReady and lib.callback and lib.callback.register then
        lib.callback.register(callbackName, handlerFunction) -- ox_lib callback directly takes (source, ...)
    else
        -- Fallback or error if ox_lib not available for callbacks
        -- QBCore/ESX style callbacks are different, so direct porting isn't simple without ox_lib
        DebugPrint(string.format("OXCoreServer.RegisterCallback: ox_lib not available or lib.callback.register is missing. Cannot register '%s'.", callbackName), "ERROR")
    end
end

--- OX Core: Add Money (Server-side)
-- Typically uses ox_inventory or a dedicated economy script linked to ox_core
function OXCoreServer.AddMoney(source, accountType, amount)
    local player = OXCoreServer.GetPlayer(source)
    if not player then DebugPrint("OXCoreServer.AddMoney: Player not found: " .. tostring(source), "ERROR"); return false end

    if Utils.Helpers.isStarted(Exports.OXInv) and exports[Exports.OXInv].AddAccountMoney then
        -- Assumes ox_inventory might have a direct AddAccountMoney or similar.
        -- The exact function and parameters depend on the inventory/economy system.
        -- This is a conceptual example.
        local success = exports[Exports.OXInv].AddAccountMoney(player.charId, accountType, amount) -- charId or source might be needed
        if success then return true end
        -- Fallback to player object if inventory direct call fails/not available
        if player.addAccountMoney then 
            player:addAccountMoney(accountType, amount)
            return true
        end
        DebugPrint(string.format("OXCoreServer.AddMoney: Could not find AddAccountMoney on ox_inventory or player object for '%s' for player %s.", accountType, source), "WARN")
        return false
    elseif player.addAccountMoney then -- If ox_inventory not primary, try player object directly
        player:addAccountMoney(accountType, amount)
        return true
    else
        DebugPrint(string.format("OXCoreServer.AddMoney: No method found to add money for account '%s' for player %s (ox_inventory not detected or function missing).", accountType, source), "ERROR")
        return false
    end
end

--- OX Core: Remove Money (Server-side)
function OXCoreServer.RemoveMoney(source, accountType, amount)
    local player = OXCoreServer.GetPlayer(source)
    if not player then DebugPrint("OXCoreServer.RemoveMoney: Player not found: " .. tostring(source), "ERROR"); return false end

    if Utils.Helpers.isStarted(Exports.OXInv) and exports[Exports.OXInv].RemoveAccountMoney then
        local success = exports[Exports.OXInv].RemoveAccountMoney(player.charId, accountType, amount)
        if success then return true end
        if player.removeAccountMoney then
            player:removeAccountMoney(accountType, amount)
            return true
        end
        DebugPrint(string.format("OXCoreServer.RemoveMoney: Could not find RemoveAccountMoney on ox_inventory or player object for '%s' for player %s.", accountType, source), "WARN")
        return false
    elseif player.removeAccountMoney then
        player:removeAccountMoney(accountType, amount)
        return true
    else
        DebugPrint(string.format("OXCoreServer.RemoveMoney: No method found to remove money for account '%s' for player %s.", accountType, source), "ERROR")
        return false
    end
end

--- OX Core: Get Money (Server-side)
function OXCoreServer.GetMoney(source, accountType)
    local player = OXCoreServer.GetPlayer(source)
    if not player then DebugPrint("OXCoreServer.GetMoney: Player not found: " .. tostring(source), "ERROR"); return 0 end

    if Utils.Helpers.isStarted(Exports.OXInv) and exports[Exports.OXInv].GetAccount then 
        local account = exports[Exports.OXInv].GetAccount(player.charId, accountType)
        if account then return account.balance or account.money or 0 end -- Property name can vary
        if player.getAccount then -- Fallback to player method
             local acc = player:getAccount(accountType)
            return acc and acc.money or 0
        end
        DebugPrint(string.format("OXCoreServer.GetMoney: Could not find GetAccount on ox_inventory or player object for '%s' for player %s.", accountType, source), "WARN")
        return 0
    elseif player.getAccount then
        local account = player:getAccount(accountType)
        return account and account.money or 0
    else
        DebugPrint(string.format("OXCoreServer.GetMoney: No method found to get money for account '%s' for player %s.", accountType, source), "ERROR")
        return 0
    end
end

--- OX Core: Add Item (Server-side) - Primarily uses ox_inventory
function OXCoreServer.AddItem(source, itemName, count, metadata, slot)
    local player = OXCoreServer.GetPlayer(source)
    if not player then DebugPrint("OXCoreServer.AddItem: Player not found: " .. tostring(source), "ERROR"); return false end

    if Utils.Helpers.isStarted(Exports.OXInv) and exports[Exports.OXInv].AddItem then
        return exports[Exports.OXInv].AddItem(player.charId, itemName, count, metadata, slot) -- charId is often used by ox_inventory
    else
        DebugPrint(string.format("OXCoreServer.AddItem: ox_inventory not started or AddItem export missing. Cannot add item '%s' for player %s.", itemName, source), "ERROR")
        return false
    end
end

--- OX Core: Remove Item (Server-side) - Primarily uses ox_inventory
function OXCoreServer.RemoveItem(source, itemName, count, metadata, slot)
    local player = OXCoreServer.GetPlayer(source)
    if not player then DebugPrint("OXCoreServer.RemoveItem: Player not found: " .. tostring(source), "ERROR"); return false end

    if Utils.Helpers.isStarted(Exports.OXInv) and exports[Exports.OXInv].RemoveItem then
        return exports[Exports.OXInv].RemoveItem(player.charId, itemName, count, metadata, slot)
    else
        DebugPrint(string.format("OXCoreServer.RemoveItem: ox_inventory not started or RemoveItem export missing. Cannot remove item '%s' for player %s.", itemName, source), "ERROR")
        return false
    end
end

--- OX Core: Has Item (Server-side) - Primarily uses ox_inventory
function OXCoreServer.HasItem(source, itemName, count, metadata)
    local player = OXCoreServer.GetPlayer(source)
    if not player then DebugPrint("OXCoreServer.HasItem: Player not found: " .. tostring(source), "ERROR"); return false end

    if Utils.Helpers.isStarted(Exports.OXInv) and exports[Exports.OXInv].Search then 
        -- ox_inventory Search function: Search(ownerType, ownerId, event, query, type)
        -- Example: Search for item by name in player inventory
        -- local items = exports[Exports.OXInv].Search(player.charId, 'slots', itemName) -- Search by name
        -- This needs a more robust implementation based on how Search works and what it returns.
        -- A simpler approach if GetItemCount is available:
        if exports[Exports.OXInv].GetItemCount then
            local itemCount = exports[Exports.OXInv].GetItemCount(player.charId, itemName, metadata, true) -- true for strict metadata match
            return itemCount >= (count or 1)
        else
            -- Fallback: Iterate through player inventory slots if direct count/search is not straightforward.
            -- This is less efficient and depends on inventory structure exposed by ox_inventory.
            DebugPrint(string.format("OXCoreServer.HasItem: ox_inventory GetItemCount not available for '%s'. Implement search logic if needed.", itemName), "WARN")
            return false -- Placeholder
        end
    else
        DebugPrint(string.format("OXCoreServer.HasItem: ox_inventory not started or Search/GetItemCount export missing. Cannot check item '%s' for player %s.", itemName, source), "ERROR")
        return false
    end
end

--- OX Core: Open Shop (Server-side)
-- ox_inventory handles shop opening client-side (exports.ox_inventory:openInventory('shop', {shopId = name}))
-- This server function is a placeholder if a specific setup requires a server trigger.
function OXCoreServer.OpenShop(source, shopData) -- shopData might be shopId or a table
    local player = OXCoreServer.GetPlayer(source)
    if not player then DebugPrint("OXCoreServer.OpenShop: Player not found: " .. tostring(source), "ERROR"); return end

    DebugPrint(string.format("OXCoreServer.OpenShop: Called for player %s, shop data: %s. OX shops are typically client-opened via ox_inventory.", source, type(shopData) == 'table' and shopData.name or shopData), "INFO")
    -- If a server-side trigger for an OX-compatible shop is needed, implement here.
    -- Example: TriggerClientEvent('custom_ox_shop:open', source, shopData)
end

--- OX Core: Register Shop (Server-side) - Primarily uses ox_inventory
function OXCoreServer.RegisterShop(name, label, items, society)
    if Utils.Helpers.isStarted(Exports.OXInv) and exports[Exports.OXInv].RegisterShop then
        DebugPrint(string.format("OXCoreServer.RegisterShop: Registering shop \'%s\' with ox_inventory.", name))
        exports[Exports.OXInv]:RegisterShop(name, {
            name = label,
            inventory = items, -- items the shop sells
            groups = nil, -- example: { police = 0 } or { 'police', 'ambulance' }
            slots = #items + 20, -- total slots in the shop inventory display
            weight = 1000000, -- max weight for the shop inventory display
            society = society -- optional: for society shops (requires society field in items and society grade checks)
        })
    else
        DebugPrint(string.format("OXCoreServer.RegisterShop: ox_inventory not started or RegisterShop export missing. Cannot register shop '%s\'.", name), "ERROR")
    end
end


-- Money and Item functions are typically handled by ox_inventory and should be routed
-- through the bridge's shared/inventoryfunctions.lua if Config.Inventory is 'ox_inventory'
-- For example: Framework.Server.AddItem would call Shared.AddItem which then calls the ox_inventory export.
-- We won't duplicate that logic here directly unless specifically overriding for ox_core without ox_inventory.

FrameworkFuncs[Config.Frameworks[Exports.OXCoreFrameWork].name].Server = OXCoreServer
DebugPrint("OX Core Server Functions Initialized.") 