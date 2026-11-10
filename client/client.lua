-- client/client.lua
local ESX = exports['es_extended']:getSharedObject()
local isInVehicle = false
local currentVehicle = nil
local hasTemporaryAccess = false

-- Utility: Load Animation Dictionary
local function LoadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(10)
    end
end

-- BLOCK DEFAULT WINDOW SMASHING & ANTI-WIRE (Engine Start)
CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        
        -- 1. Anti-Smash: Blocks default elbow smash when entering locked car
        if not IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsTryingToEnter(ped)
            if DoesEntityExist(vehicle) then
                sleep = 0
                local lockStatus = GetVehicleDoorLockStatus(vehicle)
                if lockStatus > 1 then
                    ClearPedTasks(ped)
                    lib.notify({title = 'Locked', description = 'This vehicle is locked. Use a lockpick.', type = 'error'})
                end
            end
        end

        -- 2. Anti-Wire: Blocks default engine starting/shuffling wires
        if isInVehicle and currentVehicle then
            local plate = string.gsub(GetVehicleNumberPlateText(currentVehicle), "^%s*(.-)%s*$", "%1")
            if not HasKeyForVehicle(plate) and not hasTemporaryAccess then
                sleep = 0
                -- Forces engine off every frame if no key/hotwire success
                SetVehicleEngineOn(currentVehicle, false, true, true)
                SetVehicleJetEngineOn(currentVehicle, false)
                
                -- Disable the default "hotwire" shuffling animation if it starts
                if GetIsTaskActive(ped, 150) or GetIsTaskActive(ped, 151) then 
                    ClearPedTasks(ped)
                end
            end
        end
        Wait(sleep)
    end
end)

-- Utility: Check if player has key for specific plate
function HasKeyForVehicle(plate)
    local items = exports.ox_inventory:Search('slots', 'vehicle_key')
    for _, item in pairs(items) do
        if item.metadata and item.metadata.plate == plate then
            return true
        end
    end
    return false
end

-- Lock/Unlock Logic (Bind: U)
RegisterCommand('togglevehlock', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicle = lib.getClosestVehicle(coords, 5.0, false)

    if vehicle then
        local plate = string.gsub(GetVehicleNumberPlateText(vehicle), "^%s*(.-)%s*$", "%1")
        if HasKeyForVehicle(plate) then
            local lockStatus = GetVehicleDoorLockStatus(vehicle)
            
            LoadAnimDict(Config.Animations.LockUnlock.dict)
            TaskPlayAnim(ped, Config.Animations.LockUnlock.dict, Config.Animations.LockUnlock.anim, 8.0, 8.0, -1, 48, 1, false, false, false)
            
            if lockStatus == 1 or lockStatus == 0 then
                SetVehicleDoorsLocked(vehicle, 2)
                SetVehicleDoorsLockedForAllPlayers(vehicle, true)
                lib.notify({title = 'Vehicle Locked', type = 'success', icon = 'lock'})
                TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 5, 'lock', 0.5)
            else
                SetVehicleDoorsLocked(vehicle, 1)
                SetVehicleDoorsLockedForAllPlayers(vehicle, false)
                lib.notify({title = 'Vehicle Unlocked', type = 'success', icon = 'lock-open'})
                TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 5, 'unlock', 0.5)
            end
            
            SetVehicleLights(vehicle, 2)
            Wait(200) SetVehicleLights(vehicle, 0)
            Wait(200) SetVehicleLights(vehicle, 2)
            Wait(200) SetVehicleLights(vehicle, 0)
        else
            lib.notify({title = 'No Key', description = 'You do not have the keys.', type = 'error'})
        end
    end
end)
RegisterKeyMapping('togglevehlock', 'Lock/Unlock Vehicle', 'keyboard', Config.LockKeybind)

-- Enter Vehicle Logic
lib.onCache('vehicle', function(vehicle)
    if vehicle then
        isInVehicle = true
        currentVehicle = vehicle
        local plate = string.gsub(GetVehicleNumberPlateText(vehicle), "^%s*(.-)%s*$", "%1")
        
        if GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() then
            if not HasKeyForVehicle(plate) and not hasTemporaryAccess then
                SetVehicleEngineOn(vehicle, false, true, true)
                lib.notify({title = 'Engine Off', description = 'You need to hotwire this vehicle.', type = 'error'})
                TriggerEvent('fs_vehiclekeys:client:startHotwirePrompt', vehicle)
            else
                SetVehicleEngineOn(vehicle, true, false, true)
            end
        end
    else
        isInVehicle = false
        currentVehicle = nil
        hasTemporaryAccess = false
    end
end)

