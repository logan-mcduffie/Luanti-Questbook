-- Canvas-based formspec renderer for questbook GUI
-- Provides basic interface without quest tiles

questbook.canvas = {}

-- Canvas constants - Configurable interface sizing
local CANVAS_WIDTH = 16          -- Full screen width
local CANVAS_HEIGHT = 12         -- Full screen height
local CANVAS_BG_COLOR = "#00000000"  -- Canvas background color (transparent)
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
    
    -- Start building configurable formspec
    local formspec = {
        "size[" .. CANVAS_WIDTH .. "," .. CANVAS_HEIGHT .. "]",
        "bgcolor[" .. CANVAS_BG_COLOR .. ";false]"
    }
    
    -- Left sidebar for chapters
    local sidebar = questbook.canvas.render_chapter_sidebar(player_name, current_chapter)
    table.insert(formspec, sidebar)
    
    -- Main quest canvas area (right side)
    local canvas_area = questbook.canvas.render_quest_canvas(player_name, current_chapter)
    table.insert(formspec, canvas_area)
    
    -- Bottom navigation controls
    local nav_controls = questbook.canvas.render_navigation_controls(player_name, current_chapter)
    table.insert(formspec, nav_controls)
    
    -- Quest details panel if quest selected
    if state.selected_quest then
        local details_panel = questbook.canvas.render_details_panel(player_name, state.selected_quest)
        table.insert(formspec, details_panel)
    end
    
    return table.concat(formspec)
end

-- Render chapter sidebar (left side, vertical)
function questbook.canvas.render_chapter_sidebar(player_name, current_chapter)
    local chapters = questbook.canvas.get_available_chapters(player_name)
    local formspec = {}
    
    -- Sidebar background
    table.insert(formspec, "box[0,0;" .. CHAPTER_SIDEBAR_WIDTH .. "," .. CANVAS_HEIGHT .. ";#1e1e1e]")
    
    -- Sidebar title (centered in sidebar)
    table.insert(formspec, "label[" .. (CHAPTER_SIDEBAR_WIDTH / 2 - 0.4) .. ",0.2;" .. minetest.colorize("#FFFFFF", "Chapters") .. "]")
    
    -- Chapter buttons (vertical list) - now with flexible positioning
    local base_y = 1.0
    local chapter_index = 0
    
    for _, chapter_name in ipairs(chapters) do
        local chapter_formspec = questbook.canvas.render_single_chapter_tab(chapter_name, current_chapter, 0, base_y + (chapter_index * 0.8))
        table.insert(formspec, chapter_formspec)
        chapter_index = chapter_index + 1
    end
    
    return table.concat(formspec)
end

-- Render a single chapter tab with flexible positioning (similar to quest tiles)
function questbook.canvas.render_single_chapter_tab(chapter_name, current_chapter, x, y)
    local formspec = {}
    
    -- Base starting point for this chapter tab
    local base_x = x
    local base_y = y
    
    -- Chapter state
    local is_selected = chapter_name == current_chapter
    local button_color = is_selected and "#4a4a4a" or "#333333"
    local text_color = is_selected and "#FFD700" or "#CCCCCC"
    local border_color = is_selected and "#FFD700" or "#555555"
    
    -- Element sizes
    local tab_width = CHAPTER_SIDEBAR_WIDTH
    local tab_height = 0.7
    local inner_margin = 0.05
    
    -- Border background size (adjust these to change border dimensions)
    local border_width = tab_width - 0.22      -- Border background width
    local border_height = tab_height    -- Border background height
    
    -- ADJUST THESE OFFSETS TO POSITION EACH ELEMENT:
    
    -- Border background position (offset from base)
    local border_offset_x = 0.1    -- Adjust this to move border horizontally
    local border_offset_y = 0      -- Adjust this to move border vertically
    local border_x = base_x + border_offset_x
    local border_y = base_y + border_offset_y
    
    
    -- Button/text position (offset from base)
    local button_offset_x = 0.1    -- Adjust this to move clickable button horizontally
    local button_offset_y = 0      -- Adjust this to move clickable button vertically
    local button_x = base_x + button_offset_x
    local button_y = base_y + button_offset_y
    
    -- RENDER ELEMENTS:
    
    -- Border background
    table.insert(formspec, "box[" .. border_x .. "," .. border_y .. ";" .. border_width .. "," .. border_height .. ";" .. border_color .. "]")
    
    -- Clickable button with chapter name
    local display_name = chapter_name:gsub("^%l", string.upper)
    table.insert(formspec, "button[" .. button_x .. "," .. button_y .. ";" .. tab_width .. "," .. tab_height .. ";chapter_" .. chapter_name .. ";" .. 
                minetest.colorize(text_color, display_name) .. "]")
    
    return table.concat(formspec)
