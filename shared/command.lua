--==============================================================================
--  tm-bridge :: shared/command.lua
--  TM.Command.Register(name, cb, opts)
--      opts = { help, params = {{ name, help, type }}, restricted, suggestion }
--==============================================================================

TM.Command = {}

local function nativeRegister(name, opts, cb)
    RegisterCommand(name, function(source, args, raw)
        cb(source, args, raw)
    end, opts and opts.restricted or false)

    if TM.Client and opts and opts.suggestion ~= false then
        TriggerEvent('chat:addSuggestion', '/' .. name, opts.help or '', opts.params or {})
    end
end

function TM.Command.Register(name, cb, opts)
    opts = opts or {}

    if TM.HasResource(TM.Exports.oxLib) and TM.Server then
        return exports[TM.Exports.oxLib]:addCommand(name, {
            help     = opts.help, params = opts.params, restricted = opts.restricted,
        }, function(src, args, raw) cb(src, args, raw) end)
    end

    -- QBCore / QBox helper
    if TM.Server and (TM.Framework.name == 'qbcore' or TM.Framework.name == 'qbox') then
        local QB = TM.Framework.Object()
        if QB and QB.Commands and QB.Commands.Add then
            QB.Commands.Add(name, opts.help or '', opts.params or {},
                opts.requireArgs == true, function(source, args)
                    cb(source, args, table.concat(args or {}, ' '))
                end, opts.permission)
            return
        end
    end

    -- ESX helper
    if TM.Server and TM.Framework.name == 'esx' then
        local ESX = TM.Framework.Object()
        if ESX and ESX.RegisterCommand then
            ESX.RegisterCommand(name, opts.permission or 'user', function(xSource, args)
                cb(xSource and xSource.source or 0, args, '')
            end, false, { help = opts.help })
            return
        end
    end

    nativeRegister(name, opts, cb)
end
