-- GUI event handlers for questbook
-- Handles formspec callbacks and player interactions

questbook.handlers = {}

-- Handle formspec events
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "questbook:main" then
        return false
    end
    
    local player_name = player:get_player_name()
    questbook.gui.init_player(player_name)
    
    -- Handle category selection (legacy)
    for field_name, _ in pairs(fields) do
        if field_name:match("^cat_") then
            local category = field_name:gsub("^cat_", "")
            questbook.handlers.handle_category_select(player_name, category)
            questbook.handlers.show_questbook(player_name)
            return true
        end
    end
    
    -- Handle chapter selection (new tile system)
    for field_name, _ in pairs(fields) do
        if field_name:match("^chapter_") then
            local chapter = field_name:gsub("^chapter_", "")
            questbook.handlers.handle_chapter_select(player_name, chapter)
            questbook.handlers.show_questbook(player_name)
            return true
        end
    end
    
    -- Handle navigation controls
    for field_name, _ in pairs(fields) do
        if field_name:match("^nav_") then
            local action = field_name:gsub("^nav_", "")
            questbook.handlers.handle_navigation(player_name, action)
            questbook.handlers.show_questbook(player_name)
            return true
        end
    end
    
    -- Handle tile clicks
    for field_name, _ in pairs(fields) do
        if field_name:match("^tile_") then
            local quest_id = field_name:gsub("^tile_", "")
            questbook.handlers.handle_tile_click(player_name, quest_id)
            questbook.handlers.show_questbook(player_name)
            return true
        end
    end
    
    -- Handle close details panel
    if fields.close_details then
        questbook.handlers.handle_close_details(player_name)
        questbook.handlers.show_questbook(player_name)
        return true
    end
    
    -- Handle quest selection
    for field_name, _ in pairs(fields) do
        if field_name:match("^quest_") then
            local quest_id = field_name:gsub("^quest_", "")
            questbook.handlers.handle_quest_select(player_name, quest_id)
            questbook.handlers.show_questbook(player_name)
            return true
        end
    end
    
    
    -- Handle quest abandon
    for field_name, _ in pairs(fields) do
        if field_name:match("^abandon_quest_") then
            local quest_id = field_name:gsub("^abandon_quest_", "")
            questbook.handlers.handle_quest_abandon(player_name, quest_id)
            questbook.handlers.show_questbook(player_name)
            return true
        end
    end
    
    -- Handle consume quest submission
    for field_name, _ in pairs(fields) do
        if field_name:match("^submit_consume_") then
            local quest_id = field_name:gsub("^submit_consume_", "")
            questbook.handlers.handle_consume_quest_submit(player_name, quest_id)
            questbook.handlers.show_questbook(player_name)
            return true
        end
    end
    
    -- Handle checkbox quest completion
    for field_name, _ in pairs(fields) do
        if field_name:match("^complete_checkbox_") then
            local quest_id = field_name:gsub("^complete_checkbox_", "")
            questbook.handlers.handle_checkbox_quest_complete(player_name, quest_id)
            questbook.handlers.show_questbook(player_name)
            return true
        end
    end
    
    -- Handle scroll up
    if fields.scroll_up then
        questbook.handlers.handle_scroll(player_name, -1)
        questbook.handlers.show_questbook(player_name)
        return true
    end
    
    -- Handle scroll down
    if fields.scroll_down then
        questbook.handlers.handle_scroll(player_name, 1)
        questbook.handlers.show_questbook(player_name)
        return true
    end
    
    -- Handle close
    if fields.quit then
        return true
    end
    
    return false
end)

-- Show questbook to player
function questbook.handlers.show_questbook(player_name)
    local formspec = questbook.gui.get_main_formspec(player_name)
    minetest.show_formspec(player_name, "questbook:main", formspec)
end

-- Handle category selection
function questbook.handlers.handle_category_select(player_name, category)
    questbook.gui.init_player(player_name)
    
    -- Access the player_gui_state from the formspec module
    -- We need to make this accessible
    if not questbook.gui.player_gui_state then
        questbook.gui.player_gui_state = {}
    end
    
    if not questbook.gui.player_gui_state[player_name] then
        questbook.gui.init_player(player_name)
    end
    
    questbook.gui.player_gui_state[player_name].selected_category = category
    questbook.gui.player_gui_state[player_name].selected_quest = nil
    questbook.gui.player_gui_state[player_name].scroll_pos = 0
end

-- Handle scroll
function questbook.handlers.handle_scroll(player_name, direction)
    questbook.gui.init_player(player_name)
    local state = questbook.gui.player_gui_state[player_name]
    
    -- Get quest count for current category
    local quests = questbook.gui.get_filtered_quests(player_name, state.selected_category)
    local quest_array = {}
    for _, _ in pairs(quests) do
        table.insert(quest_array, true)
    end
    
    local total_quests = #quest_array
    local visible_quests = 9
    local current_scroll = state.scroll_pos or 0
    
    -- Calculate new scroll position
    local new_scroll = current_scroll + direction
    new_scroll = math.max(0, math.min(new_scroll, total_quests - visible_quests))
    
    state.scroll_pos = new_scroll
end

-- Handle quest selection  
function questbook.handlers.handle_quest_select(player_name, quest_id)
    questbook.gui.init_player(player_name)
    questbook.gui.player_gui_state[player_name].selected_quest = quest_id
