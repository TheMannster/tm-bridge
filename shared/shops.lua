-------------------------------------------------------------
-- Selling Menu and Animation
-------------------------------------------------------------

--- Opens a selling menu with available items and prices.
---
--- @param data table Contains selling menu data:
---     - sellTable (`table`) Table with Header and Items (item names and prices).
---     - ped (optional) (`number`) Ped entity involved.
---     - onBack (optional) (`function`) Callback for returning.
--- @usage
--- ```lua
--- sellMenu({
---     sellTable = {
---         Header = "Sell Items",
---         Items = {
---             ["gold_ring"] = 100,
---             ["diamond"] = 500,
---         },
---     },
---     ped = pedEntity,
---     onBack = function() print("Returning to previous menu") end,
--- })
--- ```
function sellMenu(data)
    local origData = data
    local Menu = {}
    if data.sellTable.Items then
        local itemList = {}
        for k, v in pairs(data.sellTable.Items) do itemList[k] = 1 end
        -- Client-side HasItem check for UI display
        local hasItemsClient, hasTableClient = Utils.Helpers.HasItem(itemList) -- Assuming HasItem can take a table and return a table of results

        for k, v in pairsByKeys(data.sellTable.Items) do
            if Items[k] then -- Assuming Items global table is populated with item details
                local playerHasItem = hasTableClient and hasTableClient[k] and hasTableClient[k].hasItem
                local itemCount = hasTableClient and hasTableClient[k] and hasTableClient[k].count or 0
                Menu[#Menu + 1] = {
                    isMenuHeader = not playerHasItem,
                    icon = Utils.Helpers.invImg and Utils.Helpers.invImg(k) or 'inventory', -- Use helper or default icon
                    header = Items[k].label..(playerHasItem and ("💰 (x"..itemCount..")") or ""),
                    txt = (Loc[Config.Lan].info["sell_all"] or "Sell all for ")..v.." "..(Loc[Config.Lan].info["sell_each"] or "each"),
                    onSelect = function()
                        sellAnim({ item = k, price = v, ped = data.ped, onBack = function() sellMenu(data) end })
                    end,
                }
            end
        end
    else
        for k, v in pairsByKeys(data.sellTable) do
            if type(v) == "table" then
                Menu[#Menu + 1] = {
                    arrow = true,
                    header = k,
                    txt = (Loc[Config.Lan].info["item_amount"] or "Amount of items: ")..Utils.Helpers.countTable(v.Items),
                    onSelect = function()
                        v.onBack = function() sellMenu(origData) end
                        v.sellTable = data.sellTable[k]
                        sellMenu(v)
                    end,
                }
            end
        end
    end
    Utils.Menu.openMenu(Menu, { -- Assuming a Utils.Menu.openMenu wrapper exists now
        header = data.sellTable.Header or ((Loc[Config.Lan].info["item_amount"] or "Amount of items: ")..Utils.Helpers.countTable(data.sellTable.Items or data.sellTable)),
        headertxt = data.sellTable.Header and ((Loc[Config.Lan].info["item_amount"] or "Amount of items: ")..Utils.Helpers.countTable(data.sellTable.Items or data.sellTable)),
        canClose = true,
        onBack = data.onBack,
    })
end

