--==============================================================================
--  tm-bridge :: shared/progress.lua
--  Unified progress bar / circle.  Returns true on completion, false if the
--  player cancelled.  Auto-detects ox_lib > qb > esx > native.
--==============================================================================

TM.Progress = {}

if TM.Server then return end

local runNative  -- forward decl

--------------------------------------------------------------------------------
-- ox_lib progress
--------------------------------------------------------------------------------
local function runOx(opts)
    local fn = opts.style == 'circle' and 'progressCircle' or 'progressBar'
    local res = exports[TM.Exports.oxLib][fn](exports[TM.Exports.oxLib], {
        duration = opts.duration or 5000,
        label    = opts.label,
        position = opts.position or 'bottom',
        useWhileDead = false,
        canCancel = opts.canCancel ~= false,
        disable   = opts.disable or { car = true, move = true, combat = true },
        anim      = opts.anim,
        prop      = opts.prop,
    })
    return res ~= false and res ~= nil
end

--------------------------------------------------------------------------------
-- QBCore / QBox progress
--------------------------------------------------------------------------------
local function runQb(opts)
    local p = promise.new()
    local QB = TM.Framework.Object()
    if not (QB and QB.Functions and QB.Functions.Progressbar) then
        return runNative(opts)
    end
    QB.Functions.Progressbar('tm_progress_' .. (opts.name or 'task'), opts.label or '',
        opts.duration or 5000, false, opts.canCancel ~= false,
        { disableMovement = true, disableCarMovement = true, disableMouse = false, disableCombat = true },
        opts.animDict and { animDict = opts.animDict, anim = opts.anim, flags = opts.flags or 49 } or {},
        opts.prop or {}, {},
        function() p:resolve(true) end,
        function() p:resolve(false) end)
    return Citizen.Await(p)
end

--------------------------------------------------------------------------------
-- ESX progress
--------------------------------------------------------------------------------
local function runEsx(opts)
    if not TM.HasResource('esx_progressbar') then return runNative(opts) end
    local p = promise.new()
    exports['esx_progressbar']:Progressbar(opts.name or 'tm_progress', opts.label or '', opts.duration or 5000, {
        FreezePlayer = false,
        animation = opts.anim and { type = 'anim', dict = opts.animDict, lib = opts.anim } or nil,
        onFinish  = function() p:resolve(true) end,
        onCancel  = function() p:resolve(false) end,
    })
    return Citizen.Await(p)
end

--------------------------------------------------------------------------------
-- Native fallback (animated rectangle)
--------------------------------------------------------------------------------
runNative = function(opts)
    local duration = opts.duration or 5000
    local label    = opts.label or 'Working...'
    local startT   = GetGameTimer()
    local endT     = startT + duration
    local cancelled = false
    while GetGameTimer() < endT do
        Wait(0)
        local pct = (GetGameTimer() - startT) / duration
        if pct > 1.0 then pct = 1.0 end
        DrawRect(0.5, 0.92, 0.22, 0.03, 0, 0, 0, 180)
        DrawRect(0.5 - (0.22 * (1 - pct)) / 2, 0.92, 0.22 * pct, 0.03, 0, 200, 80, 220)
        TM.Text.Draw2D(0.5, 0.905, label, 0.4, true)
        if opts.canCancel ~= false and IsControlJustReleased(0, 73) then
            cancelled = true; break
        end
    end
    return not cancelled
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------
function TM.Progress.Bar(opts)
    opts = opts or {}
    if opts.anim and opts.anim.dict then
        TM.Anim.Play({ dict = opts.anim.dict, name = opts.anim.name, flag = opts.anim.flag or 49 })
    end
    local sys = TM.Systems.Progress
    local ok
    if sys == 'ox' and TM.HasResource(TM.Exports.oxLib) then ok = runOx(opts)
    elseif sys == 'qb' then ok = runQb(opts)
    elseif sys == 'esx' then ok = runEsx(opts)
    else ok = runNative(opts) end

    if opts.anim and opts.anim.dict then
        ClearPedTasks(PlayerPedId())
    end
    return ok
end

function TM.Progress.Stop()
    if TM.HasResource(TM.Exports.oxLib) then
        pcall(function() exports[TM.Exports.oxLib]:cancelProgress() end)
    end
    ClearPedTasks(PlayerPedId())
end
