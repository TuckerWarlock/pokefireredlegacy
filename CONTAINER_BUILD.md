# Container Build Setup

This directory includes a Docker/container build wrapper for pokefireredlegacy on macOS.

## Why Container Build?

The pokefireredlegacy project includes **pre-compiled x86-64 Linux tools only** (poryscript). Your M4 Mac can't run these natively. The container approach:

1. Creates an x86-64 Linux container
2. Copies the repo with all pre-compiled tools into the container
3. Builds the ROM inside the x86-64 environment
4. Extracts the built ROM to your Mac

## Requirements

**You need Docker Desktop for Mac** (unfortunately):
- Download: https://www.docker.com/products/docker-desktop
- Why Docker Desktop and not Apple container?
  - Apple's native container runtime only supports arm64 (no x86-64 emulation)
  - Docker Desktop uses Rosetta 2 to emulate x86-64
  - pokefireredlegacy's tools are x86-64-only
  
(If you'd prefer not to install Docker, try the official [pret/pokefirered](https://github.com/pret/pokefirered) instead)

## Quick Start

### One-time setup

1. Install Docker Desktop for Mac
2. Start the Docker Desktop app (menu bar icon)

### Build the ROM

```bash
# Build Pokémon FireRed (modern GCC)
./container-build.sh firered modern

# Build Pokémon LeafGreen (modern GCC)
./container-build.sh leafgreen modern

# Build with legacy compiler (if supported)
./container-build.sh firered legacy
```

The script will:
1. Build the container image (one-time, ~2-5 min)
2. Copy your repo into the container
3. Run the build inside x86-64 environment (~5-15 min)
4. Extract the `.gba` ROM file to `./rom_output/`

## Output

Built ROMs are saved to `./rom_output/`:

```
rom_output/
├── pokemon_firered.gba
└── pokemon_leafgreen.gba
```

## How It Works

```
Your Mac (arm64)
        ↓
Docker Desktop (Rosetta 2 x86-64 emulation)
        ↓
x86-64 Ubuntu Linux container
        ↓
Pre-compiled poryscript + ARM toolchain
        ↓
pokefirered.gba ← extracted to ./rom_output/
```

## Troubleshooting

### Docker Desktop not running

```bash
# Open Docker Desktop app from /Applications/Docker.app
# Or start from CLI:
open /Applications/Docker.app
```

### Build fails with "Exec format error"

This means the container runtime doesn't support x86-64. Make sure:
1. Docker Desktop is actually running (check menu bar)
2. You don't have Apple container set as default

### Slow build

- First build is slower (compiling dependencies)
- Rosetta 2 emulation is slower than native builds
- Subsequent builds are cached and faster

### Out of disk space

The build uses ~10GB. Free up space and try again.

## Advanced: Manual container commands

```bash
# Start an interactive shell inside the container
docker run --rm -it -v $(pwd):/workspace pokefirered-builder:latest bash

# Inside the container, run commands:
cd /workspace
make clean
make firered_modern
ls -lh build/firered_modern/pokemon_firered.gba
```

---

For more information, see `MACOS_QUICKSTART.md` or run `make help`.
