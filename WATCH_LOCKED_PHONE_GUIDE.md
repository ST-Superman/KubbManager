# Using Apple Watch with Locked iPhone

## TL;DR: Yes, It Works! 🎉

**You can absolutely use the watch to record throws while your iPhone is locked and in your pocket.** This is the primary intended use case.

## How It Works

### The Magic of WatchConnectivity

WatchConnectivity is specifically designed for this scenario:

1. **Background Communication**: The iOS app continues to receive and send messages even when locked
2. **Automatic Wake-Up**: When the watch sends a message, iOS wakes up your app to process it
3. **Seamless Experience**: From the user's perspective, everything "just works"

### Typical Session Flow

```
┌─────────────────────────────────────────────────────────────┐
│              Normal Usage Pattern                            │
└─────────────────────────────────────────────────────────────┘

1. Take out iPhone
   └─► Start session in Kubb Manager
   └─► Request first input on watch
   └─► See confirmation on watch

2. Lock iPhone and put in pocket
   └─► iPhone screen off
   └─► App running in background
   └─► Ready to receive watch messages

3. Look at watch
   └─► See input prompt
   └─► Record throw (HIT/MISS + count)
   └─► Watch sends to iPhone

4. iPhone (locked in pocket)
   └─► Receives message
   └─► Wakes up app
   └─► Processes throw
   └─► Updates stats
   └─► Sends next input request
   └─► Returns to background

5. Watch
   └─► Receives next input request
   └─► Shows new prompt
   └─► Ready for next throw

6. Repeat steps 3-5 for entire session

7. Take out iPhone when done
   └─► Unlock and view stats
   └─► End session
   └─► Review performance
```

## Technical Details

### What Happens When iPhone is Locked

```
Time    iPhone State              Watch State           Communication
────────────────────────────────────────────────────────────────────
0:00    Unlocked, session         App open              Connected
        started                   Waiting

0:05    User locks iPhone         Shows input           Connected
        → Screen off              prompt
        → App in background
        → WatchConnectivity 
          active

0:10    [LOCKED]                  User records          Watch → iPhone
        ← Receives message        throw                 Message sent
        → Wakes up app            
        → Processes result
        → Updates session
        → Sends next request      
        → Returns to sleep

0:11    [LOCKED]                  ← Receives request    iPhone → Watch
                                  Shows new prompt      Message sent

0:20    [LOCKED]                  User records          Watch → iPhone
        ← Receives message        another throw         Message sent
        → Wakes up app
        → Processes result
        → Sends next request
        → Returns to sleep

...     [LOCKED throughout]       [Continues recording] [Messages flow]

5:00    User unlocks              Session complete      Connected
        Views stats
        Ends session
```

### Background Execution

iOS provides your app with background execution time for:

1. **WatchConnectivity Messages**
   - iOS keeps your app alive to handle watch communication
   - App gets ~30 seconds to process each message
   - Plenty of time to update session and request next input

2. **State Preservation**
   - Session state is maintained in memory
   - All game logic continues to work
   - Stats are updated in real-time

3. **Efficient Power Usage**
   - App only wakes when needed (on message receipt)
   - Returns to sleep immediately after processing
   - Minimal battery impact

## What You Need to Know

### ✅ This Works Great

- **iPhone locked** - Messages still flow
- **iPhone in pocket** - No issues
- **iPhone screen off** - Perfectly fine
- **Long sessions** - iOS keeps app alive for watch communication
- **Multiple throws** - Each one wakes app, processes, returns to sleep

### ⚠️ This Doesn't Work

- **Force-quitting the iPhone app** - Breaks connection
  - Normal backgrounding/locking is fine
  - Don't swipe up to close the app

- **Backgrounding the watch app** - You won't see prompts
  - Keep watch app in foreground during session
  - This is natural since you're using it

- **Airplane mode** - Disables Bluetooth
  - Need Bluetooth for watch communication

## Battery Life

### iPhone (Locked)
- **Minimal impact** - Only wakes for messages
- **Efficient** - Returns to sleep immediately
- **Tested** - Similar to having a workout app running

### Apple Watch
- **Normal usage** - Similar to any active watch app
- **Efficient messaging** - Small data packets
- **Screen on/off** - Watch screen can sleep between throws

### Tips for Long Sessions
1. Start with good battery on both devices
2. Enable Low Power Mode on iPhone if needed (watch communication still works)
3. Let watch screen sleep between throws (raise to wake will show current prompt)

