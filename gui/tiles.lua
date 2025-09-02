-- Tile rendering system for questbook GUI
-- Handles quest tile generation, icons, and visual states

questbook.tiles = {}

-- Tile rendering constants
local TILE_BORDER_WIDTH = 2
local ICON_PADDING = 4
local TEXT_HEIGHT = 12
local PROGRESS_BAR_HEIGHT = 4

-- Tile state colors
local TILE_COLORS = {
    [questbook.data.STATUS.LOCKED] = "#444444",
    [questbook.data.STATUS.AVAILABLE] = "#2E7D32", 
    [questbook.data.STATUS.ACTIVE] = "#FFA726",
    [questbook.data.STATUS.COMPLETED] = "#43A047",
    [questbook.data.STATUS.FAILED] = "#E53935"
}

local BORDER_COLORS = {
    [questbook.data.STATUS.LOCKED] = "#666666",
    [questbook.data.STATUS.AVAILABLE] = "#4CAF50",
    [questbook.data.STATUS.ACTIVE] = "#FFB74D", 
    [questbook.data.STATUS.COMPLETED] = "#66BB6A",
    [questbook.data.STATUS.FAILED] = "#EF5350"
}

-- Generate formspec for a quest tile
function questbook.tiles.render_tile(player_name, chapter, quest_id, quest_data)
    local quest = quest_data.quest
    local progress = quest_data.progress
    
    if not quest.layout then
        return "" -- No layout data, skip rendering
    end
    
    -- Get tile configuration
    local layout = quest.layout
    local size_config = questbook.data.get_tile_size(layout.size)
    local status = progress and progress.status or questbook.data.STATUS.LOCKED
    
    -- Transform world coordinates to screen coordinates
    local screen_x, screen_y = questbook.viewport.world_to_screen(
        player_name, chapter, layout.position.x, layout.position.y)
    
    -- Convert to formspec coordinates (formspec uses different scale)
    local fs_x = screen_x / 100  -- Scale to formspec coordinates
    local fs_y = screen_y / 100
    local fs_width = size_config.width / 100
    local fs_height = size_config.height / 100
    
    -- Get tile colors
    local tile_color = layout.color or TILE_COLORS[status] or TILE_COLORS[questbook.data.STATUS.LOCKED]
    local border_color = BORDER_COLORS[status] or BORDER_COLORS[questbook.data.STATUS.LOCKED]
    
    local formspec = ""
    
    -- Tile background
    formspec = formspec .. "box[" .. fs_x .. "," .. fs_y .. ";" .. fs_width .. "," .. fs_height .. ";" .. tile_color .. "]"
    
    -- Tile border
    local border_width = TILE_BORDER_WIDTH / 100
    formspec = formspec .. "box[" .. (fs_x - border_width) .. "," .. (fs_y - border_width) .. ";" .. 
               (fs_width + 2 * border_width) .. "," .. (fs_height + 2 * border_width) .. ";" .. border_color .. "]"
    
    -- Render icon
    local icon_formspec = questbook.tiles.render_icon(layout.icon, fs_x, fs_y, size_config)
    formspec = formspec .. icon_formspec
    
    -- Render title (if space allows)
    if size_config.height >= 48 then -- Only show title on medium+ tiles
        local title_y = fs_y + (size_config.icon_size / 100) + 0.1
        local title_text = questbook.tiles.truncate_text(quest.title, size_config.width / 8)
        formspec = formspec .. "label[" .. (fs_x + 0.1) .. "," .. title_y .. ";" .. 
                   minetest.colorize("#FFFFFF", minetest.formspec_escape(title_text)) .. "]"
    end
    
    -- Render progress bar (if active)
    if status == questbook.data.STATUS.ACTIVE and progress then
        local progress_formspec = questbook.tiles.render_progress_bar(
            quest, progress, fs_x, fs_y, fs_width, fs_height)
        formspec = formspec .. progress_formspec
    end
    
    -- Clickable button overlay (invisible)
    formspec = formspec .. "button[" .. fs_x .. "," .. fs_y .. ";" .. fs_width .. "," .. fs_height .. 
               ";tile_" .. quest_id .. ";]"
    
    return formspec
end

-- Render quest icon based on icon configuration
function questbook.tiles.render_icon(icon_config, tile_x, tile_y, size_config)
    if not icon_config or icon_config.type == questbook.data.ICON_TYPES.DEFAULT then
        return questbook.tiles.render_default_icon(tile_x, tile_y, size_config)
    elseif icon_config.type == questbook.data.ICON_TYPES.ITEM then
        return questbook.tiles.render_item_icon(icon_config, tile_x, tile_y, size_config)
    elseif icon_config.type == questbook.data.ICON_TYPES.IMAGE then
        return questbook.tiles.render_image_icon(icon_config, tile_x, tile_y, size_config)
    else
        return questbook.tiles.render_default_icon(tile_x, tile_y, size_config)
    end
end