-- Hotwire Prompt
RegisterNetEvent('fs_vehiclekeys:client:startHotwirePrompt')
AddEventHandler('fs_vehiclekeys:client:startHotwirePrompt', function(vehicle)
    CreateThread(function()
        while isInVehicle and not hasTemporaryAccess and currentVehicle == vehicle do
            Wait(0)
            lib.showTextUI('[H] Hotwire Vehicle')
            if IsControlJustPressed(0, 74) then
                lib.hideTextUI()
                HotwireVehicle(vehicle)
                break
            end
        end
        lib.hideTextUI()
    end)
end)

-- HOTWIRE FUNCTION (SLOWED DOWN)
function HotwireVehicle(vehicle)
    local ped = PlayerPedId()
    local plate = string.gsub(GetVehicleNumberPlateText(vehicle), "^%s*(.-)%s*$", "%1")
    
    if IsVehicleWindowIntact(vehicle, 0) then
        LoadAnimDict(Config.Animations.SmashWindow.dict)
        TaskPlayAnim(ped, Config.Animations.SmashWindow.dict, Config.Animations.SmashWindow.anim, 8.0, 8.0, -1, 50, 0, false, false, false)
        Wait(1000)
        PlaySoundFromEntity(-1, "Glass_Smash", vehicle, "Tiny_Collision_Sounds", 0, 0)
        SmashVehicleWindow(vehicle, 0)
    end

    LoadAnimDict(Config.Animations.Hotwire.dict)
    TaskPlayAnim(ped, Config.Animations.Hotwire.dict, Config.Animations.Hotwire.anim, 8.0, 8.0, -1, 1, 0, false, false, false)

    local success = lib.skillCheck({
        'easy', 
        'easy', 
        {areaSize = 70, speedMultiplier = 0.7}, 
        {areaSize = 60, speedMultiplier = 0.9}
    }, {'w', 'a', 's', 'd'})
    
    ClearPedTasks(ped)

    if success then
        hasTemporaryAccess = true
        SetVehicleEngineOn(vehicle, true, false, true)
        lib.notify({title = 'Success', description = 'You hotwired the vehicle.', type = 'success'})
        TriggerServerEvent('fs_vehiclekeys:server:log', "Hotwire Success", "Plate: " .. plate)
    else
        lib.notify({title = 'Failed', description = 'Hotwire failed.', type = 'error'})
    end
end

-- LOCKPICK SYSTEM (SLOWED DOWN)
RegisterNetEvent('fs_vehiclekeys:client:useLockpick')
AddEventHandler('fs_vehiclekeys:client:useLockpick', function()
    local ped = PlayerPedId()
    local vehicle = lib.getClosestVehicle(GetEntityCoords(ped), 3.0, false)

    if not vehicle then
        lib.notify({title = 'Error', description = 'No vehicle nearby.', type = 'error'})
        return
    end

    TaskTurnPedToFaceEntity(ped, vehicle, 1000)
    Wait(1000)
    LoadAnimDict(Config.Animations.Lockpick.dict)
    TaskPlayAnim(ped, Config.Animations.Lockpick.dict, Config.Animations.Lockpick.anim, 8.0, 8.0, -1, 1, 0, false, false, false)

    local success = lib.skillCheck({'easy', 'easy', 'medium'}, {'w', 'a', 's', 'd'})
    
    ClearPedTasks(ped)

    if success then
        SetVehicleDoorsLocked(vehicle, 1)
        SetVehicleDoorsLockedForAllPlayers(vehicle, false)
        lib.notify({title = 'Success', description = 'Vehicle unlocked.', type = 'success'})
        PlaySoundFromEntity(-1, "Key_Unlock_Critical", vehicle, "HUD_FRONTEND_DEFAULT_SOUNDSET", 1, 0)
    else
        lib.notify({title = 'Failed', description = 'You failed to pick the lock.', type = 'error'})
        TriggerServerEvent('fs_vehiclekeys:server:lockpickFailed')
    end
end)