-- Keybind system for questbook
-- Uses custom keybind registration for reliable key detection

questbook.keybind = {}

-- Register the questbook keybind using Luanti's keybind system
minetest.register_on_mods_loaded(function()
    -- Register custom keybind for questbook
    if minetest.register_key then
        minetest.register_key("questbook:open", {
            description = "Open Questbook",
            default_key = "KEY_GRAVE", -- ~ key (grave accent)
        })
        
        minetest.log("action", "[Questbook] Registered questbook keybind")
    end
end)

-- Handle keybind press using on_player_receive_fields for custom keys
-- Since Luanti doesn't have a direct way to catch custom keybinds in mods,
-- we'll use a different approach with chat commands and inform users

-- Alternative approach: Use a simple key combination
-- Track player key states for Ctrl+Q combination
local player_key_states = {}

function questbook.keybind.init_player(player_name)
    if not player_key_states[player_name] then
        player_key_states[player_name] = {
            sneak_pressed = false,
            jump_pressed = false
        }
    end
end

-- Check for Ctrl+Q (sneak+jump) combination as questbook keybind
minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local player_name = player:get_player_name()
        local controls = player:get_player_control()
        
        questbook.keybind.init_player(player_name)
        local state = player_key_states[player_name]
        
        -- Check for sneak+jump combination (easier to detect reliably)
        if controls.sneak and controls.jump and not (state.sneak_pressed and state.jump_pressed) then
            questbook.keybind.handle_questbook_key(player_name)
        end
        
        state.sneak_pressed = controls.sneak
        state.jump_pressed = controls.jump
    end
end)

-- Handle questbook key press
function questbook.keybind.handle_questbook_key(player_name)
    -- Add a small delay to prevent spam opening
    minetest.after(0.1, function()
        questbook.handlers.show_questbook(player_name)
        minetest.chat_send_player(player_name, 
            minetest.colorize("#00FF00", "[Questbook] ") .. "Opening questbook...")
    end)
end

-- Clean up key states when player leaves
minetest.register_on_leaveplayer(function(player)
    local player_name = player:get_player_name()
    player_key_states[player_name] = nil
end)

-- Chat command as alternative to keybind
minetest.register_chatcommand("questbook", {
    description = "Open the questbook",
    func = function(name, param)
        questbook.handlers.show_questbook(name)
        return true, "Opening questbook..."
    end
})

-- Short alias for easier access
minetest.register_chatcommand("qb", {
    description = "Open the questbook (short alias)",
    func = function(name, param)
        questbook.handlers.show_questbook(name)
        return true, "Opening questbook..."
    end
})

-- Admin commands for quest management
minetest.register_chatcommand("quest_debug", {
    description = "Debug quest information",
    privs = {server = true},
    func = function(name, param)
        local args = param:split(" ")
        local cmd = args[1]
        
        if cmd == "list" then
            local quests = questbook.get_all_quests()
            local count = 0
            for quest_id, quest in pairs(quests) do
                minetest.chat_send_player(name, quest_id .. ": " .. quest.title)
                count = count + 1
            end
            return true, "Listed " .. count .. " registered quests"
            
        elseif cmd == "progress" then
            local target_player = args[2] or name
            local quest_id = args[3]
            
            if quest_id then
                local progress = questbook.get_progress(target_player, quest_id)
                if progress then
                    minetest.chat_send_player(name, "Quest " .. quest_id .. " status: " .. progress.status)
                    if progress.objectives then
                        for obj_id, obj_progress in pairs(progress.objectives) do
                            minetest.chat_send_player(name, "  " .. obj_id .. ": " .. obj_progress)
                        end
                    end
                else
                    minetest.chat_send_player(name, "No progress found for quest: " .. quest_id)
                end
            else
                local player_quests = questbook.get_player_quests(target_player)
                for quest_id, data in pairs(player_quests) do
                    minetest.chat_send_player(name, quest_id .. ": " .. data.progress.status)
                end
            end
            return true, "Quest progress displayed"
            
        elseif cmd == "start" then
            local target_player = args[2] or name
            local quest_id = args[3]
            
            if quest_id then
                local success, message = questbook.start_quest(target_player, quest_id)
                return success, message
            else
                return false, "Usage: /quest_debug start [player] <quest_id>"
            end
            
        else
            return false, "Usage: /quest_debug <list|progress|start> [args]"
        end
    end
})

-- Admin command for quest visibility settings
minetest.register_chatcommand("quest_settings", {
    description = "Configure quest visibility settings",
    privs = {server = true},
    func = function(name, param)
        local args = param:split(" ")
        local cmd = args[1]
        
        if cmd == "get" then
            local settings = questbook.settings.get_all()
            minetest.chat_send_player(name, "Quest Settings:")
            for key, value in pairs(settings) do
                minetest.chat_send_player(name, "  " .. key .. ": " .. tostring(value))
            end
            return true, "Settings displayed"
            
        elseif cmd == "set" then
            local setting_name = args[2]
            local value = args[3]
            
            if not setting_name or not value then
                return false, "Usage: /quest_settings set <setting> <value>"
            end
            
            -- Convert string to boolean for boolean settings
            if value == "true" then
                value = true
            elseif value == "false" then
                value = false
            end
            
            local success = questbook.settings.set(setting_name, value)
            if success then
                return true, "Setting " .. setting_name .. " set to " .. tostring(value)
            else
                return false, "Invalid setting: " .. setting_name
            end
            
        else
            return false, "Usage: /quest_settings <get|set> [setting] [value]\n" ..
                        "Available settings:\n" ..
                        "  hide_locked_quests: Hide quests when prerequisites not met\n" ..
                        "  show_prerequisite_info: Show prerequisite information\n" ..
                        "  show_locked_objectives: Show objectives for locked quests\n" ..
                        "  show_locked_rewards: Show rewards for locked quests"
        end
    end
})