## Testing Recommendations

### Basic Test (5 minutes)
```
1. Start session on iPhone
2. Request input on watch
3. Lock iPhone
4. Record 5-10 throws on watch
5. Unlock iPhone
6. Verify all throws were recorded
```

### Extended Test (30 minutes)
```
1. Start session on iPhone
2. Lock iPhone and put in pocket
3. Complete full training session using only watch
4. Take out iPhone
5. Verify complete session data
```

### Real-World Test
```
1. Go to kubb pitch
2. Start session on iPhone
3. Lock iPhone and put in pocket
4. Play actual game/practice
5. Record all throws on watch
6. Review stats on iPhone after
```

## Troubleshooting

### "Watch Not Reachable" Error

**Cause**: Bluetooth connection lost

**Solutions**:
- Ensure Bluetooth is enabled on iPhone
- Keep watch within ~30 feet of iPhone
- Check that watch isn't in Airplane Mode
- Restart Bluetooth on iPhone

**Note**: This is rare during normal use with phone in pocket

### Messages Not Arriving

**Cause**: App was force-quit or connection lost

**Solutions**:
- Don't force-quit the iPhone app
- Ensure watch app is in foreground
- Check connection status on watch
- Restart both apps if needed

### Delayed Prompts on Watch

**Cause**: Watch app was backgrounded

**Solutions**:
- Keep watch app in foreground during session
- If backgrounded, return to app to see pending prompts
- Messages queue and deliver when app returns to foreground

## Best Practices

### Starting a Session

```swift
// On iPhone
1. Open Kubb Manager
2. Start your training mode
3. Tap "Request Input on Watch"
4. Wait for confirmation on watch
5. Lock iPhone ← Safe to lock now!
6. Put iPhone in pocket
```

### During Session

```
On Watch:
1. Keep Kubb Manager app open (don't switch apps)
2. Record throws as prompted
3. Watch for next prompt after each throw
4. Glance at session status between throws

iPhone:
- Stays locked in pocket
- Receives and processes all data
- Sends next prompts automatically
- No interaction needed
```

### Ending Session

```
1. Complete your training
2. Take out iPhone
3. Unlock and open Kubb Manager
4. View stats and session summary
5. End session
6. Review performance
```

## Real-World Scenarios

### Scenario 1: Solo Practice
```
You: Practicing 8-meter throws alone
Phone: Locked in pocket
Watch: Recording each throw
Result: Complete session data without touching phone
```

### Scenario 2: Game Play
```
You: Playing Baseball Kubb with friends
Phone: Locked in bag
Watch: Recording each baton throw
Result: Full game stats without interrupting play
```

### Scenario 3: Tournament
```
You: Competing in tournament
Phone: Locked in pocket (tournament rules)
Watch: Discreet recording of performance
Result: Detailed stats for post-game analysis
```

## Advantages of Locked Phone Usage

### For User Experience
1. **Hands-Free** - No need to handle phone
2. **Quick** - Faster than unlocking phone each time
3. **Convenient** - Phone stays protected in pocket
4. **Focused** - Stay focused on game, not device

### For Game Play
1. **Unobtrusive** - Watch is less distracting
2. **Fast Recording** - Quick button taps
3. **No Interruption** - Game flow continues
4. **Weather Proof** - Phone protected from elements

### For Social Situations
1. **Less Awkward** - Not constantly on phone
2. **More Engaged** - Focus on game and friends
3. **Professional** - Discrete data collection
4. **Tournament Friendly** - Complies with phone restrictions

## Summary

### ✅ YES - This Works Perfectly

**Your iPhone can be locked and in your pocket throughout the entire session.** This is not just supported—it's the primary intended use case.

### How to Use
1. Start session on iPhone
2. Request input on watch
3. **Lock iPhone and put away**
4. Record throws on watch
5. Take out iPhone when done to view stats

### Why It Works
- WatchConnectivity designed for this
- iOS keeps app alive for watch messages
- Background processing handles everything
- Efficient and battery-friendly

### What to Remember
- ✅ Lock iPhone - Works great
- ✅ Put in pocket - No problem
- ✅ Long sessions - Fully supported
- ⚠️ Keep watch app open - Don't background it
- ❌ Don't force-quit iPhone app - Breaks connection

**You're good to go! Lock that phone and focus on your game.** 🎯
