-- Canvas-based formspec renderer for questbook tile GUI
-- Combines viewport, tiles, and UI elements into complete interface

questbook.canvas = {}

-- Canvas constants - Full screen like FTB Quests
local CANVAS_WIDTH = 20          -- Full screen width
local CANVAS_HEIGHT = 12         -- Full screen height
local CHAPTER_SIDEBAR_WIDTH = 3  -- Left sidebar for chapters
local UI_PANEL_HEIGHT = 1        -- Bottom UI controls height
local QUEST_AREA_WIDTH = CANVAS_WIDTH - CHAPTER_SIDEBAR_WIDTH
local QUEST_AREA_HEIGHT = CANVAS_HEIGHT - UI_PANEL_HEIGHT

-- Render the main questbook interface
function questbook.canvas.render_main(player_name)
    local state = questbook.gui.get_player_state(player_name)
    local current_chapter = state.selected_chapter or "tutorial"
    
    -- Auto-start available quests when opening questbook
    questbook.auto_start_quests(player_name)
    
    -- Start building full-screen formspec
    local formspec = "size[" .. CANVAS_WIDTH .. "," .. CANVAS_HEIGHT .. "]" ..
                    "bgcolor[#0d0d0d;true]" ..  -- Darker background like FTB
                    "background[0,0;0,0;;true]" ..  -- Remove default background
                    "style_type[item_image_button;bgcolor=#fff;bgcolor_hovered=#fff;bgcolor_pressed=#fff;bgimg=blank.png;bgimg_hovered=blank.png;border=false]"  -- Remove gray background from item images
    
    -- Left sidebar for chapters
    local sidebar = questbook.canvas.render_chapter_sidebar(player_name, current_chapter)
    formspec = formspec .. sidebar
    
    -- Main quest canvas area (right side)
    local canvas_area = questbook.canvas.render_quest_canvas(player_name, current_chapter)
    formspec = formspec .. canvas_area
    
    -- Bottom navigation controls
    local nav_controls = questbook.canvas.render_navigation_controls(player_name, current_chapter)
    formspec = formspec .. nav_controls
    
    -- IMPORTANT: Quest details panel MUST be rendered last to ensure it appears on top
    -- This prevents quest tiles from overlapping the details panel when zoomed
    if state.selected_quest then
        local details_panel = questbook.canvas.render_details_panel(player_name, state.selected_quest)
        formspec = formspec .. details_panel
    end
    
    return formspec
end

