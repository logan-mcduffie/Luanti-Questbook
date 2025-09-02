-- Quest registration and management API
-- Public API for other mods to register and manage quests

questbook.api = questbook.api or {}

-- Register a new quest
function questbook.register_quest(quest)
    return questbook.storage.register_quest(quest)
end

-- Create a quest using builder pattern
function questbook.create_quest(id, title, description)
    local quest = questbook.data.create_quest_template(id, title, description)
    -- Initialize with default layout
    quest.layout = questbook.data.create_quest_layout()
    return quest
end

-- Add objective to quest
function questbook.add_objective(quest, obj_id, obj_type, description, target, count)
    if not quest.objectives then
        quest.objectives = {}
    end
    
    local objective = questbook.data.create_objective(obj_id, obj_type, description, target, count)
    table.insert(quest.objectives, objective)
    return quest
end

-- Add reward to quest
function questbook.add_reward(quest, reward_type, item, count)
    if not quest.rewards then
        quest.rewards = {}
    end
    
    local reward = questbook.data.create_reward(reward_type, item, count)
    table.insert(quest.rewards, reward)
    return quest
end

-- Add currency reward to quest
function questbook.add_currency_reward(quest, amount)
    if not quest.rewards then
        quest.rewards = {}
    end
    
    local reward = questbook.data.create_currency_reward(amount)
    table.insert(quest.rewards, reward)
    return quest
end

-- Add lootbag reward to quest
function questbook.add_lootbag_reward(quest, name, items, max_rolls)
    if not quest.rewards then
        quest.rewards = {}
    end
    
    local reward = questbook.data.create_lootbag_reward(name, items, max_rolls)
    table.insert(quest.rewards, reward)
    return quest
end

-- Set quest prerequisites
function questbook.set_prerequisites(quest, prerequisite_quest_ids)
    quest.prerequisites = prerequisite_quest_ids or {}
    return quest
end

-- Set quest properties
function questbook.set_quest_properties(quest, properties)
    if properties.category then quest.category = properties.category end
    if properties.quest_type then quest.quest_type = properties.quest_type end
    if properties.time_limit then quest.time_limit = properties.time_limit end
    if properties.repeatable ~= nil then quest.repeatable = properties.repeatable end
    if properties.repeat_cooldown then quest.repeat_cooldown = properties.repeat_cooldown end
    if properties.repeat_type then quest.repeat_type = properties.repeat_type end
    if properties.auto_start ~= nil then quest.auto_start = properties.auto_start end
    if properties.hidden ~= nil then quest.hidden = properties.hidden end
    if properties.show_progress_chat ~= nil then quest.show_progress_chat = properties.show_progress_chat end
    if properties.hide_when_locked ~= nil then quest.hide_when_locked = properties.hide_when_locked end
    if properties.party_shared ~= nil then quest.party_shared = properties.party_shared end
    return quest
end

-- Set quest layout (position, size, icon)
function questbook.set_quest_layout(quest, chapter, x, y, size)
    if not quest.layout then
        quest.layout = questbook.data.create_quest_layout()
    end
    
    if chapter then quest.layout.chapter = chapter end
    if x and y then 
        quest.layout.position.x = x
        quest.layout.position.y = y
    end
    if size then quest.layout.size = size end
    
    return quest
end

-- Set quest icon
function questbook.set_quest_icon(quest, icon_type, source, count)
    if not quest.layout then
        quest.layout = questbook.data.create_quest_layout()
    end
    
    quest.layout.icon = questbook.data.create_icon(icon_type, source, count)
    return quest
end

-- Set quest item icon (shorthand)
function questbook.set_quest_item_icon(quest, item_name, count)
    return questbook.set_quest_icon(quest, questbook.data.ICON_TYPES.ITEM, item_name, count)
end

-- Set quest image icon (shorthand)
function questbook.set_quest_image_icon(quest, image_path)
    return questbook.set_quest_icon(quest, questbook.data.ICON_TYPES.IMAGE, image_path)
