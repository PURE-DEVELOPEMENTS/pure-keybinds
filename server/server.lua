-- server.lua
local RSGCore = exports['rsg-core']:GetCoreObject()

-- Load player key binds from database
local function loadPlayerKeyBinds(citizenid, source)
    if not citizenid then return end
    local result = exports.oxmysql:executeSync('SELECT key_name, command FROM player_keybinds WHERE citizenid = ? ORDER BY id', {citizenid})
    local keyBinds = {}
    if result then
        for _, row in ipairs(result) do
            table.insert(keyBinds, { key = row.key_name, command = row.command })
        end
    end
    TriggerClientEvent('keybind:receivePlayerBinds', source, keyBinds)
end

-- Save a new key bind
local function savePlayerKeyBind(citizenid, keyName, command, source)
    if not citizenid or not keyName or not command then return end
    local cleanCommand = string.gsub(command, "^/", "")
    cleanCommand = string.gsub(cleanCommand, "[^%w%s%-%_%.%@%#%$%%%&%*%(%)%+%=%[%]%{%}%|%\\%:%?%!%,]", "")
    if cleanCommand == "" then
        TriggerClientEvent('RSGCore:Notify', source, 'Invalid command!', 'error')
        return
    end
    local result = exports.oxmysql:executeSync('INSERT INTO player_keybinds (citizenid, key_name, command) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE command = ?, updated_at = NOW()', {citizenid, keyName, cleanCommand, cleanCommand})
    if result.insertId or result.affectedRows > 0 then
        TriggerClientEvent('keybind:bindSaved', source)
        print(string.format('[KeyBind] Saved/Updated key bind for %s: %s -> %s', citizenid, keyName, cleanCommand))
    else
        TriggerClientEvent('RSGCore:Notify', source, 'Failed to save key bind!', 'error')
    end
end

-- Update an existing key bind
local function updatePlayerKeyBind(citizenid, bindIndex, newCommand, source)
    if not citizenid or not bindIndex or not newCommand then return end
    local cleanCommand = string.gsub(newCommand, "^/", "")
    cleanCommand = string.gsub(cleanCommand, "[^%w%s%-%_%.%@%#%$%%%&%*%(%)%+%=%[%]%{%}%|%\\%:%?%!%,]", "")
    if cleanCommand == "" then
        TriggerClientEvent('RSGCore:Notify', source, 'Invalid command!', 'error')
        return
    end
    local result = exports.oxmysql:executeSync('SELECT key_name FROM player_keybinds WHERE citizenid = ? ORDER BY id LIMIT 1 OFFSET ?', {citizenid, bindIndex - 1})
    if result[1] then
        local keyName = result[1].key_name
        local updateResult = exports.oxmysql:executeSync('UPDATE player_keybinds SET command = ?, updated_at = NOW() WHERE citizenid = ? AND key_name = ?', {cleanCommand, citizenid, keyName})
        if updateResult.affectedRows > 0 then
            TriggerClientEvent('keybind:bindUpdated', source)
            print(string.format('[KeyBind] Updated key bind for %s: %s -> %s', citizenid, keyName, cleanCommand))
        else
            TriggerClientEvent('RSGCore:Notify', source, 'Failed to update key bind!', 'error')
        end
    else
        TriggerClientEvent('RSGCore:Notify', source, 'Key bind not found!', 'error')
    end
end

-- Remove a specific key bind
local function removePlayerKeyBind(citizenid, bindIndex, source)
    if not citizenid or not bindIndex then return end
    local result = exports.oxmysql:executeSync('SELECT key_name FROM player_keybinds WHERE citizenid = ? ORDER BY id LIMIT 1 OFFSET ?', {citizenid, bindIndex - 1})
    if result[1] then
        local keyName = result[1].key_name
        local deleteResult = exports.oxmysql:executeSync('DELETE FROM player_keybinds WHERE citizenid = ? AND key_name = ?', {citizenid, keyName})
        if deleteResult.affectedRows > 0 then
            TriggerClientEvent('keybind:bindRemoved', source)
            print(string.format('[KeyBind] Removed key bind for %s: %s', citizenid, keyName))
        else
            TriggerClientEvent('RSGCore:Notify', source, 'Failed to remove key bind!', 'error')
        end
    else
        TriggerClientEvent('RSGCore:Notify', source, 'Key bind not found!', 'error')
    end
