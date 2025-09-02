# Questbook GUI System Documentation

## Overview
The Questbook GUI uses an enhanced formspec-based tile system that provides visual quest trees with dependency connections, customizable positioning, and chapter-based organization.

## Architecture

### Core Components
- **Canvas Renderer** (`gui/canvas.lua`) - Core formspec rendering engine
- **Tile System** (`gui/tiles.lua`) - Quest tile rendering and management
- **Viewport** (`gui/viewport.lua`) - Pan/zoom and coordinate management  
- **Dependencies** (`gui/connections.lua`) - Automatic line drawing between quests
- **Chapters** (`gui/chapters.lua`) - Chapter-based page organization
- **Interactions** (`gui/interactions.lua`) - Click handling and quest actions

### Data Structure
```lua
quest.layout = {
    chapter = "main",           -- Chapter/page this quest belongs to
    position = {x = 100, y = 50}, -- World coordinates (pixels)
    size = "medium",            -- "small", "medium", "large"
    icon = {                    -- Icon configuration
        type = "item",          -- "item", "image", or "default"
        source = "default:dirt", -- Item name or image path
        count = 64              -- Item count display (items only)
    },
    color = "#4CAF50",          -- Optional custom color
    hidden = false              -- Hide from visual display
}
```

### Tile Sizes
- **Small** (64x48px): Side quests, optional content
- **Medium** (96x72px): Main progression quests  
- **Large** (128x96px): Major milestones, chapter endings

## Coordinate System

### World Coordinates
- Origin (0,0) at top-left of each chapter
- Positive X = right, Positive Y = down
- Units in pixels for precise positioning
- No grid restrictions - free positioning

### Screen Coordinates  
- Transformed from world coordinates via viewport
- Accounts for pan offset and zoom level
- Clipped to visible formspec area

### Viewport Management
```lua
viewport = {
    offset = {x = 0, y = 0},    -- Pan offset
    zoom = 1.0,                 -- Zoom level (0.5 - 3.0)
    bounds = {w = 800, h = 600} -- Screen dimensions
}
```

## Rendering Pipeline

### Layer System (bottom to top)
1. **Background** - Chapter background, grid (optional)
2. **Connections** - Dependency lines between quests
3. **Tiles** - Quest tiles with status indicators
4. **UI Elements** - Navigation controls, buttons
5. **Overlays** - Quest details, tooltips, menus

### Rendering Process
1. Calculate visible area from viewport
2. Filter quests to only those in visible bounds
3. Generate dependency lines between visible quests
4. Render each layer in sequence
5. Build final formspec string

## Quest Dependencies

### Connection Types
- **Prerequisite** (solid line): Must complete before unlocking
- **Recommended** (dashed line): Suggested order, not required
- **Related** (dotted line): Thematically connected

### Line Routing
- Automatic pathfinding around obstacles
- Smart connection points on tile edges
- Arrow indicators show quest flow direction
- Color coding for connection types

## Chapter System

### Chapter Organization
- Each quest category becomes a separate chapter/page
- Independent coordinate spaces per chapter
- Chapter switching via tabs or dropdown
- Chapter-specific viewport settings

### Chapter Structure
```lua
chapters = {
    ["tutorial"] = {
        name = "Getting Started",
        description = "Basic game mechanics",
        background = "tutorial_bg.png",
        icon = {                    -- Chapter icon
            type = "item",          -- "item", "image", or "default"  
            source = "default:book", -- Item name or image path
            count = 1               -- Item count (items only)
        },
        quests = {...}
    }
}
```

## User Interactions

### Navigation
- **Pan**: Arrow keys, click-drag empty space
- **Zoom**: Mouse wheel, +/- keys, zoom buttons
- **Center**: Double-click quest, "fit view" button
- **Chapters**: Tab navigation, dropdown menu

### Quest Interactions  
- **Select**: Click tile to show details
- **Action**: Click action buttons (Submit, Complete, etc.)
- **Context**: Right-click for context menu
- **Details**: Hover for tooltip, click for full panel

## Admin Tools

### Quest Positioning
- Admin mode toggle for edit capabilities
- Drag-and-drop quest repositioning
- Grid snap and alignment helpers
- Bulk selection and movement
- Undo/redo for layout changes

### Layout Management
```lua
-- Set quest position
questbook.gui.set_quest_position(quest_id, x, y, size)

-- Auto-arrange chapter
questbook.gui.auto_arrange_chapter(chapter_name, algorithm)

-- Export/import layout
questbook.gui.export_layout(chapter_name)
questbook.gui.import_layout(layout_data)
```

## Performance Optimization

### Culling
- Only render quests within viewport bounds
- Skip connection calculations for off-screen quests
- Lazy load quest details and graphics

### Caching
- Cache rendered tile graphics
- Reuse connection path calculations
- Cache formspec strings for static elements

### Limits
- Maximum quests per viewport: 50-100
- Connection line complexity limits
- Zoom level restrictions to prevent performance issues

## File Structure
```
gui/
├── README.md              # This documentation
├── canvas.lua            # Core rendering engine
├── tiles.lua             # Tile rendering and management
├── viewport.lua          # Coordinate transformation and navigation
├── connections.lua       # Dependency line drawing
├── chapters.lua          # Chapter organization and switching  
├── interactions.lua      # User input and quest interactions
├── admin.lua             # Quest positioning and layout tools
├── formspec.lua          # Legacy system (to be replaced)
├── handlers.lua          # Legacy handlers (to be updated)
└── keybind.lua           # Keyboard shortcuts and commands
```

## Migration Notes

### From Legacy System
- Old list-based GUI will be replaced gradually
- Quest data structure extended with layout fields
- Existing quests get auto-positioned initially
- Admin tools provided to customize positioning

### Backward Compatibility
- Old save files continue to work
- Missing layout data gets default values
- Graceful fallback to list view if needed

## Development Guidelines

### Adding New Features
1. Follow the layered rendering approach
2. Use world coordinates for positioning
3. Implement proper viewport clipping
4. Cache expensive calculations
5. Test with large quest trees (100+ quests)

### Performance Considerations
- Minimize formspec string length
- Batch rendering operations
- Use culling for off-screen elements
- Profile with `/debug` commands

### Visual Consistency
- Follow established tile size standards
- Use consistent color schemes
- Maintain proper spacing and alignment
- Test across different screen resolutions

## Icon System

### Icon Types
- **Item Icons**: Use in-game items/blocks as quest/chapter icons
  - Displays item with optional count overlay
  - Uses Luanti's built-in item rendering
  - Automatically scales to tile size
  
- **Image Icons**: Custom PNG/texture files
  - Stored in mod textures directory
  - Full control over visual design
  - Supports transparency and custom graphics
  
- **Default Icons**: Fallback system-generated icons
  - Based on quest type or category
  - Consistent visual style
  - Generated procedurally

### Icon Implementation
```lua
-- Item icon example
quest.layout.icon = {
    type = "item",
    source = "default:diamond_pickaxe", 
    count = 3  -- Shows "3" overlay
}

-- Image icon example  
quest.layout.icon = {
    type = "image",
    source = "questbook_custom_icon.png"
}

-- Default/auto icon
quest.layout.icon = {type = "default"}
-- or simply: quest.layout.icon = nil
```

## Future Enhancements

### Planned Features
- Animated progress indicators
- Sound effects for interactions
- Theme/skin system
- Export to image functionality
- Item icon tooltips with item descriptions

### Technical Improvements
- Sub-pixel positioning accuracy
- Smooth pan/zoom animations
- Multi-touch gesture support
- Accessibility improvements
- Mobile-responsive layouts