-- Render party information header
function questbook.canvas.render_party_info(player_name)
    local party_id = questbook.party.get_player_party(player_name)
    if not party_id then
        return ""
    end
    
    local party = questbook.party.get_party_info(party_id)
    if not party then
        return ""
    end
    
    local online_count = 0
    for _, member in ipairs(party.members) do
        if minetest.get_player_by_name(member) then
            online_count = online_count + 1
        end
    end
    
    return "label[9.5,0.3;" .. 
           minetest.colorize("#FFD700", "Party: " .. #party.members .. " members (" .. online_count .. " online)") .. "]"
end

-- Render chapter sidebar (left side, vertical like FTB Quests)
function questbook.canvas.render_chapter_sidebar(player_name, current_chapter)
    local chapters = questbook.canvas.get_available_chapters(player_name)
    local formspec = ""
    
    -- Sidebar background
    formspec = formspec .. "box[0,0;" .. CHAPTER_SIDEBAR_WIDTH .. "," .. CANVAS_HEIGHT .. ";#1e1e1e]"
    
    -- Sidebar title (centered)
    formspec = formspec .. "label[1.1,0.2;" .. minetest.colorize("#FFFFFF", "Chapters") .. "]"
    
    -- Party info in sidebar if in party
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
            formspec = formspec .. "label[0.1,0.6;" .. 
                      minetest.colorize("#FFD700", "Party: " .. online_count .. "/" .. #party.members) .. "]"
        end
    end
    
    -- Chapter buttons (vertical list)
    local y_pos = 1.0
    for _, chapter_name in ipairs(chapters) do
        local is_selected = chapter_name == current_chapter
        local button_color = is_selected and "#4a4a4a" or "#333333"
        local text_color = is_selected and "#FFD700" or "#CCCCCC"
        local border_color = is_selected and "#FFD700" or "#555555"
        
        -- Chapter button background with border
        formspec = formspec .. "box[0.1," .. y_pos .. ";" .. (CHAPTER_SIDEBAR_WIDTH - 0.2) .. ",0.7;" .. border_color .. "]"
        formspec = formspec .. "box[0.15," .. (y_pos + 0.05) .. ";" .. (CHAPTER_SIDEBAR_WIDTH - 0.3) .. ",0.6;" .. button_color .. "]"
        
        -- Chapter name
        local display_name = chapter_name:gsub("^%l", string.upper)
        formspec = formspec .. "button[0.1," .. y_pos .. ";" .. (CHAPTER_SIDEBAR_WIDTH - 0.2) .. ",0.7;chapter_" .. chapter_name .. ";" .. 
                   minetest.colorize(text_color, display_name) .. "]"
        
        y_pos = y_pos + 0.8
    end
    
    return formspec
end

-- Render viewport navigation controls (bottom bar)
function questbook.canvas.render_navigation_controls(player_name, chapter)
    local viewport_info = questbook.viewport.get_info(player_name, chapter)
    local formspec = ""
    
    -- Navigation bar background
    local nav_y = CANVAS_HEIGHT - UI_PANEL_HEIGHT
    formspec = formspec .. "box[" .. CHAPTER_SIDEBAR_WIDTH .. "," .. nav_y .. ";" .. 
               QUEST_AREA_WIDTH .. "," .. UI_PANEL_HEIGHT .. ";#333333]"
    
    -- Pan controls (start after sidebar)
    local control_x = CHAPTER_SIDEBAR_WIDTH + 0.2
    formspec = formspec .. "button[" .. control_x .. "," .. (nav_y + 0.1) .. ";0.6,0.8;nav_pan_left;◀]"
    control_x = control_x + 0.7
    formspec = formspec .. "button[" .. control_x .. "," .. (nav_y + 0.1) .. ";0.6,0.8;nav_pan_right;▶]"
    control_x = control_x + 0.7
    formspec = formspec .. "button[" .. control_x .. "," .. (nav_y + 0.1) .. ";0.6,0.8;nav_pan_up;▲]"
    control_x = control_x + 0.7
    formspec = formspec .. "button[" .. control_x .. "," .. (nav_y + 0.1) .. ";0.6,0.8;nav_pan_down;▼]"
    
    -- Zoom controls
    control_x = control_x + 1
    formspec = formspec .. "button[" .. control_x .. "," .. (nav_y + 0.1) .. ";0.6,0.8;nav_zoom_in;+]"
    control_x = control_x + 0.7
    formspec = formspec .. "button[" .. control_x .. "," .. (nav_y + 0.1) .. ";0.6,0.8;nav_zoom_out;-]"
    control_x = control_x + 0.7
    formspec = formspec .. "button[" .. control_x .. "," .. (nav_y + 0.1) .. ";1.2,0.8;nav_fit_view;Fit All]"
    
    -- Info displays (right side)
    local info_x = CANVAS_WIDTH - 4
    formspec = formspec .. "label[" .. info_x .. "," .. (nav_y + 0.3) .. ";" .. 
               minetest.colorize("#AAAAAA", "Zoom: " .. viewport_info.zoom_percent .. "%") .. "]"
    
    info_x = info_x + 2
    local coords_text
    local state = questbook.gui.get_player_state(player_name)
    if state.selected_quest then
        -- Show selected quest coordinates
        local quest = questbook.get_quest(state.selected_quest)
        if quest and quest.layout then
            coords_text = "(" .. quest.layout.position.x .. ", " .. quest.layout.position.y .. ")"
        else
            coords_text = "(?, ?)"
        end
    else
        -- Show viewport coordinates when no quest selected
        coords_text = "(" .. math.floor(viewport_info.offset.x) .. ", " .. math.floor(viewport_info.offset.y) .. ")"
    end
    formspec = formspec .. "label[" .. info_x .. "," .. (nav_y + 0.3) .. ";" .. 
               minetest.colorize("#AAAAAA", coords_text) .. "]"
    
    return formspec
end

-- Render the main quest canvas area with tiles
function questbook.canvas.render_quest_canvas(player_name, chapter)
    local quests = questbook.get_player_quests(player_name)
    
    -- Define canvas area bounds (right side of screen, after sidebar)
    local canvas_x = CHAPTER_SIDEBAR_WIDTH
    local canvas_y = 0
    local canvas_width = QUEST_AREA_WIDTH  
    local canvas_height = QUEST_AREA_HEIGHT
    
    -- Canvas background (main quest area)
    local formspec = "box[" .. canvas_x .. "," .. canvas_y .. ";" .. 
                    canvas_width .. "," .. canvas_height .. ";#2d2d2d]"
    
    -- Chapter title in quest area
    local chapter_display = chapter:gsub("^%l", string.upper)
    formspec = formspec .. "label[" .. (canvas_x + 0.2) .. ",0.2;" .. 
               minetest.colorize("#FFFFFF", "Quest Book - " .. chapter_display) .. "]"
    
    -- Set viewport bounds for rendering (larger area now)
    questbook.viewport.get_viewport(player_name, chapter).bounds = {
        width = canvas_width * 100,  -- Convert to pixel coordinates
        height = (canvas_height - 0.5) * 100  -- Leave space for title
    }
    
    -- Render visible quest tiles (visual only, no clickable buttons)
    local tiles_formspec = questbook.canvas.render_visible_tiles(player_name, chapter, quests, canvas_x, canvas_y + 0.5, false)
    formspec = formspec .. tiles_formspec
    
    -- Render dependency connections
    local connections_formspec = questbook.canvas.render_dependency_lines(player_name, chapter, quests, canvas_x, canvas_y + 0.5)
    formspec = formspec .. connections_formspec
    
    -- Render clickable buttons for tiles (separate from visuals to control z-order)
    local buttons_formspec = questbook.canvas.render_visible_tiles(player_name, chapter, quests, canvas_x, canvas_y + 0.5, true)
    formspec = formspec .. buttons_formspec
    
    return formspec
end

-- Render visible quest tiles in the canvas
function questbook.canvas.render_visible_tiles(player_name, chapter, quests, canvas_x, canvas_y, render_buttons_only)
    local visible_quests = questbook.viewport.get_visible_quests(player_name, chapter, quests)
    local formspec = ""
    
    for quest_id, quest_data in pairs(visible_quests) do
        local quest = quest_data.quest
        if quest.layout and quest.layout.chapter == chapter then
            -- Transform world coordinates to canvas coordinates
            local screen_x, screen_y = questbook.viewport.world_to_screen(
                player_name, chapter, quest.layout.position.x, quest.layout.position.y)
            
            -- Convert to formspec coordinates and offset by canvas position
            local fs_x = canvas_x + (screen_x / 100)
            local fs_y = canvas_y + (screen_y / 100)
            
            -- Only render if within canvas bounds
            if fs_x >= canvas_x and fs_y >= canvas_y then
                -- Skip rendering tiles that would overlap with details panel
                local state = questbook.gui.get_player_state(player_name)
                local layout = quest_data.quest.layout
                local size_config = questbook.data.get_tile_size(layout.size)
                local tile_right = fs_x + (size_config.width / 100)
                local details_panel_left = CANVAS_WIDTH - 4.5
                
                if state.selected_quest and tile_right > details_panel_left then
                    -- Skip this tile as it would overlap with details panel
                else
                    local tile_formspec = questbook.canvas.render_single_tile(
                        player_name, quest_id, quest_data, fs_x, fs_y, render_buttons_only)
                    formspec = formspec .. tile_formspec
                end
            end
        end
    end
    
    return formspec
end

-- Render a single quest tile
function questbook.canvas.render_single_tile(player_name, quest_id, quest_data, fs_x, fs_y, render_buttons_only)
    local quest = quest_data.quest
    local progress = quest_data.progress
    local layout = quest.layout
    
    -- Get tile configuration
    local size_config = questbook.data.get_tile_size(layout.size)
    local status = progress and progress.status or questbook.data.STATUS.LOCKED
    
    local fs_width = size_config.width / 100
    local fs_height = size_config.height / 100
    
    -- Get tile colors
    local tile_colors = {
        [questbook.data.STATUS.LOCKED] = "#444444",
        [questbook.data.STATUS.AVAILABLE] = "#2E7D32", 
        [questbook.data.STATUS.ACTIVE] = "#FFA726",
        [questbook.data.STATUS.COMPLETED] = "#43A047",
        [questbook.data.STATUS.FAILED] = "#E53935"
    }
    
    local border_colors = {
        [questbook.data.STATUS.LOCKED] = "#666666",
        [questbook.data.STATUS.AVAILABLE] = "#4CAF50",
        [questbook.data.STATUS.ACTIVE] = "#FFB74D", 
        [questbook.data.STATUS.COMPLETED] = "#66BB6A",
        [questbook.data.STATUS.FAILED] = "#EF5350"
    }
    
    local tile_color = layout.color or tile_colors[status] or tile_colors[questbook.data.STATUS.LOCKED]
    local border_color = border_colors[status] or border_colors[questbook.data.STATUS.LOCKED]
    
    local formspec = ""
    
    if render_buttons_only then
        -- Render high z-index elements first (item_image, image, labels)
        if layout.icon then
            local icon_formspec = questbook.canvas.render_tile_icon(layout.icon, fs_x, fs_y, size_config, true)
            formspec = formspec .. icon_formspec
        end
        
        -- Render title (if space allows and properly positioned)
        if size_config.height >= 48 then
            local title_y = fs_y + (size_config.icon_size / 100) + 0.12
            local max_chars = math.floor(size_config.width / 6)  -- Better character estimation
            local title_text = questbook.canvas.truncate_text(quest.title, max_chars)
            
            -- Make sure title doesn't extend beyond tile
            if title_y + 0.2 < fs_y + fs_height then
                formspec = formspec .. "label[" .. (fs_x + 0.08) .. "," .. title_y .. ";" .. 
                           minetest.colorize("#FFFFFF", minetest.formspec_escape(title_text)) .. "]"
            end
        end
        
        -- Then render the clickable button overlay (invisible)
        formspec = formspec .. "button[" .. fs_x .. "," .. fs_y .. ";" .. fs_width .. "," .. fs_height .. 
                   ";tile_" .. quest_id .. ";]"
    else
        -- Render all visual elements (but not the button)
        
        -- Tile border (gray, not colored)
        local border_width = 0.03  -- Slightly thicker for better visibility
        formspec = formspec .. "box[" .. (fs_x - border_width) .. "," .. (fs_y - border_width) .. ";" .. 
                   (fs_width + 2 * border_width) .. "," .. (fs_height + 2 * border_width) .. ";#666666]"
        
        -- Main tile background (gray)
        formspec = formspec .. "box[" .. fs_x .. "," .. fs_y .. ";" .. fs_width .. "," .. fs_height .. ";#555555]"
        
        -- Status color strip at bottom
        local status_strip_height = 0.08
        local status_y = fs_y + fs_height - status_strip_height
        formspec = formspec .. "box[" .. fs_x .. "," .. status_y .. ";" .. fs_width .. "," .. status_strip_height .. ";" .. tile_color .. "]"
        
        -- Render icon
        if layout.icon then
            local icon_formspec = questbook.canvas.render_tile_icon(layout.icon, fs_x, fs_y, size_config, false)
            formspec = formspec .. icon_formspec
        end
        
        -- Note: Title labels moved to button phase due to z-index
        
        -- Render progress bar for active quests
        if status == questbook.data.STATUS.ACTIVE and progress then
            local progress_formspec = questbook.canvas.render_tile_progress(quest, progress, fs_x, fs_y, fs_width, fs_height)
            formspec = formspec .. progress_formspec
        end
    end
    
    return formspec
end

-- Render icon for a quest tile
function questbook.canvas.render_tile_icon(icon_config, tile_x, tile_y, size_config, render_buttons_only)
    local icon_size = size_config.icon_size / 100
    local icon_x = tile_x + ((size_config.width / 100) - icon_size) / 2
    local icon_y = tile_y + ((size_config.height / 100) - icon_size) / 2 -- Center vertically
    
    if icon_config.type == questbook.data.ICON_TYPES.ITEM then
        if render_buttons_only then
            -- Render high z-index elements (item_image and labels) in buttons phase
            local formspec = "item_image[" .. icon_x .. "," .. icon_y .. ";" .. 
                            icon_size .. "," .. icon_size .. ";" .. icon_config.source .. "]"
            
            -- Count overlay (better positioned and sized)
            if icon_config.count and icon_config.count > 1 then
                local count_x = icon_x + icon_size - 0.2
                local count_y = icon_y + icon_size - 0.2
                
                formspec = formspec .. "label[" .. count_x .. "," .. count_y .. ";" .. 
                           minetest.colorize("#FFFF00", tostring(icon_config.count)) .. "]"
            end
            
            return formspec
        else
            -- Render only the background for count in visual phase
            local formspec = ""
            if icon_config.count and icon_config.count > 1 then
                local count_x = icon_x + icon_size - 0.2
                local count_y = icon_y + icon_size - 0.2
                
                -- Add cleaner background for count
                formspec = formspec .. "box[" .. (count_x - 0.06) .. "," .. (count_y - 0.03) .. ";0.32,0.18;#222222]"
                formspec = formspec .. "box[" .. (count_x - 0.05) .. "," .. (count_y - 0.02) .. ";0.3,0.16;#333333]"
            end
            return formspec
        end
        
    elseif icon_config.type == questbook.data.ICON_TYPES.IMAGE then
        if render_buttons_only then
            return "image[" .. icon_x .. "," .. icon_y .. ";" .. 
                   icon_size .. "," .. icon_size .. ";" .. icon_config.source .. "]"
        else
            return ""
        end
    else
        if not render_buttons_only then
            -- Default icon - clean, simple design
            local formspec = "box[" .. icon_x .. "," .. icon_y .. ";" .. 
                            icon_size .. "," .. icon_size .. ";#555555]"
            -- Add a subtle inner box for depth
            local inner_margin = 0.04
            formspec = formspec .. "box[" .. (icon_x + inner_margin) .. "," .. (icon_y + inner_margin) .. ";" .. 
                      (icon_size - 2 * inner_margin) .. "," .. (icon_size - 2 * inner_margin) .. ";#777777]"
            return formspec
        else
            return ""
        end
    end
end

-- Render progress bar for active quest tile
function questbook.canvas.render_tile_progress(quest, progress, tile_x, tile_y, tile_width, tile_height)
    -- Calculate completion percentage
    local completed = 0
    local total = 0
    
    for _, objective in ipairs(quest.objectives) do
        if not objective.optional then
            total = total + 1
            local obj_progress = progress.objectives[objective.id] or 0
            if obj_progress >= objective.count then
                completed = completed + 1
            end
        end
    end
    
    if total == 0 then
        return ""
    end
    
    local completion_percent = completed / total
    
    -- Progress bar dimensions (above status strip)
    local bar_height = 0.04
    local status_strip_height = 0.08
    local bar_width = tile_width -- Full width of tile
    local bar_x = tile_x -- Start at tile edge
    local bar_y = tile_y + tile_height - status_strip_height - bar_height -- Above status strip
    
    local formspec = ""
    
    -- Progress bar background
    formspec = formspec .. "box[" .. bar_x .. "," .. bar_y .. ";" .. bar_width .. "," .. bar_height .. ";#333333]"
    
    -- Progress bar fill
    if completion_percent > 0 then
        local fill_width = bar_width * completion_percent
        formspec = formspec .. "box[" .. bar_x .. "," .. bar_y .. ";" .. fill_width .. "," .. bar_height .. ";#4CAF50]"
    end
    
    return formspec
end

-- Render dependency connection lines (placeholder for Phase 2.3)
function questbook.canvas.render_dependency_lines(player_name, chapter, quests, canvas_x, canvas_y)
    -- This will be implemented in Phase 2.3
    return ""
end

-- Render quest details panel (overlay on right side)
function questbook.canvas.render_details_panel(player_name, selected_quest_id)
    if not selected_quest_id then
        return ""
    end
    
    local quest = questbook.get_quest(selected_quest_id)
    local progress = questbook.get_progress(player_name, selected_quest_id)
    
    if not quest then
        return ""
    end
    
    -- Details panel on far right side, full height
    local panel_x = CANVAS_WIDTH - 4.5
    local panel_y = 0
    local panel_width = 4.5
    local panel_height = CANVAS_HEIGHT
    
    -- Semi-transparent backdrop to ensure panel is always visible (Luanti doesn't support alpha in hex colors)
    local formspec = "box[" .. panel_x .. "," .. panel_y .. ";" .. panel_width .. "," .. panel_height .. ";#222222]"
    
    -- Panel background with border (slightly inset)
    local inner_x = panel_x + 0.1
    local inner_y = panel_y + 0.1
    local inner_width = panel_width - 0.2
    local inner_height = panel_height - 0.2
    
    formspec = formspec .. "box[" .. inner_x .. "," .. inner_y .. ";" .. inner_width .. "," .. inner_height .. ";#FFD700]"  -- Gold border
    formspec = formspec .. "box[" .. (inner_x + 0.05) .. "," .. (inner_y + 0.05) .. ";" .. (inner_width - 0.1) .. "," .. (inner_height - 0.1) .. ";#333333]"
    
    -- Quest title
    formspec = formspec .. "label[" .. (inner_x + 0.15) .. "," .. (inner_y + 0.15) .. ";" .. 
               minetest.colorize("#FFD700", quest.title) .. "]"
    
    -- Status
    local status = progress and progress.status or questbook.data.STATUS.LOCKED
    local status_color = "#AAAAAA"
    if status == questbook.data.STATUS.ACTIVE then status_color = "#FFA726"
    elseif status == questbook.data.STATUS.COMPLETED then status_color = "#43A047"
    elseif status == questbook.data.STATUS.AVAILABLE then status_color = "#4CAF50"
    end
    
    formspec = formspec .. "label[" .. (inner_x + 0.15) .. "," .. (inner_y + 0.5) .. ";" .. 
               minetest.colorize(status_color, status:upper()) .. "]"
    
    -- Description (wrapped)
    local desc_y = inner_y + 0.9
    local max_chars = 32
    local words = {}
    for word in quest.description:gmatch("%S+") do
        table.insert(words, word)
    end
    
    local current_line = ""
    local line_count = 0
    for _, word in ipairs(words) do
        if #current_line + #word + 1 <= max_chars then
            current_line = current_line == "" and word or current_line .. " " .. word
        else
            if current_line ~= "" then
                formspec = formspec .. "label[" .. (inner_x + 0.15) .. "," .. (desc_y + line_count * 0.3) .. ";" .. 
                           minetest.colorize("#CCCCCC", minetest.formspec_escape(current_line)) .. "]"
                line_count = line_count + 1
            end
            current_line = word
        end
    end
    if current_line ~= "" then
        formspec = formspec .. "label[" .. (inner_x + 0.15) .. "," .. (desc_y + line_count * 0.3) .. ";" .. 
                   minetest.colorize("#CCCCCC", minetest.formspec_escape(current_line)) .. "]"
    end
    
    -- Remove the problematic invisible button
    
    -- Close button (top right)
    formspec = formspec .. "button[" .. (inner_x + inner_width - 0.7) .. "," .. (inner_y + 0.05) .. ";0.6,0.6;close_details;X]"
    
    return formspec
end

-- Get available chapters for player
function questbook.canvas.get_available_chapters(player_name)
    local chapters = {}
    local all_quests = questbook.get_all_quests()
    
    for _, quest in pairs(all_quests) do
        if quest.layout then
            local chapter = quest.layout.chapter
            local found = false
            for _, existing in ipairs(chapters) do
                if existing == chapter then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(chapters, chapter)
            end
        end
    end
    
    -- Default to tutorial if no chapters found
    if #chapters == 0 then
        table.insert(chapters, "tutorial")
    end
    
    table.sort(chapters)
    return chapters
end

-- Utility function to truncate text
function questbook.canvas.truncate_text(text, max_chars)
    if #text <= max_chars then
        return text
    end
    return text:sub(1, max_chars - 3) .. "..."
end

minetest.log("action", "[Questbook] Canvas renderer loaded")