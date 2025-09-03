-- Simple SSCSM test script
-- Just tests if client-side script loading works

-- Test if we're in client-side environment
if not minetest.send_chat_message then
    -- We're not on the client side, this shouldn't run
    return
end

-- Global click counter
local click_count = 0

-- Simple function to test SSCSM is working
local function test_sscsm()
    click_count = click_count + 1
    minetest.send_chat_message("[SSCSM Test] Client script is working! Click count: " .. click_count)
end

-- Register a simple chat command to test
minetest.register_chatcommand("sscsm_test", {
    params = "",
    description = "Test SSCSM functionality",
    func = function()
        test_sscsm()
        return true, "SSCSM test executed"
    end,
})

-- Try to register mouse click handler if available
if minetest.register_on_mouse_button then
    minetest.register_on_mouse_button(function(button, pressed, x, y)
        if pressed and button == 1 then -- Left click when pressed
            minetest.send_chat_message("[SSCSM] Mouse click detected at " .. x .. "," .. y)
        end
    end)
end

-- Fallback: Register a global step that sends a message once
local initial_message_sent = false
minetest.register_globalstep(function(dtime)
    if not initial_message_sent then
        initial_message_sent = true
        minetest.send_chat_message("[SSCSM] Client-side script loaded successfully!")
    end
end)

-- Log that the script loaded
minetest.log("action", "[Questbook SSCSM Test] Simple test script loaded on client")