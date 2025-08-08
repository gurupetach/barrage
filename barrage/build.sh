#!/bin/bash

# Build script for Barrage - creates both escript and standalone versions

set -e  # Exit on any error

echo "🚀 Building Barrage..."

# Check for Burrito requirements
check_burrito_deps() {
    local missing=()
    command -v zig >/dev/null 2>&1 || missing+=("zig")
    command -v xz >/dev/null 2>&1 || missing+=("xz")
    command -v 7z >/dev/null 2>&1 || missing+=("7z")
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo "⚠️  Missing requirements for Burrito standalone builds: ${missing[*]}"
        echo "   To install:"
        echo "   - zig: sudo snap install zig --classic"
        echo "   - xz: sudo apt install xz-utils (usually pre-installed)"
        echo "   - 7z: sudo apt install p7zip-full (usually pre-installed)"
        echo ""
        return 1
    fi
    return 0
}

# Parse command line arguments
BUILD_TYPE="both"
if [ "$1" = "--escript-only" ]; then
    BUILD_TYPE="escript"
elif [ "$1" = "--standalone-only" ]; then
    BUILD_TYPE="standalone"
fi

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -f barrage barrage-escript barrage-standalone
rm -rf _build/prod burrito_out

# Get dependencies
echo "📦 Fetching dependencies..."
mix deps.get > /dev/null

# Build escript version (requires Elixir runtime)
if [ "$BUILD_TYPE" = "both" ] || [ "$BUILD_TYPE" = "escript" ]; then
    echo "🏗️  Building escript version..."
    MIX_ENV=prod mix escript.build > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        mv barrage barrage-escript
        echo "✅ Escript built successfully: barrage-escript"
        echo "   - Size: $(ls -lh barrage-escript | awk '{print $5}')"
        echo "   - Requires Elixir/Erlang runtime"
        echo "   - Fast startup, small size"
    else
        echo "❌ Failed to build escript"
        exit 1
    fi
fi

# Build Burrito standalone version (self-contained)
if [ "$BUILD_TYPE" = "both" ] || [ "$BUILD_TYPE" = "standalone" ]; then
    if check_burrito_deps; then
        echo "🌯 Building standalone version with Burrito..."
        echo "   (This may take a few minutes to download runtimes...)"
        
        MIX_ENV=prod mix release > /dev/null 2>&1
        
        if [ $? -eq 0 ] && [ -f "burrito_out/barrage_linux" ]; then
            cp burrito_out/barrage_linux barrage-standalone
            echo "✅ Standalone version built successfully: barrage-standalone"
            echo "   - Size: $(ls -lh barrage-standalone | awk '{print $5}')"
            echo "   - Self-contained (no runtime required)"
            echo "   - Works on any Linux x86_64 system"
            echo "   - Statically linked binary"
        else
            echo "❌ Failed to build standalone version"
            if [ "$BUILD_TYPE" = "standalone" ]; then
                exit 1
            fi
        fi
    else
        echo "⚠️  Skipping standalone build - missing dependencies"
        if [ "$BUILD_TYPE" = "standalone" ]; then
            exit 1
        fi
    fi
fi

# Choose default binary
if [ -f "barrage-standalone" ]; then
    echo "🎯 Setting standalone version as default..."
    cp barrage-standalone barrage
    DEFAULT_TYPE="standalone (no runtime required)"
elif [ -f "barrage-escript" ]; then
    echo "🎯 Setting escript version as default..."
    cp barrage-escript barrage
    DEFAULT_TYPE="escript (requires Elixir runtime)"
fi

echo ""
echo "🎉 Build complete!"
echo "📁 Files created:"

if [ -f "barrage-escript" ]; then
    echo "  - barrage-escript (escript - requires Elixir runtime, ~2MB)"
fi

if [ -f "barrage-standalone" ]; then
    echo "  - barrage-standalone (standalone - no runtime required, ~16MB)"
fi

if [ -f "barrage" ]; then
    echo "  - barrage (default: $DEFAULT_TYPE)"
fi

echo ""
echo "📋 Usage recommendations:"
echo "  - For development/testing: ./barrage"
echo "  - For users with Elixir: barrage-escript"
echo "  - For maximum compatibility: barrage-standalone"
echo "  - For distribution: Upload barrage-standalone to GitHub releases"

echo ""
echo "🧪 Quick test:"
echo "  echo 'I AGREE' | ./barrage https://example.com --quiet"