--[[
    Player Metadata Utilities Module
    ----------------------------------
    This module provides functions for retrieving and setting metadata for players
    across different frameworks (QB, ESX, OXCore). It also registers server callbacks
    for getting and setting metadata.
]]

-------------------------------------------------------------
-- Player Retrieval
-------------------------------------------------------------

--- Retrieves the player object using the active core export.
---
--- @param source number The server ID of the player.
--- @return table|nil table The player object, or nil if no supported core is detected.
---
--- @usage
--- ```lua
--- local player = GetPlayer(playerId)
--- ```
function GetPlayer(source)
    if Utils.Helpers.isStarted(QBExport) then
        debugPrint("^6Bridge^7: ^3GetPlayer^7() QBExport")
        return exports[QBExport]:GetCoreObject().Functions.GetPlayer(source)

    elseif Utils.Helpers.isStarted(QBXExport) then
        debugPrint("^6Bridge^7: ^3GetPlayer^7() QBOXExport")
        return exports[QBXExport]:GetCoreObject().Functions.GetPlayer(source)

    elseif Utils.Helpers.isStarted(ESXExport) then
        debugPrint("^6Bridge^7: ^3GetPlayer^7() ESXExport")
        return ESX.GetPlayerFromId(source)

    elseif Utils.Helpers.isStarted(OXCoreExport) then
        debugPrint("^6Bridge^7: ^3GetPlayer^7() OXCoreExport")
        return exports[OXCoreExport]:GetPlayer(source)

    elseif Utils.Helpers.isStarted(RSGExport) then
        debugPrint("^6Bridge^7: ^3GetPlayer^7() RSGExport")
        return exports[RSGExport]:GetCoreObject().Functions.GetPlayer(source)

    end
    return nil
end

-------------------------------------------------------------
-- Metadata Retrieval
-------------------------------------------------------------

--- Retrieves metadata from a player object.
---
--- If called client-side (player is nil), it triggers a server callback to retrieve metadata.
---
--- @param player table|nil The player object; if nil, metadata is retrieved via a server callback.
--- @param key string The metadata key to retrieve.
--- @return any The value of the requested metadata, or nil if not found.
---
--- @usage
--- ```lua
--- local myMeta = GetMetadata(player, "myKey")
--- ```
function GetMetadata(player, key)
    if not player then
        debugPrint("^6Bridge^7: ^3GetMetadata^7() calling server: "..key)
        return triggerCallback(Utils.Helpers.getScript()..":server:GetMetadata", key)
    else
        if Utils.Helpers.isStarted(QBExport) or Utils.Helpers.isStarted(QBXExport) then
            debugPrint("^6Bridge^7: ^3GetMetadata^7() QBExport/QBXExport", key)
            return player.PlayerData.metadata[key]

        elseif Utils.Helpers.isStarted(ESXExport) then
            debugPrint("^6Bridge^7: ^3GetMetadata^7() ESXExport", key)
            return player.getMeta(key)

        elseif Utils.Helpers.isStarted(OXCoreExport) then
            debugPrint("^6Bridge^7: ^3GetMetadata^7() OXCoreExport", key)
            return player.get(key)

        elseif Utils.Helpers.isStarted(RSGExport) then
            debugPrint("^6Bridge^7: ^3GetMetadata^7() RSGExport", key)
            return player.PlayerData.metadata[key]

        end
    end
    return nil
end

-- Register a server callback for retrieving metadata.
createCallback(Utils.Helpers.getScript()..":server:GetMetadata", function(source, key)
    debugPrint("^6Bridge^7: ^3GetMetadata Callback^7 from source: "..tostring(source)..", key: "..tostring(key))
    local player = GetPlayer(source)
    if not player then
        print("Error getting metadata: player not found for source "..tostring(source))
        return
    end

    if type(key) == "table" then
        local Metadata = {}
        for _, k in ipairs(key) do
            Metadata[k] = GetMetadata(player, k)
        end
        return Metadata
    elseif type(key) == "string" then
        return GetMetadata(player, key)
    end
end)

-------------------------------------------------------------
-- Metadata Setting
-------------------------------------------------------------

