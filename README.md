# Noxius Hub - Roblox Fishing Script

A comprehensive, modular fishing automation script for Roblox with advanced features and GitHub-ready structure.

## Features

- **Fishing Modes**: Legit, Normal Instant, and Blatant/UB modes
- **Auto Features**: Auto sell, auto favorite/unfavorite, auto enchant, auto totem
- **Teleportation**: Predefined locations, player teleport, event auto-teleport
- **Shop Integration**: Auto buy from merchant, weather events, direct purchases
- **Webhook Notifications**: Discord integration with customizable filters
- **Configuration**: Save/load settings, multiple config profiles
- **Utilities**: Freeze player, no-clip, fly mode, walk on water, FPS boost
- **Tools**: Backpack scanner, radar, oxygen tank, animation/cutscene removers

## Project Structure

```
NoxiusHub/
├── main.lua                    # Entry point (loads WindUI and UI modules)
├── src/
│   ├── init.lua                # WindUI loader and remotes cache
│   ├── main.lua                # UI initialization and tab loading
│   ├── api/
│   │   ├── remotes.lua         # Remote function getters and caching
│   │   ├── utils.lua           # Common utilities (SafeCall, FormatNumber, etc.)
│   │   ├── players.lua         # Player/character utilities
│   │   ├── fishing.lua         # Core fishing logic (UB, normal, blatant)
│   │   ├── teleport.lua        # Teleportation functions & location data
│   │   ├── config.lua          # Configuration management (save/load)
│   │   ├── shop.lua            # Shop/merchant functions
│   │   ├── events.lua          # Event tracking (Lochness, etc.)
│   │   ├── inventory.lua       # Inventory scanning & management
│   │   └── webhook.lua         # Discord webhook handling
│   └── ui/
│       ├── main.lua            # WindUI window setup
│       ├── player_tab.lua      # Player tab UI
│       ├── fishing_tab.lua     # Fishing tab UI
│       ├── auto_tab.lua        # Automatic tab UI
│       ├── teleport_tab.lua    # Teleport tab UI
│       ├── shop_tab.lua        # Shop tab UI
│       ├── events_tab.lua      # Events tab UI
│       ├── tools_tab.lua       # Tools tab UI
│       ├── webhook_tab.lua     # Webhook tab UI
│       └── config_tab.lua      # Configuration tab UI
├── README.md
├── .gitignore
└── LICENSE
```

## Installation

1. Download or clone this repository
2. Use a compatible Roblox executor that supports Lua
3. Load and execute `main.lua` in your Roblox client

## Usage

### Tabs Overview

- **Player**: Movement controls, abilities (infinite jump, noclip, fly), ESP, name hiding
- **Fishing**: All fishing modes with customizable delays
- **Automatic**: Auto sell, auto favorite/unfavorite, auto enchant, stone creation
- **Teleport**: Location presets, player TP, event auto-TP
- **Shop**: Purchase rods/bait/boats, merchant auto-buy, weather purchase
- **Events**: Ancient Lochness event tracker with auto-join
- **Tools**: Backpack scanner, radar, oxygen tank, animation/cutscene removers
- **Webhook**: Discord integration with filters
- **Configuration**: Save/load/delete configs

### Configuration

The script supports saving and loading configurations:
1. Adjust settings in the UI
2. Enter a config name in the Configuration tab
3. Click "Save Config"
4. Load later using "Load Config"

Configs are stored in `ftgshub_configs/` folder as JSON files.

## Requirements

- Roblox game with fishing mechanics
- WindUI framework (loaded automatically)
- Compatible executor

## Safety Features

- Anti-idle protection
- Safe remote calling with error handling
- Visual feedback for all actions
- Toggle-able features

## Credits

- WindUI framework by Footagesus
- Noxius Community

## Disclaimer

Use at your own risk. Not affiliated with Roblox Corporation. This script is for educational purposes.

## License

MIT License - Feel free to modify and distribute.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

Please follow the existing code structure and maintain separation between API and UI modules.