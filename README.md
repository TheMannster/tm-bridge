<div align="center">

# tm-bridge

**One bridge. Every framework. One API.**

The framework abstraction layer that powers every TheMannster script.
Drop it in, forget about it, write your scripts against a single
`TM.*` API -- regardless of whether your server runs QBCore, QBox, ESX,
OX Core, RSG (RedM), or no framework at all.

[![FiveM](https://img.shields.io/badge/FiveM-supported-success?style=flat-square)](https://fivem.net/)
[![RedM](https://img.shields.io/badge/RedM-supported-success?style=flat-square)](https://redm.net/)
[![Lua](https://img.shields.io/badge/Lua-5.4-blue?style=flat-square&logo=lua)](https://www.lua.org/)
[![License](https://img.shields.io/badge/License-Proprietary-darkred?style=flat-square)](LICENSE)
[![Version](https://img.shields.io/badge/version-3.0.0-informational?style=flat-square)](CHANGELOG.md)

</div>

---

## Why?

Writing a script that supports more than one framework usually means
shipping six copies of every function (`if QBCore then ... elseif ESX
then ...`), or pulling in a different bridge for each one.

`tm-bridge` collapses that whole problem into a single **synchronous
detection pass at script load**, then exposes one consistent surface:

```lua
-- Works on QBCore, QBox, ESX, OX Core, RSG Core, or standalone.
TM.Notify.Show('Bank Robbery', 'Cops have been alerted', 'error')
TM.Money.Charge(src, 250, 'cash', 'Vending machine')
TM.Items.Add(src, 'water', 1)
```

It auto-routes to whatever inventory, menu, notify, target, progress
bar, draw text, skill check, banking and phone resource you have
running -- and lets you override any of those if you want.

---

## Features

-   **Six framework backends** -- QBCore, QBox, ESX (legacy + new),
    OX Core, RSG Core (RedM), Standalone. Auto-detected.
-   **Drop-in ecosystem support** -- `ox_lib`, `ox_inventory`,
    `ox_target`, `qb-target`, `qb-menu`, `qb-input`, `okokNotify`,
    `PolyZone`, `Renewed-Banking`, `qb-banking`, `okokBanking`, `crm-banking`,
    `fd_banking`, `lb-phone`, `qb-phone`, `qs-smartphone`, `gksphone`,
    `roadphone`, `yflip-phone`, `jpr-phonesystem`, `ef-phone`,
    `okokPhone` and more -- detected and wired automatically.
-   **One namespace** -- everything lives under `TM.*` (no scattered
    globals, no `if framework == 'qbcore' then` boilerplate in your
    consumer scripts).
-   **Cross-resource access** -- one export call hands you the live
    `TM` table from any other resource:
    `local TM = exports['tm-bridge']:GetTM()`.
-   **Token-gated server events** -- built-in `TM.Auth` issues one-shot,
    time-limited tokens for sensitive actions (item spawning, stash
    opening, crafting) so injectors can't fire your events directly.
-   **Cinematic boot banner** -- prints exactly which framework /
    inventory / notify / menu / etc. it resolved to, so you can verify
    detection at a glance.
-   **GitHub-aware version checker** -- pings the repo on startup and
    prints the top section of `CHANGELOG.md` if you're behind.
-   **GTA V _and_ RedM** -- single resource serves both games; RedM-only
    helpers (`TM.Animal`, RDR3 progress, RDR3 draw text) light up
    automatically when running under `rdr3`.

---

## Install

```bash
cd resources
git clone https://github.com/TheMannster/tm-bridge.git
```

Then in your `server.cfg` -- **before** any TM script that depends on it:

```cfg
ensure tm-bridge
```

In your own resource's `fxmanifest.lua`:

```lua
dependencies { 'tm-bridge' }
```

That's it. Boot the server and you'll see something like:

```text
================================================================
  tm-bridge  v3.0.0
  Framework bridge + shared utilities
================================================================
  framework      : qbcore
  inventory      : ox
  notify         : ox
  menu           : ox
  input          : ox
  progress       : ox
  skill          : ox
  drawtext       : ox
  target         : ox
  zone           : ox
  bank           : renewed
================================================================
[tm-bridge] version up to date (v3.0.0, latest v3.0.0)
```

---

## Supported backends

| System         | Auto-detected backends                                                                                                                                            |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Framework**  | `qb-core`, `qbx_core`, `es_extended` (legacy + new), `ox_core`, `rsg-core`, standalone                                                                            |
| **Inventory**  | `ox_inventory`, `qb-inventory`, `lj-inventory`, `ps-inventory`, `qs-inventory`, `core_inventory`, `codem-inventory`, `origen_inventory`, `tgiann-inventory`, `rsg-inventory` |
| **Notify**     | `ox_lib`, `okokNotify`, QBCore, ESX, RSG, native GTA/RDR3                                                                                                         |
| **Menu**       | `ox_lib`, `qb-menu`, `warmenu`, native scrollwheel fallback                                                                                                       |
| **Input**      | `ox_lib`, `qb-input`, ESX dialog, native fallback                                                                                                                 |
| **Progress**   | `ox_lib`, QBCore, ESX, RDR3 native, GTA native                                                                                                                    |
| **Skill**      | `ox_lib`, `qb-skillbar`, native button-mash fallback                                                                                                              |
| **DrawText**   | `ox_lib`, QBCore, ESX, RDR3 native, GTA native                                                                                                                    |
| **Target**     | `ox_target`, `qb-target`, 3D-text fallback                                                                                                                        |
| **Zones**      | `ox_lib` zones, `PolyZone`                                                                                                                                        |
| **Banking**    | `Renewed-Banking`, `fd_banking`, `crm-banking`, `qb-banking`, `okokBanking`, ESX `addonaccount`                                                                    |
| **Phone**      | `lb-phone`, `gksphone`, `qb-phone`, `qs-smartphone`, `roadphone`, `yflip-phone`, `jpr-phonesystem`, `ef-phone`, `okokPhone`                                       |

---

## Quick start

### 1. Use it from a resource that depends on `tm-bridge`

`TM` is a global. Just write code:

```lua
-- Server
RegisterCommand('refuel', function(source)
    if not TM.Money.Charge(source, 50, 'cash', 'Refuel') then
        return TM.Notify.Send(source, 'Refuel', 'Not enough cash', 'error')
    end
    TM.Items.Add(source, 'jerrycan', 1)
    TM.Notify.Send(source, 'Refuel', 'Here you go.', 'success')
    TM.Phone.Mail({
        source = source, sender = 'Garage',
        subject = 'Receipt', message = 'Refuel: $50',
    })
end, false)
```

```lua
-- Client
CreateThread(function()
    while true do
        Wait(0)
        local veh = TM.Vehicle.Closest()
        if veh then
            TM.Text.Show('[E] Hotwire')
            if IsControlJustReleased(0, 38) then
                local ok = TM.Skill.Run({ difficulty = 'medium' })
                if ok and TM.Progress.Bar({ duration = 4000, label = 'Hotwiring...' }) then
                    SetVehicleEngineOn(veh, true, true, false)
                    TM.Notify.Show('Hotwired', '', 'success')
                end
            end
        else
            TM.Text.Hide()
        end
    end
end)
```

### 2. Use it from a resource that does NOT depend on `tm-bridge`

```lua
local TM = exports['tm-bridge']:GetTM()
TM.Notify.Show('Hello', 'from any resource', 'success')
```

Or call the curated named exports directly (see `bridge/client.lua`,
`bridge/server.lua`):

```lua
exports['tm-bridge']:Notify('Saved!', 'success')
local has = exports['tm-bridge']:HasItem(source, 'water', 1)
```

---

## Public API at a glance

> Full per-module reference is in `CHANGELOG.md` and inline in each
> `shared/<module>.lua`.

| Module                  | Surface (what it gives you)                                          |
| ----------------------- | -------------------------------------------------------------------- |
| `shared/core.lua`       | `TM`, `TM.Log` (info / warn / err / debug / banner)                  |
| `shared/framework.lua`  | `TM.Framework.name`, `TM.Framework.object`                           |
| `shared/systems.lua`    | `TM.Systems.{Notify,Menu,Inventory,Progress,Target,Zone,Bank,...}`   |
| `shared/data.lua`       | `TM.Data.{Items, Vehicles, Jobs, Gangs}`                             |
| `shared/lifecycle.lua`  | `TM.Lifecycle.OnStart/OnStop/OnPlayerLoaded/WaitFor`                 |
| `shared/util.lua`       | `TM.Util.{Table, Math, Format, Crypto, Raycast, Debug}`              |
| `shared/callback.lua`   | `TM.Callback.Register / Trigger / TriggerAsync`                      |
| `shared/notify.lua`     | `TM.Notify.Show / Send / Help`                                       |
| `shared/text.lua`       | `TM.Text.Show / Hide / Help / Draw3D / Draw2D`                       |
| `shared/input.lua`      | `TM.Input.Open / Confirm`                                            |
| `shared/menu.lua`       | `TM.Menu.Open / Close`                                               |
| `shared/progress.lua`   | `TM.Progress.Bar / Stop`                                             |
| `shared/skill.lua`      | `TM.Skill.Run`                                                       |
| `shared/command.lua`    | `TM.Command.Register`                                                |
| `shared/asset.lua`      | `TM.Asset.{Model, AnimDict, AnimSet, Texture, Ptfx, AudioBank}`      |
| `shared/anim.lua`       | `TM.Anim.{Play, Stop, PlayFor}`, `TM.Sound.{PlayFrontend, PlayAt}`   |
| `shared/target.lua`     | `TM.Target.{AddEntity, AddBox, AddSphere, AddModel, Remove*}`        |
| `shared/zone.lua`       | `TM.Zone.{Poly, Sphere, Box, Remove}`                                |
| `shared/vehicle.lua`    | `TM.Vehicle.{Closest, Plate, Properties, RequestControl, Info}`      |
| `shared/entity.lua`     | `TM.Entity.{SetScale, FacePoint, ...}`, `TM.DUI.{Create, Set, ...}`  |
| `shared/effects.lua`    | `TM.Effects.{Alien, Weed, Trevor, Focus, NightVision, Heal, ...}`    |
| `shared/animal.lua`     | `TM.Animal.{Type, Is, IsCat, IsDog, IdleAnim}` (RDR3)                |
| `shared/player.lua`     | `TM.Player.{Get, Data, Identifier, IsLoggedIn, NearbyPlayers}`       |
| `shared/money.lua`      | `TM.Money.{Get, Add, Remove, Charge, Fund}`                          |
| `shared/job.lua`        | `TM.Job.*` + `TM.Gang.*` (Get, Has, IsBoss, OnDuty, Set, ToggleDuty) |
| `shared/meta.lua`       | `TM.Meta.{Get, Set}`                                                 |
| `shared/needs.lua`      | `TM.Needs.{Hunger, Thirst, Stress, Get, Set, Add}`                   |
| `shared/society.lua`    | `TM.Society.{GetBalance, Add, Remove}`                               |
| `shared/auth.lua`       | `TM.Auth.{Issue, Verify, Request, Store, RegisterEndpoint}`          |
| `shared/items.lua`      | `TM.Items.{Has, Count, Add, Remove, Image, Durability*, Useable}`    |
| `shared/inventory.lua`  | `TM.Inventory.{Open, Lock, IsLocked, IsOpen, List, CanCarry}`        |
| `shared/stash.lua`      | `TM.Stash.{Register, Open, Items, AddItem, RemoveItem, HasItem}`     |
| `shared/shop.lua`       | `TM.Shop.{Register, Open, SellMenu}`                                 |
| `shared/crafting.lua`   | `TM.Crafting.{Register, Open, Make, Apply}` (token-guarded)          |
| `shared/rewards.lua`    | `TM.Rewards.{Roll, RollMany}` (weighted)                             |
| `shared/phone.lua`      | `TM.Phone.{Mail, Message}`                                           |
| `shared/make.lua`       | `TM.Make.{Ped, DistPed, Prop, Vehicle, Blip, EntityBlip, Cam.*}`     |
| `shared/scaleform.lua`  | `TM.Scaleform.{BigMessage, Countdown, Instructional, TimerBar, ...}` |

---

## Configuration

Everything lives in `config.lua`. Defaults are sensible, so most servers
don't need to touch anything.

```lua
Config.DebugMode    = false
Config.VersionCheck = true   -- repo/branch are hard-coded in server/versioncheck.lua

-- Leave any of these nil to auto-detect.
Config.FrameworkOverride = nil   -- 'qbcore' | 'qbox' | 'esx' | 'oxcore' | 'rsg' | 'standalone'

Config.System = {
    Notify    = nil,   -- 'ox' | 'okok' | 'qb' | 'esx' | 'rsg' | 'gta'
    Menu      = nil,   -- 'ox' | 'qb' | 'war' | 'gta'
    Input     = nil,   -- 'ox' | 'qb' | 'esx' | 'gta'
    Inventory = nil,   -- 'ox' | 'qb' | 'qbold' | 'ps' | 'qs' | 'codem' | 'origen' | 'tgiann' | 'core' | 'rsg' | 'framework'
    Progress  = nil,   -- 'ox' | 'qb' | 'esx' | 'rdr3' | 'gta'
    Skill     = nil,   -- 'ox' | 'qb' | 'gta'
    DrawText  = nil,   -- 'ox' | 'qb' | 'esx' | 'rdr3' | 'gta'
    Target    = nil,   -- 'ox' | 'qb' | 'none'
    Zone      = nil,   -- 'ox' | 'poly' | 'none'
    Bank      = nil,   -- 'renewed' | 'fd' | 'crm' | 'qb' | 'okok' | 'framework'
    DontUseTarget = false,
}
```

After detection runs you can read the resolved values from anywhere:

```lua
print(TM.Framework.name)    -- 'qbcore'
print(TM.Systems.Inventory) -- 'ox'
print(TM.Systems.Notify)    -- 'ox'
```

---

## Project layout

```
tm-bridge/
├── fxmanifest.lua         deterministic load order
├── config.lua             single source of truth for every setting
├── CHANGELOG.md           top section is what the version checker prints
├── README.md              you are here
├── version.txt            kept in sync with the manifest version field
│
├── shared/                runs on BOTH client and server
│   ├── core.lua               TM root + TM.Log
│   ├── exports.lua            canonical resource names + helpers
│   ├── framework.lua          framework auto-detection
│   ├── systems.lua            inv/menu/notify/target/progress/text/skill/zone/bank
│   ├── data.lua               Items / Vehicles / Jobs / Gangs
│   ├── lifecycle.lua          OnResourceStart/Stop/OnPlayerLoaded helpers
│   ├── util.lua               Table / Math / Format / Crypto / Raycast
│   │
│   ├── callback.lua           TM.Callback
│   ├── notify.lua             TM.Notify
│   ├── text.lua               TM.Text  (drawText / help / 3D world text)
│   ├── input.lua              TM.Input
│   ├── menu.lua               TM.Menu
│   ├── progress.lua           TM.Progress
│   ├── skill.lua              TM.Skill
│   ├── command.lua            TM.Command
│   │
│   ├── asset.lua              TM.Asset
│   ├── anim.lua               TM.Anim + TM.Sound
│   ├── target.lua             TM.Target
│   ├── zone.lua               TM.Zone
│   ├── vehicle.lua            TM.Vehicle
│   ├── entity.lua             TM.Entity + TM.DUI
│   ├── effects.lua            TM.Effects
│   ├── animal.lua             TM.Animal  (RDR3)
│   │
│   ├── player.lua             TM.Player
│   ├── money.lua              TM.Money
│   ├── job.lua                TM.Job + TM.Gang
│   ├── meta.lua               TM.Meta
│   ├── needs.lua              TM.Needs
│   ├── society.lua            TM.Society
│   │
│   ├── auth.lua               TM.Auth   (token-gated server events)
│   ├── items.lua              TM.Items
│   ├── inventory.lua          TM.Inventory
│   ├── stash.lua              TM.Stash
│   ├── shop.lua               TM.Shop + SellMenu helper
│   ├── crafting.lua           TM.Crafting
│   ├── rewards.lua            TM.Rewards
│   │
│   ├── phone.lua              TM.Phone
│   ├── make.lua               TM.Make  (Ped/Prop/Vehicle/Blip/Cam)
│   └── scaleform.lua          TM.Scaleform
│
├── bridge/                cross-resource export surface
│   ├── client.lua
│   └── server.lua
│
└── server/
    ├── boot.lua           streetside-style banner
    └── versioncheck.lua   GitHub-aware updater + CHANGELOG printing
```

Load order is **deterministic** -- it lives in `fxmanifest.lua`, grouped
into `core` → `ui` → `world` → `player` → `inventory` → `misc`.

---

## Examples

<details>
<summary><b>Notifications</b></summary>

```lua
TM.Notify.Show('Bank Robbery', 'Cops have been alerted', 'error')
TM.Notify.Send(source, 'Mail', 'You have a new email', 'info')
TM.Notify.Help('Press [E] to open')
```
</details>

<details>
<summary><b>Player + money + items (server)</b></summary>

```lua
local data = TM.Player.Data(source)
print(data.citizenid, data.job.name, data.money.cash)

if TM.Money.Charge(source, 100, 'cash', 'Repair') then
    TM.Items.Add(source, 'repairkit', 1)
end

if TM.Items.Has(source, 'lockpick', 1) then
    TM.Items.Remove(source, 'lockpick', 1)
end
```
</details>

<details>
<summary><b>Inputs, menus, progress, skillchecks (client)</b></summary>

```lua
local res = TM.Input.Open({
    title = 'Pick a number',
    fields = { { type = 'number', name = 'n', label = 'Number', min = 1, max = 99 } },
})
if res then print(res.n) end

TM.Menu.Open({
    title = 'Garage',
    options = {
        { label = 'Withdraw', value = 'wd' },
        { label = 'Deposit',  value = 'dp' },
    },
    onSelect = function(opt) print('picked', opt.value) end,
})

if TM.Skill.Run({ difficulty = 'easy' }) then
    if TM.Progress.Bar({ duration = 4000, label = 'Hacking...' }) then
        TM.Notify.Show('Hacked', '', 'success')
    end
end
```
</details>

<details>
<summary><b>Vehicles</b></summary>

```lua
local veh   = TM.Vehicle.Closest()
local plate = TM.Vehicle.Plate(veh)
local props = TM.Vehicle.GetProperties(veh)
TM.Vehicle.SetProperties(veh, props)
TM.Vehicle.RequestControl(veh)
print(TM.Vehicle.Info(veh))
```
</details>

<details>
<summary><b>Crafting + token-guarded server events</b></summary>

```lua
-- Client opens a crafting bench:
TM.Crafting.Open({
    title = 'Workbench',
    recipes = {
        { name = 'rod', label = 'Fishing Rod',
          required = { stick = 1, wire = 2 },
          give = { fishingrod = 1 },
          duration = 4000 },
    },
})

-- Server handler (token-gated automatically):
TM.Crafting.Register('rod', { fishingrod = 1 })
```
</details>

<details>
<summary><b>Phones (mail / message)</b></summary>

```lua
TM.Phone.Mail({
    source  = src,
    sender  = 'Mechanic',
    subject = 'Vehicle ready',
    message = 'Pick it up at the impound.',
})

TM.Phone.Message({ source = src, from = 'Boss', message = 'Get to the office.' })
```

Routes to whichever phone you have running -- `lb-phone`, `qb-phone`,
`okokPhone`, etc. Falls back to `TM.Notify.Send` if no phone is present.
</details>

<details>
<summary><b>Cross-resource access</b></summary>

```lua
-- Any resource, even ones that don't depend on tm-bridge:
local TM = exports['tm-bridge']:GetTM()
TM.Notify.Show('Hello', '', 'success')

-- Or named exports:
exports['tm-bridge']:Notify('Saved!', 'success')
local has = exports['tm-bridge']:HasItem(source, 'water', 1)
```
</details>

---

## Versioning

`tm-bridge` follows [Semantic Versioning](https://semver.org/). Major
version bumps = breaking API changes (e.g. `2.x → 3.0` was the rewrite
into the `TM.*` namespace). Minor = additive features. Patch = bug
fixes only.

The version checker pings GitHub on server start and -- if the local
build is behind -- prints the top section of `CHANGELOG.md` so operators
know what changed:

```text
[tm-bridge] [warn] version OUTDATED - running v3.0.0, latest is v3.1.0
[tm-bridge] download: https://github.com/TheMannster/tm-bridge
[tm-bridge] changelog:
  ## [3.1.0] - 2026-05-01
  - Added okokPhone integration
  - ...
```

Disable it with `Config.VersionCheck = false` in `config.lua`.

---

## Contributing

Open an **issue** before large changes. Pull requests are welcome **at the
maintainer's discretion** and must align with [`LICENSE`](LICENSE) (no
redistribution of this codebase outside your channel; contribution grants no
rights beyond what the license allows).

The codebase is intentionally flat -- one module per file under `shared/`, no nested folders, deterministic load
order in `fxmanifest.lua`. If you want to add support for a new backend
(notify lib, inventory, phone, etc.):

1.  Add the resource id to `shared/exports.lua` under the matching
    section.
2.  Add a detection branch to `shared/systems.lua` (if it's a system
    type) or directly to the relevant module.
3.  Add the routing branch in the consumer module (`shared/notify.lua`,
    `shared/phone.lua`, ...).
4.  Bump `version` in `fxmanifest.lua` + `version.txt` and add a
    `## [x.y.z] - YYYY-MM-DD` section to the top of `CHANGELOG.md`.

---

## Credits

-   Framework devs whose APIs `tm-bridge` adapts: **QBCore**, **QBox**,
    **ESX**, **OX Core**, **RSG Core**.
-   Ecosystem libraries auto-detected and routed to: `ox_lib`,
    `ox_inventory`, `ox_target`, `qb-target`, `qb-menu`, `qb-input`,
    `okokNotify`, `PolyZone`, `Renewed-Banking`, `qb-banking`,
    `okokBanking`, `fd_banking`, plus every supported phone listed
    above.
-   Thanks to the FiveM / RedM developer community for the
    documentation, support and feedback that made this resource
    possible.

---

## License

This resource is **proprietary** — see [`LICENSE`] for the full terms.

In short: you may run and adapt it **for your own server**; you may **not** redistribute the source as a standalone package, sell it as a primary product, or embed these files in other releases for redistribution. Point end users to **your** official distribution channel.

<div align="center">

Made with caffeine by **TheMannster**.

</div>
