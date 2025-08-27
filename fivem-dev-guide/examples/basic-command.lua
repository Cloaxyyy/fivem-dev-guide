--[[
    Basic Command Example - Vehicle Spawner
    
    This script demonstrates:
    - Creating server and client commands
    - Parameter validation
    - Server-client communication
    - Basic vehicle spawning
    - Error handling
    
    Commands:
    /spawncar [model] - Spawn a vehicle
    /deletecar - Delete current vehicle
    /fixcar - Repair current vehicle
--]]

if IsDuplicityVersion() then
    
    -- Configuration
    local Config = {
        AllowedVehicles = {
            'adder', 'zentorno', 'osiris', 'vacca', 'bullet',
            'cheetah', 'entityxf', 'infernus', 'reaper', 'turismor',
            'police', 'police2', 'police3', 'ambulance', 'firetruk'
        },
        MaxVehiclesPerPlayer = 3,
        RequirePermission = false,
        AllowedGroups = {'admin', 'moderator'}
    }
    
    -- Player vehicle tracking
    local playerVehicles = {}
    
    -- Utility functions
    local function hasPermission(source)
        if not Config.RequirePermission then
            return true
        end
        
        -- Add your permission system check here
        -- Example: return IsPlayerAceAllowed(source, 'command.spawncar')
        return true
    end
    
    local function isValidVehicle(model)
        for _, allowedModel in ipairs(Config.AllowedVehicles) do
            if string.lower(model) == string.lower(allowedModel) then
                return true
            end
        end
        return false
    end
    
    local function getPlayerVehicleCount(source)
        if not playerVehicles[source] then
            playerVehicles[source] = {}
        end
        return #playerVehicles[source]
    end
    
    local function addPlayerVehicle(source, vehicle)
        if not playerVehicles[source] then
            playerVehicles[source] = {}
        end
        table.insert(playerVehicles[source], vehicle)
    end
    
    local function removePlayerVehicle(source, vehicle)
        if not playerVehicles[source] then
            return
        end
        
        for i, v in ipairs(playerVehicles[source]) do
            if v == vehicle then
                table.remove(playerVehicles[source], i)
                break
            end
        end
    end
    
    -- Commands
    RegisterCommand('spawncar', function(source, args, rawCommand)
        local playerName = GetPlayerName(source)
        
        -- Check permissions
        if not hasPermission(source) then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {'System', 'You do not have permission to use this command.'}
            })
            return
        end
        
        -- Check if model was provided
        if not args[1] then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 255, 0},
                multiline = true,
                args = {'Usage', '/spawncar [model] - Available: ' .. table.concat(Config.AllowedVehicles, ', ')}
            })
            return
        end
        
        local model = string.lower(args[1])
        
        -- Validate vehicle model
        if not isValidVehicle(model) then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {'Error', 'Invalid vehicle model. Use /spawncar without arguments to see available vehicles.'}
            })
            return
        end
        
        -- Check vehicle limit
        if getPlayerVehicleCount(source) >= Config.MaxVehiclesPerPlayer then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {'Error', 'You have reached the maximum number of vehicles (' .. Config.MaxVehiclesPerPlayer .. '). Delete some vehicles first.'}
            })
            return
        end
        
        -- Log the command
        print(string.format('^3[Vehicle Spawner] ^7%s spawned vehicle: %s', playerName, model))
        
        -- Trigger client to spawn vehicle
        TriggerClientEvent('spawncar:spawn', source, model)
        
    end, false)
    
    RegisterCommand('deletecar', function(source, args, rawCommand)
        if not hasPermission(source) then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {'System', 'You do not have permission to use this command.'}
            })
            return
        end
        
        TriggerClientEvent('spawncar:delete', source)
    end, false)
    
    RegisterCommand('fixcar', function(source, args, rawCommand)
        if not hasPermission(source) then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {'System', 'You do not have permission to use this command.'}
            })
            return
        end
        
        TriggerClientEvent('spawncar:fix', source)
    end, false)
    
    -- Server events
    RegisterServerEvent('spawncar:vehicleSpawned')
    AddEventHandler('spawncar:vehicleSpawned', function(vehicle)
        local source = source
        addPlayerVehicle(source, vehicle)
    end)
    
    RegisterServerEvent('spawncar:vehicleDeleted')
    AddEventHandler('spawncar:vehicleDeleted', function(vehicle)
        local source = source
        removePlayerVehicle(source, vehicle)
    end)
    
    -- Cleanup on player disconnect
    AddEventHandler('playerDropped', function(reason)
        local source = source
        if playerVehicles[source] then
            playerVehicles[source] = nil
        end
    end)
    
    -- Resource start message
    AddEventHandler('onResourceStart', function(resourceName)
        if GetCurrentResourceName() == resourceName then
            print('^2[Vehicle Spawner] ^7Resource started successfully!')
            print('^2[Vehicle Spawner] ^7Available commands: /spawncar, /deletecar, /fixcar')
        end
    end)

