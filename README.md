# Questbook - Quest & Progression System for Luanti

A comprehensive quest and progression tracking system designed to provide rich storytelling and gameplay mechanics for Luanti servers.

## 🎯 Project Vision

The Questbook mod aims to be the definitive quest system for Luanti, providing both players and server administrators with powerful tools to create engaging quest-driven experiences. The system is designed with modularity and extensibility at its core, allowing other mods to seamlessly integrate and extend functionality.

## 📋 Current Status

**Version:** 0.1.0  
**Status:** Early Development  
**Implemented:** Basic mod initialization only

## 🚀 Core Features (Planned)

### Quest System
- **Quest Types**: Kill, collect, deliver, talk, explore, craft, build, timer-based, custom
- **Multiple Objectives**: Support AND/OR logic for complex quest requirements
- **Quest Chains**: Dependencies and prerequisite systems for connected storylines
- **Quest Status**: Locked, available, active, completed, failed states
- **Player-Specific Progress**: Individual quest states with persistent storage
- **Quest Categories**: Organize quests into chapters, storylines, or themes

### Reward System
- **Item Rewards**: Give items, tools, or blocks upon completion
- **Experience Integration**: Award experience points (if XP mod present)
- **Currency Support**: Money/economic rewards (if economy mod present)
- **Unlock Rewards**: Access to new areas, quests, or abilities
- **Custom Rewards**: Extensible reward system for mod integration

### Quest Givers
- **Interactive Objects**: Signs, books, altars, or custom nodes as quest sources
- **Item-Based**: Quest scrolls or items that initiate quests
- **Automatic**: Location or condition-triggered quest starts

## 🔌 Modding API (Planned)

### Quest Registration
```lua
questbook.register_quest_type("custom_type", {
    name = "Custom Quest Type",
    description = "A custom quest type for special mechanics",
    objectives = {...},
    rewards = {...},
    validators = {...}
})
```

### Event Hooks
- `questbook.on_quest_start(player, quest_id, callback)`
- `questbook.on_quest_complete(player, quest_id, callback)`
- `questbook.on_objective_progress(player, quest_id, objective, progress)`
- `questbook.on_quest_fail(player, quest_id, callback)`

### Progress Tracking
```lua
questbook.update_progress(player, quest_id, objective_id, progress)
questbook.get_progress(player, quest_id)
questbook.complete_objective(player, quest_id, objective_id)
```

### Custom Objectives
```lua
questbook.register_objective_type("mine_specific", {
    validator = function(player, data) ... end,
    progress_tracker = function(player, data) ... end
})
```

## 🎮 User Interface (Planned)

### Quest Book GUI
- **Main Quest Book**: Categorized quest browser with search functionality
- **Quest Details**: Detailed view with objectives, progress, and hints
- **Quest Log**: Active quest tracking and progress indicators
- **Quest Map**: Integration with map mods to show quest locations

### In-Game Management
- **Admin Tools**: In-game quest creation and editing interface
- **Quest Editor**: Visual quest builder for server administrators
- **Import/Export**: Save and share quest data between servers
- **Live Editing**: Modify quests without server restart

## 🛠️ Advanced Features (Planned)

### Conditional Systems
- **State-Based**: Quests that appear based on player inventory, location, or achievements
- **Time-Limited**: Quests with expiration dates or limited availability
- **Repeatable**: Daily, weekly, or custom interval recurring quests
- **Dynamic**: Procedurally generated or randomized quest elements

### Social Features
- **Party Quests**: Shared objectives for multiple players
- **Guild Integration**: Quest systems for groups and communities
- **Leaderboards**: Competitive quest completion tracking
- **Quest Sharing**: Players can recommend quests to others

### Integration Support
- **Achievements**: Automatic achievement unlocks based on quest completion
- **Statistics**: Detailed analytics and progress tracking
- **Chat Integration**: Quest notifications and updates in chat
- **HUD Elements**: Configurable on-screen quest tracking

## 📊 Development Roadmap

### Phase 1 - Core Foundation
- [ ] Basic quest data structure and storage
- [ ] Player progress persistence system
- [ ] Simple quest types (kill, collect, deliver)
- [ ] Basic reward system
- [ ] Quest registration API

### Phase 2 - User Interface
- [ ] Quest book GUI implementation
- [ ] Quest log and active quest tracking
- [ ] Admin command interface

### Phase 3 - Advanced Features
- [ ] Quest chains and dependencies
- [ ] Multiple objective support
- [ ] In-game quest editor
- [ ] Advanced reward types

### Phase 4 - Integration & Polish
- [ ] Full modding API
- [ ] Import/export functionality
- [ ] Localization support
- [ ] Performance optimization

### Phase 5 - Social & Advanced
- [ ] Party quest system
- [ ] Achievement integration
- [ ] Statistics and analytics
- [ ] Advanced conditional systems

## 🤝 Integration Examples

### With Popular Mods
- **Mobs Redo**: Kill specific creatures for bounty quests
- **Technic**: Craft advanced machinery for progression quests
- **Mesecons**: Build redstone-like contraptions for engineering quests
- **Farming**: Grow and harvest crops for agricultural quests
- **Unified Inventory**: Enhanced quest item management

### For Mod Developers
```lua
-- Register a custom quest that integrates with your mod
if minetest.get_modpath("questbook") then
    questbook.register_quest({
        id = "mymod:special_quest",
        title = "Master of MyMod",
        description = "Complete all MyMod challenges",
        objectives = {
            {type = "mymod:use_special_tool", count = 10},
            {type = "mymod:discover_location", location = "special_place"}
        },
        rewards = {
            {type = "item", item = "mymod:ultimate_reward", count = 1}
        }
    })
end
```

## 📝 Configuration

### Server Settings
- Quest persistence method (file/database)
- Maximum active quests per player
- Quest notification settings
- Performance optimization options

### Player Settings  
- Quest book keybind customization
- HUD element positioning
- Notification preferences
- UI theme selection

## 🐛 Known Issues

*None yet - mod in early development*

## 🤝 Contributing

This mod is in active development. Contributions, suggestions, and bug reports are welcome!

### Development Setup
1. Clone the repository to your Luanti mods directory
2. Enable developer mode in the mod configuration
3. Use the debug commands for testing quest functionality

### Coding Standards
- Follow Luanti Lua API conventions
- Document all public API functions
- Include unit tests for new features
- Maintain backward compatibility when possible

## 📄 License

[License TBD]

## 🙏 Credits

- **Author**: Logan
- **Questbook Sprite**: Generated with PixelLabs
- **Inspired by**: Classic RPG quest systems and Luanti community feedback

---

*This README will be updated as development progresses. Check back regularly for the latest information!*