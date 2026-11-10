-- fxmanifest.lua
fx_version 'cerulean'
game 'gta5'

author 'FS Labs'
description 'Advanced Vehicle Keys System with ox_inventory integration'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/server.lua'
}

lua54 'yes'