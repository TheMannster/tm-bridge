--==============================================================================
--  tm-bridge :: shared/asset.lua
--  TM.Asset -- thin promise-style loaders for game assets so callers don't have
--  to write Wait(0) loops.  All return true on success / false on timeout.
--==============================================================================

TM.Asset = {}

if TM.Server then return end

local function loadLoop(check, request, label, timeout)
    timeout = timeout or 5000
    if check() then return true end
    request()
    local deadline = GetGameTimer() + timeout
    while not check() do
        if GetGameTimer() > deadline then
            TM.Log.warn(('asset load timed out: %s'):format(label or 'unknown'))
            return false
        end
        Wait(10)
    end
    return true
end

function TM.Asset.Model(model)
    if type(model) == 'string' then model = joaat(model) end
    if not IsModelInCdimage(model) then
        TM.Log.warn(('invalid model hash: %s'):format(tostring(model)))
        return false
    end
    return loadLoop(function() return HasModelLoaded(model) end,
                    function() RequestModel(model) end, ('model %s'):format(model))
end

function TM.Asset.AnimDict(dict)
    if not dict or dict == '' then return false end
    if not DoesAnimDictExist(dict) then
        TM.Log.warn(('invalid anim dict: %s'):format(dict))
        return false
    end
    return loadLoop(function() return HasAnimDictLoaded(dict) end,
                    function() RequestAnimDict(dict) end, ('anim dict %s'):format(dict))
end

function TM.Asset.AnimSet(set)
    return loadLoop(function() return HasAnimSetLoaded(set) end,
                    function() RequestAnimSet(set) end, ('anim set %s'):format(set))
end

function TM.Asset.Texture(dict)
    return loadLoop(function() return HasStreamedTextureDictLoaded(dict) end,
                    function() RequestStreamedTextureDict(dict, true) end, ('texture %s'):format(dict))
end

function TM.Asset.Ptfx(dict)
    return loadLoop(function() return HasNamedPtfxAssetLoaded(dict) end,
                    function() RequestNamedPtfxAsset(dict) end, ('ptfx %s'):format(dict))
end

function TM.Asset.AudioBank(bank)
    return loadLoop(function() return RequestScriptAudioBank(bank, false) end,
                    function() RequestScriptAudioBank(bank, false) end, ('audio bank %s'):format(bank))
end

function TM.Asset.AmbientAudioBank(bank)
    return loadLoop(function() return RequestAmbientAudioBank(bank, false) end,
                    function() RequestAmbientAudioBank(bank, false) end, ('ambient bank %s'):format(bank))
end

--------------------------------------------------------------------------------
-- Release helpers (best-effort)
--------------------------------------------------------------------------------
function TM.Asset.UnloadModel(model)
    if type(model) == 'string' then model = joaat(model) end
    SetModelAsNoLongerNeeded(model)
end

function TM.Asset.UnloadAnimDict(dict)  RemoveAnimDict(dict) end
function TM.Asset.UnloadTexture(dict)   SetStreamedTextureDictAsNoLongerNeeded(dict) end
function TM.Asset.UnloadPtfx(dict)      RemoveNamedPtfxAsset(dict) end