end

-- Set quest tile color
function questbook.set_quest_color(quest, color)
    if not quest.layout then
        quest.layout = questbook.data.create_quest_layout()
    end
    
    quest.layout.color = color
    return quest
end

-- Get registered quest by ID
function questbook.get_quest(quest_id)
    return questbook.storage.get_quest(quest_id)
end

-- Get all registered quests
function questbook.get_all_quests()
    return questbook.storage.get_all_quests()
end

-- Remove a registered quest
function questbook.unregister_quest(quest_id)
    return questbook.storage.unregister_quest(quest_id)
end

-- Player quest management
function questbook.start_quest(player_name, quest_id)
    local quest = questbook.storage.get_quest(quest_id)
    if not quest then
        return false, "Quest not found: " .. quest_id
    end
    
    local progress = questbook.storage.get_player_quest_progress(player_name, quest_id)
    if progress and progress.status ~= questbook.data.STATUS.LOCKED and 
       progress.status ~= questbook.data.STATUS.AVAILABLE then
        return false, "Quest already started or completed"
    end
    
    -- Check prerequisites
    for _, prereq_id in ipairs(quest.prerequisites or {}) do
        local prereq_progress = questbook.storage.get_player_quest_progress(player_name, prereq_id)
        if not prereq_progress or prereq_progress.status ~= questbook.data.STATUS.COMPLETED then
            return false, "Prerequisites not met: " .. prereq_id
        end
    end
    
    -- Initialize quest progress
    local new_progress = table.copy(questbook.data.player_progress_template)
    new_progress.status = questbook.data.STATUS.ACTIVE
    new_progress.start_time = os.time()
    new_progress.objectives = {}
    
    -- Initialize objective progress
    for _, objective in ipairs(quest.objectives) do
        new_progress.objectives[objective.id] = 0
    end
    
    questbook.storage.set_player_quest_progress(player_name, quest_id, new_progress)
    
    -- Fire quest start event
    questbook.events.fire_quest_start(player_name, quest_id)
    
    minetest.log("action", "[Questbook] Player " .. player_name .. " started quest: " .. quest_id)
    return true, "Quest started successfully"
end

-- Update objective progress (party-aware)
function questbook.update_progress(player_name, quest_id, objective_id, progress)
    local quest = questbook.storage.get_quest(quest_id)
    if not quest then
        return false, "Quest not found"
    end
    
    -- Get progress (party or individual)
    local player_progress = questbook.get_progress(player_name, quest_id)
    if not player_progress or player_progress.status ~= questbook.data.STATUS.ACTIVE then
        return false, "Quest not active"
    end
    
    -- Find objective
    local objective = nil
    for _, obj in ipairs(quest.objectives) do
        if obj.id == objective_id then
            objective = obj
            break
        end
    end
    
    if not objective then
        return false, "Objective not found"
    end
    
    -- Update progress
    local old_progress = player_progress.objectives[objective_id] or 0
    player_progress.objectives[objective_id] = math.max(old_progress, progress)
    
    -- Fire progress event
    questbook.events.fire_objective_progress(player_name, quest_id, objective_id, progress)
    
    -- Check if objective is complete
    if progress >= objective.count then
        questbook.events.fire_objective_complete(player_name, quest_id, objective_id)
        
        -- Check if quest is complete
        questbook.api.check_quest_completion(player_name, quest_id)
    end
    
    -- Save progress (party or individual)
    if questbook.party.should_use_party_progress(player_name, quest_id) then
        local party_id = questbook.party.get_player_party(player_name)
        if party_id then
            questbook.party.set_party_quest_progress(party_id, quest_id, player_progress)
            
            -- Notify all party members of progress (only for completion)
            if progress >= objective.count then
                questbook.party.notify_party(party_id,
                    minetest.colorize("#00FF00", "[Party Quest] ") .. 
                    "Objective completed: " .. objective.description)
            end
        end
    else
        questbook.storage.set_player_quest_progress(player_name, quest_id, player_progress)
    end
    
    return true, "Progress updated"
