//
//  KubbManagerWatchApp.swift
//  Kubb Manager Watch
//
//  Created by AI Assistant on 10/8/25.
//

import SwiftUI

@main
struct KubbManagerWatchApp: App {
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectivityManager)
        }
    }
}
