# Apple Watch Integration for Kubb Manager

## Quick Start

This implementation adds Apple Watch support to Kubb Manager, allowing users to record baton throws and inkast data directly from their wrist.

## What's Included

### ✅ Complete Implementation
- **Shared Data Models**: Communication structures for phone-watch messaging
- **Phone-Side Managers**: WatchConnectivity integration for all game modes
- **Watch App UI**: Complete SwiftUI interface for Apple Watch
- **Documentation**: Setup guides and testing procedures

### ✅ Supported Game Modes
- 8-Meter Training
- Inkast & Blast
- Baseball Kubb
- Full Game Simulation

## Next Steps

### 1. Add Watch App Target
Follow the detailed instructions in `WATCH_APP_SETUP_GUIDE.md` to:
- Create the Watch app target in Xcode
- Configure bundle identifiers
- Set up provisioning profiles
- Add shared files to both targets

### 2. Add Watch App Files
Copy all files from the `Watch App/` folder to your Watch target:
- `KubbManagerWatchApp.swift`
- `ContentView.swift`
- `BatonThrowInputView.swift`
- `InkastInputView.swift`
- `WatchConnectivityManager.swift`

### 3. Enable Watch Controls in iOS App
Add watch controls to your existing views. Example for 8-Meter Training:

```swift
// In PracticeView.swift or similar
import SwiftUI

struct PracticeView: View {
    @EnvironmentObject var sessionManager: SessionManager
    
    var body: some View {
        VStack {
            // ... existing UI ...
            
            // Add watch control panel
            if sessionManager.isSessionActive {
                WatchSessionControlPanel(
                    sessionType: "8M Training",
                    onStartWatchInput: {
                        sessionManager.requestWatchBatonInput()
                    },
                    onSendSessionState: {
                        sessionManager.sendSessionStateToWatch()
                    }
                )
            }
        }
        .onAppear {
            // Setup watch connectivity
            sessionManager.setupWatchConnectivity()
            
            // Notify watch if session is active
            if sessionManager.isSessionActive {
                sessionManager.notifyWatchSessionStarted()
            }
        }
    }
}
```

### 4. Test
1. Run the iOS app on a simulator or device
2. Run the Watch app (it will automatically pair with the iOS app in simulator)
3. Start a session on the phone
4. Open the watch app
5. Request input from the phone
6. Record throws on the watch
7. Verify data syncs back to the phone

## Architecture Overview

### Two Universal Input Types

The watch provides two simple input screens:

1. **Baton Throw Input**
   - Hit or Miss buttons
   - Optional kubb count (using Digital Crown or +/- buttons)
   - Used by: All game modes

2. **Inkast Input**
   - Count input (0 to max)
   - Context-specific prompts
   - Used by: Inkast & Blast, Full Game Simulation

### Phone Handles All Logic

The phone app:
- Manages all game state
- Interprets watch inputs based on current game context
- Requests appropriate input type from watch
- Updates statistics and UI

### Benefits

- ✅ **Simple Watch UI**: Only 2 input screens for all game modes
- ✅ **Scalable**: New game modes require zero watch code changes
- ✅ **Maintainable**: Complex logic stays on phone
- ✅ **User-Friendly**: Intuitive watch interface

## File Structure

```
Kubb Manager/
├── Models/
│   └── WatchCommunication.swift          ← Shared with Watch
│
├── ViewModels/
│   ├── WatchConnectivityManager.swift    ← Phone-side manager
│   ├── SessionManager+WatchConnectivity.swift
│   ├── InkastBlastSessionManager+WatchConnectivity.swift
│   ├── BaseballKubbSessionManager+WatchConnectivity.swift
│   └── FullGameSimSessionManager+WatchConnectivity.swift
│
└── Views/
    └── WatchConnectivityView.swift       ← UI components

Watch App/
├── KubbManagerWatchApp.swift             ← App entry point
├── ContentView.swift                     ← Main view
├── BatonThrowInputView.swift             ← Baton input screen
├── InkastInputView.swift                 ← Inkast input screen
└── WatchConnectivityManager.swift        ← Watch-side manager
```

## Documentation

- **`WATCH_APP_SETUP_GUIDE.md`**: Step-by-step Xcode setup instructions
- **`WATCH_IMPLEMENTATION_SUMMARY.md`**: Complete technical documentation
- **`WATCH_README.md`**: This file (quick start guide)

## Testing Checklist

Use this checklist to verify the implementation:

### Basic Functionality
- [ ] Watch app installs and launches
- [ ] Phone and watch connect
- [ ] Session state syncs to watch
- [ ] Baton throw input works
- [ ] Inkast input works
- [ ] Results sync back to phone

### Game Modes
- [ ] 8-Meter Training
- [ ] Inkast & Blast
- [ ] Baseball Kubb
- [ ] Full Game Simulation

### Edge Cases
- [ ] Watch disconnects mid-session
- [ ] iPhone locked/in pocket (normal use case - should work perfectly)
- [ ] Watch app backgrounds (user must return to app to see prompts)
- [ ] Cancel input on watch
- [ ] Multiple rapid inputs

## Common Issues

### Watch App Not Showing
- Ensure watch is paired and unlocked
- Check "Show App on Apple Watch" in iPhone Watch app
- Try restarting both devices

### Connectivity Not Working
- Verify Bluetooth is enabled
- Ensure both apps are running (not backgrounded)
- Check console logs for errors

### Build Errors
- Clean build folder (Cmd+Shift+K)
- Verify `WatchCommunication.swift` is in both targets
- Check bundle identifiers match expected format

## Support

For detailed technical information, see:
- `WATCH_IMPLEMENTATION_SUMMARY.md` - Complete architecture and API docs
- `WATCH_APP_SETUP_GUIDE.md` - Xcode configuration steps

## What's Next

After basic implementation is working:

1. **Add to All Views**: Integrate watch controls into all game mode views
2. **Customize Prompts**: Tailor watch prompts for each game mode
3. **Add Complications**: Show active session on watch face
4. **Voice Input**: "Hey Siri, record a hit"
5. **Watch Notifications**: Alert user when round completes

## Example Usage

### Starting a Watch-Enabled Session

```swift
// 1. Start session normally
sessionManager.startNewSession(target: 100)

// 2. Setup watch connectivity
sessionManager.setupWatchConnectivity()

// 3. Notify watch
sessionManager.notifyWatchSessionStarted()

// 4. Request first input (optional)
sessionManager.requestWatchBatonInput()
```

### Handling Watch Input

The session manager extensions automatically handle watch input:

```swift
// This is already implemented in SessionManager+WatchConnectivity.swift
func didReceiveBatonThrowResult(_ result: BatonThrowResult) {
    Task {
        await addBatonResult(isHit: result.isHit)
        
        // Automatically request next input if round not complete
        if !isRoundComplete {
            requestWatchBatonInput()
        }
    }
}
```

## Implementation Status

✅ **Complete and Ready for Integration**

All code has been written and is ready to use. The only remaining step is to:
1. Create the Watch app target in Xcode (5 minutes)
2. Add the Watch app files to the target (2 minutes)
3. Test the implementation (15 minutes)

Total setup time: ~20-25 minutes

## License

This implementation is part of the Kubb Manager app.
