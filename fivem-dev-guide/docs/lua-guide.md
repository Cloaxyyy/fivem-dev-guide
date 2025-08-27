# Lua Development Guide for FiveM

This guide covers Lua programming specifically for FiveM development, including syntax, events, and best practices.

## 📚 Table of Contents

1. [Lua Basics](#lua-basics)
2. [FiveM-Specific Lua](#fivem-specific-lua)
3. [Events System](#events-system)
4. [Server vs Client Scripts](#server-vs-client-scripts)
5. [Common Patterns](#common-patterns)
6. [Best Practices](#best-practices)

## 🌙 Lua Basics

### Variables and Data Types
```lua
-- Variables (no declaration needed)
local playerName = "John Doe"        -- String
local playerId = 1                   -- Number
local isOnline = true                -- Boolean
local playerData = nil               -- Nil

-- Tables (arrays and objects)
local players = {"Alice", "Bob", "Charlie"}  -- Array
local player = {                     -- Object
    name = "John",
    id = 1,
    health = 100
}

-- Accessing table values
print(players[1])        -- "Alice" (1-indexed)
print(player.name)       -- "John"
print(player["name"])   -- "John" (alternative syntax)
```

### Functions
```lua
-- Basic function
function greetPlayer(name)
    return "Hello, " .. name .. "!"
end

-- Local function (recommended)
local function calculateDistance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

-- Anonymous function
local multiply = function(a, b)
    return a * b
end

-- Function with multiple returns
local function getPlayerInfo(playerId)
    local name = GetPlayerName(playerId)
    local ping = GetPlayerPing(playerId)
    return name, ping
end

local name, ping = getPlayerInfo(1)
```

### Control Structures
```lua
-- If statements
local health = GetEntityHealth(PlayerPedId())
if health > 100 then
    print("Player is healthy")
elseif health > 50 then
    print("Player is injured")
else
    print("Player is critical")
end

-- For loops
for i = 1, 10 do
    print("Number: " .. i)
end

-- For loops with tables
local weapons = {"pistol", "rifle", "shotgun"}
for index, weapon in ipairs(weapons) do
    print(index .. ": " .. weapon)
end

-- For loops with key-value pairs
local player = {name = "John", level = 5, money = 1000}
for key, value in pairs(player) do
    print(key .. ": " .. tostring(value))
end

-- While loop
local count = 0
while count < 5 do
    print("Count: " .. count)
    count = count + 1
end
```

### String Operations
```lua
-- String concatenation
local firstName = "John"
local lastName = "Doe"
local fullName = firstName .. " " .. lastName

-- String formatting
local message = string.format("Player %s has $%d", playerName, money)

-- String functions
local text = "Hello World"
print(string.len(text))        -- Length
print(string.upper(text))      -- "HELLO WORLD"
print(string.lower(text))      -- "hello world"
print(string.sub(text, 1, 5))  -- "Hello"
```

## 🎮 FiveM-Specific Lua

### Resource Manifest
```lua
-- fxmanifest.lua
fx_version 'cerulean'
game 'gta5'

author 'Your Name'
description 'Resource description'
version '1.0.0'

-- Dependencies
dependencies {
    'es_extended',  -- ESX framework
    'mysql-async'   -- Database
}

-- Server scripts
server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'config.lua',
    'server/*.lua'
}

-- Client scripts
client_scripts {
    'config.lua',
    'client/*.lua'
}

-- Shared scripts
shared_scripts {
    'shared/*.lua'
}

-- UI files
ui_page 'html/index.html'
files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}
```

### Configuration Files
```lua
-- config.lua (shared)
Config = {}

Config.Debug = true
Config.Locale = 'en'

Config.Vehicles = {
    {model = 'adder', label = 'Adder', price = 1000000},
    {model = 'zentorno', label = 'Zentorno', price = 725000},
    {model = 'osiris', label = 'Osiris', price = 1950000}
}

Config.Locations = {
    garage = {x = 215.124, y = -810.057, z = 30.727},
    shop = {x = -56.727, y = -1096.933, z = 26.422}
}

Config.Jobs = {
    police = {
        label = 'Police',
        grades = {
            {grade = 0, label = 'Cadet', salary = 500},
            {grade = 1, label = 'Officer', salary = 750},
            {grade = 2, label = 'Sergeant', salary = 1000}
        }
    }
}
```

### Native Functions
```lua
-- Player and Ped natives
local playerPed = PlayerPedId()                    -- Get player ped
local playerId = PlayerId()                        -- Get player ID
local playerCoords = GetEntityCoords(playerPed)    -- Get coordinates
local playerHeading = GetEntityHeading(playerPed)  -- Get heading

-- Vehicle natives
local vehicle = GetVehiclePedIsIn(playerPed, false)
if vehicle ~= 0 then
    local speed = GetEntitySpeed(vehicle)
    local model = GetEntityModel(vehicle)
    local displayName = GetDisplayNameFromVehicleModel(model)
end

-- World natives
local groundZ = 0.0
local found, z = GetGroundZFor_3dCoord(x, y, 1000.0, groundZ, false)

-- UI natives
SetNotificationTextEntry('STRING')
AddTextComponentString('Hello World!')
DrawNotification(false, false)
```

## 📡 Events System

### Server Events
```lua
-- server.lua

-- Register a server event
RegisterServerEvent('myresource:giveItem')
AddEventHandler('myresource:giveItem', function(itemName, amount)
    local source = source  -- Player who triggered the event
    local playerName = GetPlayerName(source)
    
    print(string.format("%s received %d %s", playerName, amount, itemName))
    
    -- Trigger client event back
    TriggerClientEvent('myresource:itemReceived', source, itemName, amount)
end)

-- Player connecting event
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source
    print(string.format("Player %s is connecting...", name))
end)

-- Player dropped event
AddEventHandler('playerDropped', function(reason)
    local source = source
    print(string.format("Player %s left: %s", GetPlayerName(source), reason))
end)
```

### Client Events
```lua
-- client.lua

-- Register a client event
RegisterNetEvent('myresource:itemReceived')
AddEventHandler('myresource:itemReceived', function(itemName, amount)
    -- Show notification
    SetNotificationTextEntry('STRING')
    AddTextComponentString(string.format('Received %d %s', amount, itemName))
    DrawNotification(false, false)
end)

-- Trigger server event
TriggerServerEvent('myresource:giveItem', 'bread', 5)

-- Game event handlers
AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkPlayerEnteredVehicle' then
        local player = args[1]
        local vehicle = args[2]
        print("Player entered vehicle")
    end
end)
```

### Event Best Practices
```lua
-- Use consistent naming convention
-- Format: resourcename:action or resourcename:category:action
RegisterServerEvent('garage:purchaseVehicle')
RegisterServerEvent('garage:vehicle:spawn')
RegisterServerEvent('garage:vehicle:store')

-- Validate data on server side
RegisterServerEvent('bank:withdraw')
AddEventHandler('bank:withdraw', function(amount)
    local source = source
    
    -- Validate input
    if type(amount) ~= 'number' or amount <= 0 then
        print("Invalid withdrawal amount from player " .. source)
        return
    end
    
    -- Process withdrawal
    -- ...
end)

-- Use callbacks for data requests
local function ServerCallback(name, cb, ...)
    TriggerServerEvent('myresource:serverCallback', name, ...)
    
    local function handler(result)
        cb(result)
        RemoveEventHandler('myresource:serverCallback:' .. name, handler)
    end
    
    AddEventHandler('myresource:serverCallback:' .. name, handler)
end
```

## 🔄 Server vs Client Scripts

### Server-Side Responsibilities
```lua
-- server.lua

-- Database operations
MySQL.Async.fetchAll('SELECT * FROM users WHERE identifier = @identifier', {
    ['@identifier'] = identifier
}, function(result)
    -- Handle database result
end)

-- Player data management
local playerData = {}

function getPlayerData(source)
    return playerData[source]
end

function setPlayerData(source, data)
    playerData[source] = data
end

-- Security validation
RegisterServerEvent('shop:buyItem')
AddEventHandler('shop:buyItem', function(itemName, price)
    local source = source
    local playerMoney = getPlayerMoney(source)
    
    if playerMoney >= price then
        removePlayerMoney(source, price)
        givePlayerItem(source, itemName)
    else
        TriggerClientEvent('chat:addMessage', source, {
            args = {'Shop', 'Not enough money!'}
        })
    end
end)
```

### Client-Side Responsibilities
```lua
-- client.lua

-- UI and visual effects
function showNotification(message)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(message)
    DrawNotification(false, false)
end

-- Input handling
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if IsControlJustPressed(0, 38) then -- E key
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            
            -- Check if near shop
            if GetDistanceBetweenCoords(coords, shopCoords, true) < 2.0 then
                TriggerServerEvent('shop:openMenu')
            end
        end
    end
end)

-- 3D text and markers
function drawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
end
```

## 🔧 Common Patterns

### Threading
```lua
-- Basic thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)  -- Wait 1 second
        print("Thread running...")
    end
end)

-- Conditional thread
local isNearShop = false

Citizen.CreateThread(function()
    while true do
        local wait = 1000
        
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local distance = GetDistanceBetweenCoords(coords, shopCoords, true)
        
        if distance < 10.0 then
            wait = 0
            isNearShop = distance < 2.0
            
            if isNearShop then
                drawText3D(shopCoords.x, shopCoords.y, shopCoords.z, "Press [E] to open shop")
            end
        else
            isNearShop = false
        end
        
        Citizen.Wait(wait)
    end
end)
```

### Error Handling
```lua
-- Using pcall for error handling
local function safeFunction()
    local success, result = pcall(function()
        -- Potentially dangerous code
        local data = json.decode(jsonString)
        return data
    end)
    
    if success then
        return result
    else
        print("Error: " .. tostring(result))
        return nil
    end
end

-- Validation functions
local function isValidCoords(coords)
    return coords and 
           type(coords.x) == 'number' and 
           type(coords.y) == 'number' and 
           type(coords.z) == 'number'
end

local function isValidPlayer(source)
    return source and GetPlayerName(source) ~= nil
end
```

### Utility Functions
```lua
-- Math utilities
local function round(num, decimals)
    local mult = 10^(decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- Table utilities
local function tableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

local function tableContains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- String utilities
local function split(str, delimiter)
    local result = {}
    local pattern = "([^" .. delimiter .. "]+)"
    for match in str:gmatch(pattern) do
        table.insert(result, match)
    end
    return result
end
```

## ✨ Best Practices

### Code Organization
```lua
-- Use local variables
local playerData = {}  -- Good
playerData = {}        -- Bad (global)

-- Group related functions
local PlayerManager = {}

function PlayerManager.getData(source)
    return playerData[source]
end

function PlayerManager.setData(source, data)
    playerData[source] = data
end

function PlayerManager.removeData(source)
    playerData[source] = nil
end
```

### Performance Tips
```lua
-- Cache frequently used values
local playerPed = PlayerPedId()  -- Cache outside loop
local coords = GetEntityCoords(playerPed)

-- Use appropriate wait times
Citizen.CreateThread(function()
    while true do
        local wait = 1000  -- Default wait
        
        -- Only reduce wait when necessary
        if isPlayerNearImportantArea() then
            wait = 0
            -- Do intensive operations
        end
        
        Citizen.Wait(wait)
    end
end)

-- Avoid unnecessary calculations
local distance = #(coords1 - coords2)  -- Fast distance (no square root)
local exactDistance = GetDistanceBetweenCoords(coords1, coords2, true)  -- Slower but exact
```

### Security Considerations
```lua
-- Always validate server events
RegisterServerEvent('bank:transfer')
AddEventHandler('bank:transfer', function(targetId, amount)
    local source = source
    
    -- Validate inputs
    if not targetId or not amount then return end
    if type(amount) ~= 'number' or amount <= 0 then return end
    if targetId == source then return end  -- Can't transfer to self
    
    -- Check if target player exists
    if GetPlayerName(targetId) == nil then return end
    
    -- Process transfer...
end)

-- Don't trust client data
-- Bad: Using client-provided coordinates for important operations
-- Good: Validate coordinates on server
local function isValidPosition(coords, allowedArea)
    local distance = #(coords - allowedArea.center)
    return distance <= allowedArea.radius
end
```

## 🔗 Next Steps

- Learn [JavaScript for FiveM](js-guide.md)
- Understand [Server vs Client Architecture](server-vs-client.md)
- Practice with [Example Scripts](../examples/)
- Read [Best Practices Guide](best-practices.md)

---

**Happy Lua coding!** 🌙