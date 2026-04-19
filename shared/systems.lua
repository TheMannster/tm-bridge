--==============================================================================
--  tm-bridge :: shared/systems.lua
--  Auto-detects the UI / inventory / interaction systems present on the server
--  (notify, menu, inventory, drawText, target, progress bar, skill check).
--  Each can be force-overridden in config.lua.
--==============================================================================

TM.Systems = {}

local Cfg = Config and Config.System or {}

--------------------------------------------------------------------------------
-- Notification system
--------------------------------------------------------------------------------
local function pickNotify()
    if Cfg.Notify then return Cfg.Notify end
    if TM.HasResource(TM.Exports.okOk)  then return 'okok'  end
    if TM.HasResource(TM.Exports.oxLib) then return 'ox'    end
    if TM.Framework.name == 'qbcore' or TM.Framework.name == 'qbox' then return 'qb' end
    if TM.Framework.name == 'esx' then return 'esx' end
    if TM.Framework.name == 'rsg' then return 'rsg' end
    return 'gta'
end

--------------------------------------------------------------------------------
-- Menu system
--------------------------------------------------------------------------------
local function pickMenu()
    if Cfg.Menu then return Cfg.Menu end
    if TM.HasResource(TM.Exports.oxLib)  then return 'ox'   end
    if TM.HasResource(TM.Exports.qbMenu) then return 'qb'   end
    if TM.HasResource(TM.Exports.warMenu) then return 'war' end
    return 'gta'
end

--------------------------------------------------------------------------------
-- Input dialog system
--------------------------------------------------------------------------------
local function pickInput()
    if Cfg.Input then return Cfg.Input end
    if TM.HasResource(TM.Exports.oxLib)   then return 'ox' end
    if TM.HasResource(TM.Exports.qbInput) then return 'qb' end
    if TM.Framework.name == 'esx' then return 'esx' end
    return 'gta'
end

--------------------------------------------------------------------------------
-- Inventory system
--------------------------------------------------------------------------------
local function pickInventory()
    if Cfg.Inventory then return Cfg.Inventory end
    if TM.HasResource(TM.Exports.invOX)     then return 'ox'     end
    if TM.HasResource(TM.Exports.invQS)     then return 'qs'     end
    if TM.HasResource(TM.Exports.invPS)     then return 'ps'     end
    if TM.HasResource(TM.Exports.invCodeM)  then return 'codem'  end
    if TM.HasResource(TM.Exports.invOrigen) then return 'origen' end
    if TM.HasResource(TM.Exports.invTgiann) then return 'tgiann' end
    if TM.HasResource(TM.Exports.invCore)   then return 'core'   end
    if TM.HasResource(TM.Exports.invQB)     then return 'qb'     end
    if TM.HasResource(TM.Exports.invQBOld)  then return 'qbold'  end
    if TM.HasResource(TM.Exports.invRSG)    then return 'rsg'    end
    return 'framework'   -- fall back to framework's built-in inventory
end

--------------------------------------------------------------------------------
-- Progress bar
--------------------------------------------------------------------------------
local function pickProgress()
    if Cfg.Progress then return Cfg.Progress end
    if TM.HasResource(TM.Exports.oxLib)  then return 'ox' end
    if TM.Framework.name == 'qbcore' or TM.Framework.name == 'qbox' then return 'qb' end
    if TM.Framework.name == 'esx' and TM.HasResource('esx_progressbar') then return 'esx' end
    if TM.IsRedM then return 'rdr3' end
    return 'gta'
end

--------------------------------------------------------------------------------
-- Skill check
--------------------------------------------------------------------------------
local function pickSkill()
    if Cfg.Skill then return Cfg.Skill end
    if TM.HasResource(TM.Exports.oxLib) then return 'ox' end
    if TM.Framework.name == 'qbcore' or TM.Framework.name == 'qbox' then return 'qb' end
    return 'gta'
end

--------------------------------------------------------------------------------
-- DrawText / Help text
--------------------------------------------------------------------------------
local function pickDrawText()
    if Cfg.DrawText then return Cfg.DrawText end
    if TM.HasResource(TM.Exports.oxLib) then return 'ox' end
    if TM.Framework.name == 'qbcore' or TM.Framework.name == 'qbox' then return 'qb' end
    if TM.Framework.name == 'esx' then return 'esx' end
    if TM.IsRedM then return 'rdr3' end
    return 'gta'
end

--------------------------------------------------------------------------------
-- Target system
--------------------------------------------------------------------------------
local function pickTarget()
    if Cfg.Target then return Cfg.Target end
    if Cfg.DontUseTarget then return 'none' end
    if TM.HasResource(TM.Exports.oxTarget) then return 'ox' end
    if TM.HasResource(TM.Exports.qbTarget) then return 'qb' end
    return 'none'
end

--------------------------------------------------------------------------------
-- Zone library
--------------------------------------------------------------------------------
local function pickZone()
    if Cfg.Zone then return Cfg.Zone end
    if TM.HasResource(TM.Exports.oxLib)    then return 'ox'   end
    if TM.HasResource(TM.Exports.polyZone) then return 'poly' end
    return 'none'
end

--------------------------------------------------------------------------------
-- Banking
--------------------------------------------------------------------------------
local function pickBank()
    if Cfg.Bank then return Cfg.Bank end
    if TM.HasResource(TM.Exports.bankRenewed) then return 'renewed' end
    if TM.HasResource(TM.Exports.bankFD)      then return 'fd'      end
    if TM.HasResource(TM.Exports.bankCRM)     then return 'crm'     end
    if TM.HasResource(TM.Exports.bankOkOk)    then return 'okok'    end
    if TM.HasResource(TM.Exports.bankQB)      then return 'qb'      end
    return 'framework'
end

--------------------------------------------------------------------------------
-- Apply
--------------------------------------------------------------------------------
TM.Systems.Notify    = pickNotify()
TM.Systems.Menu      = pickMenu()
TM.Systems.Input     = pickInput()
TM.Systems.Inventory = pickInventory()
TM.Systems.Progress  = pickProgress()
TM.Systems.Skill     = pickSkill()
TM.Systems.DrawText  = pickDrawText()
TM.Systems.Target    = pickTarget()
TM.Systems.Zone      = pickZone()
TM.Systems.Bank      = pickBank()

TM.Log.debug(('systems: notify=%s menu=%s input=%s inv=%s prog=%s skill=%s text=%s target=%s zone=%s bank=%s'):format(
    TM.Systems.Notify, TM.Systems.Menu, TM.Systems.Input, TM.Systems.Inventory,
    TM.Systems.Progress, TM.Systems.Skill, TM.Systems.DrawText,
    TM.Systems.Target, TM.Systems.Zone, TM.Systems.Bank))
