-- Objective tracking system for questbook
-- Automatically detects and updates quest progress based on player actions

questbook.trackers = {}

-- Track mining objectives (when players dig nodes)
minetest.register_on_dignode(function(pos, oldnode, digger)
    if not digger or not digger:is_player() then
        return
    end
    
    local player_name = digger:get_player_name()
    local node_name = oldnode.name
    
    questbook.trackers.update_mine_progress(player_name, node_name, 1)
end)

-- Track collection objectives (when players gain items)
-- We'll use inventory modifications to detect actual item collection
local player_inventories = {}

minetest.register_on_joinplayer(function(player)
    local player_name = player:get_player_name()
    player_inventories[player_name] = {}
    
    -- Take initial inventory snapshot
    local inv = player:get_inventory()
    if inv then
        for i = 1, inv:get_size("main") do
            local stack = inv:get_stack("main", i)
            if not stack:is_empty() then
                local item_name = stack:get_name()
                player_inventories[player_name][item_name] = (player_inventories[player_name][item_name] or 0) + stack:get_count()
            end
        end
    end
end)

-- Check for inventory changes every few seconds to track item collection
local inventory_check_timer = 0
minetest.register_globalstep(function(dtime)
    inventory_check_timer = inventory_check_timer + dtime
    if inventory_check_timer >= 2 then -- Check every 2 seconds
        inventory_check_timer = 0
        
        for _, player in ipairs(minetest.get_connected_players()) do
            local player_name = player:get_player_name()
            questbook.trackers.check_inventory_changes(player_name, player)
        end
    end
end)

function questbook.trackers.check_inventory_changes(player_name, player)
    if not player_inventories[player_name] then
        player_inventories[player_name] = {}
    end
    
    local old_inv = player_inventories[player_name]
    local new_inv = {}
    
    -- Get current inventory state
    local inv = player:get_inventory()
    if not inv then return end
    
    for i = 1, inv:get_size("main") do
        local stack = inv:get_stack("main", i)
        if not stack:is_empty() then
            local item_name = stack:get_name()
            new_inv[item_name] = (new_inv[item_name] or 0) + stack:get_count()
        end
    end
    
    -- Check for increases in item counts (collection)
    for item_name, new_count in pairs(new_inv) do
        local old_count = old_inv[item_name] or 0
        if new_count > old_count then
            local collected = new_count - old_count
            questbook.trackers.update_collect_progress(player_name, item_name, collected)
        end
    end
    
    -- Update stored inventory
    player_inventories[player_name] = new_inv
end

-- Track crafting objectives
minetest.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
    if not player or not player:is_player() then
        return
    end
    
    local player_name = player:get_player_name()
    local item_name = itemstack:get_name()
    local count = itemstack:get_count()
    
    questbook.trackers.update_craft_progress(player_name, item_name, count)
end)

-- Track building objectives (when players place nodes)
minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
    if not placer or not placer:is_player() then
        return
    end
    
    local player_name = placer:get_player_name()
    local node_name = newnode.name
    
    questbook.trackers.update_build_progress(player_name, node_name, 1)
end)

-- Update collect objective progress
function questbook.trackers.update_collect_progress(player_name, item_name, count)
    local player_quests = questbook.get_player_quests(player_name)
    
    for quest_id, quest_data in pairs(player_quests) do
        local progress = quest_data.progress
        if progress and progress.status == questbook.data.STATUS.ACTIVE then
            local quest = quest_data.quest
            
            -- Check each objective in the quest
            for _, objective in ipairs(quest.objectives) do
                if objective.type == questbook.data.OBJECTIVE_TYPES.COLLECT and 
                   questbook.trackers.item_matches_target(item_name, objective.target) then
                    
                    local current_progress = progress.objectives[objective.id] or 0
                    local new_progress = current_progress + count
                    
                    -- Update progress
                    questbook.update_progress(player_name, quest_id, objective.id, new_progress)
                    
                    -- Notify player only when objective is FIRST completed (not repeated notifications)
                    if new_progress >= objective.count and current_progress < objective.count then
                        minetest.chat_send_player(player_name,
                            minetest.colorize("#00FF00", "[Questbook] ") .. 
                            "Objective completed: " .. objective.description)
                    elseif quest.show_progress_chat then
                        -- Only show progress notifications if enabled for this quest
                        minetest.chat_send_player(player_name,
                            minetest.colorize("#FFFF00", "[Questbook] ") .. 
                            "Progress: " .. objective.description .. " (" .. 
                            new_progress .. "/" .. objective.count .. ")")
                    end
                end
            end
        end
    end
end

