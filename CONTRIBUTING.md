# Contributing to FiveM Development Guide

Thank you for your interest in contributing to the FiveM Development Guide! This repository aims to be the most comprehensive and up-to-date resource for FiveM developers of all skill levels.

## Table of Contents

1. [How to Contribute](#how-to-contribute)
2. [Types of Contributions](#types-of-contributions)
3. [Contribution Guidelines](#contribution-guidelines)
4. [Code Standards](#code-standards)
5. [Documentation Standards](#documentation-standards)
6. [Example Script Guidelines](#example-script-guidelines)
7. [Submission Process](#submission-process)
8. [Review Process](#review-process)
9. [Community Guidelines](#community-guidelines)
10. [Recognition](#recognition)

## How to Contribute
   ```
1. **Make Your Changes**
   - Follow our coding standards
   - Test your code thoroughly
   - Update documentation as needed

2. **Submit a Pull Request**
   - Provide a clear description
   - Reference any related issues
   - Include screenshots if applicable

## Types of Contributions

### 📚 Documentation Improvements
- Fix typos, grammar, or formatting issues
- Add missing information or clarifications
- Improve existing tutorials and guides
- Translate content to other languages
- Add diagrams and visual aids

### 💻 Example Scripts
- Create new functional example scripts
- Improve existing examples
- Add comments and documentation
- Fix bugs in existing scripts
- Optimize performance

### 🎨 UI/NUI Examples
- HTML/CSS/JavaScript interface examples
- Modern UI frameworks integration
- Responsive design examples
- Accessibility improvements
- Interactive tutorials

### 🔧 Tools and Utilities
- Development tools and helpers
- Code generators and templates
- Testing utilities
- Build scripts and automation

### 🐛 Bug Reports
- Report issues with existing code
- Identify outdated information
- Document compatibility problems
- Suggest improvements

## Contribution Guidelines

### Before You Start

1. **Check Existing Issues**
   - Look for existing issues or discussions
   - Avoid duplicate contributions
   - Comment on issues you'd like to work on

2. **Discuss Major Changes**
   - Open an issue for significant additions
   - Get feedback before starting large projects
   - Ensure alignment with project goals

3. **Follow Project Structure**
   ```
   fivem-dev-guide/
   ├── docs/                 # Documentation files
   ├── examples/             # Example scripts
   │   ├── lua/             # Lua examples
   │   ├── javascript/      # JavaScript examples
   │   └── ui-examples/     # NUI examples
   ├── assets/              # Images, diagrams, configs
   └── tools/               # Development tools
   ```

### Quality Standards

- **Functionality**: All code must work on the latest FiveM server
- **Compatibility**: Test with common frameworks (ESX, QB-Core, etc.)
- **Performance**: Optimize for minimal resource usage
- **Security**: Follow security best practices
- **Documentation**: Include comprehensive comments and README files

## Code Standards

### Lua Code Standards

```lua
-- ✅ Good: Clear naming and structure
local VehicleManager = {}
VehicleManager.__index = VehicleManager

-- Constants in UPPER_CASE
local MAX_VEHICLES_PER_PLAYER = 5
local DEFAULT_SPAWN_COORDS = vector3(0.0, 0.0, 72.0)

-- Function documentation
---Spawns a vehicle for a player
---@param playerId number The player's server ID
---@param model string The vehicle model name
---@param coords vector3 The spawn coordinates
---@return number|nil vehicleId The spawned vehicle ID or nil if failed
function VehicleManager:spawnVehicle(playerId, model, coords)
    -- Input validation
    if not playerId or not GetPlayerName(playerId) then
        return nil
    end
    
    -- Implementation with error handling
    local success, result = pcall(function()
        return self:createVehicle(model, coords)
    end)
    
    if not success then
        print('^1[ERROR] Failed to spawn vehicle: ' .. result .. '^7')
        return nil
    end
    
    return result
end
```

### JavaScript Code Standards

```javascript
// ✅ Good: Modern JavaScript with proper structure
class VehicleSpawner {
    constructor() {
        this.vehicles = new Map();
        this.maxVehicles = 5;
        this.init();
    }

    /**
     * Initializes the vehicle spawner
     */
    init() {
        this.registerEvents();
        this.setupUI();
    }

    /**
     * Spawns a vehicle at the specified location
     * @param {string} model - Vehicle model name
     * @param {Object} coords - Spawn coordinates {x, y, z}
     * @returns {Promise<number|null>} Vehicle handle or null if failed
     */
    async spawnVehicle(model, coords) {
        try {
            // Validate input
            if (!model || !coords) {
                throw new Error('Invalid parameters');
            }

            // Request model
            const hash = GetHashKey(model);
            RequestModel(hash);

            // Wait for model to load
            while (!HasModelLoaded(hash)) {
                await this.delay(100);
            }

            // Create vehicle
            const vehicle = CreateVehicle(
                hash,
                coords.x,
                coords.y,
                coords.z,
                0.0,
                true,
                false
            );

            if (!DoesEntityExist(vehicle)) {
                throw new Error('Failed to create vehicle');
            }

            this.vehicles.set(vehicle, {
                model,
                coords,
                spawnTime: Date.now()
            });

            return vehicle;
        } catch (error) {
            console.error('Vehicle spawn failed:', error);
            return null;
        }
    }

    /**
     * Utility function for delays
     * @param {number} ms - Milliseconds to wait
     * @returns {Promise} Promise that resolves after delay
     */
    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = VehicleSpawner;
}
```

### HTML/CSS Standards

```html
<!-- ✅ Good: Semantic HTML with accessibility -->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Vehicle Spawner</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container" role="main">
        <header class="header">
            <h1>Vehicle Spawner</h1>
            <button class="close-btn" aria-label="Close menu">×</button>
        </header>
        
        <main class="content">
            <form class="vehicle-form" role="form">
                <div class="form-group">
                    <label for="vehicle-model">Vehicle Model:</label>
                    <input 
                        type="text" 
                        id="vehicle-model" 
                        name="model" 
                        placeholder="Enter vehicle model"
                        required
                        aria-describedby="model-help"
                    >
                    <small id="model-help">Enter a valid GTA V vehicle model name</small>
                </div>
                
                <button type="submit" class="spawn-btn">Spawn Vehicle</button>
            </form>
        </main>
    </div>
    
    <script src="script.js"></script>
</body>
</html>
```

```css
/* ✅ Good: Modern CSS with proper organization */
:root {
    --primary-color: #007bff;
    --secondary-color: #6c757d;
    --success-color: #28a745;
    --danger-color: #dc3545;
    --background-color: #1a1a1a;
    --text-color: #ffffff;
    --border-radius: 8px;
    --transition: all 0.3s ease;
}

* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    background-color: var(--background-color);
    color: var(--text-color);
    line-height: 1.6;
}

.container {
    max-width: 600px;
    margin: 0 auto;
    padding: 20px;
    background: rgba(255, 255, 255, 0.1);
    border-radius: var(--border-radius);
    backdrop-filter: blur(10px);
}

.header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
    padding-bottom: 15px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.2);
}

.close-btn {
    background: var(--danger-color);
    color: white;
    border: none;
    width: 30px;
    height: 30px;
    border-radius: 50%;
    cursor: pointer;
    transition: var(--transition);
}

.close-btn:hover {
    background: #c82333;
    transform: scale(1.1);
}

.form-group {
    margin-bottom: 20px;
}

label {
    display: block;
    margin-bottom: 5px;
    font-weight: 600;
}

input {
    width: 100%;
    padding: 12px;
    border: 1px solid rgba(255, 255, 255, 0.3);
    border-radius: var(--border-radius);
    background: rgba(255, 255, 255, 0.1);
    color: var(--text-color);
    transition: var(--transition);
}

input:focus {
    outline: none;
    border-color: var(--primary-color);
    box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.25);
}

.spawn-btn {
    width: 100%;
    padding: 12px;
    background: var(--primary-color);
    color: white;
    border: none;
    border-radius: var(--border-radius);
    font-size: 16px;
    font-weight: 600;
    cursor: pointer;
    transition: var(--transition);
}

.spawn-btn:hover {
    background: #0056b3;
    transform: translateY(-2px);
}

/* Responsive design */
@media (max-width: 768px) {
    .container {
        margin: 10px;
        padding: 15px;
    }
}
```

## Documentation Standards

### Markdown Guidelines

```markdown
# Title (H1 - Only one per document)

Brief description of what this document covers.

## Table of Contents

1. [Section 1](#section-1)
2. [Section 2](#section-2)
3. [Examples](#examples)

## Section 1

### Subsection (H3)

Content with proper formatting:

- Use bullet points for lists
- **Bold** for emphasis
- `code` for inline code
- [Links](https://example.com) for references

### Code Examples

```lua
-- Always include language specification
-- Add comments explaining the code
local function exampleFunction(parameter)
    -- Implementation details
    return result
end
```

### Important Notes

> **Note:** Use blockquotes for important information

> **Warning:** Use warnings for potential issues

### Tables

| Column 1 | Column 2 | Description |
|----------|----------|-------------|
| Value 1  | Value 2  | Explanation |

## Examples

Always provide working examples with:
1. Clear setup instructions
2. Expected output
3. Common troubleshooting tips
```

### README Template for Examples

```markdown
# Example Name

Brief description of what this example demonstrates.

## Features

- ✅ Feature 1
- ✅ Feature 2
- ✅ Feature 3

## Requirements

- FiveM Server (latest version)
- [Optional] Framework requirements
- [Optional] Database requirements

## Installation

1. Step-by-step installation
2. Configuration instructions
3. Testing procedures

## Usage

### Commands

| Command | Description | Permission |
|---------|-------------|------------|
| `/command` | Description | `permission.name` |

### Events

#### Client Events
- `event:name` - Description

#### Server Events
- `event:name` - Description

## Configuration

```lua
Config = {
    setting1 = true,
    setting2 = 'value'
}
```

## API

### Exports

```lua
-- Example usage
local result = exports['resource-name']:functionName(parameters)
```

## Troubleshooting

### Common Issues

**Issue:** Description of problem
**Solution:** How to fix it

## Support

For support, please:
1. Check the troubleshooting section
2. Search existing issues
3. Create a new issue with details
```

## Example Script Guidelines

### Script Requirements

1. **Functionality**
   - Must work on latest FiveM server
   - Include error handling
   - Optimize for performance
   - Test thoroughly

2. **Documentation**
   - Comprehensive comments
   - README file
   - Usage examples
   - Installation instructions

3. **Structure**
   ```
   example-name/
   ├── fxmanifest.lua
   ├── README.md
   ├── config.lua (if needed)
   ├── server/
   │   └── main.lua
   ├── client/
   │   └── main.lua
   └── shared/
       └── utils.lua
   ```

### fxmanifest.lua Template

```lua
fx_version 'cerulean'
game 'gta5'

author 'Your Name'
description 'Brief description of the script'
version '1.0.0'
url 'https://github.com/yourusername/repo'

-- Scripts
shared_scripts {
    'config.lua',
    'shared/*.lua'
}

server_scripts {
    'server/*.lua'
}

client_scripts {
    'client/*.lua'
}

-- UI (if applicable)
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

-- Dependencies (if any)
dependencies {
    'dependency-name'
}

-- Lua 5.4 compatibility
lua54 'yes'
```

### Example Categories

1. **Basic Examples**
   - Simple commands
   - Basic events
   - Player interactions
   - Vehicle operations

2. **Intermediate Examples**
   - Database integration
   - UI interfaces
   - Job systems
   - Economy features

3. **Advanced Examples**
   - Framework integration
   - Complex systems
   - Performance optimization
   - Security implementations

4. **NUI Examples**
   - Modern UI frameworks
   - Interactive interfaces
   - Responsive designs
   - Accessibility features

## Submission Process

### Pull Request Template

```markdown
## Description

Brief description of changes made.

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Example script
- [ ] Performance improvement

## Testing

- [ ] Tested on latest FiveM server
- [ ] Tested with common frameworks
- [ ] No console errors
- [ ] Performance impact assessed

## Checklist

- [ ] Code follows project standards
- [ ] Documentation is updated
- [ ] Comments are comprehensive
- [ ] No sensitive information included
- [ ] README file included (for examples)

## Additional Notes

[Any additional information]
```

### Commit Message Format

```bash
# Format: type(scope): description

# Types:
feat: new feature
fix: bug fix
docs: documentation changes
style: formatting changes
refactor: code refactoring
test: adding tests
chore: maintenance tasks

# Examples:
feat(examples): add vehicle spawner with UI
fix(docs): correct installation instructions
docs(lua): improve event handling guide
refactor(examples): optimize database queries
```

## Review Process

### Review Criteria

1. **Code Quality**
   - Follows coding standards
   - Proper error handling
   - Performance considerations
   - Security best practices

2. **Documentation**
   - Clear and comprehensive
   - Proper formatting
   - Accurate information
   - Helpful examples

3. **Testing**
   - Works as described
   - No breaking changes
   - Compatible with target versions
   - Performance impact acceptable

### Review Timeline

- **Initial Review**: Within 48 hours
- **Feedback Response**: Within 7 days
- **Final Approval**: Within 14 days

### Reviewer Guidelines

- Be constructive and helpful
- Provide specific feedback
- Suggest improvements
- Test thoroughly
- Approve when standards are met

## Community Guidelines

### Code of Conduct

1. **Be Respectful**
   - Treat all contributors with respect
   - Provide constructive feedback
   - Help newcomers learn

2. **Be Collaborative**
   - Work together on improvements
   - Share knowledge and resources
   - Credit others' contributions

3. **Be Professional**
   - Use appropriate language
   - Focus on technical merit
   - Avoid personal attacks

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and ideas
- **Pull Requests**: Code contributions and reviews
- **Discord**: Real-time community chat (if available)

### Getting Help

1. **Documentation**: Check existing guides first
2. **Search**: Look for similar issues or questions
3. **Ask**: Create an issue or discussion
4. **Community**: Engage with other contributors

## Recognition

### Contributor Recognition

- **Contributors List**: Added to README
- **Commit Attribution**: Proper git attribution
- **Special Thanks**: Recognition for significant contributions
- **Maintainer Status**: For consistent, high-quality contributions

### Contribution Types

- 📝 **Documentation**: Writing and improving docs
- 💻 **Code**: Example scripts and tools
- 🎨 **Design**: UI/UX improvements
- 🐛 **Bug Reports**: Finding and reporting issues
- 💡 **Ideas**: Suggesting improvements
- 🌍 **Translation**: Localizing content
- 📢 **Promotion**: Spreading the word

---

## Quick Start Checklist

- [ ] Read the contribution guidelines
- [ ] Fork the repository
- [ ] Create a feature branch
- [ ] Make your changes
- [ ] Test thoroughly
- [ ] Update documentation
- [ ] Submit a pull request
- [ ] Respond to feedback
- [ ] Celebrate your contribution! 🎉

---

**Thank you for contributing to the FiveM Development Guide!** Your contributions help make FiveM development more accessible and enjoyable for everyone. Together, we're building the most comprehensive resource for FiveM developers.

For questions about contributing, please open an issue or start a discussion. We're here to help! 🚀