-- Admin commands for currency management
minetest.register_chatcommand("qb_currency", {
    description = "Manage player questbook currency",
    privs = {server = true},
    func = function(name, param)
        local args = param:split(" ")
        local cmd = args[1]
        
        if cmd == "get" then
            local target_player = args[2] or name
            local currency = questbook.storage.get_player_currency(target_player)
            return true, target_player .. " has " .. currency .. " questbook currency"
            
        elseif cmd == "set" then
            local target_player = args[2]
            local amount = tonumber(args[3])
            
            if not target_player or not amount then
                return false, "Usage: /qb_currency set <player> <amount>"
            end
            
            questbook.storage.set_player_currency(target_player, amount)
            return true, "Set " .. target_player .. "'s currency to " .. amount
            
        elseif cmd == "add" then
            local target_player = args[2]
            local amount = tonumber(args[3])
            
            if not target_player or not amount then
                return false, "Usage: /qb_currency add <player> <amount>"
            end
            
            questbook.storage.add_player_currency(target_player, amount)
            local new_total = questbook.storage.get_player_currency(target_player)
            return true, "Added " .. amount .. " currency to " .. target_player .. " (total: " .. new_total .. ")"
            
        elseif cmd == "remove" then
            local target_player = args[2]
            local amount = tonumber(args[3])
            
            if not target_player or not amount then
                return false, "Usage: /qb_currency remove <player> <amount>"
            end
            
            local success = questbook.storage.remove_player_currency(target_player, amount)
            local new_total = questbook.storage.get_player_currency(target_player)
            if success then
                return true, "Removed " .. amount .. " currency from " .. target_player .. " (total: " .. new_total .. ")"
            else
                return false, "Not enough currency to remove " .. amount .. " from " .. target_player
            end
            
        else
            return false, "Usage: /qb_currency <get|set|add|remove> [player] [amount]"
        end
    end
})

-- Admin command for player statistics
minetest.register_chatcommand("qb_stats", {
    description = "View player questbook statistics",
    privs = {server = true},
    func = function(name, param)
        local target_player = param ~= "" and param or name
        local stats = questbook.storage.get_player_statistics(target_player)
        local currency = questbook.storage.get_player_currency(target_player)
        
        minetest.chat_send_player(name, "=== " .. target_player .. "'s Questbook Stats ===")
        minetest.chat_send_player(name, "Currency: " .. currency)
        minetest.chat_send_player(name, "Quests completed: " .. stats.quests_completed)
        minetest.chat_send_player(name, "Total objectives: " .. stats.total_objectives)
        minetest.chat_send_player(name, "Currency earned: " .. stats.currency_earned)
        
        return true, "Statistics displayed"
    end
})

-- Advanced admin command for quest manipulation
minetest.register_chatcommand("qb_admin", {
    description = "Advanced questbook administration",
    privs = {server = true},
    func = function(name, param)
        local args = param:split(" ")
        local cmd = args[1]
        
        if cmd == "reset_player" then
            local target_player = args[2]
            if not target_player then
                return false, "Usage: /qb_admin reset_player <player>"
            end
            
            -- Clear all player data
            local world_path = minetest.get_worldpath()
            local player_data_path = world_path .. "/questbook_players/" .. target_player .. ".lua"
            local file = io.open(player_data_path, "w")
            if file then
                file:write("-- Questbook player data for " .. target_player .. " (ADMIN RESET)\n")
                file:write("return {}")
                file:close()
            end
            
            return true, "Reset all questbook data for " .. target_player
            
        elseif cmd == "complete_quest" then
            local target_player = args[2]
            local quest_id = args[3]
            
            if not target_player or not quest_id then
                return false, "Usage: /qb_admin complete_quest <player> <quest_id>"
            end
            
            local progress = questbook.get_progress(target_player, quest_id)
            if not progress then
                -- Create new progress
                local quest = questbook.get_quest(quest_id)
                if not quest then
                    return false, "Quest not found: " .. quest_id
                end
                
                progress = table.copy(questbook.data.player_progress_template)
                progress.status = questbook.data.STATUS.ACTIVE
                progress.objectives = {}
                for _, obj in ipairs(quest.objectives) do
                    progress.objectives[obj.id] = obj.count
                end
            end
            
            -- Force complete the quest
            progress.status = questbook.data.STATUS.COMPLETED
            progress.complete_time = os.time()
            questbook.storage.set_player_quest_progress(target_player, quest_id, progress)
            
            -- Give rewards
            questbook.api.give_quest_rewards(target_player, quest_id)
            
            return true, "Force completed quest " .. quest_id .. " for " .. target_player
            
        elseif cmd == "reset_quest" then
            local target_player = args[2]
            local quest_id = args[3]
            
            if not target_player or not quest_id then
                return false, "Usage: /qb_admin reset_quest <player> <quest_id>"
            end
            
            questbook.storage.set_player_quest_progress(target_player, quest_id, nil)
            return true, "Reset quest " .. quest_id .. " for " .. target_player
            
        elseif cmd == "check_repeatable" then
            questbook.api.check_repeatable_quests()
            return true, "Checked and reset all eligible repeatable quests"
            
        else
            return false, "Usage: /qb_admin <reset_player|complete_quest|reset_quest|check_repeatable> [args]\n" ..
                        "Commands:\n" ..
                        "  reset_player <player> - Clear all quest data for player\n" ..
                        "  complete_quest <player> <quest_id> - Force complete a quest\n" ..
                        "  reset_quest <player> <quest_id> - Reset a quest to not started\n" ..
                        "  check_repeatable - Force check all repeatable quest cooldowns"
        end
    end
})

minetest.log("action", "[Questbook] Keybind system loaded")