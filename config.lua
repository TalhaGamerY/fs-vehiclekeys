-- config.lua
Config = {}

-- General Settings
Config.Debug = false
Config.MaxSharedKeys = 2 -- Maximum number of people an owner can share keys with

-- Keybinds
Config.LockKeybind = 'U' -- Default key to lock/unlock

-- Lockpick Settings
Config.LockpickItem = 'lockpick'
Config.LockpickBreakChance = 40 -- Percentage chance for lockpick to break on failure
Config.LockpickAlertPoliceChance = 30 -- Percentage chance to alert police on failure

-- Hotwire Settings
Config.HotwireDuration = 10000 -- Time in ms
Config.HotwireFailChance = 30 -- Percentage chance to fail hotwire
Config.HotwireEngineDamageChance = 20 -- Percentage chance to damage engine on fail
Config.HotwireAlertPoliceChance = 50 -- Percentage chance to alert police
Config.EngineDamageAmount = 150.0 -- Amount of health to remove from engine on damage

-- Engine Failure System
Config.EngineFailureChance = 10 -- Percentage chance every tick (when driving without key)
Config.EngineFailureTickRate = 30000 -- Check every 30 seconds

-- Discord Logging
Config.Webhook = "YOUR_DISCORD_WEBHOOK_HERE"
Config.WebhookName = "FS Vehicle Keys Log"
Config.WebhookAvatar = ""

-- Animations
Config.Animations = {
    LockUnlock = {
        dict = "anim@mp_player_intmenu@key_fob@",
        anim = "fob_click"
    },
    Lockpick = {
        dict = "missheistfbisetup1",
        anim = "hassle_wire"
    },
    Hotwire = {
        dict = "veh@std@ds@base",
        anim = "hotwire"
    },
    SmashWindow = {
        dict = "veh@stealth@door_l",
        anim = "smash_window_sc"
    }
}