#!/usr/bin/env bash
# verify-build.sh - Verification script for universal macOS binary and app bundle
# Usage: ./scripts/verify-build.sh
# Exits 0 if all checks pass, non-zero otherwise

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DIST_DIR="$PROJECT_ROOT/dist"
TERMINAL_BINARY="$DIST_DIR/glm-bar"
APP_BUNDLE="$DIST_DIR/GLMBar.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/GLMBar"
APP_INFO_PLIST="$APP_BUNDLE/Contents/Info.plist"
APP_FRAMEWORKS_DIR="$APP_BUNDLE/Contents/Frameworks"
SPARKLE_FRAMEWORK="$APP_FRAMEWORKS_DIR/Sparkle.framework"
SPARKLE_FRAMEWORK_BINARY="$SPARKLE_FRAMEWORK/Versions/Current/Sparkle"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

errors=0

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((errors++))
}

check_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# =============================================================================
# Check 1: Terminal binary exists
# =============================================================================
if [[ -f "$TERMINAL_BINARY" ]]; then
    check_pass "Terminal binary exists: $TERMINAL_BINARY"
else
    check_fail "Terminal binary missing: $TERMINAL_BINARY"
fi

# =============================================================================
# Check 2: Terminal binary is universal (arm64 + x86_64)
# =============================================================================
if [[ -f "$TERMINAL_BINARY" ]]; then
    arch_info=$(lipo -info "$TERMINAL_BINARY" 2>&1 || true)
    if echo "$arch_info" | grep -q "arm64" && echo "$arch_info" | grep -q "x86_64"; then
        check_pass "Terminal binary is universal (arm64 + x86_64)"
        check_info "lipo -info: $arch_info"
    else
        check_fail "Terminal binary is NOT universal. Got: $arch_info"
    fi
fi

    # Check 4: App binary is universal (arm64 + x86_64)
    # =============================================================================
    if [[ -f "$APP_BINARY" ]]; then
        arch_info=$(lipo -info "$APP_BINARY" 2>&1 || true)
        if echo "$arch_info" | grep -q "arm64" && echo "$arch_info" | grep -q "x86_64"; then
            check_pass "App binary is universal (arm64 + x86_64)"
            check_info "lipo -info: $arch_info"
        else
            check_fail "Terminal binary is NOT universal. Got: $arch_info"
        fi
    # =============================================================================
    # Check 5: Info.plist is valid and has required keys
    # =============================================================================
if [[ -f "$APP_BINARY" ]]; then
    arch_info=$(lipo -info "$APP_BINARY" 2>&1 || true)
    if echo "$arch_info" | grep -q "arm64" && echo "$arch_info" | grep -q "x86_64"; then
        check_pass "App binary is universal (arm64 + x86_64)"
        check_info "lipo -info: $arch_info"
    else
        check_fail "App binary is NOT universal. Got: $arch_info"
    fi
