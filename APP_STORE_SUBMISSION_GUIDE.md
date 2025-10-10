# App Store Submission Guide - Kubb Manager with Apple Watch

## Current Version Information
- **iOS App**: Version 1.2, Build 2
- **Watch App**: Version 1.0, Build 1
- **Watch Support**: ✅ Included

## Pre-Submission Checklist

### 1. Update Version/Build Numbers
Before submitting, increment the build number:

**In Xcode:**
1. Open `Kubb Manager.xcodeproj`
2. Select the project in the navigator
3. Select "Kubb Manager" target
4. Go to "General" tab
5. Update version to **1.3** (or keep 1.2 if minor update)
6. Update build number to **3** (or next sequential number)
7. **Important**: Also update "Kubb Manager Watch Watch App" target with same version/build

**Alternatively via command line:**
```bash
# Update iOS app version
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 1.3" "Kubb Manager/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion 3" "Kubb Manager/Info.plist"

# Update Watch app version (if needed)
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 1.3" "Kubb Manager Watch Watch App/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion 3" "Kubb Manager Watch Watch App/Info.plist"
```

### 2. Verify Entitlements

**iOS App Entitlements** (`Kubb Manager/Kubb_Manager.entitlements`):
- ✅ CloudKit
- ✅ Push Notifications (if needed)
- ✅ Background Modes (if needed)

**Watch App Entitlements**:
- ✅ Watch Connectivity
- ✅ Background Modes (if needed)

### 3. Configure App Store Connect

#### Initial Setup (One-time)
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click "My Apps" → Find "Kubb Manager"
3. If Watch support not added yet:
   - Click "+ Version or Platform"
   - Select "watchOS"
   - Add Watch app information

