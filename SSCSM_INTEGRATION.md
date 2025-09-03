# SSCSM Integration for Questbook

The Questbook mod supports advanced mouse interactions through [SSCSM (Server-Sent Client-Side Mod)](https://content.luanti.org/packages/luk3yx/sscsm/).

## What is SSCSM?

SSCSM allows servers to send client-side scripts to players, enabling advanced interactions that aren't possible with standard formspecs.

## Enhanced Controls with SSCSM

When SSCSM is installed, players get these advanced controls:

### Mouse Controls
- **Drag Panning**: Click and drag with left mouse button to pan around the quest map
- **Scroll Wheel Zoom**: Use mouse wheel to zoom in/out smoothly
- **Natural Feel**: Intuitive controls similar to modern mapping applications

### Keyboard Controls (Fallback)
- **WASD**: Pan around the quest map when questbook is open
- **+/-**: Zoom in and out

## Installation

### For Players (Client)
1. Install SSCSM from [ContentDB](https://content.luanti.org/packages/luk3yx/sscsm/)
2. Enable client-side scripting in Luanti settings
3. Join a server with Questbook mod that has SSCSM installed

### For Server Owners
1. Install SSCSM mod on your server
2. Install Questbook mod (it will automatically use SSCSM if available)
3. No additional configuration needed

## Fallback Mode

If SSCSM is not available, the questbook will automatically fall back to button-based controls:
- Pan buttons (◀ ▶ ▲ ▼) for navigation
- Zoom buttons (+/-) for zooming
- "Fit All" button to reset view

## Chat Commands (Internal)

These commands are used internally by the SSCSM integration:
- `/questbook_pan <dx> <dy>` - Pan viewport by delta amounts
- `/questbook_zoom <direction> <factor>` - Zoom viewport

## Security

The client-side scripts are automatically sent by the server and run in a sandboxed environment. They only handle mouse/keyboard input for questbook navigation and cannot access other game systems.

## Troubleshooting

### Mouse controls not working?
1. Ensure SSCSM is installed on both client and server
2. Check that client-side scripting is enabled in settings
3. Look for questbook control notifications in chat when opening questbook

### Performance issues?
The SSCSM integration is lightweight and only active when the questbook is open. If you experience issues, you can disable SSCSM and use the fallback button controls.

## Technical Details

- Client script: `sscsm/mouse_controls.lua`
- Server integration: `gui/sscsm_integration.lua` 
- Automatic fallback detection and user notification
- Commands are rate-limited to prevent spam