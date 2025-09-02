-- Party system for questbook
-- Allows multiple players to share quest progress

questbook.party = {}

-- Active parties storage
-- Structure: { party_id = { name = "Party Name", leader = "player", officers = {"p1"}, members = {"p1", "p2"}, created = timestamp, officers_can_promote = false } }
local parties = {}

-- Player to party mapping
-- Structure: { player_name = party_id }
local player_parties = {}

-- Party quest progress
-- Structure: { party_id = { quest_id = progress_data } }
local party_quest_progress = {}

local party_counter = 0

-- Initialize party system
function questbook.party.init()
    questbook.party.load_party_data()
    minetest.log("action", "[Questbook] Party system initialized")
end

-- Create a new party
function questbook.party.create_party(leader_name, party_name)
    if questbook.party.get_player_party(leader_name) then
        return nil, "You are already in a party"
    end
    
    party_name = party_name or (leader_name .. "'s Party")
    
    party_counter = party_counter + 1
    local party_id = "party_" .. party_counter
    
    parties[party_id] = {
        name = party_name,
        leader = leader_name,
        officers = {},
        members = {leader_name},
        created = os.time(),
        officers_can_promote = false
    }
    
    player_parties[leader_name] = party_id
    party_quest_progress[party_id] = {}
    
    questbook.party.save_party_data()
    
    minetest.log("action", "[Questbook] Party created: " .. party_id .. " (" .. party_name .. ") by " .. leader_name)
    return party_id, "Party '" .. party_name .. "' created successfully"
end

-- Invite player to party
function questbook.party.invite_player(inviter_name, target_name)
    local party_id = questbook.party.get_player_party(inviter_name)
    if not party_id then
        return false, "You are not in a party"
    end
    
    local party = parties[party_id]
    if not questbook.party.can_manage_party(inviter_name, party_id) then
        return false, "Only the party leader and officers can invite players"
    end
    
    if questbook.party.get_player_party(target_name) then
        return false, target_name .. " is already in a party"
    end
    
    if questbook.party.is_in_party(party_id, target_name) then
        return false, target_name .. " is already in your party"
    end
    
    -- Add to party
    table.insert(party.members, target_name)
    player_parties[target_name] = party_id
    
    -- Transfer any individual quest progress to party
    questbook.party.transfer_individual_progress_to_party(target_name, party_id)
    
    questbook.party.save_party_data()
    
    -- Notify all party members
    questbook.party.notify_party(party_id, 
        minetest.colorize("#00FF00", "[Party] ") .. target_name .. " joined the party!")
    
    return true, target_name .. " has been added to the party"
end

-- Remove player from party
function questbook.party.remove_player(remover_name, target_name)
    local party_id = questbook.party.get_player_party(remover_name)
    if not party_id then
        return false, "You are not in a party"
    end
    
    local party = parties[party_id]
    if not questbook.party.can_manage_party(remover_name, party_id) and remover_name ~= target_name then
        return false, "Only the party leader and officers can remove players (or players can leave themselves)"
    end
    
    if not questbook.party.is_in_party(party_id, target_name) then
        return false, target_name .. " is not in your party"
    end
    
    -- Remove from party
    for i, member in ipairs(party.members) do
        if member == target_name then
            table.remove(party.members, i)
            break
        end
    end
    
    -- Remove from officers if applicable
    for i, officer in ipairs(party.officers) do
        if officer == target_name then
            table.remove(party.officers, i)
            break
        end
    end
    
    player_parties[target_name] = nil
    
    -- If leader leaves, disband party
    if target_name == party.leader then
        return questbook.party.disband_party(leader_name)
    end
    
    questbook.party.save_party_data()
    
    -- Notify party
    questbook.party.notify_party(party_id, 
        minetest.colorize("#FFFF00", "[Party] ") .. target_name .. " left the party")
    
    minetest.chat_send_player(target_name, 
        minetest.colorize("#FFFF00", "[Party] ") .. "You left the party")
    
    return true, target_name .. " has been removed from the party"
end

-- Disband party
function questbook.party.disband_party(leader_name)
    local party_id = questbook.party.get_player_party(leader_name)
    if not party_id then
        return false, "You are not in a party"
    end
    
    local party = parties[party_id]
    if party.leader ~= leader_name then
        return false, "Only the party leader can disband the party"
    end
    
    -- Notify all members
    questbook.party.notify_party(party_id, 
        minetest.colorize("#FF8888", "[Party] ") .. "Party has been disbanded")
    
    -- Transfer party progress back to individual players
    for _, member in ipairs(party.members) do
        questbook.party.transfer_party_progress_to_individual(member, party_id)
        player_parties[member] = nil
    end
    
    -- Clean up
    parties[party_id] = nil
    party_quest_progress[party_id] = nil
    
    questbook.party.save_party_data()
    
    return true, "Party disbanded successfully"
