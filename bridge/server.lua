--==============================================================================
--  tm-bridge :: bridge/server.lua
--  Cross-resource server export surface.  Mirrors bridge/client.lua but for
--  per-player server work.  Resources should grab the live TM table via
--  `local TM = exports['tm-bridge']:GetTM()` and call the modules directly.
--==============================================================================

exports('GetTM',          function() return TM end)
exports('GetFramework',   function() return TM.Framework.name end)
exports('GetSystems',     function() return TM.Systems end)

exports('GetPlayer',      function(src) return TM.Player.Get(src) end)
exports('GetIdentifier',  function(src) return TM.Player.Identifier(src) end)
exports('GetPlayerData',  function(src) return TM.Player.Data(src) end)

exports('HasItem',        function(src, item, amount) return TM.Items.Has(src, item, amount) end)
exports('CountItem',      function(src, item) return TM.Items.Count(src, item) end)
exports('AddItem',        function(src, item, amount, meta, slot) return TM.Items.Add(src, item, amount, meta, slot) end)
exports('RemoveItem',     function(src, item, amount, meta, slot) return TM.Items.Remove(src, item, amount, meta, slot) end)
exports('RegisterUseable',function(item, cb) return TM.Items.RegisterUseable(item, cb) end)

exports('GetMoney',       function(src, account) return TM.Money.Get(src, account) end)
exports('AddMoney',       function(src, amount, account, reason) return TM.Money.Add(src, amount, account, reason) end)
exports('RemoveMoney',    function(src, amount, account, reason) return TM.Money.Remove(src, amount, account, reason) end)
exports('ChargeMoney',    function(src, amount, account, reason) return TM.Money.Charge(src, amount, account, reason) end)

exports('GetSociety',     function(name) return TM.Society.GetBalance(name) end)
exports('AddSociety',     function(name, amt, reason) return TM.Society.Add(name, amt, reason) end)
exports('RemoveSociety',  function(name, amt, reason) return TM.Society.Remove(name, amt, reason) end)

exports('NotifyPlayer',   function(src, title, msg, kind, dur) TM.Notify.Send(src, title, msg, kind, dur) end)
exports('PhoneMail',      function(spec) return TM.Phone.Mail(spec) end)

exports('RegisterCallback', function(name, cb) TM.Callback.Register(name, cb) end)
exports('RegisterStash',    function(opts) TM.Stash.Register(opts) end)
exports('RegisterShop',     function(opts) TM.Shop.Register(opts) end)
exports('RegisterRecipe',   function(recipe) TM.Crafting.Register(recipe) end)
