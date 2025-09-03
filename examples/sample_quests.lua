-- Sample quests for testing questbook functionality
-- These quests demonstrate different quest types and features

-- Simple collection quest
local first_quest = questbook.create_quest(
    "questbook:first_steps", 
    "First Steps", 
    "Welcome to the world! Let's start by gathering some basic resources."
)
questbook.add_objective(first_quest, "collect_wood", "collect", "Collect wood logs", "any_tree", 10)
questbook.add_objective(first_quest, "collect_stone", "collect", "Collect stone", "any_stone", 20)
questbook.add_reward(first_quest, "item", "default:pick_stone", 1)
questbook.add_reward(first_quest, "item", "default:axe_stone", 1)
questbook.set_quest_properties(first_quest, {category = "tutorial"})
questbook.set_quest_tile(first_quest, "default:tree", 100, 100)

-- Crafting quest with prerequisites
local crafting_quest = questbook.create_quest(
    "questbook:basic_crafting",
    "Basic Crafting",
    "Now that you have resources, let's craft some essential tools and items."
)
questbook.add_objective(crafting_quest, "craft_planks", "craft", "Craft wooden planks", "any_wood", 20)
questbook.add_objective(crafting_quest, "craft_sticks", "craft", "Craft sticks", "default:stick", 10)
questbook.add_objective(crafting_quest, "craft_chest", "craft", "Craft a chest for storage", "default:chest", 1)
questbook.add_reward(crafting_quest, "item", "default:pick_steel", 1)
questbook.add_reward(crafting_quest, "item", "default:torch", 20)
questbook.set_prerequisites(crafting_quest, {"questbook:first_steps"})
questbook.set_quest_properties(crafting_quest, {category = "tutorial"})
questbook.set_quest_tile(crafting_quest, "default:chest", 350, 100)

-- Building quest
local building_quest = questbook.create_quest(
    "questbook:shelter_builder",
    "Shelter Builder",
    "Build a basic shelter to protect yourself from the elements."
)
questbook.add_objective(building_quest, "place_planks", "build", "Place wooden planks", "default:wood", 50)
questbook.add_objective(building_quest, "place_door", "build", "Place a door", "doors:door_wood_a", 1)
questbook.add_objective(building_quest, "place_bed", "build", "Place a bed", "beds:bed_bottom", 1)
questbook.add_reward(building_quest, "item", "default:glass", 10)
questbook.add_reward(building_quest, "item", "wool:white", 5)
questbook.set_prerequisites(building_quest, {"questbook:basic_crafting"})
questbook.set_quest_properties(building_quest, {category = "building"})
questbook.set_quest_tile(building_quest, "default:wood", 600, 100)

-- Exploration quest
local exploration_quest = questbook.create_quest(
    "questbook:cave_explorer",
    "Cave Explorer", 
    "Venture underground to discover the secrets beneath the surface."
)
questbook.add_objective(exploration_quest, "find_coal", "collect", "Find coal ore", "default:stone_with_coal", 15)
questbook.add_objective(exploration_quest, "find_iron", "collect", "Find iron ore", "default:stone_with_iron", 10)
questbook.add_objective(exploration_quest, "find_diamond", "collect", "Find diamonds (optional)", "default:stone_with_diamond", 2)
-- Make diamond objective optional
exploration_quest.objectives[3].optional = true
questbook.add_reward(exploration_quest, "item", "default:pick_diamond", 1)
questbook.add_reward(exploration_quest, "item", "default:torch", 50)
questbook.set_prerequisites(exploration_quest, {"questbook:shelter_builder"})
questbook.set_quest_properties(exploration_quest, {category = "exploration"})
questbook.set_quest_tile(exploration_quest, "default:stone_with_coal", 100, 400)

