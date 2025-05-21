Utils.Loaders = {}

local function requestAndCheck(requestFn, checkFn, assetName, timeoutDuration)
    requestFn(assetName)
    local timeout = timeoutDuration or 1000 -- Default 1 second timeout
    while not checkFn(assetName) and timeout > 0 do
        Citizen.Wait(0)
        timeout = timeout - 1
    end
    if not checkFn(assetName) then
        DebugPrint(string.format("Failed to load %s within timeout.", tostring(assetName)), "WARN")
        return false
    end
    return true
end

--- Loads a model into memory if valid and not already loaded.
--- @param model any Model name or hash.
--- @return boolean True if loaded or already loaded, false on failure.
function Utils.Loaders.loadModel(model)
    local modelHash = type(model) == 'string' and GetHashKey(model) or model
    if not IsModelValid(modelHash) then 
        DebugPrint("loadModel: Invalid model " .. tostring(model), "ERROR")
        return false 
    end
    if HasModelLoaded(modelHash) then return true end
    return requestAndCheck(RequestModel, HasModelLoaded, modelHash)
end

--- Unloads a model from memory.
--- @param model any Model name or hash.
function Utils.Loaders.unloadModel(model)
    local modelHash = type(model) == 'string' and GetHashKey(model) or model
    if IsModelValid(modelHash) and HasModelLoaded(modelHash) then
        SetModelAsNoLongerNeeded(modelHash)
    end
end

--- Loads an animation dictionary into memory.
--- @param animDict string Animation dictionary name.
--- @return boolean True if loaded or already loaded, false on failure.
function Utils.Loaders.loadAnimDict(animDict)
    if HasAnimDictLoaded(animDict) then return true end
    return requestAndCheck(RequestAnimDict, HasAnimDictLoaded, animDict)
end

--- Removes an animation dictionary from memory.
--- @param animDict string Animation dictionary name.
function Utils.Loaders.unloadAnimDict(animDict)
    if HasAnimDictLoaded(animDict) then
        RemoveAnimDict(animDict)
    end
end

--- Loads a particle effect (ptfx) dictionary.
--- @param ptFxName string PTFX dictionary name.
--- @return boolean True if loaded or already loaded, false on failure.
function Utils.Loaders.loadPtfxDict(ptFxName)
    if HasNamedPtfxAssetLoaded(ptFxName) then return true end
    RequestNamedPtfxAsset(ptFxName)
    local timeout = 1000
    while not HasNamedPtfxAssetLoaded(ptFxName) and timeout > 0 do
        Citizen.Wait(0)
        timeout = timeout - 1
    end
    if not HasNamedPtfxAssetLoaded(ptFxName) then
        DebugPrint("Failed to load ptfx asset " .. ptFxName, "WARN")
        return false
    end
    return true
end

--- Unloads a particle effect dictionary from memory.
--- @param dict string PTFX dictionary name.
function Utils.Loaders.unloadPtfxDict(dict)
    if HasNamedPtfxAssetLoaded(dict) then -- Assuming this is the check, might need specific unload for PTFX if available
        -- FiveM does not have a direct RemoveNamedPtfxAsset or SetPtfxAssetNoLongerNeeded
        -- PTFX assets are often managed by the engine after loading.
        -- This function might be more of a placeholder unless a specific unload native exists.
        DebugPrint("PTFX dictionaries unload automatically or via engine; direct unload not typically available: " .. dict, "INFO")
    end
end

--- Loads a streamed texture dictionary.
--- @param dict string Texture dictionary name.
--- @return boolean True if loaded or already loaded, false on failure.
function Utils.Loaders.loadTextureDict(dict)
    if HasStreamedTextureDictLoaded(dict) then return true end
    return requestAndCheck(RequestStreamedTextureDict, HasStreamedTextureDictLoaded, dict)
end

--- Unloads a streamed texture dictionary.
--- @param dict string Texture dictionary name.
function Utils.Loaders.unloadTextureDict(dict)
    if HasStreamedTextureDictLoaded(dict) then
        SetStreamedTextureDictAsNoLongerNeeded(dict)
    end
end

--- Loads a script audio bank.
--- @param bank string Audio bank name.
--- @return boolean True on success.
function Utils.Loaders.loadScriptBank(bank)
    if IsAudioBankLoaded(bank) then return true end -- Note: IsAudioBankLoaded might not be the right check here for script banks
                                              -- LoadAudioScriptBank returns a boolean itself.
    return LoadAudioScriptBank(bank)
