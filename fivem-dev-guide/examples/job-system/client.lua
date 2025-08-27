--[[
    EMS Job System - Client Component
    
    This script demonstrates:
    - Client-side job interface
    - Interactive markers and blips
    - Vehicle spawning and management
    - Emergency call handling
    - UI/UX for job activities
    - Player interaction systems
    
    Features:
    - EMS station interactions
    - Duty toggle interface
    - Emergency call notifications
    - Vehicle spawning system
    - Equipment management
    - GPS and waypoint system
--]]

local CONFIG = {
    -- UI Settings
    MARKER_TYPE = 1,
    MARKER_SIZE = vector3(1.5, 1.5, 1.0),
    MARKER_COLOR = { r = 255, g = 255, b = 255, a = 100 },
    INTERACTION_DISTANCE = 2.0,
    
    -- Notification settings
    NOTIFICATION_DURATION = 5000,
    
    -- Vehicle settings
    VEHICLE_SPAWN_DISTANCE = 5.0,
    VEHICLE_DELETE_DISTANCE = 100.0,
    
    -- Emergency call settings
    CALL_BLIP_SPRITE = 280,
    CALL_BLIP_COLOR = 1,
    CALL_BLIP_SCALE = 0.8,
    
    -- Key mappings
    DUTY_KEY = 'E',
    MENU_KEY = 'F6',
    CALL_ACCEPT_KEY = 'Y',
    CALL_DECLINE_KEY = 'N'
}


local playerData = {
    job = nil,
    rank = 1,
    rankName = 'Unemployed',
    onDuty = false,
    totalEarnings = 0,
    callsCompleted = 0
}

local emsStations = {}
local emergencyCalls = {}
local activeCall = nil
local spawnedVehicles = {}
local stationBlips = {}
local callBlips = {}
local isMenuOpen = false
local currentStation = nil


local function log(message)
    print('^3[EMS-Client]^7 ' .. message)
end

local function showNotification(message, type)
    type = type or 'info'
    
    -- Custom notification system
    SetNotificationTextEntry('STRING')
    AddTextComponentString(message)
    DrawNotification(false, false)
    
    -- Also send to chat
    local colors = {
        info = { 255, 255, 255 },
        success = { 0, 255, 0 },
        warning = { 255, 255, 0 },
        error = { 255, 0, 0 }
    }
    
    TriggerEvent('chat:addMessage', {
        color = colors[type] or colors.info,
        multiline = true,
        args = { 'EMS', message }
    })
end

local function drawText3D(coords, text, scale)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = GetDistanceBetweenCoords(px, py, pz, coords.x, coords.y, coords.z, 1)
    
    scale = scale or 0.35
    if onScreen then
        SetTextScale(scale, scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry('STRING')
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
        
        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 75)
    end
end

local function getClosestStation()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local closestStation = nil
    local closestDistance = math.huge
    
    for _, station in pairs(emsStations) do
        local distance = #(playerCoords - station.coords)
        if distance < closestDistance then
            closestDistance = distance
            closestStation = station
        end
    end
    
    return closestStation, closestDistance
end

local function isPlayerEMS()
    return playerData.job == 'ems'
end

local function isPlayerOnDuty()
    return playerData.onDuty
end


local function createStationBlips()
    for _, station in pairs(emsStations) do
        local blip = AddBlipForCoord(station.coords.x, station.coords.y, station.coords.z)
        SetBlipSprite(blip, station.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, station.blip.scale)
        SetBlipColour(blip, station.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(station.name)
        EndTextCommandSetBlipName(blip)
        
        stationBlips[station.id] = blip
    end
end

local function removeStationBlips()
    for _, blip in pairs(stationBlips) do
        RemoveBlip(blip)
    end
    stationBlips = {}
end

local function createCallBlip(call)
    local blip = AddBlipForCoord(call.coords.x, call.coords.y, call.coords.z)
    SetBlipSprite(blip, CONFIG.CALL_BLIP_SPRITE)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, CONFIG.CALL_BLIP_SCALE)
    SetBlipColour(blip, CONFIG.CALL_BLIP_COLOR)
    SetBlipAsShortRange(blip, false)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Emergency Call #' .. call.id)
    EndTextCommandSetBlipName(blip)
    
    callBlips[call.id] = blip
end

local function removeCallBlip(callId)
    if callBlips[callId] then
        RemoveBlip(callBlips[callId])
        callBlips[callId] = nil
    end
end


