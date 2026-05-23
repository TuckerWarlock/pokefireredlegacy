#!/bin/bash
# OCI Container build helper for pokefireredlegacy
# Builds ROM inside x86-64 container with pre-compiled tools included
# Works with: Apple container, Podman, Docker Desktop
# Usage: ./container-build.sh [firered|leafgreen] [modern|legacy]

set -e

# Detect container runtime (prefer Docker for x86-64 support)
if command -v docker &> /dev/null; then
    CONTAINER_CMD="docker"
    RUNTIME_NAME="Docker Desktop"
    BUILD_CMD="docker build"
    IS_APPLE_CONTAINER=false
elif command -v podman &> /dev/null; then
    CONTAINER_CMD="podman"
    RUNTIME_NAME="Podman"
    BUILD_CMD="podman build"
    IS_APPLE_CONTAINER=false
elif command -v container &> /dev/null; then
    CONTAINER_CMD="container"
    RUNTIME_NAME="Apple container"
    BUILD_CMD="container build --platform linux/amd64"
    IS_APPLE_CONTAINER=true
else
    echo "Error: No container runtime found"
    echo "Install one of:"
    echo "  • Docker Desktop for Mac"
    echo "  • Podman"
    echo "  • Apple container (native on macOS 26)"
    exit 1
fi

GAME="${1:-firered}"
COMPILER="${2:-modern}"
REPO_PATH="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="${REPO_PATH}/rom_output"

# Validate arguments
if [[ "$GAME" != "firered" && "$GAME" != "leafgreen" ]]; then
    echo "Error: Game must be 'firered' or 'leafgreen'"
    exit 1
fi

if [[ "$COMPILER" != "modern" && "$COMPILER" != "legacy" ]]; then
    echo "Error: Compiler must be 'modern' or 'legacy'"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR"/poke*.gba

echo "========================================="
echo "Pokémon FireRed/LeafGreen Legacy"
echo "Container Build System"
echo "========================================="
echo ""
echo "Container runtime: $RUNTIME_NAME"
echo "Building: $(tr '[:lower:]' '[:upper:]' <<< "$GAME") ($(tr '[:lower:]' '[:upper:]' <<< "$COMPILER") GCC)"
echo ""

# Determine make target and container name
if [[ "$GAME" == "leafgreen" && "$COMPILER" == "modern" ]]; then
    MAKE_TARGET="leafgreen_modern"
    CONTAINER_NAME="pokefirered-builder-leafgreen-modern"
elif [[ "$GAME" == "leafgreen" ]]; then
    MAKE_TARGET="leafgreen"
    CONTAINER_NAME="pokefirered-builder-leafgreen-legacy"
elif [[ "$COMPILER" == "modern" ]]; then
    MAKE_TARGET="firered_modern"
    CONTAINER_NAME="pokefirered-builder-firered-modern"
else
    MAKE_TARGET="firered"
    CONTAINER_NAME="pokefirered-builder-firered-legacy"
fi

if [[ "$COMPILER" == "modern" ]]; then
    ROM_FILE="pokere${GAME}_modern.gba"
else
    ROM_FILE="pokere${GAME}.gba"
fi

# Build container image with x86-64 platform
echo "[1/3] Building x86-64 container image..."
echo "      (First build may take a few minutes)"
$BUILD_CMD -t pokefirered-builder:latest "$REPO_PATH" > /dev/null 2>&1
echo "✓ Container image built for x86-64"
echo ""

# Run build inside container
echo "[2/3] Building ROM inside x86-64 container..."
echo ""

# Build command that runs inside container
BUILD_INSIDE_CMD="cd /workspace && make clean && make $MAKE_TARGET && cp /workspace/$ROM_FILE /output/"

# Run the container
if [[ "$IS_APPLE_CONTAINER" == "true" ]]; then
    # Apple container: use create/start with named container
    CONTAINER_ID=$($CONTAINER_CMD create \
        --name "$CONTAINER_NAME" \
        -v "$OUTPUT_DIR:/output" \
        pokefirered-builder:latest \
        bash -c "$BUILD_INSIDE_CMD")
    
    $CONTAINER_CMD start -a "$CONTAINER_ID" 2>&1 | tail -100
    $CONTAINER_CMD rm "$CONTAINER_ID" 2>/dev/null || true
else
    # Docker/Podman: use standard run with named container
    $CONTAINER_CMD run --rm --name "$CONTAINER_NAME" \
        -v "$OUTPUT_DIR:/output" \
        pokefirered-builder:latest \
        bash -c "$BUILD_INSIDE_CMD"
fi

echo ""
echo "[3/3] Checking build results..."

# Check if ROM was built
if [[ -f "$OUTPUT_DIR/$ROM_FILE" ]]; then
    ROM_PATH="$OUTPUT_DIR/$ROM_FILE"
    ROM_SIZE=$(du -h "$ROM_PATH" | cut -f1)
    
    echo "✓ ROM built: $ROM_FILE"
    echo "✓ Size: $ROM_SIZE"
    echo "✓ Location: $OUTPUT_DIR/"
    
    echo ""
    echo "========================================="
    echo "✓ Build Complete!"
    echo "========================================="
    echo ""
    echo "ROM ready at: $ROM_PATH"
else
    echo "✗ ROM file not found in output directory"
    echo ""
    echo "⚠ If you see 'Exec format error' above, Docker Desktop may not be"
    echo "  running properly. Check the Docker menu bar icon."
    echo ""
    exit 1
fi
