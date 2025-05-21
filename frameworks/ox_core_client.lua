if Config.Framework ~= Config.Frameworks[Exports.OXCoreFrameWork].name then return end

-- Ensure ox_lib is available for many OX Core related UI functions
local oxLibReady = Utils.Helpers.isStarted(Exports.OXLib)
if not oxLibReady then
    DebugPrint("ox_lib not started. Some OX Core client functions may not work as expected.", "WARN")
end

FrameworkFuncs[Config.Frameworks[Exports.OXCoreFrameWork].name] = FrameworkFuncs[Config.Frameworks[Exports.OXCoreFrameWork].name] or {}
FrameworkFuncs[Config.Frameworks[Exports.OXCoreFrameWork].name].Client = {}

local OXCoreClient = {}

-- Accessing OxPlayer global, should be initialized by ox_core
-- For functions requiring direct ox_core player object, it would be `Ox.GetPlayer()`

--- Get Local Player Data (Client-side)
-- This provides a subset of information available through OxPlayer global or Ox.GetPlayer()
function OXCoreClient.GetPlayerData()
    if not OxPlayer then 
        DebugPrint("OxPlayer global not available in OXCoreClient.GetPlayerData.", "ERROR")
        return nil 
    end
    return {
        identifier = OxPlayer.charId, -- or .identifier / .stateId / .userId depending on what ox_core version/setup provides
        charId = OxPlayer.charId,
        userId = OxPlayer.userId,
        name = OxPlayer.name,
        firstName = OxPlayer.firstName,
        lastName = OxPlayer.lastName,
        groups = OxPlayer.groups, -- table of groups
        -- Add other relevant player data points accessible from OxPlayer
    }
end

--- Show Notification (Client-side)
function OXCoreClient.ShowNotification(title, message, type, duration) -- duration might not be used by ox_lib notify
    if oxLibReady then
        lib.notify({ title = title, description = message, type = type or "inform" })
    else
        DebugPrint("ox_lib not available for ShowNotification.", "ERROR")
    end
end

--- Show Text UI (Client-side)
function OXCoreClient.ShowTextUI(text, options)
    if oxLibReady then
        lib.showTextUI(text, options) -- options: { icon = icon, position = 'left-center', style = {} }
    else
        DebugPrint("ox_lib not available for ShowTextUI.", "ERROR")
    end
end

--- Hide Text UI (Client-side)
function OXCoreClient.HideTextUI()
    if oxLibReady then
        lib.hideTextUI()
    else
        DebugPrint("ox_lib not available for HideTextUI.", "ERROR")
    end
end

--- Trigger Server Callback (Client-side)
function OXCoreClient.TriggerServerCallback(callbackName, ...)
    if oxLibReady then
        return lib.callback.await(callbackName, false, ...)
    else
        DebugPrint("ox_lib not available for TriggerServerCallback.", "ERROR")
        return nil
    end
end

--- Create Progress Bar (Client-side)
function OXCoreClient.ProgressBar(label, duration, options) -- options matches ox_lib progressBar structure
    if oxLibReady then
        return exports[Exports.OXLib]:progressBar({
            duration = duration,
            label = label,
            useWhileDead = options and options.useWhileDead or false,
            canCancel = options and options.canCancel or true,
            anim = options and options.anim or nil, -- { dict, clip, flag, scenario }
            disable = options and options.disable or { combat = true },
            -- onFinish = options.onFinish (not directly returned by ox_lib progress, it's synchronous)
            -- onCancel = options.onCancel
        })
    else
        DebugPrint("ox_lib not available for ProgressBar.", "ERROR")
        return false -- Indicate failure or non-completion
    end
end

--- Skill Check (Client-side)
function OXCoreClient.SkillCheck(inputs, areas, cb) -- cb receives success (boolean)
    if oxLibReady then
        if cb then -- Asynchronous with callback
           return exports[Exports.OXLib]:skillCheck(inputs, areas, cb)
        else -- Synchronous
            return exports[Exports.OXLib]:skillCheck(inputs, areas)
        end
    else
        DebugPrint("ox_lib not available for SkillCheck.", "ERROR")
        if cb then cb(false) else return false end
    end
end

--- Input Dialog (Client-side)
function OXCoreClient.InputDialog(title, options)
    if oxLibReady then
        return exports[Exports.OXLib]:inputDialog(title, options)
    else
        DebugPrint("ox_lib not available for InputDialog.", "ERROR")
        return nil
    end
end

--- OX Core: Open Shop (Client-side, assumes ox_inventory)
function OXCoreClient.OpenShop(shopData) -- shopData is expected to be a table, e.g., { shop = "shop_id", items = {...}, ... } or just "shop_id"
    if not Utils.Helpers.isStarted(Exports.OXInv) or not exports[Exports.OXInv].openInventory then
        DebugPrint(string.format("OXCoreClient.OpenShop: ox_inventory not started or openInventory export missing. Cannot open shop: %s", type(shopData) == 'table' and shopData.shop or shopData), "ERROR")
        if oxLibReady then lib.notify({ title = "Shop Error", description = "Inventory system not available.", type = "error" }) end
        return
    end

    local shopId = type(shopData) == 'table' and shopData.shop or shopData
    local itemsForShop = type(shopData) == 'table' and shopData.items and shopData.items.items or nil -- if items are nested under an 'items' key
    if not itemsForShop and type(shopData) == 'table' and shopData.items then itemsForShop = shopData.items end -- if items is the direct list

    DebugPrint(string.format("OXCoreClient.OpenShop: Opening shop \'%s\' via ox_inventory.", shopId))
    exports[Exports.OXInv]:openInventory('shop', { type = shopId, items = itemsForShop }) -- ox_inventory uses 'type' for shop identifier
end

--- OX Core: Check if player has item (Client-side, assumes ox_inventory)
function OXCoreClient.HasItem(itemName, count, metadata)
    if not Utils.Helpers.isStarted(Exports.OXInv) then
        DebugPrint("OXCoreClient.HasItem: ox_inventory not started. Cannot check item.", "ERROR")
        return false
    end

    if exports[Exports.OXInv].GetItemCount then
        local itemCount = exports[Exports.OXInv].GetItemCount(itemName, metadata, true) -- Last param for strict metadata match
        return itemCount >= (count or 1)
    else
        DebugPrint("OXCoreClient.HasItem: ox_inventory GetItemCount export is missing.", "ERROR")
        -- As a very basic fallback, could attempt to search player inventory if exposed, but less reliable.
        -- local inv = exports[Exports.OXInv].GetInventory()
        -- if inv and inv.items then ... iterate and count ... end
        return false
    end
end

-- TODO: Add more OX Core/ox_lib specific client functions as needed.

FrameworkFuncs[Config.Frameworks[Exports.OXCoreFrameWork].name].Client = OXCoreClient
DebugPrint("OX Core Client Functions Initialized.") 