-- Render item icon with count overlay
function questbook.tiles.render_item_icon(icon_config, tile_x, tile_y, size_config)
    local icon_size = size_config.icon_size / 100
    local icon_x = tile_x + (size_config.width / 100 - icon_size) / 2
    local icon_y = tile_y + ICON_PADDING / 100
    
    local formspec = ""
    
    -- Item image
    formspec = formspec .. "item_image[" .. icon_x .. "," .. icon_y .. ";" .. 
               icon_size .. "," .. icon_size .. ";" .. icon_config.source .. "]"
    
    -- Count overlay (if count > 1)
    if icon_config.count and icon_config.count > 1 then
        local count_x = icon_x + icon_size - 0.3
        local count_y = icon_y + icon_size - 0.2
        formspec = formspec .. "label[" .. count_x .. "," .. count_y .. ";" .. 
                   minetest.colorize("#FFFF00", tostring(icon_config.count)) .. "]"
    end
    
    return formspec
end

-- Render custom image icon  
function questbook.tiles.render_image_icon(icon_config, tile_x, tile_y, size_config)
    local icon_size = size_config.icon_size / 100
    local icon_x = tile_x + (size_config.width / 100 - icon_size) / 2  
    local icon_y = tile_y + ICON_PADDING / 100
    
    -- Custom image
    local formspec = "image[" .. icon_x .. "," .. icon_y .. ";" .. 
                    icon_size .. "," .. icon_size .. ";" .. icon_config.source .. "]"
    
    return formspec
end

-- Render default/fallback icon
function questbook.tiles.render_default_icon(tile_x, tile_y, size_config)
    local icon_size = size_config.icon_size / 100
    local icon_x = tile_x + (size_config.width / 100 - icon_size) / 2
    local icon_y = tile_y + ICON_PADDING / 100
    
    -- Simple colored box as default icon
    local formspec = "box[" .. icon_x .. "," .. icon_y .. ";" .. 
                    icon_size .. "," .. icon_size .. ";#888888]"
    
    return formspec
end

-- Render progress bar for active quests
function questbook.tiles.render_progress_bar(quest, progress, tile_x, tile_y, tile_width, tile_height)
    if not progress or not progress.objectives then
        return ""
    end
    
    -- Calculate overall completion percentage
    local completed_objectives = 0
    local total_objectives = 0
    
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
        return ""
    end
    
    local completion_percent = completed_objectives / total_objectives
    
    -- Progress bar dimensions
    local bar_height = PROGRESS_BAR_HEIGHT / 100
    local bar_width = tile_width - 0.2 -- Leave padding
    local bar_x = tile_x + 0.1
    local bar_y = tile_y + tile_height - bar_height - 0.1
    
    local formspec = ""
    
    -- Progress bar background
    formspec = formspec .. "box[" .. bar_x .. "," .. bar_y .. ";" .. bar_width .. "," .. bar_height .. ";#333333]"
    
    -- Progress bar fill
    local fill_width = bar_width * completion_percent
    if fill_width > 0 then
        formspec = formspec .. "box[" .. bar_x .. "," .. bar_y .. ";" .. fill_width .. "," .. bar_height .. ";#4CAF50]"
    end
    
    return formspec
end

-- Truncate text to fit within specified width (approximate)
function questbook.tiles.truncate_text(text, max_chars)
    if #text <= max_chars then
        return text
    end
    
    return text:sub(1, max_chars - 3) .. "..."
end

-- Generate formspec for all visible tiles in chapter
function questbook.tiles.render_chapter(player_name, chapter, quests)
    local visible_quests = questbook.viewport.get_visible_quests(player_name, chapter, quests)
    local formspec = ""
    
    -- Render each visible quest tile
    for quest_id, quest_data in pairs(visible_quests) do
        local tile_formspec = questbook.tiles.render_tile(player_name, chapter, quest_id, quest_data)
        formspec = formspec .. tile_formspec
    end
    
    return formspec
end

-- Get tile size configuration for a quest
function questbook.tiles.get_quest_tile_size(quest)
    if not quest or not quest.layout then
        return questbook.data.TILE_SIZES.MEDIUM
    end
    
    return questbook.data.get_tile_size(quest.layout.size)
end

-- Check if screen coordinates are within a quest tile
function questbook.tiles.is_point_in_tile(player_name, chapter, quest, screen_x, screen_y)
    if not quest.layout then
        return false
    end
    
    local tile_screen_x, tile_screen_y = questbook.viewport.world_to_screen(
        player_name, chapter, quest.layout.position.x, quest.layout.position.y)
    
    local size_config = questbook.data.get_tile_size(quest.layout.size)
    
    return screen_x >= tile_screen_x and screen_x <= tile_screen_x + size_config.width and
           screen_y >= tile_screen_y and screen_y <= tile_screen_y + size_config.height
end

-- Get tile bounds in screen coordinates
function questbook.tiles.get_tile_screen_bounds(player_name, chapter, quest)
    if not quest.layout then
        return nil
    end
    
    local screen_x, screen_y = questbook.viewport.world_to_screen(
        player_name, chapter, quest.layout.position.x, quest.layout.position.y)
    
    local size_config = questbook.data.get_tile_size(quest.layout.size)
    
    return {
        x = screen_x,
        y = screen_y, 
        width = size_config.width,
        height = size_config.height
    }
end

-- Validate icon configuration
function questbook.tiles.validate_icon(icon_config)
    return questbook.data.validate_icon(icon_config)
end

-- Create tile preview for admin tools (not implemented yet)
function questbook.tiles.create_tile_preview(quest, status)
    -- This would generate a preview image for quest positioning tools
    -- Implementation depends on how admin interface is built
    return "placeholder_preview.png"
end

minetest.log("action", "[Questbook] Tile rendering system loaded")