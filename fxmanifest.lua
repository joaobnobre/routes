fx_version 'adamant'
game 'gta5'

author 'bfmjoao at Back-End, jnobre at Front-End'
contact 'Ocelot Development - discord.gg/TwuEPcKXvr'

ui_page 'web/index.html'

shared_scripts {
    'ocelot.lua',
    'framework.lua',
    'config.lua',
}

server_script 'server.lua'

client_script 'client.lua'

files {
    'web/*'
}