-- Update craft objective progress
function questbook.trackers.update_craft_progress(player_name, item_name, count)
    local player_quests = questbook.get_player_quests(player_name)
    
    for quest_id, quest_data in pairs(player_quests) do
        local progress = quest_data.progress
        if progress and progress.status == questbook.data.STATUS.ACTIVE then
            local quest = quest_data.quest
            
            -- Check each objective in the quest
            for _, objective in ipairs(quest.objectives) do
                if objective.type == questbook.data.OBJECTIVE_TYPES.CRAFT and 
                   questbook.trackers.item_matches_target(item_name, objective.target) then
                    
                    local current_progress = progress.objectives[objective.id] or 0
                    local new_progress = current_progress + count
                    
                    -- Update progress
                    questbook.update_progress(player_name, quest_id, objective.id, new_progress)
                    
                    -- Notify player only when objective is FIRST completed (not repeated notifications)
                    if new_progress >= objective.count and current_progress < objective.count then
                        minetest.chat_send_player(player_name,
                            minetest.colorize("#00FF00", "[Questbook] ") .. 
                            "Objective completed: " .. objective.description)
                    elseif quest.show_progress_chat then
                        -- Only show progress notifications if enabled for this quest
                        minetest.chat_send_player(player_name,
                            minetest.colorize("#FFFF00", "[Questbook] ") .. 
                            "Progress: " .. objective.description .. " (" .. 
                            new_progress .. "/" .. objective.count .. ")")
                    end
                end
            end
        end
    end
end

-- Update mine objective progress
function questbook.trackers.update_mine_progress(player_name, node_name, count)
    local player_quests = questbook.get_player_quests(player_name)
    
    for quest_id, quest_data in pairs(player_quests) do
        local progress = quest_data.progress
        if progress and progress.status == questbook.data.STATUS.ACTIVE then
            local quest = quest_data.quest
            
            -- Check each objective in the quest
            for _, objective in ipairs(quest.objectives) do
                if objective.type == questbook.data.OBJECTIVE_TYPES.MINE and 
                   questbook.trackers.item_matches_target(node_name, objective.target) then
                    
                    local current_progress = progress.objectives[objective.id] or 0
                    local new_progress = current_progress + count
                    
                    -- Update progress
                    questbook.update_progress(player_name, quest_id, objective.id, new_progress)
                    
                    -- Notify player only when objective is FIRST completed (not repeated notifications)
                    if new_progress >= objective.count and current_progress < objective.count then
                        minetest.chat_send_player(player_name,
                            minetest.colorize("#00FF00", "[Questbook] ") .. 
                            "Objective completed: " .. objective.description)
                    elseif quest.show_progress_chat then
                        -- Only show progress notifications if enabled for this quest
                        minetest.chat_send_player(player_name,
                            minetest.colorize("#FFFF00", "[Questbook] ") .. 
                            "Progress: " .. objective.description .. " (" .. 
                            new_progress .. "/" .. objective.count .. ")")
                    end
                end
            end
        end
    end
end

-- Update build objective progress
function questbook.trackers.update_build_progress(player_name, node_name, count)
    local player_quests = questbook.get_player_quests(player_name)
    
    for quest_id, quest_data in pairs(player_quests) do
        local progress = quest_data.progress
        if progress and progress.status == questbook.data.STATUS.ACTIVE then
            local quest = quest_data.quest
            
            -- Check each objective in the quest
            for _, objective in ipairs(quest.objectives) do
                if objective.type == questbook.data.OBJECTIVE_TYPES.BUILD and 
                   questbook.trackers.item_matches_target(node_name, objective.target) then
                    
                    local current_progress = progress.objectives[objective.id] or 0
                    local new_progress = current_progress + count
                    
                    -- Update progress
                    questbook.update_progress(player_name, quest_id, objective.id, new_progress)
                    
                    -- Notify player only when objective is FIRST completed (not repeated notifications)
                    if new_progress >= objective.count and current_progress < objective.count then
                        minetest.chat_send_player(player_name,
                            minetest.colorize("#00FF00", "[Questbook] ") .. 
                            "Objective completed: " .. objective.description)
                    elseif quest.show_progress_chat then
                        -- Only show progress notifications if enabled for this quest
                        minetest.chat_send_player(player_name,
                            minetest.colorize("#FFFF00", "[Questbook] ") .. 
                            "Progress: " .. objective.description .. " (" .. 
                            new_progress .. "/" .. objective.count .. ")")
                    end
                end
            end
        end
    end
end

