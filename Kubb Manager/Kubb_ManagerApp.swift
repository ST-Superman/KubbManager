//
//  Kubb_ManagerApp.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import SwiftUI

@main
struct Kubb_ManagerApp: App {
    @StateObject private var appInitializationManager = AppInitializationManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await appInitializationManager.initializeApp()
                }
        }
    }
}
