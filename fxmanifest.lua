fx_version 'cerulean'
author 'atiysu'
game 'gta5'
description 'aty_icehud'

shared_script 'config.lua'

client_scripts{
    'client/utils.lua',
    'client/client.lua',
}

server_scripts{
    'server/*.lua',
}

ui_page{
    'ui/index.html'
} 

files {
    'ui/index.html',
    'ui/css/*.*',
    'ui/scripts/*.*',
    'ui/img/*.*',
    'ui/sounds/*.*',
}