-- Core data structures and constants for questbook
-- Defines quest templates, objectives, rewards, and status enums

questbook.data = {}

-- Quest status constants
questbook.data.STATUS = {
    LOCKED = "locked",       -- Prerequisites not met
    AVAILABLE = "available", -- Can be started
    ACTIVE = "active",       -- Currently in progress
    COMPLETED = "completed", -- Successfully finished
    FAILED = "failed"        -- Failed or abandoned
}

-- Quest objective types
questbook.data.OBJECTIVE_TYPES = {
    KILL = "kill",           -- Kill specific mobs
    COLLECT = "collect",     -- Collect items (gain items in inventory)
    MINE = "mine",           -- Mine specific blocks (break blocks)
    DELIVER = "deliver",     -- Deliver items to location/player
    CRAFT = "craft",         -- Craft specific items
    BUILD = "build",         -- Build structures
    EXPLORE = "explore",     -- Visit locations
    TALK = "talk",           -- Interact with objects/signs
    TIMER = "timer",         -- Wait for time period
    CUSTOM = "custom"        -- Custom objective type
}

-- Quest types
questbook.data.QUEST_TYPES = {
    STANDARD = "standard",   -- Regular objective-based quests
    CONSUME = "consume",     -- Quests that consume items when manually submitted
    CHECKBOX = "checkbox"    -- Information-based quests completed by checking
}

-- Reward types
questbook.data.REWARD_TYPES = {
    ITEM = "item",           -- Give items
    EXPERIENCE = "experience", -- Award XP (if mod available)
    CURRENCY = "currency",   -- Give external mod currency (if economy mod available)
    QB_CURRENCY = "qb_currency", -- Give questbook virtual currency
    LOOTBAG = "lootbag",     -- Random weighted reward selection
    UNLOCK = "unlock",       -- Unlock access/features
    CUSTOM = "custom"        -- Custom reward type
}

-- Quest template structure
questbook.data.quest_template = {
    id = "",                 -- Unique quest identifier
    title = "",              -- Display name
    description = "",        -- Quest description
    category = "main",       -- Quest category/chapter
    quest_type = "standard", -- Quest type (see QUEST_TYPES)
    prerequisites = {},      -- Required completed quests
    objectives = {},         -- List of objectives
    rewards = {},           -- List of rewards
    time_limit = nil,       -- Optional time limit in seconds
    repeatable = false,     -- Can quest be repeated
    repeat_cooldown = 0,    -- Cooldown in seconds between repeats (0 = immediate)
    repeat_type = "manual", -- "manual", "daily", "weekly", "cooldown"
    auto_start = true,      -- Starts automatically when prerequisites met
    hidden = false,         -- Hidden from quest book until unlocked
    show_progress_chat = false, -- Show chat notifications for progress updates
    hide_when_locked = nil, -- Override global visibility (nil=use global, true=hide when locked, false=always show)
    party_shared = false,   -- Allow party members to share progress on this quest
    tile_item = "",         -- Item to display on quest tile
    tile_x = 0,             -- Tile X position in pixels
    tile_y = 0              -- Tile Y position in pixels
}

-- Objective template structure
questbook.data.objective_template = {
    id = "",                -- Unique objective identifier within quest
    type = "",              -- Objective type (see OBJECTIVE_TYPES)
    description = "",       -- Display description
    target = "",            -- Target item/mob/location
    count = 1,              -- Required count
    optional = false,       -- Optional objective
    data = {}               -- Additional type-specific data
}

-- Reward template structure  
questbook.data.reward_template = {
    type = "",              -- Reward type (see REWARD_TYPES)
    item = "",              -- Item name (for item rewards)
    count = 1,              -- Amount to give
    data = {}               -- Additional type-specific data
}

-- Player quest progress structure
questbook.data.player_progress_template = {
    status = questbook.data.STATUS.LOCKED,
    objectives = {},        -- Objective ID -> progress count
    start_time = nil,       -- When quest was started
    complete_time = nil,    -- When quest was completed
    last_completion = nil,  -- Last completion time (for repeatable quests)
    completion_count = 0,   -- Number of times completed (for repeatable quests)
    data = {}               -- Quest-specific data storage
}

-- Player data structure (global player data)
questbook.data.player_data_template = {
    currency = 0,           -- Virtual questbook currency
    statistics = {          -- Player statistics
        quests_completed = 0,
        total_objectives = 0,
        currency_earned = 0
    },
    settings = {}           -- Player-specific settings
}





-- Validation functions
function questbook.data.validate_quest(quest)
    if type(quest) ~= "table" then
        return false, "Quest must be a table"
    end
    
    if not quest.id or quest.id == "" then
        return false, "Quest must have a valid ID"
    end
    
    if not quest.title or quest.title == "" then
        return false, "Quest must have a title"
    end
    
    if not quest.objectives or #quest.objectives == 0 then
        return false, "Quest must have at least one objective"
    end
    
    -- Validate objectives
    for i, obj in ipairs(quest.objectives) do
        if not obj.id or obj.id == "" then
            return false, "Objective " .. i .. " must have an ID"
        end
        
        if not questbook.data.OBJECTIVE_TYPES[obj.type:upper()] then
            return false, "Invalid objective type: " .. (obj.type or "nil")
        end
    end
    
    return true, "Valid quest"
end




function questbook.data.create_quest_template(id, title, description)
    local quest = table.copy(questbook.data.quest_template)
    quest.id = id
    quest.title = title
    quest.description = description or ""
    return quest
end

function questbook.data.create_objective(id, obj_type, description, target, count)
    local objective = table.copy(questbook.data.objective_template)
    objective.id = id
    objective.type = obj_type
    objective.description = description
    objective.target = target or ""
    objective.count = count or 1
    return objective
end

function questbook.data.create_reward(reward_type, item, count)
    local reward = table.copy(questbook.data.reward_template)
    reward.type = reward_type
    reward.item = item or ""
    reward.count = count or 1
    return reward
end

-- Create a currency reward
function questbook.data.create_currency_reward(amount)
    local reward = table.copy(questbook.data.reward_template)
    reward.type = questbook.data.REWARD_TYPES.QB_CURRENCY
    reward.count = amount or 1
    reward.item = "currency"
    return reward
end






-- Create a lootbag reward
function questbook.data.create_lootbag_reward(name, items, max_rolls)
    local reward = table.copy(questbook.data.reward_template)
    reward.type = questbook.data.REWARD_TYPES.LOOTBAG
    reward.item = name or "Loot Bag"
    reward.count = max_rolls or 1 -- How many items to roll from the bag
    reward.data = {
        items = items or {} -- Array of {item, count, weight, chance}
    }
    return reward
end

minetest.log("action", "[Questbook] Core data structures loaded")