end

-- Check if quest is completed
function questbook.api.check_quest_completion(player_name, quest_id)
    local quest = questbook.storage.get_quest(quest_id)
    local player_progress = questbook.storage.get_player_quest_progress(player_name, quest_id)
    
    if not quest or not player_progress or player_progress.status ~= questbook.data.STATUS.ACTIVE then
        return false
    end
    
    -- Check all required objectives
    local all_complete = true
    for _, objective in ipairs(quest.objectives) do
        if not objective.optional then
            local obj_progress = player_progress.objectives[objective.id] or 0
            if obj_progress < objective.count then
                all_complete = false
                break
            end
        end
    end
    
    if all_complete then
        player_progress.status = questbook.data.STATUS.COMPLETED
        player_progress.complete_time = os.time()
        
        questbook.storage.set_player_quest_progress(player_name, quest_id, player_progress)
        
        -- Give rewards
        questbook.api.give_quest_rewards(player_name, quest_id)
        
        -- Fire completion event
        questbook.events.fire_quest_complete(player_name, quest_id)
        
        -- Auto-start available quests after completion
        questbook.auto_start_quests(player_name)
        
        -- Handle repeatable quests
        if quest.repeatable then
            questbook.api.handle_quest_repeat(player_name, quest_id)
        end
        
        minetest.log("action", "[Questbook] Player " .. player_name .. " completed quest: " .. quest_id)
        return true
    end
    
    return false
end

-- Give quest rewards to player
function questbook.api.give_quest_rewards(player_name, quest_id)
    local quest = questbook.storage.get_quest(quest_id)
    if not quest or not quest.rewards then
        return
    end
    
    local player = minetest.get_player_by_name(player_name)
    if not player then
        return
    end
    
    minetest.chat_send_player(player_name, 
        minetest.colorize("#00FF00", "[Questbook] ") .. 
        "Quest completed: " .. quest.title)
    
    if #quest.rewards > 0 then
        minetest.chat_send_player(player_name, 
            minetest.colorize("#FFD700", "[Questbook] Rewards received:"))
    end
    
    for _, reward in ipairs(quest.rewards) do
        if reward.type == questbook.data.REWARD_TYPES.ITEM then
            local inv = player:get_inventory()
            local itemstack = ItemStack(reward.item .. " " .. reward.count)
            local leftover = inv:add_item("main", itemstack)
            
            if leftover:is_empty() then
                minetest.chat_send_player(player_name, 
                    minetest.colorize("#FFD700", "  • ") .. 
                    reward.count .. "x " .. reward.item)
            else
                -- Drop items that don't fit in inventory
                minetest.add_item(player:get_pos(), leftover)
                minetest.chat_send_player(player_name, 
                    minetest.colorize("#FFD700", "  • ") .. 
                    reward.count .. "x " .. reward.item .. " (dropped)")
            end
            
        elseif reward.type == questbook.data.REWARD_TYPES.EXPERIENCE then
            -- XP reward (if experience mod is available)
            if minetest.get_modpath("experience") then
                experience.add_experience(player_name, reward.count)
                minetest.chat_send_player(player_name, 
                    minetest.colorize("#FFD700", "  • ") .. 
                    reward.count .. " experience points")
            end
            
        elseif reward.type == questbook.data.REWARD_TYPES.CURRENCY then
            -- Currency reward (if economy mod is available)
            if minetest.get_modpath("money") then
                money.set_money(player_name, money.get_money(player_name) + reward.count)
                minetest.chat_send_player(player_name, 
                    minetest.colorize("#FFD700", "  • ") .. 
                    reward.count .. " coins")
            end
            
        elseif reward.type == questbook.data.REWARD_TYPES.QB_CURRENCY then
            -- Questbook virtual currency reward
            questbook.storage.add_player_currency(player_name, reward.count)
            questbook.storage.update_player_statistics(player_name, "currency_earned", reward.count)
            minetest.chat_send_player(player_name, 
                minetest.colorize("#FFD700", "  • ") .. 
                reward.count .. " questbook currency")
            
        elseif reward.type == questbook.data.REWARD_TYPES.LOOTBAG then
            -- Lootbag reward - random weighted selection
            local loot_items = questbook.api.roll_lootbag(reward)
            if #loot_items > 0 then
                minetest.chat_send_player(player_name, 
                    minetest.colorize("#FFD700", "  • ") .. reward.item .. ":")
                
                local inv = player:get_inventory()
                for _, loot_item in ipairs(loot_items) do
                    local itemstack = ItemStack(loot_item.item .. " " .. loot_item.count)
                    local leftover = inv:add_item("main", itemstack)
                    
                    if leftover:is_empty() then
                        minetest.chat_send_player(player_name, 
                            minetest.colorize("#FFD700", "    - ") .. 
                            loot_item.count .. "x " .. loot_item.item)
                    else
                        -- Drop items that don't fit in inventory
                        minetest.add_item(player:get_pos(), leftover)
                        minetest.chat_send_player(player_name, 
                            minetest.colorize("#FFD700", "    - ") .. 
                            loot_item.count .. "x " .. loot_item.item .. " (dropped)")
                    end
                end
            end
            
        elseif reward.type == questbook.data.REWARD_TYPES.CUSTOM then
            -- Custom reward handling - fire event for other mods
            questbook.events.fire_custom_reward(player_name, quest_id, reward)
        end
    end
