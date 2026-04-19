--==============================================================================
--  tm-bridge :: shared/shop.lua
--  TM.Shop -- register a shop server-side, open it client-side.  Provides a
--  "selling menu" UX as well that uses TM.Menu under the hood.
--==============================================================================

TM.Shop = {}

local INV = function() return TM.Systems.Inventory end

--==============================================================================
-- REGISTER (server)
--   opts = { id, label, items = { { name, price, amount, metadata, ... } } }
--==============================================================================
if TM.Server then
    function TM.Shop.Register(opts)
        opts = opts or {}
        local id = opts.id; if not id then return TM.Log.warn('TM.Shop.Register: missing id') end

        if INV() == 'ox' then
            return exports[TM.Exports.invOX]:RegisterShop(id, {
                name = opts.label or id, inventory = opts.items, groups = opts.groups,
            })
        end
        if INV() == 'qb' or INV() == 'qbold' then
            -- qb-inventory exposes a "CreateShop" export in newer versions
            local ok = pcall(function()
                exports[TM.Exports.invQB]:CreateShop({ name = id, label = opts.label, items = opts.items })
            end)
            if ok then return true end
        end
        -- ESX: nothing to register; client just opens "shop" with a list
    end
end

--==============================================================================
-- OPEN (client)
--==============================================================================
if TM.Client then
    function TM.Shop.Open(id, opts)
        opts = opts or {}
        if INV() == 'ox' then
            return exports[TM.Exports.invOX]:openInventory('shop', { type = id })
        end
        if INV() == 'qb' or INV() == 'qbold' then
            TriggerServerEvent('inventory:server:OpenInventory', 'shop',
                opts.label or id, { label = opts.label, items = opts.items, slots = #(opts.items or {}) })
            return
        end
        if INV() == 'qs' then
            TriggerServerEvent('qs-inventory:server:openShop', id); return
        end
        TM.Log.warn('TM.Shop.Open: no compatible inventory for ' .. tostring(id))
    end
end

--==============================================================================
-- SELL MENU (client) -- pops a TM.Menu listing what the player has and prompts
-- for how much to sell at each price.
--   spec = {
--      title    = 'Butcher',
--      prices   = { meat = 25, fur = 80 },
--      onSell   = function(item, amount) ... end,
--   }
--==============================================================================
if TM.Client then
    function TM.Shop.SellMenu(spec)
        spec = spec or {}
        local items = TM.Inventory.List()
        local rows  = {}
        for _, inv in pairs(items or {}) do
            local price = spec.prices[inv.name]
            if price then
                rows[#rows + 1] = {
                    title = ('%s x%d  ($%d each)'):format(inv.label or inv.name, inv.amount or inv.count or 1, price),
                    icon  = 'fa-solid fa-coins',
                    onSelect = function()
                        local ans = TM.Input.Open({
                            title  = 'Sell ' .. inv.name,
                            fields = { { type = 'number', name = 'amount', label = 'Amount', default = 1, min = 1, max = inv.amount or inv.count or 1 } },
                        })
                        if ans and tonumber(ans.amount) and tonumber(ans.amount) > 0 then
                            if spec.onSell then spec.onSell(inv.name, tonumber(ans.amount)) end
                        end
                    end,
                }
            end
        end
        if #rows == 0 then
            return TM.Notify.Show(spec.title, 'You have nothing to sell.', 'warn')
        end
        TM.Menu.Open({ title = spec.title or 'Sell', items = rows })
    end
end
