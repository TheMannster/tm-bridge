--==============================================================================
--  tm-bridge :: shared/core.lua
--  Establishes the root `TM` namespace and the `TM.Log` console writer.
--  Loads first so every other file can rely on TM and TM.Log being present.
--==============================================================================

TM = TM or {}
TM.Version  = '3.0.0'
TM.Resource = GetCurrentResourceName()
TM.Server   = IsDuplicityVersion() == true
TM.Client   = not TM.Server
TM.Game     = (GetGameName and GetGameName()) or (GetConvar and GetConvar('gamename', 'gta5')) or 'gta5'
TM.IsRedM   = TM.Game == 'rdr3'

--------------------------------------------------------------------------------
-- Logger
--------------------------------------------------------------------------------
TM.Log = {}

local PFX = '^5[tm-bridge]^7 '

local function out(channel, msg)
    print(PFX .. channel .. tostring(msg) .. '^7')
end

function TM.Log.info(msg)  out('^2', msg) end
function TM.Log.warn(msg)  out('^3', '[warn] ' .. msg) end
function TM.Log.err(msg)   out('^1', '[err]  ' .. msg) end
function TM.Log.debug(msg)
    if not (Config and Config.DebugMode) then return end
    out('^6', '[dbg]  ' .. msg)
end
function TM.Log.tag(tag, msg) out('^6[' .. tag .. ']^7 ', msg) end

--------------------------------------------------------------------------------
-- Boot banner pieces (used by the server boot script)
--------------------------------------------------------------------------------
function TM.Log.line()
    print('^5================================================================^7')
end

function TM.Log.banner(title, subtitle)
    TM.Log.line()
    print('^5  ' .. (title or 'tm-bridge') .. '^7  ^3v' .. TM.Version .. '^7')
    if subtitle and subtitle ~= '' then
        print('^7  ' .. subtitle)
    end
    TM.Log.line()
end

function TM.Log.module(label, value, ok)
    local v = tostring(value or 'none')
    local colour = ok == false and '^1' or (ok == true and '^2' or '^3')
    print(string.format('^7  %-14s ^7: %s%s^7', label, colour, v))
end

function TM.Log.footer()
    TM.Log.line()
end

--------------------------------------------------------------------------------
-- Pretty JSON dump (debug-mode only)
--------------------------------------------------------------------------------
function TM.Log.dump(label, data)
    if not (Config and Config.DebugMode) then return end
    local ok, encoded = pcall(json.encode, data, { indent = true, sort_keys = true })
    print(PFX .. '^6[dump]^7 ' .. tostring(label or '') .. ' = ' .. (ok and encoded or tostring(data)))
end

--------------------------------------------------------------------------------
-- Boot line
--------------------------------------------------------------------------------
TM.Log.debug(('core ready (resource=%s, side=%s, game=%s)'):format(TM.Resource, TM.Server and 'server' or 'client', TM.Game))
