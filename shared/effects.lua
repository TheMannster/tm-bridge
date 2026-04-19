--==============================================================================
--  tm-bridge :: shared/effects.lua
--  TM.Effects -- screen-effect / one-shot buff helpers.  Names mirror common
--  GTA "set timecycle" presets; durations are in milliseconds.
--==============================================================================

TM.Effects = {}

if TM.Server then return end

local function start(name, duration, looped)
    AnimpostfxStop(name)
    AnimpostfxPlay(name, duration or 0, looped or false)
    if duration and duration > 0 and not looped then
        SetTimeout(duration, function() AnimpostfxStop(name) end)
    end
end

function TM.Effects.Alien(duration)    start('DrugsMichaelAliensFightIn', duration or 5000) end
function TM.Effects.Weed(duration)     start('DrugsTrevorClownsFight',     duration or 7000) end
function TM.Effects.Trevor(duration)   start('DrugsTrevorClownsFightIn',   duration or 7000) end
function TM.Effects.Turbo(duration)    start('RaceTurbo',                  duration or 1500) end
function TM.Effects.Rampage(duration)  start('Rampage',                    duration or 5000) end
function TM.Effects.Focus(duration)    start('FocusIn',                    duration or 5000) end
function TM.Effects.Death(duration)    start('DeathFailOut',               duration or 4000) end
function TM.Effects.Fade(duration)     DoScreenFadeOut(duration or 800); SetTimeout(duration or 800, function() DoScreenFadeIn(duration or 800) end) end

function TM.Effects.NightVision(on)    SetNightvision(on == true) end
function TM.Effects.Thermal(on)        SetSeethrough(on == true) end

--------------------------------------------------------------------------------
-- Buff effects
--------------------------------------------------------------------------------
function TM.Effects.Heal(amount)
    local ped = PlayerPedId()
    SetEntityHealth(ped, math.min(GetEntityMaxHealth(ped), GetEntityHealth(ped) + (amount or 25)))
end

function TM.Effects.Stamina()
    if TM.IsRedM then
        Citizen.InvokeNative(0xC6258F41D86676E0, PlayerId(), 0, 100.0)
    else
        ResetPlayerStamina(PlayerId())
        RestorePlayerStamina(PlayerId(), 1.0)
    end
end

--------------------------------------------------------------------------------
-- StopAll
--------------------------------------------------------------------------------
function TM.Effects.StopAll()
    AnimpostfxStopAll()
    SetNightvision(false)
    SetSeethrough(false)
end