fi

    # Check 4: App binary is universal (arm64 + x86_64)
    # =============================================================================
    if [[ -f "$APP_BINARY" ]]; then
        arch_info=$(lipo -info "$APP_BINARY" 2>&1 || true)
        if echo "$arch_info" | grep -q "arm64" && echo "$arch_info" | grep -q "x86_64"; then
            check_pass "App binary is universal (arm64 + x86_64)"
            check_info "lipo -info: $arch_info"
        else
            check_fail "Terminal binary is NOT universal. Got: $arch_info"
        fi
    fi

    # =============================================================================
    # Check 5: Info.plist is valid and has required keys
    # =============================================================================
    if [[ -f "$APP_INFO_PLIST" ]]; then
        # Validate plist syntax
        if plutil -lint "$APP_INFO_PLIST" &>/dev/null; then
            check_pass "Info.plist is valid plist format"
        else
            check_fail "Info.plist has invalid plist syntax"
        fi
        
        # Check CFBundleExecutable
        bundle_exec=$(defaults read "$APP_INFO_PLIST" CFBundleExecutable 2>/dev/null || true)
        if [[ "$bundle_exec" == "GLMBar" ]]; then
            check_pass "CFBundleExecutable = GLMBar"
        else
            check_fail "CFBundleExecutable should be 'GLMBar', got: '$bundle_exec'"
        fi
        
        # Check CFBundleIdentifier
        bundle_id=$(defaults read "$APP_INFO_PLIST" CFBundleIdentifier 2>/dev/null || true)
        if [[ "$bundle_id" == "com.uwseoul.glmbar" ]]; then
            check_pass "CFBundleIdentifier = com.uwseoul.glmbar"
        else
            check_fail "CFBundleIdentifier should be 'com.uwseoul.glmbar', got: '$bundle_id'"
        fi
        
        # Check CFBundlePackageType
        pkg_type=$(defaults read "$APP_INFO_PLIST" CFBundlePackageType 2>/dev/null || true)
        if [[ "$pkg_type" == "APPL" ]]; then
            check_pass "CFBundlePackageType = APPL"
        else
            check_fail "CFBundlePackageType should be 'APPL', got: '$pkg_type'"
        fi
        
        # Check LSUIElement (menu bar app should not show in Dock)
        ls_ui=$(defaults read "$APP_INFO_PLIST" LSUIElement 2>/dev/null || true)
        if [[ "$ls_ui" == "1" ]] || [[ "$ls_ui" == "true" ]] || [[ "$ls_ui" == "True" ]]; then
            check_pass "LSUIElement = true (menu bar only)"
        else
            check_fail "LSUIElement should be true for menu bar app, got: '$ls_ui'"
        fi
        
        # Check LSMinimumSystemVersion
        min_ver=$(defaults read "$APP_INFO_PLIST" LSMinimumSystemVersion 2>/dev/null || true)
        if [[ -n "$min_ver" ]]; then
            check_pass "LSMinimumSystemVersion = $min_ver"
        else
            check_fail "LSMinimumSystemVersion is missing"
        fi
        
        # Check CFBundleExecutable
        bundle_exec=$(defaults read "$APP_INFO_PLIST" CFBundleExecutable 2>/dev/null || true)
        if [[ "$bundle_exec" == "GLMBar" ]]; then
            check_pass "CFBundleExecutable = GLMBar"
        else
            check_fail "CFBundleExecutable should be 'GLMBar', got: '$bundle_exec'"
        fi
        
        # Check CFBundleIdentifier
        bundle_id=$(defaults read "$APP_INFO_PLIST" CFBundleIdentifier 2>/dev/null || true)
        if [[ "$bundle_id" == "com.uwseoul.glmbar" ]]; then
            check_pass "CFBundleIdentifier = com.uwseoul.glmbar"
        else
            check_fail "CFBundleIdentifier should be 'com.uwseoul.glmbar', got: '$bundle_id'"
        fi
        
        # Check CFBundlePackageType
        pkg_type=$(defaults read "$APP_INFO_PLIST" CFBundlePackageType 2>/dev/null || true)
        if [[ "$pkg_type" == "APPL" ]]; then
            check_pass "CFBundlePackageType = APPL"
        else
            check_fail "CFBundlePackageType should be 'APPL', got: '$pkg_type'"
        fi
        
        # Check LSUIElement (menu bar app should not show in Dock)
        ls_ui=$(defaults read "$APP_INFO_PLIST" LSUIElement 2>/dev/null || true)
        if [[ "$ls_ui" == "1" ]] || [[ "$ls_ui" == "true" ]] || [[ "$ls_ui" == "True" ]]; then
            check_pass "LSUIElement = true (menu bar only)"
        else
            check_fail "LSUIElement should be true for menu bar app, got: '$ls_ui'"
        fi
        
        # Check LSMinimumSystemVersion
        min_ver=$(defaults read "$APP_INFO_PLIST" LSMinimumSystemVersion 2>/dev/null || true)
        if [[ -n "$min_ver" ]]; then
            check_pass "LSMinimumSystemVersion = $min_ver"
        else
            check_fail "LSMinimumSystemVersion is missing"
        fi
        bundle_exec=$(defaults read "$APP_INFO_PLIST" CFBundleExecutable 2>/dev/null || true)
        if [[ "$bundle_exec" == "GLMBar" ]]; then
            check_pass "CFBundleExecutable = GLMBar"
        else
            check_fail "CFBundleExecutable should be 'GLMBar', got: '$bundle_exec'"
        fi
        
        # Check CFBundleIdentifier
        bundle_id=$(defaults read "$APP_INFO_PLIST" CFBundleIdentifier 2>/dev/null || true)
        if [[ "$bundle_id" == "com.uwseoul.glmbar" ]]; then
            check_pass "CFBundleIdentifier = com.uwseoul.glmbar"
        else
            check_fail "CFBundleIdentifier should be 'com.uwseoul.glmbar', got: '$bundle_id'"
        fi
        
        # Check CFBundlePackageType
        pkg_type=$(defaults read "$APP_INFO_PLIST" CFBundlePackageType 2>/dev/null || true)
        if [[ "$pkg_type" == "APPL" ]]; then
            check_pass "CFBundlePackageType = APPL"
        else
            check_fail "CFBundlePackageType should be 'APPL', got: '$pkg_type'"
        fi
        
        # Check LSUIElement (menu bar app should not show in Dock)
        ls_ui=$(defaults read "$APP_INFO_PLIST" LSUIElement 2>/dev/null || true)
        if [[ "$ls_ui" == "1" ]] || [[ "$ls_ui" == "true" ]] || [[ "$ls_ui" == "True" ]]; then
            check_pass "LSUIElement = true (menu bar only)"
        else
            check_fail "LSUIElement should be true for menu bar app, got: '$ls_ui'"
        fi
        
        # Check LSMinimumSystemVersion
        min_ver=$(defaults read "$APP_INFO_PLIST" LSMinimumSystemVersion 2>/dev/null || true)
        if [[ -n "$min_ver" ]]; then
            check_pass "LSMinimumSystemVersion = $min_ver"
        else
            check_fail "LSMinimumSystemVersion is missing"
        fi

    if [[ -f "$APP_BINARY" ]]; then
        check_pass "App executable exists: $APP_BINARY"
    else
        check_fail "App executable missing: $APP_BINARY"
    fi

    if [[ -f "$APP_INFO_PLIST" ]]; then
        check_pass "App Info.plist exists: $APP_INFO_PLIST"
    else
        check_fail "App Info.plist missing: $APP_INFO_PLIST"
    fi

    # Check LSMinimumSystemVersion
    min_ver=$(defaults read "$APP_INFO_PLIST" LSMinimumSystemVersion 2>/dev/null || true)
    if [[ -n "$min_ver" ]]; then
        check_pass "LSMinimumSystemVersion = $min_ver"
    else
        check_fail "LSMinimumSystemVersion is missing"
    fi

    # Check LSMinimumSystemVersion
    min_ver=$(defaults read "$APP_INFO_PLIST" LSMinimumSystemVersion 2>/dev/null || true)
    if [[ -n "$min_ver" ]]; then
        check_pass "LSMinimumSystemVersion = $min_ver"
    else
        check_fail "LSMinimumSystemVersion is missing"
    fi
