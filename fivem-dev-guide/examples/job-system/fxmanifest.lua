fx_version 'cerulean'
game 'gta5'

author 'FiveM Dev Guide'
description 'EMS Job System - Complete job management with emergency calls, vehicle spawning, and player progression'
version '1.0.0'

-- Dependencies (uncomment if using frameworks)
-- dependency 'es_extended'  -- For ESX framework
-- dependency 'qb-core'     -- For QB-Core framework

-- Shared scripts (loaded on both client and server)
shared_scripts {
    -- '@es_extended/imports.lua',  -- Uncomment if using ESX
    -- '@qb-core/imports.lua',      -- Uncomment if using QB-Core
}

-- Server-side scripts
server_scripts {
    'server.lua'
}

-- Client-side scripts
client_scripts {
    'client.lua'
}

-- Optional: NUI files (if you want to add a web-based UI)
-- ui_page 'html/index.html'
-- files {
--     'html/index.html',
--     'html/style.css',
--     'html/script.js'
-- }

-- Optional: Data files
-- files {
--     'data/vehicles.json',
--     'data/stations.json'
-- }

-- Lua 5.4 compatibility
lua54 'yes'

-- Server exports (functions other resources can call)
server_exports {
    'setPlayerJob',
    'getPlayerData',
    'createEmergencyCall',
    'getOnDutyEMS',
    'getActiveCalls'
}

-- Client exports (functions other resources can call)
client_exports {
    -- Add client exports here if needed
}

-- Optional: Provide configuration
provides {
    'ems-job',
    'emergency-calls',
    'job-system'
}

-- Optional: Resource metadata
metadata {
    ['framework'] = 'standalone', -- or 'esx', 'qb-core'
    ['category'] = 'jobs',
    ['tags'] = { 'ems', 'job', 'emergency', 'medical' }
}