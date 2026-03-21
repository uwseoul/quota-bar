#!/usr/bin/env bash
# Build universal macOS binary (arm64 + x86_64) for GLM Bar
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SOURCE_FILES=(
    "$PROJECT_ROOT/Storage.swift"
    "$PROJECT_ROOT/UsageFetcher.swift"
    "$PROJECT_ROOT/GLMBarApp.swift"
)

BUILD_DIR="$PROJECT_ROOT/build"
DIST_DIR="$PROJECT_ROOT/dist"
APP_NAME="GLMBar"
BINARY_NAME="glm-bar"
DEPLOYMENT_TARGET="11.0"

build_arm64() {
    echo "Building for arm64..."
    mkdir -p "$BUILD_DIR/arm64"
    swiftc \
        -target "arm64-apple-macosx$DEPLOYMENT_TARGET" \
        -O \
        -o "$BUILD_DIR/arm64/$BINARY_NAME" \
        "${SOURCE_FILES[@]}" \
        -framework SwiftUI \
        -framework AppKit
    echo "✓ arm64 build complete"
}

build_x86_64() {
    echo "Building for x86_64..."
    mkdir -p "$BUILD_DIR/x86_64"
    swiftc \
        -target "x86_64-apple-macosx$DEPLOYMENT_TARGET" \
        -O \
        -o "$BUILD_DIR/x86_64/$BINARY_NAME" \
        "${SOURCE_FILES[@]}" \
        -framework SwiftUI \
        -framework AppKit
    echo "✓ x86_64 build complete"
}

create_universal_binary() {
    echo "Creating universal binary..."
    mkdir -p "$DIST_DIR"
    lipo -create \
        "$BUILD_DIR/arm64/$BINARY_NAME" \
        "$BUILD_DIR/x86_64/$BINARY_NAME" \
        -output "$DIST_DIR/$BINARY_NAME"
    echo "✓ Universal binary created: $DIST_DIR/$BINARY_NAME"
}

create_app_bundle() {
    echo "Creating app bundle..."
    local app_dir="$DIST_DIR/$APP_NAME.app"
    local contents_dir="$app_dir/Contents"
    local macos_dir="$contents_dir/MacOS"
    
    rm -rf "$app_dir"
    mkdir -p "$macos_dir"
    
    cp "$DIST_DIR/$BINARY_NAME" "$macos_dir/$APP_NAME"
    cp "$PROJECT_ROOT/packaging/Info.plist" "$contents_dir/Info.plist"
    
    chmod +x "$macos_dir/$APP_NAME"
    
    codesign --force --deep --sign - "$app_dir" 2>/dev/null || true
    
    echo "✓ App bundle created: $app_dir"
}

create_release_archives() {
    echo "Creating release archives..."
    
    tar -czf "$DIST_DIR/glm-bar-macos.tar.gz" -C "$DIST_DIR" "$BINARY_NAME"
    echo "✓ Created: $DIST_DIR/glm-bar-macos.tar.gz"
    
    pushd "$DIST_DIR" >/dev/null
    zip -r -q "$APP_NAME.zip" "$APP_NAME.app"
    popd >/dev/null
    echo "✓ Created: $DIST_DIR/$APP_NAME.zip"
}

print_summary() {
    echo ""
    echo "========================================"
    echo "Build Summary"
    echo "========================================"
    echo "Universal binary: $DIST_DIR/$BINARY_NAME"
    lipo -info "$DIST_DIR/$BINARY_NAME"
    echo ""
    echo "App bundle:       $DIST_DIR/$APP_NAME.app"
    echo "Release archives:"
    echo "  - $DIST_DIR/glm-bar-macos.tar.gz"
    echo "  - $DIST_DIR/$APP_NAME.zip"
    echo ""
    file "$DIST_DIR/$BINARY_NAME"
}

main() {
    echo "GLM Bar Universal Build"
    echo "======================="
    echo ""
    
    build_arm64
    build_x86_64
    create_universal_binary
    create_app_bundle
    create_release_archives
    print_summary
    
    echo ""
    echo "Running verification..."
    "$SCRIPT_DIR/verify-build.sh"
}

main "$@"