end

-- Remove all key binds for a player
local function removeAllPlayerKeyBinds(citizenid, source)
    if not citizenid then return end
    local result = exports.oxmysql:executeSync('DELETE FROM player_keybinds WHERE citizenid = ?', {citizenid})
    if result.affectedRows > 0 then
        TriggerClientEvent('keybind:allBindsRemoved', source)
        print(string.format('[KeyBind] Removed all key binds for %s', citizenid))
    else
        TriggerClientEvent('RSGCore:Notify', source, 'No key binds found to remove!', 'error')
    end
end

-- Command execution handler
RegisterNetEvent('keybind:executeCommand', function(command)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local cmdName = command:match("^(%S+)") or command
    local args = {}
    for arg in command:gmatch("%S+") do
        if arg ~= cmdName then
            table.insert(args, arg)
        end
    end
    
    if RSGCore.Commands.List[cmdName] then
        local cmdData = RSGCore.Commands.List[cmdName]
        if cmdData.permission and not RSGCore.Functions.HasPermission(src, cmdData.permission) then
            TriggerClientEvent('RSGCore:Notify', src, 'No permission for this command!', 'error')
            return
        end
        cmdData['function'](src, args)
        print(string.format('[KeyBind] Player %s executed RSG-Core command: %s', Player.PlayerData.citizenid, cmdName))
    else
        -- Send command back to client for execution
        TriggerClientEvent('keybind:executeClientCommand', src, command)
        print(string.format('[KeyBind] Player %s executed chat command: %s', Player.PlayerData.citizenid, command))
    end
end)

-- Event handlers
RegisterNetEvent('keybind:loadPlayerBinds', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if Player and Player.PlayerData and Player.PlayerData.citizenid then
        loadPlayerKeyBinds(Player.PlayerData.citizenid, src)
    else
        -- Player not fully loaded yet, try again in a moment
        SetTimeout(1000, function()
            local RetryPlayer = RSGCore.Functions.GetPlayer(src)
            if RetryPlayer and RetryPlayer.PlayerData and RetryPlayer.PlayerData.citizenid then
                loadPlayerKeyBinds(RetryPlayer.PlayerData.citizenid, src)
            else
                TriggerClientEvent('RSGCore:Notify', src, 'Please wait until you are fully loaded!', 'error')
            end
        end)
    end
end)

RegisterNetEvent('keybind:savePlayerBind', function(bindData)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if Player and Player.PlayerData and Player.PlayerData.citizenid and bindData and bindData.key and bindData.command then
        savePlayerKeyBind(Player.PlayerData.citizenid, bindData.key, bindData.command, src)
    else
        TriggerClientEvent('RSGCore:Notify', src, 'Please wait until you are fully loaded!', 'error')
    end
end)

RegisterNetEvent('keybind:updatePlayerBind', function(bindIndex, newCommand)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if Player and Player.PlayerData and Player.PlayerData.citizenid and bindIndex and newCommand then
        updatePlayerKeyBind(Player.PlayerData.citizenid, bindIndex, newCommand, src)
    else
        TriggerClientEvent('RSGCore:Notify', src, 'Please wait until you are fully loaded!', 'error')
    end
end)

RegisterNetEvent('keybind:removePlayerBind', function(bindIndex)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if Player and Player.PlayerData and Player.PlayerData.citizenid and bindIndex then
        removePlayerKeyBind(Player.PlayerData.citizenid, bindIndex, src)
    else
        TriggerClientEvent('RSGCore:Notify', src, 'Please wait until you are fully loaded!', 'error')
    end
end)

RegisterNetEvent('keybind:removeAllPlayerBinds', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if Player and Player.PlayerData and Player.PlayerData.citizenid then
        removeAllPlayerKeyBinds(Player.PlayerData.citizenid, src)
    else
        TriggerClientEvent('RSGCore:Notify', src, 'Please wait until you are fully loaded!', 'error')
    end
end)

-- Commands
RSGCore.Commands.Add('keybinds', 'Open key binding menu', {}, false, function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player and Player.PlayerData and Player.PlayerData.citizenid then
        TriggerClientEvent('keybind:openMenu', source)
    else
        TriggerClientEvent('RSGCore:Notify', source, 'Please wait until you are fully loaded!', 'error')
    end
end)

