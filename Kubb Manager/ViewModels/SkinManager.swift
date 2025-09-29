//
//  SkinManager.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class SkinManager: ObservableObject {
    static let shared = SkinManager()
    
    @Published var selectedKubbSkin: KubbSkin
    @Published var selectedKingSkin: KubbSkin
    @Published var selectedBatonSkin: KubbSkin
    @Published var availableSkins: [KubbSkin] = []
    @Published var unlockedSkins: Set<String> = []
    
    private let userDefaults = UserDefaults.standard
    private let selectedKubbSkinKey = "selectedKubbSkin"
    private let selectedKingSkinKey = "selectedKingSkin"
    private let selectedBatonSkinKey = "selectedBatonSkin"
    private let unlockedSkinsKey = "unlockedSkins"
    
    private init() {
        // Initialize with default skins
        self.availableSkins = KubbSkin.defaultSkins
        
        // Unlock all skins by default (achievements disabled)
        self.unlockedSkins = Set(KubbSkin.defaultSkins.map { $0.id })
        
        // Initialize with Classic Blue package (default)
        let classicBlueSkin = KubbSkin.defaultSkins.first { $0.id == "classic_blue" } ?? KubbSkin.defaultSkins.first!
        self.selectedKubbSkin = classicBlueSkin
        self.selectedKingSkin = classicBlueSkin
        self.selectedBatonSkin = classicBlueSkin
        
        // Now that all properties are initialized, load saved selections
        if let savedKubbSkin = loadSelectedSkin(for: selectedKubbSkinKey) {
            self.selectedKubbSkin = savedKubbSkin
        }
        if let savedKingSkin = loadSelectedSkin(for: selectedKingSkinKey) {
            self.selectedKingSkin = savedKingSkin
        }
        if let savedBatonSkin = loadSelectedSkin(for: selectedBatonSkinKey) {
            self.selectedBatonSkin = savedBatonSkin
        }
        
        // Load unlocked skins
        loadUnlockedSkins()
        
        // Update skin unlock status
        updateSkinUnlockStatus()
    }
    
    // MARK: - Skin Selection
    
    func selectKubbSkin(_ skin: KubbSkin) {
        selectedKubbSkin = skin
        saveSelectedSkin(skin, for: selectedKubbSkinKey)
    }
    
    func selectKingSkin(_ skin: KubbSkin) {
        selectedKingSkin = skin
        saveSelectedSkin(skin, for: selectedKingSkinKey)
    }
    
    func selectBatonSkin(_ skin: KubbSkin) {
        selectedBatonSkin = skin
        saveSelectedSkin(skin, for: selectedBatonSkinKey)
    }
    
    // MARK: - Skin Unlocking
    
    func unlockSkin(_ skinId: String) {
        unlockedSkins.insert(skinId)
        saveUnlockedSkins()
        updateSkinUnlockStatus()
    }
    
    func isSkinUnlocked(_ skinId: String) -> Bool {
        // All skins are now unlocked by default
        return true
    }
    
    func checkAndUnlockSkins() async {
        // DISABLED: All skins are now unlocked by default
        // No achievement or premium unlock checking needed
        // This method is kept for compatibility but does nothing
        return
    }
    
    private func shouldUnlockSkin(_ skin: KubbSkin) async -> Bool {
        // DISABLED: All skins are now unlocked by default
        // Always return true since all skins should be available
        return true
    }
    
    private func checkAchievementRequirement(_ requirement: String) async -> Bool {
        // This would integrate with your existing achievement system
        // For now, we'll implement basic checks
        
        let historyManager = HistoryManager()
        
        switch requirement {
        case "Complete 10 practice sessions":
            return historyManager.totalSessions >= 10
        case "Achieve 80% accuracy in 8-meter training":
            return historyManager.overallAccuracy >= 0.8
        case "Hit 100 king kubbs":
            return historyManager.totalKingHits >= 100
        case "Win 5 baseball kubb games":
            // This would need to be tracked in your BaseballKubbSession
            return false // Placeholder
        case "Train for 30 consecutive days":
            return await calculateConsecutiveDays() >= 30
        case "Complete 20 sessions":
            return historyManager.totalSessions >= 20
        case "Complete 5 practice sessions":
            return historyManager.totalSessions >= 5
        case "Achieve 85% accuracy in 10 sessions":
            return historyManager.overallAccuracy >= 0.85 && historyManager.totalSessions >= 10
        case "Hit 50 king kubbs":
            return historyManager.totalKingHits >= 50
        case "Achieve 90% accuracy in 5 consecutive sessions":
            return historyManager.overallAccuracy >= 0.9 && historyManager.totalSessions >= 5
        default:
            return false
        }
    }
    
    private func checkLevelRequirement(_ requirement: String) -> Bool {
        // Implement level-based unlocking
        return false
    }
    
    private func checkSpecialRequirement(_ requirement: String) -> Bool {
        // Implement special event unlocking
        return false
    }
    
    private func calculateConsecutiveDays() async -> Int {
        let historyManager = HistoryManager()
        let sessions = historyManager.sessions.sorted { $0.date < $1.date }
        guard !sessions.isEmpty else { return 0 }
        
        var consecutiveDays = 0
        let calendar = Calendar.current
        var currentDate = sessions.first!.date
        
        for session in sessions {
            if calendar.isDate(session.date, inSameDayAs: currentDate) {
                consecutiveDays += 1
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return consecutiveDays
    }
    
    // MARK: - Persistence
    
    private func loadSelectedSkin(for key: String) -> KubbSkin? {
        guard let skinId = userDefaults.string(forKey: key),
              let skin = availableSkins.first(where: { $0.id == skinId }) else {
            return nil
        }
        return skin
    }
    
    private func saveSelectedSkin(_ skin: KubbSkin, for key: String) {
        userDefaults.set(skin.id, forKey: key)
    }
    
    private func loadUnlockedSkins() {
        if let unlockedArray = userDefaults.array(forKey: unlockedSkinsKey) as? [String] {
            unlockedSkins = Set(unlockedArray)
        }
    }
    
    private func saveUnlockedSkins() {
        userDefaults.set(Array(unlockedSkins), forKey: unlockedSkinsKey)
    }
    
    private func updateSkinUnlockStatus() {
        availableSkins = availableSkins.map { skin in
            KubbSkin(
                id: skin.id,
                name: skin.name,
                description: skin.description,
                category: skin.category,
                unlockType: skin.unlockType,
                unlockRequirement: skin.unlockRequirement,
                isUnlocked: true, // All skins are now unlocked by default
                isDefault: skin.isDefault,
                kubbColor: skin.kubbColor,
                kubbAccentColor: skin.kubbAccentColor,
                kingColor: skin.kingColor,
                kingAccentColor: skin.kingAccentColor,
                texture: skin.texture,
                pattern: skin.pattern,
                kubbImageName: skin.kubbImageName,
                kingImageName: skin.kingImageName,
                kubbImageScale: skin.kubbImageScale,
                kingImageScale: skin.kingImageScale,
                batonColor: skin.batonColor,
                batonAccentColor: skin.batonAccentColor,
                batonImageName: skin.batonImageName,
                batonImageScale: skin.batonImageScale,
                batonHighlightColor: skin.batonHighlightColor,
                batonHighlightStyle: skin.batonHighlightStyle,
                iconName: skin.iconName,
                previewImageName: skin.previewImageName
            )
        }
    }
    
    // MARK: - Skin Filtering
    
    func skinsForCategory(_ category: SkinCategory) -> [KubbSkin] {
        return availableSkins.filter { $0.category == category }
    }
    
    func unlockedSkinsForCategory(_ category: SkinCategory) -> [KubbSkin] {
        return skinsForCategory(category).filter { $0.isUnlocked }
    }
    
    func lockedSkinsForCategory(_ category: SkinCategory) -> [KubbSkin] {
        return skinsForCategory(category).filter { !$0.isUnlocked }
    }
    
    // MARK: - Preview Helpers
    
    func getSkinPreview(for skinId: String) -> KubbSkin? {
        return availableSkins.first { $0.id == skinId }
    }
    
    // MARK: - Reset (for testing)
    
    func resetToDefaults() {
        selectedKubbSkin = KubbSkin.defaultSkins.first!
        selectedKingSkin = KubbSkin.defaultSkins.first!
        // All skins are now unlocked by default
        unlockedSkins = Set(KubbSkin.defaultSkins.map { $0.id })
        
        saveSelectedSkin(selectedKubbSkin, for: selectedKubbSkinKey)
        saveSelectedSkin(selectedKingSkin, for: selectedKingSkinKey)
        saveUnlockedSkins()
        updateSkinUnlockStatus()
    }
}

// MARK: - Skin Package Management

extension SkinManager {
    func selectSkinPackage(_ packageId: String) {
        // Find skins that belong to this package (same base ID)
        let packageSkins = availableSkins.filter { skin in
            extractBaseId(from: skin.id) == packageId
        }
        
        // Find the kubb and king skins for this package
        if let kubbSkin = packageSkins.first(where: { $0.id == packageId }) {
            selectKubbSkin(kubbSkin)
        }
        if let kingSkin = packageSkins.first(where: { $0.id == packageId }) {
            selectKingSkin(kingSkin)
        }
    }
    
    func isPackageHighlighted(_ packageId: String) -> Bool {
        let selectedKubbBaseId = extractBaseId(from: selectedKubbSkin.id)
        let selectedKingBaseId = extractBaseId(from: selectedKingSkin.id)
        
        // Package is highlighted only if both kubb and king are from the same package
        return selectedKubbBaseId == packageId && selectedKingBaseId == packageId
    }
    
    func getAvailablePackages() -> [String] {
        // Get unique base IDs from all available skins
        let baseIds = Set(availableSkins.map { extractBaseId(from: $0.id) })
        return Array(baseIds).sorted()
    }
    
    private func extractBaseId(from skinId: String) -> String {
        // Extract the base ID from skin ID (everything before any suffix)
        // For example: "classic_blue" from "classic_blue", "wooden_classic" from "wooden_classic", etc.
        return skinId
    }
}

// MARK: - Skin Unlock Notifications

extension SkinManager {
    func notifySkinUnlocked(_ skin: KubbSkin) {
        // This could trigger a notification or celebration animation
        // For now, we'll just update the UI
        objectWillChange.send()
    }
}

// MARK: - Integration with Existing Systems

extension SkinManager {
    func checkSkinsAfterSession() async {
        // Call this after each training session to check for new unlocks
        await checkAndUnlockSkins()
    }
    
    func checkSkinsAfterAchievement(_ achievementId: String) async {
        // Call this when an achievement is completed
        await checkAndUnlockSkins()
    }
}
