-- Event system for quest state changes
-- Allows other mods to hook into quest events

questbook.events = {}

-- Event callback storage
local event_callbacks = {
    quest_start = {},
    quest_complete = {},
    quest_fail = {},
    objective_progress = {},
    objective_complete = {},
    custom_reward = {}
}

-- Register callback for quest start event
function questbook.on_quest_start(callback)
    if type(callback) == "function" then
        table.insert(event_callbacks.quest_start, callback)
        return true
    end
    return false
end

-- Register callback for quest completion event
function questbook.on_quest_complete(callback)
    if type(callback) == "function" then
        table.insert(event_callbacks.quest_complete, callback)
        return true
    end
    return false
end

-- Register callback for quest failure event
function questbook.on_quest_fail(callback)
    if type(callback) == "function" then
        table.insert(event_callbacks.quest_fail, callback)
        return true
    end
    return false
end

-- Register callback for objective progress event
function questbook.on_objective_progress(callback)
    if type(callback) == "function" then
        table.insert(event_callbacks.objective_progress, callback)
        return true
    end
    return false
end

-- Register callback for objective completion event  
function questbook.on_objective_complete(callback)
    if type(callback) == "function" then
        table.insert(event_callbacks.objective_complete, callback)
        return true
    end
    return false
end

-- Register callback for custom reward event
function questbook.on_custom_reward(callback)
    if type(callback) == "function" then
        table.insert(event_callbacks.custom_reward, callback)
        return true
    end
    return false
end

-- Fire quest start event
function questbook.events.fire_quest_start(player_name, quest_id)
    local quest = questbook.storage.get_quest(quest_id)
    for _, callback in ipairs(event_callbacks.quest_start) do
        local success, error = pcall(callback, player_name, quest_id, quest)
        if not success then
            minetest.log("error", "[Questbook] Error in quest_start callback: " .. error)
        end
    end
end

-- Fire quest completion event
function questbook.events.fire_quest_complete(player_name, quest_id)
    local quest = questbook.storage.get_quest(quest_id)
    for _, callback in ipairs(event_callbacks.quest_complete) do
        local success, error = pcall(callback, player_name, quest_id, quest)
        if not success then
            minetest.log("error", "[Questbook] Error in quest_complete callback: " .. error)
        end
    end
end

-- Fire quest failure event
function questbook.events.fire_quest_fail(player_name, quest_id, reason)
    local quest = questbook.storage.get_quest(quest_id)
    for _, callback in ipairs(event_callbacks.quest_fail) do
        local success, error = pcall(callback, player_name, quest_id, quest, reason)
        if not success then
            minetest.log("error", "[Questbook] Error in quest_fail callback: " .. error)
        end
    end
end

-- Fire objective progress event
function questbook.events.fire_objective_progress(player_name, quest_id, objective_id, progress)
    local quest = questbook.storage.get_quest(quest_id)
    for _, callback in ipairs(event_callbacks.objective_progress) do
        local success, error = pcall(callback, player_name, quest_id, objective_id, progress, quest)
        if not success then
            minetest.log("error", "[Questbook] Error in objective_progress callback: " .. error)
        end
    end
end

-- Fire objective completion event
function questbook.events.fire_objective_complete(player_name, quest_id, objective_id)
    local quest = questbook.storage.get_quest(quest_id)
    for _, callback in ipairs(event_callbacks.objective_complete) do
        local success, error = pcall(callback, player_name, quest_id, objective_id, quest)
        if not success then
            minetest.log("error", "[Questbook] Error in objective_complete callback: " .. error)
        end
    end
end

-- Fire custom reward event
function questbook.events.fire_custom_reward(player_name, quest_id, reward)
    for _, callback in ipairs(event_callbacks.custom_reward) do
        local success, error = pcall(callback, player_name, quest_id, reward)
        if not success then
            minetest.log("error", "[Questbook] Error in custom_reward callback: " .. error)
        end
    end
end

-- Clear all callbacks (useful for testing)
function questbook.events.clear_callbacks()
    for event_type, _ in pairs(event_callbacks) do
        event_callbacks[event_type] = {}
    end
end

minetest.log("action", "[Questbook] Event system loaded")