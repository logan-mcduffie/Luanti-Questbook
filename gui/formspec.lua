-- GUI formspec system for questbook
-- Handles quest browser, quest details, and UI interactions

questbook.gui = {}

-- GUI constants
local GUI_SIZE = "size[14,10]"
local QUEST_LIST_SIZE = "4,7"
local QUEST_DETAIL_SIZE = "7.5,7"

-- Player GUI state (make it accessible to other modules)
questbook.gui.player_gui_state = {}

-- Initialize GUI state for player
function questbook.gui.init_player(player_name)
    if not questbook.gui.player_gui_state[player_name] then
        questbook.gui.player_gui_state[player_name] = {
            current_view = "tile_canvas",  -- New default view
            selected_quest = nil,
            selected_chapter = "tutorial", -- Changed from category to chapter
            selected_category = "all",     -- Keep for legacy compatibility
            scroll_pos = 0,
            edit_mode = false,            -- Edit mode state
            controls_notified = false     -- SSCSM controls notification flag
        }
    end
end

-- Get player GUI state
function questbook.gui.get_player_state(player_name)
    questbook.gui.init_player(player_name)
    return questbook.gui.player_gui_state[player_name]
end

-- Check if player has edit permissions
function questbook.gui.can_edit(player_name)
    local player = minetest.get_player_by_name(player_name)
    if not player then return false end
    
    -- Check for questbook_admin privilege
    return minetest.check_player_privs(player_name, {questbook_admin = true})
end

-- Toggle edit mode for player
function questbook.gui.toggle_edit_mode(player_name)
    if not questbook.gui.can_edit(player_name) then
        minetest.chat_send_player(player_name, "You don't have permission to use edit mode.")
        return false
    end
    
    local state = questbook.gui.get_player_state(player_name)
    state.edit_mode = not state.edit_mode
    
    local mode_text = state.edit_mode and "enabled" or "disabled"
    minetest.chat_send_player(player_name, "Edit mode " .. mode_text .. ".")
    
    return true
end

-- Get formspec for main questbook interface
function questbook.gui.get_main_formspec(player_name)
    questbook.gui.init_player(player_name)
    local state = questbook.gui.player_gui_state[player_name]
    
    -- Use new tile-based canvas renderer
    if state.current_view == "tile_canvas" then
        return questbook.canvas.render_main(player_name)
    end
    
    -- Fallback to legacy list-based interface for compatibility
    return questbook.gui.get_legacy_formspec(player_name)
end