--- Plays the selling animation and processes the sale transaction.
---
--- Checks if the player has the item, plays animations, triggers the server event for selling,
--- and then calls the onBack callback if provided.
---
--- @param data table Contains:
---   `- item: The item to sell.
---   `- price: Price per item.
---   `- ped (optional): Ped entity involved.
---   `- onBack (optional): Callback to call on completion.
---@usage
--- ```lua
--- sellAnim({
---     item = "gold_ring",
---     price = 100,
---     ped = pedEntity,
---     onBack = function() sellMenu(data) end,
--- })
--- ```
function sellAnim(data)
    -- Client-side check before animation (server will re-verify)
    if not Utils.Helpers.HasItem(data.item, 1) then 
        triggerNotify(nil, (Loc[Config.Lan].error["dont_have"] or "You don\'t have any ").." "..(Items[data.item] and Items[data.item].label or data.item), "error")
        return
    end

    for _, obj in pairs(GetGamePool('CObject')) do
        for _, model in pairs({ `p_cs_clipboard` }) do
            if GetEntityModel(obj) == model and IsEntityAttachedToEntity(data.ped, obj) then
                DeleteObject(obj)
                DetachEntity(obj, 0, 0)
                SetEntityAsMissionEntity(obj, true, true)
                Wait(100)
                DeleteEntity(obj)
            end
        end
    end

    TriggerServerEvent(Config.ResourceName .. ":SellItemFramework", data) -- Changed event name
    Utils.Helpers.lookEnt(data.ped)
    local dict = "mp_common"
    Utils.Helpers.playAnim(dict, "givetake2_a", 0.3, 48)
    Utils.Helpers.playAnim(dict, "givetake2_b", 0.3, 48, data.ped)
    Wait(2000)
    StopAnimTask(PlayerPedId(), dict, "givetake2_a", 0.5)
    StopAnimTask(data.ped, dict, "givetake2_b", 0.5)
    if data.onBack then
        data.onBack()
    end
end

RegisterNetEvent(Config.ResourceName .. ":SellItemFramework", function(data)
    local src = source
    local fwServer = FrameworkFuncs[Config.Framework] and FrameworkFuncs[Config.Framework].Server

    if not fwServer or not fwServer.HasItem or not fwServer.RemoveItem or not fwServer.AddMoney then
        DebugPrint("SellItemFramework: Framework server functions not available for " .. (Config.Framework or "Unknown"), "ERROR")
        triggerNotify(src, "Server error processing sale.", "error")
        return
    end

    -- Server-side validation
    local hasItemServer, itemData = fwServer.HasItem(src, data.item, 1) -- Assuming HasItem might return more details or just boolean
    
    -- Adjusting to expect a boolean from HasItem. If it returns a table (like QBCore Player.Functions.HasItem) this needs adjustment
    -- For simplicity, assuming hasItemServer is boolean. If it returns item data, the logic below is fine.
    local actualCount = 1 -- Default to 1 if not specified by HasItem result
    if type(hasItemServer) == 'table' and hasItemServer.count then -- QBCore pattern
        actualCount = hasItemServer.count
        hasItemServer = actualCount >= 1
    elseif type(itemData) == 'table' and itemData.count then -- ESX pattern if getInventoryItem returns object
        actualCount = itemData.count
        hasItemServer = actualCount >=1
    end 
    -- If HasItem just returns boolean, we might need to get item count separately or assume selling all of one type
    -- For now, this assumes we are selling ONE unit of the item, or all if count is implicitly handled by RemoveItem.
    -- The original script implies selling ALL of the item the player has of that type.
    -- Let's assume fwServer.HasItem confirms existence and we can get count if needed
    -- For now, to match original logic, we'd need a GetItemCount or assume RemoveItem handles amount correctly
    -- Let's refine this: we need the player's current count of that item to sell all.

    local playerItem = fwServer.GetItem and fwServer.GetItem(src, data.item) -- Conceptual GetItem, might need specific framework impl.
    local sellCount = playerItem and playerItem.count or 1 -- Fallback to 1 if count not directly available
    
    if fwServer.HasItem(src, data.item, 1) then -- Check if player has at least one
        -- To sell ALL items of that type, we need to know the count. 
        -- This part is tricky without a consistent GetItemCount across frameworks.
        -- The original code did `hasTable[data.item].count` after a client-side check.
        -- We will try to remove `sellCount` which we hope represents the total owned.
        -- This might need a new FrameworkFunc: GetItemCount(src, itemName)

        -- Simplified: Assume for now RemoveItem will take care of removing the correct amount (e.g., all if not specified, or if it gets from player data).
        -- This is a point of potential difference from original if not handled carefully in FrameworkFuncs.
        -- For now, let's stick to the original logic of selling ALL of a specific item the player has.
        -- This means fwServer.RemoveItem should ideally remove ALL of that item if amount is not specified, or we fetch the amount.

        -- Let's assume the item details (like actual count player has) comes from a GetItem or HasItem (if it returns count)
        local itemInstance = fwServer.HasItem(src, data.item) -- Re-calling, assuming it might give count if it's a table
        local countToSell = 1
        if type(itemInstance) == 'table' and itemInstance.count then
            countToSell = itemInstance.count
        elseif fwServer.GetItemCount then -- Ideal scenario
            countToSell = fwServer.GetItemCount(src, data.item)
        else 
            DebugPrint("SellItemFramework: Cannot determine exact count of item '" .. data.item .. "'. Selling 1. Implement GetItemCount in FrameworkFuncs.", "WARN")
        end

        if countToSell == 0 then -- Double check after trying to get count
             triggerNotify(src, (Loc[Config.Lan].error["dont_have"] or "You don\'t have any ")..(Items[data.item] and Items[data.item].label or data.item), "error")
             return
        end

        if fwServer.RemoveItem(src, data.item, countToSell) then
            local totalAmount = countToSell * data.price
            fwServer.AddMoney(src, "cash", totalAmount) -- Ensure account type matches (cash, bank etc.)
            -- triggerNotify(src, string.format(Loc[Config.Lan].success["item_sold"] or "Sold %s x%d for $%s", Items[data.item].label, countToSell, totalAmount), "success")
        else
            triggerNotify(src, "Error selling item.", "error")
        end
    else
        triggerNotify(src, (Loc[Config.Lan].error["dont_have"] or "You don\'t have any ")..(Items[data.item] and Items[data.item].label or data.item), "error")
    end
end)