end

-- Get player's quest progress (party-aware)
function questbook.get_progress(player_name, quest_id)
    -- Check if quest should use party progress
    if questbook.party.should_use_party_progress(player_name, quest_id) then
        local party_id = questbook.party.get_player_party(player_name)
        if party_id then
            return questbook.party.get_party_quest_progress(party_id, quest_id)
        end
    end
    
    -- Use individual progress
    return questbook.storage.get_player_quest_progress(player_name, quest_id)
end

-- Get all player's quests with their progress
function questbook.get_player_quests(player_name)
    local player_data = questbook.storage.get_player_data(player_name)
    local quests = {}
    
    for quest_id, progress in pairs(player_data) do
        local quest = questbook.storage.get_quest(quest_id)
        if quest then
            quests[quest_id] = {
                quest = quest,
                progress = progress
            }
        end
    end
    
    return quests
end

-- Auto-start available quests for player
function questbook.auto_start_quests(player_name)
    local all_quests = questbook.get_all_quests()
    local started_count = 0
    
    for quest_id, quest in pairs(all_quests) do
        local progress = questbook.get_progress(player_name, quest_id)
        
        -- Only auto-start if quest has no progress and auto_start is enabled
        if not progress and quest.auto_start then
            -- Check if prerequisites are met
            if questbook.settings.quest_prereqs_met(player_name, quest) then
                -- Start the quest
                local success = questbook.start_quest(player_name, quest_id)
                if success then
                    started_count = started_count + 1
                    
                    -- Notify player
                    minetest.chat_send_player(player_name,
                        minetest.colorize("#00FF00", "[Questbook] ") .. 
                        "New quest available: " .. quest.title)
                end
            end
        end
    end
    
    return started_count
end

-- Check if quest is completed (helper function)
function questbook.is_quest_completed(player_name, quest_id)
    local progress = questbook.get_progress(player_name, quest_id)
    return progress and progress.status == questbook.data.STATUS.COMPLETED
end

