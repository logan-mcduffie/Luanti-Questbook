-- Simple quest tile rendering system
-- 250x250 pixel tiles with item icons and color coding

questbook.tiles = {}

-- Tile constants
local TILE_SIZE = 1.25  -- 125 pixels = 1.25 formspec units
local ITEM_SIZE = 0.75  -- Size of item icon

-- Status colors
local STATUS_COLORS = {
    [questbook.data.STATUS.LOCKED] = "#666666",      -- Gray for locked
    [questbook.data.STATUS.AVAILABLE] = "#FFA500",   -- Orange/Yellow for available
    [questbook.data.STATUS.ACTIVE] = "#FFA500",      -- Orange/Yellow for active 
    [questbook.data.STATUS.COMPLETED] = "#4CAF50",   -- Green for completed
    [questbook.data.STATUS.FAILED] = "#E53935"       -- Red for failed
}

-- Render quest tiles in the canvas area
function questbook.tiles.render_tiles(player_name, chapter, canvas_x, canvas_y, canvas_width, canvas_height)
    local quests = questbook.get_player_quests(player_name)
    local formspec = {}
    
    for quest_id, quest_data in pairs(quests) do
        local quest = quest_data.quest
        local progress = quest_data.progress
        
        -- Only render quests in the current chapter
        if quest.category == chapter then
            -- Check if quest should be visible
            local status = progress and progress.status or questbook.data.STATUS.LOCKED
            if questbook.tiles.should_show_quest(quest, status) then
                -- Transform world coordinates to screen coordinates using viewport
                local screen_x, screen_y = questbook.viewport.world_to_screen(
                    player_name, chapter, quest.tile_x, quest.tile_y)
                
                -- Convert to formspec coordinates and offset by canvas position
                local tile_x = canvas_x + (screen_x / 100)
                local tile_y = canvas_y + (screen_y / 100)
                
                -- Check if tile is within canvas bounds
                if tile_x >= canvas_x - TILE_SIZE and tile_y >= canvas_y - TILE_SIZE and 
                   tile_x <= canvas_x + canvas_width and tile_y <= canvas_y + canvas_height then
                    
                    local tile_formspec = questbook.tiles.render_single_tile(quest_id, quest, status, tile_x, tile_y)
                    table.insert(formspec, tile_formspec)
                end
            end
        end
    end
    
    return table.concat(formspec)
end

-- Render a single quest tile
function questbook.tiles.render_single_tile(quest_id, quest, status, x, y)
    local formspec = {}
    
    -- Get tile color based on status
    local tile_color = STATUS_COLORS[status] or STATUS_COLORS[questbook.data.STATUS.LOCKED]
    
    -- Base starting point for this quest tile (e.g., quest at 100, 250)
    local base_x = x
    local base_y = y
    
    -- Element sizes - exact pixel sizing
    local button_size = 0.85  -- Gray button size - adjust this value to get perfect square
    local bg_width = 0.7     -- Colored background width (x-axis)
    local bg_height = 0.74    -- Colored background height (y-axis)
    
    -- ADJUST THESE OFFSETS TO POSITION EACH ELEMENT:
    
    -- Gray button position (offset from base)
    local button_offset_x = 0.1    -- Adjust this to move button horizontally
    local button_offset_y = 0.05    -- Adjust this to move button vertically
    local button_x = base_x + button_offset_x
    local button_y = base_y + button_offset_y
    
    -- Colored background position (offset from base) 
    local bg_offset_x = 0.07        -- Adjust this to move colored box horizontally
    local bg_offset_y = 0.04        -- Adjust this to move colored box vertically
    local bg_x = base_x + bg_offset_x
    local bg_y = base_y + bg_offset_y
    
    -- Item icon position (offset from base)
    local item_offset_x = 0.12   -- Adjust this to move item horizontally 
    local item_offset_y = 0.09   -- Adjust this to move item vertically
    local item_x = base_x + item_offset_x
    local item_y = base_y + item_offset_y
    
    -- RENDER ELEMENTS:
    
    -- Square clickable button (gray button)
    table.insert(formspec, "button[" .. button_x .. "," .. button_y .. ";" .. button_size .. "," .. button_size .. 
                ";tile_" .. quest_id .. ";]")
    
    -- Colored background box
    table.insert(formspec, "box[" .. bg_x .. "," .. bg_y .. ";" .. bg_width .. "," .. bg_height .. ";" .. tile_color .. "]")
    
    -- Render item icon
    if quest.tile_item and quest.tile_item ~= "" then
        table.insert(formspec, "item_image[" .. item_x .. "," .. item_y .. ";" .. 
                    ITEM_SIZE .. "," .. ITEM_SIZE .. ";" .. quest.tile_item .. "]")
    else
        -- Default icon if no item specified
        local icon_size = 0.5
        table.insert(formspec, "box[" .. item_x .. "," .. item_y .. ";" .. icon_size .. "," .. icon_size .. ";#777777]")
    end
    
    -- Brighter colored border around the background (attached to bg_x, bg_y)
    local border_width = 0.03
    local border_color = tile_color .. "CC"  -- Add some brightness/alpha effect
    
    -- Four border pieces to create a brighter frame (positioned relative to colored background)
    table.insert(formspec, "box[" .. bg_x .. "," .. bg_y .. ";" .. bg_width .. "," .. border_width .. ";" .. border_color .. "]")        -- Top
    table.insert(formspec, "box[" .. bg_x .. "," .. (bg_y + bg_height - border_width) .. ";" .. bg_width .. "," .. border_width .. ";" .. border_color .. "]")  -- Bottom
    table.insert(formspec, "box[" .. bg_x .. "," .. bg_y .. ";" .. border_width .. "," .. bg_height .. ";" .. border_color .. "]")        -- Left
    table.insert(formspec, "box[" .. (bg_x + bg_width - border_width) .. "," .. bg_y .. ";" .. border_width .. "," .. bg_height .. ";" .. border_color .. "]")  -- Right
    
    -- Tooltip with quest title and mandatory/optional status
    local tooltip_text = quest.title
    if quest.objectives then
        local has_optional = false
        for _, obj in ipairs(quest.objectives) do
            if obj.optional then
                has_optional = true
                break
            end
        end
        tooltip_text = tooltip_text .. "\n" .. (has_optional and "[Has Optional]" or "[Mandatory]")
    end
    table.insert(formspec, "tooltip[tile_" .. quest_id .. ";" .. minetest.formspec_escape(tooltip_text) .. "]")
    
    return table.concat(formspec)
end

-- Check if a quest should be shown based on visibility settings
function questbook.tiles.should_show_quest(quest, status)
    -- If quest is hidden, don't show it
    if quest.hidden then
        return false
    end
    
    -- Check hide_when_locked setting
    if quest.hide_when_locked and status == questbook.data.STATUS.LOCKED then
        return false
    end
    
    -- Always show non-locked quests
    if status ~= questbook.data.STATUS.LOCKED then
        return true
    end
    
    -- For locked quests, check global visibility setting (assume visible for now)
    return true
end

-- API functions for setting tile properties
function questbook.tiles.set_tile_item(quest, item_name)
    quest.tile_item = item_name or ""
    return quest
end

function questbook.tiles.set_tile_position(quest, x, y)
    quest.tile_x = x or 0
    quest.tile_y = y or 0
    return quest
end

minetest.log("action", "[Questbook] Simple tile system loaded")