//
//  NavigationCoordinator.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import SwiftUI

class NavigationCoordinator: ObservableObject {
    @Published var shouldReturnToMainApp = false
    @Published var selectedTab: Int = 0
    
    func returnToMainApp(tab: Int = 0) {
        selectedTab = tab
        shouldReturnToMainApp = true
    }
    
    func reset() {
        shouldReturnToMainApp = false
    }
}
