# Apple Watch App Setup Guide

This guide walks you through setting up the Apple Watch target for Kubb Manager.

## Step 1: Add Watch App Target

1. Open `Kubb Manager.xcodeproj` in Xcode
2. Go to **File > New > Target**
3. Select **watchOS > Watch App** (not "Watch App for iOS App")
4. Click **Next**
5. Configure the target:
   - **Product Name**: `Kubb Manager Watch`
   - **Bundle Identifier**: Accept Xcode's auto-generated identifier (e.g., `ST-Superman.Kubb-Manager-Watch`)
   - **Language**: Swift
   - **User Interface**: SwiftUI
   - **Include Notification Scene**: No (optional)
   
   **Note**: Xcode will auto-generate the bundle identifier based on your iOS app's bundle ID. This is correct - use whatever Xcode suggests.
6. Click **Finish**
7. When prompted "Activate 'Kubb Manager Watch' scheme?", click **Activate**

## Step 2: Configure Watch App Settings

### Info.plist Configuration

**Note**: Modern Xcode (15+) handles these settings automatically. You likely won't see `WKCompanionAppBundleIdentifier` or `WKApplication` in the Info tab - **this is normal and correct**. Xcode manages the watch-iOS app relationship automatically based on your project structure.

**Skip this section** unless you're using an older version of Xcode or encounter issues.

<details>
<summary>For older Xcode versions or troubleshooting (click to expand)</summary>

If you need to manually configure these (rare):

1. Select the **Kubb Manager Watch** target
2. Go to the **Info** tab
3. Add these keys if missing:
   - `WKCompanionAppBundleIdentifier`: Should match your iOS app's bundle ID (e.g., `ST-Superman.Kubb-Manager`)
   - `WKApplication`: `true`

</details>

### Signing & Capabilities (Required)

1. Select the **Kubb Manager Watch** target
2. Go to **Signing & Capabilities** tab
3. Ensure **Automatically manage signing** is checked
4. Select your development team from the dropdown
5. Xcode will automatically handle provisioning profiles

**This is the important step** - make sure signing is configured correctly.

## Step 3: Add Shared Files to Watch Target

The following files need to be accessible to both iOS and watchOS targets:

### Models (Shared Data)
1. Select `WatchCommunication.swift`
2. In the **File Inspector** (right panel), check both:
   - ☑️ Kubb Manager (iOS)
   - ☑️ Kubb Manager Watch (watchOS)

This file contains all the shared data structures for communication.

### Watch-Only Files