RSGCore.Commands.Add('kb', 'Open key binding menu (short)', {}, false, function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player and Player.PlayerData and Player.PlayerData.citizenid then
        TriggerClientEvent('keybind:openMenu', source)
    else
        TriggerClientEvent('RSGCore:Notify', source, 'Please wait until you are fully loaded!', 'error')
    end
end)

-- Auto-load keybinds when player is fully loaded
RegisterNetEvent('RSGCore:Server:PlayerLoaded', function(Player)
    local src = source
    if Player and Player.PlayerData and Player.PlayerData.citizenid then
        -- Wait a bit to ensure everything is fully loaded
        SetTimeout(2000, function()
            loadPlayerKeyBinds(Player.PlayerData.citizenid, src)
        end)
    end
end)

-- Also handle when player spawns
RegisterNetEvent('RSGCore:Server:OnPlayerLoaded', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if Player and Player.PlayerData and Player.PlayerData.citizenid then
        -- Wait a bit to ensure everything is fully loaded
        SetTimeout(2000, function()
            loadPlayerKeyBinds(Player.PlayerData.citizenid, src)
        end)
    end
end)

RSGCore.Commands.Add('viewkeybinds', 'View a player\'s key binds (Admin Only)', {{name = 'id', help = 'Player ID'}}, true, function(source, args)
    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('RSGCore:Notify', source, 'Invalid player ID!', 'error')
        return
    end
    local TargetPlayer = RSGCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then
        TriggerClientEvent('RSGCore:Notify', source, 'Player not found!', 'error')
        return
    end
    local result = exports.oxmysql:executeSync('SELECT key_name, command FROM player_keybinds WHERE citizenid = ? ORDER BY id', {TargetPlayer.PlayerData.citizenid})
    if result and #result > 0 then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'[KeyBind System]', string.format('Key binds for %s %s:', TargetPlayer.PlayerData.charinfo.firstname, TargetPlayer.PlayerData.charinfo.lastname)}
        })
        for _, row in ipairs(result) do
            TriggerClientEvent('chat:addMessage', source, {
                args = {'[KeyBind]', string.format('LALT + %s: %s', row.key_name, row.command)}
            })
        end
    else
        TriggerClientEvent('RSGCore:Notify', source, 'Player has no key binds!', 'error')
    end
end, 'admin')

RSGCore.Commands.Add('clearkeybinds', 'Clear a player\'s key binds (Admin Only)', {{name = 'id', help = 'Player ID'}}, true, function(source, args)
    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('RSGCore:Notify', source, 'Invalid player ID!', 'error')
        return
    end
    local TargetPlayer = RSGCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then
        TriggerClientEvent('RSGCore:Notify', source, 'Player not found!', 'error')
        return
    end
    local result = exports.oxmysql:executeSync('DELETE FROM player_keybinds WHERE citizenid = ?', {TargetPlayer.PlayerData.citizenid})
    if result.affectedRows > 0 then
        TriggerClientEvent('RSGCore:Notify', source, string.format('Cleared %d key binds for %s %s', result.affectedRows, TargetPlayer.PlayerData.charinfo.firstname, TargetPlayer.PlayerData.charinfo.lastname), 'success')
        TriggerClientEvent('RSGCore:Notify', targetId, 'Your key binds have been cleared by an admin!', 'error')
        TriggerClientEvent('keybind:loadPlayerBinds', targetId)
    else
        TriggerClientEvent('RSGCore:Notify', source, 'Player has no key binds to clear!', 'error')
    end
end, 'admin')

-- Exports
exports('GetPlayerKeyBinds', function(citizenid)
    return exports.oxmysql:executeSync('SELECT key_name, command FROM player_keybinds WHERE citizenid = ? ORDER BY id', {citizenid})
end)

exports('AddPlayerKeyBind', function(citizenid, keyName, command)
    return exports.oxmysql:executeSync('INSERT INTO player_keybinds (citizenid, key_name, command) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE command = VALUES(command)', {citizenid, keyName, command})
end)

exports('RemovePlayerKeyBind', function(citizenid, keyName)
    return exports.oxmysql:executeSync('DELETE FROM player_keybinds WHERE citizenid = ? AND key_name = ?', {citizenid, keyName})
end)

print('^2[KeyBind System] ^7Server-side loaded successfully!')