else
    
-- ============================================================================
-- CLIENT SIDE
-- ============================================================================
    
    -- Configuration
    local spawnDistance = 5.0  -- Distance in front of player to spawn vehicle
    local lastSpawnedVehicle = nil
    
    -- Utility functions
    local function showNotification(message, type)
        local color = {255, 255, 255}  -- White default
        
        if type == 'success' then
            color = {0, 255, 0}  -- Green
        elseif type == 'error' then
            color = {255, 0, 0}  -- Red
        elseif type == 'warning' then
            color = {255, 255, 0}  -- Yellow
        end
        
        TriggerEvent('chat:addMessage', {
            color = color,
            multiline = true,
            args = {'Vehicle Spawner', message}
        })
    end
    
    local function getSpawnPosition()
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local playerHeading = GetEntityHeading(playerPed)
        
        -- Calculate position in front of player
        local spawnCoords = {
            x = playerCoords.x + math.cos(math.rad(playerHeading)) * spawnDistance,
            y = playerCoords.y + math.sin(math.rad(playerHeading)) * spawnDistance,
            z = playerCoords.z
        }
        
        -- Get ground Z coordinate
        local groundFound, groundZ = GetGroundZFor_3dCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z + 10.0, false)
        if groundFound then
            spawnCoords.z = groundZ
        end
        
        return spawnCoords, playerHeading
    end
    
    local function spawnVehicle(model)
        local modelHash = GetHashKey(model)
        
        -- Check if model is valid
        if not IsModelInCdimage(modelHash) or not IsModelAVehicle(modelHash) then
            showNotification('Invalid vehicle model: ' .. model, 'error')
            return
        end
        
        -- Request model
        RequestModel(modelHash)
        
        local timeout = 0
        while not HasModelLoaded(modelHash) and timeout < 10000 do
            Citizen.Wait(10)
            timeout = timeout + 10
        end
        
        if not HasModelLoaded(modelHash) then
            showNotification('Failed to load vehicle model: ' .. model, 'error')
            return
        end
        
        -- Get spawn position
        local spawnCoords, heading = getSpawnPosition()
        
        -- Create vehicle
        local vehicle = CreateVehicle(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, heading, true, false)
        
        if DoesEntityExist(vehicle) then
            -- Set vehicle properties
            SetVehicleOnGroundProperly(vehicle)
            SetEntityAsMissionEntity(vehicle, true, true)
            SetVehicleEngineOn(vehicle, true, true, false)
            SetVehicleNumberPlateText(vehicle, 'SPAWNED')
            
            -- Put player in vehicle
            local playerPed = PlayerPedId()
            TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
            
            -- Store reference
            lastSpawnedVehicle = vehicle
            
            -- Notify server
            TriggerServerEvent('spawncar:vehicleSpawned', vehicle)
            
            showNotification('Vehicle spawned: ' .. model, 'success')
        else
            showNotification('Failed to spawn vehicle: ' .. model, 'error')
        end
        
        -- Clean up model
        SetModelAsNoLongerNeeded(modelHash)
    end
    
    local function deleteCurrentVehicle()
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        
        if vehicle == 0 then
            -- Check if player is near last spawned vehicle
            if lastSpawnedVehicle and DoesEntityExist(lastSpawnedVehicle) then
                local playerCoords = GetEntityCoords(playerPed)
                local vehicleCoords = GetEntityCoords(lastSpawnedVehicle)
                local distance = #(playerCoords - vehicleCoords)
                
                if distance <= 10.0 then
                    vehicle = lastSpawnedVehicle
                end
            end
        end
        
        if vehicle ~= 0 and DoesEntityExist(vehicle) then
            -- Check if it's a spawned vehicle (has our plate)
            local plate = GetVehicleNumberPlateText(vehicle)
            if string.find(plate, 'SPAWNED') then
                DeleteEntity(vehicle)
                
                if vehicle == lastSpawnedVehicle then
                    lastSpawnedVehicle = nil
                end
                
                TriggerServerEvent('spawncar:vehicleDeleted', vehicle)
                showNotification('Vehicle deleted successfully', 'success')
            else
                showNotification('You can only delete spawned vehicles', 'warning')
            end
        else
            showNotification('No vehicle found to delete', 'warning')
        end
    end
    
    local function fixCurrentVehicle()
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        
        if vehicle == 0 then
            showNotification('You must be in a vehicle to repair it', 'warning')
            return
        end
        
        if DoesEntityExist(vehicle) then
            -- Repair vehicle
            SetVehicleFixed(vehicle)
            SetVehicleDeformationFixed(vehicle)
            SetVehicleUndriveable(vehicle, false)
            SetVehicleEngineOn(vehicle, true, true, false)
            
            -- Refill fuel (if you have a fuel system)
            -- SetVehicleFuelLevel(vehicle, 100.0)
            
            showNotification('Vehicle repaired successfully', 'success')
        end
    end
    
    -- Client events
    RegisterNetEvent('spawncar:spawn')
    AddEventHandler('spawncar:spawn', function(model)
        spawnVehicle(model)
    end)
    
    RegisterNetEvent('spawncar:delete')
    AddEventHandler('spawncar:delete', function()
        deleteCurrentVehicle()
    end)
    
    RegisterNetEvent('spawncar:fix')
    AddEventHandler('spawncar:fix', function()
        fixCurrentVehicle()
    end)
    
    -- Key mappings (optional)
    RegisterKeyMapping('deletecar', 'Delete Current Vehicle', 'keyboard', 'DELETE')
    RegisterKeyMapping('fixcar', 'Fix Current Vehicle', 'keyboard', 'F6')
    
    -- Resource start message
    AddEventHandler('onResourceStart', function(resourceName)
        if GetCurrentResourceName() == resourceName then
            showNotification('Vehicle Spawner loaded! Use /spawncar [model] to spawn a vehicle', 'success')
        end
    end)
    
end

--[[
    Installation Instructions:
    
    1. Create a new folder in your resources directory: [local]/vehicle-spawner
    2. Save this file as: vehicle-spawner/basic-command.lua
    3. Create fxmanifest.lua with:
    
    fx_version 'cerulean'
    game 'gta5'
    
    author 'Your Name'
    description 'Basic Vehicle Spawner Commands'
    version '1.0.0'
    
    server_scripts {
        'basic-command.lua'
    }
    
    client_scripts {
        'basic-command.lua'
    }
    
    4. Add 'ensure vehicle-spawner' to your server.cfg
    5. Restart your server or use 'refresh' and 'start vehicle-spawner'
    
    Usage:
    - /spawncar adder - Spawns an Adder
    - /deletecar - Deletes current/nearby spawned vehicle
    - /fixcar - Repairs current vehicle
    - DELETE key - Quick delete vehicle
    - F6 key - Quick repair vehicle
--]]