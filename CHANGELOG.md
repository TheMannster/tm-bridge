# Changelog

All notable changes to `tm-bridge` are documented here. The version checker
in `server/versioncheck.lua` reads the top section of this file when it
detects an outdated install, so keep the most recent release at the top
using `## [x.y.z]` headings.

## [3.0.0] - 2026-04-19

### Complete rewrite (clean break)

The entire `shared/` directory was rewritten from scratch under a single
`TM.*` namespace. None of the old `jim_bridge`-style names (`triggerNotify`,
`createCallback`, `addItem`, `chargePlayer`, `openMenu`, `drawText`, etc.)
exist anymore. Consumers must update to the new TM API.

- Single, deterministic load order driven by the `shared_scripts` block
  in `fxmanifest.lua` (grouped into core → ui → world → player → inventory
  → misc).
- Per-framework adapters folded into the modules that need them; the
  `frameworks/` directory is gone. Framework selection is now resolved in
  `shared/framework.lua` and used directly by `TM.Player`, `TM.Money`,
  `TM.Items`, etc.
- New token-based exploit guard module (`TM.Auth`) gates sensitive server
  events (item spawning, stash opening, crafting) by issuing one-shot
  expiring tokens.
- New `Bridge` exports surface (`bridge/client.lua`, `bridge/server.lua`)
  exposes `GetTM` so cross-resource consumers can grab the live TM table:
  `local TM = exports['tm-bridge']:GetTM()`.
- Version-checker repo/branch are hard-coded in `server/versioncheck.lua`
  so they live with the code instead of the user's config.

### Module map

| File                       | Public surface                              |
| -------------------------- | ------------------------------------------- |
| `shared/core.lua`          | `TM`, `TM.Log`                              |
| `shared/exports.lua`       | `TM.Exports`, `TM.HasResource`              |
| `shared/framework.lua`     | `TM.Framework`                              |
| `shared/systems.lua`       | `TM.Systems`                                |
| `shared/data.lua`          | `TM.Data` (Items / Vehicles / Jobs / Gangs) |
| `shared/lifecycle.lua`     | `TM.Lifecycle` (OnStart / OnPlayerLoaded)   |
| `shared/util.lua`          | `TM.Util` (Table / Math / Format / Crypto)  |
| `shared/callback.lua`      | `TM.Callback.Register/Trigger`              |
| `shared/notify.lua`        | `TM.Notify.Show/Send/Help`                  |
| `shared/text.lua`          | `TM.Text.Show/Hide/Help/Draw3D/Draw2D`      |
| `shared/input.lua`         | `TM.Input.Open/Confirm`                     |
| `shared/menu.lua`          | `TM.Menu.Open/Close`                        |
| `shared/progress.lua`      | `TM.Progress.Bar/Stop`                      |
| `shared/skill.lua`         | `TM.Skill.Run`                              |
| `shared/command.lua`       | `TM.Command.Register`                       |
| `shared/asset.lua`         | `TM.Asset.Model/AnimDict/Texture/Audio…`    |
| `shared/anim.lua`          | `TM.Anim.Play/Stop`, `TM.Sound.PlayAt/...`  |
| `shared/target.lua`        | `TM.Target.AddEntity/Box/Sphere/Model`      |
| `shared/zone.lua`          | `TM.Zone.Poly/Sphere/Box/Remove`            |
| `shared/vehicle.lua`       | `TM.Vehicle.Closest/Properties/Plate/Info`  |
| `shared/entity.lua`        | `TM.Entity` + `TM.DUI.Create/Set/Destroy`   |
| `shared/effects.lua`       | `TM.Effects.Alien/Weed/Trevor/...`          |
| `shared/animal.lua`        | `TM.Animal.Is/IsCat/IsDog/IdleAnim`         |
| `shared/player.lua`        | `TM.Player.Get/Data/Identifier/...`         |
| `shared/money.lua`         | `TM.Money.Get/Add/Remove/Charge`            |
| `shared/job.lua`           | `TM.Job` + `TM.Gang`                        |
| `shared/meta.lua`          | `TM.Meta.Get/Set`                           |
| `shared/needs.lua`         | `TM.Needs.Hunger/Thirst/Stress`             |
| `shared/society.lua`       | `TM.Society.GetBalance/Add/Remove`          |
| `shared/auth.lua`          | `TM.Auth.Issue/Verify/Request`              |
| `shared/items.lua`         | `TM.Items` (has/count/add/remove/durability)|
| `shared/inventory.lua`     | `TM.Inventory.Open/Lock/List/CanCarry`      |
| `shared/stash.lua`         | `TM.Stash.Register/Open/Items`              |
| `shared/shop.lua`          | `TM.Shop.Register/Open/SellMenu`            |
| `shared/crafting.lua`      | `TM.Crafting.Open/Make/Register`            |
| `shared/rewards.lua`       | `TM.Rewards.Roll/RollMany`                  |
| `shared/phone.lua`         | `TM.Phone.Mail/Message`                     |
| `shared/make.lua`          | `TM.Make.Ped/Prop/Vehicle/Blip/Cam`         |
| `shared/scaleform.lua`     | `TM.Scaleform.BigMessage/Countdown/...`     |

### Migration note

There are NO compatibility shims. Update your other TM scripts to call the
`TM.*` API directly. Cross-resource consumers can keep using the existing
`exports['tm-bridge']:HasItem(...)` style names; see `bridge/client.lua` and
`bridge/server.lua` for the supported list.

## [2.0.0] - 2026-04-19

Refactor pass over the original `jim_bridge`-derived prototype. Superseded
by 3.0.0; see the previous CHANGELOG entry in the git history if you need
to reference it.

## [1.x] - prior

Original prototype.