-- Advanced quest chain
local master_quest = questbook.create_quest(
    "questbook:master_crafter",
    "Master Crafter",
    "Prove your mastery by crafting advanced items and tools."
)
questbook.add_objective(master_quest, "craft_furnace", "craft", "Craft a furnace", "default:furnace", 1)
questbook.add_objective(master_quest, "craft_steel_ingot", "craft", "Smelt steel ingots", "default:steel_ingot", 10)
questbook.add_objective(master_quest, "craft_mese_crystal", "craft", "Craft mese crystals", "default:mese_crystal", 5)
questbook.add_reward(master_quest, "item", "default:mese_block", 2)
questbook.add_reward(master_quest, "item", "default:diamondblock", 1)
questbook.set_prerequisites(master_quest, {"questbook:cave_explorer"})
questbook.set_quest_properties(master_quest, {category = "advanced"})
questbook.set_quest_tile(master_quest, "default:mese_block", 350, 400)

-- Repeatable daily quest
local daily_quest = questbook.create_quest(
    "questbook:daily_gathering",
    "Daily Gathering",
    "A daily task to keep you busy. This quest can be repeated."
)
questbook.add_objective(daily_quest, "collect_dirt", "collect", "Collect dirt", "default:dirt", 64)
questbook.add_objective(daily_quest, "collect_sand", "collect", "Collect sand", "default:sand", 32)
questbook.add_reward(daily_quest, "item", "default:gold_ingot", 2)
questbook.set_quest_properties(daily_quest, {
    category = "daily", 
    repeatable = true,
    time_limit = 86400 -- 24 hours in seconds
})
questbook.set_quest_tile(daily_quest, "default:dirt", 100, 100)

-- Example quest WITH progress notifications (for testing/demonstration)
local verbose_quest = questbook.create_quest(
    "questbook:verbose_gathering",
    "Verbose Gathering", 
    "This quest will show progress notifications in chat - useful for testing or short-term objectives."
)
questbook.add_objective(verbose_quest, "collect_cobble", "collect", "Collect cobblestone", "default:cobble", 5)
questbook.add_reward(verbose_quest, "item", "default:torch", 10)
questbook.set_quest_properties(verbose_quest, {
    category = "tutorial", 
    show_progress_chat = true -- Enable progress notifications
})
questbook.set_quest_tile(verbose_quest, "default:cobble", 100, 250)

-- Example quest that hides when locked (demonstrates per-quest visibility)
local secret_quest = questbook.create_quest(
    "questbook:secret_advanced",
    "Secret Advanced Quest",
    "A mysterious quest that only appears when you're ready for it."
)
questbook.add_objective(secret_quest, "collect_diamonds", "collect", "Collect diamonds", "any_diamond", 3)
questbook.add_reward(secret_quest, "item", "default:mese_block", 5)
questbook.set_prerequisites(secret_quest, {"questbook:master_crafter"})
questbook.set_quest_properties(secret_quest, {
    category = "advanced",
    hide_when_locked = true -- This quest will be hidden until prerequisites are met
})

-- Example party quest (demonstrates shared progress)
local party_quest = questbook.create_quest(
    "questbook:party_mining",
    "Team Mining Operation",
    "Work together with your party to gather resources for a major construction project. Progress is shared between all party members!"
)
questbook.add_objective(party_quest, "mine_stone", "collect", "Mine stone blocks", "any_stone", 200)
questbook.add_objective(party_quest, "mine_wood", "collect", "Gather wood logs", "any_tree", 100)
questbook.add_objective(party_quest, "mine_iron", "collect", "Mine iron ore", "any_iron", 50)
questbook.add_reward(party_quest, "item", "default:steelblock", 10)
questbook.add_reward(party_quest, "item", "default:goldblock", 5)
questbook.set_quest_properties(party_quest, {
    category = "party",
    party_shared = true -- Enable party sharing for this quest
})