-- Check if player has required items for consume quest
function questbook.check_consume_quest_items(player_name, quest_id)
    local quest = questbook.get_quest(quest_id)
    if not quest or quest.quest_type ~= questbook.data.QUEST_TYPES.CONSUME then
        return false, "Not a consume quest"
    end
    
    local player = minetest.get_player_by_name(player_name)
    if not player then
        return false, "Player not found"
    end
    
    local inv = player:get_inventory()
    local missing_items = {}
    
    -- Check each objective for required items
    for _, objective in ipairs(quest.objectives) do
        if objective.type == questbook.data.OBJECTIVE_TYPES.COLLECT then
            local has_count = 0
            
            -- Count matching items in inventory
            for i = 1, inv:get_size("main") do
                local stack = inv:get_stack("main", i)
                if questbook.trackers.item_matches_target(stack:get_name(), objective.target) then
                    has_count = has_count + stack:get_count()
                end
            end
            
            if has_count < objective.count then
                table.insert(missing_items, {
                    target = objective.target,
                    needed = objective.count,
                    has = has_count
                })
            end
        end
    end
    
    if #missing_items > 0 then
        return false, "Missing items", missing_items
    end
    
    return true, "All items available"
end

-- Submit items for consume quest (consume items and complete quest)
function questbook.submit_consume_quest(player_name, quest_id)
    local quest = questbook.get_quest(quest_id)
    if not quest or quest.quest_type ~= questbook.data.QUEST_TYPES.CONSUME then
        return false, "Not a consume quest"
    end
    
    local progress = questbook.get_progress(player_name, quest_id)
    if not progress or progress.status ~= questbook.data.STATUS.ACTIVE then
        return false, "Quest not active"
    end
    
    -- Check if player has required items
    local has_items, msg, missing = questbook.check_consume_quest_items(player_name, quest_id)
    if not has_items then
        return false, msg, missing
    end
    
    local player = minetest.get_player_by_name(player_name)
    if not player then
        return false, "Player not found"
    end
    
    local inv = player:get_inventory()
    
    -- Consume required items
    for _, objective in ipairs(quest.objectives) do
        if objective.type == questbook.data.OBJECTIVE_TYPES.COLLECT then
            local remaining_to_consume = objective.count
            
            -- Remove items from inventory
            for i = 1, inv:get_size("main") do
                if remaining_to_consume <= 0 then
                    break
                end
                
                local stack = inv:get_stack("main", i)
                if questbook.trackers.item_matches_target(stack:get_name(), objective.target) then
                    local consume_count = math.min(remaining_to_consume, stack:get_count())
                    stack:take_item(consume_count)
                    inv:set_stack("main", i, stack)
                    remaining_to_consume = remaining_to_consume - consume_count
                end
            end
        end
    end
    
    -- Complete the quest
    progress.status = questbook.data.STATUS.COMPLETED
    progress.complete_time = os.time()
    questbook.storage.set_player_quest_progress(player_name, quest_id, progress)
    
    -- Give rewards
    questbook.api.give_quest_rewards(player_name, quest_id)
    
    -- Fire completion event
    questbook.events.fire_quest_complete(player_name, quest_id)
    
    -- Auto-start available quests after completion
    questbook.auto_start_quests(player_name)
    
    minetest.log("action", "[Questbook] Player " .. player_name .. " submitted consume quest: " .. quest_id)
    return true, "Items submitted and quest completed"
end

-- Complete checkbox quest (simple manual completion)
function questbook.complete_checkbox_quest(player_name, quest_id)
    local quest = questbook.get_quest(quest_id)
    if not quest or quest.quest_type ~= questbook.data.QUEST_TYPES.CHECKBOX then
        return false, "Not a checkbox quest"
    end
    
    local progress = questbook.get_progress(player_name, quest_id)
    if not progress or progress.status ~= questbook.data.STATUS.ACTIVE then
        return false, "Quest not active"
    end
    
    -- Complete the quest
    progress.status = questbook.data.STATUS.COMPLETED
    progress.complete_time = os.time()
    questbook.storage.set_player_quest_progress(player_name, quest_id, progress)
    
    -- Give rewards
    questbook.api.give_quest_rewards(player_name, quest_id)
    
    -- Fire completion event
    questbook.events.fire_quest_complete(player_name, quest_id)
    
    -- Auto-start available quests after completion
    questbook.auto_start_quests(player_name)
    
    minetest.log("action", "[Questbook] Player " .. player_name .. " completed checkbox quest: " .. quest_id)
    return true, "Quest completed"
