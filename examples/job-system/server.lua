--[[
    EMS Job System - Server Component
    
    This script demonstrates:
    - Job management system
    - Player data persistence
    - Server-client communication
    - Event handling and validation
    - Database integration patterns
    - Permission and role management
    
    Features:
    - EMS job assignment and management
    - Emergency call system
    - Player duty status tracking
    - Salary and payment system
    - Equipment and vehicle management
    - Performance tracking
--]]

local CONFIG = {
    -- Job settings
    JOB_NAME = 'ems',
    MAX_EMS_PLAYERS = 8,
    SALARY_AMOUNT = 150,
    SALARY_INTERVAL = 300000, -- 5 minutes in milliseconds
    
    -- Emergency call settings
    CALL_TIMEOUT = 600000, -- 10 minutes
    MAX_ACTIVE_CALLS = 10,
    CALL_REWARD = 500,
    
    -- EMS stations and spawn points
    STATIONS = {
        {
            id = 1,
            name = 'Pillbox Medical Center',
            coords = vector3(298.6, -584.4, 43.3),
            blip = { sprite = 61, color = 1, scale = 0.8 },
            vehicles = {
                { model = 'ambulance', coords = vector4(294.5, -574.2, 43.2, 70.0) },
                { model = 'ambulance', coords = vector4(297.2, -578.8, 43.2, 70.0) }
            },
            equipment = {
                { item = 'medkit', amount = 5 },
                { item = 'bandage', amount = 10 },
                { item = 'painkillers', amount = 8 }
            }
        },
        {
            id = 2,
            name = 'Sandy Shores Medical',
            coords = vector3(1839.6, 3672.9, 34.3),
            blip = { sprite = 61, color = 1, scale = 0.8 },
            vehicles = {
                { model = 'ambulance', coords = vector4(1831.4, 3679.1, 34.0, 210.0) }
            },
            equipment = {
                { item = 'medkit', amount = 3 },
                { item = 'bandage', amount = 6 },
                { item = 'painkillers', amount = 5 }
            }
        }
    },
    
    -- EMS ranks and permissions
    RANKS = {
        [1] = { name = 'Trainee Paramedic', salary = 100, permissions = {'basic_treatment'} },
        [2] = { name = 'Paramedic', salary = 150, permissions = {'basic_treatment', 'advanced_treatment'} },
        [3] = { name = 'Senior Paramedic', salary = 200, permissions = {'basic_treatment', 'advanced_treatment', 'supervise'} },
        [4] = { name = 'EMS Supervisor', salary = 250, permissions = {'basic_treatment', 'advanced_treatment', 'supervise', 'manage_calls'} },
        [5] = { name = 'Chief of EMS', salary = 300, permissions = {'basic_treatment', 'advanced_treatment', 'supervise', 'manage_calls', 'admin'} }
    }
}

-- ============================================================================
-- DATA STORAGE
-- ============================================================================

-- Player data storage (in production, use database)
local playerData = {}
local onDutyPlayers = {}
local emergencyCalls = {}
local callIdCounter = 1
local salaryTimers = {}

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

local function log(message, level)
    level = level or 'info'
    local timestamp = os.date('%Y-%m-%d %H:%M:%S')
    print(string.format('^3[EMS-Server]^7 [%s] [%s] %s', timestamp, level:upper(), message))
end

local function getPlayerIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, id in pairs(identifiers) do
        if string.find(id, 'license:') then
            return id
        end
    end
    return nil
end

local function getPlayerData(source)
    local identifier = getPlayerIdentifier(source)
    if not identifier then return nil end
    
    if not playerData[identifier] then
        playerData[identifier] = {
            source = source,
            identifier = identifier,
            job = nil,
            rank = 1,
            onDuty = false,
            totalEarnings = 0,
            callsCompleted = 0,
            joinDate = os.time(),
            lastSalary = 0
        }
    end
    
    playerData[identifier].source = source
    return playerData[identifier]
end

local function hasPermission(source, permission)
    local data = getPlayerData(source)
    if not data or data.job ~= CONFIG.JOB_NAME then return false end
    
    local rank = CONFIG.RANKS[data.rank]
    if not rank then return false end
    
    for _, perm in pairs(rank.permissions) do
        if perm == permission then
            return true
        end
    end
    return false
end

local function notifyPlayer(source, message, type)
    type = type or 'info'
    TriggerClientEvent('ems:notify', source, message, type)
end

local function notifyAllEMS(message, type)
    for source, _ in pairs(onDutyPlayers) do
        notifyPlayer(source, message, type)
    end
