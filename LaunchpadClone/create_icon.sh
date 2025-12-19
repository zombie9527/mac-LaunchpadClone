#!/bin/bash

# Check if input file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <input_png>"
    exit 1
fi

INPUT_PNG="$1"
ICONSET_DIR="AppIcon.iconset"

# Create iconset directory
mkdir -p "$ICONSET_DIR"

# Generate various sizes
echo "🎨 Generating icon sizes..."
sips -s format png -z 16 16     "$INPUT_PNG" --out "$ICONSET_DIR/icon_16x16.png"
sips -s format png -z 32 32     "$INPUT_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png"
sips -s format png -z 32 32     "$INPUT_PNG" --out "$ICONSET_DIR/icon_32x32.png"
sips -s format png -z 64 64     "$INPUT_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png"
sips -s format png -z 128 128   "$INPUT_PNG" --out "$ICONSET_DIR/icon_128x128.png"
sips -s format png -z 256 256   "$INPUT_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png"
sips -s format png -z 256 256   "$INPUT_PNG" --out "$ICONSET_DIR/icon_256x256.png"
sips -s format png -z 512 512   "$INPUT_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png"
sips -s format png -z 512 512   "$INPUT_PNG" --out "$ICONSET_DIR/icon_512x512.png"
sips -s format png -z 1024 1024 "$INPUT_PNG" --out "$ICONSET_DIR/icon_512x512@2x.png"

# Convert iconset to icns
echo "📦 Converting to .icns..."
iconutil -c icns "$ICONSET_DIR"

# Cleanup
rm -rf "$ICONSET_DIR"

echo "✅ Done! AppIcon.icns created."
