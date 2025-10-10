# Apple Watch Architecture Diagram

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         KUBB MANAGER                             │
│                    Apple Watch Integration                       │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────┐         ┌──────────────────────────┐
│      iPhone App          │         │      Apple Watch         │
│                          │         │                          │
│  ┌────────────────────┐  │         │  ┌────────────────────┐  │
│  │  Session Managers  │  │         │  │   ContentView      │  │
│  │  ┌──────────────┐  │  │         │  │  (Session Status)  │  │
│  │  │ 8M Training  │  │  │         │  └────────────────────┘  │
│  │  │ Inkast Blast │  │  │         │           │              │
│  │  │ Baseball Kubb│  │  │         │           ▼              │
│  │  │ Full Game Sim│  │  │         │  ┌────────────────────┐  │
│  │  └──────────────┘  │  │         │  │  Input Views       │  │
│  │         │          │  │         │  │  ┌──────────────┐  │  │
│  │         ▼          │  │         │  │  │ Baton Throw  │  │  │
│  │  ┌──────────────┐  │  │         │  │  │   Input      │  │  │
│  │  │Watch Connect │  │  │◄───────►│  │  └──────────────┘  │  │
│  │  │   Manager    │  │  │  BLE    │  │  ┌──────────────┐  │  │
│  │  └──────────────┘  │  │         │  │  │   Inkast     │  │  │
│  └────────────────────┘  │         │  │  │   Input      │  │  │
│           │              │         │  │  └──────────────┘  │  │
│           ▼              │         │  └────────────────────┘  │
│  ┌────────────────────┐  │         │           │              │
│  │  Watch UI          │  │         │           ▼              │
│  │  Components        │  │         │  ┌────────────────────┐  │
│  └────────────────────┘  │         │  │Watch Connect       │  │
│                          │         │  │   Manager          │  │
└──────────────────────────┘         │  └────────────────────┘  │
                                     │                          │
                                     └──────────────────────────┘
```

## Data Flow Diagram

### Baton Throw Recording Flow

```
┌──────────────────────────────────────────────────────────────────────┐
│                      BATON THROW FLOW                                 │
└──────────────────────────────────────────────────────────────────────┘

iPhone                                                     Apple Watch
  │                                                              │
  │ 1. User starts session                                      │
  ├──────────────────────────────────────────────────────────►  │
  │    Message: sessionStarted                                  │
  │    Data: { sessionType, isActive }                          │
  │                                                              │
  │                                                              │ Display
  │                                                              │ session
  │                                                              │ status
  │                                                              │
  │ 2. Request baton input                                      │
  ├──────────────────────────────────────────────────────────►  │
  │    Message: requestInput                                    │
  │    Data: {                                                  │
  │      inputType: "batonThrow",                              │
  │      promptText: "Baton 1 of 6",                           │
  │      allowKubbCount: true,                                 │
  │      maxKubbs: 5                                           │
  │    }                                                        │
  │                                                              │
  │                                                              │ Show
  │                                                              │ input
  │                                                              │ screen
  │                                                              │
  │                                                              │ User
  │                                                              │ taps
  │                                                              │ HIT + 2
  │                                                              │
  │ 3. Receive result                                           │
  │  ◄──────────────────────────────────────────────────────────┤
  │    Message: batonThrowResult                                │
  │    Data: {                                                  │
  │      isHit: true,                                           │
  │      kubbsHit: 2,                                           │
  │      timestamp: Date()                                      │
  │    }                                                        │
  │                                                              │
  │ Process result                                              │
  │ (interpret based                                            │
  │  on game state)                                             │
  │                                                              │
  │ Update stats                                                │
  │                                                              │
  │ 4. Request next input                                       │
  ├──────────────────────────────────────────────────────────►  │
  │    Message: requestInput                                    │
  │    Data: { ... }                                            │
  │                                                              │
  ▼                                                              ▼
```

### Inkast Recording Flow

```
┌──────────────────────────────────────────────────────────────────────┐
│                        INKAST FLOW                                    │
└──────────────────────────────────────────────────────────────────────┘

