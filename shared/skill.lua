--==============================================================================
--  tm-bridge :: shared/skill.lua
--  TM.Skill.Run(spec) -> boolean
--  spec can be either a list of strings ("easy", "medium", "hard") for ox_lib,
--  or a difficulty number (1-100) for qb-skillbar, or { difficulty, length }
--  for native fallback.
--==============================================================================

TM.Skill = {}

if TM.Server then return end

local function runOx(spec)
    local diffs
    if type(spec) == 'string' then diffs = { spec }
    elseif type(spec) == 'table' and spec.difficulties then diffs = spec.difficulties
    elseif type(spec) == 'table' and #spec > 0 then diffs = spec
    else diffs = { 'easy' } end
    return exports[TM.Exports.oxLib]:skillCheck(diffs, spec.keys)
end

local function runQb(spec)
    local difficulty = (type(spec) == 'number' and spec) or (spec and spec.difficulty) or 50
    local QB = TM.Framework.Object()
    if not (QB and QB.Functions and QB.Functions.GetPlayerData) then return false end
    local p = promise.new()
    -- qb-skillbar style call (resource name varies)
    local skillRes = TM.PickResource('qb-skillbar', 'qbx_skillbar')
    if not skillRes then return false end
    exports[skillRes]:Start({ duration = 2500, accuracy = difficulty }, function(success)
        p:resolve(success)
    end)
    return Citizen.Await(p)
end

--------------------------------------------------------------------------------
-- Native button-mash fallback
--------------------------------------------------------------------------------
local function runNative(spec)
    local needed   = (spec and spec.presses) or 8
    local timeout  = (spec and spec.timeout) or 5000
    local key      = (spec and spec.key)     or 38   -- E
    local pressed  = 0
    local deadline = GetGameTimer() + timeout
    while GetGameTimer() < deadline do
        Wait(0)
        DrawRect(0.5, 0.85, 0.20, 0.04, 0, 0, 0, 180)
        TM.Text.Draw2D(0.5, 0.84, ('Mash [E]  %d/%d'):format(pressed, needed), 0.4, true)
        if IsControlJustPressed(0, key) then
            pressed = pressed + 1
            if pressed >= needed then return true end
        end
    end
    return false
end

function TM.Skill.Run(spec)
    if TM.Systems.Skill == 'ox' and TM.HasResource(TM.Exports.oxLib) then return runOx(spec) end
    if TM.Systems.Skill == 'qb' then return runQb(spec) end
    return runNative(spec)
end
