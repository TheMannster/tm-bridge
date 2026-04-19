--==============================================================================
--  tm-bridge :: shared/money.lua
--  TM.Money -- get / add / remove cash & bank across frameworks (server only).
--  Wraps the noisy framework calls into a single consistent surface.
--==============================================================================

TM.Money = {}

if TM.Client then
    -- Client-side mirror so scripts can ask "how much cash do I have?"
    function TM.Money.Get(account)
        local d = TM.Player.Data()
        if not d then return 0 end
        return (d.money and d.money[account or 'cash']) or 0
    end
    return
end

--------------------------------------------------------------------------------
-- Server
--------------------------------------------------------------------------------
local function withPlayer(src, fn)
    local p = TM.Player.Get(src)
    if not p then
        TM.Log.warn('TM.Money: no player object for src=' .. tostring(src))
        return false
    end
    return fn(p)
end

function TM.Money.Get(src, account)
    account = account or 'cash'
    return withPlayer(src, function(p)
        local fw = TM.Framework.name
        if fw == 'qbcore' or fw == 'qbox' or fw == 'rsg' then
            return p.PlayerData and p.PlayerData.money and p.PlayerData.money[account] or 0
        end
        if fw == 'esx' then
            if account == 'cash' or account == 'money' then return p.getMoney and p:getMoney() or 0 end
            local acc = p.getAccount and p:getAccount(account)
            return (acc and acc.money) or 0
        end
        return 0
    end) or 0
end

function TM.Money.Add(src, amount, account, reason)
    if not amount or amount <= 0 then return false end
    account = account or 'cash'
    return withPlayer(src, function(p)
        local fw = TM.Framework.name
        if fw == 'qbcore' or fw == 'qbox' or fw == 'rsg' then
            return p.Functions and p.Functions.AddMoney and p.Functions.AddMoney(account, amount, reason or 'tm-bridge') == true
        end
        if fw == 'esx' then
            if account == 'cash' or account == 'money' then p.addMoney(amount); return true end
            p.addAccountMoney(account, amount); return true
        end
    end)
end

function TM.Money.Remove(src, amount, account, reason)
    if not amount or amount <= 0 then return false end
    account = account or 'cash'
    return withPlayer(src, function(p)
        local fw = TM.Framework.name
        if fw == 'qbcore' or fw == 'qbox' or fw == 'rsg' then
            return p.Functions and p.Functions.RemoveMoney and p.Functions.RemoveMoney(account, amount, reason or 'tm-bridge') == true
        end
        if fw == 'esx' then
            if account == 'cash' or account == 'money' then p.removeMoney(amount); return true end
            p.removeAccountMoney(account, amount); return true
        end
    end)
end

--------------------------------------------------------------------------------
-- Charge: only succeeds if the player has the funds; remove + return bool
--------------------------------------------------------------------------------
function TM.Money.Charge(src, amount, account, reason)
    account = account or 'cash'
    if TM.Money.Get(src, account) < amount then return false end
    return TM.Money.Remove(src, amount, account, reason)
end

function TM.Money.Fund(src, amount, account, reason)
    return TM.Money.Add(src, amount, account, reason)
end
