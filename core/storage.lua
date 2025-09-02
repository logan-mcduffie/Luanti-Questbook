-- Player progress persistence and quest data storage
-- Handles saving/loading player quest progress and registered quests

questbook.storage = {}

-- Internal storage
local registered_quests = {}
local player_data = {}

-- File paths
local world_path = minetest.get_worldpath()
local data_path = world_path .. "/questbook_data.lua"
local player_data_path = world_path .. "/questbook_players/"

-- Initialize storage directories
function questbook.storage.init()
    -- Create player data directory if it doesn't exist
    minetest.mkdir(player_data_path)
    
    -- Load registered quests
    questbook.storage.load_quests()
    
    minetest.log("action", "[Questbook] Storage system initialized")
end

-- Quest registration and management
function questbook.storage.register_quest(quest)
    local valid, message = questbook.data.validate_quest(quest)
    if not valid then
        minetest.log("error", "[Questbook] Invalid quest '" .. (quest.id or "unknown") .. "': " .. message)
        return false
    end
    
    registered_quests[quest.id] = quest
    questbook.storage.save_quests()
    
    minetest.log("action", "[Questbook] Registered quest: " .. quest.id)
    return true
end

function questbook.storage.get_quest(quest_id)
    return registered_quests[quest_id]
end

function questbook.storage.get_all_quests()
    return table.copy(registered_quests)
end

function questbook.storage.unregister_quest(quest_id)
    if registered_quests[quest_id] then
        registered_quests[quest_id] = nil
        questbook.storage.save_quests()
        minetest.log("action", "[Questbook] Unregistered quest: " .. quest_id)
        return true
    end
    return false
end

-- Quest data persistence
function questbook.storage.save_quests()
    local file = io.open(data_path, "w")
    if not file then
        minetest.log("error", "[Questbook] Could not save quest data to " .. data_path)
        return false
    end
    
    file:write("-- Questbook registered quests data\n")
    file:write("return " .. minetest.serialize(registered_quests))
    file:close()
    
    return true
end

function questbook.storage.load_quests()
    local file = io.open(data_path, "r")
    if not file then
        minetest.log("info", "[Questbook] No existing quest data found, starting fresh")
        return true
    end
    
    local data = file:read("*all")
    file:close()
    
    if data and data ~= "" then
        local loaded_data = minetest.deserialize(data:match("return (.*)"))
        if loaded_data and type(loaded_data) == "table" then
            registered_quests = loaded_data
            local count = 0
            for _ in pairs(registered_quests) do count = count + 1 end
            minetest.log("action", "[Questbook] Loaded " .. count .. " registered quests")
        else
            minetest.log("error", "[Questbook] Failed to parse quest data file")
        end
    end
    
    return true
end

-- Player progress management
function questbook.storage.get_player_data(player_name)
    if not player_data[player_name] then
        questbook.storage.load_player_data(player_name)
    end
    return player_data[player_name] or {}
end

function questbook.storage.set_player_quest_progress(player_name, quest_id, progress)
    if not player_data[player_name] then
        player_data[player_name] = {}
    end
    
    player_data[player_name][quest_id] = progress
    questbook.storage.save_player_data(player_name)
end

function questbook.storage.get_player_quest_progress(player_name, quest_id)
    local data = questbook.storage.get_player_data(player_name)
    return data[quest_id]
end

function questbook.storage.save_player_data(player_name)
    local file_path = player_data_path .. player_name .. ".lua"
    local file = io.open(file_path, "w")
    if not file then
        minetest.log("error", "[Questbook] Could not save player data for " .. player_name)
        return false
    end
    
    local data = player_data[player_name] or {}
    file:write("-- Questbook player data for " .. player_name .. "\n")
    file:write("return " .. minetest.serialize(data))
    file:close()
    
    return true
end

function questbook.storage.load_player_data(player_name)
    local file_path = player_data_path .. player_name .. ".lua"
    local file = io.open(file_path, "r")
    if not file then
        -- New player, initialize empty data
        player_data[player_name] = {}
        return true
    end
    
    local data = file:read("*all")
    file:close()
    
    if data and data ~= "" then
        local loaded_data = minetest.deserialize(data:match("return (.*)"))
        if loaded_data and type(loaded_data) == "table" then
            player_data[player_name] = loaded_data
        else
            minetest.log("error", "[Questbook] Failed to parse player data for " .. player_name)
            player_data[player_name] = {}
        end
    else
        player_data[player_name] = {}
    end
    
    return true
end

-- Global player data management (currency, statistics, etc.)
function questbook.storage.get_player_global_data(player_name)
    if not player_data[player_name] then
        questbook.storage.load_player_data(player_name)
    end
    
    -- Ensure global data structure exists
    if not player_data[player_name]._global then
        player_data[player_name]._global = table.copy(questbook.data.player_data_template)
    end
    
    return player_data[player_name]._global
end

function questbook.storage.set_player_global_data(player_name, global_data)
    if not player_data[player_name] then
        player_data[player_name] = {}
    end
    
    player_data[player_name]._global = global_data
    questbook.storage.save_player_data(player_name)
end

-- Currency management
function questbook.storage.get_player_currency(player_name)
    local global_data = questbook.storage.get_player_global_data(player_name)
    return global_data.currency or 0
end

function questbook.storage.set_player_currency(player_name, amount)
    local global_data = questbook.storage.get_player_global_data(player_name)
    global_data.currency = math.max(0, amount) -- Prevent negative currency
    questbook.storage.set_player_global_data(player_name, global_data)
end

function questbook.storage.add_player_currency(player_name, amount)
    local current = questbook.storage.get_player_currency(player_name)
    questbook.storage.set_player_currency(player_name, current + amount)
end

function questbook.storage.remove_player_currency(player_name, amount)
    local current = questbook.storage.get_player_currency(player_name)
    local new_amount = math.max(0, current - amount)
    questbook.storage.set_player_currency(player_name, new_amount)
    return new_amount >= 0 -- Return true if successful (had enough currency)
end

-- Statistics management
function questbook.storage.get_player_statistics(player_name)
    local global_data = questbook.storage.get_player_global_data(player_name)
    return global_data.statistics or table.copy(questbook.data.player_data_template.statistics)
end

function questbook.storage.update_player_statistics(player_name, stat_name, value)
    local global_data = questbook.storage.get_player_global_data(player_name)
    if global_data.statistics[stat_name] then
        global_data.statistics[stat_name] = global_data.statistics[stat_name] + value
        questbook.storage.set_player_global_data(player_name, global_data)
    end
end

-- Cleanup player data when player leaves
minetest.register_on_leaveplayer(function(player)
    local player_name = player:get_player_name()
    if player_data[player_name] then
        questbook.storage.save_player_data(player_name)
        -- Keep data in memory for quick rejoins, but could be cleared for memory optimization
    end
end)

-- Save all player data on server shutdown
minetest.register_on_shutdown(function()
    for player_name, _ in pairs(player_data) do
        questbook.storage.save_player_data(player_name)
    end
    questbook.storage.save_quests()
    minetest.log("action", "[Questbook] Saved all data on shutdown")
end)

minetest.log("action", "[Questbook] Storage system loaded")