# Kubb Practice Tracker - iOS App

A native Swift iOS application for tracking kubb practice sessions with CloudKit integration for seamless data synchronization across devices.

## Features

- **Daily Target Setting**: Set and track your daily kubb practice goals
- **Round-Based Tracking**: Track practice rounds with 6 kubbs per round
- **Real-Time Progress**: Visual progress bar and live statistics
- **Session Management**: Start, pause, resume, and complete practice sessions
- **CloudKit Sync**: Automatic synchronization across all your devices
- **Data Export**: Export session data in JSON or CSV format
- **Accessibility**: Full VoiceOver support for inclusive usage
- **Haptic Feedback**: Tactile feedback for better user experience

## CloudKit Setup

### 1. Apple Developer Portal Configuration

1. Log in to the [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select **Identifiers** and find your app identifier
4. Enable **CloudKit** capability
5. Go to **CloudKit Dashboard** and select your container: `iCloud.ST-Superman.Kubb-Manager`

### 2. CloudKit Schema Setup

In the CloudKit Dashboard, create the following record types:

#### PracticeSession Record Type
- **sessionId**: String (Indexed, Queryable)
- **date**: Date (Indexed, Queryable)
- **target**: Int64 (Indexed, Queryable)
- **totalKubbs**: Int64 (Indexed, Queryable)
- **totalBatons**: Int64 (Indexed, Queryable)
- **startTime**: Date (Indexed, Queryable)
- **endTime**: Date
- **isComplete**: Int64 (Indexed, Queryable)
- **createdAt**: Date (Indexed, Queryable)
- **modifiedAt**: Date (Indexed, Queryable)
- **rounds**: String (JSON data)

#### Round Record Type (Optional - stored as JSON in PracticeSession)
- **roundId**: String
- **sessionReference**: Reference to PracticeSession
- **roundNumber**: Int64
- **kubbStates**: String (JSON array of 6 booleans)
- **batonsUsed**: Int64
- **isComplete**: Int64

### 3. Xcode Project Configuration

The project is already configured with:
- CloudKit capability enabled in entitlements
- Container identifier: `iCloud.ST-Superman.Kubb-Manager`
- Proper CloudKit imports and setup

## Project Structure

```
Kubb Manager/
├── Models/
│   ├── PracticeSession.swift      # Session data model with CloudKit support
│   ├── Round.swift               # Round data model
│   └── CloudKitManager.swift     # CloudKit operations manager
├── ViewModels/
│   ├── SessionManager.swift      # Session state management
│   └── HistoryManager.swift      # Historical data management
├── Views/
│   ├── ContentView.swift         # Main navigation and app structure
│   ├── TargetSettingView.swift   # Target configuration screen
│   ├── PracticeView.swift        # Main practice tracking interface
│   ├── SessionResultsView.swift  # Session completion and results
│   └── HistoryView.swift         # Historical sessions and statistics
└── Assets.xcassets/              # App icons and colors
```

## Key Features Implementation

### Session Management
- **Auto-save**: Every baton throw is automatically saved to CloudKit
- **Session Recovery**: Incomplete sessions are automatically recovered on app launch
- **Cross-device Sync**: Sessions sync seamlessly across all signed-in devices
- **Offline Support**: Data is cached locally and syncs when connectivity returns

### User Interface
- **Native iOS Design**: Uses SF Symbols, native navigation, and iOS design patterns
- **Large Touch Targets**: HIT/MISS buttons optimized for practice use
- **Progress Visualization**: Real-time progress bars and statistics
- **Haptic Feedback**: Success/error feedback for baton results

### Data Persistence
- **CloudKit Integration**: Private database with automatic conflict resolution
- **Local Caching**: Offline capability with sync when online
- **Data Export**: JSON and CSV export with share sheet integration
- **Error Handling**: Comprehensive CloudKit error handling and retry logic

## Usage

### Starting a Practice Session
1. Open the app and navigate to the Practice tab
2. Set your daily target (default: 100 kubbs)
3. Tap "Start Practice Session"
4. Begin throwing batons and tap HIT or MISS for each throw

### During Practice
- The kubb grid shows current round progress (6 kubbs per round)
- Progress bar tracks overall session progress toward your target
- Statistics show real-time accuracy and baton count
- All data is automatically saved to CloudKit

### Session Completion
- Sessions auto-complete when target is reached
- Manual completion available via "End Session" button
- Results screen shows detailed statistics and round breakdown
- Data export available via share sheet

### Viewing History
- History tab shows all completed sessions
- Overall statistics and trends
- Individual session details and export options
- Data filtering and sorting capabilities

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Apple Developer Account with CloudKit capability
- iCloud account for data synchronization

## Installation

1. Clone the repository
2. Open `Kubb Manager.xcodeproj` in Xcode
3. Configure your Apple Developer Team ID
4. Set up CloudKit container in Apple Developer Portal
5. Build and run on device or simulator

## CloudKit Troubleshooting

### Common Issues

1. **"Not Authenticated" Error**
   - Ensure user is signed in to iCloud
   - Check CloudKit capability is enabled

2. **"Container Not Found" Error**
   - Verify container identifier matches in entitlements
   - Ensure container exists in CloudKit Dashboard

3. **Sync Issues**
   - Check network connectivity
   - Verify CloudKit schema matches code expectations
   - Check Apple Developer Portal for service status

### Development Tips

- Use CloudKit Dashboard to monitor record creation
- Test with multiple devices for sync verification
- Check console logs for CloudKit operation details
- Use development environment for testing, production for release

## Contributing

This is a personal project for kubb practice tracking. Feel free to fork and modify for your own use.

## License

Private project - All rights reserved.
