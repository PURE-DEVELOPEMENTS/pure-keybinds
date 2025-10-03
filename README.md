# Pure Keybinds - RSG-Core Key Binding System

A comprehensive key binding system that allows players to save custom key combinations (LALT + KEY) that execute chat commands. Built for RedM using RSG-Core framework and MenuAPI.

## Features

- **Custom Key Bindings**: Players can bind LALT + any available key to execute chat commands
- **Database Storage**: All key binds are saved to the database using player CID
- **User-Friendly Menu**: Easy-to-use menu system with input fields for commands
- **Real-time Execution**: Key combinations work instantly when pressed
- **Management Tools**: Add, edit, remove, and clear all bindings
- **Admin Commands**: Server administrators can view and clear player bindings
- **Conflict Prevention**: System prevents duplicate key bindings per player

## Installation

### 1. Database Setup

Run the SQL commands from `keybinds.sql` in your database:

```sql
CREATE TABLE IF NOT EXISTS `player_keybinds` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(50) NOT NULL,
    `key_name` VARCHAR(20) NOT NULL,
    `command` TEXT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_citizen_key` (`citizenid`, `key_name`),
    INDEX `idx_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 2. Resource Setup

1. Download or clone this repository
2. Place the `pure-keybinds` folder in your server's `resources` directory
3. Ensure the folder structure is correct:
   ```
   pure-keybinds/
   ├── client/
   │   └── client.lua
   ├── server/
   │   └── server.lua
   ├── config.lua
   ├── fxmanifest.lua
   └── keybinds.sql
   ```

### 3. Server Configuration

Add the resource to your `server.cfg`:

```
ensure pure-keybinds
```

### 4. Dependencies

Make sure you have the following resources installed and running:

- `rsg-core` - Core framework
- `rsg-menubase` - Menu system
- `rsg-input` - Input handling
- `oxmysql` - Database handler

## Usage

### Player Commands

- `/keybinds` or `/kb` - Opens the key binding menu

### Key Binding Process

1. Use `/keybinds` to open the menu
2. Select "Add New Key Bind"
3. Choose an available key from the list
4. Enter the command you want to execute (without the `/`)
5. Save the binding

### Using Key Bindings

- Hold `LALT` and press your bound key to execute the command
- Example: If you bound `F1` to `me waves`, press `LALT + F1` to execute `/me waves`

### Managing Bindings

- **Edit**: Select an existing binding from the main menu to modify the command
- **Remove**: Use the edit menu to remove individual bindings
- **Clear All**: Remove all your key bindings at once

## Available Keys

The system supports the following keys for binding:

### Letters
A, B, C, D, E, F, G, H, I, J, L, M, N, O, P, Q, R, S, U, V, W, X, Z

### Numbers
1, 2, 3, 4, 5, 6, 7, 8

### Function Keys
F1, F4, F6

### Special Keys
RIGHTBRACKET, LEFTBRACKET

*Note: Some keys like K, T, Y are not included due to missing hash values in RedM*

## Admin Commands

### `/viewkeybinds [player_id]`
**Permission**: Admin
**Description**: View all key bindings for a specific player
**Usage**: `/viewkeybinds 1`

### `/clearkeybinds [player_id]`
**Permission**: Admin
**Description**: Remove all key bindings for a specific player
**Usage**: `/clearkeybinds 1`

## Configuration

Edit `config.lua` to customize the script:

```lua
Config = {
    ShowInfoHud = true,              -- Show info HUD
    ModifierKey = "LALT",            -- Modifier key (currently only LALT supported)
    Debug = false                     -- Enable debug logging
}
```

### Customizing Available Keys

To add or remove available keys, modify the `KEYS` table in `client/client.lua`:

```lua
local KEYS = {
    ["NEW_KEY"] = 0xYOURHASH,
    -- Add your custom keys here
}
```

### Changing Key Combination

To use a different modifier key instead of LALT, change the `LALT_KEY` variable in `client/client.lua`:

```lua
local LALT_KEY = 0x8AAA0AD4 -- Change this to your preferred key hash
```

## API Exports

The resource provides exports for other resources to interact with the key binding system:

```lua
-- Get all key binds for a player
local binds = exports['pure-keybinds']:GetPlayerKeyBinds(citizenid)

-- Add a key bind for a player
exports['pure-keybinds']:AddPlayerKeyBind(citizenid, 'F1', 'me waves')

-- Remove a specific key bind
exports['pure-keybinds']:RemovePlayerKeyBind(citizenid, 'F1')
```

## Security Features

- **Command Sanitization**: All commands are sanitized to remove dangerous characters
- **CID Validation**: Only authenticated players can save bindings
- **Unique Constraints**: Database prevents duplicate key bindings per player
- **Admin Oversight**: Administrators can monitor and manage player bindings

## Troubleshooting

### Common Issues

1. **Menu not opening**: Ensure MenuAPI is properly installed and running
2. **Key binds not saving**: Check database connection and table creation
3. **Commands not executing**: Verify RSG-Core is running and commands exist
4. **Keys not responding**: Make sure no other resources are conflicting with the key inputs

### Debug Information

Enable debugging in `config.lua` to see key binding activities:
- Binding creation/updates are logged
- Failed operations are reported
- Database errors are displayed

## Support

For issues, questions, or feature requests, please check:
1. Console logs for error messages
2. Database connection status
3. Resource dependencies
4. RedM key hash documentation

## Version History

- **v1.0.1**: Current version
- **v1.0.0**: Initial release with full key binding functionality

## Credits

- **Author**: DIGITALEN
- **Framework**: RSG-Core

## License

This resource is provided as-is for use with RSG-Core framework. Modify as needed for your server.
