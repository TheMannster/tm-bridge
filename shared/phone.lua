--==============================================================================
--  tm-bridge :: shared/phone.lua
--  TM.Phone -- mail / message helpers across popular FiveM phones:
--      lb-phone, gksphone, qb-phone, qs-smartphone, roadphone, yflip-phone,
--      jpr-phonesystem, ef-phone, okokPhone.  Server-side only (clients just
--      receive the resulting events).
--
--  okokPhone reference (Exports / Statebags / API):
--      https://okokphone.notion.site/Exports-Statebags-API-200220b438cf467b8c08610223d56beb
--==============================================================================

TM.Phone = {}

if TM.Client then return end

--------------------------------------------------------------------------------
-- Internal helpers
--------------------------------------------------------------------------------

-- Fetches the okokPhone email address for an online src.  Returns nil if the
-- export isn't present, the player has no equipped phone, or no email is set.
local function okokEmailForSource(src)
    local ok, email = pcall(function()
        return exports[TM.Exports.phoneOkOk]:getEmailAddressFromSource(tonumber(src))
    end)
    if ok and type(email) == 'string' and email ~= '' then return email end
    return nil
end

--------------------------------------------------------------------------------
-- TM.Phone.Mail(spec)
--   spec = {
--       source  = <player src>,
--       sender  = 'System',
--       subject = 'New Message',
--       message = 'body...',
--       button  = { text = 'Open', event = 'evt:name', data = {...} }, -- optional
--   }
--   Returns true if a phone backend handled it, false if it fell back to a notify.
--------------------------------------------------------------------------------
function TM.Phone.Mail(spec)
    spec = spec or {}
    if not spec.source then
        return TM.Log.warn('TM.Phone.Mail: missing source')
    end

    local src = tonumber(spec.source)
    local id  = TM.Player.Identifier(src)

    --  okokPhone (https://okokphone.notion.site/Exports-Statebags-API-200220b438cf467b8c08610223d56beb)
    if TM.HasResource(TM.Exports.phoneOkOk) then
        local email = okokEmailForSource(src)
        if email then
            exports[TM.Exports.phoneOkOk]:sendEmail({
                sender     = spec.sender  or 'System',
                recipients = { email },
                subject    = spec.subject or 'New Message',
                body       = spec.message or '',
            })
            return true
        end
    end

    if TM.HasResource(TM.Exports.phoneLB) then
        exports[TM.Exports.phoneLB]:SendMail({
            to       = id,
            sender   = spec.sender  or 'System',
            subject  = spec.subject or 'New Message',
            message  = spec.message or '',
            actions  = spec.button and { {
                type  = 'event',
                label = spec.button.text or 'Open',
                data  = { event = spec.button.event, data = spec.button.data },
            } } or nil,
        })
        return true
    end

    if TM.HasResource(TM.Exports.phoneGks) then
        TriggerClientEvent('gksphone:newMail', src, {
            sender  = spec.sender,
            subject = spec.subject,
            message = spec.message,
            button  = spec.button,
        })
        return true
    end

    if TM.HasResource(TM.Exports.phoneQB) then
        TriggerEvent('qb-phone:server:sendNewMail', {
            source  = src,
            sender  = spec.sender,
            subject = spec.subject,
            message = spec.message,
            button  = spec.button or {},
        })
        return true
    end

    if TM.HasResource(TM.Exports.phoneQS) then
        TriggerClientEvent('qs-smartphone:client:sendMail', src,
            spec.subject, spec.sender, spec.message)
        return true
    end

    if TM.HasResource(TM.Exports.phoneRoad) then
        exports[TM.Exports.phoneRoad]:sendMail({
            identifier = id,
            sender     = spec.sender,
            subject    = spec.subject,
            message    = spec.message,
        })
        return true
    end

    if TM.HasResource(TM.Exports.phoneYflip) then
        exports[TM.Exports.phoneYflip]:SendMail({
            to      = id,
            sender  = spec.sender,
            subject = spec.subject,
            body    = spec.message,
        })
        return true
    end

    if TM.HasResource(TM.Exports.phoneJpr) then
        TriggerClientEvent('jpr-phonesystem:client:newMail', src,
            spec.sender, spec.subject, spec.message)
        return true
    end

    if TM.HasResource(TM.Exports.phoneEf) then
        exports[TM.Exports.phoneEf]:Mail({
            source  = src,
            sender  = spec.sender,
            subject = spec.subject,
            message = spec.message,
        })
        return true
    end

    -- Fallback: notify the player so the message isn't silently dropped.
    TM.Notify.Send(src, spec.sender or 'Phone', spec.subject or '', 'info')
    return false
end

--------------------------------------------------------------------------------
-- TM.Phone.Message(spec)
--   spec = { source, from, message }
--   Falls back to TM.Phone.Mail when the active phone has no SMS surface.
--------------------------------------------------------------------------------
function TM.Phone.Message(spec)
    spec = spec or {}
    if not spec.source then
        return TM.Log.warn('TM.Phone.Message: missing source')
    end
    local src = tonumber(spec.source)

    if TM.HasResource(TM.Exports.phoneLB) then
        exports[TM.Exports.phoneLB]:SendMessage(TM.Player.Identifier(src), spec.from, spec.message)
        return true
    end

    if TM.HasResource(TM.Exports.phoneQB) then
        TriggerClientEvent('qb-phone:client:newMessage', src,
            { sender = spec.from, message = spec.message })
        return true
    end

    -- okokPhone has no public SMS export; fall through to email so the
    -- user still gets the message inside the phone.
    return TM.Phone.Mail({
        source  = src,
        sender  = spec.from,
        subject = spec.from or 'Message',
        message = spec.message,
    })
end
