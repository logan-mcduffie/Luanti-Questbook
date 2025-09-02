-- Viewport system for questbook tile-based GUI
-- Handles coordinate transformation, pan/zoom, and navigation

questbook.viewport = {}

-- Viewport constants
local VIEWPORT_WIDTH = 800      -- Available GUI width (pixels)  
local VIEWPORT_HEIGHT = 600     -- Available GUI height (pixels)
local MIN_ZOOM = 0.25           -- Minimum zoom level (25%)
local MAX_ZOOM = 4.0            -- Maximum zoom level (400%)
local DEFAULT_ZOOM = 1.0        -- Default zoom level (100%)
local PAN_SPEED = 50            -- Pixels per pan step

-- Player viewport states
local player_viewports = {}

-- Initialize viewport for player
function questbook.viewport.init_player(player_name)
    if not player_viewports[player_name] then
        player_viewports[player_name] = {}
    end
    
    -- Initialize chapter viewports as needed
    local player_vp = player_viewports[player_name]
    return player_vp
end

-- Get viewport for player and chapter
function questbook.viewport.get_viewport(player_name, chapter)
    local player_vp = questbook.viewport.init_player(player_name)
    chapter = chapter or "main"
    
    if not player_vp[chapter] then
        player_vp[chapter] = {
            offset = {x = 0, y = 0},    -- Pan offset (world coordinates)
            zoom = DEFAULT_ZOOM,         -- Zoom level
            bounds = {                   -- Screen bounds
                width = VIEWPORT_WIDTH,
                height = VIEWPORT_HEIGHT
            },
            world_bounds = {             -- Calculated world bounds visible
                min_x = 0, min_y = 0,
                max_x = VIEWPORT_WIDTH, max_y = VIEWPORT_HEIGHT
            }
        }
        
        -- Update calculated bounds
        questbook.viewport.update_world_bounds(player_name, chapter)
    end
    
    return player_vp[chapter]
end

-- Update calculated world bounds based on zoom and offset
function questbook.viewport.update_world_bounds(player_name, chapter)
    local viewport = questbook.viewport.get_viewport(player_name, chapter)
    
    -- Calculate world area visible in viewport
    local world_width = viewport.bounds.width / viewport.zoom
    local world_height = viewport.bounds.height / viewport.zoom
    
    viewport.world_bounds = {
        min_x = viewport.offset.x,
        min_y = viewport.offset.y,
        max_x = viewport.offset.x + world_width,
        max_y = viewport.offset.y + world_height
    }
end

-- Transform world coordinates to screen coordinates
function questbook.viewport.world_to_screen(player_name, chapter, world_x, world_y)
    local viewport = questbook.viewport.get_viewport(player_name, chapter)
    
    -- Apply offset and zoom transformation
    local screen_x = (world_x - viewport.offset.x) * viewport.zoom
    local screen_y = (world_y - viewport.offset.y) * viewport.zoom
    
    return screen_x, screen_y
end

-- Transform screen coordinates to world coordinates
function questbook.viewport.screen_to_world(player_name, chapter, screen_x, screen_y)
    local viewport = questbook.viewport.get_viewport(player_name, chapter)
    
    -- Reverse the transformation
    local world_x = (screen_x / viewport.zoom) + viewport.offset.x
    local world_y = (screen_y / viewport.zoom) + viewport.offset.y
    
    return world_x, world_y
end

-- Check if world coordinates are visible in current viewport
function questbook.viewport.is_visible(player_name, chapter, world_x, world_y, width, height)
    local viewport = questbook.viewport.get_viewport(player_name, chapter)
    width = width or 0
    height = height or 0
    
    -- Check if object bounds overlap with viewport bounds
    local obj_min_x = world_x
    local obj_min_y = world_y  
    local obj_max_x = world_x + width
    local obj_max_y = world_y + height
    
    local vp_bounds = viewport.world_bounds
    
    return not (obj_max_x < vp_bounds.min_x or obj_min_x > vp_bounds.max_x or
                obj_max_y < vp_bounds.min_y or obj_min_y > vp_bounds.max_y)
end

