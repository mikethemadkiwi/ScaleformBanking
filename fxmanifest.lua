fx_version 'bodacious'
games { 'gta5' }

description 'GTA V Native ATM Scaleform for FiveM Reworked By Madkiwi'

client_scripts {
	'mkatmClient.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'mkatmServer.lua'
}