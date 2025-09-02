-- Party management chat commands
-- Unified /party command with subcommands

-- Main party command with subcommands
minetest.register_chatcommand("party", {
    description = "Party management commands",
    params = "<create [party_name] | invite <player> | kick <player> | leave | disband | info | promote <player> | demote <player> | transfer <player> | help>",
    func = function(name, param)
        local args = param:split(" ")
        local subcmd = args[1] and args[1]:lower() or ""
        
        if subcmd == "create" then
            -- /party create [party_name]
            local party_name = table.concat(args, " ", 2)
            if party_name == "" then
                party_name = nil -- Use default naming
            end
            
            local party_id, message = questbook.party.create_party(name, party_name)
            if party_id then
                return true, message
            else
                return false, message
            end
            
        elseif subcmd == "invite" then
            -- /party invite <player>
            local target_name = args[2]
            if not target_name then
                return false, "Usage: /party invite <player_name>"
            end
            
            if not minetest.get_player_by_name(target_name) then
                return false, "Player '" .. target_name .. "' is not online"
            end
            
            local success, message = questbook.party.invite_player(name, target_name)
            return success, message
            
        elseif subcmd == "kick" then
            -- /party kick <player>
            local target_name = args[2]
            if not target_name then
                return false, "Usage: /party kick <player_name>"
            end
            
            local success, message = questbook.party.remove_player(name, target_name)
            return success, message
            
        elseif subcmd == "leave" then
            -- /party leave
            local success, message = questbook.party.remove_player(name, name)
            return success, message
            
        elseif subcmd == "disband" then
            -- /party disband
            local success, message = questbook.party.disband_party(name)
            return success, message
            
        elseif subcmd == "info" then
            -- /party info
            local party_id = questbook.party.get_player_party(name)
            if not party_id then
                return false, "You are not in a party"
            end
            
            local party = questbook.party.get_party_info(party_id)
            if not party then
                return false, "Party not found"
            end
            
            minetest.chat_send_player(name, minetest.colorize("#00FFFF", "=== Party Information ==="))
            minetest.chat_send_player(name, "Name: " .. party.name)
            minetest.chat_send_player(name, "Leader: " .. party.leader)
            
            if #party.officers > 0 then
                minetest.chat_send_player(name, "Officers: " .. table.concat(party.officers, ", "))
            end
            
            minetest.chat_send_player(name, "Members (" .. #party.members .. "):")
            
            for _, member in ipairs(party.members) do
                local status = minetest.get_player_by_name(member) and 
                              minetest.colorize("#00FF00", "[Online]") or 
                              minetest.colorize("#888888", "[Offline]")
                local rank = ""
                if member == party.leader then
                    rank = minetest.colorize("#FFD700", " [Leader]")
                else
                    for _, officer in ipairs(party.officers) do
                        if member == officer then
                            rank = minetest.colorize("#00FFFF", " [Officer]")
                            break
                        end
                    end
                end
                minetest.chat_send_player(name, "  • " .. member .. rank .. " " .. status)
            end
            
            return true, ""
            
        elseif subcmd == "promote" then
            -- /party promote <player>
            local target_name = args[2]
            if not target_name then
                return false, "Usage: /party promote <player_name>"
            end
            
            local success, message = questbook.party.promote_player(name, target_name)
            return success, message
            
        elseif subcmd == "demote" then
            -- /party demote <player>
            local target_name = args[2]
            if not target_name then
                return false, "Usage: /party demote <player_name>"
            end
            
            local success, message = questbook.party.demote_player(name, target_name)
            return success, message
            
        elseif subcmd == "transfer" then
            -- /party transfer <player>
            local target_name = args[2]
            if not target_name then
                return false, "Usage: /party transfer <player_name>"
            end
            
            local success, message = questbook.party.transfer_leadership(name, target_name)
            return success, message
            
        elseif subcmd == "toggle_officer_promote" then
            -- /party toggle_officer_promote
            local success, message = questbook.party.toggle_officer_promote_permission(name)
            return success, message
            
        elseif subcmd == "help" or subcmd == "" then
            -- /party help
            local help_text = minetest.colorize("#00FFFF", "=== Party System Help ===") .. "\n" ..
                             "/party create [name] - Create a new party\n" ..
                             "/party invite <player> - Invite a player to your party\n" ..
                             "/party kick <player> - Kick player from party\n" ..
                             "/party leave - Leave your current party\n" ..
                             "/party disband - Disband party (leader only)\n" ..
                             "/party info - Show party information\n" ..
                             "/party promote <player> - Promote player to officer (leader only)\n" ..
                             "/party demote <player> - Demote officer to member (leader only)\n" ..
                             "/party transfer <player> - Transfer leadership (leader only)\n" ..
                             "/party toggle_officer_promote - Toggle officer promotion rights (leader only)\n" ..
                             "/party help - Show this help\n" ..
                             "\n" .. minetest.colorize("#FFFF00", "Note: ") .. 
                             "Only quests marked as 'party_shared' will share progress between party members."
            
            minetest.chat_send_player(name, help_text)
            return true, ""
            
        else
            return false, "Unknown subcommand. Use '/party help' for available commands."
        end
    end
})

-- Track players who have initiated reset process
local reset_confirmations = {}

-- Questbook reset functionality
minetest.register_chatcommand("questbook", {
    description = "Questbook management commands",
    params = "<reset>",
    func = function(name, param)
        local args = param:split(" ")
        local subcmd = args[1] and args[1]:lower() or ""
        
        if subcmd == "reset" then
            -- First stage: Warning message
            if not reset_confirmations[name] then
                reset_confirmations[name] = os.time()
                
                minetest.chat_send_player(name, 
                    minetest.colorize("#FF0000", "⚠️  WARNING: QUESTBOOK RESET  ⚠️"))
                minetest.chat_send_player(name, 
                    minetest.colorize("#FFFF00", "This will PERMANENTLY delete ALL of your quest progress!"))
                minetest.chat_send_player(name, 
                    minetest.colorize("#FFFF00", "This action is IRREVERSIBLE and cannot be undone."))
                minetest.chat_send_player(name, "")
                minetest.chat_send_player(name, 
                    "If you are absolutely sure you want to reset your questbook,")
                minetest.chat_send_player(name, 
                    "type: " .. minetest.colorize("#FF8888", "/questbook reset confirm"))
                minetest.chat_send_player(name, "")
                minetest.chat_send_player(name, 
                    minetest.colorize("#888888", "This confirmation will expire in 30 seconds."))
                
                -- Clear confirmation after 30 seconds
                minetest.after(30, function()
                    reset_confirmations[name] = nil
                end)
                
                return true, ""
                
            else
                -- Check if "confirm" was provided
                if args[2] and args[2]:lower() == "confirm" then
                    -- Perform reset
                    reset_confirmations[name] = nil
                    
                    -- Clear all quest progress for player
                    local player_data_path = minetest.get_worldpath() .. "/questbook_players/" .. name .. ".lua"
                    local file = io.open(player_data_path, "w")
                    if file then
                        file:write("-- Questbook player data for " .. name .. " (RESET)\n")
                        file:write("return {}")
                        file:close()
                    end
                    
                    -- Remove from party if in one
                    local party_id = questbook.party.get_player_party(name)
                    if party_id then
                        questbook.party.remove_player(name, name)
                    end
                    
                    minetest.chat_send_player(name, 
                        minetest.colorize("#00FF00", "✓ Questbook reset completed."))
                    minetest.chat_send_player(name, 
                        "All quest progress has been cleared.")
                    minetest.chat_send_player(name, 
                        "You can now start fresh with all quests.")
                    
                    return true, ""
                    
                else
                    return false, "To confirm reset, use: /questbook reset confirm"
                end
            end
            
        else
            return false, "Usage: /questbook reset"
        end
    end
})

-- Clean up expired reset confirmations when player leaves
minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    reset_confirmations[name] = nil
end)

minetest.log("action", "[Questbook] Party commands loaded")