end

-- ============================================================================
-- JOB MANAGEMENT
-- ============================================================================

local function setPlayerJob(source, job, rank)
    local data = getPlayerData(source)
    if not data then return false end
    
    data.job = job
    data.rank = rank or 1
    
    -- Update client
    TriggerClientEvent('ems:updateJobData', source, {
        job = data.job,
        rank = data.rank,
        rankName = CONFIG.RANKS[data.rank] and CONFIG.RANKS[data.rank].name or 'Unknown',
        onDuty = data.onDuty
    })
    
    log(string.format('Player %s assigned to job %s (rank %d)', GetPlayerName(source), job, rank))
    return true
end

local function toggleDuty(source)
    local data = getPlayerData(source)
    if not data or data.job ~= CONFIG.JOB_NAME then
        notifyPlayer(source, 'You are not employed as EMS!', 'error')
        return false
    end
    
    data.onDuty = not data.onDuty
    
    if data.onDuty then
        -- Going on duty
        onDutyPlayers[source] = true
        
        -- Start salary timer
        salaryTimers[source] = SetTimeout(CONFIG.SALARY_INTERVAL, function()
            paySalary(source)
        end)
        
        -- Notify
        notifyPlayer(source, 'You are now on duty as ' .. CONFIG.RANKS[data.rank].name, 'success')
        notifyAllEMS(GetPlayerName(source) .. ' has gone on duty', 'info')
        
        -- Send duty data to client
        TriggerClientEvent('ems:onDuty', source, {
            stations = CONFIG.STATIONS,
            rank = data.rank,
            permissions = CONFIG.RANKS[data.rank].permissions
        })
        
    else
        -- Going off duty
        onDutyPlayers[source] = nil
        
        -- Clear salary timer
        if salaryTimers[source] then
            ClearTimeout(salaryTimers[source])
            salaryTimers[source] = nil
        end
        
        -- Notify
        notifyPlayer(source, 'You are now off duty', 'info')
        notifyAllEMS(GetPlayerName(source) .. ' has gone off duty', 'info')
        
        -- Send off duty to client
        TriggerClientEvent('ems:offDuty', source)
    end
    
    -- Update client job data
    TriggerClientEvent('ems:updateJobData', source, {
        job = data.job,
        rank = data.rank,
        rankName = CONFIG.RANKS[data.rank].name,
        onDuty = data.onDuty
    })
    
    return true
end

function paySalary(source)
    local data = getPlayerData(source)
    if not data or not data.onDuty or data.job ~= CONFIG.JOB_NAME then return end
    
    local rank = CONFIG.RANKS[data.rank]
    if not rank then return end
    
    local amount = rank.salary
    data.totalEarnings = data.totalEarnings + amount
    data.lastSalary = os.time()
    
    -- Add money to player (implement your economy system here)
    -- exports['your-economy']:addMoney(source, 'bank', amount)
    
    notifyPlayer(source, string.format('Salary received: $%d', amount), 'success')
    log(string.format('Paid salary $%d to %s', amount, GetPlayerName(source)))
    
    -- Schedule next salary
    salaryTimers[source] = SetTimeout(CONFIG.SALARY_INTERVAL, function()
        paySalary(source)
    end)
end

-- ============================================================================
-- EMERGENCY CALL SYSTEM
-- ============================================================================

local function createEmergencyCall(coords, description, caller)
    if #emergencyCalls >= CONFIG.MAX_ACTIVE_CALLS then
        return false, 'Maximum active calls reached'
    end
    
    local call = {
        id = callIdCounter,
        coords = coords,
        description = description,
        caller = caller,
        timestamp = os.time(),
        status = 'pending', -- pending, assigned, completed, cancelled
        assignedTo = nil,
        priority = 'normal' -- low, normal, high, critical
    }
    
    emergencyCalls[call.id] = call
    callIdCounter = callIdCounter + 1
    
    -- Notify all on-duty EMS
    notifyAllEMS(string.format('New emergency call: %s', description), 'warning')
    
    -- Send call data to all EMS
    for source, _ in pairs(onDutyPlayers) do
        TriggerClientEvent('ems:newEmergencyCall', source, call)
    end
    
    -- Auto-expire call after timeout
    SetTimeout(CONFIG.CALL_TIMEOUT, function()
        if emergencyCalls[call.id] and emergencyCalls[call.id].status == 'pending' then
            emergencyCalls[call.id].status = 'expired'
            notifyAllEMS(string.format('Emergency call #%d has expired', call.id), 'error')
            TriggerClientEvent('ems:callExpired', -1, call.id)
        end
    end)
    
    log(string.format('Emergency call created: ID %d, Description: %s', call.id, description))
    return true, call
