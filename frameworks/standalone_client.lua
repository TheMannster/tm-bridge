-- Standalone Client-Side Logic for tm-bridge
-- This file is loaded when no specific framework (ESX, QBCore, etc.) is detected or if configured for standalone mode.
-- It should contain default behaviors, stubs, or basic native implementations for bridge functions.

DebugPrint("tm-bridge: standalone_client.lua loaded", "INFO")

-- Example: Define a Notify function if no other is available
-- if not Bridge.Notify then
--     Bridge.Notify = function(title, message, type, src)
--         -- Basic GTA native notification as a fallback
--         if src and src ~= PlayerId() then return end -- Only show to self if src is different or not specified for others
--         SetNotificationTextEntry("STRING")
--         AddTextComponentSubstringPlayerName(message)
--         DrawNotification(false, true)
--         DebugPrint(string.format("Standalone Notify: %s - %s (%s)", title, message, type), "INFO")
--     end
--     DebugPrint("tm-bridge: Using Standalone Notify.", "INFO")
-- end 