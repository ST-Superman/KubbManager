# TestFlight Debugging Guide - Viewing Console Logs on Real Devices

## Overview

When testing TestFlight builds on real devices (not connected to Xcode), you need different methods to view console logs. This guide covers all available options.

## Method 1: Xcode Devices Window (Recommended)

### Steps:

1. **Connect Device via USB**
   - Plug iPhone or Apple Watch (via iPhone) into Mac with cable
   - Unlock device and trust computer if prompted

2. **Open Devices Window**
   - Xcode → Window → Devices and Simulators (⇧⌘2)
   - Or: Xcode menu → Window → Devices and Simulators

3. **Select Your Device**
   - Click on your iPhone in left sidebar
   - For Watch logs: Select iPhone (Watch logs appear through paired iPhone)

4. **Open Console**
   - Click "Open Console" button in bottom right
   - New window opens showing live device logs

5. **Filter Logs**
   - In search box at top, type: `Kubb Manager` or `[iPhone]` or `[Watch]`
   - Use process filter dropdown to select "Kubb Manager"
   - Click "Start" to begin streaming logs

6. **Use Your App**
   - With console window open, use your app on device
   - Watch logs appear in real-time
   - Look for your custom log prefixes:
     - `📱 [iPhone]`
     - `⌚️ [Watch]`

### Tips:
- **Save logs**: Click "Save" button to export logs to file
- **Clear logs**: Click "Clear" to remove old logs
- **Pause/Resume**: Click "Pause" to stop streaming, then "Start" again
- **Search**: Use Cmd+F to search within logs

### Pros:
✅ Real-time streaming  
✅ Easy to use  
✅ Built into Xcode  
✅ Works for both iPhone and Watch  

### Cons:
❌ Requires USB connection  
❌ Can't view logs after disconnecting  
❌ Device must be unlocked initially  

---

## Method 2: Console.app (Mac)

Apple's Console app can view logs from connected devices without Xcode.

### Steps:

1. **Connect Device via USB**
   - Plug device into Mac
   - Unlock and trust computer

2. **Open Console App**
   - Applications → Utilities → Console.app
   - Or: Spotlight search for "Console"

3. **Select Device**
   - In left sidebar under "Devices", click your iPhone
   - For Watch: Select iPhone (Watch logs route through iPhone)

4. **Filter for Your App**
   - Click "Start" streaming button (top toolbar)
   - In search field, type: `process:Kubb Manager`
   - Or search for your log prefixes: `[iPhone]` or `[Watch]`

5. **Advanced Filtering**
   - Use predicates for precise filtering:
     ```
     process == "Kubb Manager" AND (messageType == "Default" OR messageType == "Error")
     ```
   - Filter by subsystem if you add os_log:
     ```
     subsystem == "com.yourcompany.KubbManager"
     ```

### Tips:
- **Save logs**: File → Export
- **Multiple devices**: View logs from multiple devices simultaneously
- **Time-based**: Jump to specific timestamps
- **Persist**: Logs saved even after device disconnects

### Pros:
✅ No Xcode required  
✅ More powerful filtering  
✅ Can save logs easily  
✅ Works across reboots  

### Cons:
❌ Still requires USB connection  
❌ More complex interface  
❌ Harder to parse in real-time  

---

## Method 3: Wireless Debugging (Xcode 13+)

View logs wirelessly if devices on same network.

### One-Time Setup:

1. **Enable Wireless Debugging**
   - Connect iPhone via USB first time
   - Xcode → Window → Devices and Simulators
   - Select your device
   - Check "Connect via network" checkbox
   - Wait for network icon to appear next to device

2. **Disconnect USB**
   - Unplug device
   - Device should remain in device list with network icon

### Using Wireless Logs:

1. **Open Console**
   - Xcode → Window → Devices and Simulators
   - Select wireless device
   - Click "Open Console"

2. **Filter and View**
   - Same as Method 1 above

### Tips:
- **Same WiFi**: Both Mac and iPhone must be on same network
- **Proximity**: Works best when devices are close
- **Battery**: Uses more battery than USB

### Pros:
✅ No cables required  
✅ Same Xcode interface  
✅ Real-time streaming  

### Cons:
❌ Initial USB setup required  
❌ Same network required  
❌ Can be slower/laggy  
❌ Uses more device battery  

---

## Method 4: OSLog with Structured Logging (Best for Production)

For TestFlight and production, implement structured logging with OSLog.

### Implementation:

