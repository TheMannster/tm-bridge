--==============================================================================
--  tm-bridge :: shared/menu.lua
--  TM.Menu.Open(opts)  -- universal context menu
--      opts = { title, subtitle, items = { { title, desc, icon, onSelect, args } } }
--  Routes to ox_lib context menu, qb-menu, or a tiny native scrollwheel
--  fallback.
--==============================================================================

TM.Menu = {}

if TM.Server then return end

local activeId = 0
local stash = {}

--------------------------------------------------------------------------------
-- ox_lib backend
--------------------------------------------------------------------------------
local function openOx(opts)
    activeId = activeId + 1
    local id = 'tm_menu_' .. activeId
    local options = {}

    for _, item in ipairs(opts.items or {}) do
        options[#options + 1] = {
            title    = item.title,
            description = item.desc,
            icon     = item.icon,
            disabled = item.disabled,
            onSelect = function()
                if item.onSelect then item.onSelect(item.args) end
            end,
        }
    end

    exports[TM.Exports.oxLib]:registerContext({ id = id, title = opts.title or 'Menu', options = options })
    exports[TM.Exports.oxLib]:showContext(id)
end

--------------------------------------------------------------------------------
-- qb-menu backend
--------------------------------------------------------------------------------
local function openQb(opts)
    local items = {}
    items[#items + 1] = { isMenuHeader = true, header = opts.title or 'Menu', txt = opts.subtitle }
    for _, item in ipairs(opts.items or {}) do
        items[#items + 1] = {
            header = item.title,
            txt    = item.desc,
            icon   = item.icon,
            params = {
                isAction = true,
                event    = function(args) if item.onSelect then item.onSelect(args) end end,
                args     = item.args,
            },
        }
    end
    exports[TM.Exports.qbMenu]:openMenu(items)
end

--------------------------------------------------------------------------------
-- Native fallback (extremely simple list using TM.Text.Draw2D)
--------------------------------------------------------------------------------
local function openNative(opts)
    activeId = activeId + 1
    local id = activeId
    stash[id] = { opts = opts, index = 1, open = true }

    CreateThread(function()
        local s = stash[id]
        while s and s.open do
            Wait(0)
            local items = s.opts.items or {}
            DrawRect(0.85, 0.5, 0.25, math.min(0.05 * (#items + 1), 0.6), 0, 0, 0, 180)
            TM.Text.Draw2D(0.85, 0.4, '~y~' .. (s.opts.title or 'Menu'), 0.45, true)
            for i, item in ipairs(items) do
                local prefix = (i == s.index) and '~g~> ' or '~w~  '
                TM.Text.Draw2D(0.85, 0.42 + (i * 0.025), prefix .. item.title, 0.4, true)
            end
            DisableControlAction(0, 172, true)
            DisableControlAction(0, 173, true)
            DisableControlAction(0, 176, true)
            DisableControlAction(0, 177, true)
            if IsDisabledControlJustPressed(0, 172) then
                s.index = math.max(1, s.index - 1)
            elseif IsDisabledControlJustPressed(0, 173) then
                s.index = math.min(#items, s.index + 1)
            elseif IsDisabledControlJustPressed(0, 176) then
                local item = items[s.index]
                s.open = false; stash[id] = nil
                if item and item.onSelect then item.onSelect(item.args) end
                break
            elseif IsDisabledControlJustPressed(0, 177) then
                s.open = false; stash[id] = nil
                break
            end
        end
    end)
end

--------------------------------------------------------------------------------
-- Public Open
--------------------------------------------------------------------------------
function TM.Menu.Open(opts)
    opts = opts or {}
    local sys = TM.Systems.Menu
    if sys == 'ox' and TM.HasResource(TM.Exports.oxLib) then return openOx(opts) end
    if sys == 'qb' and TM.HasResource(TM.Exports.qbMenu) then return openQb(opts) end
    return openNative(opts)
end

--------------------------------------------------------------------------------
-- Close (best-effort; ox_lib hides context, others auto-close on selection)
--------------------------------------------------------------------------------
function TM.Menu.Close()
    if TM.HasResource(TM.Exports.oxLib) then
        pcall(function() exports[TM.Exports.oxLib]:hideContext() end)
    end
    if TM.HasResource(TM.Exports.qbMenu) then
        pcall(function() exports[TM.Exports.qbMenu]:closeMenu() end)
    end
    for k, s in pairs(stash) do s.open = false; stash[k] = nil end
end
