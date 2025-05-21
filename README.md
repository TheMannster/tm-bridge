# TM Bridge - v2.0.0

A comprehensive framework bridge for FiveM (and potentially RedM) servers, designed to allow scripts to seamlessly integrate with various core frameworks like QBCore, ESX, OX Core, and QBox. It also supports a **standalone mode** for framework-agnostic scripts.

**This bridge will be a core requirement for most, if not all, future scripts released by TheMannster Scripts.**

This project is heavily inspired by and builds upon the foundation laid by **jim_bridge**. A significant portion of the initial functionality, structural design, and utility functions were adapted from `jim_bridge`. Full credit and sincere thanks to Jim for his excellent work, without which this version would not have been possible.

## About

This bridge script acts as a compatibility layer, abstracting framework-specific functions. This means your scripts can call standardized bridge functions, and `tm-bridge` will handle the translation to the appropriate function for your active server framework. It features auto-detection for frameworks and various common systems (inventory, notifications, menus, etc.), with options for manual overrides.

## Features

-   **Multi-Framework Support:** QBCore, ESX (with ox_lib/ox_inventory dependency), QBox, OX Core, and RSG Core (for RedM).
-   **Standalone Mode:** Allows scripts to function with basic GTA natives if no major framework is detected or desired.
-   **Auto-Detection:** Automatically detects the running framework and common shared resources (inventory, menus, notifications, etc.).
-   **Override System:** Comprehensive `config.lua` allows server owners to manually specify which framework or system to use, bypassing auto-detection if needed.
-   **Shared Utilities:** Includes a rich set of helper functions for common tasks (debugging, JSON handling, vector math, raycasting, entity/vehicle/ped creation, and more).
-   **Standardized API:** Provides a consistent API for scripts to interact with core functionalities like player data, money, items, notifications, and input dialogs.

## Installation

1.  Download or clone the `tm-bridge` repository into your server's `resources` folder.
2.  Add `ensure tm-bridge` to your `server.cfg`. Ensure it's started *before* any scripts that depend on it.
3.  Review and adjust `config.lua` if you need to override any auto-detected settings (e.g., force a specific framework or menu system). By default, auto-detection should handle most setups.

## Configuration

The primary configuration file is `config.lua`.

-   **`Config.DebugMode`**: Set to `true` for verbose console prints, `false` for production.
-   **Override Settings**:
    -   `Config.FrameworkOverride`: Manually set your core framework (e.g., 'qb-core', 'esx', 'standalone').
    -   `Config.InventorySystemOverride`, `Config.MenuSystemOverride`, `Config.NotifySystemOverride`, etc.: Manually set specific systems if auto-detection fails or is not desired.
    -   `Config.DontUseTarget`: Set to `true` to disable third-party target systems (`ox_target`, `qb-target`) and use a basic DrawText3D fallback for target interactions.
-   **Exports**: The `Exports` table lists standardized names used by the bridge to identify common resources. These generally do not need to be changed unless you have uniquely named forks of these resources.

Refer to the comments within `config.lua` for more detailed explanations of each option.

## For Developers (Using the Bridge in Your Scripts)

To use `tm-bridge` in your scripts:

1.  Add `tm-bridge` as a dependency in your script's `fxmanifest.lua`:
    ```lua
    dependencies {
        'tm-bridge'
    }
    ```
2.  Access bridge functions through the global `Bridge` table or specific exports. For example:
    ```lua
    -- Client-side example
    Bridge.Notify("Info", "This is a notification!", "info")
    local playerData = Bridge.GetPlayer()

    -- Server-side example
    local xPlayer = Bridge.GetPlayer(source)
    Bridge.AddMoney(source, "bank", 1000)
    ```
3.  Explore the `shared/` folder within `tm-bridge` to see available functions and their usage. Key files include:
    -   `helpers.lua`: General utility functions.
    -   `notify.lua`: For displaying notifications.
    -   `input.lua`: For creating input dialogs.
    -   `targets.lua`: For creating interaction targets.
    -   `playerfunctions.lua`, `itemcontrol.lua`, `inventories.lua`: For player and item interactions.

## Credits

-   **Jim (jim_bridge):** This project is heavily inspired by and extensively utilizes concepts, structure, and utility functions from `jim_bridge`. His work was foundational to `tm-bridge`.
-   **Framework Developers:** Creators and maintainers of QBCore, ESX, OX Core, QBox, RSG Core, and various inventory/library resources like ox_lib, ox_inventory, etc.

## Required by

-   tm-pmrobbery
-   (This bridge will be required for most, if not all, future TheMannster Scripts resources)

## License

This script is licensed under the MIT License. 