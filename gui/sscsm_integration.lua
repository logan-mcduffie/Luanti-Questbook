-- SSCSM integration for questbook
-- Handles client-server communication for advanced mouse controls

questbook.sscsm = {}

-- Check if SSCSM is available
local sscsm_available = minetest.get_modpath("sscsm") ~= nil

-- Initialize SSCSM integration
function questbook.sscsm.init()
    if not sscsm_available then
        minetest.log("info", "[Questbook] SSCSM not available, using fallback controls")
        return false
    end
    
    -- Load client-side scripts via SSCSM
    local modpath = minetest.get_modpath("questbook")
    local mouse_script_path = modpath .. "/sscsm/mouse_controls.lua"
    
    -- Read and send client script
    local file = io.open(mouse_script_path, "r")
    if file then
        local script_content = file:read("*all")
        file:close()
        
        -- Send script to all players with SSCSM
        sscsm.register({
            name = "questbook:mouse_controls",
            file = mouse_script_path,
            description = "Questbook mouse controls"
        })
        
        minetest.log("action", "[Questbook] SSCSM mouse controls registered")
        return true
    else
        minetest.log("error", "[Questbook] Could not read mouse controls script")
        return false
    end
end

-- Register chat commands for client-server communication
minetest.register_chatcommand("questbook_pan", {
    params = "<dx> <dy>",
    description = "Pan questbook viewport (internal use)",
    privs = {},
    func = function(player_name, param)
        -- Parse parameters
        local dx, dy = param:match("([%-%d%.]+)%s+([%-%d%.]+)")
        dx, dy = tonumber(dx), tonumber(dy)
        
        if not dx or not dy then
            return false, "Invalid parameters"
        end
        
        -- Apply pan to viewport
        local state = questbook.gui.get_player_state(player_name)
        local current_chapter = state.selected_chapter or "tutorial"
        
        if questbook.viewport.pan(player_name, current_chapter, dx, dy) then
            -- Refresh questbook for this player
            questbook.handlers.show_questbook(player_name)
            return true
        end
        
        return false, "Pan failed"
    end,
})

minetest.register_chatcommand("questbook_zoom", {
    params = "<direction> <factor>",
    description = "Zoom questbook viewport (internal use)", 
    privs = {},
    func = function(player_name, param)
        -- Parse parameters
        local direction, factor = param:match("(%w+)%s+([%d%.]+)")
        factor = tonumber(factor) or 0.1
        
        if not direction then
            return false, "Invalid parameters"
        end
        
        -- Apply zoom to viewport
        local state = questbook.gui.get_player_state(player_name)
        local current_chapter = state.selected_chapter or "tutorial"
        
        local success = false
        if direction == "in" then
            success = questbook.viewport.zoom_in(player_name, current_chapter, factor)
        elseif direction == "out" then
            success = questbook.viewport.zoom_out(player_name, current_chapter, factor)
        end
        
        if success then
            -- Refresh questbook for this player
            questbook.handlers.show_questbook(player_name)
            return true
        end
        
        return false, "Zoom failed"
    end,
})

-- Check if player has SSCSM support
function questbook.sscsm.player_has_support(player_name)
    if not sscsm_available then
        return false
    end
    
    -- Check if player has SSCSM client mod
    local player = minetest.get_player_by_name(player_name)
    if not player then
        return false
    end
    
    -- SSCSM provides a way to check if player has the client mod
    return sscsm.has_csm_support(player_name) or false
end

-- Send notification about mouse controls to players
function questbook.sscsm.notify_controls(player_name)
    if questbook.sscsm.player_has_support(player_name) then
        minetest.chat_send_player(player_name, 
            minetest.colorize("#00FF00", "[Questbook] ") ..
            "Advanced mouse controls enabled! Use mouse drag to pan, scroll wheel to zoom."
        )
    else
        minetest.chat_send_player(player_name,
            minetest.colorize("#FFAA00", "[Questbook] ") ..
            "Using button controls. Install SSCSM for advanced mouse interactions."
        )
    end
end

-- Initialize when mod loads
minetest.register_on_mods_loaded(function()
    questbook.sscsm.init()
end)

minetest.log("action", "[Questbook] SSCSM integration loaded")