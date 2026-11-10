# FS Vehicle Keys
**Developed by FS Labs**

An advanced, secure, and fully optimized Vehicle Lock & Key System designed for ESX Legacy and ox_inventory.

## 🌟 Features
- **Physical Keys:** Vehicle keys exist as physical items with metadata in `ox_inventory`.
- **Immersive Animations:** Custom animations for fob clicks, lockpicking, smashing windows, and hotwiring.
- **Lock/Unlock System:** Dedicated bind to toggle vehicle locks seamlessly.
- **Lockpicking Minigame:** Integration with `ox_lib` skill checks for picking vehicle locks.
- **Hotwire System:** No key? Smash the window and hotwire the ignition to gain temporary access.
- **Engine Failure System:** Hotwired cars have a chance to stall and take engine damage while driving.
- **Key Management:** Owners can share keys (up to a configurable limit) or revoke them.
- **Vehicle Transfer:** Easily transfer keys when selling a vehicle (purges old keys from online players).
- **Admin Tools:** Generate or remove keys via command.
- **High Security:** Fully server-sided validations to prevent exploit and event abuse.
- **Discord Logs:** Extensive webhook logging for security monitoring.
- **Highly Optimized:** 0.00ms idle usage. Event-driven architecture.

## 📋 Requirements
- ESX Legacy
- ox_inventory
- ox_lib

## 🛠️ Installation

1. Drop the `fs_vehiclekeys` folder into your `resources` directory.
2. Add `ensure fs_vehiclekeys` to your `server.cfg`.

### 📦 ox_inventory Setup
You need to register the physical key and lockpick items. Navigate to `ox_inventory/data/items.lua` and add the following:

```lua
['vehicle_key'] = {
    label = 'Vehicle Key',
    weight = 50,
    stack = false,
    consume = 0,
    client = {
        image = 'keys.png',
    }
},
['lockpick'] = {
    label = 'Lockpick',
    weight = 100,
    stack = true,
    consume = 0,
    client = {
        image = 'lockpick.png',
    }
},