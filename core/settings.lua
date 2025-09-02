-- Global questbook settings and configuration
-- Handles server-wide quest visibility and behavior settings

questbook.settings = {}

-- Default global settings
local global_settings = {
    hide_locked_quests = false,           -- Global: Hide quests that don't meet prerequisites
    show_prerequisite_info = true,       -- Global: Show prerequisite information for locked quests
    show_locked_objectives = false,      -- Global: Show objectives for locked quests
    show_locked_rewards = false          -- Global: Show rewards for locked quests
}

-- Initialize settings system
function questbook.settings.init()
    questbook.settings.load_global_settings()
    minetest.log("action", "[Questbook] Settings system initialized")
end

-- Get global setting value
function questbook.settings.get(setting_name)
    return global_settings[setting_name]
end

-- Set global setting value
function questbook.settings.set(setting_name, value)
    if global_settings[setting_name] ~= nil then
        global_settings[setting_name] = value
        questbook.settings.save_global_settings()
        return true
    end
    return false
end

-- Get all global settings
function questbook.settings.get_all()
    return table.copy(global_settings)
end

-- Load global settings from file
function questbook.settings.load_global_settings()
    local world_path = minetest.get_worldpath()
    local settings_path = world_path .. "/questbook_settings.lua"
    
    local file = io.open(settings_path, "r")
    if not file then
        minetest.log("info", "[Questbook] No settings file found, using defaults")
        return true
    end
    
    local data = file:read("*all")
    file:close()
    
    if data and data ~= "" then
        local loaded_settings = minetest.deserialize(data:match("return (.*)"))
        if loaded_settings and type(loaded_settings) == "table" then
            -- Merge loaded settings with defaults (preserving any new defaults)
            for key, value in pairs(loaded_settings) do
                if global_settings[key] ~= nil then
                    global_settings[key] = value
                end
            end
            minetest.log("action", "[Questbook] Loaded global settings")
        else
            minetest.log("error", "[Questbook] Failed to parse settings file")
        end
    end
    
    return true
end

-- Save global settings to file
function questbook.settings.save_global_settings()
    local world_path = minetest.get_worldpath()
    local settings_path = world_path .. "/questbook_settings.lua"
    
    local file = io.open(settings_path, "w")
    if not file then
        minetest.log("error", "[Questbook] Could not save settings to " .. settings_path)
        return false
    end
    
    file:write("-- Questbook global settings\n")
    file:write("return " .. minetest.serialize(global_settings))
    file:close()
    
    return true
end

-- Check if a quest should be visible to a player
function questbook.settings.is_quest_visible(player_name, quest)
    -- Check per-quest visibility setting first
    if quest.hide_when_locked ~= nil then
        -- Quest has specific visibility setting
        if quest.hide_when_locked then
            return questbook.settings.quest_prereqs_met(player_name, quest)
        else
            -- Quest specifically wants to be visible even when locked
            return true
        end
    end
    
    -- Use global setting
    if global_settings.hide_locked_quests then
        return questbook.settings.quest_prereqs_met(player_name, quest)
    end
    
    -- Default: show all quests unless quest.hidden is true
    return not quest.hidden
end

-- Check if quest prerequisites are met
function questbook.settings.quest_prereqs_met(player_name, quest)
    for _, prereq_id in ipairs(quest.prerequisites or {}) do
        local prereq_progress = questbook.get_progress(player_name, prereq_id)
        if not prereq_progress or prereq_progress.status ~= questbook.data.STATUS.COMPLETED then
            return false
        end
    end
    return true
end

-- Check if quest details should be shown (for locked quests)
function questbook.settings.should_show_quest_details(player_name, quest)
    -- If quest is available/started/completed, always show details
    local progress = questbook.get_progress(player_name, quest.id)
    if progress and progress.status ~= questbook.data.STATUS.LOCKED then
        return {
            objectives = true,
            rewards = true,
            prerequisites = true
        }
    end
    
    -- Quest is locked, check visibility settings
    return {
        objectives = global_settings.show_locked_objectives,
        rewards = global_settings.show_locked_rewards,
        prerequisites = global_settings.show_prerequisite_info
    }
end

minetest.log("action", "[Questbook] Settings system loaded")