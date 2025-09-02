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
    layout = {}             -- Visual layout configuration for tile-based GUI
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

-- Quest layout template structure
questbook.data.quest_layout_template = {
    chapter = "main",       -- Chapter/page this quest belongs to
    position = {x = 0, y = 0}, -- World coordinates (pixels)
    size = "medium",        -- Tile size: "small", "medium", "large"
    icon = {                -- Icon configuration
        type = "default",   -- "item", "image", "default"
        source = "",        -- Item name or image path
        count = 1           -- Item count display (items only)
    },
    color = nil,            -- Optional custom tile color (#RRGGBB)
    hidden = false,         -- Hide from visual display
    connections = {}        -- Custom connection styling per prerequisite
}

-- Icon types
questbook.data.ICON_TYPES = {
    ITEM = "item",          -- Use in-game item/block
    IMAGE = "image",        -- Use custom PNG/texture file  
    DEFAULT = "default"     -- Use auto-generated icon
}

-- Tile sizes with dimensions (pixels)
questbook.data.TILE_SIZES = {
    SMALL = {
        name = "small",
        width = 64,
        height = 48,
        icon_size = 32
    },
    MEDIUM = {
        name = "medium", 
        width = 96,
        height = 72,
        icon_size = 48
    },
    LARGE = {
        name = "large",
        width = 128,
        height = 96, 
        icon_size = 64
    }
}

-- Chapter layout template
questbook.data.chapter_template = {
    name = "",              -- Display name
    description = "",       -- Chapter description
    background = nil,       -- Optional background image
    icon = {                -- Chapter icon
        type = "default",   -- "item", "image", "default"
        source = "",        -- Item name or image path
        count = 1           -- Item count (items only)
    },
    viewport = {            -- Default viewport for this chapter
        x = 0, y = 0,       -- Initial pan position
        zoom = 1.0          -- Initial zoom level
    }
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

-- Validate quest layout
function questbook.data.validate_quest_layout(layout)
    if type(layout) ~= "table" then
        return false, "Layout must be a table"
    end
    
    -- Validate position
    if layout.position then
        if type(layout.position) ~= "table" then
            return false, "Layout position must be a table"
        end
        if type(layout.position.x) ~= "number" or type(layout.position.y) ~= "number" then
            return false, "Layout position must have numeric x and y coordinates"
        end
    end
    
    -- Validate size
    if layout.size then
        local valid_sizes = {"small", "medium", "large"}
        local size_valid = false
        for _, valid_size in ipairs(valid_sizes) do
            if layout.size == valid_size then
                size_valid = true
                break
            end
        end
        if not size_valid then
            return false, "Layout size must be 'small', 'medium', or 'large'"
        end
    end
    
    -- Validate icon
    if layout.icon then
        local valid, message = questbook.data.validate_icon(layout.icon)
        if not valid then
            return false, "Layout icon invalid: " .. message
        end
    end
    
    return true, "Valid layout"
end

-- Validate icon configuration
function questbook.data.validate_icon(icon)
    if type(icon) ~= "table" then
        return false, "Icon must be a table"
    end
    
    local valid_types = {"item", "image", "default"}
    local type_valid = false
    for _, valid_type in ipairs(valid_types) do
        if icon.type == valid_type then
            type_valid = true
            break
        end
    end
    if not type_valid then
        return false, "Icon type must be 'item', 'image', or 'default'"
    end
    
    -- Validate item icons
    if icon.type == "item" then
        if not icon.source or icon.source == "" then
            return false, "Item icons must have a valid source item name"
        end
        if icon.count and (type(icon.count) ~= "number" or icon.count < 1) then
            return false, "Item icon count must be a positive number"
        end
    end
    
    -- Validate image icons
    if icon.type == "image" then
        if not icon.source or icon.source == "" then
            return false, "Image icons must have a valid source file path"
        end
    end
    
    return true, "Valid icon"
end

-- Get tile size configuration
function questbook.data.get_tile_size(size_name)
    for _, size_config in pairs(questbook.data.TILE_SIZES) do
        if size_config.name == size_name then
            return size_config
        end
    end
    return questbook.data.TILE_SIZES.MEDIUM -- Default fallback
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

-- Create a quest layout configuration
function questbook.data.create_quest_layout(chapter, x, y, size)
    local layout = table.copy(questbook.data.quest_layout_template)
    layout.chapter = chapter or "main"
    layout.position = {x = x or 0, y = y or 0}
    layout.size = size or "medium"
    return layout
end

-- Create an icon configuration
function questbook.data.create_icon(icon_type, source, count)
    local icon = {
        type = icon_type or questbook.data.ICON_TYPES.DEFAULT,
        source = source or "",
        count = count or 1
    }
    return icon
end

-- Create item icon shorthand
function questbook.data.create_item_icon(item_name, count)
    return questbook.data.create_icon(questbook.data.ICON_TYPES.ITEM, item_name, count)
end

-- Create image icon shorthand  
function questbook.data.create_image_icon(image_path)
    return questbook.data.create_icon(questbook.data.ICON_TYPES.IMAGE, image_path)
end

-- Create chapter configuration
function questbook.data.create_chapter(name, description)
    local chapter = table.copy(questbook.data.chapter_template)
    chapter.name = name or ""
    chapter.description = description or ""
    return chapter
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