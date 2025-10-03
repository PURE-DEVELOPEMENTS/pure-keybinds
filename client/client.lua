-- client.lua
local RSGCore = exports['rsg-core']:GetCoreObject()

-- Config for debugging (fallback if not loaded from shared)
Config = Config or { Debug = true }

-- Import MenuData from rsg-menubase
local MenuData = nil

-- Try different methods to get MenuData
Citizen.CreateThread(function()
    while not MenuData do
        Citizen.Wait(100)
        -- Try export method first
        if exports['rsg-menubase'] and exports['rsg-menubase'].GetMenuData then
            MenuData = exports['rsg-menubase']:GetMenuData()
            print("^2[KeyBind] MenuData loaded via export!")
        -- Try global variable
        elseif _G.MenuData then
            MenuData = _G.MenuData
            print("^2[KeyBind] MenuData loaded via global!")
        -- Try menuapi global
        elseif _G.menuapi then
            MenuData = _G.menuapi
            print("^2[KeyBind] MenuData loaded via menuapi!")
        end
    end
    print("^2[KeyBind] MenuData loaded successfully!")
end)

-- Key definitions for RedM
local KEYS = {
    -- Letters
    ["A"] = 0x7065027D, ["B"] = 0x4CC0E2FE, ["C"] = 0x9959A6F0, ["D"] = 0xB4E465B4,
    ["E"] = 0xCEFD9220, ["F"] = 0xB2F377E8, ["G"] = 0x760A9C6F, ["H"] = 0x24978A28,
    ["I"] = 0xC1989F95, ["J"] = 0xF3830D8E, ["L"] = 0x80F28E95, ["M"] = 0xE31C6A41,
    ["N"] = 0x4BC9DABB, ["O"] = 0xF1301666, ["P"] = 0xD82E0BD2, ["Q"] = 0xDE794E3E,
    ["R"] = 0xE30CD707, ["S"] = 0xD27782E3, ["U"] = 0xD8F73058, ["V"] = 0x7F8D09B8,
    ["W"] = 0x8FD015D8, ["X"] = 0x8CC9CD42, ["Z"] = 0x26E9DC00,
    -- Numbers
    ["1"] = 0xE6F612E4, ["2"] = 0x1CE6D9EB, ["3"] = 0x4F49CC4C, ["4"] = 0x8F9F9E58,
    ["5"] = 0xAB62E997, ["6"] = 0xA1FDE2A6, ["7"] = 0xB03A913B, ["8"] = 0x42385422,
    -- Function Keys
    ["F1"] = 0xA8E3F467, ["F4"] = 0x1F6D95E5, ["F6"] = 0x3C0A40F2,
    -- Special Keys
    ["RIGHTBRACKET"] = 0xA5BDCD3C, ["LEFTBRACKET"] = 0x430593AA
}

-- LALT key hash
local LALT_KEY = 0x8AAA0AD4

-- Player data
local PlayerData = {}
local playerKeyBinds = {}

-- Initialize player data
RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    PlayerData = RSGCore.Functions.GetPlayerData()
    print("^3[KeyBind] Player data loaded: citizenid = " .. (PlayerData.citizenid or "nil"))
    TriggerServerEvent('keybind:loadPlayerBinds')
end)

RegisterNetEvent('RSGCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    playerKeyBinds = {}
end)