-- Get all visible quests for current viewport
function questbook.viewport.get_visible_quests(player_name, chapter, quests)
    local visible_quests = {}
    
    for quest_id, quest_data in pairs(quests or {}) do
        local quest = quest_data.quest
        if quest.layout and quest.layout.chapter == chapter then
            local pos = quest.layout.position
            local size_config = questbook.data.get_tile_size(quest.layout.size)
            
            if questbook.viewport.is_visible(player_name, chapter, pos.x, pos.y, 
                                           size_config.width, size_config.height) then
                visible_quests[quest_id] = quest_data
            end
        end
    end
    
    return visible_quests
end

-- Pan viewport by specified amount
function questbook.viewport.pan(player_name, chapter, dx, dy)
    local viewport = questbook.viewport.get_viewport(player_name, chapter)
    
    viewport.offset.x = viewport.offset.x + dx
    viewport.offset.y = viewport.offset.y + dy
    
    -- Apply reasonable bounds (prevent panning too far from content)
    local MAX_OFFSET = 10000
    viewport.offset.x = math.max(-MAX_OFFSET, math.min(MAX_OFFSET, viewport.offset.x))
    viewport.offset.y = math.max(-MAX_OFFSET, math.min(MAX_OFFSET, viewport.offset.y))
    
    questbook.viewport.update_world_bounds(player_name, chapter)
    return true
end

-- Pan viewport in cardinal directions
function questbook.viewport.pan_up(player_name, chapter)
    return questbook.viewport.pan(player_name, chapter, 0, -PAN_SPEED)
end

function questbook.viewport.pan_down(player_name, chapter)
    return questbook.viewport.pan(player_name, chapter, 0, PAN_SPEED)
end

function questbook.viewport.pan_left(player_name, chapter)
    return questbook.viewport.pan(player_name, chapter, -PAN_SPEED, 0)
end

function questbook.viewport.pan_right(player_name, chapter)
    return questbook.viewport.pan(player_name, chapter, PAN_SPEED, 0)
end

-- Set zoom level
function questbook.viewport.set_zoom(player_name, chapter, zoom_level)
    local viewport = questbook.viewport.get_viewport(player_name, chapter)
    
    -- Clamp zoom to valid range
    zoom_level = math.max(MIN_ZOOM, math.min(MAX_ZOOM, zoom_level))
    viewport.zoom = zoom_level
    
    questbook.viewport.update_world_bounds(player_name, chapter)
    return true
end

-- Zoom in/out by factor
function questbook.viewport.zoom_in(player_name, chapter, factor)
    local viewport = questbook.viewport.get_viewport(player_name, chapter)
    factor = factor or 1.25 -- 25% zoom in
    return questbook.viewport.set_zoom(player_name, chapter, viewport.zoom * factor)
end

function questbook.viewport.zoom_out(player_name, chapter, factor)
    local viewport = questbook.viewport.get_viewport(player_name, chapter)
    factor = factor or 1.25 -- 25% zoom out
    return questbook.viewport.set_zoom(player_name, chapter, viewport.zoom / factor)
end

-- Reset zoom to default
function questbook.viewport.reset_zoom(player_name, chapter)
    return questbook.viewport.set_zoom(player_name, chapter, DEFAULT_ZOOM)
end

-- Center viewport on specific world coordinates
function questbook.viewport.center_on(player_name, chapter, world_x, world_y)
    local viewport = questbook.viewport.get_viewport(player_name, chapter)
    
    -- Center the point in the viewport
    viewport.offset.x = world_x - (viewport.bounds.width / viewport.zoom) / 2
    viewport.offset.y = world_y - (viewport.bounds.height / viewport.zoom) / 2
    
    questbook.viewport.update_world_bounds(player_name, chapter)
    return true
end

-- Center viewport on specific quest
function questbook.viewport.center_on_quest(player_name, quest_id)
    local quest = questbook.get_quest(quest_id)
    if not quest or not quest.layout then
        return false
    end
    
    local pos = quest.layout.position
    local chapter = quest.layout.chapter
    return questbook.viewport.center_on(player_name, chapter, pos.x, pos.y)
end

