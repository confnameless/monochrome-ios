#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEME="monochrome"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="monochrome"

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "Building $SCHEME..."
xcodebuild \
    -project "$PROJECT_DIR/$APP_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -sdk iphoneos \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGN_IDENTITY="" \
    -quiet

# Find the .app
APP_PATH=$(find "$BUILD_DIR/DerivedData" -name "$APP_NAME.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo "Build failed: $APP_NAME.app not found"
    exit 1
fi

echo "Packaging IPA..."
mkdir -p "$BUILD_DIR/Payload"
cp -r "$APP_PATH" "$BUILD_DIR/Payload/"
cd "$BUILD_DIR"
zip -r -q "$PROJECT_DIR/$APP_NAME.ipa" Payload/

# Clean up
rm -rf "$BUILD_DIR"

echo "Done: $PROJECT_DIR/$APP_NAME.ipa"