```swift
import os.log

// Create custom log category
extension OSLog {
    private static var subsystem = Bundle.main.bundleIdentifier!
    
    static let watchConnectivity = OSLog(subsystem: subsystem, category: "WatchConnectivity")
    static let sessionManager = OSLog(subsystem: subsystem, category: "SessionManager")
    static let ui = OSLog(subsystem: subsystem, category: "UI")
}

// Usage in code
os_log("Watch reachability changed: %{public}@", 
       log: .watchConnectivity, 
       type: .info, 
       isReachable ? "true" : "false")

os_log("Failed to send message: %{public}@", 
       log: .watchConnectivity, 
       type: .error, 
       error.localizedDescription)
```

### Viewing OSLog Logs:

1. **In Console.app**:
   - Filter by subsystem: `subsystem:com.yourcompany.KubbManager`
   - Filter by category: `category:WatchConnectivity`

2. **In Xcode Console**:
   - Logs appear with category labels
   - Color-coded by severity

### Benefits:
- **Production safe**: Logs survive app deletion
- **Structured**: Easy to filter and analyze
- **Private data**: Automatically redacts sensitive info
- **Performance**: Efficient even with many logs

---

## Method 5: Third-Party Tools

### A. Proxyman / Charles Proxy
For network debugging:
- Intercept HTTPS traffic
- View API calls
- Not useful for WatchConnectivity (uses Bluetooth)

### B. Instruments
For performance profiling:
- Xcode → Open Developer Tool → Instruments
- Connect device and profile
- Not for real-time logging

### C. TestFlight Crash Reports
For crashes only:
- App Store Connect → TestFlight → Crashes
- Automatic crash reporting
- Not for console logs

---

## Method 6: In-App Debug Screen (Recommended for TestFlight)

Create an in-app debug screen to view logs without Mac connection.

### Implementation:

```swift
// Add to your app
class DebugLogManager: ObservableObject {
    @Published var logs: [String] = []
    static let shared = DebugLogManager()
    
    func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logEntry = "[\(timestamp)] \(message)"
        
        DispatchQueue.main.async {
            self.logs.insert(logEntry, at: 0)
            // Keep only last 100 logs
            if self.logs.count > 100 {
                self.logs.removeLast()
            }
        }
        
        // Also print to console
        print(message)
    }
}

// Debug View
struct DebugLogView: View {
    @StateObject var debugLog = DebugLogManager.shared
    
    var body: some View {
        NavigationView {
            List(debugLog.logs, id: \.self) { log in
                Text(log)
                    .font(.system(.caption, design: .monospaced))
            }
            .navigationTitle("Debug Logs")
            .toolbar {
                Button("Clear") {
                    debugLog.logs.removeAll()
                }
                Button("Export") {
                    exportLogs()
                }
            }
        }
    }
    
    private func exportLogs() {
        let logsText = debugLog.logs.joined(separator: "\n")
        // Use ShareSheet to export
        let activityVC = UIActivityViewController(activityItems: [logsText], applicationActivities: nil)
        // Present activity controller
    }
}

// Add to your watch connectivity manager
private func log(_ message: String) {
    let fullMessage = "📱 [iPhone] \(message)"
    print(fullMessage)
    DebugLogManager.shared.log(fullMessage)
}
```

### Access Debug Screen:

Add hidden gesture in your app:
```swift
// In your main view
.onLongPressGesture(minimumDuration: 3.0) {
    showDebugLogs = true
}
.sheet(isPresented: $showDebugLogs) {
    DebugLogView()
}
```

### Benefits:
✅ No Mac required  
✅ Works with TestFlight  
✅ Can share logs via email/message  
✅ Users can send you logs  
✅ Works offline  

---

## Practical Testing Workflow

### For Active Development:
1. Use **Method 1** (Xcode Devices Window)
2. Keep device connected via USB
3. Real-time log streaming
4. Quick iteration

### For TestFlight Testing:
1. Implement **Method 6** (In-App Debug Screen)
2. Test scenarios
3. Export logs from device
4. Email logs to yourself
5. Analyze on Mac

### For External Beta Testers:
1. Use **Method 6** with export
2. Ask testers to reproduce issue
3. Have them export and send logs
4. Bonus: Include screenshot capability

---

## Quick Reference

| Method | USB Required | Mac Required | Real-Time | Works Offline |
|--------|-------------|--------------|-----------|---------------|
| Xcode Devices | ✅ | ✅ | ✅ | ❌ |
| Console.app | ✅ | ✅ | ✅ | ❌ |
| Wireless Debug | ❌ | ✅ | ✅ | ❌ |
| OSLog | ✅ | ✅ | ✅ | ✅ (stored) |
| In-App Debug | ❌ | ❌ | ✅ | ✅ |

