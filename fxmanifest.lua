fx_version 'cerulean'
game 'gta5'
description 'east_hud'

shared_script 'config.lua'

client_scripts {
    'client/main.lua'
}

exports {
    'seatbelt'
}

ui_page 'ui/index.html'
files {
    'ui/index.html',
    'ui/app.js',
    'ui/reset.css',
    'ui/style.css',
}

dependency 'yarn'
