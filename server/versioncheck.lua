--==============================================================================
--  tm-bridge :: server/versioncheck.lua
--  Pings GitHub for the latest fxmanifest version; if the local build is
--  behind, prints the top section of CHANGELOG.md so the operator can see
--  what changed.  Repo/branch are hard-coded here on purpose -- they live
--  with the code, not in the user's config.
--==============================================================================

if Config.VersionCheck == false then return end

local REPO   = 'TheMannster/tm-bridge'
local BRANCH = 'main'

local LOCAL  = GetResourceMetadata(TM.Resource, 'version', 0) or '0.0.0'
local RAW    = ('https://raw.githubusercontent.com/%s/%s'):format(REPO, BRANCH)

local function parseVersion(str)
    str = tostring(str or ''):gsub('^[vV]', '')
    local parts = {}
    for chunk in str:gmatch('[^%.]+') do parts[#parts + 1] = tonumber(chunk) or 0 end
    return parts
end

local function compareVersions(a, b)
    local pa, pb = parseVersion(a), parseVersion(b)
    local n = math.max(#pa, #pb)
    for i = 1, n do
        local av, bv = pa[i] or 0, pb[i] or 0
        if av < bv then return -1 elseif av > bv then return 1 end
    end
    return 0
end

local function topChangelogSection(md)
    if not md or md == '' then return nil end
    local first = md:find('\n##%s')
    if not first then return md end
    local rest = md:sub(first + 1)
    local second = rest:find('\n##%s')
    if second then return rest:sub(1, second - 1) end
    return rest
end

local function printChangelog(text)
    if not text or text == '' then return end
    TM.Log.info('changelog:')
    for line in (text .. '\n'):gmatch('([^\n]*)\n') do
        if line ~= '' then print(('  ^7%s'):format(line)) end
    end
end

local function fetch(url, cb)
    PerformHttpRequest(url, function(status, body)
        cb((status == 200) and body or nil, status)
    end, 'GET', '', { ['User-Agent'] = 'tm-bridge-versioncheck' })
end

CreateThread(function()
    Wait(3000)

    fetch(RAW .. '/fxmanifest.lua', function(manifest, status)
        if not manifest then
            TM.Log.warn(('version check failed (HTTP %s) - running ^2v%s^7'):format(tostring(status), LOCAL))
            return
        end

        local padded = '\n' .. manifest
        local remote = padded:match("[\n\r;]version%s+'([^']+)'") or padded:match('[\n\r;]version%s+"([^"]+)"')
        if not remote then
            TM.Log.warn('version check: could not find version field in remote fxmanifest.lua')
            return
        end

        if compareVersions(LOCAL, remote) >= 0 then
            TM.Log.info(('version up to date (^2v%s^7, latest ^2v%s^7)'):format(LOCAL, remote))
            return
        end

        TM.Log.warn(('version ^1OUTDATED^7 - running ^3v%s^7, latest is ^2v%s^7'):format(LOCAL, remote))
        TM.Log.info(('download: ^4https://github.com/%s^7'):format(REPO))

        fetch(RAW .. '/CHANGELOG.md', function(changelog)
            printChangelog(topChangelogSection(changelog))
        end)
    end)
end)
