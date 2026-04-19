--==============================================================================
--  tm-bridge :: shared/rewards.lua
--  TM.Rewards -- weighted random reward picker.  Pure logic; no game side
--  effects so it can run on either client or server.
--==============================================================================

TM.Rewards = {}

--  Pick one entry from a weighted reward table:
--      table = { { item = 'apple', amount = 1, chance = 60 },
--                { item = 'gold',  amount = 1, chance = 5  } }
--  Chances do not need to sum to 100 -- they are rolled relative to the total.
function TM.Rewards.Roll(rewardTable)
    if type(rewardTable) ~= 'table' or #rewardTable == 0 then return nil end
    local total = 0
    for _, r in ipairs(rewardTable) do total = total + (r.chance or 0) end
    if total <= 0 then return nil end
    local pick = TM.Util.Crypto.Random(1, total)
    local acc = 0
    for _, r in ipairs(rewardTable) do
        acc = acc + (r.chance or 0)
        if pick <= acc then return r end
    end
end

--  Roll N times and aggregate counts -- handy for "loot bag" scenarios.
function TM.Rewards.RollMany(rewardTable, count)
    local out = {}
    for _ = 1, (count or 1) do
        local r = TM.Rewards.Roll(rewardTable); if not r then return out end
        local key = r.item
        out[key] = out[key] or { item = key, amount = 0, metadata = r.metadata }
        out[key].amount = out[key].amount + (r.amount or 1)
    end
    return out
end
