//
//  KubbManagerWatchApp.swift
//  Kubb Manager Watch
//
//  Created by AI Assistant on 10/8/25.
//

import SwiftUI
import UserNotifications

@main
struct KubbManagerWatchApp: App {
    @StateObject private var connectivityManager = WatchConnectivityManager.shared

    init() {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("⌚️ Notification permission error: \(error.localizedDescription)")
            } else {
                print("⌚️ Notification permission: \(granted ? "granted" : "denied")")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectivityManager)
        }
    }
}
