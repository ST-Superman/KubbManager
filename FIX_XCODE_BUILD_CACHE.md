# Fixing "Ambiguous ScrollView init" Error in Xcode

**Date**: October 18, 2025
**Issue**: Xcode showing "Ambiguous use of 'init'" on MainMenuView.swift:25 despite code being correct

---

## Why This Is Happening

The code in MainMenuView.swift is **actually correct** (line 25 has `ScrollView(.vertical)`), but Xcode is showing a cached error from its Derived Data. This is a common Xcode issue where the IDE doesn't pick up file changes properly.

**Verification**: Command-line builds succeed for the iOS app - only the Watch app fails (pre-existing WatchKit issue).

---

## Solution: Clean Xcode Build Cache

### Option 1: Clean Build Folder (Fastest)

1. **Open Xcode**
2. **Select Product menu** → **Clean Build Folder** (or press `⇧⌘K`)
3. **Wait for cleaning to complete**
4. **Build again** (`⌘B`)

### Option 2: Delete Derived Data (Most Thorough)

If Option 1 doesn't work, do this:

1. **Quit Xcode completely**

2. **Delete Derived Data folder**:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/Kubb_Manager-*
   ```

3. **Reopen Xcode**

4. **Clean Build Folder**: Product → Clean Build Folder (`⇧⌘K`)

5. **Build**: Product → Build (`⌘B`)

---

## Alternative: Use Command Line Build

If you want to verify the build works without Xcode:

```bash
cd "/Users/sthompson/Library/CloudStorage/OneDrive-DomoInc/Documents/gitHub/KubbManager"

# Build just the iOS app (excludes Watch app)
xcodebuild -project "Kubb Manager.xcodeproj" \
  -scheme "Kubb Manager" \
  -sdk iphonesimulator \
  -configuration Debug \
  build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
```

The iOS app will build successfully. Only the Watch app will fail (pre-existing issue).

---

## Expected Result After Clean

After cleaning, Xcode should:
- ✅ No longer show "Ambiguous use of 'init'" error on MainMenuView.swift:25
- ✅ Successfully build the "Kubb Manager" iOS app target
- ⚠️ Watch app will still fail (pre-existing WatchKit module issue - unrelated to our changes)

---

## To See the Redesigned Views

Once the build succeeds:

1. **Select "Kubb Manager" scheme** (not Watch App)
2. **Choose iOS Simulator** (iPhone 15, etc.)
3. **Run the app** (`⌘R`)
4. **Navigate to**: Main Menu → 8-Meter Training
5. **You should see**:
   - New navigation with NavigationStack (no nested tabs)
   - Back button instead of "Dismiss"
   - Clean overview dashboard with stats cards
   - Tutorial as "?" button instead of tab

---

## Files That Were Fixed

All these changes are already committed and pushed:

- ✅ `MainMenuView.swift` - Line 25: `ScrollView(.vertical)`
- ✅ `SessionCards.swift` - Extracted shared components
- ✅ `HomeViewRedesigned.swift` - Removed duplicate components
- ✅ `EightMeterTrainingViewRedesigned.swift` - New navigation architecture

**Latest Commit**: `71bebac` - "Fix ambiguous ScrollView initializer in MainMenuView"

---

## If Issue Persists

If after cleaning Derived Data you still see the error:

1. Check that you're editing the correct file:
   ```
   /Users/sthompson/Library/CloudStorage/OneDrive-DomoInc/Documents/gitHub/KubbManager/Kubb Manager/Views/MainMenuView.swift
   ```

2. Verify line 25 shows:
   ```swift
   ScrollView(.vertical) {
   ```

3. Make sure you've **saved all files** in Xcode (`⌘S`)

4. Try **restarting Xcode** completely

---

## Summary

The error is a **false positive from Xcode's cache**, not an actual code problem. Clean Build Folder or delete Derived Data should resolve it.

The redesigned views are ready to use and will display correctly once Xcode picks up the latest changes!
