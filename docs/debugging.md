# Debugging FiveM Scripts

Debugging is an essential skill for FiveM development. This guide covers various debugging techniques, tools, and best practices to help you identify and fix issues in your scripts efficiently.

## Table of Contents

1. [Basic Debugging Concepts](#basic-debugging-concepts)
2. [Console Logging](#console-logging)
3. [FiveM Developer Tools](#fivem-developer-tools)
4. [Client-Side Debugging](#client-side-debugging)
5. [Server-Side Debugging](#server-side-debugging)
6. [Network Debugging](#network-debugging)
7. [Performance Debugging](#performance-debugging)
8. [Common Issues and Solutions](#common-issues-and-solutions)
9. [Advanced Debugging Techniques](#advanced-debugging-techniques)
10. [Debugging Tools and Resources](#debugging-tools-and-resources)

## Basic Debugging Concepts

### Types of Errors

1. **Syntax Errors**: Code that doesn't follow language rules
2. **Runtime Errors**: Errors that occur during execution
3. **Logic Errors**: Code runs but produces incorrect results
4. **Performance Issues**: Code runs slowly or uses too many resources

### Debugging Mindset

```lua
-- ✅ Good debugging approach
-- 1. Reproduce the issue consistently
-- 2. Isolate the problem area
-- 3. Add logging to understand flow
-- 4. Test hypotheses systematically
-- 5. Fix one issue at a time

-- ❌ Bad debugging approach
-- 1. Making random changes
-- 2. Fixing multiple issues simultaneously
-- 3. Not testing changes
-- 4. Ignoring error messages
```

## Console Logging

### Basic Logging

```lua
-- Server-side logging
print('Basic server message')
Citizen.Trace('Detailed server trace')

-- Client-side logging
print('Basic client message')
console.log('JavaScript-style logging') -- In JS resources

-- Formatted logging
print(string.format('[%s] Player %s connected', GetCurrentResourceName(), GetPlayerName(source)))
```

### Advanced Logging System

```lua
-- shared/logger.lua
local Logger = {}
Logger.__index = Logger

local LOG_LEVELS = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4
}

local CURRENT_LOG_LEVEL = LOG_LEVELS.DEBUG

function Logger.new(prefix)
    local self = setmetatable({}, Logger)
    self.prefix = prefix or GetCurrentResourceName()
    return self
end

function Logger:log(level, message, ...)
    if LOG_LEVELS[level] < CURRENT_LOG_LEVEL then
        return
    end
    
    local timestamp = os.date('%Y-%m-%d %H:%M:%S')
    local formattedMessage = string.format(message, ...)
    
    local colors = {
        DEBUG = '^8',
        INFO = '^2',
        WARN = '^3',
        ERROR = '^1'
    }
    
    local logLine = string.format('%s[%s]^7 [%s] [%s] %s',
        colors[level] or '^7',
        self.prefix,
        timestamp,
        level,
        formattedMessage
    )
    
    print(logLine)
    
    -- Optional: Write to file
    if level == 'ERROR' then
        self:writeToFile(logLine)
    end
end

function Logger:debug(message, ...)
    self:log('DEBUG', message, ...)
end

function Logger:info(message, ...)
    self:log('INFO', message, ...)
end

function Logger:warn(message, ...)
    self:log('WARN', message, ...)
end

function Logger:error(message, ...)
    self:log('ERROR', message, ...)
end

function Logger:writeToFile(message)
    -- Implement file writing if needed
    -- SaveResourceFile(GetCurrentResourceName(), 'logs/error.log', message .. '\n', -1)
end

-- Usage
local logger = Logger.new('MyResource')
logger:info('Resource started successfully')
logger:error('Failed to connect to database: %s', errorMessage)
```

### Conditional Logging

```lua
-- Debug mode configuration
local DEBUG_MODE = GetConvar('debug_mode', 'false') == 'true'

local function debugPrint(message, ...)
    if DEBUG_MODE then
        print(string.format('[DEBUG] ' .. message, ...))
    end
end

-- Usage
debugPrint('Player %s entered zone %s', playerName, zoneName)

-- Server.cfg configuration
# Enable debug mode
set debug_mode true
```

## FiveM Developer Tools

### Built-in Commands

```bash
# Server console commands
resmon                    # Resource monitor
perf start [resource]     # Start performance profiling
perf stop [resource]      # Stop performance profiling
refresh                   # Refresh resource list
restart [resource]        # Restart specific resource
stop [resource]          # Stop resource
start [resource]         # Start resource

# Client console commands (F8)
resmon                    # Client resource monitor
neteventlog on           # Enable network event logging
neteventlog off          # Disable network event logging
```

### Resource Monitor

```lua
-- Monitor resource performance
CreateThread(function()
    while true do
        Wait(5000) -- Check every 5 seconds
        
        local resourceName = GetCurrentResourceName()
        local memoryUsage = GetResourceMetadata(resourceName, 'memory_usage', 0)
        
        if memoryUsage and tonumber(memoryUsage) > 10.0 then -- 10MB threshold
            print(string.format('^3[WARNING] High memory usage: %.2f MB', memoryUsage))
        end
    end
end)
```

## Client-Side Debugging

### Browser Developer Tools

```javascript
// For NUI debugging (HTML/CSS/JS)
// Enable developer tools in fxmanifest.lua
ui_page 'html/index.html'

// In your NUI JavaScript
console.log('Debug message');
console.error('Error message');
console.table(dataObject);

// Debug NUI messages
window.addEventListener('message', function(event) {
    console.log('Received NUI message:', event.data);
});
```

### Client Debug Overlay

```lua
-- client.lua
local debugOverlay = false
local debugInfo = {}

RegisterCommand('debugoverlay', function()
    debugOverlay = not debugOverlay
end, false)

CreateThread(function()
    while true do
        Wait(0)
        
        if debugOverlay then
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local heading = GetEntityHeading(playerPed)
            local health = GetEntityHealth(playerPed)
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            
            -- Update debug info
            debugInfo = {
                'Player Debug Info:',
                string.format('Coords: %.2f, %.2f, %.2f', coords.x, coords.y, coords.z),
                string.format('Heading: %.2f', heading),
                string.format('Health: %d', health),
                string.format('In Vehicle: %s', vehicle ~= 0 and 'Yes' or 'No'),
                string.format('FPS: %d', math.floor(1.0 / GetFrameTime())),
                string.format('Game Timer: %d', GetGameTimer())
            }
            
            -- Draw debug overlay
            local yPos = 0.1
            for _, line in ipairs(debugInfo) do
                SetTextFont(4)
                SetTextProportional(1)
                SetTextScale(0.35, 0.35)
                SetTextColour(255, 255, 255, 255)
                SetTextEntry('STRING')
                AddTextComponentString(line)
                DrawText(0.02, yPos)
                yPos = yPos + 0.025
            end
        end
    end
end)
```

### Entity Debugging

```lua
-- Debug entity information
local function debugEntity(entity)
    if not DoesEntityExist(entity) then
        print('Entity does not exist')
        return
    end
    
    local coords = GetEntityCoords(entity)
    local model = GetEntityModel(entity)
    local health = GetEntityHealth(entity)
    local netId = NetworkGetNetworkIdFromEntity(entity)
    
    print(string.format('Entity Debug:'))
    print(string.format('  Handle: %d', entity))
    print(string.format('  Model: %d (0x%X)', model, model))
    print(string.format('  Coords: %.2f, %.2f, %.2f', coords.x, coords.y, coords.z))
    print(string.format('  Health: %d', health))
    print(string.format('  Network ID: %d', netId))
    print(string.format('  Is Mission Entity: %s', IsEntityAMissionEntity(entity)))
end

-- Usage
RegisterCommand('debugentity', function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle ~= 0 then
        debugEntity(vehicle)
    else
        debugEntity(playerPed)
    end
end, false)
```

## Server-Side Debugging

### Player Connection Debugging

```lua
-- server.lua
local connectionLog = {}

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source
    local identifiers = GetPlayerIdentifiers(source)
    
    print(string.format('[CONNECTION] Player %s (%d) connecting...', name, source))
    print(string.format('[CONNECTION] Identifiers: %s', json.encode(identifiers)))
    
    connectionLog[source] = {
        name = name,
        identifiers = identifiers,
        connectTime = os.time()
    }
end)

AddEventHandler('playerJoining', function()
    local source = source
    print(string.format('[JOIN] Player %s (%d) joined successfully', GetPlayerName(source), source))
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    local connectTime = connectionLog[source] and connectionLog[source].connectTime or 0
    local sessionTime = os.time() - connectTime
    
    print(string.format('[DISCONNECT] Player %s (%d) disconnected: %s', 
          GetPlayerName(source), source, reason))
    print(string.format('[DISCONNECT] Session time: %d seconds', sessionTime))
    
    connectionLog[source] = nil
end)
```

### Event Debugging

```lua
-- Debug all incoming events
local originalAddEventHandler = AddEventHandler

function AddEventHandler(eventName, callback)
    return originalAddEventHandler(eventName, function(...)
        local args = {...}
        print(string.format('[EVENT] %s triggered with %d args', eventName, #args))
        
        -- Log first few arguments (be careful with sensitive data)
        for i = 1, math.min(3, #args) do
            if type(args[i]) == 'table' then
                print(string.format('  Arg %d: %s', i, json.encode(args[i])))
            else
                print(string.format('  Arg %d: %s', i, tostring(args[i])))
            end
        end
        
        return callback(...)
    end)
end
```

### Database Debugging

```lua
-- Debug database queries
local function debugQuery(query, parameters)
    print(string.format('[DB] Executing query: %s', query))
    if parameters then
        print(string.format('[DB] Parameters: %s', json.encode(parameters)))
    end
    
    local startTime = GetGameTimer()
    
    -- Execute your database query here
    -- local result = MySQL.query(query, parameters)
    
    local endTime = GetGameTimer()
    print(string.format('[DB] Query completed in %d ms', endTime - startTime))
    
    -- return result
end
```

## Network Debugging

### Event Flow Tracking

```lua
-- shared/debug.lua
local eventLog = {}

local function logEvent(eventName, source, target, data)
    local entry = {
        timestamp = GetGameTimer(),
        event = eventName,
        source = source,
        target = target,
        data = data
    }
    
    table.insert(eventLog, entry)
    
    -- Keep only last 100 events
    if #eventLog > 100 then
        table.remove(eventLog, 1)
    end
    
    print(string.format('[NET] %s: %s -> %s', eventName, source or 'server', target or 'all'))
end

-- Override TriggerServerEvent
local originalTriggerServerEvent = TriggerServerEvent
function TriggerServerEvent(eventName, ...)
    logEvent(eventName, 'client', 'server', {...})
    return originalTriggerServerEvent(eventName, ...)
end

-- Override TriggerClientEvent (server-side)
local originalTriggerClientEvent = TriggerClientEvent
function TriggerClientEvent(eventName, target, ...)
    logEvent(eventName, 'server', target, {...})
    return originalTriggerClientEvent(eventName, target, ...)
end
```

### Network Event Monitor

```lua
-- client.lua
local networkStats = {
    sent = {},
    received = {}
}

RegisterCommand('netstats', function()
    print('Network Event Statistics:')
    print('Sent Events:')
    for event, count in pairs(networkStats.sent) do
        print(string.format('  %s: %d', event, count))
    end
    
    print('Received Events:')
    for event, count in pairs(networkStats.received) do
        print(string.format('  %s: %d', event, count))
    end
end, false)

-- Track sent events
local originalTriggerServerEvent = TriggerServerEvent
function TriggerServerEvent(eventName, ...)
    networkStats.sent[eventName] = (networkStats.sent[eventName] or 0) + 1
    return originalTriggerServerEvent(eventName, ...)
end

-- Track received events
local originalAddEventHandler = AddEventHandler
function AddEventHandler(eventName, callback)
    return originalAddEventHandler(eventName, function(...)
        networkStats.received[eventName] = (networkStats.received[eventName] or 0) + 1
        return callback(...)
    end)
end
```

## Performance Debugging

### Frame Time Monitoring

```lua
-- client.lua
local frameTimeHistory = {}
local maxHistorySize = 60 -- 1 second at 60 FPS

CreateThread(function()
    while true do
        Wait(0)
        
        local frameTime = GetFrameTime()
        table.insert(frameTimeHistory, frameTime)
        
        if #frameTimeHistory > maxHistorySize then
            table.remove(frameTimeHistory, 1)
        end
        
        -- Check for frame drops
        if frameTime > 0.033 then -- Below 30 FPS
            print(string.format('^3[PERF] Frame drop detected: %.3f ms (%.1f FPS)', 
                  frameTime * 1000, 1.0 / frameTime))
        end
    end
end)

RegisterCommand('fps', function()
    if #frameTimeHistory > 0 then
        local avgFrameTime = 0
        for _, ft in ipairs(frameTimeHistory) do
            avgFrameTime = avgFrameTime + ft
        end
        avgFrameTime = avgFrameTime / #frameTimeHistory
        
        local avgFPS = 1.0 / avgFrameTime
        print(string.format('Average FPS: %.1f (%.3f ms)', avgFPS, avgFrameTime * 1000))
    end
end, false)
```

### Memory Usage Tracking

```lua
-- server.lua
local function getMemoryUsage()
    -- This is a simplified example
    -- In practice, you'd use more sophisticated memory tracking
    return collectgarbage('count')
end

local memoryHistory = {}

CreateThread(function()
    while true do
        Wait(10000) -- Check every 10 seconds
        
        local currentMemory = getMemoryUsage()
        table.insert(memoryHistory, {
            timestamp = os.time(),
            memory = currentMemory
        })
        
        -- Keep only last hour of data
        while #memoryHistory > 360 do
            table.remove(memoryHistory, 1)
        end
        
        -- Check for memory leaks
        if #memoryHistory >= 2 then
            local previous = memoryHistory[#memoryHistory - 1].memory
            local current = memoryHistory[#memoryHistory].memory
            local increase = current - previous
            
            if increase > 1024 then -- 1MB increase
                print(string.format('^3[MEMORY] Significant memory increase: %.2f MB', 
                      increase / 1024))
            end
        end
    end
end)
```

### Function Profiling

```lua
-- Profiling wrapper
local function profileFunction(func, name)
    return function(...)
        local startTime = GetGameTimer()
        local result = {func(...)}
        local endTime = GetGameTimer()
        
        local duration = endTime - startTime
        if duration > 5 then -- Log functions taking more than 5ms
            print(string.format('[PROFILE] %s took %d ms', name or 'anonymous', duration))
        end
        
        return table.unpack(result)
    end
end

-- Usage
local expensiveFunction = profileFunction(function(data)
    -- Your expensive function here
    for i = 1, 1000000 do
        -- Some work
    end
end, 'expensiveFunction')
```

## Common Issues and Solutions

### Issue 1: Events Not Triggering

```lua
-- ❌ Problem: Event not registered
AddEventHandler('myEvent', function()
    print('This will not work!')
end)

-- ✅ Solution: Register the event first
RegisterNetEvent('myEvent')
AddEventHandler('myEvent', function()
    print('This works!')
end)
```

### Issue 2: Nil Value Errors

```lua
-- ❌ Problem: Not checking for nil
local function processPlayer(playerId)
    local playerName = GetPlayerName(playerId)
    print('Processing: ' .. playerName) -- Error if playerId is invalid
end

-- ✅ Solution: Always validate inputs
local function processPlayer(playerId)
    if not playerId then
        print('Error: playerId is nil')
        return
    end
    
    local playerName = GetPlayerName(playerId)
    if not playerName then
        print('Error: Could not get player name for ID ' .. playerId)
        return
    end
    
    print('Processing: ' .. playerName)
end
```

### Issue 3: Infinite Loops

```lua
-- ❌ Problem: No wait in loop
CreateThread(function()
    while true do
        -- This will freeze the game!
        doSomething()
    end
end)

-- ✅ Solution: Always include Wait()
CreateThread(function()
    while true do
        Wait(1000) -- Wait 1 second
        doSomething()
    end
end)
```

### Issue 4: Resource Dependencies

```lua
-- ❌ Problem: Using undefined functions
local result = SomeFrameworkFunction() -- Error if framework not loaded

-- ✅ Solution: Check dependencies
local function safeCall(func, ...)
    if func then
        return func(...)
    else
        print('Warning: Function not available')
        return nil
    end
end

-- Or check for exports
if exports['framework-name'] then
    local result = exports['framework-name']:someFunction()
else
    print('Framework not available')
end
```

## Advanced Debugging Techniques

### Stack Trace Logging

```lua
local function getStackTrace()
    local trace = {}
    local level = 2 -- Skip this function
    
    while true do
        local info = debug.getinfo(level, 'Sln')
        if not info then break end
        
        table.insert(trace, string.format('%s:%d in %s', 
            info.short_src or 'unknown', 
            info.currentline or 0, 
            info.name or 'anonymous'
        ))
        
        level = level + 1
    end
    
    return table.concat(trace, '\n  ')
end

local function logError(message)
    print(string.format('^1[ERROR] %s\nStack trace:\n  %s^7', message, getStackTrace()))
end

-- Usage
local function riskyFunction()
    if someCondition then
        logError('Something went wrong!')
    end
end
```

### Conditional Breakpoints

```lua
local function debugBreakpoint(condition, message)
    if condition then
        print(string.format('^3[BREAKPOINT] %s^7', message or 'Debug breakpoint hit'))
        print('Stack trace:')
        print(getStackTrace())
        
        -- Optional: Pause execution (be careful in production)
        if GetConvar('debug_mode', 'false') == 'true' then
            -- You could implement a pause mechanism here
        end
    end
end

-- Usage
local function processData(data)
    debugBreakpoint(not data, 'Data is nil in processData')
    debugBreakpoint(type(data) ~= 'table', 'Data is not a table')
    
    -- Continue with function
end
```

### Remote Debugging

```lua
-- server.lua - Remote debug commands
RegisterCommand('debug_player', function(source, args)
    local targetId = tonumber(args[1])
    if not targetId then
        print('Usage: debug_player [player_id]')
        return
    end
    
    -- Send debug command to specific client
    TriggerClientEvent('debug:enableOverlay', targetId)
    print('Debug overlay enabled for player ' .. targetId)
end, true) -- Restrict to admins

RegisterCommand('debug_all', function(source, args)
    -- Send debug command to all clients
    TriggerClientEvent('debug:enableOverlay', -1)
    print('Debug overlay enabled for all players')
end, true)

-- client.lua - Handle remote debug commands
RegisterNetEvent('debug:enableOverlay')
AddEventHandler('debug:enableOverlay', function()
    debugOverlay = true
    print('Debug overlay enabled by admin')
end)
```

## Debugging Tools and Resources

### Recommended Tools

1. **Visual Studio Code Extensions:**
   - Lua Language Server
   - FiveM Development Tools
   - GitLens (for code history)

2. **Browser Tools:**
   - Chrome DevTools (for NUI debugging)
   - Firefox Developer Tools

3. **External Tools:**
   - Wireshark (for network analysis)
   - Process Monitor (for file system debugging)
   - Resource Monitor (for performance analysis)

### Useful Console Commands

```bash
# Server console
resmon                    # Resource performance monitor
perf start [resource]     # Start performance profiling
perf stop [resource]      # Stop performance profiling
monitor [resource]        # Monitor resource events
refresh                   # Refresh resource list
ensure [resource]         # Start resource if not running

# Client console (F8)
resmon                    # Client resource monitor
neteventlog on           # Log network events
neteventlog off          # Disable network event logging
quit                     # Exit game
connect [ip:port]        # Connect to server
disconnect               # Disconnect from server
```

### Debug Configuration

```lua
-- fxmanifest.lua
fx_version 'cerulean'
game 'gta5'

-- Enable debug mode
if GetConvar('debug_mode', 'false') == 'true' then
    client_scripts {
        'debug/client_debug.lua',
        'client.lua'
    }
    
    server_scripts {
        'debug/server_debug.lua',
        'server.lua'
    }
else
    client_scripts {
        'client.lua'
    }
    
    server_scripts {
        'server.lua'
    }
end
```

### Creating Debug Builds

```bash
# server.cfg
# Development configuration
set debug_mode true
set sv_debugqueue true
set sv_debugprint true

# Production configuration
set debug_mode false
set sv_debugqueue false
set sv_debugprint false
```

By following these debugging techniques and using the provided tools, you'll be able to identify and fix issues in your FiveM scripts more efficiently. Remember that good debugging practices include:

1. **Reproduce issues consistently**
2. **Use systematic approaches**
3. **Log relevant information**
4. **Test fixes thoroughly**
5. **Document solutions for future reference**

Debugging is a skill that improves with practice, so don't get discouraged if it takes time to master these techniques!