-- Receive key binds from server
RegisterNetEvent('keybind:receivePlayerBinds', function(binds)
    print(string.format("^3[KeyBind] Received %d key binds from server", binds and #binds or 0))
    if binds == nil then
        print("^1[KeyBind] Warning: Received nil binds from server, initializing empty table")
        playerKeyBinds = {}
    else
        playerKeyBinds = binds or {}
        for i, bind in ipairs(playerKeyBinds) do
            print(string.format("^3[KeyBind] Bind %d: LALT + %s -> %s", i, bind.key, bind.command))
        end
    end
end)

-- Function to get key name from hash
local function getKeyNameFromHash(hash)
    for name, keyHash in pairs(KEYS) do
        if keyHash == hash then
            return name
        end
    end
    return "UNKNOWN"
end

-- Function to open main keybind menu
local function openKeybindMenu()
    print("^3[KeyBind] Opening keybind menu...")
    if not MenuData then
        print("^1[KeyBind] MenuData is nil!")
        RSGCore.Functions.Notify("Please wait for the system to initialize or relog!", "error")
        return
    end
    print("^3[KeyBind] MenuData is available, creating menu...")
    
    local menu = {
        title = "PURE KEYBINDS",
        elements = {
            { label = "Keybinds System", type = "label" }
        }
    }
    
    for i, bind in ipairs(playerKeyBinds) do
        local elementValue = "edit_" .. i
        print(string.format("^3[KeyBind] Creating menu element %d: %s -> %s", i, elementValue, bind.command))
        table.insert(menu.elements, {
            label = string.format("LALT + %s: %s", bind.key, bind.command),
            value = elementValue,
            type = "button"
        })
    end

    table.insert(menu.elements, { label = "Add New Keybind", value = "add_new", type = "button" })
    if #playerKeyBinds > 0 then
        table.insert(menu.elements, { label = "Remove All Added", value = "remove_all", type = "button" })
    end
    table.insert(menu.elements, { label = "Close Menu", value = "close", type = "button" })

    MenuData.Open('default', 'keybind_system', 'main_menu', {
        title = menu.title,
        elements = menu.elements
    }, function(data, menu)
        print("^3[KeyBind] Menu callback triggered!")
        if not data or not data.current or not data.current.value then
            print("^1[KeyBind] No data received in menu callback!")
            menu.close()
            return
        end
        
        print(string.format("^3[KeyBind] Menu selection: %s", data.current.value))
        
        if data.current.value == "add_new" then
            print("^3[KeyBind] Opening add new menu...")
            menu.close()
            openAddBindMenu()
        elseif data.current.value == "remove_all" then
            print("^3[KeyBind] Opening remove all menu...")
            menu.close()
            openConfirmRemoveAllMenu()
        elseif data.current.value == "close" then
            print("^3[KeyBind] Closing menu...")
            menu.close()
        elseif string.find(data.current.value, "edit_") then
            local indexString = string.gsub(data.current.value, "edit_", "")
            local bindIndex = tonumber(indexString)
            print(string.format("^3[KeyBind] Opening edit menu for bind index: %d", bindIndex))
            menu.close()
            openEditBindMenu(bindIndex)
        else
            print(string.format("^1[KeyBind] Unknown menu selection: %s", data.current.value))
        end
    end, function(data, menu)
        menu.close()
    end)
end

-- Function to open add bind menu
function openAddBindMenu()
    if not MenuData then
        RSGCore.Functions.Notify("Menu system not ready, please try again!", "error")
        return
    end
    
    local menu = {
        title = "Choose a Key",
        elements = {
            { label = "Select a button (LALT + this button will trigger this command)", type = "label" }
        }
    }
    
    for keyName, _ in pairs(KEYS) do
        local alreadyBound = false
        for _, binding in ipairs(playerKeyBinds) do
            if binding.key == keyName then
                alreadyBound = true
                break
            end
        end
        if not alreadyBound then
            table.insert(menu.elements, { label = keyName, value = "key_" .. keyName, type = "button" })
        end
    end

    table.insert(menu.elements, { label = "Back to Menu", value = "back", type = "button" })

    MenuData.Open('default', 'keybind_system', 'add_bind_menu', {
        title = menu.title,
        elements = menu.elements
    }, function(data, menu)
        if not data or not data.current or not data.current.value then
            menu.close()
            openKeybindMenu()
            return
        end
        
        if data.current.value == "back" then
            menu.close()
            openKeybindMenu()
        elseif string.find(data.current.value, "key_") then
            local selectedKey = string.gsub(data.current.value, "key_", "")
            menu.close()
            openCommandInputMenu(selectedKey)
        end
    end, function(data, menu)
        menu.close()
        openKeybindMenu()
    end)
end

-- Function to open command input menu
function openCommandInputMenu(selectedKey)
    local input = exports['rsg-input']:ShowInput({
        header = "Enter Chat Command",
        submitText = "Save Binding",
        inputs = {
            {
                text = string.format("Binding: LALT + %s", selectedKey),
                name = "info",
                type = "text",
                isRequired = false,
                disabled = true
            },
            {
                text = "Command (without /):",
                name = "command",
                type = "text",
                isRequired = true,
                placeholder = "Example: me waves"
            }
        }
    })

    if input then
        local command = input.command
        if command and command ~= "" then
            TriggerServerEvent('keybind:savePlayerBind', { key = selectedKey, command = command })
            RSGCore.Functions.Notify("Successfully added!", "success")
        else
            RSGCore.Functions.Notify("Please enter a command!", "error")
        end
    end
    -- Always return to main menu after input
    openKeybindMenu()
end

-- Function to open edit bind menu
function openEditBindMenu(bindIndex)
    print(string.format("^3[KeyBind] openEditBindMenu called with bindIndex: %d", bindIndex))
    if not MenuData then
        print("^1[KeyBind] MenuData is nil in openEditBindMenu!")
        RSGCore.Functions.Notify("Menu system not ready, please try again!", "error")
        return
    end
    
    local bind = playerKeyBinds[bindIndex]
    print(string.format("^3[KeyBind] Retrieved bind: %s", bind and (bind.key .. " -> " .. bind.command) or "nil"))
    if not bind then 
        print("^1[KeyBind] Bind not found for index: " .. bindIndex)
        return 
    end
    
    local menu = {
        title = "Edit Keybind",
        elements = {
            { label = string.format("Editing Keybind: LALT + %s", bind.key), type = "label" },
            { label = "Current Command: " .. bind.command, type = "label" },
            { label = "Change Command", value = "update", type = "button" },
            { label = "Remove", value = "remove", type = "button" },
            { label = "Back", value = "back", type = "button" }
        }
    }
    
    MenuData.Open('default', 'keybind_system', 'edit_bind', {
        title = menu.title,
        elements = menu.elements
    }, function(data, menu)
        if not data or not data.current or not data.current.value then
            menu.close()
            openKeybindMenu()
            return
        end
        
        if data.current.value == "update" then
            menu.close()
            -- Use rsg-input for command editing
            local input = exports['rsg-input']:ShowInput({
                header = "Edit Command",
                submitText = "Change Command",
                inputs = {
                    {
                        text = string.format("Editing: LALT + %s", bind.key),
                        name = "info",
                        type = "text",
                        isRequired = false,
                        disabled = true
                    },
                    {
                        text = "New Command (without /):",
                        name = "command",
                        type = "text",
                        isRequired = true,
                        default = bind.command,
                        placeholder = bind.command
                    }
                }
            })

            if input then
                local command = input.command
                if command and command ~= "" then
                    TriggerServerEvent('keybind:updatePlayerBind', bindIndex, command)
                    RSGCore.Functions.Notify("Successfully updated!", "success")
                else
                    RSGCore.Functions.Notify("Please enter a command!", "error")
                end
            end
            -- Return to main menu after input
            openKeybindMenu()
        elseif data.current.value == "remove" then
            TriggerServerEvent('keybind:removePlayerBind', bindIndex)
            menu.close()
            RSGCore.Functions.Notify("Keybind removed!", "success")
        elseif data.current.value == "back" then
            menu.close()
            openKeybindMenu()
        end
    end, function(data, menu)
        menu.close()
        openKeybindMenu()
    end)
end

-- Function to open confirm remove all menu
function openConfirmRemoveAllMenu()
    if not MenuData then
        RSGCore.Functions.Notify("Menu system not ready, please try again!", "error")
        return
    end
    
    local menu = {
        title = "Confirm Removal",
        elements = {
            { label = "Are you sure you want to remove all?", type = "label" },
            { label = "This cannot be undone!", type = "label" },
            { label = "Yes, Remove All", value = "confirm", type = "button" },
            { label = "No, Cancel", value = "cancel", type = "button" }
        }
    }
    
    MenuData.Open('default', 'keybind_system', 'confirm_remove_all', {
        title = menu.title,
        elements = menu.elements
    }, function(data, menu)
        if not data or not data.current or not data.current.value then
            menu.close()
            openKeybindMenu()
            return
        end
        
        if data.current.value == "confirm" then
            TriggerServerEvent('keybind:removeAllPlayerBinds')
            menu.close()
            RSGCore.Functions.Notify("All keybinds removed!", "success")
        elseif data.current.value == "cancel" then
            menu.close()
            openKeybindMenu()
        end
    end, function(data, menu)
        menu.close()
        openKeybindMenu()
    end)
end

-- Key detection thread
Citizen.CreateThread(function()
    print("^2[KeyBind] Key detection thread started!")
    -- Wait until PlayerData and playerKeyBinds are properly initialized
    while not PlayerData or not PlayerData.citizenid or not playerKeyBinds do
        Citizen.Wait(100)
    end
    print("^2[KeyBind] Player data and keybinds initialized, starting detection loop!")
    while true do
        Citizen.Wait(0)
        if PlayerData and PlayerData.citizenid and IsControlPressed(0, LALT_KEY) then
            -- Ensure playerKeyBinds is a table before iterating
            if type(playerKeyBinds) == "table" then
                -- Check for key presses
                for _, bind in ipairs(playerKeyBinds) do
                    local keyHash = KEYS[bind.key]
                    if keyHash and IsControlJustPressed(0, keyHash) then
                        -- Disable native action immediately after detection
                        DisableControlAction(0, keyHash, true) -- Input group 0 (gameplay)
                        DisableControlAction(1, keyHash, true) -- Input group 1 (frontend)
                        if Config.Debug then
                            print(string.format("^3[KeyBind] Disabled native action for key: %s (hash: 0x%X)", bind.key, keyHash))
                        end
                        print(string.format("^3[KeyBind] Key combo detected: LALT + %s -> %s", bind.key, bind.command))
                        local command = bind.command
                        if string.sub(command, 1, 1) == "/" then
                            command = string.sub(command, 2)
                        end
                        -- Trigger server event
                        TriggerServerEvent('keybind:executeCommand', command)
                        if Config.Debug then
                            print(string.format("^3[KeyBind] Triggered server event for command: %s", command))
                        end
                        -- Test direct client execution
                        ExecuteCommand(command)
                        if Config.Debug then
                            print(string.format("^3[KeyBind] Directly executed command on client: %s", command))
                        end
                        Citizen.Wait(200) -- Debounce
                        break
                    end
                end
            end
        else
            -- Re-enable all bound key controls when LALT is not pressed
            if type(playerKeyBinds) == "table" then
                for _, bind in ipairs(playerKeyBinds) do
                    local keyHash = KEYS[bind.key]
                    if keyHash then
                        EnableControlAction(0, keyHash, true) -- Input group 0
                        EnableControlAction(1, keyHash, true) -- Input group 1
                    end
                end
            end
        end
    end
end)

-- Event handlers for server responses
RegisterNetEvent('keybind:bindSaved', function()
    TriggerServerEvent('keybind:loadPlayerBinds')
    openKeybindMenu()
end)

RegisterNetEvent('keybind:bindUpdated', function()
    TriggerServerEvent('keybind:loadPlayerBinds')
    openKeybindMenu()
end)

RegisterNetEvent('keybind:bindRemoved', function()
    TriggerServerEvent('keybind:loadPlayerBinds')
    openKeybindMenu()
end)

RegisterNetEvent('keybind:allBindsRemoved', function()
    TriggerServerEvent('keybind:loadPlayerBinds')
    openKeybindMenu()
end)

-- Event handler for opening menu
RegisterNetEvent('keybind:openMenu', function()
    print("^3[KeyBind] Menu open event triggered!")
    if PlayerData and PlayerData.citizenid then
        print("^3[KeyBind] Player data valid, opening menu...")
        openKeybindMenu()
    else
        print("^1[KeyBind] Player data not ready!")
        RSGCore.Functions.Notify("You need to relog!", "error")
    end
end)

-- Event handler for executing client commands
RegisterNetEvent('keybind:executeClientCommand', function(command)
    -- Execute command on client side
    ExecuteCommand(command)
    if Config.Debug then
        print(string.format("^3[KeyBind] Executed client command from server: %s", command))
    end
end)