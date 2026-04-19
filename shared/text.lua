--==============================================================================
--  tm-bridge :: shared/text.lua
--  TM.Text -- multi-system on-screen text helpers (drawText, hint, 3D world
--  text, custom 2D text).  Client side only.
--==============================================================================

TM.Text = {}

if TM.Server then return end

local active = false

--------------------------------------------------------------------------------
-- DrawText (corner-of-screen hint text)
--------------------------------------------------------------------------------
function TM.Text.Show(text, position)
    if not text or text == '' then return end
    position = position or 'right'
    local sys = TM.Systems.DrawText

    if sys == 'ox' and TM.HasResource(TM.Exports.oxLib) then
        exports[TM.Exports.oxLib]:showTextUI(text, { position = position .. '-center' })
        active = true
        return
    end

    if sys == 'qb' then
        if TM.HasResource('qb-core') and exports['qb-core'] and exports['qb-core'].DrawText then
            exports['qb-core']:DrawText(text, position)
            active = true
            return
        end
    end

    if sys == 'esx' then
        local obj = TM.Framework.Object()
        if obj and obj.TextUI then obj.TextUI(text); active = true; return end
    end

    -- Native help notification fallback
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, false, -1)
end

function TM.Text.Hide()
    if not active then
        if TM.HasResource(TM.Exports.oxLib) then
            pcall(function() exports[TM.Exports.oxLib]:hideTextUI() end)
        end
        return
    end
    active = false

    if TM.Systems.DrawText == 'ox' and TM.HasResource(TM.Exports.oxLib) then
        exports[TM.Exports.oxLib]:hideTextUI()
        return
    end
    if TM.Systems.DrawText == 'qb' and TM.HasResource('qb-core') and exports['qb-core'].HideText then
        exports['qb-core']:HideText()
        return
    end
    local obj = TM.Framework.Object()
    if TM.Systems.DrawText == 'esx' and obj and obj.HideUI then obj.HideUI() end
end

--------------------------------------------------------------------------------
-- Help text (single-tick prompt at the top-centre)
--------------------------------------------------------------------------------
function TM.Text.Help(message, beep)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(message or '')
    EndTextCommandDisplayHelp(0, false, beep ~= false, -1)
end

--------------------------------------------------------------------------------
-- 3D world text (call every tick from your loop)
--------------------------------------------------------------------------------
function TM.Text.Draw3D(coords, text, scale)
    scale = scale or 0.35
    local cam = GetGameplayCamCoord()
    local dist = #(cam - vector3(coords.x, coords.y, coords.z))
    local fov = (1.0 / GetGameplayCamFov()) * 100.0
    local size = scale * fov / dist

    SetTextScale(0.0 * size, 0.55 * size)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text or '')
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    DrawText(0.0, 0.0)

    -- subtle background panel
    local factor = (string.len(text or '')) / 370
    DrawRect(0.0, 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

--------------------------------------------------------------------------------
-- 2D text (call every tick from your loop)
--------------------------------------------------------------------------------
function TM.Text.Draw2D(x, y, text, scale, centred)
    SetTextScale(scale or 0.35, scale or 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry('STRING')
    if centred then SetTextCentre(true) end
    AddTextComponentString(text or '')
    DrawText(x, y)
end
