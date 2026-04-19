--==============================================================================
--  tm-bridge :: shared/job.lua
--  TM.Job -- read / set job, grade, duty + gang helpers.
--==============================================================================

TM.Job  = {}
TM.Gang = {}

--------------------------------------------------------------------------------
-- Read (works client- and server-side)
--------------------------------------------------------------------------------
function TM.Job.Get(src)
    local d = TM.Player.Data(src)
    return d and d.job or nil
end

function TM.Gang.Get(src)
    local d = TM.Player.Data(src)
    return d and d.gang or nil
end

function TM.Job.Has(src, jobName, minGrade)
    local j = TM.Job.Get(src)
    if not j then return false end
    if type(jobName) == 'table' then
        for _, name in ipairs(jobName) do
            if j.name == name and (not minGrade or (j.grade or 0) >= minGrade) then return true end
        end
        return false
    end
    return j.name == jobName and (not minGrade or (j.grade or 0) >= minGrade)
end

function TM.Gang.Has(src, gangName, minGrade)
    local g = TM.Gang.Get(src)
    if not g then return false end
    if type(gangName) == 'table' then
        for _, name in ipairs(gangName) do
            if g.name == name and (not minGrade or (g.grade or 0) >= minGrade) then return true end
        end
        return false
    end
    return g.name == gangName and (not minGrade or (g.grade or 0) >= minGrade)
end

function TM.Job.IsBoss(src)
    local j = TM.Job.Get(src)
    return j and j.isboss == true
end

function TM.Gang.IsBoss(src)
    local g = TM.Gang.Get(src)
    return g and g.isboss == true
end

function TM.Job.OnDuty(src)
    local j = TM.Job.Get(src)
    return j and j.onduty ~= false
end

--------------------------------------------------------------------------------
-- Mutators (server only)
--------------------------------------------------------------------------------
if TM.Server then
    function TM.Job.Set(src, name, grade)
        local p = TM.Player.Get(src)
        if not p then return false end
        local fw = TM.Framework.name
        if fw == 'qbcore' or fw == 'qbox' or fw == 'rsg' then
            return p.Functions and p.Functions.SetJob and p.Functions.SetJob(name, grade or 0)
        end
        if fw == 'esx' then
            return p.setJob and p:setJob(name, grade or 0)
        end
    end

    function TM.Gang.Set(src, name, grade)
        local p = TM.Player.Get(src)
        if not p then return false end
        local fw = TM.Framework.name
        if fw == 'qbcore' or fw == 'qbox' then
            return p.Functions and p.Functions.SetGang and p.Functions.SetGang(name, grade or 0)
        end
    end

    function TM.Job.SetDuty(src, onDuty)
        local p = TM.Player.Get(src)
        if not p then return false end
        if p.Functions and p.Functions.SetJobDuty then
            return p.Functions.SetJobDuty(onDuty == true)
        end
    end
end

--------------------------------------------------------------------------------
-- Client-side toggle convenience: triggers the framework's toggleDuty event
--------------------------------------------------------------------------------
if TM.Client then
    function TM.Job.ToggleDuty()
        if TM.Framework.name == 'qbcore' or TM.Framework.name == 'qbox' then
            TriggerServerEvent('QBCore:ToggleDuty')
        elseif TM.Framework.name == 'esx' then
            TriggerServerEvent('esx:toggleDuty')
        end
    end
end