end

-- Get player's party ID
function questbook.party.get_player_party(player_name)
    return player_parties[player_name]
end

-- Check if player is in specific party
function questbook.party.is_in_party(party_id, player_name)
    local party = parties[party_id]
    if not party then
        return false
    end
    
    for _, member in ipairs(party.members) do
        if member == player_name then
            return true
        end
    end
    return false
end

-- Get party information
function questbook.party.get_party_info(party_id)
    return parties[party_id]
end

-- Get party members list
function questbook.party.get_party_members(party_id)
    local party = parties[party_id]
    return party and party.members or {}
end

-- Check if player can manage party (leader or officer)
function questbook.party.can_manage_party(player_name, party_id)
    local party = parties[party_id]
    if not party then
        return false
    end
    
    -- Leader can always manage
    if party.leader == player_name then
        return true
    end
    
    -- Check if player is an officer
    for _, officer in ipairs(party.officers) do
        if officer == player_name then
            return true
        end
    end
    
    return false
end

-- Promote player to officer
function questbook.party.promote_player(promoter_name, target_name)
    local party_id = questbook.party.get_player_party(promoter_name)
    if not party_id then
        return false, "You are not in a party"
    end
    
    local party = parties[party_id]
    
    -- Check if promoter has permission to promote
    local can_promote = false
    if party.leader == promoter_name then
        -- Leader can always promote
        can_promote = true
    else
        -- Check if promoter is an officer and officers can promote
        local is_officer = false
        for _, officer in ipairs(party.officers) do
            if officer == promoter_name then
                is_officer = true
                break
            end
        end
        
        if is_officer and party.officers_can_promote then
            can_promote = true
        end
    end
    
    if not can_promote then
        if party.officers_can_promote then
            return false, "Only the party leader and officers can promote players"
        else
            return false, "Only the party leader can promote players"
        end
    end
    
    if not questbook.party.is_in_party(party_id, target_name) then
        return false, target_name .. " is not in your party"
    end
    
    if party.leader == target_name then
        return false, "Player is already the party leader"
    end
    
    -- Check if already an officer
    for _, officer in ipairs(party.officers) do
        if officer == target_name then
            return false, target_name .. " is already an officer"
        end
    end
    
    -- Add to officers
    table.insert(party.officers, target_name)
    questbook.party.save_party_data()
    
    -- Notify party
    questbook.party.notify_party(party_id, 
        minetest.colorize("#FFD700", "[Party] ") .. target_name .. " has been promoted to officer")
    
    return true, target_name .. " has been promoted to officer"
end

-- Transfer leadership
function questbook.party.transfer_leadership(leader_name, target_name)
    local party_id = questbook.party.get_player_party(leader_name)
    if not party_id then
        return false, "You are not in a party"
    end
    
    local party = parties[party_id]
    if party.leader ~= leader_name then
        return false, "Only the party leader can transfer leadership"
    end
    
    if not questbook.party.is_in_party(party_id, target_name) then
        return false, target_name .. " is not in your party"
    end
    
    if party.leader == target_name then
        return false, "Player is already the party leader"
    end
    
    -- Remove target from officers if they were one
    for i, officer in ipairs(party.officers) do
        if officer == target_name then
            table.remove(party.officers, i)
            break
        end
    end
    
    -- Add old leader to officers
    table.insert(party.officers, leader_name)
    
    -- Transfer leadership
    party.leader = target_name
    questbook.party.save_party_data()
    
    -- Notify party
    questbook.party.notify_party(party_id, 
        minetest.colorize("#FFD700", "[Party] ") .. target_name .. " is now the party leader")
    
    return true, "Leadership transferred to " .. target_name
end

-- Demote player from officer to member
function questbook.party.demote_player(leader_name, target_name)
    local party_id = questbook.party.get_player_party(leader_name)
    if not party_id then
        return false, "You are not in a party"
    end
    
    local party = parties[party_id]
    if party.leader ~= leader_name then
        return false, "Only the party leader can demote players"
    end
    
    if not questbook.party.is_in_party(party_id, target_name) then
        return false, target_name .. " is not in your party"
    end
    
    if party.leader == target_name then
        return false, "Cannot demote the party leader"
    end
    
    -- Check if player is an officer
    local was_officer = false
    for i, officer in ipairs(party.officers) do
        if officer == target_name then
            table.remove(party.officers, i)
            was_officer = true
            break
        end
    end
    
    if not was_officer then
        return false, target_name .. " is not an officer"
    end
    
    questbook.party.save_party_data()
    
    -- Notify party
    questbook.party.notify_party(party_id, 
        minetest.colorize("#FFFF00", "[Party] ") .. target_name .. " has been demoted to member")
    
    return true, target_name .. " has been demoted to member"
