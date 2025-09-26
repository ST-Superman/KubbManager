# CloudKit Setup Guide

## The Issue
You're getting CloudKit errors because the record types haven't been created in the CloudKit Dashboard yet. This is normal for a new CloudKit setup.

**Good News**: The app now has local storage fallback, so it works perfectly even without CloudKit setup!

## Quick Fix Steps

### 1. Open CloudKit Dashboard
1. Go to [developer.apple.com](https://developer.apple.com)
2. Sign in with your Apple Developer account
3. Navigate to **CloudKit Dashboard**

### 2. Select Your Container
1. Find and select: `iCloud.ST-Superman.Kubb-Manager`
2. If it doesn't exist, you may need to create it first

### 3. Create the PracticeSession Record Type
1. Click **Schema** in the left sidebar
2. Click **Record Types** tab
3. Click the **+** button to add a new record type
4. Name it: `PracticeSession`

### 4. Add Required Fields
Add these fields to the PracticeSession record type:

| Field Name | Type | Indexed | Queryable |
|------------|------|---------|-----------|
| sessionId | String | ✅ | ✅ |
| date | Date | ✅ | ✅ |
| target | Int64 | ✅ | ✅ |
| totalKubbs | Int64 | ✅ | ✅ |
| totalBatons | Int64 | ✅ | ✅ |
| startTime | Date | ✅ | ✅ |
| endTime | Date | ❌ | ❌ |
| isComplete | Int64 | ✅ | ✅ |
| createdAt | Date | ✅ | ✅ |
| modifiedAt | Date | ✅ | ✅ |
| rounds | String | ❌ | ❌ |

**Note**: The `recordName` field is automatically created by CloudKit and doesn't need to be added manually.

### 5. Deploy Schema
1. Click **Deploy Schema Changes** button
2. Select **Production** environment
3. Click **Deploy**

## Alternative: Use App Without CloudKit

The app now has local storage fallback, so you can use it without CloudKit setup:

1. **Local Storage**: All data is saved locally on your device
2. **No Sync**: Data won't sync across devices until CloudKit is set up
3. **Full Functionality**: All features work normally

## Testing the Fix

1. Build and run the app
2. Try starting a practice session
3. Record a few HIT/MISS results
4. Check that the sync status shows "iCloud Ready" instead of errors

## Troubleshooting

### If you still get errors:
1. **Wait 5-10 minutes** after deploying schema changes
2. **Check container identifier** matches exactly: `iCloud.ST-Superman.Kubb-Manager`
3. **Verify iCloud sign-in** on your device
4. **Try deleting and reinstalling** the app to clear any cached errors

### If CloudKit Dashboard shows no container:
1. Make sure CloudKit capability is enabled in your Xcode project
2. Check your Apple Developer Team ID matches
3. Ensure your app bundle identifier is correct

## Need Help?

The app will now gracefully handle CloudKit setup issues and save data locally until CloudKit is properly configured. You can use all features normally while setting up CloudKit in the background.
