--==============================================================================
--  tm-bridge :: shared/input.lua
--  TM.Input.Open(opts)         -> fields[] dialog, returns table (or nil)
--  TM.Input.Confirm(title, body) -> boolean (yes/no)
--  Routes to ox_lib > qb-input > native fallback.
--==============================================================================

TM.Input = {}

if TM.Server then return end

--------------------------------------------------------------------------------
-- Internal: convert generic schema -> system-specific schema
--------------------------------------------------------------------------------
local function toOxFields(opts)
    return opts.fields or {}
end

local function toQbFields(opts)
    local rows = {}
    for _, f in ipairs(opts.fields or {}) do
        rows[#rows + 1] = {
            type = f.type or 'text', label = f.label, name = f.name,
            isRequired = f.required, default = f.default,
            options = f.options, min = f.min, max = f.max,
        }
    end
    return rows
end

--------------------------------------------------------------------------------
-- Open
--------------------------------------------------------------------------------
function TM.Input.Open(opts)
    opts = opts or {}
    local sys = TM.Systems.Input

    if sys == 'ox' and TM.HasResource(TM.Exports.oxLib) then
        return exports[TM.Exports.oxLib]:inputDialog(opts.title or 'Input', toOxFields(opts), opts.options)
    end

    if sys == 'qb' and TM.HasResource(TM.Exports.qbInput) then
        return exports[TM.Exports.qbInput]:ShowInput({
            header    = opts.title or 'Input',
            submitText = opts.submit or 'Submit',
            inputs    = toQbFields(opts),
        })
    end

    if sys == 'esx' then
        local obj = TM.Framework.Object()
        if obj and obj.UI and obj.UI.Menu then
            local p = promise.new()
            local first = (opts.fields or {})[1] or {}
            obj.UI.Menu.Open('dialog', TM.Resource, 'tm_input_' .. (first.name or 'value'), {
                title = (first.label or opts.title or 'Input'), value = first.default,
            }, function(_, menu)
                local r = { [first.name or 'value'] = menu.value }
                menu.close()
                p:resolve(r)
            end, function(_, menu) menu.close(); p:resolve(nil) end)
            return Citizen.Await(p)
        end
    end

    -- Last-resort native: show help text and return defaults so calling code
    -- doesn't deadlock waiting for a UI we cannot render.
    TM.Log.warn('TM.Input.Open had no UI backend available; returning defaults')
    local out = {}
    for _, f in ipairs(opts.fields or {}) do out[f.name] = f.default end
    return out
end

--------------------------------------------------------------------------------
-- Confirm
--------------------------------------------------------------------------------
function TM.Input.Confirm(title, body)
    if TM.HasResource(TM.Exports.oxLib) then
        local res = exports[TM.Exports.oxLib]:alertDialog({
            header = title or 'Confirm', content = body or '', centered = true, cancel = true,
        })
        return res == 'confirm'
    end

    -- Fallback: a single-field menu
    local res = TM.Input.Open({
        title  = title or 'Confirm',
        fields = { { type = 'select', name = 'choice', label = body or 'Continue?',
                     options = { { value = 'yes', text = 'Yes' }, { value = 'no', text = 'No' } } } },
    })
    return res and res.choice == 'yes'
end