end

local function assignCall(source, callId)
    local data = getPlayerData(source)
    if not data or not data.onDuty or data.job ~= CONFIG.JOB_NAME then
        return false, 'You are not on duty as EMS'
    end
    
    local call = emergencyCalls[callId]
    if not call then
        return false, 'Call not found'
    end
    
    if call.status ~= 'pending' then
        return false, 'Call is no longer available'
    end
    
    call.status = 'assigned'
    call.assignedTo = source
    
    notifyPlayer(source, string.format('You have been assigned to call #%d', callId), 'success')
    notifyAllEMS(string.format('%s has been assigned to call #%d', GetPlayerName(source), callId), 'info')
    
    -- Send call details to assigned player
    TriggerClientEvent('ems:callAssigned', source, call)
    
    -- Update other EMS that call is taken
    for emsSource, _ in pairs(onDutyPlayers) do
        if emsSource ~= source then
            TriggerClientEvent('ems:callTaken', emsSource, callId)
        end
    end
    
    log(string.format('Call #%d assigned to %s', callId, GetPlayerName(source)))
    return true, call
end

local function completeCall(source, callId)
    local data = getPlayerData(source)
    if not data or not data.onDuty or data.job ~= CONFIG.JOB_NAME then
        return false, 'You are not on duty as EMS'
    end
    
    local call = emergencyCalls[callId]
    if not call then
        return false, 'Call not found'
    end
    
    if call.assignedTo ~= source then
        return false, 'You are not assigned to this call'
    end
    
    call.status = 'completed'
    call.completedAt = os.time()
    
    -- Reward player
    data.callsCompleted = data.callsCompleted + 1
    data.totalEarnings = data.totalEarnings + CONFIG.CALL_REWARD
    
    -- Add money to player (implement your economy system here)
    -- exports['your-economy']:addMoney(source, 'cash', CONFIG.CALL_REWARD)
    
    notifyPlayer(source, string.format('Call completed! Reward: $%d', CONFIG.CALL_REWARD), 'success')
    notifyAllEMS(string.format('%s completed call #%d', GetPlayerName(source), callId), 'success')
    
    -- Remove call from active list after delay
    SetTimeout(30000, function()
        emergencyCalls[callId] = nil
    end)
    
    log(string.format('Call #%d completed by %s', callId, GetPlayerName(source)))
    return true
end

-- ============================================================================
-- EQUIPMENT AND VEHICLE MANAGEMENT
-- ============================================================================

local function giveEquipment(source, stationId)
    local data = getPlayerData(source)
    if not data or not data.onDuty or data.job ~= CONFIG.JOB_NAME then
        return false, 'You are not on duty as EMS'
    end
    
    local station = nil
    for _, s in pairs(CONFIG.STATIONS) do
        if s.id == stationId then
            station = s
            break
        end
    end
    
    if not station then
        return false, 'Station not found'
    end
    
    -- Give equipment (implement your inventory system here)
    for _, equipment in pairs(station.equipment) do
        -- exports['your-inventory']:addItem(source, equipment.item, equipment.amount)
        log(string.format('Gave %s x%d to %s', equipment.item, equipment.amount, GetPlayerName(source)))
    end
    
    notifyPlayer(source, 'Equipment received from ' .. station.name, 'success')
    return true
end

local function spawnEMSVehicle(source, stationId, vehicleIndex)
    local data = getPlayerData(source)
    if not data or not data.onDuty or data.job ~= CONFIG.JOB_NAME then
        return false, 'You are not on duty as EMS'
    end
    
    local station = nil
    for _, s in pairs(CONFIG.STATIONS) do
        if s.id == stationId then
            station = s
            break
        end
    end
    
    if not station or not station.vehicles[vehicleIndex] then
        return false, 'Vehicle not available'
    end
    
    local vehicle = station.vehicles[vehicleIndex]
    
    -- Trigger client to spawn vehicle
    TriggerClientEvent('ems:spawnVehicle', source, {
        model = vehicle.model,
        coords = vehicle.coords,
        station = station.name
    })
    
    log(string.format('EMS vehicle %s spawned for %s at %s', vehicle.model, GetPlayerName(source), station.name))
    return true
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

-- Player connecting
AddEventHandler('playerConnecting', function()
    local source = source
    getPlayerData(source) -- Initialize player data
end)