end

-- Roll lootbag rewards with weighted random selection
function questbook.api.roll_lootbag(reward)
    local items = reward.data.items or {}
    local max_rolls = reward.count or 1
    local selected_items = {}
    
    for roll = 1, max_rolls do
        -- Calculate total weight for weighted selection
        local total_weight = 0
        for _, item_data in ipairs(items) do
            total_weight = total_weight + (item_data.weight or 1)
        end
        
        if total_weight <= 0 then
            break -- No valid items
        end
        
        -- Roll random number
        local roll_value = math.random() * total_weight
        local current_weight = 0
        
        -- Select item based on weight
        for _, item_data in ipairs(items) do
            current_weight = current_weight + (item_data.weight or 1)
            if roll_value <= current_weight then
                -- Check chance if specified
                local chance = item_data.chance or 100
                if math.random(1, 100) <= chance then
                    table.insert(selected_items, {
                        item = item_data.item,
                        count = item_data.count or 1
                    })
                end
                break
            end
        end
    end
    
    return selected_items
end

-- Repeatable quest management
function questbook.api.handle_quest_repeat(player_name, quest_id)
    local quest = questbook.get_quest(quest_id)
    if not quest or not quest.repeatable then
        return false
    end
    
    local progress = questbook.get_progress(player_name, quest_id)
    if not progress then
        return false
    end
    
    -- Update completion tracking
    progress.last_completion = os.time()
    progress.completion_count = (progress.completion_count or 0) + 1
    
    -- Update statistics
    questbook.storage.update_player_statistics(player_name, "quests_completed", 1)
    
    local repeat_type = quest.repeat_type or "manual"
    
    if repeat_type == "manual" then
        -- Manual repeat - reset quest to available immediately
        progress.status = questbook.data.STATUS.AVAILABLE
        progress.objectives = {}
        progress.start_time = nil
        progress.complete_time = nil
    elseif repeat_type == "cooldown" then
        -- Cooldown repeat - quest becomes available after cooldown period
        progress.status = questbook.data.STATUS.LOCKED
        progress.objectives = {}
        progress.start_time = nil
        progress.complete_time = nil
        -- Quest will become available again when cooldown expires
    elseif repeat_type == "daily" then
        -- Daily repeat - resets at next day
        progress.status = questbook.data.STATUS.LOCKED
        progress.objectives = {}
        progress.start_time = nil
        progress.complete_time = nil
    elseif repeat_type == "weekly" then
        -- Weekly repeat - resets at next week
        progress.status = questbook.data.STATUS.LOCKED
        progress.objectives = {}
        progress.start_time = nil
        progress.complete_time = nil
    end
    
    -- Save progress
    if questbook.party.should_use_party_progress(player_name, quest_id) then
        local party_id = questbook.party.get_player_party(player_name)
        if party_id then
            questbook.party.set_party_quest_progress(party_id, quest_id, progress)
        end
    else
        questbook.storage.set_player_quest_progress(player_name, quest_id, progress)
    end
    
    minetest.log("action", "[Questbook] Quest " .. quest_id .. " set up for repeat (" .. repeat_type .. ") for player " .. player_name)
    return true
end

