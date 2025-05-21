-- Version Check (inspired by jim_bridge)
local currentVersion = "2.0.0" -- Should match version.txt
local resourceName = GetCurrentResourceName()
local githubRepo = "TheMannster/tm-bridge" -- Replace with your actual GitHub repo path if different

local function CheckVersion()
    PerformHttpRequest(string.format("https://raw.githubusercontent.com/%s/development/version.txt", githubRepo), function(err, text, headers)
        if err == 200 then
            local latestVersion = text:match("^%s*(.-)%s*$") -- Trim whitespace
            if latestVersion and latestVersion ~= currentVersion then
                local msg = string.format("[%s] Your version (%s) is outdated! Latest is %s. Get it from https://github.com/%s",
                                        resourceName, currentVersion, latestVersion, githubRepo)
                Print(msg)
                if Config.DebugMode then
                    SendNUIMessage({ -- Example NUI message for developers if you have an NUI
                        action = "showNotification",
                        type = "warning",
                        message = msg
                    })
                end
            elseif latestVersion then
                Print(string.format("[%s] Version %s is up to date.", resourceName, currentVersion))
            else
                Print(string.format("[%s] Could not parse latest version from GitHub.", resourceName), "WARN")
            end
        else
            Print(string.format("[%s] Could not check for updates (HTTP Error: %s).", resourceName, err), "WARN")
        end
    end)
end

-- Run check shortly after resource start, only on server to avoid spam
if IsDuplicityVersion() then
    Citizen.CreateThread(function()
        Citizen.Wait(10000) -- Wait 10 seconds before checking
        CheckVersion()
    end)
end

DebugPrint("_versioncheck.lua loaded.") 