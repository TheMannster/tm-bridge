--==============================================================================
--  tm-bridge :: shared/society.lua
--  TM.Society -- read / mutate society (faction) bank balances.  Auto-routes
--  through Renewed-Banking, fd_banking, crm-banking, qb-banking, okokBanking,
--  or the ESX addon "esx_addonaccount" depending on what's installed.
--
--  crm-banking export reference:
--      https://corem.gitbook.io/welcome/crm-banking/exports
--==============================================================================

TM.Society = {}

if TM.Client then return end

local function call(name, ...)
    if not TM.HasResource(name) then return nil end
    return exports[name][select(1, ...)](exports[name], select(2, ...))
end

--------------------------------------------------------------------------------
-- Get balance
--------------------------------------------------------------------------------
function TM.Society.GetBalance(society)
    local sys = TM.Systems.Bank
    if sys == 'renewed' then
        return call(TM.Exports.bankRenewed, 'getAccountMoney', society) or 0
    end
    if sys == 'fd' then
        return call(TM.Exports.bankFD, 'GetAccountBalance', society) or 0
    end
    if sys == 'crm' then
        return call(TM.Exports.bankCRM, 'getSocietyMoney', society) or 0
    end
    if sys == 'qb' then
        return call(TM.Exports.bankQB, 'GetAccountBalance', society) or 0
    end
    if sys == 'okok' then
        return call(TM.Exports.bankOkOk, 'GetAccount', society) or 0
    end

    -- ESX addonaccount fallback
    if TM.Framework.name == 'esx' and TM.HasResource('esx_addonaccount') then
        local p = promise.new()
        TriggerEvent('esx_addonaccount:getSharedAccount', society, function(acc)
            p:resolve(acc and acc.money or 0)
        end)
        return Citizen.Await(p)
    end
    return 0
end

--------------------------------------------------------------------------------
-- Mutate
--------------------------------------------------------------------------------
function TM.Society.Add(society, amount, reason)
    if not amount or amount <= 0 then return false end
    local sys = TM.Systems.Bank
    if sys == 'renewed' then call(TM.Exports.bankRenewed, 'addAccountMoney', society, amount); return true end
    if sys == 'fd'      then call(TM.Exports.bankFD, 'AddAccountBalance', society, amount, reason or 'tm-bridge'); return true end
    if sys == 'crm'     then
        local ok = call(TM.Exports.bankCRM, 'addSocietyMoney', society, amount)
        --  Best-effort transaction log; the export is a no-op if not present.
        pcall(function()
            exports[TM.Exports.bankCRM]:addSocietyTransaction(society, amount, 'crm-deposit', reason or 'tm-bridge', nil)
        end)
        return ok ~= false
    end
    if sys == 'qb'      then call(TM.Exports.bankQB, 'AddMoney', society, amount, reason or 'tm-bridge'); return true end
    if sys == 'okok'    then call(TM.Exports.bankOkOk, 'AddMoney', society, amount); return true end
    if TM.Framework.name == 'esx' and TM.HasResource('esx_addonaccount') then
        TriggerEvent('esx_addonaccount:getSharedAccount', society, function(acc)
            if acc then acc.addMoney(amount) end
        end)
        return true
    end
    return false
end

function TM.Society.Remove(society, amount, reason)
    if not amount or amount <= 0 then return false end
    local sys = TM.Systems.Bank
    if sys == 'renewed' then call(TM.Exports.bankRenewed, 'removeAccountMoney', society, amount); return true end
    if sys == 'fd'      then call(TM.Exports.bankFD, 'RemoveAccountBalance', society, amount, reason or 'tm-bridge'); return true end
    if sys == 'crm'     then
        local ok = call(TM.Exports.bankCRM, 'removeSocietyMoney', society, amount)
        pcall(function()
            exports[TM.Exports.bankCRM]:addSocietyTransaction(society, amount, 'crm-withdraw', reason or 'tm-bridge', nil)
        end)
        return ok ~= false
    end
    if sys == 'qb'      then call(TM.Exports.bankQB, 'RemoveMoney', society, amount, reason or 'tm-bridge'); return true end
    if sys == 'okok'    then call(TM.Exports.bankOkOk, 'RemoveMoney', society, amount); return true end
    if TM.Framework.name == 'esx' and TM.HasResource('esx_addonaccount') then
        TriggerEvent('esx_addonaccount:getSharedAccount', society, function(acc)
            if acc then acc.removeMoney(amount) end
        end)
        return true
    end
    return false
end
