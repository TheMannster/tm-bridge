--==============================================================================
--  tm-bridge :: bridge/client.lua
--  Cross-resource client export surface.  Most TM scripts should consume the TM
--  global directly (`local TM = exports['tm-bridge']:GetTM()`); the per-method
--  exports below exist for ergonomics and for non-Lua consumers.
--==============================================================================

exports('GetTM',          function() return TM end)
exports('GetFramework',   function() return TM.Framework.name end)
exports('GetSystems',     function() return TM.Systems end)

exports('IsPlayerLoaded', function() return TM.Lifecycle.IsPlayerLoaded() end)
exports('GetPlayerData',  function() return TM.Player.Data() end)

exports('Notify',         function(title, message, kind, dur) TM.Notify.Show(title, message, kind, dur) end)
exports('HelpText',       function(msg, beep) TM.Notify.Help(msg, beep) end)

exports('Progress',       function(opts) return TM.Progress.Bar(opts) end)
exports('Skill',          function(spec) return TM.Skill.Run(spec) end)
exports('Input',          function(opts) return TM.Input.Open(opts) end)
exports('Menu',           function(opts) TM.Menu.Open(opts) end)

exports('TriggerCallback',function(name, ...) return TM.Callback.Trigger(name, ...) end)

exports('HasItem',        function(item, amount) return TM.Items.Has(nil, item, amount) end)
exports('CountItem',      function(item) return TM.Items.Count(nil, item) end)
exports('ItemImage',      function(item) return TM.Items.Image(item) end)

exports('GetVehicleProperties', function(veh) return TM.Vehicle.GetProperties(veh) end)
exports('SetVehicleProperties', function(veh, p) TM.Vehicle.SetProperties(veh, p) end)
exports('ClosestVehicle',       function(coords, radius) return TM.Vehicle.Closest(coords, radius) end)

exports('OpenShop',     function(id, opts) TM.Shop.Open(id, opts) end)
exports('OpenStash',    function(id, opts) TM.Stash.Open(id, opts) end)
exports('OpenCrafting', function(spec) TM.Crafting.Open(spec) end)