-- Another party quest with different objectives
local party_building = questbook.create_quest(
    "questbook:party_construction",
    "Community Construction",
    "Build a community structure together! Each party member's building progress counts toward the shared goal."
)
questbook.add_objective(party_building, "place_cobble", "build", "Place cobblestone blocks", "default:cobble", 500)
questbook.add_objective(party_building, "place_wood", "build", "Place wooden planks", "any_wood", 300)
questbook.add_objective(party_building, "place_glass", "build", "Place glass blocks", "default:glass", 100)
questbook.add_reward(party_building, "item", "default:diamondblock", 3)
questbook.add_reward(party_building, "item", "default:mese_crystal", 20)
questbook.set_prerequisites(party_building, {"questbook:party_mining"})
questbook.set_quest_properties(party_building, {
    category = "party",
    party_shared = true -- Enable party sharing for this quest
})

-- Example consume quest (shop-like functionality)
local consume_quest = questbook.create_quest(
    "questbook:wood_trader",
    "Wood Trader",
    "Trade wood resources for useful tools. This quest consumes your items when you submit them - like a shop!"
)
questbook.add_objective(consume_quest, "bring_logs", "collect", "Bring wood logs", "any_tree", 10)
questbook.add_objective(consume_quest, "bring_planks", "collect", "Bring wooden planks", "any_wood", 20)
questbook.add_reward(consume_quest, "item", "default:pick_steel", 1)
questbook.add_reward(consume_quest, "item", "default:axe_steel", 1)
questbook.add_reward(consume_quest, "item", "default:shovel_steel", 1)
questbook.set_quest_properties(consume_quest, {
    category = "trading",
    quest_type = "consume" -- This makes it a consume quest
})

-- Example checkbox quest (information-based)
local info_quest = questbook.create_quest(
    "questbook:server_rules",
    "Server Rules & Information",
    "Please read and acknowledge the server rules and guidelines. This is an information quest - simply check it complete when you've read everything."
)
-- Checkbox quests need a dummy objective for validation, but it's not tracked
questbook.add_objective(info_quest, "acknowledge_rules", "custom", "Read and acknowledge the server rules", "rules_acknowledged", 1)
questbook.add_reward(info_quest, "item", "default:torch", 10)
questbook.add_reward(info_quest, "item", "farming:bread", 5)
questbook.set_quest_properties(info_quest, {
    category = "tutorial",
    quest_type = "checkbox" -- This makes it a checkbox quest
})

-- Another consume quest example
local ore_trader = questbook.create_quest(
    "questbook:ore_exchange",
    "Ore Exchange Service",
    "Exchange raw ores for refined materials. Bring the required ores and receive processed goods in return."
)
questbook.add_objective(ore_trader, "bring_coal", "collect", "Bring coal lumps", "any_coal", 15)
questbook.add_objective(ore_trader, "bring_iron", "collect", "Bring iron lumps", "any_iron", 8)
questbook.add_reward(ore_trader, "item", "default:steel_ingot", 10)
questbook.add_reward(ore_trader, "item", "default:torch", 20)
questbook.add_reward(ore_trader, "item", "default:coal_lump", 5)
questbook.set_prerequisites(ore_trader, {"questbook:cave_explorer"})
questbook.set_quest_properties(ore_trader, {
    category = "trading",
    quest_type = "consume"
})

-- Example quest with currency reward
local currency_quest = questbook.create_quest(
    "questbook:stone_collector",
    "Stone Collector",
    "Collect various stone types and earn questbook currency for your efforts!"
)
questbook.add_objective(currency_quest, "collect_stone", "collect", "Collect regular stone", "default:stone", 50)
questbook.add_objective(currency_quest, "collect_cobble", "collect", "Collect cobblestone", "default:cobble", 30)
questbook.add_currency_reward(currency_quest, 25)
questbook.add_reward(currency_quest, "item", "default:torch", 10)
questbook.set_quest_properties(currency_quest, {
    category = "currency",
    repeatable = true,
    repeat_type = "daily"
})

-- Example quest with lootbag reward
local loot_quest = questbook.create_quest(
    "questbook:treasure_hunter",
    "Treasure Hunter",
    "Hunt for treasure and receive a random loot bag with valuable rewards!"
)
questbook.add_objective(loot_quest, "mine_deep", "collect", "Mine deep ores", "any_diamond", 3)
questbook.add_objective(loot_quest, "collect_gold", "collect", "Collect gold ore", "default:stone_with_gold", 5)