local function spawnVehicle(vehicleData)
    local model = GetHashKey(vehicleData.model)
    
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end
    
    local vehicle = CreateVehicle(
        model,
        vehicleData.coords.x,
        vehicleData.coords.y,
        vehicleData.coords.z,
        vehicleData.coords.w,
        true,
        false
    )
    
    if DoesEntityExist(vehicle) then
        SetEntityAsMissionEntity(vehicle, true, true)
        SetVehicleOnGroundProperly(vehicle)
        SetVehicleEngineOn(vehicle, false, false, false)
        SetVehicleNumberPlateText(vehicle, 'EMS' .. math.random(100, 999))
        
        -- Add to spawned vehicles list
        table.insert(spawnedVehicles, vehicle)
        
        -- Set vehicle properties for EMS
        SetVehicleLivery(vehicle, 0) -- EMS livery
        SetVehicleExtra(vehicle, 1, false) -- Enable sirens
        
        showNotification('EMS vehicle spawned at ' .. vehicleData.station, 'success')
        log('Spawned EMS vehicle: ' .. vehicleData.model)
        
        return vehicle
    else
        showNotification('Failed to spawn vehicle', 'error')
        return nil
    end
end

local function deleteNearbyVehicles()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local deletedCount = 0
    
    for i = #spawnedVehicles, 1, -1 do
        local vehicle = spawnedVehicles[i]
        if DoesEntityExist(vehicle) then
            local vehicleCoords = GetEntityCoords(vehicle)
            local distance = #(playerCoords - vehicleCoords)
            
            if distance <= CONFIG.VEHICLE_DELETE_DISTANCE then
                DeleteEntity(vehicle)
                table.remove(spawnedVehicles, i)
                deletedCount = deletedCount + 1
            end
        else
            table.remove(spawnedVehicles, i)
        end
    end
    
    if deletedCount > 0 then
        showNotification('Deleted ' .. deletedCount .. ' EMS vehicles', 'info')
    end
end


local function showCallNotification(call)
    -- Create a more prominent notification for emergency calls
    local message = string.format(
        'EMERGENCY CALL #%d\n%s\nPress %s to accept, %s to decline',
        call.id,
        call.description,
        CONFIG.CALL_ACCEPT_KEY,
        CONFIG.CALL_DECLINE_KEY
    )
    
    showNotification(message, 'warning')
    
    -- Play emergency sound
    PlaySoundFrontend(-1, 'TIMER_STOP', 'HUD_MINI_GAME_SOUNDSET', 1)
    
    -- Create blip for call
    createCallBlip(call)
end

local function acceptCall(callId)
    TriggerServerEvent('ems:assignCall', callId)
end

local function completeCall(callId)
    TriggerServerEvent('ems:completeCall', callId)
    activeCall = nil
    removeCallBlip(callId)
end

local function setWaypointToCall(call)
    SetNewWaypoint(call.coords.x, call.coords.y)
    showNotification('Waypoint set to emergency call location', 'info')
end


local function openEMSMenu()
    if not isPlayerEMS() then
        showNotification('You are not employed as EMS!', 'error')
        return
    end
    
    isMenuOpen = true
    
    -- Send menu data to NUI (if using NUI)
    SendNUIMessage({
        type = 'openEMSMenu',
        playerData = playerData,
        station = currentStation,
        emergencyCalls = emergencyCalls
    })
    
    SetNuiFocus(true, true)
end

local function closeEMSMenu()
    isMenuOpen = false
    SendNUIMessage({ type = 'closeEMSMenu' })
    SetNuiFocus(false, false)
end

local function drawEMSMenu()
    -- Simple text-based menu (replace with NUI for better UI)
    if not currentStation then return end
    
    local screenW, screenH = GetScreenResolution()
    
    -- Draw background
    DrawRect(0.5, 0.5, 0.3, 0.4, 0, 0, 0, 200)
    
    -- Draw title
    SetTextFont(4)
    SetTextProportional(1)
    SetTextScale(0.6, 0.6)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry('STRING')
    SetTextCentre(1)
    AddTextComponentString(currentStation.name)
    DrawText(0.5, 0.35)
    
    -- Draw player info
    local yPos = 0.42
    local info = {
        'Rank: ' .. playerData.rankName,
        'Status: ' .. (playerData.onDuty and 'On Duty' or 'Off Duty'),
        'Earnings: $' .. playerData.totalEarnings,
        'Calls: ' .. playerData.callsCompleted
    }
    
    SetTextScale(0.4, 0.4)
    for _, line in pairs(info) do
        SetTextEntry('STRING')
        AddTextComponentString(line)
        DrawText(0.5, yPos)
        yPos = yPos + 0.03
    end
    
    -- Draw options
    yPos = yPos + 0.02
    local options = {
        '[1] Toggle Duty',
        '[2] Request Equipment',
        '[3] Spawn Vehicle',
        '[4] View Active Calls',
        '[ESC] Close Menu'
    }
    
    SetTextColour(255, 255, 0, 255)
    for _, option in pairs(options) do
        SetTextEntry('STRING')
        AddTextComponentString(option)
        DrawText(0.5, yPos)
        yPos = yPos + 0.025
    end
