-- Player control-based input system for questbook
-- Uses get_player_control() to detect mouse clicks and keyboard input

questbook.controls = {}

-- Player control state tracking
local player_control_states = {}

-- Initialize control tracking for player
function questbook.controls.init_player(player_name)
    if not player_control_states[player_name] then
        player_control_states[player_name] = {
            last_controls = {},
            lmb_held = false,
            rmb_held = false,
            drag_start_time = 0,
            last_pan_time = 0
        }
    end
end

-- Check if questbook is currently open for player
local function is_questbook_open(player_name)
    local state = questbook.gui.get_player_state(player_name)
    -- Simple check - we could make this more sophisticated
    return state and state.selected_chapter
end

-- Handle player control input
function questbook.controls.handle_player_input(player_name)
    if not is_questbook_open(player_name) then
        return
    end
    
    local player = minetest.get_player_by_name(player_name)
    if not player then
        return
    end
    
    questbook.controls.init_player(player_name)
    local control_state = player_control_states[player_name]
    local controls = player:get_player_control()
    local last_controls = control_state.last_controls
    
    local state = questbook.gui.get_player_state(player_name)
    local current_chapter = state.selected_chapter or "tutorial"
    local current_time = minetest.get_us_time() / 1000000 -- Convert to seconds
    
    -- Detect WASD movement for panning - smoother approach
    local base_pan_speed = 80
    local pan_cooldown = 0.05 -- Faster refresh for smoother movement
    
    if current_time - control_state.last_pan_time > pan_cooldown then
        local dx, dy = 0, 0
        
        if controls.up then
            dy = dy - base_pan_speed
        end
        if controls.down then
            dy = dy + base_pan_speed
        end
        if controls.left then
            dx = dx - base_pan_speed
        end
        if controls.right then
            dx = dx + base_pan_speed
        end
        
        -- Apply movement if any direction is pressed
        if dx ~= 0 or dy ~= 0 then
            questbook.viewport.pan(player_name, current_chapter, dx, dy)
            control_state.last_pan_time = current_time
            questbook.handlers.show_questbook(player_name)
        end
    end
    
    -- Detect mouse button presses for potential click-to-zoom
    -- LMB press (dig) - zoom in
    if controls.LMB and not last_controls.LMB then
        questbook.viewport.zoom_in(player_name, current_chapter, 0.1)
        questbook.handlers.show_questbook(player_name)
        minetest.chat_send_player(player_name, "[Questbook] LMB detected - Zoomed in")
    end
    
    -- RMB press (place) - zoom out  
    if controls.RMB and not last_controls.RMB then
        questbook.viewport.zoom_out(player_name, current_chapter, 0.1)
        questbook.handlers.show_questbook(player_name)
        minetest.chat_send_player(player_name, "[Questbook] RMB detected - Zoomed out")
    end
    
    -- Aux1 (sneak+use) for reset zoom
    if controls.aux1 and not last_controls.aux1 then
        questbook.viewport.reset_zoom(player_name, current_chapter)
        questbook.handlers.show_questbook(player_name)
        minetest.chat_send_player(player_name, "[Questbook] Aux1 detected - Reset zoom")
    end
    
    -- Store current controls for next comparison
    control_state.last_controls = table.copy(controls)
end

-- Register global step to monitor player controls
minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local player_name = player:get_player_name()
        questbook.controls.handle_player_input(player_name)
    end
end)

-- Register chat command to test controls
minetest.register_chatcommand("questbook_test_controls", {
    params = "",
    description = "Test player control detection",
    privs = {},
    func = function(player_name, param)
        local player = minetest.get_player_by_name(player_name)
        if not player then
            return false, "Player not found"
        end
        
        local controls = player:get_player_control()
        local control_list = {}
        
        for key, pressed in pairs(controls) do
            if pressed then
                table.insert(control_list, key)
            end
        end
        
        if #control_list > 0 then
            return true, "Currently pressed: " .. table.concat(control_list, ", ")
        else
            return true, "No controls currently pressed"
        end
    end,
})

minetest.log("action", "[Questbook] Player control system loaded")