iPhone                                                     Apple Watch
  │                                                              │
  │ 1. Request first attempt count                              │
  ├──────────────────────────────────────────────────────────►  │
  │    Message: requestInput                                    │
  │    Data: {                                                  │
  │      inputType: "inkast",                                   │
  │      promptText: "Out of bounds\n(1st attempt)?",          │
  │      maxCount: 5,                                           │
  │      inkastType: "first_attempt_out"                       │
  │    }                                                        │
  │                                                              │
  │                                                              │ User
  │                                                              │ sets
  │                                                              │ count: 2
  │                                                              │
  │ 2. Receive result                                           │
  │  ◄──────────────────────────────────────────────────────────┤
  │    Message: inkastResult                                    │
  │    Data: {                                                  │
  │      count: 2,                                              │
  │      inkastType: "first_attempt_out"                       │
  │    }                                                        │
  │                                                              │
  │ Process: 2 kubbs out                                        │
  │                                                              │
  │ 3. Request second attempt count                             │
  ├──────────────────────────────────────────────────────────►  │
  │    Message: requestInput                                    │
  │    Data: {                                                  │
  │      inputType: "inkast",                                   │
  │      promptText: "Out of bounds\n(2nd attempt)?",          │
  │      maxCount: 2,                                           │
  │      inkastType: "second_attempt_out"                      │
  │    }                                                        │
  │                                                              │
  │                                                              │ User
  │                                                              │ sets
  │                                                              │ count: 1
  │                                                              │
  │ 4. Receive result                                           │
  │  ◄──────────────────────────────────────────────────────────┤
  │    Data: { count: 1, inkastType: "second_attempt_out" }    │
  │                                                              │
  │ Process: 1 penalty kubb                                     │
  │                                                              │
  │ 5. Request neighbor count                                   │
  ├──────────────────────────────────────────────────────────►  │
  │    Data: {                                                  │
  │      promptText: "How many\nneighbors?",                   │
  │      maxCount: 4,                                           │
  │      inkastType: "neighbors"                               │
  │    }                                                        │
  │                                                              │
  │ 6. Receive result                                           │
  │  ◄──────────────────────────────────────────────────────────┤
  │    Data: { count: 0, inkastType: "neighbors" }             │
  │                                                              │
  │ Complete inkast phase                                       │
  │ Move to blasting                                            │
  │                                                              │
  ▼                                                              ▼
```

## Component Architecture

### iPhone App Components

```
┌─────────────────────────────────────────────────────────────┐
│                    iPhone App Layers                         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      UI Layer                                │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  WatchConnectivityView.swift                         │   │
│  │  - WatchConnectivityStatusView                       │   │
│  │  - WatchInputButton                                  │   │
│  │  - WatchSessionControlPanel                          │   │
│  │  - CompactWatchButton                                │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                  ViewModel Layer                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Session Manager Extensions                          │   │
│  │  - SessionManager+WatchConnectivity                  │   │
│  │  - InkastBlastSessionManager+WatchConnectivity       │   │
│  │  - BaseballKubbSessionManager+WatchConnectivity      │   │
│  │  - FullGameSimSessionManager+WatchConnectivity       │   │
│  │                                                       │   │
│  │  Implements: WatchCommunicationDelegate              │   │
│  │  - didReceiveBatonThrowResult()                      │   │
│  │  - didReceiveInkastResult()                          │   │
│  │  - didRequestSessionState()                          │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                 Connectivity Layer                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  WatchConnectivityManager.swift                      │   │
│  │  - Manages WCSession                                 │   │
│  │  - Sends input requests                              │   │
│  │  - Receives results                                  │   │
│  │  - Handles connectivity state                        │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    Model Layer                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  WatchCommunication.swift (Shared)                   │   │
│  │  - WatchInputType                                    │   │
│  │  - BatonThrowContext / Result                        │   │
│  │  - InkastContext / Result                            │   │
│  │  - WatchSessionState                                 │   │
│  │  - WatchMessage enum                                 │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Watch App Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Watch App Layers                          │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      App Layer                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  KubbManagerWatchApp.swift                           │   │
│  │  - @main entry point                                 │   │
│  │  - Initializes WatchConnectivityManager              │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                      UI Layer                                │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  ContentView.swift                                   │   │
│  │  - Session status display                            │   │
│  │  - Connection status                                 │   │
│  │  - Pending input notification                        │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  BatonThrowInputView.swift                           │   │
│  │  - Hit/Miss buttons                                  │   │
│  │  - Kubb count picker                                 │   │
│  │  - Digital Crown support                             │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  InkastInputView.swift                               │   │
│  │  - Count picker (0 to max)                           │   │
│  │  - +/- buttons                                       │   │
│  │  - Quick select buttons                              │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                 Connectivity Layer                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  WatchConnectivityManager.swift                      │   │
│  │  - Manages WCSession                                 │   │
│  │  - Receives input requests                           │   │
│  │  - Sends results                                     │   │
│  │  - Manages pending input state                       │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    Model Layer                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  WatchCommunication.swift (Shared)                   │   │
│  │  - Same models as iPhone                             │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## State Management