-- Create a lootbag with weighted random rewards
local treasure_items = {
    {item = "default:diamond", count = 2, weight = 5, chance = 80},
    {item = "default:gold_ingot", count = 3, weight = 10, chance = 100},
    {item = "default:mese_crystal", count = 1, weight = 3, chance = 60},
    {item = "default:steel_ingot", count = 5, weight = 15, chance = 100},
    {item = "default:pick_diamond", count = 1, weight = 2, chance = 40},
    {item = "default:mese_block", count = 1, weight = 1, chance = 20}
}
questbook.add_lootbag_reward(loot_quest, "Treasure Chest", treasure_items, 2)
questbook.add_currency_reward(loot_quest, 50)
questbook.set_quest_properties(loot_quest, {
    category = "advanced",
    repeatable = true,
    repeat_type = "cooldown",
    repeat_cooldown = 3600 -- 1 hour cooldown
})

-- Example manual repeatable currency shop quest
local shop_quest = questbook.create_quest(
    "questbook:resource_exchange",
    "Resource Exchange",
    "Trade your surplus resources for questbook currency at the exchange!"
)
questbook.add_objective(shop_quest, "trade_wood", "collect", "Bring wood for trade", "any_tree", 64)
questbook.add_objective(shop_quest, "trade_stone", "collect", "Bring stone for trade", "any_stone", 32)
questbook.add_currency_reward(shop_quest, 15)
questbook.set_quest_properties(shop_quest, {
    category = "trading",
    quest_type = "consume", -- Items are consumed when submitted
    repeatable = true,
    repeat_type = "manual" -- Can be repeated immediately
})

-- Example weekly repeatable quest with mixed rewards
local weekly_quest = questbook.create_quest(
    "questbook:weekly_challenge",
    "Weekly Challenge",
    "Complete weekly challenges for great rewards! This quest resets every week."
)
questbook.add_objective(weekly_quest, "craft_tools", "craft", "Craft steel tools", "default:pick_steel", 3)
questbook.add_objective(weekly_quest, "build_house", "build", "Place building blocks", "default:stonebrick", 100)
questbook.add_objective(weekly_quest, "mine_ores", "collect", "Mine various ores", "any_iron", 25)

-- Mixed rewards: currency, items, and a loot bag
questbook.add_currency_reward(weekly_quest, 100)
questbook.add_reward(weekly_quest, "item", "default:diamondblock", 1)

local weekly_loot = {
    {item = "default:mese_crystal", count = 3, weight = 10, chance = 100},
    {item = "default:diamond", count = 5, weight = 8, chance = 90},
    {item = "default:goldblock", count = 1, weight = 5, chance = 70},
    {item = "default:pick_mese", count = 1, weight = 3, chance = 50}
}
questbook.add_lootbag_reward(weekly_quest, "Weekly Bonus Pack", weekly_loot, 1)

questbook.set_quest_properties(weekly_quest, {
    category = "advanced",
    repeatable = true,
    repeat_type = "weekly"
})

-- Register all sample quests
local sample_quests = {
    first_quest,
    crafting_quest, 
    building_quest,
    exploration_quest,
    master_quest,
    daily_quest,
    verbose_quest,
    secret_quest,
    party_quest,
    party_building,
    consume_quest,
    info_quest,
    ore_trader,
    currency_quest,
    loot_quest,
    shop_quest,
    weekly_quest
}

for _, quest in ipairs(sample_quests) do
    local success = questbook.register_quest(quest)
    if success then
        minetest.log("action", "[Questbook] Registered sample quest: " .. quest.id)
    else
        minetest.log("error", "[Questbook] Failed to register sample quest: " .. quest.id)
    end
end

minetest.log("action", "[Questbook] Sample quests loaded")