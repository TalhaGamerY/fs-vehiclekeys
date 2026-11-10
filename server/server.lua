-- server/server.lua
local ESX = exports['es_extended']:getSharedObject()
local SharedKeysData = {} -- Tracks: SharedKeysData[plate] = {id1, id2}

-- Discord Webhook Logger
local function SendDiscordLog(title, message, color)
    if not Config.Webhook or Config.Webhook == "YOUR_DISCORD_WEBHOOK_HERE" then return end

    local embed = {
        {
            ["color"] = color or 3447003,
            ["title"] = title,
            ["description"] = message,
            ["footer"] = {
                ["text"] = "FS Vehicle Keys | Logs"
            }
        }
    }

    PerformHttpRequest(Config.Webhook, function(err, text, headers) end, 'POST', json.encode({username = Config.WebhookName, embeds = embed, avatar_url = Config.WebhookAvatar}), { ['Content-Type'] = 'application/json' })
end

RegisterNetEvent('fs_vehiclekeys:server:log')
AddEventHandler('fs_vehiclekeys:server:log', function(title, msg)
    local src = source
    local identifier = ESX.GetPlayerFromId(src).identifier
    SendDiscordLog(title, "**Player:** " .. GetPlayerName(src) .. " (" .. identifier .. ")\n**Action:** " .. msg)
end)

-- FIXED: Using standard ESX usable item format which ox_inventory supports natively
ESX.RegisterUsableItem(Config.LockpickItem, function(source)
    TriggerClientEvent('fs_vehiclekeys:client:useLockpick', source)
end)

RegisterNetEvent('fs_vehiclekeys:server:lockpickFailed')
AddEventHandler('fs_vehiclekeys:server:lockpickFailed', function()
    local src = source
    if math.random(1, 100) <= Config.LockpickBreakChance then
        exports.ox_inventory:RemoveItem(src, Config.LockpickItem, 1)
        TriggerClientEvent('ox_lib:notify', src, {title = 'Broken', description = 'Your lockpick broke.', type = 'error'})
    end
end)

-- Admin Commands
ESX.RegisterCommand('adminkey', 'admin', function(xPlayer, args, showError)
    local action = args.action
    local plate = args.plate
    local targetId = args.target
    
    if not action or not plate or not targetId then
        showError('Usage: /adminkey [give/remove] [plate] [playerId]')
        return
    end
    
    local targetPlayer = ESX.GetPlayerFromId(tonumber(targetId))
    if not targetPlayer then
        showError('Target player not found.')
        return
    end

    if action == 'give' then
        local metadata = { plate = string.upper(plate), owner = targetPlayer.identifier, description = "Key for plate: " .. string.upper(plate) }
        exports.ox_inventory:AddItem(targetPlayer.source, 'vehicle_key', 1, metadata)
        SendDiscordLog("Admin Key Given", string.format("Admin %s gave key for plate %s to %s", xPlayer.getName(), plate, targetPlayer.getName()), 16711680)
        TriggerClientEvent('ox_lib:notify', xPlayer.source, {title = 'Success', description = 'Key given.', type = 'success'})
    elseif action == 'remove' then
        local items = exports.ox_inventory:Search(targetPlayer.source, 'slots', 'vehicle_key')
        for _, item in pairs(items) do
            if item.metadata and item.metadata.plate == string.upper(plate) then
                exports.ox_inventory:RemoveItem(targetPlayer.source, 'vehicle_key', 1, nil, item.slot)
            end
        end
        SendDiscordLog("Admin Key Removed", string.format("Admin %s removed key for plate %s from %s", xPlayer.getName(), plate, targetPlayer.getName()), 16711680)
        TriggerClientEvent('ox_lib:notify', xPlayer.source, {title = 'Success', description = 'Key removed.', type = 'success'})
    end
end, true, {help = 'Manage vehicle keys', validate = false, arguments = {
    {name = 'action', help = 'give or remove', type = 'string'},
    {name = 'plate', help = 'Vehicle Plate', type = 'string'},
    {name = 'target', help = 'Player ID', type = 'number'}
}})

