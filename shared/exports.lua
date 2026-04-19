--==============================================================================
--  tm-bridge :: shared/exports.lua
--  Canonical registry of every external resource tm-bridge can talk to.
--  Other files always read from TM.Exports.<key> instead of hard-coding strings,
--  so renaming a resource only requires changing it here.
--==============================================================================

TM.Exports = {
    ----------------------------------------------------------------------------
    -- Frameworks
    ----------------------------------------------------------------------------
    qbcore      = 'qb-core',
    qbox        = 'qbx_core',
    esx         = 'es_extended',
    oxcore      = 'ox_core',
    rsg         = 'rsg-core',

    ----------------------------------------------------------------------------
    -- Inventories
    ----------------------------------------------------------------------------
    invOX       = 'ox_inventory',
    invQB       = 'qb-inventory',
    invQBOld    = 'lj-inventory',
    invPS       = 'ps-inventory',
    invQS       = 'qs-inventory',
    invCore     = 'core_inventory',
    invCodeM    = 'codem-inventory',
    invOrigen   = 'origen_inventory',
    invTgiann   = 'tgiann-inventory',
    invRSG      = 'rsg-inventory',

    ----------------------------------------------------------------------------
    -- UI / utility libraries
    ----------------------------------------------------------------------------
    oxLib       = 'ox_lib',
    oxTarget    = 'ox_target',
    qbTarget    = 'qb-target',
    qbMenu      = 'qb-menu',
    qbInput     = 'qb-input',
    okOk        = 'okokNotify',
    warMenu     = 'warmenu',
    polyZone    = 'PolyZone',

    ----------------------------------------------------------------------------
    -- Phones (resource ids only -- per-phone API lives in shared/phone.lua).
    -- See: https://okokphone.notion.site/Exports-Statebags-API-200220b438cf467b8c08610223d56beb
    ----------------------------------------------------------------------------
    phoneLB        = 'lb-phone',
    phoneGks       = 'gksphone',
    phoneQB        = 'qb-phone',
    phoneQS        = 'qs-smartphone',
    phoneRoad      = 'roadphone',
    phoneYflip     = 'yflip-phone',
    phoneJpr       = 'jpr-phonesystem',
    phoneEf        = 'ef-phone',
    phoneOkOk      = 'okokPhone',

    ----------------------------------------------------------------------------
    -- Banking
    --   crm-banking docs: https://corem.gitbook.io/welcome/crm-banking/exports
    ----------------------------------------------------------------------------
    bankQB      = 'qb-banking',
    bankRenewed = 'Renewed-Banking',
    bankFD      = 'fd_banking',
    bankOkOk    = 'okokBanking',
    bankCRM     = 'crm-banking',
}

--------------------------------------------------------------------------------
-- Tiny helper to query if a resource is started.  Defined here (right after the
-- export table) so EVERY other file can call TM.HasResource() safely.
--------------------------------------------------------------------------------
function TM.HasResource(name)
    if not name or name == '' then return false end
    return GetResourceState(name) == 'started'
end

--------------------------------------------------------------------------------
-- Convenience: returns the first resource (from a list) that is started.
--------------------------------------------------------------------------------
function TM.PickResource(...)
    for _, name in ipairs({ ... }) do
        if TM.HasResource(name) then return name end
    end
    return nil
end
