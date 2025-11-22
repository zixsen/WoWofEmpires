# WoWofEmpires

A World of Warcraft addon that adds Age of Empires inspired sound effects and quality-of-life features.

## Features

- **Soundboard**: Play Age of Empires sounds via chat commands
- **Auto Vendor**: Automatically sell grey items when visiting a vendor
- **Auto Repair**: Automatically repair items when visiting a vendor
- **Auto Invite**: Automatically accept party invites from friends
- **Bag Space**: Display remaining bag space on your backpack
- **Custom Portraits**: Scroll through custom portrait atlases for your character and party members
- **Spy Integration**: Sync KoS (Kill on Sight) lists with guild members

## Structure

The addon is organized into modular files for better maintainability:

- **config.lua**: Sound mappings and configuration data
- **utils.lua**: Helper functions used across the addon
- **sounds.lua**: Sound playing and TTS functionality
- **chat.lua**: Chat message processing for sound triggers
- **events.lua**: Event handlers for combat, party, and game events
- **merchant.lua**: Vendor and repair automation
- **core.lua**: Main initialization and UI creation
- **Portrait/Main.lua**: Custom portrait functionality
- **Portrait/Main.xml**: Portrait frame definitions

## Usage

### Soundboard
Type numbers or keywords in any chat channel (say, party, guild, etc.) to play sounds:
- Numbers 1-105 trigger specific Age of Empires sounds
- Keywords like "wow", "bruh", "snoop", etc. trigger custom sounds

### TTS (Text-to-Speech)
Type `tts:<message>` in chat to have text spoken aloud

### Commands
- Right-click the minimap button to stop the last 5 sounds
- Left-click the minimap button to open the main interface

### QoL Features
Enable/disable features in the QoL tab:
- Auto vendor grey items
- Auto repair at vendors
- Auto-accept party invites from friends
- Show bag space on backpack icon

## Installation

1. Download or clone this repository
2. Place the WoWofEmpires folder in your `World of Warcraft/_classic_/Interface/AddOns/` directory
3. Restart World of Warcraft or reload UI with `/reload`

## Development

### Recent Refactoring (Nov 2024)
The addon was recently refactored to improve maintainability:
- Split monolithic 1136-line core.lua into 7 modular files
- Reduced code duplication in Portrait module by using factory functions
- Removed all commented-out dead code
- Standardized namespace organization under WoWofEmpires table
- Consistent formatting and naming conventions
- Added comprehensive documentation

### Code Organization
All code is organized under the `WoWofEmpires` namespace to avoid polluting the global environment. Each module is self-contained with clear responsibilities. The load order in WoWofEmpires.toc ensures dependencies are loaded correctly.
