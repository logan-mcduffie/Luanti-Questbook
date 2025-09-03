-- Client-side mouse controls for questbook
-- Handles drag panning and scroll wheel zooming using SSCSM

local mouse_state = {
    dragging = false,
    last_x = 0,
    last_y = 0,
    drag_start_x = 0,
    drag_start_y = 0
}

-- Check if questbook formspec is currently open
local function is_questbook_open()
    -- Check if current formspec is questbook
    local formspec = minetest.get_formspec()
    return formspec and formspec:find("questbook") ~= nil
end

-- Send pan command to server
local function send_pan_command(dx, dy)
    if math.abs(dx) > 2 or math.abs(dy) > 2 then -- Only send if movement is significant
        minetest.send_chat_message("/questbook_pan " .. dx .. " " .. dy)
    end
end

-- Send zoom command to server  
local function send_zoom_command(direction, factor)
    minetest.send_chat_message("/questbook_zoom " .. direction .. " " .. (factor or 0.1))
end

-- Handle mouse button events
local function on_mouse_button(button, pressed, x, y)
    if not is_questbook_open() then return end
    
    if button == 1 then -- Left mouse button
        if pressed then
            -- Start dragging
            mouse_state.dragging = true
            mouse_state.last_x = x
            mouse_state.last_y = y
            mouse_state.drag_start_x = x
            mouse_state.drag_start_y = y
        else
            -- Stop dragging
            mouse_state.dragging = false
        end
    end
end

-- Handle mouse movement
local function on_mouse_move(x, y)
    if not is_questbook_open() or not mouse_state.dragging then return end
    
    local dx = x - mouse_state.last_x
    local dy = y - mouse_state.last_y
    
    -- Convert screen movement to world movement (invert for natural panning)
    send_pan_command(-dx, -dy)
    
    mouse_state.last_x = x
    mouse_state.last_y = y
end

-- Handle mouse wheel events
local function on_mouse_wheel(direction)
    if not is_questbook_open() then return end
    
    if direction > 0 then
        send_zoom_command("in", 0.1)
    elseif direction < 0 then
        send_zoom_command("out", 0.1) 
    end
end

-- Register mouse event handlers if available
if minetest.register_on_mouse_button then
    minetest.register_on_mouse_button(on_mouse_button)
end

if minetest.register_on_mouse_move then
    minetest.register_on_mouse_move(on_mouse_move)
end

if minetest.register_on_mouse_wheel then
    minetest.register_on_mouse_wheel(on_mouse_wheel)
end

-- Alternative approach using keyboard shortcuts as fallback
local function on_keypress(key)
    if not is_questbook_open() then return end
    
    -- WASD panning when questbook is open
    if key == "KEY_W" then
        send_pan_command(0, -50)
    elseif key == "KEY_S" then
        send_pan_command(0, 50)
    elseif key == "KEY_A" then
        send_pan_command(-50, 0)
    elseif key == "KEY_D" then
        send_pan_command(50, 0)
    elseif key == "KEY_EQUALS" or key == "KEY_PLUS" then -- + key
        send_zoom_command("in", 0.1)
    elseif key == "KEY_MINUS" then -- - key
        send_zoom_command("out", 0.1)
    end
end

if minetest.register_on_keypress then
    minetest.register_on_keypress(on_keypress)
end

minetest.log("action", "[Questbook] Client-side mouse controls loaded")