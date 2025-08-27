# Getting Started with FiveM Development

Welcome to FiveM development! This guide will walk you through setting up your development environment and understanding the basics of FiveM scripting.

## 📋 Prerequisites

### Required Software
- **Text Editor**: [Visual Studio Code](https://code.visualstudio.com/) (recommended)
- **Git**: [Download Git](https://git-scm.com/) for version control

### Recommended VS Code Extensions
```
- Lua Language Server
- JavaScript (ES6) code snippets
- Bracket Pair Colorizer
- GitLens
- FiveM Natives (community extension)
```

### 1. Basic Server Configuration

Create a `server.cfg` file in your server directory:

```cfg
# Basic server configuration
endpoint_add_tcp "0.0.0.0:30120"
endpoint_add_udp "0.0.0.0:30120"

# Server info
sv_hostname "My FiveM Development Server"
sv_maxclients 32
sv_licensekey "your_license_key_here"

# Game settings
gamemode "freeroam"
mapname "Los Santos"

# Resources
ensure mapmanager
ensure chat
ensure spawnmanager
ensure sessionmanager
ensure basic-gamemode
ensure hardcap

# Your custom resources
ensure my-first-script
```

### 2. Get Your License Key
1. Visit [FiveM Keymaster](https://keymaster.fivem.net/)
2. Log in with your account
3. Generate a new server key
4. Replace `your_license_key_here` in server.cfg

## 📁 Understanding FiveM Folder Structure

```
FiveM-Server/
├── server.cfg              # Main server configuration
├── FXServer.exe            # Server executable
├── cache/                  # Server cache files
├── logs/                   # Server logs
└── resources/              # All your scripts go here
    ├── [essential]/        # Core FiveM resources
    ├── [local]/           # Your custom resources
    └── [maps]/            # Custom maps
```

### Resource Structure
Each resource (script) has its own folder:

```
resources/[local]/my-script/
├── fxmanifest.lua         # Resource manifest (required)
├── server.lua             # Server-side code
├── client.lua             # Client-side code
├── shared.lua             # Shared between server/client
└── html/                  # NUI files (optional)
    ├── index.html
    ├── style.css
    └── script.js
```

## 📝 Creating Your First Script

### 3. Create Resource Folder
```bash
mkdir resources/[local]/my-first-script
cd resources/[local]/my-first-script
```

### 2. Create fxmanifest.lua
```lua
fx_version 'cerulean'
game 'gta5'

author 'Your Name'
description 'My first FiveM script'
version '1.0.0'

-- Server scripts
server_scripts {
    'server.lua'
}

-- Client scripts
client_scripts {
    'client.lua'
}
```

### 4. Create server.lua
```lua
-- Server-side code
print("^2[My First Script] ^7Server started successfully!")

-- Register a command
RegisterCommand('hello', function(source, args, rawCommand)
    local playerName = GetPlayerName(source)
    print(string.format("^3%s ^7said hello!", playerName))
    
    -- Send message back to player
    TriggerClientEvent('chat:addMessage', source, {
        color = {255, 0, 0},
        multiline = true,
        args = {"Server", "Hello " .. playerName .. "!"}
    })
end, false)
```

### 5. Create client.lua
```lua
-- Client-side code
print("^2[My First Script] ^7Client started successfully!")

-- Register a key mapping
RegisterKeyMapping('greet', 'Say Hello', 'keyboard', 'F1')

-- Register the command
RegisterCommand('greet', function()
    -- Get player data
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Send notification
    SetNotificationTextEntry('STRING')
    AddTextComponentString('Hello from client!')
    DrawNotification(false, false)
    
    -- Print coordinates
    print(string.format("Player position: %.2f, %.2f, %.2f", 
        playerCoords.x, playerCoords.y, playerCoords.z))
end, false)
```

### 6. Add to server.cfg
Add this line to your `server.cfg`:
```cfg
ensure my-first-script
```

## 🔧 Development Tools

### Console Commands
```bash
# Start the server
./FXServer.exe +exec server.cfg

# Restart a resource
restart my-first-script

# Stop a resource
stop my-first-script

# Start a resource
start my-first-script

# Refresh resources list
refresh
```

### Useful Server Console Commands
```bash
# List all resources
list

# Show resource info
resource my-first-script

# Monitor resource performance
monitor

# Clear console
clear
```

## 🐛 Basic Debugging

### Print Statements
```lua
-- Server-side
print("^1[ERROR] ^7Something went wrong!")
print("^2[SUCCESS] ^7Everything is working!")
print("^3[WARNING] ^7Be careful!")
print("^5[INFO] ^7Just some info")

-- Client-side (appears in F8 console)
print("Client debug message")
```

### Color Codes
- `^0` - Black
- `^1` - Red
- `^2` - Green
- `^3` - Yellow
- `^4` - Blue
- `^5` - Cyan
- `^6` - Pink
- `^7` - White
- `^8` - Orange
- `^9` - Grey

### F8 Console (Client)
- Press `F8` in-game to open client console
- View client-side print statements
- Execute client commands
- Check for JavaScript errors

## 📚 Essential Concepts

### Server vs Client
- **Server**: Handles data, database operations, player management
- **Client**: Handles UI, player input, visual effects
- **Communication**: Use events to communicate between server and client

### Events
```lua
-- Server to Client
TriggerClientEvent('eventName', source, data)

-- Client to Server
TriggerServerEvent('eventName', data)

-- Listen for events
RegisterNetEvent('eventName')
AddEventHandler('eventName', function(data)
    -- Handle the event
end)
```

### Natives
- Pre-built functions provided by FiveM/GTA V
- Documentation: [FiveM Natives](https://docs.fivem.net/natives/)
- Examples: `GetPlayerPed()`, `GetEntityCoords()`, `SetEntityHealth()`

## 🎯 Next Steps

1. **Learn Lua**: Read our [Lua Guide](lua-guide.md)
2. **Understand Architecture**: Check [Server vs Client](server-vs-client.md)
3. **Try Examples**: Explore the [examples folder](../examples/)
4. **Join Community**: Connect with other developers

## 🔗 Useful Resources

- [FiveM Documentation](https://docs.fivem.net/)
- [FiveM Natives Reference](https://docs.fivem.net/natives/)
- [FiveM Forums](https://forum.fivem.net/)
- [FiveM Discord](https://discord.gg/fivem)
- [Lua 5.4 Reference](https://www.lua.org/manual/5.4/)

## ❓ Common Issues

### Resource Won't Start
1. Check `fxmanifest.lua` syntax
2. Ensure resource is in correct folder
3. Check server console for errors
4. Verify resource name in `server.cfg`

### Script Errors
1. Check syntax in Lua files
2. Verify event names match
3. Check server and client consoles
4. Use print statements for debugging

### Connection Issues
1. Check firewall settings
2. Verify port 30120 is open
3. Ensure license key is valid
4. Check server.cfg configuration

---

**Ready to start coding?** Continue with our [Lua Guide](lua-guide.md) to learn FiveM-specific Lua development!