#!/bin/bash

# Clean Xcode Cache Script
# This script thoroughly cleans Xcode's build cache and derived data
# Use this when Xcode is showing old/cached views despite code changes

set -e  # Exit on any error

echo "🧹 Xcode Cache Cleaning Script"
echo "=============================="
echo ""

# Check if Xcode is running
if pgrep -x "Xcode" > /dev/null; then
    echo "⚠️  WARNING: Xcode is currently running!"
    echo "   Please quit Xcode completely before running this script."
    echo ""
    read -p "Press ENTER after you've quit Xcode, or Ctrl+C to cancel..."
    echo ""
fi

# Store current directory
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "📂 Project directory: $PROJECT_DIR"
echo ""

# Step 1: Delete Derived Data
echo "🗑️  Step 1: Deleting Derived Data..."
if [ -d ~/Library/Developer/Xcode/DerivedData/Kubb_Manager-* ]; then
    rm -rf ~/Library/Developer/Xcode/DerivedData/Kubb_Manager-*
    echo "   ✅ Deleted Kubb Manager Derived Data"
else
    echo "   ℹ️  No Kubb Manager Derived Data found (already clean)"
fi

# Step 2: Delete Module Cache
echo ""
echo "🗑️  Step 2: Deleting Module Cache..."
if [ -d ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex ]; then
    rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
    echo "   ✅ Deleted Module Cache"
else
    echo "   ℹ️  No Module Cache found (already clean)"
fi

# Step 3: Delete local build folder
echo ""
echo "🗑️  Step 3: Deleting local build folder..."
cd "$PROJECT_DIR"
if [ -d "build" ]; then
    rm -rf build/
    echo "   ✅ Deleted local build folder"
else
    echo "   ℹ️  No local build folder found (already clean)"
fi

# Step 4: Pull latest changes
echo ""
echo "📥 Step 4: Pulling latest changes from git..."
git pull origin develop
echo "   ✅ Git pull completed"

# Step 5: Summary
echo ""
echo "✅ CLEANUP COMPLETE!"
echo "==================="
echo ""
echo "Next steps:"
echo "1. Open Xcode"
echo "2. Product → Clean Build Folder (⇧⌘K)"
echo "3. Product → Build (⌘B)"
echo "4. Run the app (⌘R)"
echo ""
echo "Expected result:"
echo "- Title should say: '8-Meter Practice [REDESIGNED]'"
echo "- NO tabs at bottom"
echo "- 'Done' button on left, '?' button on right"
echo ""
echo "If you still see the old view with tabs, please let me know!"
