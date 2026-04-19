--==============================================================================
--  tm-bridge :: server/boot.lua
--  Streetside-style boot banner.  Runs after every shared module so the
--  printed flags reflect the actual resolved state.
--==============================================================================

CreateThread(function()
    Wait(250)

    TM.Log.banner('tm-bridge', 'Framework bridge + shared utilities')

    TM.Log.module('framework', TM.Framework.name,    TM.Framework.name ~= 'standalone')
    TM.Log.module('inventory', TM.Systems.Inventory, TM.Systems.Inventory ~= 'framework')
    TM.Log.module('notify',    TM.Systems.Notify,    TM.Systems.Notify   ~= 'gta')
    TM.Log.module('menu',      TM.Systems.Menu,      TM.Systems.Menu     ~= 'gta')
    TM.Log.module('input',     TM.Systems.Input,     TM.Systems.Input    ~= 'gta')
    TM.Log.module('progress',  TM.Systems.Progress,  TM.Systems.Progress ~= 'gta')
    TM.Log.module('skill',     TM.Systems.Skill,     TM.Systems.Skill    ~= 'gta')
    TM.Log.module('drawtext',  TM.Systems.DrawText,  TM.Systems.DrawText ~= 'gta')
    TM.Log.module('target',    TM.Systems.Target,    TM.Systems.Target   ~= 'none')
    TM.Log.module('zone',      TM.Systems.Zone,      TM.Systems.Zone     ~= 'none')
    TM.Log.module('bank',      TM.Systems.Bank,      TM.Systems.Bank     ~= 'framework')

    TM.Log.footer()
end)