-- Manual progress update for custom objective types
function questbook.trackers.update_custom_progress(player_name, quest_id, objective_id, progress)
    questbook.update_progress(player_name, quest_id, objective_id, progress)
    
    -- Get quest and objective for notification
    local quest = questbook.get_quest(quest_id)
    if quest then
        for _, objective in ipairs(quest.objectives) do
            if objective.id == objective_id then
                if progress >= objective.count then
                    minetest.chat_send_player(player_name,
                        minetest.colorize("#00FF00", "[Questbook] ") .. 
                        "Objective completed: " .. objective.description)
                elseif quest.show_progress_chat then
                    -- Only show progress notifications if enabled for this quest
                    minetest.chat_send_player(player_name,
                        minetest.colorize("#FFFF00", "[Questbook] ") .. 
                        "Progress: " .. objective.description .. " (" .. 
                        progress .. "/" .. objective.count .. ")")
                end
                break
            end
        end
    end
end

-- Flexible item matching system
function questbook.trackers.item_matches_target(item_name, target)
    -- Direct match
    if item_name == target then
        return true
    end
    
    -- Check for group-based matching (e.g., "group:tree" matches any tree)
    if target:match("^group:") then
        local group_name = target:gsub("^group:", "")
        return questbook.trackers.item_in_group(item_name, group_name)
    end
    
    -- Check for pattern matching (e.g., "tree" matches any item with "tree" in name)
    if target:match("^pattern:") then
        local pattern = target:gsub("^pattern:", "")
        return item_name:match(pattern) ~= nil
    end
    
    -- Check for alias matching (common item variations)
    return questbook.trackers.item_matches_alias(item_name, target)
end

-- Check if item belongs to a group
function questbook.trackers.item_in_group(item_name, group_name)
    local item_def = minetest.registered_items[item_name]
    if not item_def or not item_def.groups then
        return false
    end
    
    return item_def.groups[group_name] ~= nil and item_def.groups[group_name] > 0
end

-- Check for common item aliases and variations
function questbook.trackers.item_matches_alias(item_name, target)
    -- Define common aliases
    local aliases = {
        -- Tree/wood variations
        ["wood_logs"] = {"default:tree", "default:jungletree", "default:pine_tree", "default:acacia_tree", "default:aspen_tree"},
        ["any_tree"] = {"default:tree", "default:jungletree", "default:pine_tree", "default:acacia_tree", "default:aspen_tree"},
        ["any_wood"] = {"default:wood", "default:junglewood", "default:pine_wood", "default:acacia_wood", "default:aspen_wood"},
        
        -- Stone variations  
        ["any_stone"] = {"default:stone", "default:cobble", "default:stonebrick", "default:stone_block"},
        
        -- Ore variations
        ["any_coal"] = {"default:coal_lump", "default:stone_with_coal"},
        ["any_iron"] = {"default:iron_lump", "default:stone_with_iron"},
        ["any_diamond"] = {"default:diamond", "default:stone_with_diamond"},
    }
    
    -- Check if target is an alias
    if aliases[target] then
        for _, alias_item in ipairs(aliases[target]) do
            if item_name == alias_item then
                return true
            end
        end
    end
    
    -- Check reverse - if item_name is the alias target
    for alias_name, alias_items in pairs(aliases) do
        if target == alias_name then
            for _, alias_item in ipairs(alias_items) do
                if item_name == alias_item then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Auto-start quests with auto_start flag when prerequisites are met
function questbook.trackers.check_auto_start_quests(player_name)
    local all_quests = questbook.get_all_quests()
    
    for quest_id, quest in pairs(all_quests) do
        if quest.auto_start then
            local progress = questbook.get_progress(player_name, quest_id)
            
            -- Only auto-start if quest isn't already started/completed
            if not progress or progress.status == questbook.data.STATUS.LOCKED then
                -- Check if prerequisites are met
                local can_start = true
                for _, prereq_id in ipairs(quest.prerequisites or {}) do
                    local prereq_progress = questbook.get_progress(player_name, prereq_id)
                    if not prereq_progress or prereq_progress.status ~= questbook.data.STATUS.COMPLETED then
                        can_start = false
                        break
                    end
                end
                
                if can_start then
                    local success = questbook.start_quest(player_name, quest_id)
                    if success then
                        minetest.chat_send_player(player_name,
                            minetest.colorize("#00FF00", "[Questbook] ") .. 
                            "New quest available: " .. quest.title)
                    end
                end
            end
        end
    end
end

-- Check for auto-start quests when player joins
minetest.register_on_joinplayer(function(player)
    local player_name = player:get_player_name()
    -- Delay to ensure player data is loaded
    minetest.after(2, function()
        questbook.trackers.check_auto_start_quests(player_name)
    end)
end)

-- Periodic check for quest completion and auto-start (every 30 seconds)
local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer >= 30 then
        timer = 0
        
        for _, player in ipairs(minetest.get_connected_players()) do
            local player_name = player:get_player_name()
            questbook.trackers.check_auto_start_quests(player_name)
        end
    end
end)

minetest.log("action", "[Questbook] Objective tracking system loaded")