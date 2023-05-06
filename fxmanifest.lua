shared_script '@AC/waveshield.lua' --this line was automatically written by WaveShield

fx_version 'cerulean'
games { 'gta5' }

author 'rambo'

client_scripts {"client/*.lua"}
server_scripts {"server/*.lua"}

shared_scripts {'shared/*.lua'}

escrow_ignore {
    'shared/config.lua',
    'shared/routes.lua',
}

lua54 'yes'