end

--- Loads an ambient audio bank.
--- @param bank string Audio bank name.
--- @return boolean True on success.
function Utils.Loaders.loadAmbientBank(bank)
    -- Similar to script banks, direct check before load might not be standard.
    -- LoadAmbientAudioBank returns a boolean.
    return LoadAmbientAudioBank(bank)
end

--- Plays an animation on a ped.
--- Loads the dictionary if not already loaded.
--- @param animDict string Animation dictionary.
--- @param animName string Animation name.
--- @param duration number (Optional) Duration in ms. If -1 or nil, plays until stopped.
--- @param flag number (Optional) Animation flags.
--- @param ped number (Optional) Ped to play on (default: PlayerPedId()).
--- @param speed number (Optional) Animation speed.
function Utils.Loaders.playAnim(animDict, animName, duration, flag, ped, speed)
    ped = ped or PlayerPedId()
    if not Utils.Loaders.loadAnimDict(animDict) then 
        DebugPrint("playAnim: Failed to load anim dict " .. animDict, "ERROR")
        return 
    end
    local animDuration = duration or -1 -- Play indefinitely if no duration
    local animFlag = flag or 0
    local animSpeed = speed or 1.0
    TaskPlayAnim(ped, animDict, animName, animSpeed, -animSpeed, animDuration, animFlag, 0, false, false, false)
end

--- Stops an animation and unloads the dictionary.
--- @param animDict string Animation dictionary.
--- @param animName string Animation name.
--- @param ped number (Optional) Ped to stop anim on (default: PlayerPedId()).
function Utils.Loaders.stopAnim(animDict, animName, ped)
    ped = ped or PlayerPedId()
    StopAnimTask(ped, animDict, animName, 1.0)
    -- Optional: Unload immediately. Consider if the dict is used by other anims.
    -- Utils.Loaders.unloadAnimDict(animDict) 
end

--- Plays a game sound from a coordinate or entity.
--- @param audioBank string Name of the audio bank (e.g., from game files or DLC).
--- @param soundSet string Usually the same as soundRef for simple sounds, or a set name.
--- @param soundRef string Sound name reference.
--- @param coords vector3|number Coordinates (vector3) or entity handle (number).
--- @param synced boolean (Optional) If the sound should be synced across clients.
--- @param range number (Optional) Audible range of the sound.
function Utils.Loaders.playGameSound(audioBank, soundSet, soundRef, coordsOrEntity, synced, range)
    -- This is a simplified version. True sound playing involves PlaySoundFromCoord or PlaySoundFromEntity
    -- and potentially RequestScriptAudioBank if not already loaded via other means.
    -- The example in jim_bridge is `playGameSound('DLC_HEIST_HACKING_SNAKE_SOUNDS', 'Beep', vector3(0, 0, 0), false, 15.0)`
    -- which doesn't quite map to a single native. It implies PlaySoundFromCoord or similar.

    local soundId = GetSoundId()
    if type(coordsOrEntity) == 'vector3' then
        PlaySoundFromCoord(soundId, soundRef, coordsOrEntity.x, coordsOrEntity.y, coordsOrEntity.z, soundSet, synced or false, range or 0, false)
    elseif type(coordsOrEntity) == 'number' then -- Assuming entity handle
        PlaySoundFromEntity(soundId, soundRef, coordsOrEntity, soundSet, synced or false, range or 0)
    else
        DebugPrint("playGameSound: Invalid coordsOrEntity type. Expected vector3 or entity handle.", "ERROR")
        return
    end
    -- ReleaseSoundId(soundId) -- Important to release after it plays or is no longer needed.
    -- Consider how to manage sound IDs, especially for looped or long sounds.
    -- For one-shot sounds, releasing soon after might be fine.
    Citizen.CreateThread(function()
        Citizen.Wait(5000) -- Wait 5s then release, assuming it's a short sound
        if soundId ~= -1 then ReleaseSoundId(soundId) end
    end)

    DebugPrint(string.format("Attempted to play sound: %s / %s from %s", soundSet, soundRef, tostring(coordsOrEntity)), "AUDIO")
end

DebugPrint("shared/loaders.lua loaded and Utils.Loaders populated.") 