-- Legacy list-based formspec (renamed from get_main_formspec)
function questbook.gui.get_legacy_formspec(player_name)
    questbook.gui.init_player(player_name)
    local state = questbook.gui.player_gui_state[player_name]
    
    -- Auto-start available quests when opening questbook
    questbook.auto_start_quests(player_name)
    
    local formspec = {
        GUI_SIZE,
        "bgcolor[#1a1a1a;true]",
        "box[0,0;14,10;#2a2a2a]",
        "label[0.5,0.5;" .. minetest.colorize("#ffffff", "Quest Book (Legacy)") .. "]"
    }
    
    -- Show party info if player is in a party
    local party_id = questbook.party.get_player_party(player_name)
    if party_id then
        local party = questbook.party.get_party_info(party_id)
        if party then
            local online_count = 0
            for _, member in ipairs(party.members) do
                if minetest.get_player_by_name(member) then
                    online_count = online_count + 1
                end
            end
            table.insert(formspec, "label[9,0.5;" .. 
                        minetest.colorize("#FFD700", "Party: " .. #party.members .. " members (" .. online_count .. " online)") .. "]")
        end
    end
    
    -- Category filter buttons
    table.insert(formspec, questbook.gui.get_category_buttons(player_name))
    
    -- Quest list
    table.insert(formspec, questbook.gui.get_quest_list(player_name))
    
    -- Quest details panel
    if state.selected_quest then
        table.insert(formspec, questbook.gui.get_quest_details(player_name, state.selected_quest))
    else
        table.insert(formspec, questbook.gui.get_no_selection_panel())
    end
    
    return table.concat(formspec)
end

-- Generate category filter buttons
function questbook.gui.get_category_buttons(player_name)
    local state = questbook.gui.player_gui_state[player_name]
    local categories = questbook.gui.get_quest_categories(player_name)
    
    local formspec = {}
    local x_pos = 0.5
    local y_pos = 1.2
    
    -- All category button
    local all_style = state.selected_category == "all" and "button" or "button"
    table.insert(formspec, all_style .. "[" .. x_pos .. "," .. y_pos .. ";1,0.6;cat_all;All]")
    x_pos = x_pos + 1.1
    
    -- Individual category buttons
    for _, category in ipairs(categories) do
        if x_pos > 12 then -- Wrap to next row
            x_pos = 0.5
            y_pos = y_pos + 0.7
        end
        
        local btn_style = state.selected_category == category and "button" or "button"
        local cap_category = category:sub(1,1):upper() .. category:sub(2)
        table.insert(formspec, btn_style .. "[" .. x_pos .. "," .. y_pos .. ";1.5,0.6;cat_" .. category .. ";" .. cap_category .. "]")
        x_pos = x_pos + 1.6
    end
    
    return table.concat(formspec)
end

-- Generate quest list
function questbook.gui.get_quest_list(player_name)
    local state = questbook.gui.player_gui_state[player_name]
    local quests = questbook.gui.get_filtered_quests(player_name, state.selected_category)
    
    -- Convert quests table to sorted array for consistent ordering
    local quest_array = {}
    for quest_id, quest_data in pairs(quests) do
        table.insert(quest_array, {id = quest_id, data = quest_data})
    end
    
    -- Sort by quest title for consistent ordering
    table.sort(quest_array, function(a, b)
        return a.data.quest.title < b.data.quest.title
    end)
    
    local formspec = {
        "box[0.5,2.5;" .. QUEST_LIST_SIZE .. ";#333333]",
        "label[0.7,2.7;" .. minetest.colorize("#ffff00", "Available Quests") .. "]"
    }
    
    local total_quests = #quest_array
    local visible_quests = 9 -- Number of quests that can fit in the display area
    local scroll_offset = state.scroll_pos or 0
    
    -- Scroll buttons if needed
    if total_quests > visible_quests then
        -- Scroll up button
        if scroll_offset > 0 then
            table.insert(formspec, "button[4.2,3.0;0.4,0.4;scroll_up;↑]")
        else
            table.insert(formspec, "button[4.2,3.0;0.4,0.4;scroll_up_disabled;" .. minetest.colorize("#666666", "↑") .. "]")
        end
        
        -- Scroll down button
        if scroll_offset < (total_quests - visible_quests) then
            table.insert(formspec, "button[4.2,8.8;0.4,0.4;scroll_down;↓]")
        else
            table.insert(formspec, "button[4.2,8.8;0.4,0.4;scroll_down_disabled;" .. minetest.colorize("#666666", "↓") .. "]")
        end
        
        -- Scroll indicator
        local scroll_percent = math.floor((scroll_offset / (total_quests - visible_quests)) * 100)
        table.insert(formspec, "label[4.3,9.4;" .. minetest.colorize("#AAAAAA", scroll_percent .. "%") .. "]")
    end
    
    local y_pos = 3.2
    local quest_count = 0
    
    -- Display quests with scroll offset
    for i = scroll_offset + 1, math.min(scroll_offset + visible_quests, total_quests) do
        local quest_entry = quest_array[i]
        local quest_id = quest_entry.id
        local quest_data = quest_entry.data
        local quest = quest_data.quest
        local progress = quest_data.progress
        
        -- Quest status color
        local color = questbook.gui.get_status_color(progress and progress.status or "locked")
        
        -- Quest button with better styling (fit within panel)
        local btn_color = state.selected_quest == quest_id and "#4a4a4a" or "#2a2a2a"
        table.insert(formspec, "box[0.7," .. y_pos .. ";3.6,0.6;" .. btn_color .. "]")
        table.insert(formspec, "button[0.7," .. y_pos .. ";3.6,0.6;quest_" .. quest_id .. ";" .. 
                    minetest.colorize(color, quest.title) .. "]")
        
        -- Progress indicator (positioned within panel)
        if progress and progress.status == questbook.data.STATUS.ACTIVE then
            local completion = questbook.gui.calculate_quest_completion(quest, progress)
            table.insert(formspec, "label[3.8," .. (y_pos + 0.15) .. ";" .. 
                        minetest.colorize("#FFFF00", completion .. "%") .. "]")
        end
        
        y_pos = y_pos + 0.7
        quest_count = quest_count + 1
    end
    
    if total_quests == 0 then
        table.insert(formspec, "label[0.7,4;No quests available in this category]")
    end
    
    return table.concat(formspec)
end

-- Generate quest details panel
function questbook.gui.get_quest_details(player_name, quest_id)
    local quest = questbook.get_quest(quest_id)
    local progress = questbook.get_progress(player_name, quest_id)
    
    if not quest then
        return questbook.gui.get_no_selection_panel()
    end
    
    -- If no progress, check if quest should be available
    if not progress then
        local prereqs_met = questbook.settings.quest_prereqs_met(player_name, quest)
        if prereqs_met then
            -- Create available status for display
            progress = {status = questbook.data.STATUS.AVAILABLE, objectives = {}}
        else
            -- Quest is locked
            progress = {status = questbook.data.STATUS.LOCKED, objectives = {}}
        end
    end
    
    -- Check what details should be shown based on visibility settings
    local show_details = questbook.settings.should_show_quest_details(player_name, quest)
    local status = progress.status
    
    local formspec = {
        "box[5.5,2.5;" .. QUEST_DETAIL_SIZE .. ";#333333]",
        "label[5.7,2.7;" .. minetest.colorize("#ffff00", quest.title) .. "]",
        "label[5.7,3.2;" .. minetest.colorize("#aaaaaa", "Category: " .. (quest.category or "main")) .. "]"
    }
    
    -- Show party quest indicator
    if quest.party_shared then
        formspec = formspec .. "label[11,2.7;" .. minetest.colorize("#FFD700", "[Party Quest]") .. "]"
    end
    
    -- Description
    local desc_lines = questbook.gui.wrap_text(quest.description, 40)
    local y_pos = 3.8
    for _, line in ipairs(desc_lines) do
        formspec = formspec .. "label[5.7," .. y_pos .. ";" .. minetest.colorize("#ffffff", minetest.formspec_escape(line)) .. "]"
        y_pos = y_pos + 0.3
    end
    
    y_pos = y_pos + 0.3
    
    -- Prerequisites (if quest is locked and should show prerequisite info)
    if status == questbook.data.STATUS.LOCKED and show_details.prerequisites and quest.prerequisites and #quest.prerequisites > 0 then
        formspec = formspec .. "label[5.7," .. y_pos .. ";" .. minetest.colorize("#FF8888", "Prerequisites:") .. "]"
        y_pos = y_pos + 0.4
        
        for _, prereq_id in ipairs(quest.prerequisites) do
            local prereq_quest = questbook.get_quest(prereq_id)
            local prereq_progress = questbook.get_progress(player_name, prereq_id)
            local prereq_completed = prereq_progress and prereq_progress.status == questbook.data.STATUS.COMPLETED
            local check = prereq_completed and "☑" or "☐"
            local color = prereq_completed and "#00FF00" or "#FF8888"
            local prereq_title = prereq_quest and prereq_quest.title or prereq_id
            
            formspec = formspec .. "label[5.9," .. y_pos .. ";" .. check .. " " .. 
                      minetest.colorize(color, prereq_title) .. "]"
            y_pos = y_pos + 0.3
        end
        
        y_pos = y_pos + 0.3
    end
    
    -- Objectives (show if available/active/completed OR if settings allow showing locked objectives)
    if status ~= questbook.data.STATUS.LOCKED or show_details.objectives then
        formspec = formspec .. "label[5.7," .. y_pos .. ";" .. minetest.colorize("#00FF00", "Objectives:") .. "]"
        y_pos = y_pos + 0.4
        
        for _, objective in ipairs(quest.objectives) do
            local obj_progress = progress and progress.objectives[objective.id] or 0
            local completed = obj_progress >= objective.count
            local color = completed and "#00FF00" or "#FFFFFF"
            local check = completed and "☑" or "☐"
            
            if status == questbook.data.STATUS.LOCKED then
                -- For locked quests, don't show progress
                check = "☐"
                color = "#AAAAAA"
            end
            
            formspec = formspec .. "label[5.9," .. y_pos .. ";" .. check .. " " .. 
                      minetest.colorize(color, objective.description) .. "]"
            
            if objective.count > 1 and status ~= questbook.data.STATUS.LOCKED then
                formspec = formspec .. "label[12," .. y_pos .. ";" .. 
                          minetest.colorize("#FFFF00", obj_progress .. "/" .. objective.count) .. "]"
            end
            
            y_pos = y_pos + 0.3
        end
        
        y_pos = y_pos + 0.3
    end
    
    -- Rewards (show if available/active/completed OR if settings allow showing locked rewards)
    if quest.rewards and #quest.rewards > 0 and (status ~= questbook.data.STATUS.LOCKED or show_details.rewards) then
        formspec = formspec .. "label[5.7," .. y_pos .. ";" .. minetest.colorize("#FFD700", "Rewards:") .. "]"
        y_pos = y_pos + 0.4
        
        for _, reward in ipairs(quest.rewards) do
            if reward.type == "item" then
                local color = status == questbook.data.STATUS.LOCKED and "#AAAAAA" or "#FFFFFF"
                formspec = formspec .. "label[5.9," .. y_pos .. ";" .. 
                          minetest.colorize(color, "• " .. reward.count .. "x " .. reward.item) .. "]"
                y_pos = y_pos + 0.3
            end
        end
    end
    
    -- Action buttons
    y_pos = 9.5
    local status = progress.status
    local quest_type = quest.quest_type or questbook.data.QUEST_TYPES.STANDARD
    
    if status == questbook.data.STATUS.AVAILABLE then
        -- No start button - quests auto-start when prerequisites are met
        formspec = formspec .. "label[5.7," .. y_pos .. ";" .. minetest.colorize("#FFFF00", "Quest will start automatically") .. "]"
    elseif status == questbook.data.STATUS.ACTIVE then
        if quest_type == questbook.data.QUEST_TYPES.CONSUME then
            -- Check if player has required items
            local has_items = questbook.check_consume_quest_items(player_name, quest_id)
            if has_items then
                formspec = formspec .. "button[5.7," .. y_pos .. ";2,0.8;submit_consume_" .. quest_id .. ";Submit Items]"
            else
                formspec = formspec .. "label[5.7," .. y_pos .. ";" .. minetest.colorize("#FF8888", "Missing Items") .. "]"
            end
        elseif quest_type == questbook.data.QUEST_TYPES.CHECKBOX then
            formspec = formspec .. "button[5.7," .. y_pos .. ";2,0.8;complete_checkbox_" .. quest_id .. ";Mark Complete]"
        else
            -- Standard quest - show progress
            formspec = formspec .. "label[5.7," .. y_pos .. ";" .. minetest.colorize("#FFFF00", "Quest Active") .. "]"
        end
        formspec = formspec .. "button[8," .. y_pos .. ";2,0.8;abandon_quest_" .. quest_id .. ";Abandon]"
    elseif status == questbook.data.STATUS.COMPLETED then
        formspec = formspec .. "label[5.7," .. y_pos .. ";" .. minetest.colorize("#00FF00", "Quest Completed!") .. "]"
    end
    
    return formspec
end

-- Generate no selection panel
function questbook.gui.get_no_selection_panel()
    return "box[5.5,2.5;" .. QUEST_DETAIL_SIZE .. ";#333333]" ..
           "label[8.5,5.5;" .. minetest.colorize("#aaaaaa", "Select a quest to view details") .. "]"
end

-- Helper functions
function questbook.gui.get_quest_categories(player_name)
    local categories = {}
    local all_quests = questbook.get_all_quests()
    
    for _, quest in pairs(all_quests) do
        local category = quest.category or "main"
        local found = false
        for _, existing_cat in ipairs(categories) do
            if existing_cat == category then
                found = true
                break
            end
        end
        if not found then
            table.insert(categories, category)
        end
    end
    
    table.sort(categories)
    return categories
end

function questbook.gui.get_filtered_quests(player_name, category_filter)
    local all_quests = questbook.get_all_quests()
    local player_quests = questbook.get_player_quests(player_name)
    local filtered = {}
    
    for quest_id, quest in pairs(all_quests) do
        local quest_category = quest.category or "main"
        
        if category_filter == "all" or quest_category == category_filter then
            local progress = player_quests[quest_id] and player_quests[quest_id].progress
            
            -- Check if quest should be visible based on visibility settings
            local visible = questbook.settings.is_quest_visible(player_name, quest)
            
            if visible then
                if not progress then
                    -- Check if prerequisites are met
                    local prereqs_met = questbook.settings.quest_prereqs_met(player_name, quest)
                    if prereqs_met then
                        -- Create available status for display
                        progress = {status = questbook.data.STATUS.AVAILABLE, objectives = {}}
                    else
                        -- Quest is locked but visible
                        progress = {status = questbook.data.STATUS.LOCKED, objectives = {}}
                    end
                end
                
                filtered[quest_id] = {quest = quest, progress = progress}
            end
        end
    end
    
    return filtered
end

function questbook.gui.get_status_color(status)
    if status == questbook.data.STATUS.COMPLETED then
        return "#00FF00"
    elseif status == questbook.data.STATUS.ACTIVE then
        return "#FFFF00"
    elseif status == questbook.data.STATUS.AVAILABLE then
        return "#FFFFFF"
    elseif status == questbook.data.STATUS.FAILED then
        return "#FF0000"
    else
        return "#888888"
    end
end

function questbook.gui.calculate_quest_completion(quest, progress)
    if not progress or not progress.objectives then
        return 0
    end
    
    local total_objectives = 0
    local completed_objectives = 0
    
    for _, objective in ipairs(quest.objectives) do
        if not objective.optional then
            total_objectives = total_objectives + 1
            local obj_progress = progress.objectives[objective.id] or 0
            if obj_progress >= objective.count then
                completed_objectives = completed_objectives + 1
            end
        end
    end
    
    if total_objectives == 0 then
        return 100
    end
    
    return math.floor((completed_objectives / total_objectives) * 100)
end

function questbook.gui.wrap_text(text, max_length)
    local lines = {}
    local current_line = ""
    
    for word in text:gmatch("%S+") do
        if current_line == "" then
            current_line = word
        elseif #current_line + #word + 1 <= max_length then
            current_line = current_line .. " " .. word
        else
            table.insert(lines, current_line)
            current_line = word
        end
    end
    
    if current_line ~= "" then
        table.insert(lines, current_line)
    end
    
    return lines
end

-- Clean up GUI state when player leaves
minetest.register_on_leaveplayer(function(player)
    local player_name = player:get_player_name()
    questbook.gui.player_gui_state[player_name] = nil
end)

minetest.log("action", "[Questbook] GUI formspec system loaded")