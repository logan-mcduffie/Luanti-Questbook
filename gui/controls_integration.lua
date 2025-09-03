-- Controls mod integration for questbook
-- Uses the controls mod for better input handling

questbook.controls_mod = {}

-- Check if controls mod is available - disabled due to mod bug
local controls_available = false -- minetest.get_modpath("controls") ~= nil and controls ~= nil

-- Check if questbook is open for player
local function is_questbook_open(player_name)
    local state = questbook.gui.get_player_state(player_name)
    return state and state.selected_chapter
end

-- Initialize controls mod integration
function questbook.controls_mod.init()
    if not controls_available then
        minetest.log("info", "[Questbook] Controls mod not available")
        return false
    end
    
    minetest.log("action", "[Questbook] Initializing controls mod integration")
    
    -- Pan controls using WASD
    controls.register_on_hold("up", function(player, dtime)
        local player_name = player:get_player_name()
        if is_questbook_open(player_name) then
            local state = questbook.gui.get_player_state(player_name)
            local current_chapter = state.selected_chapter or "tutorial"
            questbook.viewport.pan(player_name, current_chapter, 0, -50 * dtime * 5) -- Smooth panning
        end
    end)
    
    controls.register_on_hold("down", function(player, dtime)
        local player_name = player:get_player_name()
        if is_questbook_open(player_name) then
            local state = questbook.gui.get_player_state(player_name)
            local current_chapter = state.selected_chapter or "tutorial"
            questbook.viewport.pan(player_name, current_chapter, 0, 50 * dtime * 5)
        end
    end)
    
    controls.register_on_hold("left", function(player, dtime)
        local player_name = player:get_player_name()
        if is_questbook_open(player_name) then
            local state = questbook.gui.get_player_state(player_name)
            local current_chapter = state.selected_chapter or "tutorial"
            questbook.viewport.pan(player_name, current_chapter, -50 * dtime * 5, 0)
        end
    end)
    
    controls.register_on_hold("right", function(player, dtime)
        local player_name = player:get_player_name()
        if is_questbook_open(player_name) then
            local state = questbook.gui.get_player_state(player_name)
            local current_chapter = state.selected_chapter or "tutorial"
            questbook.viewport.pan(player_name, current_chapter, 50 * dtime * 5, 0)
        end
    end)
    
    -- Mouse click zoom controls
    controls.register_on_press("LMB", function(player)
        local player_name = player:get_player_name()
        if is_questbook_open(player_name) then
            local state = questbook.gui.get_player_state(player_name)
            local current_chapter = state.selected_chapter or "tutorial"
            questbook.viewport.zoom_in(player_name, current_chapter, 0.1)
            questbook.handlers.show_questbook(player_name)
            minetest.chat_send_player(player_name, "[Questbook] Zoom In (LMB)")
        end
    end)
    
    controls.register_on_press("RMB", function(player)
        local player_name = player:get_player_name()
        if is_questbook_open(player_name) then
            local state = questbook.gui.get_player_state(player_name)
            local current_chapter = state.selected_chapter or "tutorial"
            questbook.viewport.zoom_out(player_name, current_chapter, 0.1)
            questbook.handlers.show_questbook(player_name)
            minetest.chat_send_player(player_name, "[Questbook] Zoom Out (RMB)")
        end
    end)
    
    -- Reset zoom with Aux1
    controls.register_on_press("aux1", function(player)
        local player_name = player:get_player_name()
        if is_questbook_open(player_name) then
            local state = questbook.gui.get_player_state(player_name)
            local current_chapter = state.selected_chapter or "tutorial"
            questbook.viewport.reset_zoom(player_name, current_chapter)
            questbook.handlers.show_questbook(player_name)
            minetest.chat_send_player(player_name, "[Questbook] Reset Zoom")
        end
    end)
    
    -- Smooth panning refresh
    local last_refresh_time = {}
    controls.register_on_hold("up", function(player, dtime)
        local player_name = player:get_player_name()
        if is_questbook_open(player_name) then
            local current_time = minetest.get_us_time() / 1000000
            if not last_refresh_time[player_name] or current_time - last_refresh_time[player_name] > 0.1 then
                questbook.handlers.show_questbook(player_name)
                last_refresh_time[player_name] = current_time
            end
        end
    end)
    
    -- Add similar refresh for other directions
    for _, direction in ipairs({"down", "left", "right"}) do
        controls.register_on_hold(direction, function(player, dtime)
            local player_name = player:get_player_name()
            if is_questbook_open(player_name) then
                local current_time = minetest.get_us_time() / 1000000
                if not last_refresh_time[player_name] or current_time - last_refresh_time[player_name] > 0.1 then
                    questbook.handlers.show_questbook(player_name)
                    last_refresh_time[player_name] = current_time
                end
            end
        end)
    end
    
    minetest.log("action", "[Questbook] Controls mod integration initialized")
    return true
end

-- Check if controls mod is available for notifications
function questbook.controls_mod.is_available()
    return controls_available
end

-- Initialize on mod load
minetest.register_on_mods_loaded(function()
    questbook.controls_mod.init()
end)

minetest.log("action", "[Questbook] Controls mod integration loaded")