end

-- Render navigation controls with zoom and fit buttons
function questbook.canvas.render_navigation_controls(player_name, chapter)
    local formspec = {}
    
    -- Navigation bar background
    local nav_y = CANVAS_HEIGHT - UI_PANEL_HEIGHT
    table.insert(formspec, "box[" .. CHAPTER_SIDEBAR_WIDTH .. "," .. nav_y .. ";" .. 
                QUEST_AREA_WIDTH .. "," .. UI_PANEL_HEIGHT .. ";#333333]")
    
    -- Control buttons
    local control_x = CHAPTER_SIDEBAR_WIDTH + 0.2
    
    -- Pan controls (compact layout)
    table.insert(formspec, "button[" .. control_x .. "," .. (nav_y + 0.1) .. ";0.6,0.8;nav_pan_left;◀]")
    control_x = control_x + 0.7
    table.insert(formspec, "button[" .. control_x .. "," .. (nav_y + 0.1) .. ";0.6,0.8;nav_pan_right;▶]")
    control_x = control_x + 0.7
    table.insert(formspec, "button[" .. control_x .. "," .. (nav_y + 0.1) .. ";0.6,0.8;nav_pan_up;▲]")
    control_x = control_x + 0.7
    table.insert(formspec, "button[" .. control_x .. "," .. (nav_y + 0.1) .. ";0.6,0.8;nav_pan_down;▼]")
    
    -- Zoom controls
    control_x = control_x + 1
    table.insert(formspec, "button[" .. control_x .. "," .. (nav_y + 0.1) .. ";0.6,0.8;nav_zoom_in;+]")
    control_x = control_x + 0.7
    table.insert(formspec, "button[" .. control_x .. "," .. (nav_y + 0.1) .. ";0.6,0.8;nav_zoom_out;-]")
    control_x = control_x + 0.7
    table.insert(formspec, "button[" .. control_x .. "," .. (nav_y + 0.1) .. ";1.2,0.8;nav_fit_view;Fit All]")
    
    -- Edit mode toggle button (far right)
    local edit_x = CHAPTER_SIDEBAR_WIDTH + QUEST_AREA_WIDTH - 0.8
    table.insert(formspec, "image_button[" .. edit_x .. "," .. (nav_y + 0.1) .. ";0.8,0.8;questbook_edit_icon.png;toggle_edit_mode;]")
    table.insert(formspec, "tooltip[toggle_edit_mode;Toggle edit mode]")
    
    return table.concat(formspec)
end