end


CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        -- Check station interactions
        for _, station in pairs(emsStations) do
            local distance = #(playerCoords - station.coords)
            
            if distance <= CONFIG.INTERACTION_DISTANCE then
                sleep = 0
                currentStation = station
                
                -- Draw marker
                DrawMarker(
                    CONFIG.MARKER_TYPE,
                    station.coords.x, station.coords.y, station.coords.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    CONFIG.MARKER_SIZE.x, CONFIG.MARKER_SIZE.y, CONFIG.MARKER_SIZE.z,
                    CONFIG.MARKER_COLOR.r, CONFIG.MARKER_COLOR.g, CONFIG.MARKER_COLOR.b, CONFIG.MARKER_COLOR.a,
                    false, true, 2, false, nil, nil, false
                )
                
                -- Draw interaction text
                if isPlayerEMS() then
                    drawText3D(station.coords, '[E] EMS Station\n[F6] Open Menu', 0.4)
                else
                    drawText3D(station.coords, 'EMS Station\n(EMS Personnel Only)', 0.4)
                end
                
                -- Handle input
                if IsControlJustPressed(0, 38) then -- E key
                    if isPlayerEMS() then
                        TriggerServerEvent('ems:toggleDuty')
                    else
                        showNotification('You are not employed as EMS!', 'error')
                    end
                end
                
                if IsControlJustPressed(0, 167) then -- F6 key
                    if isPlayerEMS() then
                        openEMSMenu()
                    end
                end
                
            elseif currentStation == station then
                currentStation = nil
            end
        end
        
        -- Draw menu if open
        if isMenuOpen and currentStation then
            sleep = 0
            drawEMSMenu()
            
            -- Handle menu input
            if IsControlJustPressed(0, 177) then -- BACKSPACE
                closeEMSMenu()
            elseif IsControlJustPressed(0, 49) then -- 1 key
                TriggerServerEvent('ems:toggleDuty')
            elseif IsControlJustPressed(0, 50) then -- 2 key
                TriggerServerEvent('ems:requestEquipment', currentStation.id)
            elseif IsControlJustPressed(0, 51) then -- 3 key
                TriggerServerEvent('ems:requestVehicle', currentStation.id, 1)
            end
        end
        
        -- Handle emergency call responses
        if activeCall then
            sleep = 0
            
            if IsControlJustPressed(0, 246) then -- Y key
                acceptCall(activeCall.id)
            elseif IsControlJustPressed(0, 249) then -- N key
                activeCall = nil
                showNotification('Emergency call declined', 'info')
            end
        end
        
        Wait(sleep)
    end
end)


-- Server events
RegisterNetEvent('ems:updateJobData')
AddEventHandler('ems:updateJobData', function(data)
    playerData = data
    log('Job data updated: ' .. json.encode(data))
end)

RegisterNetEvent('ems:onDuty')
AddEventHandler('ems:onDuty', function(data)
    emsStations = data.stations
    createStationBlips()
    showNotification('You are now on duty as EMS', 'success')
    log('Player went on duty')
end)

RegisterNetEvent('ems:offDuty')
AddEventHandler('ems:offDuty', function()
    removeStationBlips()
    deleteNearbyVehicles()
    
    -- Clear active calls
    for callId, _ in pairs(callBlips) do
        removeCallBlip(callId)
    end
    emergencyCalls = {}
    activeCall = nil
    
    showNotification('You are now off duty', 'info')
    log('Player went off duty')
end)

RegisterNetEvent('ems:notify')
AddEventHandler('ems:notify', function(message, type)
    showNotification(message, type)
end)

