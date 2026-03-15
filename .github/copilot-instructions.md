# Pokémon FireRed/LeafGreen Legacy - Copilot Instructions

This is a **Game Boy Advance decompilation project** for Pokémon FireRed and LeafGreen, featuring quality-of-life improvements and gameplay enhancements.

## Build System

### Quick Start
- **Build FireRed**: `make firered`
- **Build LeafGreen**: `make leafgreen`
- **Build with modern GCC**: `make firered_modern` or `make leafgreen_modern`
- **Compare against original ROM** (legacy compiler only): `make compare_firered` or `make compare_leafgreen`
- **Clean build artifacts**: `make clean`

### Build Configuration
Edit `config.mk` to change:
- `GAME_VERSION`: `FIRERED` or `LEAFGREEN` (default: FIRERED)
- `GAME_REVISION`: `0` or `1` (default: 0, affects build name)
- `MODERN`: `0` (legacy agbcc compiler) or `1` (modern GCC, faster compilation)
- `COMPARE`: `1` to verify ROM matches original checksums (legacy only)

### Prerequisites
See `INSTALL.md` for detailed setup. Requires:
- ARM cross-compiler toolchain (`arm-none-eabi-*`)
- Python 3 (for build scripts)
- Make
- On Windows: WSL1, msys2, or Cygwin

## Repository Architecture

### Directory Structure
- **`src/`** - C source code (decompiled and new code)
  - `src/data/` - Game data: Pokémon stats, movesets, trainer teams, items, ingame trades
  - Battle engine, UI, field logic, event handling
- **`asm/`** - ARM assembly routines (critical timing-sensitive or undecompiled sections)
- **`data/`** - Map layouts, scripts, sprites in binary form
  - `data/maps/` - ~400 map definitions (JSON + binary)
  - `data/layouts/` - Tileset and collision data
- **`include/`** - C header files
- **`tools/`** - Build tools: compilers (agbcc), Porymap utilities, poryscript

### Build Rules
Modular `.mk` files handle asset compilation:
- `json_data_rules.mk` - Compiles JSON data to binary (Pokémon, trainers, items)
- `map_data_rules.mk` - Processes map data and event scripts
- `graphics_file_rules.mk` - Compiles graphics/sprites
- `spritesheet_rules.mk` - Handles sprite sheets
- `tileset_rules.mk` - Processes tileset data
- `audio_rules.mk` - Processes music/sound

## Key Conventions

### Pokémon/Trainer Data
All game balance data lives in `src/data/`:
- **Movesets & stats**: Modified for QoL improvements and type balance (see README for Ghost/Dark swap)
- **Trainer teams**: Enhanced with better Pokémon choices, evolution, and move coverage
- **Items & locations**: Adjusted for better availability and progression
- **Trade evolutions**: Changed to level-up or item-based instead of requiring link cable

**Structure**: Data is organized as structured C code with macros (e.g., `BULBASAUR: { .hp = 45, .attack = 49, ... }`). To modify game data, edit these files directly.

### Game Versions
Two versions with minor differences:
- **FireRed vs LeafGreen** - Handled via `GAME_VERSION` define
- **Revision 0 vs 1** - Affects build filename and some constants
- Build as `FIRERED` by default; switch via `make leafgreen`
- Version-specific code uses `#ifdef FIRERED` / `#ifdef LEAFGREEN` guards

### Assembly vs C Code
- **C code** (`src/`): Game logic, AI, UI, events
- **Assembly** (`asm/`): Performance-critical sections (battle animations, decompression)
- Most new features are added in C; ASM is rarely needed unless dealing with tight loops or specific hardware timing

### Game Balance Features (from README)
- **Difficulty modes**: Normal (classic), Hard (level caps + set mode), Hardcore (permadeath)
- **Type changes**: Dark is Physical, Ghost is Special
- **Evolution changes**: Trade evos evolve by level OR item
- **Postgame content**: Gym rematches, roaming Pokémon system, Sevii Islands expansion
- **QoL additions**: Faster Nurse Joy, bag sorting, EV/IV checkers, repeatable items, running indoors

## Important Files to Know

### Game Data
- `src/data/pokemon/` - Stats, movesets, abilities
- `src/data/items.json.txt` - Item definitions
- `src/data/trainers/` - Trainer AI and teams
- `src/data/ingame_trades.h` - NPC trades

### Engine/Mechanics
- `src/battle*.c` - Battle engine, animations, AI scripts
- `src/event_data.c` - Story events and scripting
- `src/map_*.c` - Map event handlers
- `src/pokemon*.c` - Pokémon data and calculations

### Builds/Configuration
- `config.mk` - Compiler and version settings
- `Makefile` - Main build orchestration
- `ld_script.ld` - Memory layout (legacy)
- `ld_script_modern.ld` - Memory layout (modern GCC)

## Common Tasks

### Building the ROM
```bash
# Standard FireRed with legacy compiler
make firered

# LeafGreen with modern GCC (faster)
make leafgreen_modern

# Verify it matches the original (legacy compiler only)
make compare_firered
```

### Adding/Editing Pokémon Data
1. Locate Pokémon in `src/data/pokemon/stats.h` (stats), `src/data/pokemon/learnsets.h` (moves), etc.
2. Modify the entry directly
3. Run `make firered` to rebuild
4. Use `make clean` if you hit link errors

### Editing Maps or Events
1. Use **Porymap** (in `tools/` directory) for visual map editing (recommended)
2. Or edit `data/maps/*/map.json` directly for lower-level changes
3. Run `make firered` to compile

### Working with Game Scripts
Event scripts are written in **poryscript** (high-level script language compiled to battle/event bytecode). Most are in:
- `data/event_scripts.s` (main story events)
- `data/maps/*/*.inc` (map-specific scripts)

## Architecture Notes

### Decompilation Status
This repo is a **partial decompilation**: some code is original C (newly written), some is decompiled from the original GBA binary. The COMPARE build verifies that decompiled sections produce bitwise-identical output.

### Naming Conventions
- Game objects use Game Freak's original names (e.g., `sPlayerParty`, `gBattleResults`)
- New code follows C conventions (snake_case for functions/variables)
- Data structures match original Game Freak headers where decompiled

### Version Control
- Two ROMs are supported (FireRed + LeafGreen revision 0 and 1)
- SHA1 checksums in `firered.sha1`, `leafgreen.sha1`, etc. verify ROM validity before patching
- Build artifacts go to `build/` directory (ignored by git)

## Debugging

### Build Failures
1. Check that `arm-none-eabi-*` toolchain is in PATH: `which arm-none-eabi-gcc`
2. Try `make clean` then rebuild
3. For modern GCC issues, try legacy: `make MODERN=0 firered`
4. See INSTALL.md for platform-specific setup

### ROM Issues
1. Verify source ROM matches SHA1: `sha1sum pokefirered.gba`
2. Expected: `41cb23d8dccc8ebd7c649cd8fbb58eeace6e2fdc` (FireRed) or `574fa542ffebb14be69902d1d36f1ec0a4afd71e` (LeafGreen)
