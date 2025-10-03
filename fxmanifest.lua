-- fxmanifest.lua
fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

description 'Key Binding System for RSG-Core'
version '1.0.1'
author 'DIGITALEN'

dependencies {
    'rsg-core',
    'rsg-menubase',
    'rsg-input',
    'oxmysql'
}

shared_scripts {
    '@rsg-core/shared/locale.lua',
    'config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    'server/server.lua'
}

lua54 'yes'