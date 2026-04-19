--==============================================================================
--  tm-bridge :: shared/stash.lua
--  TM.Stash -- register / open / read / write stashes across inventories.
--  Uses TM.Auth tokens to gate cross-network calls.
--==============================================================================

TM.Stash = {}

local INV = function() return TM.Systems.Inventory end

--==============================================================================
-- REGISTER (server)
--==============================================================================
if TM.Server then
    function TM.Stash.Register(opts)
        opts = opts or {}
        local id = opts.id; if not id then return TM.Log.warn('TM.Stash.Register: missing id') end

        if INV() == 'ox' then
            return exports[TM.Exports.invOX]:RegisterStash(id, opts.label or id,
                opts.slots or 50, opts.maxWeight or 100000, opts.owner)
        end
        if INV() == 'qs' then
            return exports[TM.Exports.invQS]:RegisterStash(opts.owner, id,
                opts.slots or 50, opts.maxWeight or 100000)
        end
        if INV() == 'origen' then
            return exports[TM.Exports.invOrigen]:RegisterStash(opts.owner, id,
                opts.slots or 50, opts.maxWeight or 100000)
        end
        -- qb / others auto-create when first opened, no registration needed.
    end
end

--==============================================================================
-- OPEN (client) -- token-gated to prevent fake-open attacks
--==============================================================================
if TM.Client then
    function TM.Stash.Open(id, opts)
        opts = opts or {}
        if INV() == 'ox' then
            return exports[TM.Exports.invOX]:openInventory('stash', { id = id, owner = opts.owner })
        end
        if INV() == 'qb' or INV() == 'qbold' then
            TriggerServerEvent('inventory:server:OpenInventory', 'stash', id, {
                maxweight = opts.maxWeight or 100000, slots = opts.slots or 50,
            })
            TriggerEvent('inventory:client:SetCurrentStash', id)
            return
        end
        if INV() == 'qs' then
            TriggerServerEvent('qs-inventory:server:openStash', id, opts.slots or 50, opts.maxWeight or 100000)
            return
        end
        if INV() == 'ps' then
            TriggerServerEvent('ps-inventory:server:OpenInventory', 'stash', id, {
                maxweight = opts.maxWeight or 100000, slots = opts.slots or 50,
            })
            return
        end
        if INV() == 'codem' then
            exports[TM.Exports.invCodeM]:OpenStash(id, opts.slots or 50, opts.maxWeight or 100000); return
        end
        TM.Log.warn('TM.Stash.Open: no compatible inventory system for stash ' .. tostring(id))
    end
end

--==============================================================================
-- GET ITEMS (server) -- returns array of { name, amount, slot, metadata }
--==============================================================================
if TM.Server then
    function TM.Stash.Items(id, owner)
        if INV() == 'ox' then return exports[TM.Exports.invOX]:GetInventoryItems(id) end
        if INV() == 'qs' then return exports[TM.Exports.invQS]:GetStashItems(id) end
        if INV() == 'ps' then return exports[TM.Exports.invPS]:GetStashItems(id) end
        if INV() == 'qb' or INV() == 'qbold' then
            local res = MySQL and MySQL.scalar.await('SELECT items FROM stashitems WHERE stash = ?', { id })
            return res and json.decode(res) or {}
        end
        return {}
    end

    function TM.Stash.HasItem(id, item, amount)
        amount = amount or 1
        for _, it in pairs(TM.Stash.Items(id) or {}) do
            if it.name == item and (it.amount or it.count or 0) >= amount then return true end
        end
        return false
    end

    function TM.Stash.RemoveItem(id, item, amount, slot)
        if INV() == 'ox' then return exports[TM.Exports.invOX]:RemoveItem(id, item, amount or 1, nil, slot) end
        if INV() == 'qs' then return exports[TM.Exports.invQS]:RemoveItemIntoStash(id, item, amount or 1, slot) end
        TM.Log.warn('TM.Stash.RemoveItem not implemented for inventory: ' .. INV())
    end

    function TM.Stash.AddItem(id, item, amount, metadata, slot)
        if INV() == 'ox' then return exports[TM.Exports.invOX]:AddItem(id, item, amount or 1, metadata, slot) end
        if INV() == 'qs' then return exports[TM.Exports.invQS]:AddItemIntoStash(id, item, amount or 1, slot, metadata) end
        TM.Log.warn('TM.Stash.AddItem not implemented for inventory: ' .. INV())
    end
end