--- Sets metadata on a player object.
---
--- The function updates the player's metadata using the active core export.
---
--- @param player table The player object.
--- @param key string The metadata key to set.
--- @param value any The new value for the metadata key.
---
--- @usage
--- ```lua
--- SetMetadata(player, "myKey", "newValue")
--- ```
function SetMetadata(player, key, value)
    debugPrint("^6Bridge^7: ^3SetMetadata^7() setting metadata for key: "..key)
    if Utils.Helpers.isStarted(QBExport) or Utils.Helpers.isStarted(QBXExport) then
        debugPrint("^6Bridge^7: ^3SetMetadata^7() using QBExport/QBXExport")
        player.Functions.SetMetaData(key, value)

    elseif Utils.Helpers.isStarted(ESXExport) then
        debugPrint("^6Bridge^7: ^3SetMetadata^7() using ESXExport")
        player.setMeta(key, value)

    elseif Utils.Helpers.isStarted(OXCoreExport) then
        debugPrint("^6Bridge^7: ^3SetMetadata^7() using OXCoreExport")
        player.set(key, value)

    elseif Utils.Helpers.isStarted(RSGExport) then
        debugPrint("^6Bridge^7: ^3SetMetadata^7() using RSGExport")
        player.Functions.SetMetaData(key, value)

    end
end

-- Register a server callback for setting metadata.
createCallback(Utils.Helpers.getScript()..":server:SetMetadata", function(source, key, value)
    debugPrint("SetMetadata callback triggered for source:", source, "key:", key, "value:", value)
    local player = GetPlayer(source)
    --[[if not player then
        print("Error setting metadata: player not found for source "..tostring(source))
        return false
    end]]
    SetMetadata(player, key, value)
    print("Metadata set successfully.", key)
    return true
end)

-- Event to set entity metadata, typically from server to client.
RegisterNetEvent(Utils.Helpers.getScript() .. ":SetMetaData", function(netId, key, val)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        --[[if not player then
            print("Error setting metadata: player not found for source "..tostring(source))
            return false
        end]]
        SetMetadata(player, key, val)
        print("Metadata set successfully.", key)
        return true
    end
end)

function setMetaData(key, val, source)
    local src = source or GetPlayerServerId(PlayerId())
    local Player = getPlayer(src)
    if not Player then
        print(string.format("^1ERROR^7: Player not found for source %s in setMetaData", src))
        return
    end

    -- Ensure Player.metadata exists
    if not Player.PlayerData.metadata then
        Player.PlayerData.metadata = {}
    end

    -- Debug print before setting metadata
    if Utils.Helpers.isServer() and Config.System and Config.System.ServerDebugMode then
        print(string.format("--- SERVER setMetaData DEBUG --- Source: %s, Key: %s, Old Value: %s, New Value: %s", src, key, json.encode(Player.PlayerData.metadata[key]), json.encode(val)))
    end

    Player.PlayerData.metadata[key] = val

    -- Additional debug for specific frameworks
    if Utils.Helpers.isStarted(Exports.QBFrameWork) and QBCore and QBCore.Player then -- Check if QB is started via Utils.Helpers
        if QBCore.Player.SetMetaData then
             QBCore.Player.SetMetaData(key, val) -- For qb-core
        end
    elseif Utils.Helpers.isStarted(Exports.ESXFrameWork) and ESX then -- Check if ESX is started
        -- ESX might require triggering a client event or using a specific function if metadata is synced differently
        TriggerClientEvent('esx:setPlayerData', src, key, val) -- Example, adjust if ESX handles metadata differently
        if Config.System and Config.System.ServerDebugMode then
            print(string.format("--- SERVER setMetaData DEBUG (ESX) --- Triggered esx:setPlayerData for key: %s", key))
        end
    end
    if Utils.Helpers.isServer() and Config.System and Config.System.ServerDebugMode then
        print(string.format("--- SERVER setMetaData SUCCESS --- For Source: %s, Key: %s, New Value: %s", src, key, json.encode(Player.PlayerData.metadata[key])))
    end
end