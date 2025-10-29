//
//  KubbManagerWatchApp.swift
//  Kubb Manager Watch
//
//  Created by AI Assistant on 10/8/25.
//

import SwiftUI
import UserNotifications
import WatchConnectivity

@main
struct KubbManagerWatchApp: App {
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    @WKApplicationDelegateAdaptor private var appDelegate: WatchAppDelegate

    init() {
        print("⌚️ [WatchApp] App initializing...")

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

// Watch App Delegate to handle background tasks
class WatchAppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        print("⌚️ [WatchAppDelegate] App did finish launching")
        // Ensure WatchConnectivity is activated early
        _ = WatchConnectivityManager.shared
    }

    func applicationDidBecomeActive() {
        print("⌚️ [WatchAppDelegate] App did become active")
    }

    func applicationWillResignActive() {
        print("⌚️ [WatchAppDelegate] App will resign active")
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        print("⌚️ [WatchAppDelegate] Handling \(backgroundTasks.count) background tasks")

        for task in backgroundTasks {
            print("⌚️ [WatchAppDelegate] Task type: \(type(of: task))")

            switch task {
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                print("⌚️ [WatchAppDelegate] 🎯 WatchConnectivity background task received!")
                // Ensure connectivity manager processes any pending transfers
                _ = WatchConnectivityManager.shared
                connectivityTask.setTaskCompletedWithSnapshot(false)

            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                print("⌚️ [WatchAppDelegate] Snapshot task")
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)

            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                print("⌚️ [WatchAppDelegate] URL session task")
                urlSessionTask.setTaskCompletedWithSnapshot(false)

            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                print("⌚️ [WatchAppDelegate] Relevant shortcut task")
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)

            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                print("⌚️ [WatchAppDelegate] Intent did run task")
                intentDidRunTask.setTaskCompletedWithSnapshot(false)

            default:
                print("⌚️ [WatchAppDelegate] Other task type")
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}
