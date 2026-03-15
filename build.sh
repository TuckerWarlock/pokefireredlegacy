#!/bin/bash
# Pokémon FireRed/LeafGreen Legacy - macOS Build Wrapper
# Simplifies building the ROM with proper environment setup

set -e

# Color codes
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure ARM toolchain is in PATH on Apple Silicon
if [[ $(arch) == "arm64" ]]; then
    ARM_TOOLCHAIN_PATH="/Applications/ArmGNUToolchain/15.2.rel1/arm-none-eabi/bin"
    if [[ -d "$ARM_TOOLCHAIN_PATH" ]] && [[ ":$PATH:" != *":$ARM_TOOLCHAIN_PATH:"* ]]; then
        export PATH="$ARM_TOOLCHAIN_PATH:$PATH"
    fi
fi

# Verify ARM compiler is accessible
if ! command -v arm-none-eabi-gcc &> /dev/null; then
    echo -e "${YELLOW}arm-none-eabi-gcc not found${NC}"
    echo "Please run ./setup-macos.sh first to install the ARM toolchain"
    exit 1
fi

# Parse arguments
VERSION="FIRERED"
MODIFIER=""
BUILD_MODERN=0

while [[ $# -gt 0 ]]; do
    case $1 in
        firered)
            VERSION="FIRERED"
            shift
            ;;
        leafgreen)
            VERSION="LEAFGREEN"
            shift
            ;;
        modern)
            BUILD_MODERN=1
            shift
            ;;
        clean)
            MODIFIER="clean"
            shift
            ;;
        compare)
            MODIFIER="compare"
            shift
            ;;
        -h|--help)
            echo "Usage: $(basename "$0") [VERSION] [OPTIONS]"
            echo ""
            echo "VERSION (optional):"
            echo "  firered     Build Pokémon FireRed (default)"
            echo "  leafgreen   Build Pokémon LeafGreen"
            echo ""
            echo "OPTIONS:"
            echo "  modern      Use modern GCC compiler (faster)"
            echo "  clean       Clean build artifacts before building"
            echo "  compare     Verify ROM against original checksums (legacy compiler only)"
            echo ""
            echo "Examples:"
            echo "  $(basename "$0") firered                    # Build FireRed with legacy compiler"
            echo "  $(basename "$0") leafgreen modern           # Build LeafGreen with modern GCC"
            echo "  $(basename "$0") clean firered modern       # Clean and build FireRed with modern GCC"
            exit 0
            ;;
        *)
            echo -e "${YELLOW}Unknown option: $1${NC}"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Build the command
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Pokémon FireRed/LeafGreen Legacy Builder${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

BUILD_CMD="make"

if [[ -n "$MODIFIER" ]]; then
    BUILD_CMD="$BUILD_CMD $MODIFIER"
fi

if [[ $BUILD_MODERN -eq 1 ]]; then
    BUILD_CMD="$BUILD_CMD GAME_VERSION=$VERSION MODERN=1"
    echo -e "${GREEN}Building: Pokémon $VERSION (Modern GCC)${NC}"
else
    BUILD_CMD="$BUILD_CMD GAME_VERSION=$VERSION"
    echo -e "${GREEN}Building: Pokémon $VERSION (Legacy Compiler)${NC}"
fi

if [[ -n "$MODIFIER" ]]; then
    echo -e "${GREEN}Mode: $MODIFIER${NC}"
fi

echo ""

# Execute build
cd "$SCRIPT_DIR"
eval "$BUILD_CMD"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Build Complete!${NC}"
echo -e "${GREEN}========================================${NC}"

# Find and display the ROM path
ROM_NAME="pokere${VERSION,,}_modern.gba"
if [[ $BUILD_MODERN -eq 0 ]]; then
    ROM_NAME="pokere${VERSION,,}.gba"
fi

ROM_PATH="$SCRIPT_DIR/build/$(echo ${VERSION,,})/$(echo $ROM_NAME)"

if [[ -f "$ROM_PATH" ]]; then
    echo ""
    echo -e "${BLUE}ROM Location:${NC}"
    echo "  $ROM_PATH"
    echo ""
    echo "You can now play the ROM with a GBA emulator!"
fi
