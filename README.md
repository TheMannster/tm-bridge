# TM Bridge

A simple framework bridge script that allows TM Scripts to work with both QBCore and Qbox frameworks.

## About

This bridge script acts as a compatibility layer between TM Scripts and your chosen framework. It handles all the necessary framework-specific functions and ensures smooth operation of TM Scripts regardless of whether you're using QBCore or Qbox.

## Installation

1. Place `tm-bridge` in your resources folder
2. Add `ensure tm-bridge` to your server.cfg
3. Configure your framework in the config file

## Configuration

Open `config.lua` and set your framework:
```lua
Config.Framework = "qbcore" -- options: "qbcore", "qbox"
```

## Required by

- TM Parking Meter Robbery
- Other TM Scripts

## License

This script is licensed under the MIT License. 