Create these files in the Watch app target (they're provided below):

1. `KubbManagerWatchApp.swift` - Main watch app entry point
2. `ContentView.swift` - Main watch view (session overview)
3. `BatonThrowInputView.swift` - Baton throw input screen
4. `InkastInputView.swift` - Inkast input screen
5. `WatchConnectivityManager.swift` - Watch-side connectivity manager

## Step 4: Configure Build Settings

### Watch App Target

1. Select **Kubb Manager Watch** target
2. Go to **Build Settings**
3. Set these values:
   - **iOS Deployment Target**: watchOS 9.0 or later
   - **Swift Language Version**: Swift 5
   - **Enable Bitcode**: No (deprecated)

### iOS App Target

1. Select **Kubb Manager** target
2. Go to **General** tab
3. Scroll to **Frameworks, Libraries, and Embedded Content**
4. Ensure **WatchConnectivity.framework** is added (it should be automatic)

## Step 5: Update iOS App Info.plist

Add the watch app bundle identifier to your iOS app:

**Note**: This step is usually **not required** for modern watchOS apps. Xcode handles the linking automatically. Only add this if you encounter issues with the watch app not appearing.

If needed, you can add this to your iOS app's `Info.plist`:

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>WKAppBundleIdentifier</key>
        <string>ST-Superman.Kubb-Manager-Watch</string>
    </dict>
</dict>
```

Replace `ST-Superman.Kubb-Manager-Watch` with whatever bundle ID Xcode generated for your watch app.

## Step 6: Test Watch Connectivity

### Using Simulator

1. Open Xcode
2. Select **Kubb Manager Watch** scheme
3. Choose an iPhone + Watch simulator pair (e.g., "iPhone 15 Pro + Apple Watch Series 9")
4. Click **Run** (or Cmd+R)
5. The iOS app and Watch app will both launch

### Testing Communication

1. Start a session in the iOS app
2. Open the Watch app
3. The watch should show the active session
4. Test requesting input from the phone
5. Verify data syncs back to the phone

### Testing Locked iPhone (Primary Use Case)

**Important**: The watch is designed to work while the iPhone is locked and in your pocket.

1. Start a session in the iOS app
2. Request input on watch
3. **Lock the iPhone** (press side button)
4. Record several throws on the watch
5. Verify prompts continue to appear automatically
6. Unlock iPhone and verify all data was recorded

**This is the normal usage pattern** - users will have their phone locked during sessions.

## Step 7: Provisioning for Device Testing

### Development Provisioning

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Create App IDs for:
   - iOS App: Your existing bundle ID (e.g., `ST-Superman.Kubb-Manager`)
   - Watch App: Your watch bundle ID (e.g., `ST-Superman.Kubb-Manager-Watch`)
4. Create provisioning profiles for both
5. Download and install in Xcode

**Note**: Xcode can automatically register the watch app ID if you have "Automatically manage signing" enabled.

### Device Testing

1. Connect your iPhone to your Mac
2. Ensure your Apple Watch is paired with the iPhone
3. Select your iPhone as the run destination
4. Build and run the iOS app
5. The Watch app will automatically install on your paired watch

## Common Issues and Solutions

### Issue: Watch app doesn't appear on watch

**Solution**: 
- Ensure the watch is paired and unlocked
- Check that "Show App on Apple Watch" is enabled in the Watch app on iPhone
- Try restarting both devices

### Issue: WatchConnectivity not working

**Solution**:
- Ensure both apps are running (iPhone can be locked, but not force-quit)
- Check that Bluetooth is enabled
- Keep watch app in foreground (don't switch to another watch app)
- Check console logs for connectivity errors

**Note**: iPhone being locked is normal and expected - messages work while locked.

### Issue: Build errors for shared files

**Solution**:
- Ensure `WatchCommunication.swift` is added to both targets
- Check that import statements are correct (use `#if os(iOS)` if needed)
- Verify deployment targets are compatible

## Next Steps

After setup is complete:

1. ✅ Test basic connectivity between phone and watch
2. ✅ Test baton throw input flow
3. ✅ Test inkast input flow
4. ✅ **Test with iPhone locked** (primary use case)
5. ✅ Test with each game mode (8M, Inkast & Blast, Baseball Kubb)
6. ✅ Test error handling and edge cases
7. ✅ Test battery usage during extended sessions

## File Structure

Your project should look like this:

```
Kubb Manager/
├── Kubb Manager/              (iOS App)
│   ├── Models/
│   │   ├── WatchCommunication.swift  ← Shared with Watch
│   │   └── ...
│   ├── ViewModels/
│   │   ├── WatchConnectivityManager.swift
│   │   ├── SessionManager+WatchConnectivity.swift
│   │   └── ...
│   ├── Views/
│   │   ├── WatchConnectivityView.swift
│   │   └── ...
│   └── ...
│
└── Kubb Manager Watch/        (watchOS App)
    ├── KubbManagerWatchApp.swift
    ├── ContentView.swift
    ├── BatonThrowInputView.swift
    ├── InkastInputView.swift
    ├── WatchConnectivityManager.swift
    └── Assets.xcassets/
```

## Important Usage Notes

### ✅ iPhone Can Be Locked

**The watch is designed to work with the iPhone locked and in your pocket.** This is the primary use case.

- WatchConnectivity continues to work when iPhone is locked
- Messages are delivered reliably in both directions
- iPhone wakes up to process watch messages, then returns to sleep
- Minimal battery impact

See `WATCH_LOCKED_PHONE_GUIDE.md` for complete details.

### ⚠️ Keep Watch App in Foreground

The watch app should stay in the foreground during active sessions:
- Input prompts appear immediately
- User can respond to prompts right away
- Natural usage pattern (you're using it to record throws)

### ❌ Don't Force-Quit iPhone App

Normal backgrounding/locking is fine, but don't force-quit:
- Locking iPhone: ✅ Works perfectly
- iPhone sleeping: ✅ No problem
- Force-quitting app: ❌ Breaks connection

## Resources

- [Apple Watch Programming Guide](https://developer.apple.com/documentation/watchkit)
- [WatchConnectivity Framework](https://developer.apple.com/documentation/watchconnectivity)
- [SwiftUI for watchOS](https://developer.apple.com/documentation/swiftui/watchos-apps)
- `WATCH_LOCKED_PHONE_GUIDE.md` - Detailed guide on locked iPhone usage