fi

if [[ -d "$APP_FRAMEWORKS_DIR" ]]; then
    check_pass "App Frameworks directory exists: $APP_FRAMEWORKS_DIR"
else
    check_fail "App Frameworks directory missing: $APP_FRAMEWORKS_DIR"
fi

if [[ -d "$SPARKLE_FRAMEWORK" ]]; then
    check_pass "Sparkle framework exists: $SPARKLE_FRAMEWORK"
else
    check_fail "Sparkle framework missing: $SPARKLE_FRAMEWORK"
fi

if [[ -f "$SPARKLE_FRAMEWORK_BINARY" ]]; then
    check_pass "Sparkle binary exists: $SPARKLE_FRAMEWORK_BINARY"
else
    check_fail "Sparkle binary missing: $SPARKLE_FRAMEWORK_BINARY"
fi

if [[ -d "$SPARKLE_FRAMEWORK" ]]; then
    if codesign --verify --verbose=3 --strict "$SPARKLE_FRAMEWORK" >/dev/null 2>&1; then
        check_pass "Sparkle framework signature is valid"
    else
        check_fail "Sparkle framework signature is invalid"
    fi
fi

if [[ -d "$APP_BUNDLE" ]]; then
    if codesign -vvv --deep --strict "$APP_BUNDLE" >/dev/null 2>&1; then
        check_pass "App bundle passes codesign -vvv --deep --strict"
    else
        check_fail "App bundle failed codesign -vvv --deep --strict"
    fi
fi

if [[ -f "$TERMINAL_BINARY" ]]; then
    file_info=$(file "$TERMINAL_BINARY")
    if echo "$file_info" | grep -q "Mach-O universal binary"; then
        check_pass "file reports universal Mach-O binary"
        check_info "file: $file_info"
    else
        check_fail "file does NOT report universal binary: $file_info"
    fi
fi

# =============================================================================
# Summary
# =============================================================================
echo ""
echo "========================================"
if [[ $errors -eq 0 ]]; then
    echo -e "${GREEN}All verification checks passed!${NC}"
    exit 0
else
    echo -e "${RED}Verification failed with $errors error(s)${NC}"
    exit 1
fi
