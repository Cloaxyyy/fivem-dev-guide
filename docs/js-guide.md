# JavaScript Development Guide for FiveM

This guide covers JavaScript programming for FiveM development, including syntax, fxserver exports, and practical examples.

## 📚 Table of Contents

1. [JavaScript in FiveM](#javascript-in-fivem)
2. [Setting Up JavaScript Resources](#setting-up-javascript-resources)
3. [Basic JavaScript Syntax](#basic-javascript-syntax)
4. [FiveM JavaScript API](#fivem-javascript-api)
5. [Events and Networking](#events-and-networking)
6. [Working with Natives](#working-with-natives)
7. [Advanced Patterns](#advanced-patterns)
8. [Best Practices](#best-practices)

## ⚡ JavaScript in FiveM

### Why Use JavaScript?
- **Familiar Syntax**: Many developers already know JavaScript
- **Modern Features**: ES6+ support with async/await
- **Rich Ecosystem**: NPM packages and modern tooling
- **Type Safety**: TypeScript support available
- **Performance**: V8 engine provides excellent performance

### JavaScript vs Lua in FiveM
```javascript
// JavaScript - Modern syntax
const players = new Map();
const getPlayer = (id) => players.get(id);

// Async/await support
const fetchPlayerData = async (identifier) => {
    try {
        const result = await MySQL.query('SELECT * FROM users WHERE identifier = ?', [identifier]);
        return result[0];
    } catch (error) {
        console.error('Database error:', error);
        return null;
    }
};
```

```lua
-- Lua - Traditional approach
local players = {}
local function getPlayer(id)
    return players[id]
end

-- Callback-based
MySQL.Async.fetchAll('SELECT * FROM users WHERE identifier = @identifier', {
    ['@identifier'] = identifier
}, function(result)
    -- Handle result
end)
```

## 🚀 Setting Up JavaScript Resources

### Resource Manifest
```javascript
// fxmanifest.js
fx_version('cerulean');
game('gta5');

author('Your Name');
description('JavaScript FiveM Resource');
version('1.0.0');

// Server scripts
server_scripts([
    'server/main.js',
    'server/events.js',
    'server/database.js'
]);

// Client scripts
client_scripts([
    'client/main.js',
    'client/ui.js',
    'client/events.js'
]);

// Shared scripts
shared_scripts([
    'shared/config.js',
    'shared/utils.js'
]);

// Dependencies
dependencies([
    'mysql-async'
]);

// UI files
ui_page('html/index.html');
files([
    'html/index.html',
    'html/style.css',
    'html/script.js'
]);
```

### Package.json (Optional)
```json
{
  "name": "my-fivem-resource",
  "version": "1.0.0",
  "description": "FiveM JavaScript Resource",
  "main": "server/main.js",
  "scripts": {
    "dev": "nodemon --watch . --ext js --exec \"echo Resource updated\"",
    "lint": "eslint .",
    "format": "prettier --write ."
  },
  "devDependencies": {
    "@types/node": "^18.0.0",
    "eslint": "^8.0.0",
    "prettier": "^2.0.0",
    "nodemon": "^2.0.0"
  }
}
```

## 📝 Basic JavaScript Syntax

### Variables and Constants
```javascript
// Modern variable declarations
const playerName = 'John Doe';        // Immutable
let playerId = 1;                     // Mutable
var oldStyle = 'avoid this';          // Avoid var

// Data types
const isOnline = true;                // Boolean
const playerData = null;              // Null
let undefinedVar;                     // Undefined
const playerCount = 42;               // Number
const serverName = 'My Server';       // String

// Objects and arrays
const player = {
    name: 'John',
    id: 1,
    health: 100,
    inventory: ['bread', 'water']
};

const players = ['Alice', 'Bob', 'Charlie'];
```

### Functions
```javascript
// Function declaration
function greetPlayer(name) {
    return `Hello, ${name}!`;
}

// Arrow functions (preferred)
const calculateDistance = (x1, y1, x2, y2) => {
    const dx = x2 - x1;
    const dy = y2 - y1;
    return Math.sqrt(dx * dx + dy * dy);
};

// Short arrow function
const multiply = (a, b) => a * b;

// Async functions
const fetchPlayerData = async (playerId) => {
    try {
        const data = await someAsyncOperation(playerId);
        return data;
    } catch (error) {
        console.error('Error fetching player data:', error);
        throw error;
    }
};

// Higher-order functions
const players = ['Alice', 'Bob', 'Charlie'];
const upperCaseNames = players.map(name => name.toUpperCase());
const activePlayers = players.filter(name => isPlayerActive(name));
```

### Modern JavaScript Features
```javascript
// Destructuring
const player = { name: 'John', id: 1, health: 100 };
const { name, health } = player;
const [first, second] = ['Alice', 'Bob'];

// Spread operator
const newPlayer = { ...player, level: 5 };
const allPlayers = [...onlinePlayers, ...offlinePlayers];

// Template literals
const message = `Player ${name} has ${health} health`;

// Optional chaining
const playerName = player?.profile?.name ?? 'Unknown';

// Nullish coalescing
const defaultHealth = player.health ?? 100;

// Array methods
const playerIds = players.map(p => p.id);
const highLevelPlayers = players.filter(p => p.level > 10);
const totalHealth = players.reduce((sum, p) => sum + p.health, 0);
```

## 🎮 FiveM JavaScript API

### Global Functions
```javascript
// Resource management
const resourceName = GetCurrentResourceName();
const isResourceStarted = GetResourceState('es_extended') === 'started';

// Exports
exports('getPlayerData', (playerId) => {
    return playerDatabase.get(playerId);
});

// Using exports from other resources
const ESX = exports['es_extended'].getSharedObject();
const playerMoney = exports['bank'].getPlayerMoney(playerId);

// Console output
console.log('Server started successfully');
console.error('An error occurred:', error);
console.warn('Warning: deprecated function used');
```

### Server-Side API
```javascript
// server/main.js

// Player management
const getPlayerName = (source) => GetPlayerName(source);
const getPlayerIdentifiers = (source) => {
    const identifiers = {};
    for (let i = 0; i < GetNumPlayerIdentifiers(source); i++) {
        const identifier = GetPlayerIdentifier(source, i);
        const [type, value] = identifier.split(':');
        identifiers[type] = value;
    }
    return identifiers;
};

// Commands
RegisterCommand('heal', (source, args) => {
    const playerPed = GetPlayerPed(source);
    SetEntityHealth(playerPed, 200);
    
    emitNet('chat:addMessage', source, {
        color: [0, 255, 0],
        multiline: true,
        args: ['Server', 'You have been healed!']
    });
}, false);

// HTTP requests
const makeHttpRequest = (url, options = {}) => {
    return new Promise((resolve, reject) => {
        PerformHttpRequest(url, (errorCode, resultData, resultHeaders) => {
            if (errorCode === 200) {
                resolve({ data: resultData, headers: resultHeaders });
            } else {
                reject(new Error(`HTTP ${errorCode}`));
            }
        }, 'GET', '', options);
    });
};
```

### Client-Side API
```javascript
// client/main.js

// Player and world
const getPlayerData = () => {
    const playerPed = PlayerPedId();
    const playerId = PlayerId();
    const coords = GetEntityCoords(playerPed, false);
    const heading = GetEntityHeading(playerPed);
    
    return { playerPed, playerId, coords, heading };
};

// Vehicle operations
const spawnVehicle = async (model, coords, heading = 0.0) => {
    const modelHash = GetHashKey(model);
    
    if (!IsModelInCdimage(modelHash) || !IsModelAVehicle(modelHash)) {
        throw new Error(`Invalid vehicle model: ${model}`);
    }
    
    RequestModel(modelHash);
    
    while (!HasModelLoaded(modelHash)) {
        await new Promise(resolve => setTimeout(resolve, 10));
    }
    
    const vehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, heading, true, false);
    SetModelAsNoLongerNeeded(modelHash);
    
    return vehicle;
};

// UI operations
const showNotification = (message, type = 'info') => {
    SetNotificationTextEntry('STRING');
    AddTextComponentString(message);
    DrawNotification(false, false);
};

const showHelpText = (message) => {
    BeginTextCommandDisplayHelp('STRING');
    AddTextComponentSubstringPlayerName(message);
    EndTextCommandDisplayHelp(0, false, true, -1);
};
```

## 📡 Events and Networking

### Server Events
```javascript
// server/events.js

// Register server events
onNet('playerRequestVehicle', (model, coords) => {
    const source = global.source;
    const playerName = GetPlayerName(source);
    
    console.log(`${playerName} requested vehicle: ${model}`);
    
    // Validate request
    if (!isValidVehicleModel(model)) {
        emitNet('vehicleSpawnError', source, 'Invalid vehicle model');
        return;
    }
    
    // Spawn vehicle
    emitNet('spawnVehicleClient', source, model, coords);
});

// Player events
on('playerConnecting', (name, setKickReason, deferrals) => {
    const source = global.source;
    console.log(`Player ${name} is connecting...`);
    
    // Async connection handling
    deferrals.defer();
    
    setTimeout(() => {
        deferrals.done();
    }, 1000);
});

on('playerDropped', (reason) => {
    const source = global.source;
    const playerName = GetPlayerName(source);
    console.log(`Player ${playerName} left: ${reason}`);
    
    // Cleanup player data
    cleanupPlayerData(source);
});
```

### Client Events
```javascript
// client/events.js

// Register client events
onNet('spawnVehicleClient', async (model, coords) => {
    try {
        const vehicle = await spawnVehicle(model, coords);
        const playerPed = PlayerPedId();
        
        TaskWarpPedIntoVehicle(playerPed, vehicle, -1);
        showNotification(`Spawned ${model}`, 'success');
    } catch (error) {
        console.error('Failed to spawn vehicle:', error);
        showNotification('Failed to spawn vehicle', 'error');
    }
});

onNet('vehicleSpawnError', (message) => {
    showNotification(message, 'error');
});

// Game events
on('gameEventTriggered', (name, args) => {
    switch (name) {
        case 'CEventNetworkPlayerEnteredVehicle':
            const [player, vehicle] = args;
            console.log('Player entered vehicle');
            break;
            
        case 'CEventNetworkPlayerLeftVehicle':
            console.log('Player left vehicle');
            break;
    }
});
```

### Event Utilities
```javascript
// shared/events.js

// Event emitter class
class EventEmitter {
    constructor() {
        this.events = new Map();
    }
    
    on(event, callback) {
        if (!this.events.has(event)) {
            this.events.set(event, []);
        }
        this.events.get(event).push(callback);
    }
    
    emit(event, ...args) {
        const callbacks = this.events.get(event);
        if (callbacks) {
            callbacks.forEach(callback => callback(...args));
        }
    }
    
    off(event, callback) {
        const callbacks = this.events.get(event);
        if (callbacks) {
            const index = callbacks.indexOf(callback);
            if (index > -1) {
                callbacks.splice(index, 1);
            }
        }
    }
}

// Server callback system
const serverCallbacks = new Map();
let callbackId = 0;

const triggerServerCallback = (name, callback, ...args) => {
    const id = callbackId++;
    serverCallbacks.set(id, callback);
    
    emitNet('serverCallback', name, id, ...args);
    
    // Timeout after 10 seconds
    setTimeout(() => {
        if (serverCallbacks.has(id)) {
            serverCallbacks.delete(id);
            callback(null, 'Callback timeout');
        }
    }, 10000);
};

onNet('serverCallbackResponse', (id, result, error) => {
    const callback = serverCallbacks.get(id);
    if (callback) {
        serverCallbacks.delete(id);
        callback(result, error);
    }
});
```

## 🔧 Working with Natives

### Native Function Patterns
```javascript
// Async native wrapper
const requestModel = async (model) => {
    const modelHash = typeof model === 'string' ? GetHashKey(model) : model;
    
    if (HasModelLoaded(modelHash)) {
        return modelHash;
    }
    
    RequestModel(modelHash);
    
    return new Promise((resolve, reject) => {
        const timeout = setTimeout(() => {
            reject(new Error(`Model ${model} failed to load`));
        }, 10000);
        
        const checkLoaded = () => {
            if (HasModelLoaded(modelHash)) {
                clearTimeout(timeout);
                resolve(modelHash);
            } else {
                setTimeout(checkLoaded, 10);
            }
        };
        
        checkLoaded();
    });
};

// Native with error handling
const safeGetEntityCoords = (entity) => {
    if (!DoesEntityExist(entity)) {
        throw new Error('Entity does not exist');
    }
    
    const coords = GetEntityCoords(entity, false);
    return { x: coords[0], y: coords[1], z: coords[2] };
};

// Batch native operations
const getVehicleInfo = (vehicle) => {
    if (!DoesEntityExist(vehicle)) {
        return null;
    }
    
    return {
        model: GetEntityModel(vehicle),
        coords: safeGetEntityCoords(vehicle),
        heading: GetEntityHeading(vehicle),
        speed: GetEntitySpeed(vehicle),
        health: GetVehicleEngineHealth(vehicle),
        plate: GetVehicleNumberPlateText(vehicle).trim()
    };
};
```

### Threading and Timing
```javascript
// Modern threading with async/await
const mainLoop = async () => {
    while (true) {
        await new Promise(resolve => setTimeout(resolve, 0)); // Wait one frame
        
        const playerPed = PlayerPedId();
        const coords = GetEntityCoords(playerPed, false);
        
        // Check for nearby interactions
        checkNearbyInteractions(coords);
    }
};

// Start the loop
mainLoop().catch(console.error);

// Interval-based operations
setInterval(() => {
    // Update player data every 5 seconds
    updatePlayerData();
}, 5000);

// Conditional threading
let isNearShop = false;

const shopCheckLoop = async () => {
    while (true) {
        const wait = isNearShop ? 0 : 1000;
        
        const playerPed = PlayerPedId();
        const coords = GetEntityCoords(playerPed, false);
        const distance = GetDistanceBetweenCoords(coords[0], coords[1], coords[2], 
                                                 shopCoords.x, shopCoords.y, shopCoords.z, true);
        
        isNearShop = distance < 2.0;
        
        if (isNearShop) {
            showHelpText('Press [E] to open shop');
            
            if (IsControlJustPressed(0, 38)) { // E key
                emitNet('shop:open');
            }
        }
        
        await new Promise(resolve => setTimeout(resolve, wait));
    }
};

shopCheckLoop().catch(console.error);
```

## 🏗️ Advanced Patterns

### Class-Based Architecture
```javascript
// Player class
class Player {
    constructor(source) {
        this.source = source;
        this.name = GetPlayerName(source);
        this.identifiers = this.getIdentifiers();
        this.data = new Map();
    }
    
    getIdentifiers() {
        const identifiers = {};
        for (let i = 0; i < GetNumPlayerIdentifiers(this.source); i++) {
            const identifier = GetPlayerIdentifier(this.source, i);
            const [type, value] = identifier.split(':');
            identifiers[type] = value;
        }
        return identifiers;
    }
    
    async loadData() {
        try {
            const result = await MySQL.query(
                'SELECT * FROM users WHERE identifier = ?',
                [this.identifiers.license]
            );
            
            if (result.length > 0) {
                this.data = new Map(Object.entries(result[0]));
            } else {
                await this.createData();
            }
        } catch (error) {
            console.error(`Failed to load data for ${this.name}:`, error);
        }
    }
    
    async saveData() {
        try {
            const data = Object.fromEntries(this.data);
            await MySQL.query(
                'UPDATE users SET ? WHERE identifier = ?',
                [data, this.identifiers.license]
            );
        } catch (error) {
            console.error(`Failed to save data for ${this.name}:`, error);
        }
    }
    
    get(key) {
        return this.data.get(key);
    }
    
    set(key, value) {
        this.data.set(key, value);
    }
    
    kick(reason = 'No reason provided') {
        DropPlayer(this.source, reason);
    }
    
    notify(message, type = 'info') {
        emitNet('notification:show', this.source, message, type);
    }
}

// Player manager
class PlayerManager {
    constructor() {
        this.players = new Map();
        this.setupEvents();
    }
    
    setupEvents() {
        on('playerConnecting', async (name, setKickReason, deferrals) => {
            const source = global.source;
            deferrals.defer();
            
            try {
                const player = new Player(source);
                await player.loadData();
                
                this.players.set(source, player);
                deferrals.done();
                
                console.log(`Player ${name} connected successfully`);
            } catch (error) {
                console.error(`Failed to load player ${name}:`, error);
                deferrals.done('Failed to load player data');
            }
        });
        
        on('playerDropped', async (reason) => {
            const source = global.source;
            const player = this.players.get(source);
            
            if (player) {
                await player.saveData();
                this.players.delete(source);
                console.log(`Player ${player.name} disconnected: ${reason}`);
            }
        });
    }
    
    getPlayer(source) {
        return this.players.get(source);
    }
    
    getAllPlayers() {
        return Array.from(this.players.values());
    }
    
    getPlayerCount() {
        return this.players.size;
    }
}

// Initialize player manager
const playerManager = new PlayerManager();

// Export for other scripts
exports('getPlayer', (source) => playerManager.getPlayer(source));
exports('getAllPlayers', () => playerManager.getAllPlayers());
```

### Database Integration
```javascript
// Database wrapper class
class Database {
    static async query(sql, params = []) {
        return new Promise((resolve, reject) => {
            MySQL.Async.mysql_execute(sql, params, (result) => {
                if (result) {
                    resolve(result);
                } else {
                    reject(new Error('Database query failed'));
                }
            });
        });
    }
    
    static async fetchAll(sql, params = []) {
        return new Promise((resolve, reject) => {
            MySQL.Async.mysql_fetch_all(sql, params, (result) => {
                resolve(result || []);
            });
        });
    }
    
    static async fetchScalar(sql, params = []) {
        return new Promise((resolve, reject) => {
            MySQL.Async.mysql_fetch_scalar(sql, params, (result) => {
                resolve(result);
            });
        });
    }
    
    static async insert(table, data) {
        const keys = Object.keys(data);
        const values = Object.values(data);
        const placeholders = keys.map(() => '?').join(', ');
        
        const sql = `INSERT INTO ${table} (${keys.join(', ')}) VALUES (${placeholders})`;
        return this.query(sql, values);
    }
    
    static async update(table, data, where, whereParams = []) {
        const updates = Object.keys(data).map(key => `${key} = ?`).join(', ');
        const values = [...Object.values(data), ...whereParams];
        
        const sql = `UPDATE ${table} SET ${updates} WHERE ${where}`;
        return this.query(sql, values);
    }
    
    static async delete(table, where, whereParams = []) {
        const sql = `DELETE FROM ${table} WHERE ${where}`;
        return this.query(sql, whereParams);
    }
}

// Usage example
const savePlayerData = async (identifier, data) => {
    try {
        await Database.update('users', data, 'identifier = ?', [identifier]);
        console.log('Player data saved successfully');
    } catch (error) {
        console.error('Failed to save player data:', error);
    }
};
```

## ✨ Best Practices

### Code Organization
```javascript
// Use modules and exports
// utils.js
export const formatMoney = (amount) => {
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD'
    }).format(amount);
};

export const getDistance = (pos1, pos2) => {
    const dx = pos1.x - pos2.x;
    const dy = pos1.y - pos2.y;
    const dz = pos1.z - pos2.z;
    return Math.sqrt(dx * dx + dy * dy + dz * dz);
};

// main.js
import { formatMoney, getDistance } from './utils.js';

// Use constants for configuration
const CONFIG = {
    MAX_PLAYERS: 32,
    SAVE_INTERVAL: 300000, // 5 minutes
    DEFAULT_SPAWN: { x: 0, y: 0, z: 72 }
};

// Use enums for states
const PlayerState = {
    CONNECTING: 'connecting',
    ACTIVE: 'active',
    AFK: 'afk',
    DISCONNECTING: 'disconnecting'
};
```

### Error Handling
```javascript
// Global error handler
process.on('unhandledRejection', (reason, promise) => {
    console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

process.on('uncaughtException', (error) => {
    console.error('Uncaught Exception:', error);
});

// Try-catch with async/await
const safeAsyncOperation = async (operation) => {
    try {
        const result = await operation();
        return { success: true, data: result };
    } catch (error) {
        console.error('Operation failed:', error);
        return { success: false, error: error.message };
    }
};

// Validation functions
const validatePlayer = (source) => {
    if (!source || typeof source !== 'number') {
        throw new Error('Invalid player source');
    }
    
    if (!GetPlayerName(source)) {
        throw new Error('Player not found');
    }
    
    return true;
};

const validateCoords = (coords) => {
    if (!coords || typeof coords !== 'object') {
        throw new Error('Invalid coordinates object');
    }
    
    const { x, y, z } = coords;
    if (typeof x !== 'number' || typeof y !== 'number' || typeof z !== 'number') {
        throw new Error('Coordinates must be numbers');
    }
    
    return true;
};
```

### Performance Optimization
```javascript
// Debounce function
const debounce = (func, wait) => {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
};

// Throttle function
const throttle = (func, limit) => {
    let inThrottle;
    return function(...args) {
        if (!inThrottle) {
            func.apply(this, args);
            inThrottle = true;
            setTimeout(() => inThrottle = false, limit);
        }
    };
};

// Cache frequently accessed data
const cache = new Map();
const CACHE_TTL = 60000; // 1 minute

const getCachedData = (key, fetchFunction) => {
    const cached = cache.get(key);
    
    if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
        return cached.data;
    }
    
    const data = fetchFunction();
    cache.set(key, { data, timestamp: Date.now() });
    
    return data;
};

// Batch operations
const batchPlayerUpdates = (() => {
    const updates = new Map();
    let timeoutId = null;
    
    const processBatch = async () => {
        if (updates.size === 0) return;
        
        const batch = Array.from(updates.entries());
        updates.clear();
        
        try {
            await Database.transaction(async (trx) => {
                for (const [playerId, data] of batch) {
                    await trx('users').where('id', playerId).update(data);
                }
            });
        } catch (error) {
            console.error('Batch update failed:', error);
        }
    };
    
    return (playerId, data) => {
        updates.set(playerId, { ...updates.get(playerId), ...data });
        
        if (timeoutId) clearTimeout(timeoutId);
        timeoutId = setTimeout(processBatch, 1000);
    };
})();
```

## 🔗 Next Steps

- Learn about [Server vs Client Architecture](server-vs-client.md)
- Practice with [JavaScript Examples](../examples/vehicle-spawner.js)
- Read [Debugging Guide](debugging.md)
- Explore [Best Practices](best-practices.md)

---

**Happy JavaScript coding!** ⚡