-- Player dropping
AddEventHandler('playerDropped', function()
    local source = source
    
    -- Clean up on-duty status
    if onDutyPlayers[source] then
        onDutyPlayers[source] = nil
        notifyAllEMS(GetPlayerName(source) .. ' has disconnected', 'info')
    end
    
    -- Clear salary timer
    if salaryTimers[source] then
        ClearTimeout(salaryTimers[source])
        salaryTimers[source] = nil
    end
end)

-- Resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        log('EMS Job System started successfully')
        
        -- Initialize any persistent data here
        -- loadPlayerData()
    end
end)

-- Resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        log('EMS Job System stopping...')
        
        -- Save player data
        -- savePlayerData()
        
        -- Clear all timers
        for source, timer in pairs(salaryTimers) do
            ClearTimeout(timer)
        end
    end
end)

-- ============================================================================
-- REGISTERED EVENTS
-- ============================================================================

-- Job management
RegisterNetEvent('ems:toggleDuty')
AddEventHandler('ems:toggleDuty', function()
    local source = source
    toggleDuty(source)
end)

RegisterNetEvent('ems:requestJobData')
AddEventHandler('ems:requestJobData', function()
    local source = source
    local data = getPlayerData(source)
    
    if data then
        TriggerClientEvent('ems:updateJobData', source, {
            job = data.job,
            rank = data.rank,
            rankName = CONFIG.RANKS[data.rank] and CONFIG.RANKS[data.rank].name or 'Unemployed',
            onDuty = data.onDuty,
            totalEarnings = data.totalEarnings,
            callsCompleted = data.callsCompleted
        })
    end
end)

-- Emergency calls
RegisterNetEvent('ems:createCall')
AddEventHandler('ems:createCall', function(coords, description)
    local source = source
    local success, result = createEmergencyCall(coords, description, source)
    
    if success then
        notifyPlayer(source, 'Emergency call created successfully', 'success')
    else
        notifyPlayer(source, 'Failed to create call: ' .. result, 'error')
    end
end)

RegisterNetEvent('ems:assignCall')
AddEventHandler('ems:assignCall', function(callId)
    local source = source
    local success, result = assignCall(source, callId)
    
    if not success then
        notifyPlayer(source, result, 'error')
    end
end)

RegisterNetEvent('ems:completeCall')
AddEventHandler('ems:completeCall', function(callId)
    local source = source
    local success, result = completeCall(source, callId)
    
    if not success then
        notifyPlayer(source, result, 'error')
    end
end)

-- Equipment and vehicles
RegisterNetEvent('ems:requestEquipment')
AddEventHandler('ems:requestEquipment', function(stationId)
    local source = source
    giveEquipment(source, stationId)
end)

RegisterNetEvent('ems:requestVehicle')
AddEventHandler('ems:requestVehicle', function(stationId, vehicleIndex)
    local source = source
    spawnEMSVehicle(source, stationId, vehicleIndex)
end)

-- ============================================================================
-- COMMANDS
-- ============================================================================

-- Admin commands
RegisterCommand('setjob', function(source, args)
    if source == 0 then -- Console only
        local targetId = tonumber(args[1])
        local job = args[2]
        local rank = tonumber(args[3]) or 1
        
        if targetId and job then
            setPlayerJob(targetId, job, rank)
            print(string.format('Set player %s job to %s (rank %d)', GetPlayerName(targetId), job, rank))
        else
            print('Usage: setjob [player_id] [job] [rank]')
        end
    end
end, true)

RegisterCommand('emsinfo', function(source, args)
    local data = getPlayerData(source)
    if not data then return end
    
    local info = {
        'EMS Information:',
        'Job: ' .. (data.job or 'Unemployed'),
        'Rank: ' .. (CONFIG.RANKS[data.rank] and CONFIG.RANKS[data.rank].name or 'N/A'),
        'On Duty: ' .. (data.onDuty and 'Yes' or 'No'),
        'Total Earnings: $' .. data.totalEarnings,
        'Calls Completed: ' .. data.callsCompleted,
        'Join Date: ' .. os.date('%Y-%m-%d', data.joinDate)
    }
    
    for _, line in pairs(info) do
        TriggerClientEvent('chat:addMessage', source, { args = { 'EMS', line } })
    end
end, false)

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports('setPlayerJob', setPlayerJob)
exports('getPlayerData', getPlayerData)
exports('createEmergencyCall', createEmergencyCall)
exports('getOnDutyEMS', function() return onDutyPlayers end)
exports('getActiveCalls', function() return emergencyCalls end)

log('EMS Job System server component loaded successfully')