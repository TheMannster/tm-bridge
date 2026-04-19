--==============================================================================
--  tm-bridge :: shared/items.lua
--  TM.Items -- has / count / add / remove / image / register-useable, plus
--  durability helpers.  Add/remove are server-only (use TM.Items.Has on the
--  client).  Routes to ox_inventory > qb-inventory variants > framework.
--==============================================================================

TM.Items = {}

local INV = function() return TM.Systems.Inventory end

--==============================================================================
-- HAS / COUNT
--==============================================================================
function TM.Items.Count(src, item)
    if INV() == 'ox' then
        return exports[TM.Exports.invOX]:GetItemCount(src, item) or 0
    end
    if TM.Server then
        local p = TM.Player.Get(src)
        if not p then return 0 end
        if TM.Framework.name == 'qbcore' or TM.Framework.name == 'qbox' or TM.Framework.name == 'rsg' then
            local it = p.Functions and p.Functions.GetItemByName and p.Functions.GetItemByName(item)
            return it and it.amount or 0
        end
        if TM.Framework.name == 'esx' then
            local it = p.getInventoryItem and p:getInventoryItem(item)
            return it and it.count or 0
        end
    else
        if TM.Framework.name == 'qbcore' or TM.Framework.name == 'qbox' or TM.Framework.name == 'rsg' then
            local d = TM.Player.Data()
            for _, v in pairs((d and d.items) or {}) do
                if v.name == item then return v.amount end
            end
        end
        if TM.Framework.name == 'esx' then
            local d = TM.Player.Data() or {}
            for _, v in ipairs(d.inventory or {}) do
                if v.name == item then return v.count end
            end
        end
    end
    return 0
end

function TM.Items.Has(src, item, amount)
    return TM.Items.Count(src, item) >= (amount or 1)
end

--==============================================================================
-- IMAGE  (returns nui:// or fallback)
--==============================================================================
function TM.Items.Image(item)
    if INV() == 'ox' then return ('nui://%s/web/images/%s.png'):format(TM.Exports.invOX, item) end
    if INV() == 'qb' or INV() == 'qbold' then
        return ('nui://%s/html/images/%s.png'):format(TM.Exports.invQB, item)
    end
    if INV() == 'qs' then return ('nui://%s/html/images/%s.png'):format(TM.Exports.invQS, item) end
    if INV() == 'ps' then return ('nui://%s/html/images/%s.png'):format(TM.Exports.invPS, item) end
    return nil
end

--==============================================================================
-- ADD / REMOVE  (server only)
--==============================================================================
if TM.Server then
    function TM.Items.Add(src, item, amount, metadata, slot)
        amount = amount or 1
        if INV() == 'ox' then
            return exports[TM.Exports.invOX]:AddItem(src, item, amount, metadata, slot) ~= false
        end
        local p = TM.Player.Get(src)
        if not p then return false end
        if TM.Framework.name == 'qbcore' or TM.Framework.name == 'qbox' or TM.Framework.name == 'rsg' then
            return p.Functions and p.Functions.AddItem and p.Functions.AddItem(item, amount, slot, metadata) == true
        end
        if TM.Framework.name == 'esx' then
            p.addInventoryItem(item, amount, metadata); return true
        end
        return false
    end

    function TM.Items.Remove(src, item, amount, metadata, slot)
        amount = amount or 1
        if INV() == 'ox' then
            return exports[TM.Exports.invOX]:RemoveItem(src, item, amount, metadata, slot) ~= false
        end
        local p = TM.Player.Get(src)
        if not p then return false end
        if TM.Framework.name == 'qbcore' or TM.Framework.name == 'qbox' or TM.Framework.name == 'rsg' then
            return p.Functions and p.Functions.RemoveItem and p.Functions.RemoveItem(item, amount, slot) == true
        end
        if TM.Framework.name == 'esx' then
            p.removeInventoryItem(item, amount); return true
        end
        return false
    end

    --------------------------------------------------------------------------------
    -- Useable item registration -- routes to whichever framework handles it.
    --------------------------------------------------------------------------------
    function TM.Items.RegisterUseable(item, callback)
        if TM.Framework.name == 'qbcore' or TM.Framework.name == 'qbox' or TM.Framework.name == 'rsg' then
            local QB = TM.Framework.Object()
            if QB and QB.Functions and QB.Functions.CreateUseableItem then
                QB.Functions.CreateUseableItem(item, function(src, info) callback(src, info) end)
                return true
            end
        end
        if TM.Framework.name == 'esx' then
            local ESX = TM.Framework.Object()
            if ESX and ESX.RegisterUsableItem then
                ESX.RegisterUsableItem(item, function(src) callback(src) end)
                return true
            end
        end
        if INV() == 'ox' and TM.HasResource(TM.Exports.invOX) then
            -- ox_inventory uses a separate registry; consumers must add `server` callback
            -- in their items.lua; we still provide a TriggerEvent fallback for parity.
        end
        TM.Log.warn('TM.Items.RegisterUseable: no compatible framework for ' .. tostring(item))
    end

    --------------------------------------------------------------------------------
    -- Durability helpers
    --   GetDurability(src, item, slot) -> 0..100
    --   SetDurability(src, item, value, slot)
    --   Damage(src, item, delta, slot) -- deletes the item when it hits 0.
    --------------------------------------------------------------------------------
    local function metaSlot(src, item, slot)
        if INV() == 'ox' then
            local invSlot = exports[TM.Exports.invOX]:GetSlot(src, slot or item)
            return invSlot and invSlot.metadata, invSlot and invSlot.slot
        end
        local p = TM.Player.Get(src); if not p then return nil end
        if p.Functions and p.Functions.GetItemByName then
            local it = p.Functions.GetItemByName(item)
            return it and it.info or it and it.metadata, it and it.slot
        end
    end

    function TM.Items.GetDurability(src, item, slot)
        local meta = metaSlot(src, item, slot)
        if not meta then return 100 end
        return meta.durability or meta.quality or 100
    end

    function TM.Items.SetDurability(src, item, value, slot)
        if INV() == 'ox' then
            local s = slot or exports[TM.Exports.invOX]:GetSlot(src, item)
            s = type(s) == 'table' and s.slot or s
            return exports[TM.Exports.invOX]:SetMetadata(src, s, { durability = value })
        end
        -- QB/ESX: refresh by removing+adding with new metadata
        local meta, s = metaSlot(src, item, slot)
        if not meta then return false end
        meta.durability = value
        TM.Items.Remove(src, item, 1, nil, s)
        TM.Items.Add(src, item, 1, meta, s)
        return true
    end

    function TM.Items.Damage(src, item, delta, slot)
        local cur = TM.Items.GetDurability(src, item, slot)
        local next = math.max(0, cur - (delta or 5))
        if next <= 0 then
            TM.Items.Remove(src, item, 1, nil, slot)
            TM.Notify.Send(src, item, 'broke!', 'error')
            return 0, true
        end
        TM.Items.SetDurability(src, item, next, slot)
        return next, false
    end
end
