--==============================================================================
--  tm-bridge :: shared/anim.lua
--  TM.Anim  -- play / stop scenarios and animation tasks
--  TM.Sound -- one-shot frontend / 3D sound helpers
--==============================================================================

TM.Anim  = {}
TM.Sound = {}

if TM.Server then return end

--------------------------------------------------------------------------------
-- Play
--    opts = { dict, name, ped (optional), flag (default 49), duration (-1),
--             playbackRate (1.0), scenario (overrides anim) }
--------------------------------------------------------------------------------
function TM.Anim.Play(opts)
    opts = opts or {}
    local ped = opts.ped or PlayerPedId()

    if opts.scenario then
        TaskStartScenarioInPlace(ped, opts.scenario, 0, true)
        return true
    end

    if not opts.dict or not opts.name then return false end
    if not TM.Asset.AnimDict(opts.dict) then return false end

    TaskPlayAnim(ped, opts.dict, opts.name,
        opts.blendIn or 8.0, opts.blendOut or -8.0,
        opts.duration or -1, opts.flag or 49,
        opts.playbackRate or 0, false, false, false)

    return true
end

--------------------------------------------------------------------------------
-- Stop
--------------------------------------------------------------------------------
function TM.Anim.Stop(ped)
    ClearPedTasks(ped or PlayerPedId())
end

function TM.Anim.StopScenario(ped)
    ClearPedTasksImmediately(ped or PlayerPedId())
end

--------------------------------------------------------------------------------
-- One-shot scenario w/ duration (returns when finished)
--------------------------------------------------------------------------------
function TM.Anim.PlayFor(opts, durationMs)
    if not TM.Anim.Play(opts) then return false end
    Wait(durationMs or 1000)
    TM.Anim.Stop(opts.ped)
    return true
end

--------------------------------------------------------------------------------
-- TM.Sound
--------------------------------------------------------------------------------
function TM.Sound.PlayFrontend(name, set)
    PlaySoundFrontend(-1, name, set or 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
end

function TM.Sound.PlayAt(coords, name, set)
    PlaySoundFromCoord(-1, name, coords.x, coords.y, coords.z, set or '', false, 0, false)
end

function TM.Sound.PlayOnEntity(entity, name, set)
    PlaySoundFromEntity(-1, name, entity, set or '', false, 0)
end