-- Check if a repeatable quest can be started again
function questbook.api.can_repeat_quest(player_name, quest_id)
    local quest = questbook.get_quest(quest_id)
    if not quest or not quest.repeatable then
        return false, "Quest is not repeatable"
    end
    
    local progress = questbook.get_progress(player_name, quest_id)
    if not progress or not progress.last_completion then
        return true, "Quest has never been completed"
    end
    
    local repeat_type = quest.repeat_type or "manual"
    local now = os.time()
    
    if repeat_type == "manual" then
        return progress.status == questbook.data.STATUS.AVAILABLE, "Manual repeat quest"
    elseif repeat_type == "cooldown" then
        local cooldown = quest.repeat_cooldown or 0
        local time_since_completion = now - progress.last_completion
        if time_since_completion >= cooldown then
            return true, "Cooldown expired"
        else
            local remaining = cooldown - time_since_completion
            return false, "Cooldown remaining: " .. questbook.api.format_time(remaining)
        end
    elseif repeat_type == "daily" then
        local last_day = os.date("*t", progress.last_completion).yday
        local current_day = os.date("*t", now).yday
        return current_day ~= last_day, "Daily reset check"
    elseif repeat_type == "weekly" then
        local last_week = math.floor(progress.last_completion / (7 * 24 * 60 * 60))
        local current_week = math.floor(now / (7 * 24 * 60 * 60))
        return current_week ~= last_week, "Weekly reset check"
    end
    
    return false, "Unknown repeat type"
end

-- Reset a repeatable quest if conditions are met
function questbook.api.try_reset_repeatable_quest(player_name, quest_id)
    local can_repeat, reason = questbook.api.can_repeat_quest(player_name, quest_id)
    if not can_repeat then
        return false, reason
    end
    
    local quest = questbook.get_quest(quest_id)
    local progress = questbook.get_progress(player_name, quest_id)
    
    if not progress then
        return false, "No progress found"
    end
    
    -- Reset quest to available state
    progress.status = questbook.data.STATUS.AVAILABLE
    progress.objectives = {}
    progress.start_time = nil
    progress.complete_time = nil
    
    -- Save progress
    if questbook.party.should_use_party_progress(player_name, quest_id) then
        local party_id = questbook.party.get_player_party(player_name)
        if party_id then
            questbook.party.set_party_quest_progress(party_id, quest_id, progress)
        end
    else
        questbook.storage.set_player_quest_progress(player_name, quest_id, progress)
    end
    
    minetest.log("action", "[Questbook] Reset repeatable quest " .. quest_id .. " for player " .. player_name)
    return true, "Quest reset successfully"
end

-- Format time in seconds to readable format
function questbook.api.format_time(seconds)
    if seconds < 60 then
        return seconds .. "s"
    elseif seconds < 3600 then
        return math.floor(seconds / 60) .. "m " .. (seconds % 60) .. "s"
    elseif seconds < 86400 then
        return math.floor(seconds / 3600) .. "h " .. math.floor((seconds % 3600) / 60) .. "m"
    else
        return math.floor(seconds / 86400) .. "d " .. math.floor((seconds % 86400) / 3600) .. "h"
    end
end

-- Check and reset daily/weekly/cooldown quests for all players (called periodically)
function questbook.api.check_repeatable_quests()
    local all_quests = questbook.get_all_quests()
    
    -- Get list of all players who have quest data
    local world_path = minetest.get_worldpath()
    local player_data_path = world_path .. "/questbook_players/"
    local player_files = minetest.get_dir_list(player_data_path, false)
    
    for _, filename in ipairs(player_files) do
        if filename:match("%.lua$") then
            local player_name = filename:gsub("%.lua$", "")
            
            for quest_id, quest in pairs(all_quests) do
                if quest.repeatable then
                    questbook.api.try_reset_repeatable_quest(player_name, quest_id)
                end
            end
        end
    end
end

-- Schedule periodic check for repeatable quests (every 5 minutes)
local repeatable_timer = 0
minetest.register_globalstep(function(dtime)
    repeatable_timer = repeatable_timer + dtime
    if repeatable_timer >= 300 then -- 5 minutes
        repeatable_timer = 0
        questbook.api.check_repeatable_quests()
    end
end)

minetest.log("action", "[Questbook] Quest API loaded")