-- Player Commands: Give Key
ESX.RegisterCommand('givekey', 'user', function(xPlayer, args, showError)
    local targetId = args.target
    if not targetId then return showError('Usage: /givekey [playerId]') end
    
    local targetPlayer = ESX.GetPlayerFromId(tonumber(targetId))
    if not targetPlayer then return showError('Target player not found.') end
    if targetPlayer.source == xPlayer.source then return showError('Cannot give key to yourself.') end

    local ped = GetPlayerPed(xPlayer.source)
    local coords = GetEntityCoords(ped)
    local targetPed = GetPlayerPed(targetPlayer.source)
    local targetCoords = GetEntityCoords(targetPed)
    
    if #(coords - targetCoords) > 5.0 then return showError('Player is too far.') end

    local hasKey = false
    local keyMetadata = nil
    local items = exports.ox_inventory:Search(xPlayer.source, 'slots', 'vehicle_key')
    for _, item in pairs(items) do
        hasKey = true
        keyMetadata = item.metadata
        break
    end

    if not hasKey or not keyMetadata then return showError('You do not have a vehicle key in hand.') end
    
    local plate = keyMetadata.plate
    SharedKeysData[plate] = SharedKeysData[plate] or {}

    if #SharedKeysData[plate] >= Config.MaxSharedKeys then
        return showError('You have reached the maximum number of shared keys (' .. Config.MaxSharedKeys .. ').')
    end

    table.insert(SharedKeysData[plate], targetPlayer.identifier)
    exports.ox_inventory:AddItem(targetPlayer.source, 'vehicle_key', 1, keyMetadata)
    
    SendDiscordLog("Key Shared", string.format("%s shared key for plate %s with %s", xPlayer.getName(), plate, targetPlayer.getName()), 3447003)
    TriggerClientEvent('ox_lib:notify', xPlayer.source, {title = 'Key Given', description = 'You gave a copy of your keys.', type = 'success'})
    TriggerClientEvent('ox_lib:notify', targetPlayer.source, {title = 'Key Received', description = 'You received a vehicle key.', type = 'success'})
end, false, {help = 'Give a copy of your vehicle key to someone', validate = false, arguments = {
    {name = 'target', help = 'Player ID', type = 'number'}
}})

-- Player Commands: Remove Key
ESX.RegisterCommand('removekey', 'user', function(xPlayer, args, showError)
    local targetId = args.target
    if not targetId then return showError('Usage: /removekey [playerId]') end
    
    local targetPlayer = ESX.GetPlayerFromId(tonumber(targetId))
    if not targetPlayer then return showError('Target player not found.') end

    local keyMetadata = nil
    local items = exports.ox_inventory:Search(xPlayer.source, 'slots', 'vehicle_key')
    for _, item in pairs(items) do
        keyMetadata = item.metadata
        break
    end
    if not keyMetadata then return showError('You must hold your key to revoke access.') end

    local plate = keyMetadata.plate
    if SharedKeysData[plate] then
        for i, identifier in ipairs(SharedKeysData[plate]) do
            if identifier == targetPlayer.identifier then
                table.remove(SharedKeysData[plate], i)
                break
            end
        end
    end

    local targetItems = exports.ox_inventory:Search(targetPlayer.source, 'slots', 'vehicle_key')
    for _, item in pairs(targetItems) do
        if item.metadata and item.metadata.plate == plate then
            exports.ox_inventory:RemoveItem(targetPlayer.source, 'vehicle_key', 1, nil, item.slot)
        end
    end

    SendDiscordLog("Key Revoked", string.format("%s revoked key for plate %s from %s", xPlayer.getName(), plate, targetPlayer.getName()), 15158332)
    TriggerClientEvent('ox_lib:notify', xPlayer.source, {title = 'Key Revoked', description = 'You removed their key.', type = 'success'})
end, false, {help = 'Remove a shared key from someone', validate = false, arguments = {
    {name = 'target', help = 'Player ID', type = 'number'}
}})

-- Transfer Vehicle Keys (Sell Car)
ESX.RegisterCommand('transfercar', 'user', function(xPlayer, args, showError)
    local targetId = args.target
    if not targetId then return showError('Usage: /transfercar [playerId]') end
    
    local targetPlayer = ESX.GetPlayerFromId(tonumber(targetId))
    if not targetPlayer then return showError('Target player not found.') end

    local keyMetadata = nil
    local items = exports.ox_inventory:Search(xPlayer.source, 'slots', 'vehicle_key')
    for _, item in pairs(items) do
        keyMetadata = item.metadata
        break
    end

    if not keyMetadata then return showError('You must hold the key to transfer it.') end
    local plate = keyMetadata.plate

    local players = ESX.GetExtendedPlayers()
    for _, player in pairs(players) do
        local pItems = exports.ox_inventory:Search(player.source, 'slots', 'vehicle_key')
        for _, pItem in pairs(pItems) do
            if pItem.metadata and pItem.metadata.plate == plate then
                exports.ox_inventory:RemoveItem(player.source, 'vehicle_key', 1, nil, pItem.slot)
            end
        end
    end

    SharedKeysData[plate] = {}
    
    local newMetadata = { plate = plate, owner = targetPlayer.identifier, description = "Key for plate: " .. plate }
    exports.ox_inventory:AddItem(targetPlayer.source, 'vehicle_key', 1, newMetadata)

    SendDiscordLog("Vehicle Transferred", string.format("%s transferred vehicle plate %s to %s. Old keys purged.", xPlayer.getName(), plate, targetPlayer.getName()), 3066993)
    TriggerClientEvent('ox_lib:notify', xPlayer.source, {title = 'Transferred', description = 'Vehicle keys transferred to new owner.', type = 'success'})
    TriggerClientEvent('ox_lib:notify', targetPlayer.source, {title = 'Received', description = 'You received keys for your new vehicle.', type = 'success'})

end, false, {help = 'Transfer keys to a new owner (Purges old keys)', validate = false, arguments = {
    {name = 'target', help = 'Player ID', type = 'number'}
}})