#### Required Information:
- **Screenshots**:
  - iPhone (6.7", 6.5", 5.5" required)
  - Apple Watch (40mm, 44mm, 45mm, 49mm)
- **App Description** (with Watch features mentioned)
- **What's New** (mention Watch support)
- **Keywords**
- **Privacy Policy URL**
- **Support URL**

### 4. Prepare Release Notes

Add to your "What's New" section:
```
🎉 Apple Watch Support!
- Record throws directly from your Apple Watch
- Hands-free operation while playing
- Real-time sync between iPhone and Watch
- Watch Mode for continuous input
- All game modes supported: 8M Training, Inkast & Blast, Full Game Sim, and Baseball Kubb

Plus improvements and bug fixes.
```

## Submission Process

### Method 1: Xcode (Recommended)

#### Step 1: Archive Your App
1. **Clean Build Folder**:
   - In Xcode menu: `Product` → `Clean Build Folder` (⇧⌘K)

2. **Select Device**:
   - In toolbar, select: `Any iOS Device (arm64)`
   - **Important**: Must be "Any iOS Device", not simulator

3. **Archive**:
   - Menu: `Product` → `Archive` (or ⌘B then ⌥⌘I)
   - Wait for archive to complete (may take 5-10 minutes)
   - Watch app is automatically included in the iOS app archive

4. **Verify Archive**:
   - Check that both iOS and Watch targets are included
   - Look for "Kubb Manager Watch Watch App" in archive details

#### Step 2: Upload to App Store Connect
1. **Organizer Window** should open automatically (or `Window` → `Organizer`)
2. Select the archive you just created
3. Click **"Distribute App"**
4. Choose **"App Store Connect"**
5. Click **"Upload"**
6. Select distribution certificate and provisioning profiles:
   - Let Xcode manage signing automatically (recommended)
   - Or manually select your certificates
7. Review app information
8. Click **"Upload"**
9. Wait for upload to complete (10-30 minutes depending on connection)

#### Step 3: Processing
- Apple will process your build (15 minutes to 2 hours)
- You'll receive email when processing is complete
- Build will appear in App Store Connect under "Activity" tab

### Method 2: Command Line (Advanced)

```bash
# Archive the app
xcodebuild -project "Kubb Manager.xcodeproj" \
  -scheme "Kubb Manager" \
  -configuration Release \
  -archivePath "$HOME/Desktop/KubbManager.xcarchive" \
  clean archive

# Export for App Store
xcodebuild -exportArchive \
  -archivePath "$HOME/Desktop/KubbManager.xcarchive" \
  -exportPath "$HOME/Desktop/KubbManager-Export" \
  -exportOptionsPlist ExportOptions.plist

# Upload using altool or Transporter app
xcrun altool --upload-app \
  --type ios \
  --file "$HOME/Desktop/KubbManager-Export/Kubb Manager.ipa" \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_ISSUER_ID
```

## TestFlight Configuration

### Step 1: Enable Build for Testing
1. In App Store Connect → "TestFlight" tab
2. Wait for build to finish processing
3. Select the build
4. Fill in "What to Test" (focus on Watch features):
   ```
   Please test the new Apple Watch integration:
   - Open Watch app and test recording throws
   - Try Watch Mode (continuous input)
   - Test all game modes from Watch
   - Verify sync between iPhone and Watch
   - Check watch connectivity indicators
   ```

### Step 2: Add Test Information
1. **Beta App Description**: Describe Watch features
2. **Feedback Email**: Your email
3. **Export Compliance**: Answer questions
   - If using encryption: Likely "Yes"
   - If only HTTPS: Select appropriate option

### Step 3: Add Testers
1. **Internal Testing** (Apple automatically distributes):
   - Add up to 100 team members
   - Immediate access after processing

2. **External Testing** (Requires Apple review):
   - Add up to 10,000 external testers
   - First build requires TestFlight review (~24-48 hours)
   - Submit for review with test information

## App Store Submission

### Step 1: Create New Version
1. App Store Connect → "App Store" tab
2. Click "+ Version" or "+ iOS App"
3. Enter version number (e.g., 1.3)

### Step 2: Complete App Information

#### Required Fields:
- **Screenshots** (iPhone + Watch)
- **Promotional Text** (170 characters)
- **Description** (4000 characters)
- **Keywords** (100 characters)
- **Support URL**
- **Marketing URL** (optional)
- **Version Information**:
  - What's New (mention Watch support)
  - Build selection (choose your uploaded build)

#### App Review Information:
- **Contact Information**
- **Demo Account** (if login required)
- **Notes** for reviewer:
  ```
  This version adds Apple Watch support. To test:
  1. Pair an Apple Watch with test device
  2. Install Watch app from iPhone
  3. Start any game mode in iOS app
  4. Tap Watch panel at bottom to expand controls
  5. Enable "Watch Mode" or tap "Request Input on Watch"
  6. Watch will display throw recording interface
  
  All game modes support Watch integration.
  ```

### Step 3: App Privacy
- Update privacy details if Watch collects any new data
- Review data collection practices
- Update privacy policy if needed

### Step 4: Submit for Review
1. Review all information
2. Click **"Add for Review"**
3. Click **"Submit to App Review"**
4. Select **"Manual Release"** or **"Automatic Release"**
5. Confirm submission

## Expected Timeline

- **Build Processing**: 15 minutes - 2 hours
- **TestFlight Beta Review** (first time): 24-48 hours
- **App Store Review**: 24-48 hours (can be faster or slower)
- **Total**: 2-4 days typically

## Common Issues & Solutions

### Issue 1: Missing Compliance
**Solution**: Answer export compliance questions in TestFlight

### Issue 2: Invalid Bundle
**Solution**: 
- Ensure both iOS and Watch app have same version/build numbers
- Verify all required architectures are included
- Check that Watch app is properly embedded

### Issue 3: Missing Entitlements
**Solution**: 
- Verify entitlements files are correct
- Check App Store Connect capabilities match code

### Issue 4: Missing Watch Screenshots
**Solution**: 
- Use Xcode simulator to capture Watch screenshots
- Required sizes: 40mm, 44mm, 45mm, 49mm
- Can use Xcode → Window → Devices and Simulators → Screenshot

### Issue 5: Build Processing Stuck
**Solution**: 
- Wait 2-3 hours
- If still stuck, contact Apple Developer Support
- Check email for processing errors

## Post-Submission Monitoring

### After Submission:
1. **Check Status**: App Store Connect → Activity tab
2. **Review Email**: Apple sends updates
3. **Status Updates**:
   - "Processing" → Build is being processed
   - "Ready to Submit" → Can add to app version
   - "Waiting for Review" → In queue
   - "In Review" → Being reviewed (usually 6-24 hours)
   - "Pending Developer Release" → Approved, ready to release
   - "Ready for Sale" → Live on App Store

### If Rejected:
1. Read rejection reason carefully
2. Address all issues mentioned
3. Use Resolution Center to communicate
4. Fix issues and resubmit
5. Common Watch-related rejections:
   - Missing Watch screenshots
   - Watch app not properly functional
   - Privacy issues
   - Incomplete What's New info about Watch

## Watch App Screenshots Guide

### Capturing Screenshots:
1. Open Xcode
2. Window → Devices and Simulators
3. Add Watch simulators if needed
4. Run app on Watch simulator
5. Navigate to feature
6. Cmd + S to save screenshot

### Required Sizes:
- **40mm** (Apple Watch Series 5/SE): 324 x 394 pixels
- **44mm** (Apple Watch Series 6/7/8): 368 x 448 pixels  
- **45mm** (Apple Watch Series 7/8/Ultra): 396 x 484 pixels
- **49mm** (Apple Watch Ultra): 410 x 502 pixels

### Screenshot Tips:
- Show Watch input interface
- Display baton throw recording
- Show session state on Watch
- Capture "Watch Mode" indicator
- Show sync between devices

## Helpful Commands

### Check Current Version:
```bash
/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "Kubb Manager/Info.plist"
/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "Kubb Manager/Info.plist"
```

### Validate Archive:
```bash
xcrun altool --validate-app \
  --file "KubbManager.ipa" \
  --type ios \
  --apiKey YOUR_KEY \
  --apiIssuer YOUR_ISSUER
```

### Check Entitlements:
```bash
codesign -d --entitlements :- "KubbManager.app"
```

## Resources

- [App Store Connect](https://appstoreconnect.apple.com)
- [Apple Developer Portal](https://developer.apple.com)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)

## Quick Checklist

- [ ] Version/build numbers updated
- [ ] Clean build successful
- [ ] Archive created with Watch app
- [ ] Uploaded to App Store Connect
- [ ] Build finished processing
- [ ] TestFlight configured
- [ ] Watch screenshots captured
- [ ] App Store listing updated
- [ ] What's New mentions Watch support
- [ ] App Review notes include Watch testing instructions
- [ ] Privacy information current
- [ ] Submitted for review

## Need Help?

If you encounter issues:
1. Check Apple Developer Forums
2. Review App Store Connect resolution center
3. Contact Apple Developer Support
4. Check Xcode console for specific errors

---

**Good luck with your submission! 🚀⌚📱**