-- Emergency call events
RegisterNetEvent('ems:newEmergencyCall')
AddEventHandler('ems:newEmergencyCall', function(call)
    emergencyCalls[call.id] = call
    
    if isPlayerOnDuty() then
        showCallNotification(call)
        activeCall = call
    end
end)

RegisterNetEvent('ems:callAssigned')
AddEventHandler('ems:callAssigned', function(call)
    activeCall = call
    setWaypointToCall(call)
    showNotification('You have been assigned to emergency call #' .. call.id, 'success')
end)

RegisterNetEvent('ems:callTaken')
AddEventHandler('ems:callTaken', function(callId)
    if emergencyCalls[callId] then
        emergencyCalls[callId] = nil
        removeCallBlip(callId)
        
        if activeCall and activeCall.id == callId then
            activeCall = nil
        end
    end
end)

RegisterNetEvent('ems:callExpired')
AddEventHandler('ems:callExpired', function(callId)
    if emergencyCalls[callId] then
        emergencyCalls[callId] = nil
        removeCallBlip(callId)
        
        if activeCall and activeCall.id == callId then
            activeCall = nil
            showNotification('Emergency call #' .. callId .. ' has expired', 'warning')
        end
    end
end)

-- Vehicle spawning
RegisterNetEvent('ems:spawnVehicle')
AddEventHandler('ems:spawnVehicle', function(vehicleData)
    spawnVehicle(vehicleData)
end)


RegisterCommand('emsmenu', function()
    if currentStation and isPlayerEMS() then
        if isMenuOpen then
            closeEMSMenu()
        else
            openEMSMenu()
        end
    else
        showNotification('You must be at an EMS station to open the menu', 'error')
    end
end, false)

RegisterCommand('emsduty', function()
    TriggerServerEvent('ems:toggleDuty')
end, false)

RegisterCommand('emscall', function(args)
    if #args < 1 then
        showNotification('Usage: /emscall [description]', 'error')
        return
    end
    
    local description = table.concat(args, ' ')
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    TriggerServerEvent('ems:createCall', playerCoords, description)
end, false)

RegisterCommand('completecall', function()
    if activeCall then
        completeCall(activeCall.id)
        showNotification('Emergency call completed', 'success')
    else
        showNotification('You are not assigned to any call', 'error')
    end
end, false)

RegisterCommand('deletevehicles', function()
    deleteNearbyVehicles()
end, false)


RegisterKeyMapping('emsduty', 'Toggle EMS Duty', 'keyboard', 'F5')
RegisterKeyMapping('emsmenu', 'Open EMS Menu', 'keyboard', 'F6')
RegisterKeyMapping('completecall', 'Complete Emergency Call', 'keyboard', 'F8')

CreateThread(function()
    -- Request job data on resource start
    TriggerServerEvent('ems:requestJobData')
    
    log('EMS Job System client component loaded successfully')
end)

-- Resource cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- Clean up blips
        removeStationBlips()
        for callId, _ in pairs(callBlips) do
            removeCallBlip(callId)
        end
        
        -- Clean up vehicles
        for _, vehicle in pairs(spawnedVehicles) do
            if DoesEntityExist(vehicle) then
                DeleteEntity(vehicle)
            end
        end
        
        log('EMS Job System client cleaned up')
    end
end)

--[[
    Installation Instructions:
    
    1. Create folder: [local]/ems-job-system
    2. Save server.lua and client.lua in this folder
    3. Create fxmanifest.lua:
    
    fx_version 'cerulean'
    game 'gta5'
    
    author 'Your Name'
    description 'EMS Job System with Emergency Calls'
    version '1.0.0'
    
    shared_scripts {
        '@es_extended/imports.lua' -- If using ESX
    }
    
    server_scripts {
        'server.lua'
    }
    
    client_scripts {
        'client.lua'
    }
    
    4. Add 'ensure ems-job-system' to server.cfg
    5. Restart server or use 'refresh' and 'start ems-job-system'
    
    Usage:
    - Go to EMS stations (Pillbox Medical, Sandy Shores Medical)
    - Press E to toggle duty status
    - Press F6 to open EMS menu
    - Use /emscall [description] to create emergency calls
    - Press F8 to complete assigned calls
    - Use /emsinfo to view your EMS statistics
    
    Admin Commands:
    - setjob [player_id] ems [rank] - Assign EMS job to player
    
    Features:
    - Complete job management system
    - Emergency call dispatch
    - Vehicle spawning and management
    - Equipment distribution
    - Salary and reward system
    - Rank progression
    - Interactive stations
    - GPS waypoint system
--]]