---

## Specific to Your App

### Viewing Watch Connectivity Logs:

1. **Connect iPhone to Mac via USB**

2. **Open Xcode Devices Window** (⇧⌘2)

3. **Open Console for iPhone**

4. **Filter with**: `[iPhone]` or `[Watch]`

5. **Look for these log patterns**:

   **iPhone logs**:
   ```
   📱 [iPhone] Watch session activated
   📱 [iPhone] Watch reachability changed: true
   📱 [iPhone] Queued message (priority: high, queue size: 1)
   📱 [iPhone] ✅ Received reply for message
   📱 [iPhone] Received baton throw result: isHit=true, kubbs=1
   📱 [iPhone] Sending session state update
   ```

   **Watch logs** (also appear on iPhone console):
   ```
   ⌚️ [Watch] Watch session activated: 2
   ⌚️ [Watch] 📱 Phone reachability changed: true
   ⌚️ [Watch] Received baton throw request: Baton 1
   ⌚️ [Watch] Sending result (attempt 1/3)...
   ⌚️ [Watch] ✅ Result delivered successfully
   ```

6. **Common Issues to Look For**:
   - `❌` - Error messages
   - `⏱️` - Timeout messages
   - `🔄` - Retry attempts
   - Repeated error patterns
   - Missing acknowledgments

---

## Troubleshooting Log Access

### Issue: No logs appearing
**Solutions**:
- Verify device is unlocked
- Check device is selected in devices list
- Click "Start" streaming button
- Check USB cable connection
- Try unplugging and replugging device
- Restart Xcode

### Issue: Too many logs
**Solutions**:
- Use process filter: Select "Kubb Manager" only
- Use text filter: Type `[iPhone]` or specific keywords
- Use category filter in Console.app
- Clear logs and start fresh

### Issue: Logs stop streaming
**Solutions**:
- Device may have locked - unlock it
- Click "Pause" then "Start" again
- Disconnect and reconnect device
- Restart Console/Xcode

### Issue: Can't find Watch logs
**Solution**:
- Watch logs route through paired iPhone
- Connect iPhone, not Watch directly
- Look for `[Watch]` prefix in iPhone console
- Verify Watch app is actually running

---

## Export and Share Logs

### From Xcode Console:
1. Click "Save" button
2. Choose location
3. Opens in Text Edit
4. Can share via email

### From Console.app:
1. File → Export
2. Choose format (text recommended)
3. Save and share

### From In-App Debug:
1. Open debug screen
2. Tap "Export"
3. Use Share Sheet
4. Send via Messages/Email/AirDrop

---

## Best Practices

### For Development:
1. **Use emoji prefixes**: Easy to visually scan
2. **Include context**: Device type, state, values
3. **Log errors verbosely**: Include error codes and messages
4. **Time-sensitive operations**: Log start and end
5. **State changes**: Log before and after

### For Production/TestFlight:
1. **Implement OSLog**: Structured, efficient
2. **Add debug screen**: For users to export
3. **Include session info**: Version, device model, OS version
4. **Privacy**: Don't log user data
5. **Log levels**: Use appropriate severity (info, debug, error)

### Sample Log Format:
```swift
private func log(_ message: String, type: LogType = .info) {
    let emoji = type.emoji
    let timestamp = Date().timeIntervalSince1970
    let formattedMessage = "\(emoji) [\(deviceType)] [\(timestamp)] \(message)"
    print(formattedMessage)
    DebugLogManager.shared.log(formattedMessage)
}

enum LogType {
    case info, success, error, retry, waiting
    
    var emoji: String {
        switch self {
        case .info: return "📱"
        case .success: return "✅"
        case .error: return "❌"
        case .retry: return "🔄"
        case .waiting: return "⏸️"
        }
    }
}
```

---

## Additional Resources

- [Apple Console.app Guide](https://developer.apple.com/documentation/os/logging)
- [Xcode Debugging Guide](https://developer.apple.com/documentation/xcode/running-your-app-in-the-simulator-or-on-a-device)
- [OSLog Documentation](https://developer.apple.com/documentation/os/logging)
- [TestFlight Best Practices](https://developer.apple.com/testflight/)

---

**Quick Answer**: Connect your iPhone to Mac via USB, open Xcode → Window → Devices and Simulators (⇧⌘2), select your iPhone, click "Open Console", then filter for `[iPhone]` or `[Watch]` to see your custom logs in real-time while using the TestFlight app.

