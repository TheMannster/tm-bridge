--==============================================================================
--  tm-bridge :: shared/crafting.lua
--  TM.Crafting -- a tiny menu-and-progressbar driven crafting helper that
--  enforces ingredient checks via TM.Items + TM.Auth tokens.  Designed for
--  workbench-style stations (think jewelry, gunsmithing, BBQ).
--
--  Recipe format:
--      {
--          name        = 'fishingrod',
--          label       = 'Fishing Rod',
--          required    = { stick = 1, wire = 2 },
--          give        = { fishingrod = 1 },
--          duration    = 4000,
--          anim        = { dict = 'amb@world_human_hammering@male@base', name = 'base' },
--          camera      = nil,  -- optional TM.Make.Cam
--          job         = nil,
--          successNotify = 'You crafted a fishing rod.',
--          failNotify  = 'Crafting failed.',
--      }
--==============================================================================

TM.Crafting = {}

--==============================================================================
-- CLIENT: OPEN MENU
--==============================================================================
if TM.Client then
    function TM.Crafting.Open(spec)
        spec = spec or {}
        local rows = {}
        for _, recipe in ipairs(spec.recipes or {}) do
            local reqLines = {}
            for item, count in pairs(recipe.required or {}) do
                local label = (TM.Data.Items[item] and TM.Data.Items[item].label) or item
                local have = TM.Items.Count(nil, item)
                reqLines[#reqLines + 1] = ('%s %d/%d'):format(label, have, count)
            end
            rows[#rows + 1] = {
                title = recipe.label or recipe.name,
                desc  = table.concat(reqLines, ' | '),
                icon  = recipe.icon,
                onSelect = function() TM.Crafting.Make(recipe) end,
            }
        end
        TM.Menu.Open({ title = spec.title or 'Crafting', items = rows })
    end

    --------------------------------------------------------------------------------
    -- CLIENT: MAKE -- runs the progress bar then asks the server to apply
    --------------------------------------------------------------------------------
    function TM.Crafting.Make(recipe)
        for item, count in pairs(recipe.required or {}) do
            if not TM.Items.Has(nil, item, count) then
                TM.Notify.Show('Crafting', 'Missing ' .. item, 'error'); return false
            end
        end

        local token = TM.Auth.Request('crafting', 30000)
        if not token then return false end

        local ok = TM.Progress.Bar({
            label    = 'Crafting ' .. (recipe.label or recipe.name),
            duration = recipe.duration or 4000,
            anim     = recipe.anim,
        })
        if not ok then return false end

        TriggerServerEvent(TM.Resource .. ':crafting:apply', token, recipe.name)
        if recipe.successNotify then TM.Notify.Show('Crafting', recipe.successNotify, 'success') end
        return true
    end
end

--==============================================================================
-- SERVER: REGISTER RECIPES + APPLY HANDLER
--==============================================================================
if TM.Server then
    local registry = {}

    function TM.Crafting.Register(recipe)
        if not recipe or not recipe.name then return TM.Log.warn('TM.Crafting.Register missing name') end
        registry[recipe.name] = recipe
    end

    function TM.Crafting.Apply(src, name)
        local recipe = registry[name]
        if not recipe then return false end

        for item, count in pairs(recipe.required or {}) do
            if not TM.Items.Has(src, item, count) then return false end
        end

        for item, count in pairs(recipe.required or {}) do
            TM.Items.Remove(src, item, count)
        end
        for item, count in pairs(recipe.give or {}) do
            TM.Items.Add(src, item, count)
        end

        return true
    end

    TM.Auth.RegisterEndpoint(TM.Resource .. ':crafting:apply', 'crafting', function(src, recipeName)
        TM.Crafting.Apply(src, recipeName)
    end)
end
