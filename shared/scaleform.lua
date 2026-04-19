--==============================================================================
--  tm-bridge :: shared/scaleform.lua
--  TM.Scaleform.* -- handful of common Scaleform helpers (BigMessage, Countdown,
--  InstructionalButtons, TimerBar, Debug overlay).
--==============================================================================

TM.Scaleform = {}

if TM.Server then return end

local function loadMovie(name)
    local handle = RequestScaleformMovie(name)
    while not HasScaleformMovieLoaded(handle) do Wait(0) end
    return handle
end

--==============================================================================
-- BIG MESSAGE
--   TM.Scaleform.BigMessage.Show(title, message, opts)
--     opts = { duration=4000, style='shard'|'mp_shard'|'wasted'|'mp_message', colour=140 }
--==============================================================================
TM.Scaleform.BigMessage = {}

function TM.Scaleform.BigMessage.Show(title, message, opts)
    opts = opts or {}
    local h = loadMovie('MP_BIG_MESSAGE_FREEMODE')
    local style = opts.style or 'shard'
    BeginScaleformMovieMethod(h,
        style == 'wasted' and 'SHOW_SHARD_WASTED_MP_MESSAGE'
        or style == 'mp_message' and 'SHOW_CENTERED_MP_MESSAGE_LARGE'
        or style == 'shard' and 'SHOW_SHARD_CENTERED_MP_MESSAGE'
        or 'SHOW_SHARD_CENTERED_MP_MESSAGE')
    BeginTextCommandScaleformString('STRING'); AddTextComponentSubstringPlayerName(title or ''); EndTextCommandScaleformString()
    BeginTextCommandScaleformString('STRING'); AddTextComponentSubstringPlayerName(message or ''); EndTextCommandScaleformString()
    if opts.colour then ScaleformMovieMethodAddParamInt(opts.colour) end
    EndScaleformMovieMethod()

    CreateThread(function()
        local deadline = GetGameTimer() + (opts.duration or 4000)
        while GetGameTimer() < deadline do
            DrawScaleformMovieFullscreen(h, 255, 255, 255, 255, 0)
            Wait(0)
        end
        SetScaleformMovieAsNoLongerNeeded(h)
    end)
end

--==============================================================================
-- COUNTDOWN  (3...2...1...GO)
--==============================================================================
TM.Scaleform.Countdown = {}

function TM.Scaleform.Countdown.Run(opts)
    opts = opts or {}
    local from   = opts.from or 3
    local label  = opts.label or 'GO!'
    local h = loadMovie('COUNTDOWN')

    for i = from, 1, -1 do
        BeginScaleformMovieMethod(h, 'SET_MESSAGE')
        ScaleformMovieMethodAddParamPlayerNameString(tostring(i))
        ScaleformMovieMethodAddParamInt(255); ScaleformMovieMethodAddParamInt(255); ScaleformMovieMethodAddParamInt(255)
        ScaleformMovieMethodAddParamBool(true)
        EndScaleformMovieMethod()
        if opts.beep ~= false then
            PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true)
        end
        local deadline = GetGameTimer() + 1000
        while GetGameTimer() < deadline do
            DrawScaleformMovieFullscreen(h, 255, 255, 255, 255, 0)
            Wait(0)
        end
    end

    BeginScaleformMovieMethod(h, 'SET_MESSAGE')
    ScaleformMovieMethodAddParamPlayerNameString(label)
    ScaleformMovieMethodAddParamInt(255); ScaleformMovieMethodAddParamInt(255); ScaleformMovieMethodAddParamInt(255)
    ScaleformMovieMethodAddParamBool(true)
    EndScaleformMovieMethod()
    if opts.beep ~= false then
        PlaySoundFrontend(-1, 'CHECKPOINT_PERFECT', 'HUD_MINI_GAME_SOUNDSET', true)
    end
    local deadline = GetGameTimer() + 800
    while GetGameTimer() < deadline do
        DrawScaleformMovieFullscreen(h, 255, 255, 255, 255, 0); Wait(0)
    end
    SetScaleformMovieAsNoLongerNeeded(h)
    if opts.onFinish then opts.onFinish() end