end

-- Toggle officer promotion permission
function questbook.party.toggle_officer_promote_permission(leader_name)
    local party_id = questbook.party.get_player_party(leader_name)
    if not party_id then
        return false, "You are not in a party"
    end
    
    local party = parties[party_id]
    if party.leader ~= leader_name then
        return false, "Only the party leader can toggle officer promotion permissions"
    end
    
    -- Toggle the permission
    party.officers_can_promote = not party.officers_can_promote
    questbook.party.save_party_data()
    
    local status = party.officers_can_promote and "enabled" or "disabled"
    local message = "Officer promotion permissions " .. status
    
    -- Notify party
    questbook.party.notify_party(party_id, 
        minetest.colorize("#FFD700", "[Party] ") .. message)
    
    return true, message
end

-- Notify all party members
function questbook.party.notify_party(party_id, message)
    local party = parties[party_id]
    if not party then
        return
    end
    
    for _, member in ipairs(party.members) do
        local player = minetest.get_player_by_name(member)
        if player then
            minetest.chat_send_player(member, message)
        end
    end
end

-- Transfer individual quest progress to party
function questbook.party.transfer_individual_progress_to_party(player_name, party_id)
    local individual_quests = questbook.get_player_quests(player_name)
    
    for quest_id, quest_data in pairs(individual_quests) do
        local quest = questbook.get_quest(quest_id)
        if quest and quest.party_shared then
            -- Move progress to party if quest supports party sharing
            if not party_quest_progress[party_id][quest_id] then
                party_quest_progress[party_id][quest_id] = quest_data.progress
                -- Clear individual progress
                questbook.storage.set_player_quest_progress(player_name, quest_id, nil)
            end
        end
    end
end

-- Transfer party quest progress back to individual player
function questbook.party.transfer_party_progress_to_individual(player_name, party_id)
    local party_progress = party_quest_progress[party_id] or {}
    
    for quest_id, progress in pairs(party_progress) do
        -- Give copy of party progress to individual player
        questbook.storage.set_player_quest_progress(player_name, quest_id, progress)
    end
end

-- Get party quest progress
function questbook.party.get_party_quest_progress(party_id, quest_id)
    if not party_quest_progress[party_id] then
        return nil
    end
    return party_quest_progress[party_id][quest_id]
end

-- Set party quest progress
function questbook.party.set_party_quest_progress(party_id, quest_id, progress)
    if not party_quest_progress[party_id] then
        party_quest_progress[party_id] = {}
    end
    party_quest_progress[party_id][quest_id] = progress
    questbook.party.save_party_data()
end

-- Check if player should use party progress for a quest
function questbook.party.should_use_party_progress(player_name, quest_id)
    local party_id = questbook.party.get_player_party(player_name)
    if not party_id then
        return false
    end
    
    local quest = questbook.get_quest(quest_id)
    return quest and quest.party_shared == true
end

-- Save party data
function questbook.party.save_party_data()
    local world_path = minetest.get_worldpath()
    local party_data = {
        parties = parties,
        player_parties = player_parties,
        party_quest_progress = party_quest_progress,
        party_counter = party_counter
    }
    
    local file = io.open(world_path .. "/questbook_parties.lua", "w")
    if file then
        file:write("-- Questbook party data\n")
        file:write("return " .. minetest.serialize(party_data))
        file:close()
    end
end

-- Load party data
function questbook.party.load_party_data()
    local world_path = minetest.get_worldpath()
    local file = io.open(world_path .. "/questbook_parties.lua", "r")
    if not file then
        return
    end
    
    local data = file:read("*all")
    file:close()
    
    if data and data ~= "" then
        local loaded_data = minetest.deserialize(data:match("return (.*)"))
        if loaded_data and type(loaded_data) == "table" then
            parties = loaded_data.parties or {}
            player_parties = loaded_data.player_parties or {}
            party_quest_progress = loaded_data.party_quest_progress or {}
            party_counter = loaded_data.party_counter or 0
        end
    end
end

-- Clean up when player leaves server
minetest.register_on_leaveplayer(function(player)
    -- Note: We don't auto-remove from party when player leaves
    -- Party persists until manually disbanded
end)

minetest.log("action", "[Questbook] Party system loaded")