### Session State Synchronization

```
┌────────────────────────────────────────────────────────────┐
│              Session State Lifecycle                        │
└────────────────────────────────────────────────────────────┘

iPhone State                          Watch State
     │                                     │
     │ Session Started                    │
     ├────────────────────────────────────►│
     │                                     │ Update UI
     │                                     │ Show session
     │                                     │
     │ Round Complete                     │
     ├────────────────────────────────────►│
     │                                     │ Update round
     │                                     │ number
     │                                     │
     │ Phase Change                       │
     ├────────────────────────────────────►│
     │ (Inkast → Blasting)                │ Update phase
     │                                     │ display
     │                                     │
     │ Session Ended                      │
     ├────────────────────────────────────►│
     │                                     │ Clear state
     │                                     │ Show "No
     │                                     │ Session"
     │                                     │
     │ Watch Becomes Reachable            │
     │ ◄────────────────────────────────────┤
     │                                     │ Request
     │                                     │ current state
     │                                     │
     │ Send Current State                 │
     ├────────────────────────────────────►│
     │                                     │ Sync state
     │                                     │
     ▼                                     ▼
```

## Message Protocol

### Message Types

```
┌────────────────────────────────────────────────────────────┐
│                    Message Types                            │
└────────────────────────────────────────────────────────────┘

Phone → Watch:
├── sessionStarted
│   └── WatchSessionState
├── sessionEnded
├── requestInput
│   ├── BatonThrowContext
│   └── InkastContext
├── sessionStateUpdate
│   └── WatchSessionState
└── acknowledgment

Watch → Phone:
├── batonThrowResult
│   └── BatonThrowResult
├── inkastResult
│   └── InkastResult
├── requestSessionState
└── acknowledgment

Bidirectional:
└── error
    └── error message string
```

### Message Format Examples

```json
// Session Started
{
  "messageType": "session_started",
  "sessionType": "8M Training",
  "isActive": true,
  "currentRound": 1
}

// Request Baton Input
{
  "messageType": "request_input",
  "inputType": "batonThrow",
  "promptText": "Baton 1 of 6",
  "allowKubbCount": false,
  "maxKubbs": 1,
  "batonNumber": 1,
  "totalBatons": 6
}

// Baton Throw Result
{
  "messageType": "baton_throw_result",
  "isHit": true,
  "kubbsHit": 1,
  "timestamp": 1696780800.0
}

// Request Inkast Input
{
  "messageType": "request_input",
  "inputType": "inkast",
  "promptText": "Out of bounds\n(1st attempt)?",
  "maxCount": 5,
  "inkastType": "first_attempt_out"
}

// Inkast Result
{
  "messageType": "inkast_result",
  "count": 2,
  "inkastType": "first_attempt_out",
  "timestamp": 1696780800.0
}
```

## Error Handling

```
┌────────────────────────────────────────────────────────────┐
│                   Error Scenarios                           │
└────────────────────────────────────────────────────────────┘

Scenario: Watch Not Reachable
├── Detection: WCSession.isReachable == false
├── iPhone Action:
│   ├── Show "Watch not reachable" message
│   ├── Disable watch input buttons
│   └── Continue allowing phone input
└── Watch Action:
    ├── Show "iPhone not reachable" message
    └── Queue messages for when connection restored

Scenario: Message Send Failure
├── Detection: WCSession.sendMessage() error
├── Action:
│   ├── Log error
│   ├── Show user-friendly error message
│   └── Retry with exponential backoff
└── Fallback: Use transferUserInfo() for queued delivery

Scenario: Invalid Message Format
├── Detection: Missing required fields
├── Action:
│   ├── Log detailed error
│   ├── Send error message to sender
│   └── Request session state resync
└── Recovery: Automatic state synchronization

Scenario: Session State Mismatch
├── Detection: Watch shows different state than phone
├── Action:
│   ├── Watch requests current state
│   ├── Phone sends full state update
│   └── Watch updates UI
└── Prevention: Regular state sync on connectivity change
```

---

*This architecture provides a robust, scalable foundation for Apple Watch integration with clear separation of concerns and reliable error handling.*