end

--==============================================================================
-- INSTRUCTIONAL BUTTONS  (top-right keyboard prompt strip)
--   TM.Scaleform.Instructional.Set({ { control = 38, label = 'Interact' }, ... })
--   TM.Scaleform.Instructional.Hide()
--==============================================================================
TM.Scaleform.Instructional = {}

local instr = { handle = nil, items = nil, drawing = false }

local function buildInstr()
    if instr.handle then SetScaleformMovieAsNoLongerNeeded(instr.handle) end
    instr.handle = loadMovie('INSTRUCTIONAL_BUTTONS')
    PushScaleformMovieFunction(instr.handle, 'CLEAR_ALL'); PopScaleformMovieFunctionVoid()
    PushScaleformMovieFunction(instr.handle, 'SET_CLEAR_SPACE'); PushScaleformMovieFunctionParameterInt(200); PopScaleformMovieFunctionVoid()
    for i, btn in ipairs(instr.items or {}) do
        PushScaleformMovieFunction(instr.handle, 'SET_DATA_SLOT')
        PushScaleformMovieFunctionParameterInt(i - 1)
        ScaleformMovieMethodAddParamPlayerNameString(GetControlInstructionalButton(0, btn.control or 38, true))
        PushScaleformMovieFunctionParameterString(btn.label or '')
        PopScaleformMovieFunctionVoid()
    end
    PushScaleformMovieFunction(instr.handle, 'DRAW_INSTRUCTIONAL_BUTTONS'); PopScaleformMovieFunctionVoid()
end

function TM.Scaleform.Instructional.Set(buttons)
    instr.items = buttons or {}
    buildInstr()
    if not instr.drawing then
        instr.drawing = true
        CreateThread(function()
            while instr.drawing do
                if instr.handle then DrawScaleformMovieFullscreen(instr.handle, 255, 255, 255, 255, 0) end
                Wait(0)
            end
            if instr.handle then SetScaleformMovieAsNoLongerNeeded(instr.handle); instr.handle = nil end
        end)
    end
end

function TM.Scaleform.Instructional.Hide()
    instr.drawing = false; instr.items = nil
end

--==============================================================================
-- TIMER BAR HUD  (lightweight DrawRect-based bar; works on RDR3 too)
--==============================================================================
TM.Scaleform.TimerBar = {}

function TM.Scaleform.TimerBar.Show(spec)
    spec = spec or {}
    local handle = { alive = true, label = spec.label or '', value = spec.value or '0' }
    CreateThread(function()
        while handle.alive do
            local x, y = (spec.x or 0.86), (spec.y or 0.86)
            DrawRect(x, y, 0.16, 0.034, 0, 0, 0, 180)
            TM.Text.Draw2D(x, y - 0.012, handle.label, 0.32, true)
            TM.Text.Draw2D(x, y + 0.005, handle.value, 0.45, true)
            Wait(0)
        end
    end)
    function handle:set(value, label)
        handle.value = tostring(value)
        if label then handle.label = label end
    end
    function handle:hide() handle.alive = false end
    return handle
end

--==============================================================================
-- DEBUG OVERLAY (text in the corner when Config.DebugMode is true)
--==============================================================================
TM.Scaleform.Debug = {}

local debugLines = {}
function TM.Scaleform.Debug.Set(key, text)
    debugLines[key] = text
end
function TM.Scaleform.Debug.Clear(key)
    debugLines[key] = nil
end

CreateThread(function()
    while true do
        if Config and Config.DebugMode and next(debugLines) then
            local i = 0
            for _, line in pairs(debugLines) do
                TM.Text.Draw2D(0.005, 0.01 + (i * 0.018), '~y~' .. tostring(line), 0.3, false)
                i = i + 1
            end
        end
        Wait(0)
    end
end)
