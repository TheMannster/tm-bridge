--==============================================================================
--  tm-bridge :: shared/inventory.lua
--  TM.Inventory -- open / lock / list / canCarry helpers.
--==============================================================================

TM.Inventory = {}

local INV = function() return TM.Systems.Inventory end

--==============================================================================
-- LOCK / UNLOCK (client only)
--==============================================================================
if TM.Client then
    local locked = false

    function TM.Inventory.Lock(state)
        locked = state == true
        if INV() == 'ox' then
            return LocalPlayer.state:set('invBusy', locked, true)
        end
        if INV() == 'qb' or INV() == 'qbold' then
            LocalPlayer.state:set('inv_busy', locked, true)
        end
    end

    function TM.Inventory.IsLocked()
        return locked
    end

    function TM.Inventory.IsOpen()
        if INV() == 'ox' then return LocalPlayer.state.invOpen == true end
        if INV() == 'qs' and TM.HasResource(TM.Exports.invQS) then
            return exports[TM.Exports.invQS]:inInventory() == true
        end
        return false
    end
end

--==============================================================================
-- OPEN PLAYER INVENTORY (client)
--==============================================================================
if TM.Client then
    function TM.Inventory.Open()
        if INV() == 'ox' then return TriggerEvent('ox_inventory:openInventory') end
        if INV() == 'qb' or INV() == 'qbold' then
            TriggerEvent('inventory:client:ToggleInventory')
            return
        end
        if INV() == 'qs' then
            TriggerEvent('qs-inventory:client:openInventory'); return
        end
        if TM.Framework.name == 'esx' then
            TriggerEvent('esx_inventoryhud:openPlayerInventory'); return
        end
        TM.Log.warn('TM.Inventory.Open: no compatible inventory system')
    end
end

--==============================================================================
-- LIST PLAYER ITEMS  (server preferred; client returns local cache)
--==============================================================================
function TM.Inventory.List(src)
    if INV() == 'ox' then
        if TM.Server then return exports[TM.Exports.invOX]:GetInventoryItems(src) end
        return exports[TM.Exports.invOX]:GetPlayerItems()
    end
    if TM.Server then
        local p = TM.Player.Get(src)
        if not p then return {} end
        if TM.Framework.name == 'qbcore' or TM.Framework.name == 'qbox' or TM.Framework.name == 'rsg' then
            return p.PlayerData and p.PlayerData.items or {}
        end
        if TM.Framework.name == 'esx' then
            return p.inventory or {}
        end
    else
        local d = TM.Player.Data()
        return (d and (d.items or d.inventory)) or {}
    end
end

--==============================================================================
-- CAN CARRY (server)
--==============================================================================
if TM.Server then
    function TM.Inventory.CanCarry(src, item, amount)
        if INV() == 'ox' then
            return exports[TM.Exports.invOX]:CanCarryItem(src, item, amount or 1)
        end
        -- QB/ESX: optimistic (always returns true unless inventory says otherwise)
        return true
    end
end
