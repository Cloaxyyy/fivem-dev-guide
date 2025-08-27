# FiveM Development Best Practices

This guide outlines industry-standard best practices for FiveM development, covering code organization, naming conventions, performance optimization, security, and maintainability.

## Table of Contents

1. [Code Organization](#code-organization)
2. [Naming Conventions](#naming-conventions)
3. [Performance Best Practices](#performance-best-practices)
4. [Security Guidelines](#security-guidelines)
5. [Error Handling](#error-handling)
6. [Documentation Standards](#documentation-standards)
7. [Version Control](#version-control)
8. [Testing Strategies](#testing-strategies)
9. [Deployment Guidelines](#deployment-guidelines)
10. [Maintenance and Updates](#maintenance-and-updates)

## Code Organization

### Project Structure

```
my-resource/
├── fxmanifest.lua          # Resource manifest
├── README.md               # Resource documentation
├── config.lua              # Configuration file
├── shared/                 # Shared utilities
│   ├── utils.lua
│   ├── constants.lua
│   └── events.lua
├── server/                 # Server-side code
│   ├── main.lua
│   ├── database.lua
│   ├── events.lua
│   └── commands.lua
├── client/                 # Client-side code
│   ├── main.lua
│   ├── ui.lua
│   ├── events.lua
│   └── controls.lua
├── html/                   # NUI files
│   ├── index.html
│   ├── style.css
│   ├── script.js
│   └── assets/
├── locales/               # Internationalization
│   ├── en.lua
│   ├── es.lua
│   └── fr.lua
└── sql/                   # Database schemas
    ├── install.sql
    └── updates/
```

### Modular Design

```lua
-- ✅ Good: Modular approach
-- shared/utils.lua
local Utils = {}

function Utils.formatMoney(amount)
    return string.format('$%s', string.reverse(string.gsub(string.reverse(tostring(amount)), '(%d%d%d)', '%1,')))
end

function Utils.getDistance(pos1, pos2)
    return math.sqrt(
        (pos1.x - pos2.x)^2 + 
        (pos1.y - pos2.y)^2 + 
        (pos1.z - pos2.z)^2
    )
end

function Utils.roundToDecimal(num, decimals)
    local mult = 10^(decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

return Utils

-- Usage in other files
local Utils = require('shared.utils')
local distance = Utils.getDistance(pos1, pos2)
```

### Configuration Management

```lua
-- config.lua
Config = {}

-- General settings
Config.Debug = false
Config.Locale = 'en'
Config.CheckForUpdates = true

-- Database settings
Config.Database = {
    host = 'localhost',
    port = 3306,
    username = 'root',
    password = '',
    database = 'fivem'
}

-- Feature toggles
Config.Features = {
    enableVehicleSpawning = true,
    enablePlayerManagement = true,
    enableEconomy = false
}

-- Gameplay settings
Config.Gameplay = {
    maxVehiclesPerPlayer = 3,
    vehicleDespawnTime = 300000, -- 5 minutes
    allowedVehicleClasses = {0, 1, 2, 3, 4, 5, 6, 7}
}

-- UI settings
Config.UI = {
    showNotifications = true,
    notificationDuration = 5000,
    theme = 'dark'
}

-- Validation function
function Config.validate()
    assert(type(Config.Locale) == 'string', 'Locale must be a string')
    assert(type(Config.Features) == 'table', 'Features must be a table')
    assert(Config.Gameplay.maxVehiclesPerPlayer > 0, 'Max vehicles must be positive')
end

-- Initialize validation
Config.validate()
```

### Event Management

```lua
-- shared/events.lua
local Events = {
    -- Player events
    PLAYER_LOADED = 'player:loaded',
    PLAYER_LOGOUT = 'player:logout',
    PLAYER_UPDATE_MONEY = 'player:updateMoney',
    
    -- Vehicle events
    VEHICLE_SPAWN = 'vehicle:spawn',
    VEHICLE_DELETE = 'vehicle:delete',
    VEHICLE_LOCK = 'vehicle:lock',
    
    -- UI events
    UI_OPEN_MENU = 'ui:openMenu',
    UI_CLOSE_MENU = 'ui:closeMenu',
    UI_UPDATE_DATA = 'ui:updateData'
}

return Events

-- Usage
local Events = require('shared.events')
TriggerServerEvent(Events.VEHICLE_SPAWN, vehicleModel, coords)
```

## Naming Conventions

### Variables and Functions

```lua
-- ✅ Good: Descriptive and consistent naming
local playerVehicles = {}
local maxVehicleCount = 5
local isPlayerInVehicle = false

local function spawnVehicleForPlayer(playerId, vehicleModel, coordinates)
    -- Function implementation
end

local function getPlayerVehicleCount(playerId)
    return #(playerVehicles[playerId] or {})
end

-- ❌ Bad: Unclear and inconsistent naming
local pv = {}
local max = 5
local flag = false

local function spawn(p, v, c)
    -- Function implementation
end
```

### Constants and Configuration

```lua
-- ✅ Good: UPPER_CASE for constants
local MAX_PLAYERS = 32
local DEFAULT_SPAWN_COORDS = vector3(0.0, 0.0, 72.0)
local VEHICLE_CLASSES = {
    COMPACTS = 0,
    SEDANS = 1,
    SUVS = 2,
    SPORTS = 4
}

-- Configuration with clear naming
Config.VehicleSpawning = {
    enabled = true,
    maxPerPlayer = 3,
    despawnTime = 300000,
    allowedClasses = {0, 1, 2, 4}
}
```

### Events and Commands

```lua
-- ✅ Good: Consistent event naming with namespace
RegisterNetEvent('myresource:player:spawn')
RegisterNetEvent('myresource:vehicle:create')
RegisterNetEvent('myresource:ui:toggle')

-- ✅ Good: Clear command names
RegisterCommand('spawnvehicle', function() end)
RegisterCommand('deletevehicle', function() end)
RegisterCommand('toggleui', function() end)

-- ❌ Bad: Inconsistent and unclear naming
RegisterNetEvent('spawn')
RegisterNetEvent('create_veh')
RegisterNetEvent('ui')
```

### File and Directory Names

```lua
-- ✅ Good: Clear and organized
client/
├── main.lua
├── vehicle_manager.lua
├── ui_controller.lua
└── event_handlers.lua

server/
├── main.lua
├── player_manager.lua
├── database_handler.lua
└── command_processor.lua

-- ❌ Bad: Unclear and disorganized
client/
├── c.lua
├── veh.lua
├── ui.lua
└── stuff.lua
```

## Performance Best Practices

### Efficient Loops and Threading

```lua
-- ✅ Good: Proper wait times and efficient loops
CreateThread(function()
    while true do
        Wait(1000) -- Appropriate wait time
        
        -- Batch operations
        local playersToProcess = {}
        for _, playerId in ipairs(GetPlayers()) do
            if shouldProcessPlayer(playerId) then
                table.insert(playersToProcess, playerId)
            end
        end
        
        -- Process in batches
        for _, playerId in ipairs(playersToProcess) do
            processPlayer(playerId)
        end
    end
end)

-- ❌ Bad: No wait and inefficient processing
CreateThread(function()
    while true do
        -- This will cause performance issues!
        for _, playerId in ipairs(GetPlayers()) do
            processPlayer(playerId)
        end
    end
end)
```

### Memory Management

```lua
-- ✅ Good: Proper cleanup and memory management
local vehicleCache = {}
local maxCacheSize = 100

local function addToCache(vehicleId, data)
    vehicleCache[vehicleId] = data
    
    -- Cleanup old entries
    local cacheSize = 0
    for _ in pairs(vehicleCache) do
        cacheSize = cacheSize + 1
    end
    
    if cacheSize > maxCacheSize then
        local oldestKey = next(vehicleCache)
        vehicleCache[oldestKey] = nil
    end
end

local function removeFromCache(vehicleId)
    vehicleCache[vehicleId] = nil
end

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        vehicleCache = {}
    end
end)
```

### Database Optimization

```lua
-- ✅ Good: Prepared statements and connection pooling
local function updatePlayerMoney(playerId, amount)
    local identifier = GetPlayerIdentifier(playerId, 0)
    
    MySQL.update('UPDATE users SET money = ? WHERE identifier = ?', {
        amount,
        identifier
    }, function(affectedRows)
        if affectedRows > 0 then
            TriggerClientEvent('player:moneyUpdated', playerId, amount)
        end
    end)
end

-- ✅ Good: Batch operations
local function updateMultiplePlayersMoney(updates)
    local queries = {}
    
    for playerId, amount in pairs(updates) do
        local identifier = GetPlayerIdentifier(playerId, 0)
        table.insert(queries, {
            query = 'UPDATE users SET money = ? WHERE identifier = ?',
            parameters = {amount, identifier}
        })
    end
    
    MySQL.transaction(queries, function(success)
        if success then
            for playerId, amount in pairs(updates) do
                TriggerClientEvent('player:moneyUpdated', playerId, amount)
            end
        end
    end)
end
```

### Event Optimization

```lua
-- ✅ Good: Efficient event handling
local eventQueue = {}
local isProcessingQueue = false

local function queueEvent(eventData)
    table.insert(eventQueue, eventData)
    
    if not isProcessingQueue then
        processEventQueue()
    end
end

local function processEventQueue()
    isProcessingQueue = true
    
    CreateThread(function()
        while #eventQueue > 0 do
            local event = table.remove(eventQueue, 1)
            processEvent(event)
            Wait(0) -- Yield to prevent blocking
        end
        
        isProcessingQueue = false
    end)
end

-- ❌ Bad: Immediate processing without queuing
local function handleEvent(eventData)
    -- This could block if processing takes too long
    processEvent(eventData)
end
```

## Security Guidelines

### Input Validation

```lua
-- ✅ Good: Comprehensive input validation
local function validateVehicleSpawn(playerId, vehicleModel, coords)
    -- Validate player
    if not playerId or not GetPlayerName(playerId) then
        return false, 'Invalid player'
    end
    
    -- Validate vehicle model
    if not vehicleModel or type(vehicleModel) ~= 'string' then
        return false, 'Invalid vehicle model'
    end
    
    if not IsModelInCdimage(GetHashKey(vehicleModel)) then
        return false, 'Vehicle model does not exist'
    end
    
    -- Validate coordinates
    if not coords or type(coords) ~= 'table' then
        return false, 'Invalid coordinates'
    end
    
    if not coords.x or not coords.y or not coords.z then
        return false, 'Incomplete coordinates'
    end
    
    -- Range validation
    if math.abs(coords.x) > 10000 or math.abs(coords.y) > 10000 then
        return false, 'Coordinates out of range'
    end
    
    return true
end

RegisterNetEvent('vehicle:spawn')
AddEventHandler('vehicle:spawn', function(vehicleModel, coords)
    local source = source
    local isValid, errorMessage = validateVehicleSpawn(source, vehicleModel, coords)
    
    if not isValid then
        print(string.format('Invalid spawn request from %d: %s', source, errorMessage))
        return
    end
    
    -- Proceed with spawning
end)
```

### Permission System

```lua
-- ✅ Good: Role-based permission system
local Permissions = {}

local playerRoles = {}
local rolePermissions = {
    admin = {'vehicle.spawn', 'vehicle.delete', 'player.kick', 'player.ban'},
    moderator = {'vehicle.spawn', 'vehicle.delete', 'player.kick'},
    vip = {'vehicle.spawn'},
    user = {}
}

function Permissions.setPlayerRole(playerId, role)
    if not rolePermissions[role] then
        return false, 'Invalid role'
    end
    
    playerRoles[playerId] = role
    return true
end

function Permissions.hasPermission(playerId, permission)
    local role = playerRoles[playerId] or 'user'
    local permissions = rolePermissions[role] or {}
    
    for _, perm in ipairs(permissions) do
        if perm == permission then
            return true
        end
    end
    
    return false
end

function Permissions.requirePermission(playerId, permission)
    if not Permissions.hasPermission(playerId, permission) then
        TriggerClientEvent('chat:addMessage', playerId, {
            color = {255, 0, 0},
            multiline = true,
            args = {'System', 'You do not have permission to use this command.'}
        })
        return false
    end
    
    return true
end

-- Usage in commands
RegisterCommand('spawnvehicle', function(source, args)
    if not Permissions.requirePermission(source, 'vehicle.spawn') then
        return
    end
    
    -- Command implementation
end, false)
```

### Rate Limiting

```lua
-- ✅ Good: Rate limiting for events
local rateLimits = {}
local RATE_LIMIT_WINDOW = 60000 -- 1 minute
local MAX_REQUESTS = 10

local function isRateLimited(playerId, eventName)
    local key = playerId .. ':' .. eventName
    local now = GetGameTimer()
    
    if not rateLimits[key] then
        rateLimits[key] = {count = 0, resetTime = now + RATE_LIMIT_WINDOW}
    end
    
    local limit = rateLimits[key]
    
    -- Reset if window expired
    if now >= limit.resetTime then
        limit.count = 0
        limit.resetTime = now + RATE_LIMIT_WINDOW
    end
    
    limit.count = limit.count + 1
    
    if limit.count > MAX_REQUESTS then
        print(string.format('Rate limit exceeded for player %d on event %s', playerId, eventName))
        return true
    end
    
    return false
end

RegisterNetEvent('vehicle:spawn')
AddEventHandler('vehicle:spawn', function(vehicleModel, coords)
    local source = source
    
    if isRateLimited(source, 'vehicle:spawn') then
        return
    end
    
    -- Process event
end)
```

### Data Sanitization

```lua
-- ✅ Good: Data sanitization
local function sanitizeString(input, maxLength)
    if type(input) ~= 'string' then
        return ''
    end
    
    -- Remove potentially dangerous characters
    input = string.gsub(input, '[<>"\'\\/]', '')
    
    -- Limit length
    if maxLength and #input > maxLength then
        input = string.sub(input, 1, maxLength)
    end
    
    -- Trim whitespace
    input = string.match(input, '^%s*(.-)%s*$')
    
    return input
end

local function sanitizeNumber(input, min, max)
    local num = tonumber(input)
    
    if not num then
        return nil
    end
    
    if min and num < min then
        num = min
    end
    
    if max and num > max then
        num = max
    end
    
    return num
end

-- Usage
RegisterNetEvent('player:updateName')
AddEventHandler('player:updateName', function(newName)
    local source = source
    local sanitizedName = sanitizeString(newName, 32)
    
    if #sanitizedName < 3 then
        TriggerClientEvent('notification', source, 'Name must be at least 3 characters long')
        return
    end
    
    -- Update player name
end)
```

## Error Handling

### Graceful Error Handling

```lua
-- ✅ Good: Comprehensive error handling
local function safeExecute(func, errorMessage, ...)
    local success, result = pcall(func, ...)
    
    if not success then
        print(string.format('^1[ERROR] %s: %s^7', errorMessage or 'Unknown error', result))
        return nil, result
    end
    
    return result
end

local function spawnVehicle(playerId, model, coords)
    local result, error = safeExecute(function()
        local hash = GetHashKey(model)
        
        if not IsModelInCdimage(hash) then
            error('Invalid vehicle model: ' .. model)
        end
        
        RequestModel(hash)
        
        local timeout = 0
        while not HasModelLoaded(hash) and timeout < 5000 do
            Wait(100)
            timeout = timeout + 100
        end
        
        if not HasModelLoaded(hash) then
            error('Failed to load vehicle model: ' .. model)
        end
        
        local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, 0.0, true, false)
        
        if not DoesEntityExist(vehicle) then
            error('Failed to create vehicle')
        end
        
        SetModelAsNoLongerNeeded(hash)
        return vehicle
    end, 'Vehicle spawn failed')
    
    if not result then
        TriggerClientEvent('notification', playerId, 'Failed to spawn vehicle: ' .. (error or 'Unknown error'))
        return nil
    end
    
    return result
end
```

### Logging System

```lua
-- ✅ Good: Structured logging system
local Logger = {}
Logger.__index = Logger

local LOG_LEVELS = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
    FATAL = 5
}

local CURRENT_LOG_LEVEL = LOG_LEVELS.INFO

function Logger.new(component)
    local self = setmetatable({}, Logger)
    self.component = component or 'Unknown'
    return self
end

function Logger:log(level, message, data)
    if LOG_LEVELS[level] < CURRENT_LOG_LEVEL then
        return
    end
    
    local timestamp = os.date('%Y-%m-%d %H:%M:%S')
    local logEntry = {
        timestamp = timestamp,
        level = level,
        component = self.component,
        message = message,
        data = data
    }
    
    -- Format for console
    local consoleMessage = string.format('[%s] [%s] [%s] %s',
        timestamp,
        level,
        self.component,
        message
    )
    
    if data then
        consoleMessage = consoleMessage .. ' | Data: ' .. json.encode(data)
    end
    
    print(consoleMessage)
    
    -- Optional: Send to external logging service
    if level == 'ERROR' or level == 'FATAL' then
        self:sendToExternalLogger(logEntry)
    end
end

function Logger:debug(message, data)
    self:log('DEBUG', message, data)
end

function Logger:info(message, data)
    self:log('INFO', message, data)
end

function Logger:warn(message, data)
    self:log('WARN', message, data)
end

function Logger:error(message, data)
    self:log('ERROR', message, data)
end

function Logger:fatal(message, data)
    self:log('FATAL', message, data)
end

function Logger:sendToExternalLogger(logEntry)
    -- Implement external logging (webhook, file, database)
end

-- Usage
local logger = Logger.new('VehicleManager')
logger:info('Vehicle spawned successfully', {playerId = source, model = model})
logger:error('Failed to spawn vehicle', {playerId = source, error = errorMessage})
```

## Documentation Standards

### Code Comments

```lua
-- ✅ Good: Clear and helpful comments

---@class VehicleManager
---@field vehicles table<number, Vehicle> Active vehicles by entity ID
---@field playerVehicles table<number, number[]> Player vehicles by player ID
local VehicleManager = {}
VehicleManager.__index = VehicleManager

---Creates a new VehicleManager instance
---@return VehicleManager
function VehicleManager.new()
    local self = setmetatable({}, VehicleManager)
    self.vehicles = {}
    self.playerVehicles = {}
    return self
end

---Spawns a vehicle for a player
---@param playerId number The player's server ID
---@param model string The vehicle model name
---@param coords vector3 The spawn coordinates
---@param heading number The spawn heading (optional)
---@return number|nil vehicleId The spawned vehicle ID or nil if failed
function VehicleManager:spawnVehicle(playerId, model, coords, heading)
    heading = heading or 0.0
    
    -- Validate input parameters
    if not self:validateSpawnRequest(playerId, model, coords) then
        return nil
    end
    
    -- Check player vehicle limit
    local playerVehicleCount = #(self.playerVehicles[playerId] or {})
    if playerVehicleCount >= Config.maxVehiclesPerPlayer then
        self:notifyPlayer(playerId, 'Vehicle limit reached')
        return nil
    end
    
    -- Spawn the vehicle
    local vehicleId = self:createVehicle(model, coords, heading)
    if not vehicleId then
        return nil
    end
    
    -- Register vehicle
    self:registerVehicle(vehicleId, playerId)
    
    return vehicleId
end
```

### Function Documentation

```lua
-- ✅ Good: Comprehensive function documentation

---Calculates the distance between two 3D points
---@param pos1 vector3 First position
---@param pos2 vector3 Second position
---@return number distance The distance in game units
---@example
--- local dist = calculateDistance(
---     vector3(0, 0, 0),
---     vector3(100, 100, 0)
--- )
--- print(dist) -- Output: 141.42
local function calculateDistance(pos1, pos2)
    return math.sqrt(
        (pos1.x - pos2.x)^2 + 
        (pos1.y - pos2.y)^2 + 
        (pos1.z - pos2.z)^2
    )
end

---Formats a number as currency
---@param amount number The amount to format
---@param currency string The currency symbol (default: '$')
---@return string formatted The formatted currency string
---@throws Error if amount is not a number
local function formatCurrency(amount, currency)
    currency = currency or '$'
    
    if type(amount) ~= 'number' then
        error('Amount must be a number, got ' .. type(amount))
    end
    
    -- Format with commas
    local formatted = tostring(math.floor(amount))
    formatted = string.reverse(string.gsub(string.reverse(formatted), '(%d%d%d)', '%1,'))
    
    -- Remove leading comma if present
    if string.sub(formatted, 1, 1) == ',' then
        formatted = string.sub(formatted, 2)
    end
    
    return currency .. formatted
end
```

### README Documentation

```markdown
# Vehicle Manager Resource

A comprehensive vehicle management system for FiveM servers.

## Features

- ✅ Vehicle spawning with model validation
- ✅ Player vehicle limits and tracking
- ✅ Automatic cleanup and despawning
- ✅ Permission-based access control
- ✅ Comprehensive logging and error handling

## Installation

1. Download the resource
2. Extract to your `resources` folder
3. Add `ensure vehicle-manager` to your `server.cfg`
4. Configure settings in `config.lua`
5. Restart your server

## Configuration

```lua
Config.maxVehiclesPerPlayer = 3
Config.vehicleDespawnTime = 300000 -- 5 minutes
Config.allowedVehicleClasses = {0, 1, 2, 3, 4, 5, 6, 7}
```

## Commands

| Command | Description | Permission |
|---------|-------------|------------|
| `/spawnvehicle [model]` | Spawn a vehicle | `vehicle.spawn` |
| `/deletevehicle` | Delete nearest vehicle | `vehicle.delete` |
| `/listvehicles` | List your vehicles | None |

## API

### Server Exports

```lua
-- Spawn a vehicle for a player
local vehicleId = exports['vehicle-manager']:spawnVehicle(playerId, 'adder', coords)

-- Delete a player's vehicle
exports['vehicle-manager']:deleteVehicle(vehicleId)

-- Get player's vehicles
local vehicles = exports['vehicle-manager']:getPlayerVehicles(playerId)
```

## Events

### Client Events

- `vehicle:spawned` - Triggered when a vehicle is spawned
- `vehicle:deleted` - Triggered when a vehicle is deleted

### Server Events

- `vehicle:spawn` - Request to spawn a vehicle
- `vehicle:delete` - Request to delete a vehicle

## Support

For support, please create an issue on GitHub or join our Discord server.
```

## Version Control

### Git Best Practices

```bash
# ✅ Good: Descriptive commit messages
git commit -m "feat: add vehicle spawning with model validation"
git commit -m "fix: resolve memory leak in vehicle cleanup"
git commit -m "docs: update API documentation"
git commit -m "refactor: improve error handling in database module"

# ❌ Bad: Unclear commit messages
git commit -m "fix stuff"
git commit -m "update"
git commit -m "changes"
```

### Branching Strategy

```bash
# Main branches
main/master     # Production-ready code
develop         # Integration branch for features

# Feature branches
feature/vehicle-spawning
feature/player-management
feature/ui-improvements

# Release branches
release/v1.2.0

# Hotfix branches
hotfix/critical-bug-fix
```

### .gitignore Example

```gitignore
# FiveM specific
*.log
cache/
server-data/

# Configuration files with sensitive data
config_private.lua
database_config.lua

# Development files
.vscode/
*.tmp
*.bak

# Node.js (for NUI)
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
```

## Testing Strategies

### Unit Testing

```lua
-- tests/utils_test.lua
local Utils = require('shared.utils')

local function testFormatMoney()
    assert(Utils.formatMoney(1000) == '$1,000', 'Format money failed for 1000')
    assert(Utils.formatMoney(1234567) == '$1,234,567', 'Format money failed for 1234567')
    assert(Utils.formatMoney(0) == '$0', 'Format money failed for 0')
    print('✅ formatMoney tests passed')
end

local function testGetDistance()
    local pos1 = vector3(0, 0, 0)
    local pos2 = vector3(3, 4, 0)
    local distance = Utils.getDistance(pos1, pos2)
    assert(math.abs(distance - 5.0) < 0.01, 'Distance calculation failed')
    print('✅ getDistance tests passed')
end

-- Run tests
testFormatMoney()
testGetDistance()
print('All tests completed!')
```

### Integration Testing

```lua
-- tests/integration_test.lua
local function testVehicleSpawning()
    local testPlayerId = 1
    local testModel = 'adder'
    local testCoords = vector3(0, 0, 72)
    
    -- Test vehicle spawning
    local vehicleId = exports['vehicle-manager']:spawnVehicle(testPlayerId, testModel, testCoords)
    assert(vehicleId ~= nil, 'Vehicle spawning failed')
    assert(DoesEntityExist(vehicleId), 'Spawned vehicle does not exist')
    
    -- Test vehicle cleanup
    exports['vehicle-manager']:deleteVehicle(vehicleId)
    Wait(1000) -- Allow time for cleanup
    assert(not DoesEntityExist(vehicleId), 'Vehicle cleanup failed')
    
    print('✅ Vehicle spawning integration test passed')
end

-- Run integration tests
CreateThread(function()
    Wait(5000) -- Wait for resource to fully load
    testVehicleSpawning()
end)
```

## Deployment Guidelines

### Pre-deployment Checklist

```lua
-- deployment/checklist.lua
local DeploymentChecklist = {
    -- Code quality
    'All functions have proper error handling',
    'Input validation is implemented',
    'Rate limiting is in place for events',
    'Memory leaks have been checked',
    
    -- Security
    'No hardcoded credentials in code',
    'Permission system is implemented',
    'SQL injection prevention is in place',
    'Client-server communication is validated',
    
    -- Performance
    'Database queries are optimized',
    'Loops have appropriate wait times',
    'Resource usage is within acceptable limits',
    'Caching is implemented where appropriate',
    
    -- Documentation
    'README is up to date',
    'API documentation is complete',
    'Configuration options are documented',
    'Installation instructions are clear',
    
    -- Testing
    'Unit tests pass',
    'Integration tests pass',
    'Load testing has been performed',
    'Edge cases have been tested'
}

local function validateDeployment()
    print('Deployment Checklist:')
    for i, item in ipairs(DeploymentChecklist) do
        print(string.format('%d. [ ] %s', i, item))
    end
end

validateDeployment()
```

### Environment Configuration

```lua
-- config/environments.lua
local Environment = {}

local ENVIRONMENTS = {
    development = {
        debug = true,
        logLevel = 'DEBUG',
        database = {
            host = 'localhost',
            database = 'fivem_dev'
        },
        features = {
            enableAllCommands = true,
            skipPermissionChecks = true
        }
    },
    
    staging = {
        debug = true,
        logLevel = 'INFO',
        database = {
            host = 'staging-db.example.com',
            database = 'fivem_staging'
        },
        features = {
            enableAllCommands = false,
            skipPermissionChecks = false
        }
    },
    
    production = {
        debug = false,
        logLevel = 'WARN',
        database = {
            host = 'prod-db.example.com',
            database = 'fivem_prod'
        },
        features = {
            enableAllCommands = false,
            skipPermissionChecks = false
        }
    }
}

function Environment.get()
    local env = GetConvar('environment', 'development')
    return ENVIRONMENTS[env] or ENVIRONMENTS.development
end

function Environment.isDevelopment()
    return Environment.get().debug == true
end

function Environment.isProduction()
    local env = GetConvar('environment', 'development')
    return env == 'production'
end

return Environment
```

## Maintenance and Updates

### Update Strategy

```lua
-- maintenance/updater.lua
local Updater = {}

local CURRENT_VERSION = '1.2.0'
local UPDATE_CHECK_URL = 'https://api.github.com/repos/yourname/yourresource/releases/latest'

function Updater.checkForUpdates()
    if not Config.checkForUpdates then
        return
    end
    
    PerformHttpRequest(UPDATE_CHECK_URL, function(statusCode, response)
        if statusCode == 200 then
            local data = json.decode(response)
            local latestVersion = data.tag_name
            
            if Updater.isNewerVersion(latestVersion, CURRENT_VERSION) then
                print(string.format('^3[UPDATE] New version available: %s (current: %s)^7', 
                      latestVersion, CURRENT_VERSION))
                print('^3[UPDATE] Download: ' .. data.html_url .. '^7')
            end
        end
    end, 'GET')
end

function Updater.isNewerVersion(latest, current)
    local function parseVersion(version)
        local major, minor, patch = version:match('v?(%d+)%.(%d+)%.(%d+)')
        return tonumber(major) or 0, tonumber(minor) or 0, tonumber(patch) or 0
    end
    
    local latestMajor, latestMinor, latestPatch = parseVersion(latest)
    local currentMajor, currentMinor, currentPatch = parseVersion(current)
    
    if latestMajor > currentMajor then return true end
    if latestMajor < currentMajor then return false end
    
    if latestMinor > currentMinor then return true end
    if latestMinor < currentMinor then return false end
    
    return latestPatch > currentPatch
end

-- Check for updates on resource start
CreateThread(function()
    Wait(10000) -- Wait 10 seconds after start
    Updater.checkForUpdates()
end)
```

### Monitoring and Health Checks

```lua
-- maintenance/health_check.lua
local HealthCheck = {}

local healthMetrics = {
    resourceUptime = 0,
    memoryUsage = 0,
    activeConnections = 0,
    errorCount = 0,
    lastError = nil
}

function HealthCheck.start()
    CreateThread(function()
        local startTime = GetGameTimer()
        
        while true do
            Wait(30000) -- Check every 30 seconds
            
            -- Update metrics
            healthMetrics.resourceUptime = GetGameTimer() - startTime
            healthMetrics.memoryUsage = collectgarbage('count')
            healthMetrics.activeConnections = #GetPlayers()
            
            -- Check thresholds
            HealthCheck.checkThresholds()
            
            -- Optional: Send metrics to external monitoring
            HealthCheck.sendMetrics()
        end
    end)
end

function HealthCheck.checkThresholds()
    -- Memory usage check
    if healthMetrics.memoryUsage > 100 * 1024 then -- 100MB
        print('^3[HEALTH] High memory usage detected: ' .. 
              math.floor(healthMetrics.memoryUsage / 1024) .. 'MB^7')
    end
    
    -- Error rate check
    if healthMetrics.errorCount > 10 then
        print('^1[HEALTH] High error rate detected: ' .. healthMetrics.errorCount .. ' errors^7')
    end
end

function HealthCheck.recordError(error)
    healthMetrics.errorCount = healthMetrics.errorCount + 1
    healthMetrics.lastError = {
        message = error,
        timestamp = os.time()
    }
end

function HealthCheck.getStatus()
    return {
        status = 'healthy',
        uptime = healthMetrics.resourceUptime,
        memory = healthMetrics.memoryUsage,
        connections = healthMetrics.activeConnections,
        errors = healthMetrics.errorCount
    }
end

-- Start health monitoring
HealthCheck.start()
```

By following these best practices, you'll create maintainable, secure, and performant FiveM resources that are easy to debug, update, and scale. Remember that good practices are not just about writing code—they encompass the entire development lifecycle from planning to deployment and maintenance.