end

-- Handle chapter selection (new tile system)
function questbook.handlers.handle_chapter_select(player_name, chapter)
    questbook.gui.init_player(player_name)
    local state = questbook.gui.player_gui_state[player_name]
    
    state.selected_chapter = chapter
    state.selected_quest = nil  -- Clear selected quest when changing chapters
    
    -- Reset viewport when switching chapters
    questbook.viewport.get_viewport(player_name, chapter)
end

-- Handle navigation actions
function questbook.handlers.handle_navigation(player_name, action)
    local state = questbook.gui.get_player_state(player_name)
    local chapter = state.selected_chapter or "tutorial"
    
    if action == "pan_left" then
        questbook.viewport.pan_left(player_name, chapter)
    elseif action == "pan_right" then
        questbook.viewport.pan_right(player_name, chapter)
    elseif action == "pan_up" then
        questbook.viewport.pan_up(player_name, chapter)
    elseif action == "pan_down" then
        questbook.viewport.pan_down(player_name, chapter)
    elseif action == "zoom_in" then
        questbook.viewport.zoom_in(player_name, chapter)
    elseif action == "zoom_out" then
        questbook.viewport.zoom_out(player_name, chapter)
    elseif action == "fit_view" then
        local quests = questbook.get_player_quests(player_name)
        questbook.viewport.fit_chapter(player_name, chapter, quests)
    end
end

-- Handle tile clicks
function questbook.handlers.handle_tile_click(player_name, quest_id)
    questbook.gui.init_player(player_name)
    local state = questbook.gui.player_gui_state[player_name]
    
    -- Select the quest
    state.selected_quest = quest_id
    
    -- Get quest and progress for action handling
    local quest = questbook.get_quest(quest_id)
    local progress = questbook.get_progress(player_name, quest_id)
    
    if not quest then
        return
    end
    
    -- Handle quest actions based on type and status
    local status = progress and progress.status or questbook.data.STATUS.LOCKED
    local quest_type = quest.quest_type or questbook.data.QUEST_TYPES.STANDARD
    
    if status == questbook.data.STATUS.ACTIVE then
        if quest_type == questbook.data.QUEST_TYPES.CONSUME then
            -- Check if can submit consume quest
            local has_items = questbook.check_consume_quest_items(player_name, quest_id)
            if has_items then
                questbook.handlers.handle_consume_quest_submit(player_name, quest_id)
            end
        elseif quest_type == questbook.data.QUEST_TYPES.CHECKBOX then
            -- Complete checkbox quest
            questbook.handlers.handle_checkbox_quest_complete(player_name, quest_id)
        end
        -- Standard quests just get selected for details view
    end
end


-- Handle quest abandon
function questbook.handlers.handle_quest_abandon(player_name, quest_id)
    local progress = questbook.get_progress(player_name, quest_id)
    if progress and progress.status == questbook.data.STATUS.ACTIVE then
        -- Set quest status to available (can be restarted)
        progress.status = questbook.data.STATUS.AVAILABLE
        progress.start_time = nil
        progress.objectives = {}
        
        questbook.storage.set_player_quest_progress(player_name, quest_id, progress)
        
        -- Fire abandon event (treated as quest fail)
        questbook.events.fire_quest_fail(player_name, quest_id, "abandoned")
        
        minetest.chat_send_player(player_name, 
            minetest.colorize("#FFFF00", "[Questbook] ") .. "Quest abandoned: " .. 
            (questbook.get_quest(quest_id).title or quest_id))
    end
end

-- Handle consume quest submission
function questbook.handlers.handle_consume_quest_submit(player_name, quest_id)
    local success, message, missing_items = questbook.submit_consume_quest(player_name, quest_id)
    
    if success then
        minetest.chat_send_player(player_name, 
            minetest.colorize("#00FF00", "[Questbook] ") .. "Items submitted and quest completed!")
    else
        if missing_items then
            minetest.chat_send_player(player_name, 
                minetest.colorize("#FF0000", "[Questbook] ") .. "Missing required items:")
            for _, missing in ipairs(missing_items) do
                minetest.chat_send_player(player_name, 
                    minetest.colorize("#FF8888", "  • ") .. 
                    missing.target .. ": " .. missing.has .. "/" .. missing.needed)
            end
        else
            minetest.chat_send_player(player_name, 
                minetest.colorize("#FF0000", "[Questbook] ") .. "Failed to submit items: " .. message)
        end
    end
end

-- Handle checkbox quest completion
function questbook.handlers.handle_checkbox_quest_complete(player_name, quest_id)
    local success, message = questbook.complete_checkbox_quest(player_name, quest_id)
    
    if success then
        minetest.chat_send_player(player_name, 
            minetest.colorize("#00FF00", "[Questbook] ") .. "Quest completed!")
    else
        minetest.chat_send_player(player_name, 
            minetest.colorize("#FF0000", "[Questbook] ") .. "Failed to complete quest: " .. message)
    end
end

-- Handle close details panel
function questbook.handlers.handle_close_details(player_name)
    questbook.gui.init_player(player_name)
    local state = questbook.gui.player_gui_state[player_name]
    state.selected_quest = nil
end

minetest.log("action", "[Questbook] GUI handlers loaded")