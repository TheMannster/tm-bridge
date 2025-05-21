--[[ Input Dialog Module - Refactored for tm-bridge
    ---------------------
    This module provides a function to create a simple input dialog compatible with
    multiple menu systems. It supports various input types such as radio buttons,
    numbers, text, and select dropdowns. It now uses Config.Menu and FrameworkFuncs.
]]

function createInput(title, opts)
    local fwClient = FrameworkFuncs[Config.Framework] and FrameworkFuncs[Config.Framework].Client

    if Config.Menu == "ox" then
        if not fwClient or not fwClient.InputDialog then 
            DebugPrint("createInput: OXCoreClient.InputDialog not found! Falling back to direct ox_lib export if available.", "WARN")
            if Utils.Helpers.isStarted(Exports.OXLib) and lib.inputDialog then
                -- Prepare options for ox_lib:inputDialog format
                local oxOptions = {}
                for i = 1, #opts do
                    local currentOpt = opts[i]
                    if currentOpt then
                        if currentOpt.type == "radio" then
                            for k in pairs(currentOpt.options) do currentOpt.options[k].label = currentOpt.options[k].text end
                            oxOptions[#oxOptions+1] = { type = "select", isRequired = currentOpt.isRequired, label = currentOpt.label or currentOpt.text, name = currentOpt.name, default = currentOpt.default or currentOpt.options[1].value, options = currentOpt.options }
                        elseif currentOpt.type == "number" then
                            oxOptions[#oxOptions+1] = { type = currentOpt.type, label = (currentOpt.label or currentOpt.text)..(currentOpt.txt and " - "..currentOpt.txt or ""), isRequired = currentOpt.isRequired, name = currentOpt.name, options = currentOpt.options, min = currentOpt.min, max = currentOpt.max, default = currentOpt.default }
                        elseif currentOpt.type == "text" then
                            oxOptions[#oxOptions+1] = { type = "input", label = (currentOpt.label or currentOpt.text)..(currentOpt.txt and " - "..currentOpt.txt or ""), default = currentOpt.default, isRequired = currentOpt.isRequired, name = currentOpt.name }
                        elseif currentOpt.type == "select" then
                             oxOptions[#oxOptions+1] = { type = currentOpt.type, label = (currentOpt.label or currentOpt.text)..(currentOpt.txt and " - "..currentOpt.txt or ""), isRequired = currentOpt.isRequired, name = currentOpt.name, options = currentOpt.options, min = currentOpt.min, max = currentOpt.max, default = currentOpt.default }
                        elseif currentOpt.type == "checkbox" then
                            -- OX lib checkbox might be different, this is a basic interpretation
                            for k_cb, v_cb in ipairs(currentOpt.options) do
                                oxOptions[#oxOptions+1] = { type = currentOpt.type, label = v_cb.text..(currentOpt.txt and " - "..currentOpt.txt or ""), name = v_cb.value, default = v_cb.default or false }
                            end
                        else
                             oxOptions[#oxOptions+1] = currentOpt -- Pass as is for other types like color, slider
                        end
                    end
                end
                return lib.inputDialog(title, oxOptions)
            else
                DebugPrint("createInput: ox_lib or lib.inputDialog not available for OX menu.", "ERROR")
                return nil
            end
        end
        -- Standard path: Use FrameworkFuncs.Client.InputDialog for OX
        local oxOptions = {}
        for i = 1, #opts do
            local currentOpt = opts[i]
            if currentOpt then
                if currentOpt.type == "radio" then
                    for k_rad in pairs(currentOpt.options) do currentOpt.options[k_rad].label = currentOpt.options[k_rad].text end
                    oxOptions[#oxOptions+1] = { type = "select", isRequired = currentOpt.isRequired, label = currentOpt.label or currentOpt.text, name = currentOpt.name, default = currentOpt.default or currentOpt.options[1].value, options = currentOpt.options }
                elseif currentOpt.type == "number" then
                     oxOptions[#oxOptions+1] = { type = currentOpt.type, label = (currentOpt.label or currentOpt.text)..(currentOpt.txt and " - "..currentOpt.txt or ""), isRequired = currentOpt.isRequired, name = currentOpt.name, options = currentOpt.options, min = currentOpt.min, max = currentOpt.max, default = currentOpt.default }
                elseif currentOpt.type == "text" then
                    oxOptions[#oxOptions+1] = { type = "input", label = (currentOpt.label or currentOpt.text)..(currentOpt.txt and " - "..currentOpt.txt or ""), default = currentOpt.default, isRequired = currentOpt.isRequired, name = currentOpt.name }
                 elseif currentOpt.type == "select" then
                    oxOptions[#oxOptions+1] = { type = currentOpt.type, label = (currentOpt.label or currentOpt.text)..(currentOpt.txt and " - "..currentOpt.txt or ""), isRequired = currentOpt.isRequired, name = currentOpt.name, options = currentOpt.options, min = currentOpt.min, max = currentOpt.max, default = currentOpt.default }
                elseif currentOpt.type == "checkbox" then
                     for k_cb, v_cb in ipairs(currentOpt.options) do
                        oxOptions[#oxOptions+1] = { type = currentOpt.type, label = v_cb.text..(currentOpt.txt and " - "..currentOpt.txt or ""), name = v_cb.value, default = v_cb.default or false }
                    end
                else
                    oxOptions[#oxOptions+1] = currentOpt -- Pass as is for other types like color, slider
                end
            end
        end
        return fwClient.InputDialog(title, oxOptions)

    elseif Config.Menu == "qb" then
        if not fwClient or not fwClient.ShowInput then
            DebugPrint("createInput: QBClient.ShowInput not found! Falling back to direct qb-input export if available.", "WARN")
            if Utils.Helpers.isStarted('qb-input') and exports['qb-input'] and exports['qb-input'].ShowInput then
                return exports['qb-input']:ShowInput({ header = title, submitText = "Accept", inputs = opts })
            else
                DebugPrint("createInput: qb-input export not available for QB menu.", "ERROR")
                return nil
            end
        end
        -- Standard path: Use FrameworkFuncs.Client.ShowInput for QB
        -- qb-input expects opts directly in its `inputs` field.
        return fwClient.ShowInput(title, "Accept", opts) 

    elseif Config.Menu == "esx" then
        if fwClient and fwClient.ShowInputDialog then
            return fwClient.ShowInputDialog(title, opts)
        else
            -- Fallback to original ESX logic if ShowInputDialog not in FrameworkFuncs
            DebugPrint("createInput: ESXClient.ShowInputDialog not found. Using direct ESX UI logic.", "INFO")
            local results = {}
            for i, opt in ipairs(opts) do
                local prompt = opt.text or opt.label or "Enter value"
                if (opt.type == "radio" or opt.type == "select") and opt.options then
                    local choices = ""
                    for j, choice in ipairs(opt.options) do
                        choices = choices .. choice.text .. " (" .. tostring(choice.value) .. ")"
                        if j < #opt.options then choices = choices .. ", " end
                    end
                    prompt = prompt .. " [" .. choices .. "]"
                elseif opt.type == "number" then
                    prompt = prompt .. " (number between " .. (opt.min or 0) .. " and " .. (opt.max or 100) .. ")"
                end
                local value = nil
                ESX.UI.Menu.Open('dialog', Config.ResourceName, 'input_' .. i, { title = prompt }, 
                    function(data, menu) value = data.value; menu.close() end, 
                    function(data, menu) menu.close() end)
                while value == nil do Wait(0) end
                if opt.type == "number" then value = tonumber(value) end
                results[opt.name or i] = value
            end
            return results
        end

    elseif Config.Menu == "gta" then
        if not Utils.Helpers.isStarted(Exports.WarMenu) then
            DebugPrint("createInput: WarMenu is not started. Cannot use GTA style input.", "ERROR")
            return nil
        end
        -- WarMenu logic is complex and uses its own global. Keep direct implementation for now.
        WarMenu.CreateMenu(tostring(opts), title, " ", { titleColor = { 222, 255, 255 }, maxOptionCountOnScreen = 15, width = 0.25, x = 0.7, })
        if WarMenu.IsAnyMenuOpened() then return end
        WarMenu.OpenMenu(tostring(opts))
        local close = true
        local _comboBoxItems = {}
        local _comboBoxIndex = {}

        for i=1, #opts do _comboBoxIndex[i] = opts[i].defaultIndex or 1 end -- Initialize default index for comboboxes

        while true do
            if WarMenu.Begin(tostring(opts)) then
                for i = 1, #opts do
                    if opts[i].type == "radio" or opts[i].type == "select" then
                        if not _comboBoxItems[i] then 
                            _comboBoxItems[i] = {}
                            for k_item, v_item in ipairs(opts[i].options) do
                                _comboBoxItems[i][k_item] = v_item.text
                            end
                        end
                        local _, comboBoxIndex = WarMenu.ComboBox(opts[i].label or opts[i].text, _comboBoxItems[i], _comboBoxIndex[i])
                        if _comboBoxIndex[i] ~= comboBoxIndex then _comboBoxIndex[i] = comboBoxIndex end
                    elseif opts[i].type == "number" then
                        if not _comboBoxItems[i] then 
                            _comboBoxItems[i] = {}
                            for b = (opts[i].min or 1), (opts[i].max or 10) do -- Default range if not specified
                                _comboBoxItems[i][#_comboBoxItems[i]+1] = tostring(b)
                            end
                        end
                         local _, comboBoxIndex = WarMenu.ComboBox(opts[i].text, _comboBoxItems[i], _comboBoxIndex[i])
                        if _comboBoxIndex[i] ~= comboBoxIndex then _comboBoxIndex[i] = comboBoxIndex end
                    elseif opts[i].type == "text" then
                         -- WarMenu doesn't have a direct text input like qb-input or ox_lib dialog.
                         -- This would require a more complex solution, perhaps using game's keyboard input.
                         -- For now, this option will be non-functional or displayed as simple text.
                        WarMenu.Label(opts[i].text or opts[i].label or "Text Input (Not directly supported)")
                    end
                end
                if WarMenu.Button("Accept") then -- Changed from "Pay"
                    WarMenu.CloseMenu()
                    close = false
                    local result = {}
                    for i = 1, #opts do
                        if (opts[i].type == "radio" or opts[i].type == "select") and _comboBoxItems[i] then
                            result[opts[i].name or i] = opts[i].options[_comboBoxIndex[i]].value -- Return the actual value
                        elseif opts[i].type == "number" and _comboBoxItems[i] then
                            result[opts[i].name or i] = tonumber(_comboBoxItems[i][_comboBoxIndex[i]])
                        elseif opts[i].type == "text" then
                            result[opts[i].name or i] = "" -- Placeholder for text input
                        end
                    end
                    return result
                end
                WarMenu.End()
            else
                return nil -- Menu was closed externally or failed to begin
            end
            if not WarMenu.IsAnyMenuOpened() and close then
                -- if data.onExit then data.onExit() end -- data variable not defined in this scope
                return nil -- Menu closed without accepting
            end
            Wait(0)
        end
    else
        DebugPrint("createInput: No valid Config.Menu system detected or configured: " .. tostring(Config.Menu), "ERROR")
    end
    return nil
end