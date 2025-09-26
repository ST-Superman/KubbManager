# Kubb Manager

A comprehensive iOS training companion for Kubb players, designed to help you track your progress, improve your accuracy, and reach your practice goals.

![iOS](https://img.shields.io/badge/iOS-18.5+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)
![CloudKit](https://img.shields.io/badge/CloudKit-Enabled-green.svg)

## 🎯 Overview

Kubb Manager is a personal training app built for Kubb enthusiasts who want to improve their 8-meter throwing accuracy. The app provides a structured approach to practice sessions with detailed progress tracking, statistics, and CloudKit synchronization for seamless data backup across devices.

## ✨ Features

### 🏆 Training Modes
- **8-Meter Training**: Practice your precision throwing with customizable targets
- **Inkast & Blast Training**: Coming soon - Advanced throwing techniques
- **Full Game Simulation**: Coming soon - Complete game scenarios

### 📊 Progress Tracking
- **Real-time Statistics**: Track accuracy, total kubbs hit, and batons thrown
- **Session History**: View detailed history of all your practice sessions
- **Goal Setting**: Set daily targets and track your progress
- **Round Management**: Track individual rounds with baseline clears and king throws

### 🔄 Data Management
- **CloudKit Integration**: Automatic sync across all your iOS devices
- **Local Storage**: Works offline with local Core Data storage
- **Data Export**: Export your practice data as JSON or CSV
- **Duplicate Detection**: Automatic cleanup of duplicate records

### 📱 User Experience
- **Intuitive Interface**: Clean, modern SwiftUI design
- **Tutorial System**: Built-in guidance for new users
- **Session Recovery**: Resume interrupted practice sessions
- **Dark Mode Support**: Optimized for all iOS appearance modes

## 🚀 Getting Started

### Prerequisites
- iOS 18.5 or later
- Xcode 16.4 or later (for development)
- Apple Developer Account (for TestFlight/App Store distribution)

### Installation

#### For Users
The app is available through TestFlight for beta testing. Contact the developer for access.

#### For Developers
1. Clone the repository:
   ```bash
   git clone https://github.com/ST-Superman/KubbManager.git
   ```

2. Open the project in Xcode:
   ```bash
   open "Kubb Manager.xcodeproj"
   ```

3. Configure your development team in project settings

4. Build and run on your device or simulator

## 📖 How to Use

### Starting a Practice Session
1. Launch the app and navigate to the **8-Meter Training** section
2. Tap **"Start New Session"**
3. Set your daily target (number of kubbs to hit)
4. Begin throwing and tap **Hit** or **Miss** for each baton
5. Complete rounds by hitting all 5 kubbs, then attempt the king
6. Reach your target to complete the session

### Tracking Progress
- View real-time statistics during your session
- Check your overall progress in the **Overview** tab
- Review detailed session history in the **History** tab
- Monitor accuracy trends and improvement over time

### Data Synchronization
- Sign in to iCloud to enable automatic sync
- Your data will sync across all your iOS devices
- Sessions are stored locally and backed up to CloudKit

## 🏗️ Technical Architecture

### Core Technologies
- **SwiftUI**: Modern declarative UI framework
- **Core Data**: Local data persistence
- **CloudKit**: Cloud synchronization and backup
- **Combine**: Reactive programming for data flow

### Project Structure
```
Kubb Manager/
├── Models/           # Data models and business logic
│   ├── PracticeSession.swift
│   ├── Round.swift
│   ├── TrainingMode.swift
│   └── CloudKitManager.swift
├── ViewModels/       # Business logic and state management
│   ├── SessionManager.swift
│   ├── HistoryManager.swift
│   └── SettingsManager.swift
├── Views/           # SwiftUI views and UI components
│   ├── HomeView.swift
│   ├── PracticeView.swift
│   ├── HistoryView.swift
│   └── Tutorial views
└── Assets.xcassets/ # Images and app icons
```

### Key Components

#### SessionManager
Manages active practice sessions, handles round progression, and tracks statistics in real-time.

#### HistoryManager
Provides access to historical session data, statistics calculation, and data export functionality.

#### CloudKitManager
Handles all CloudKit operations including sync, conflict resolution, and duplicate detection.

## 🔧 Configuration

### CloudKit Setup
The app uses CloudKit for data synchronization. The container identifier is:
```
iCloud.ST-Superman.Kubb-Manager
```

### Bundle Configuration
- **Bundle ID**: `ST-Superman.Kubb-Manager`
- **Version**: 1.0
- **Build**: Increment for each TestFlight release

## 🧪 Testing

### TestFlight Distribution
The app is distributed through TestFlight for beta testing:
- Internal testing: Up to 100 team members
- External testing: Up to 10,000 testers (requires Apple review)

### Debug Features
Enable debug tools in settings to access:
- CloudKit connection testing
- Data cleanup utilities
- Sync status monitoring

## 📱 Screenshots

*Screenshots would be added here showing the main interface, practice view, and history tracking*

## 🛠️ Development

### Building for TestFlight
1. Update the build number in project settings
2. Archive the app in Xcode
3. Upload to App Store Connect
4. Add to TestFlight for testing

### Code Style
- Follow Swift API Design Guidelines
- Use SwiftUI best practices
- Maintain consistent naming conventions
- Include comprehensive documentation

## 📄 License

This project is a personal app developed for individual use. All rights reserved.

## 🤝 Contributing

This is a personal project, but feedback and suggestions are welcome. Please contact the developer with any issues or feature requests.

## 📞 Support

For support, questions, or bug reports:
- **Email**: sathomps@gmail.com
- **GitHub Issues**: https://github.com/ST-Superman/KubbManager/issues

## 🔮 Future Enhancements

- [ ] Inkast & Blast training mode
- [ ] Full game simulation
- [ ] Advanced statistics and analytics
- [ ] Training plans and recommendations
- [ ] Social features and leaderboards
- [ ] Remote Play
- [ ] Apple Watch companion app

## 📊 App Information

- **Developer**: Scott Thompson
- **Category**: Sports
- **Age Rating**: 4+ (No objectionable content)
- **Languages**: English
- **Device Support**: iPhone, iPad
- **Storage**: Minimal local storage + CloudKit sync

---

*Built with ❤️ for the Kubb community*