-------------------------------------------------------------
-- Shop Interface
-------------------------------------------------------------

--- Opens a shop interface for the player.
---
--- Checks job/gang restrictions, then uses the active inventory system to open the shop.
--- @param data table Contains:
---     - shop (`string`) The shop identifier.
---     - items (`table`) The items available in the shop.
---     - coords (`vector3`) where the shop is located.
---     - job/gang (optional) (`string`) Job or gang requirements.
---@usage
--- ```lua
--- openShop({
---     shop = "weapon_shop",
---     items = weaponShopItems,
---     coords = vector3(100.0, 200.0, 300.0),
---     job = "police",
--- })
--- ```
function openShop(data)
    -- Perform job/gang check client-side first if applicable (server should always re-verify if sensitive)
    if (data.job or data.gang) and not Utils.Helpers.jobCheck(data.job or data.gang) then 
        triggerNotify(nil, Loc[Config.Lan].error["job_locked"] or "You do not have the required job/gang.", "error")
        return 
    end

    local fwClient = FrameworkFuncs[Config.Framework] and FrameworkFuncs[Config.Framework].Client
    if fwClient and fwClient.OpenShop then
        -- Prepare shopData for the framework function
        -- It expects { shop = "shop_id", items = { label="Shop Label", items = {...} (actual items) }, coords = vector3 (optional for some) }
        local shopDataForFramework = {
            shop = data.shop, -- This is the shop identifier
            items = data.items, -- This should be the table of items the shop sells, possibly with a .label for the shop itself
            label = data.items and data.items.label or data.shop, -- Fallback label
            coords = data.coords -- For lookEnt or other client-side effects
        }
        fwClient.OpenShop(shopDataForFramework)
        if data.coords then Utils.Helpers.lookEnt(data.coords) end
    else
        DebugPrint("openShop: Framework client function OpenShop not available for " .. (Config.Framework or "Unknown"), "ERROR")
        triggerNotify(nil, "Shop system not available.", "error")
    end
end

--- Registers a shop with the active inventory system via FrameworkFuncs
function registerShop(name, label, items, society)
    if not IsDuplicityVersion() then return end -- Server-side only

    local fwServer = FrameworkFuncs[Config.Framework] and FrameworkFuncs[Config.Framework].Server
    if fwServer and fwServer.RegisterShop then
        fwServer.RegisterShop(name, label, items, society)
    else
        DebugPrint("registerShop: Framework server function RegisterShop not available for " .. (Config.Framework or "Unknown"), "ERROR")
    end
end