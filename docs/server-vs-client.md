# Server vs Client Scripting in FiveM

Understanding the distinction between server-side and client-side scripting is crucial for developing effective FiveM resources. This guide explains when to use each, how they communicate, and best practices for organizing your code.

## Table of Contents

1. [Overview](#overview)
2. [Server-Side Scripting](#server-side-scripting)
3. [Client-Side Scripting](#client-side-scripting)
4. [Communication Between Server and Client](#communication-between-server-and-client)
5. [Security Considerations](#security-considerations)
6. [Performance Best Practices](#performance-best-practices)
7. [Common Patterns](#common-patterns)
8. [Examples](#examples)
9. [Troubleshooting](#troubleshooting)

## Overview

FiveM uses a distributed architecture where code runs in two main environments:

- **Server-Side**: Runs on the FiveM server, handles game logic, data persistence, and player management
- **Client-Side**: Runs on each player's game client, handles UI, local interactions, and rendering

### Key Principles

```
┌─────────────────┐    Network Events    ┌─────────────────┐
│   Server-Side   │ ◄─────────────────► │   Client-Side   │
│                 │                      │                 │
│ • Game Logic    │                      │ • User Interface│
│ • Data Storage  │                      │ • Local Actions │
│ • Validation    │                      │ • Rendering     │
│ • Security      │                      │ • Input Handling│
└─────────────────┘                      └─────────────────┘
```

## Server-Side Scripting

### What Belongs on the Server

**✅ Server-side responsibilities:**
- Player data management and persistence
- Game state validation and synchronization
- Economy and transaction processing
- Anti-cheat and security measures
- Database operations
- Cross-player interactions
- Administrative functions
- Resource management

### Server-Side Example

```lua
-- server.lua
local playerMoney = {}

-- Handle money transactions (MUST be server-side for security)
RegisterNetEvent('economy:transferMoney')
AddEventHandler('economy:transferMoney', function(targetId, amount)
    local source = source
    
    -- Validate transaction server-side
    if playerMoney[source] and playerMoney[source] >= amount then
        playerMoney[source] = playerMoney[source] - amount
        playerMoney[targetId] = (playerMoney[targetId] or 0) + amount
        
        -- Notify both players
        TriggerClientEvent('economy:moneyUpdated', source, playerMoney[source])
        TriggerClientEvent('economy:moneyUpdated', targetId, playerMoney[targetId])
        
        -- Log transaction
        print(string.format('Transfer: %s -> %s: $%d', 
              GetPlayerName(source), GetPlayerName(targetId), amount))
    else
        TriggerClientEvent('economy:transferFailed', source, 'Insufficient funds')
    end
end)

-- Player connection handling
AddEventHandler('playerConnecting', function()
    local source = source
    playerMoney[source] = 5000 -- Starting money
end)

AddEventHandler('playerDropped', function()
    local source = source
    -- Save player data to database here
    playerMoney[source] = nil
end)
```

### Server-Side APIs

```lua
-- Player management
GetPlayerName(source)
GetPlayerIdentifiers(source)
DropPlayer(source, reason)

-- Server events
TriggerClientEvent(eventName, source, ...)
TriggerEvent(eventName, ...)

-- Resource management
GetCurrentResourceName()
GetResourceState(resourceName)
StopResource(resourceName)

-- Console output
print(message)
Citizen.Trace(message)
```

## Client-Side Scripting

### What Belongs on the Client

**✅ Client-side responsibilities:**
- User interface and menus
- Local player interactions
- Visual effects and notifications
- Input handling and controls
- Camera management
- Local entity manipulation
- Drawing and rendering
- Audio playback

### Client-Side Example

```lua
-- client.lua
local playerMoney = 0
local isMenuOpen = false

-- Update money display when server sends update
RegisterNetEvent('economy:moneyUpdated')
AddEventHandler('economy:moneyUpdated', function(newAmount)
    playerMoney = newAmount
    
    -- Update UI
    SendNUIMessage({
        type = 'updateMoney',
        amount = playerMoney
    })
    
    -- Show notification
    SetNotificationTextEntry('STRING')
    AddTextComponentString('Money updated: $' .. playerMoney)
    DrawNotification(false, false)
end)

-- Handle transfer failures
RegisterNetEvent('economy:transferFailed')
AddEventHandler('economy:transferFailed', function(reason)
    -- Show error to player
    SetNotificationTextEntry('STRING')
    AddTextComponentString('Transfer failed: ' .. reason)
    DrawNotification(false, false)
end)

-- Main thread for UI and interactions
CreateThread(function()
    while true do
        Wait(0)
        
        -- Draw money on screen
        SetTextFont(4)
        SetTextProportional(1)
        SetTextScale(0.5, 0.5)
        SetTextColour(255, 255, 255, 255)
        SetTextEntry('STRING')
        AddTextComponentString('Money: $' .. playerMoney)
        DrawText(0.85, 0.05)
        
        -- Handle menu toggle
        if IsControlJustPressed(0, 166) then -- F5
            isMenuOpen = not isMenuOpen
            SetNuiFocus(isMenuOpen, isMenuOpen)
            
            SendNUIMessage({
                type = isMenuOpen and 'openMenu' or 'closeMenu'
            })
        end
    end
end)

-- Command to transfer money
RegisterCommand('transfer', function(source, args)
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])
    
    if targetId and amount and amount > 0 then
        -- Send to server for processing
        TriggerServerEvent('economy:transferMoney', targetId, amount)
    else
        print('Usage: /transfer [player_id] [amount]')
    end
end, false)
```

### Client-Side APIs

```lua
-- Player and entity management
PlayerPedId()
GetEntityCoords(entity)
SetEntityCoords(entity, x, y, z)

-- UI and drawing
DrawText(x, y)
DrawRect(x, y, width, height, r, g, b, a)
SetNotificationTextEntry(text)

-- Input handling
IsControlPressed(inputGroup, control)
IsControlJustPressed(inputGroup, control)

-- Game world
GetGameTimer()
GetFrameTime()
RequestModel(hash)
```

## Communication Between Server and Client

### Network Events

Events are the primary way server and client communicate:

```lua
-- Server to Client
TriggerClientEvent('eventName', source, data)
TriggerClientEvent('eventName', -1, data) -- All clients

-- Client to Server
TriggerServerEvent('eventName', data)

-- Registering event handlers
RegisterNetEvent('eventName')
AddEventHandler('eventName', function(data)
    -- Handle event
end)
```

### Event Flow Diagram

```
Client A                Server                Client B
   │                      │                      │
   │──── TriggerServerEvent ────►│                      │
   │                      │                      │
   │                      │◄─── Process Event ───│
   │                      │                      │
   │◄─── TriggerClientEvent ─────│                      │
   │                      │                      │
   │                      │──── TriggerClientEvent ────►│
   │                      │                      │
```

### Best Practices for Events

```lua
-- ✅ Good: Descriptive event names
TriggerServerEvent('inventory:addItem', itemName, quantity)
TriggerClientEvent('ui:showNotification', source, message, type)

-- ❌ Bad: Generic event names
TriggerServerEvent('doSomething', data)
TriggerClientEvent('update', source, stuff)

-- ✅ Good: Validate data on server
RegisterNetEvent('shop:buyItem')
AddEventHandler('shop:buyItem', function(itemId, quantity)
    local source = source
    
    -- Validate input
    if type(itemId) ~= 'string' or type(quantity) ~= 'number' then
        return
    end
    
    if quantity <= 0 or quantity > 100 then
        return
    end
    
    -- Process purchase
end)

-- ✅ Good: Use meaningful data structures
TriggerClientEvent('player:updateStats', source, {
    health = 100,
    armor = 50,
    hunger = 75,
    thirst = 80
})
```

## Security Considerations

### Never Trust the Client

**❌ Insecure - Client controls money:**
```lua
-- client.lua (NEVER DO THIS)
local money = 1000

RegisterCommand('addmoney', function()
    money = money + 1000 -- Client can modify this!
    TriggerServerEvent('money:update', money)
end)
```

**✅ Secure - Server controls money:**
```lua
-- server.lua
local playerMoney = {}

RegisterNetEvent('money:request')
AddEventHandler('money:request', function()
    local source = source
    -- Server validates and processes
    if canPlayerReceiveMoney(source) then
        playerMoney[source] = (playerMoney[source] or 0) + 1000
        TriggerClientEvent('money:updated', source, playerMoney[source])
    end
end)
```

### Input Validation

```lua
-- server.lua
RegisterNetEvent('vehicle:spawn')
AddEventHandler('vehicle:spawn', function(model, coords)
    local source = source
    
    -- Validate model
    if type(model) ~= 'string' then
        return
    end
    
    -- Validate coordinates
    if type(coords) ~= 'table' or 
       type(coords.x) ~= 'number' or 
       type(coords.y) ~= 'number' or 
       type(coords.z) ~= 'number' then
        return
    end
    
    -- Check if player has permission
    if not hasPermission(source, 'vehicle.spawn') then
        return
    end
    
    -- Spawn vehicle
    spawnVehicle(source, model, coords)
end)
```

### Rate Limiting

```lua
-- server.lua
local rateLimits = {}

local function isRateLimited(source, action, limit, timeWindow)
    local now = GetGameTimer()
    local key = source .. ':' .. action
    
    if not rateLimits[key] then
        rateLimits[key] = { count = 1, resetTime = now + timeWindow }
        return false
    end
    
    if now > rateLimits[key].resetTime then
        rateLimits[key] = { count = 1, resetTime = now + timeWindow }
        return false
    end
    
    rateLimits[key].count = rateLimits[key].count + 1
    return rateLimits[key].count > limit
end

RegisterNetEvent('chat:sendMessage')
AddEventHandler('chat:sendMessage', function(message)
    local source = source
    
    -- Rate limit: 5 messages per 10 seconds
    if isRateLimited(source, 'chat', 5, 10000) then
        TriggerClientEvent('chat:rateLimited', source)
        return
    end
    
    -- Process message
end)
```

## Performance Best Practices

### Client-Side Performance

```lua
-- ✅ Good: Use appropriate wait times
CreateThread(function()
    while true do
        local sleep = 1000 -- Default to longer wait
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        -- Only check nearby interactions
        for _, marker in pairs(markers) do
            local distance = #(playerCoords - marker.coords)
            
            if distance < 50.0 then
                sleep = 0 -- Reduce wait when near markers
                
                if distance < 2.0 then
                    -- Draw interaction text
                    DrawText3D(marker.coords, marker.text)
                    
                    if IsControlJustPressed(0, 38) then
                        marker.action()
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- ❌ Bad: Always waiting 0
CreateThread(function()
    while true do
        Wait(0) -- This runs every frame!
        
        -- Expensive operations every frame
        checkAllMarkers()
        updateAllUI()
    end
end)
```

### Server-Side Performance

```lua
-- ✅ Good: Batch database operations
local pendingUpdates = {}

CreateThread(function()
    while true do
        Wait(30000) -- Every 30 seconds
        
        if #pendingUpdates > 0 then
            -- Batch update database
            updatePlayerDataBatch(pendingUpdates)
            pendingUpdates = {}
        end
    end
end)

-- ✅ Good: Use efficient data structures
local playerData = {} -- Hash table for O(1) lookup

function getPlayerData(source)
    return playerData[source]
end

-- ❌ Bad: Linear search
local playerList = {} -- Array

function getPlayerData(source)
    for i, player in ipairs(playerList) do
        if player.source == source then
            return player
        end
    end
end
```

## Common Patterns

### Request-Response Pattern

```lua
-- client.lua
local function requestPlayerData()
    local promise = promise.new()
    
    local function responseHandler(data)
        RemoveEventHandler('player:dataResponse', responseHandler)
        promise:resolve(data)
    end
    
    RegisterNetEvent('player:dataResponse')
    AddEventHandler('player:dataResponse', responseHandler)
    
    TriggerServerEvent('player:requestData')
    
    return Citizen.Await(promise)
end

-- server.lua
RegisterNetEvent('player:requestData')
AddEventHandler('player:requestData', function()
    local source = source
    local data = getPlayerData(source)
    TriggerClientEvent('player:dataResponse', source, data)
end)
```

### State Synchronization

```lua
-- server.lua
local gameState = {
    weather = 'CLEAR',
    time = { hour = 12, minute = 0 }
}

function updateGameState(newState)
    gameState = newState
    TriggerClientEvent('game:stateUpdated', -1, gameState)
end

-- client.lua
RegisterNetEvent('game:stateUpdated')
AddEventHandler('game:stateUpdated', function(state)
    SetWeatherTypePersist(state.weather)
    NetworkOverrideClockTime(state.time.hour, state.time.minute, 0)
end)
```

### Event Validation Wrapper

```lua
-- server.lua
local function validateEvent(eventName, validator)
    RegisterNetEvent(eventName)
    AddEventHandler(eventName, function(...)
        local source = source
        local args = {...}
        
        if validator(source, args) then
            TriggerEvent(eventName .. ':validated', source, table.unpack(args))
        else
            print('Invalid event data from player ' .. source)
        end
    end)
end

-- Usage
validateEvent('shop:buyItem', function(source, args)
    local itemId, quantity = args[1], args[2]
    return type(itemId) == 'string' and 
           type(quantity) == 'number' and 
           quantity > 0 and quantity <= 100
end)

AddEventHandler('shop:buyItem:validated', function(source, itemId, quantity)
    -- Process validated purchase
end)
```

## Examples

### Complete Vehicle Spawner System

**server.lua:**
```lua
local spawnedVehicles = {}

RegisterNetEvent('vehicle:spawn')
AddEventHandler('vehicle:spawn', function(model, coords)
    local source = source
    
    -- Validate input
    if type(model) ~= 'string' or type(coords) ~= 'table' then
        return
    end
    
    -- Check player permissions
    if not hasPermission(source, 'vehicle.spawn') then
        TriggerClientEvent('vehicle:spawnFailed', source, 'No permission')
        return
    end
    
    -- Limit vehicles per player
    if not spawnedVehicles[source] then
        spawnedVehicles[source] = {}
    end
    
    if #spawnedVehicles[source] >= 3 then
        TriggerClientEvent('vehicle:spawnFailed', source, 'Vehicle limit reached')
        return
    end
    
    -- Create vehicle
    local vehicle = CreateVehicle(GetHashKey(model), coords.x, coords.y, coords.z, coords.w, true, true)
    
    if DoesEntityExist(vehicle) then
        table.insert(spawnedVehicles[source], vehicle)
        TriggerClientEvent('vehicle:spawned', source, NetworkGetNetworkIdFromEntity(vehicle))
    else
        TriggerClientEvent('vehicle:spawnFailed', source, 'Failed to create vehicle')
    end
end)

AddEventHandler('playerDropped', function()
    local source = source
    
    -- Clean up player's vehicles
    if spawnedVehicles[source] then
        for _, vehicle in ipairs(spawnedVehicles[source]) do
            if DoesEntityExist(vehicle) then
                DeleteEntity(vehicle)
            end
        end
        spawnedVehicles[source] = nil
    end
end)
```

**client.lua:**
```lua
local spawnedVehicles = {}

RegisterCommand('spawncar', function(source, args)
    local model = args[1]
    if not model then
        print('Usage: /spawncar [model]')
        return
    end
    
    local playerPed = PlayerPedId()
    local coords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 5.0, 0.0)
    local heading = GetEntityHeading(playerPed)
    
    TriggerServerEvent('vehicle:spawn', model, {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        w = heading
    })
end)

RegisterNetEvent('vehicle:spawned')
AddEventHandler('vehicle:spawned', function(networkId)
    local vehicle = NetworkGetEntityFromNetworkId(networkId)
    table.insert(spawnedVehicles, vehicle)
    
    SetNotificationTextEntry('STRING')
    AddTextComponentString('Vehicle spawned successfully!')
    DrawNotification(false, false)
end)

RegisterNetEvent('vehicle:spawnFailed')
AddEventHandler('vehicle:spawnFailed', function(reason)
    SetNotificationTextEntry('STRING')
    AddTextComponentString('Failed to spawn vehicle: ' .. reason)
    DrawNotification(false, false)
end)
```

## Troubleshooting

### Common Issues

**1. Events not triggering:**
```lua
-- ❌ Forgot to register event
AddEventHandler('myEvent', function()
    -- This won't work!
end)

-- ✅ Properly registered
RegisterNetEvent('myEvent')
AddEventHandler('myEvent', function()
    -- This works!
end)
```

**2. Client-server desync:**
```lua
-- ❌ Client assumes server state
local money = 1000 -- Client thinks they have money
TriggerServerEvent('shop:buy', itemId)

-- ✅ Server authoritative
TriggerServerEvent('shop:buy', itemId)
-- Wait for server response before updating UI
```

**3. Performance issues:**
```lua
-- ❌ Expensive operations in main thread
CreateThread(function()
    while true do
        Wait(0)
        
        -- This runs every frame!
        for i = 1, 1000 do
            doExpensiveOperation()
        end
    end
end)

-- ✅ Proper timing and batching
CreateThread(function()
    while true do
        Wait(1000) -- Only run once per second
        
        -- Batch operations
        local batch = {}
        for i = 1, 100 do -- Smaller batches
            table.insert(batch, prepareOperation(i))
        end
        processBatch(batch)
    end
end)
```

### Debugging Tips

1. **Use descriptive console output:**
```lua
-- Server
print(string.format('[%s] Player %s (%d) performed action: %s', 
      GetCurrentResourceName(), GetPlayerName(source), source, action))

-- Client
print(string.format('[%s] Local player action: %s at %s', 
      GetCurrentResourceName(), action, json.encode(coords)))
```

2. **Validate event flow:**
```lua
-- Add debug prints to track event flow
TriggerServerEvent('test:event', data)
print('Client: Sent test:event')

-- Server
RegisterNetEvent('test:event')
AddEventHandler('test:event', function(data)
    print('Server: Received test:event from ' .. source)
    TriggerClientEvent('test:response', source, 'ok')
    print('Server: Sent test:response to ' .. source)
end)

-- Client
RegisterNetEvent('test:response')
AddEventHandler('test:response', function(response)
    print('Client: Received test:response: ' .. response)
end)
```

3. **Monitor resource usage:**
```bash
# In server console
resmon

# Check specific resource
perf start [resourceName]
# ... wait some time ...
perf stop [resourceName]
```

By following these patterns and best practices, you'll create more secure, performant, and maintainable FiveM resources that properly separate client and server responsibilities.