-- Fit all quests in chapter within viewport (auto-zoom and center)
function questbook.viewport.fit_chapter(player_name, chapter, quests)
    local chapter_quests = {}
    local min_x, min_y, max_x, max_y = nil, nil, nil, nil
    
    -- Find bounds of all quests in chapter
    for quest_id, quest_data in pairs(quests or {}) do
        local quest = quest_data.quest
        if quest.layout and quest.layout.chapter == chapter then
            local pos = quest.layout.position
            local size_config = questbook.data.get_tile_size(quest.layout.size)
            
            local quest_min_x = pos.x
            local quest_min_y = pos.y
            local quest_max_x = pos.x + size_config.width
            local quest_max_y = pos.y + size_config.height
            
            min_x = min_x and math.min(min_x, quest_min_x) or quest_min_x
            min_y = min_y and math.min(min_y, quest_min_y) or quest_min_y
            max_x = max_x and math.max(max_x, quest_max_x) or quest_max_x
            max_y = max_y and math.max(max_y, quest_max_y) or quest_max_y
        end
    end
    
    if not min_x then
        -- No quests in chapter, center at origin
        questbook.viewport.center_on(player_name, chapter, 0, 0)
        questbook.viewport.reset_zoom(player_name, chapter)
        return true
    end
    
    -- Add padding
    local padding = 100
    min_x = min_x - padding
    min_y = min_y - padding  
    max_x = max_x + padding
    max_y = max_y + padding
    
    -- Calculate required zoom to fit content
    local content_width = max_x - min_x
    local content_height = max_y - min_y
    local viewport = questbook.viewport.get_viewport(player_name, chapter)
    
    -- Account for details panel taking up space (4.5 formspec units = 450 world units)
    local state = questbook.gui.get_player_state(player_name)
    local available_width = viewport.bounds.width
    if state.selected_quest then
        available_width = available_width - 450  -- Details panel width in world coordinates
    end
    
    local zoom_x = available_width / content_width
    local zoom_y = viewport.bounds.height / content_height
    local fit_zoom = math.min(zoom_x, zoom_y)
    
    -- Apply zoom and center
    questbook.viewport.set_zoom(player_name, chapter, fit_zoom)
    local center_x = (min_x + max_x) / 2
    local center_y = (min_y + max_y) / 2
    questbook.viewport.center_on(player_name, chapter, center_x, center_y)
    
    return true
end

-- Get viewport info for display (coordinates, zoom level, etc.)
function questbook.viewport.get_info(player_name, chapter)
    local viewport = questbook.viewport.get_viewport(player_name, chapter)
    
    return {
        offset = {x = viewport.offset.x, y = viewport.offset.y},
        zoom = viewport.zoom,
        zoom_percent = math.floor(viewport.zoom * 100),
        world_bounds = viewport.world_bounds,
        screen_bounds = viewport.bounds
    }
end

-- Handle viewport navigation from GUI inputs
function questbook.viewport.handle_navigation(player_name, chapter, action, param)
    if action == "pan_up" then
        return questbook.viewport.pan_up(player_name, chapter)
    elseif action == "pan_down" then
        return questbook.viewport.pan_down(player_name, chapter)
    elseif action == "pan_left" then
        return questbook.viewport.pan_left(player_name, chapter)
    elseif action == "pan_right" then
        return questbook.viewport.pan_right(player_name, chapter)
    elseif action == "zoom_in" then
        return questbook.viewport.zoom_in(player_name, chapter)
    elseif action == "zoom_out" then
        return questbook.viewport.zoom_out(player_name, chapter)
    elseif action == "reset_zoom" then
        return questbook.viewport.reset_zoom(player_name, chapter)
    elseif action == "center_quest" then
        return questbook.viewport.center_on_quest(player_name, param)
    elseif action == "fit_chapter" then
        local quests = questbook.get_player_quests(player_name)
        return questbook.viewport.fit_chapter(player_name, chapter, quests)
    end
    
    return false
end

-- Clean up viewport data when player leaves
function questbook.viewport.cleanup_player(player_name)
    player_viewports[player_name] = nil
end

-- Register cleanup on player leave
minetest.register_on_leaveplayer(function(player)
    local player_name = player:get_player_name()
    questbook.viewport.cleanup_player(player_name)
end)

minetest.log("action", "[Questbook] Viewport system loaded")