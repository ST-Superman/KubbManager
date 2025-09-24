//
//  SettingsManager.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import Foundation
import Combine
import UserNotifications

@MainActor
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    // MARK: - Debug Settings
    @Published var showDebugTools: Bool {
        didSet {
            UserDefaults.standard.set(showDebugTools, forKey: "showDebugTools")
        }
    }
    
    // MARK: - Cloud Sync Settings
    @Published var cloudSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(cloudSyncEnabled, forKey: "cloudSyncEnabled")
        }
    }
    
    @Published var syncOverWiFiOnly: Bool {
        didSet {
            UserDefaults.standard.set(syncOverWiFiOnly, forKey: "syncOverWiFiOnly")
        }
    }
    
    @Published var dataRetentionDays: Int {
        didSet {
            UserDefaults.standard.set(dataRetentionDays, forKey: "dataRetentionDays")
        }
    }
    
    // MARK: - Visual Preferences
    @Published var colorScheme: ColorSchemeOption {
        didSet {
            UserDefaults.standard.set(colorScheme.rawValue, forKey: "colorScheme")
        }
    }
    
    @Published var hapticFeedbackEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticFeedbackEnabled, forKey: "hapticFeedbackEnabled")
        }
    }
    
    // MARK: - Training Reminders
    @Published var trainingRemindersEnabled: Bool {
        didSet {
            UserDefaults.standard.set(trainingRemindersEnabled, forKey: "trainingRemindersEnabled")
            updateNotificationPermissions()
        }
    }
    
    @Published var weeklyTrainingTarget: Int {
        didSet {
            UserDefaults.standard.set(weeklyTrainingTarget, forKey: "weeklyTrainingTarget")
            updateTrainingSchedule()
        }
    }
    
    @Published var reminderTime: Date {
        didSet {
            UserDefaults.standard.set(reminderTime, forKey: "reminderTime")
            updateTrainingSchedule()
        }
    }
    
    enum ColorSchemeOption: String, CaseIterable {
        case system = "system"
        case light = "light"
        case dark = "dark"
        
        var displayName: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
    }
    
    private init() {
        // Debug Settings
        self.showDebugTools = UserDefaults.standard.bool(forKey: "showDebugTools")
        
        // Cloud Sync Settings
        self.cloudSyncEnabled = UserDefaults.standard.object(forKey: "cloudSyncEnabled") == nil ? true : UserDefaults.standard.bool(forKey: "cloudSyncEnabled")
        self.syncOverWiFiOnly = UserDefaults.standard.bool(forKey: "syncOverWiFiOnly")
        self.dataRetentionDays = UserDefaults.standard.object(forKey: "dataRetentionDays") == nil ? 365 : UserDefaults.standard.integer(forKey: "dataRetentionDays")
        
        // Visual Preferences
        let colorSchemeRaw = UserDefaults.standard.string(forKey: "colorScheme") ?? ColorSchemeOption.system.rawValue
        self.colorScheme = ColorSchemeOption(rawValue: colorSchemeRaw) ?? .system
        self.hapticFeedbackEnabled = UserDefaults.standard.object(forKey: "hapticFeedbackEnabled") == nil ? true : UserDefaults.standard.bool(forKey: "hapticFeedbackEnabled")
        
        // Training Reminders
        self.trainingRemindersEnabled = UserDefaults.standard.bool(forKey: "trainingRemindersEnabled")
        self.weeklyTrainingTarget = UserDefaults.standard.object(forKey: "weeklyTrainingTarget") == nil ? 3 : UserDefaults.standard.integer(forKey: "weeklyTrainingTarget")
        
        // Default reminder time to 6 PM
        let defaultTime = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
        self.reminderTime = UserDefaults.standard.object(forKey: "reminderTime") as? Date ?? defaultTime
    }
    
    // MARK: - Helper Methods
    
    private func updateNotificationPermissions() {
        // Request notification permissions when reminders are enabled
        if trainingRemindersEnabled {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                DispatchQueue.main.async {
                    if !granted {
                        self.trainingRemindersEnabled = false
                    }
                }
            }
        }
    }
    
    private func updateTrainingSchedule() {
        // Cancel existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        guard trainingRemindersEnabled else { return }
        
        // Create new notification schedule based on weekly target
        let content = UNMutableNotificationContent()
        content.title = "Kubb Training Reminder"
        content.body = "Time for your daily kubb practice! 🎯"
        content.sound = .default
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
        
        // Schedule notifications for each day of the week up to the target
        for dayOffset in 0..<weeklyTrainingTarget {
            var dateComp = dateComponents
            dateComp.weekday = (dayOffset % 7) + 1 // Sunday = 1, Monday = 2, etc.
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComp, repeats: true)
            let request = UNNotificationRequest(
                identifier: "kubbTrainingReminder_\(dayOffset)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    var weeklyTrainingDescription: String {
        switch weeklyTrainingTarget {
        case 1: return "Once per week"
        case 2: return "Twice per week (weekends)"
        case 3: return "3 times per week"
        case 4: return "4 times per week"
        case 5: return "5 times per week (weekdays)"
        case 6: return "6 times per week"
        case 7: return "Daily"
        default: return "\(weeklyTrainingTarget) times per week"
        }
    }
}
