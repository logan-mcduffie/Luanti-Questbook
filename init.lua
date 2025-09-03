-- Questbook Mod for Luanti
-- A quest and progression tracking system

questbook = {}

-- Load core modules
local modpath = minetest.get_modpath("questbook")

dofile(modpath .. "/core/data.lua")
dofile(modpath .. "/core/storage.lua")
dofile(modpath .. "/core/events.lua")
dofile(modpath .. "/core/settings.lua")
dofile(modpath .. "/core/party.lua")
dofile(modpath .. "/core/trackers.lua")
dofile(modpath .. "/api/quest.lua")

-- Load GUI modules
dofile(modpath .. "/gui/viewport.lua")
dofile(modpath .. "/gui/tiles.lua")
dofile(modpath .. "/gui/canvas.lua")
dofile(modpath .. "/gui/formspec.lua")
dofile(modpath .. "/gui/handlers.lua")
dofile(modpath .. "/gui/keybind.lua")
dofile(modpath .. "/gui/party_commands.lua")
dofile(modpath .. "/gui/player_controls.lua")
dofile(modpath .. "/gui/sscsm_integration.lua")

-- Load example quests (remove in production)
dofile(modpath .. "/examples/sample_quests.lua")

-- Initialize the questbook system
function questbook.init()
    minetest.log("action", "[Questbook] Initializing questbook mod...")
    
    -- Initialize storage system
    questbook.storage.init()
    
    -- Initialize settings system
    questbook.settings.init()
    
    -- Initialize party system
    questbook.party.init()
    
    -- Post confirmation message to all players
    minetest.after(1, function()
        minetest.chat_send_all(minetest.colorize("#00ff00", "[Questbook] ") .. 
                              "Quest system initialized successfully!")
    end)
end

-- Register initialization
minetest.register_on_mods_loaded(function()
    questbook.init()
end)

-- Register privileges
minetest.register_privilege("questbook_admin", {
    description = "Allows editing quests and questbook content",
    give_to_singleplayer = true
})

minetest.log("action", "[Questbook] Questbook mod loaded")