-- Render the main quest canvas area with tiles
function questbook.canvas.render_quest_canvas(player_name, chapter)
    -- Define canvas area bounds
    local canvas_x = CHAPTER_SIDEBAR_WIDTH
    local canvas_y = 0.5  -- Leave space for chapter title
    local canvas_width = QUEST_AREA_WIDTH  
    local canvas_height = QUEST_AREA_HEIGHT - 0.5
    
    -- Canvas background
    local formspec = {
        "box[" .. CHAPTER_SIDEBAR_WIDTH .. ",0;" .. 
                    QUEST_AREA_WIDTH .. "," .. QUEST_AREA_HEIGHT .. ";#2d2d2d]"
    }
    
    -- Chapter title
    local chapter_display = chapter:gsub("^%l", string.upper)
    table.insert(formspec, "label[" .. (CHAPTER_SIDEBAR_WIDTH + 0.2) .. ",0.2;" .. 
                minetest.colorize("#FFFFFF", "Quest Book - " .. chapter_display) .. "]")
    
    -- Add scroll area for potential mouse wheel detection (experimental)
    table.insert(formspec, "scrollbaroptions[max=1000;smallstep=50;largestep=200]")
    table.insert(formspec, "scroll_container[" .. canvas_x .. "," .. canvas_y .. ";" .. canvas_width .. "," .. canvas_height .. ";canvas_scroll;vertical;0.5]")
    
    -- Create a large invisible area that might capture scroll events
    table.insert(formspec, "box[0,0;" .. (canvas_width * 2) .. "," .. (canvas_height * 2) .. ";#00000000]")
    
    -- Add invisible clickable areas for simple pan control (click to center)
    local pan_size = 1.0
    table.insert(formspec, "button[" .. (canvas_width - pan_size) .. ",0;" .. pan_size .. "," .. pan_size .. ";pan_click_right;]")  -- Top right
    table.insert(formspec, "button[0,0;" .. pan_size .. "," .. pan_size .. ";pan_click_left;]")  -- Top left
    table.insert(formspec, "button[" .. (canvas_width/2 - pan_size/2) .. ",0;" .. pan_size .. "," .. pan_size .. ";pan_click_up;]")  -- Top center
    table.insert(formspec, "button[" .. (canvas_width/2 - pan_size/2) .. "," .. (canvas_height - pan_size) .. ";" .. pan_size .. "," .. pan_size .. ";pan_click_down;]")  -- Bottom center
    
    -- Render quest tiles
    local tiles_formspec = questbook.tiles.render_tiles(player_name, chapter, canvas_x, canvas_y, canvas_width, canvas_height)
    table.insert(formspec, tiles_formspec)
    
    -- Close scroll container
    table.insert(formspec, "scroll_container_end[]")
    
    return table.concat(formspec)
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
    
    -- Details panel on far right side - aligned with quest canvas area
    local panel_x = CANVAS_WIDTH - 4.5
    local panel_y = 0
    local panel_width = 4.5
    local panel_height = QUEST_AREA_HEIGHT  -- Stop at navigation bar, don't overlap
    
    -- Panel background (dark gray)
    local formspec = {
        "box[" .. panel_x .. "," .. panel_y .. ";" .. panel_width .. "," .. panel_height .. ";#333333]"
    }
    
    -- Status
    local status = progress and progress.status or questbook.data.STATUS.LOCKED
    local status_color = "#AAAAAA"
    if status == questbook.data.STATUS.ACTIVE then status_color = "#FFA726"
    elseif status == questbook.data.STATUS.COMPLETED then status_color = "#43A047"
    elseif status == questbook.data.STATUS.AVAILABLE then status_color = "#4CAF50"
    end
    
    -- Small colored status rectangle at top (for title and status)
    local status_rect_height = 0.8
    table.insert(formspec, "box[" .. panel_x .. "," .. panel_y .. ";" .. panel_width .. "," .. status_rect_height .. ";" .. status_color .. "]")
    
    -- Content area positioning
    local content_x = panel_x + 0.15
    local title_y = panel_y + 0.05
    local status_text_y = panel_y + 0.35
    
    -- Quest title (white text on colored background)
    table.insert(formspec, "label[" .. content_x .. "," .. title_y .. ";" .. 
                minetest.colorize("#FFFFFF", quest.title) .. "]")
    
    -- Status text (white text on colored background)
    table.insert(formspec, "label[" .. content_x .. "," .. status_text_y .. ";" .. 
                minetest.colorize("#FFFFFF", status:upper()) .. "]")
    
    -- Description (wrapped)
    local desc_y = panel_y + 1.0
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
                table.insert(formspec, "label[" .. content_x .. "," .. (desc_y + line_count * 0.3) .. ";" .. 
                            minetest.colorize("#CCCCCC", minetest.formspec_escape(current_line)) .. "]")
                line_count = line_count + 1
            end
            current_line = word
        end
    end
    if current_line ~= "" then
        table.insert(formspec, "label[" .. content_x .. "," .. (desc_y + line_count * 0.3) .. ";" .. 
                    minetest.colorize("#CCCCCC", minetest.formspec_escape(current_line)) .. "]")
    end
    
    -- Close button
    table.insert(formspec, "button[" .. (panel_x + panel_width - 0.7) .. "," .. (panel_y + 0.05) .. ";0.6,0.6;close_details;X]")
    
    return table.concat(formspec)
end

-- Get available chapters for player
function questbook.canvas.get_available_chapters(player_name)
    local chapters = {}
    local all_quests = questbook.get_all_quests()
    
    for _, quest in pairs(all_quests) do
        if quest.category then
            local chapter = quest.category
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

minetest.log("action", "[Questbook] Canvas renderer loaded (tiles removed)")