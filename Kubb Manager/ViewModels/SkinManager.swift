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
        print("🚀 [SkinManager] Initializing with default skin: \(classicBlueSkin.name) (ID: \(classicBlueSkin.id))")
        self.selectedKubbSkin = classicBlueSkin
        self.selectedKingSkin = classicBlueSkin
        self.selectedBatonSkin = classicBlueSkin
        
        // Now that all properties are initialized, load saved selections
        if let savedKubbSkin = loadSelectedSkin(for: selectedKubbSkinKey) {
            print("🚀 [SkinManager] Loading saved kubb skin: \(savedKubbSkin.name) (ID: \(savedKubbSkin.id))")
            self.selectedKubbSkin = savedKubbSkin
        } else {
            print("🚀 [SkinManager] No saved kubb skin found, using default")
        }
        if let savedKingSkin = loadSelectedSkin(for: selectedKingSkinKey) {
            print("🚀 [SkinManager] Loading saved king skin: \(savedKingSkin.name) (ID: \(savedKingSkin.id))")
            self.selectedKingSkin = savedKingSkin
        } else {
            print("🚀 [SkinManager] No saved king skin found, using default")
        }
        if let savedBatonSkin = loadSelectedSkin(for: selectedBatonSkinKey) {
            print("🚀 [SkinManager] Loading saved baton skin: \(savedBatonSkin.name) (ID: \(savedBatonSkin.id))")
            self.selectedBatonSkin = savedBatonSkin
        } else {
            print("🚀 [SkinManager] No saved baton skin found, using default")
        }
        
        print("🚀 [SkinManager] Final selected skins - Kubb: \(selectedKubbSkin.name), King: \(selectedKingSkin.name), Baton: \(selectedBatonSkin.name)")
        
        // Load unlocked skins
        loadUnlockedSkins()
        
        // Update skin unlock status
        updateSkinUnlockStatus()
    }
    
    // MARK: - Skin Selection
    
    func selectKubbSkin(_ skin: KubbSkin) {
        print("🎨 [SkinManager] selectKubbSkin called with: \(skin.name) (ID: \(skin.id))")
        print("🎨 [SkinManager] Skin has multiple images: \(skin.hasMultipleKubbImages)")
        print("🎨 [SkinManager] Skin image names: \(skin.kubbImageNames)")
        selectedKubbSkin = skin
        saveSelectedSkin(skin, for: selectedKubbSkinKey)
        print("🎨 [SkinManager] Kubb skin selection saved")
    }
    
    func selectKingSkin(_ skin: KubbSkin) {
        selectedKingSkin = skin
        saveSelectedSkin(skin, for: selectedKingSkinKey)
    }
    
    func selectBatonSkin(_ skin: KubbSkin) {
        selectedBatonSkin = skin
        saveSelectedSkin(skin, for: selectedBatonSkinKey)
    }
    
    // MARK: - Multi-Image Random Selection
    
    /// Get a random kubb image name for the given index (0-9)
    func getRandomKubbImageName(for index: Int) -> String? {
        print("🎯 [SkinManager] getRandomKubbImageName called for index: \(index)")
        print("🎯 [SkinManager] Current selected skin: \(selectedKubbSkin.name) (ID: \(selectedKubbSkin.id))")
        print("🎯 [SkinManager] Has multiple kubb images: \(selectedKubbSkin.hasMultipleKubbImages)")
        print("🎯 [SkinManager] Kubb image names: \(selectedKubbSkin.kubbImageNames)")
        print("🎯 [SkinManager] Kubb image name (single): \(selectedKubbSkin.kubbImageName ?? "nil")")
        
        // If skin has multiple images, pick randomly; otherwise use deterministic selection
        if selectedKubbSkin.hasMultipleKubbImages {
            let selected = selectedKubbSkin.kubbImageNames.randomElement()
            print("🎯 [SkinManager] Random selection result: \(selected ?? "nil")")
            return selected
        } else {
            let selected = selectedKubbSkin.getKubbImageName(for: index)
            print("🎯 [SkinManager] Deterministic selection result: \(selected ?? "nil")")
            return selected
        }
    }
    
    /// Get a random kubb down image name for the given index (0-9)
    func getRandomKubbDownImageName(for index: Int) -> String? {
        // If skin has multiple down images, pick randomly; otherwise use deterministic selection
        if !selectedKubbSkin.kubbDownImageNames.isEmpty {
            return selectedKubbSkin.kubbDownImageNames.randomElement()
        } else {
            return selectedKubbSkin.getKubbDownImageName(for: index)
        }
    }
    
    /// Get a random king image name
    func getRandomKingImageName() -> String? {
        // If skin has multiple images, pick randomly; otherwise use single image
        if selectedKingSkin.hasMultipleKingImages {
            return selectedKingSkin.kingImageNames.randomElement()
        } else {
            return selectedKingSkin.getKingImageName()
        }
    }
    
    /// Get a random king down image name
    func getRandomKingDownImageName() -> String? {
        // If skin has multiple down images, pick randomly; otherwise use single image
        if !selectedKingSkin.kingDownImageNames.isEmpty {
            return selectedKingSkin.kingDownImageNames.randomElement()
        } else {
            return selectedKingSkin.getKingDownImageName()
        }
    }
    
    /// Get a random baton image name for the given index (0-5)
    func getRandomBatonImageName(for index: Int) -> String? {
        // If skin has multiple images, pick randomly; otherwise use deterministic selection
        if selectedBatonSkin.hasMultipleBatonImages {
            return selectedBatonSkin.batonImageNames.randomElement()
        } else {
            return selectedBatonSkin.getBatonImageName(for: index)
        }
    }
    
    /// Check if the selected kubb skin has multiple images
    var hasMultipleKubbImages: Bool {
        return selectedKubbSkin.hasMultipleKubbImages
    }
    
    /// Check if the selected king skin has multiple images
    var hasMultipleKingImages: Bool {
        return selectedKingSkin.hasMultipleKingImages
    }
    
    /// Check if the selected baton skin has multiple images
    var hasMultipleBatonImages: Bool {
        return selectedBatonSkin.hasMultipleBatonImages
    }
    
    /// Check if any selected skin has custom down images
    var hasCustomDownImages: Bool {
        return selectedKubbSkin.hasCustomDownImages || 
               selectedKingSkin.hasCustomDownImages
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
        guard let skinId = userDefaults.string(forKey: key) else {
            print("🔍 [SkinManager] No saved skin ID found for key: \(key)")
            return nil
        }
        print("🔍 [SkinManager] Found saved skin ID: \(skinId) for key: \(key)")
        
        guard let skin = availableSkins.first(where: { $0.id == skinId }) else {
            print("🔍 [SkinManager] No skin found with ID: \(skinId)")
            return nil
        }
        print("🔍 [SkinManager] Loaded skin: \(skin.name) (ID: \(skin.id))")
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
                kubbImageNames: skin.kubbImageNames,
                kubbDownImageName: skin.kubbDownImageName,
                kubbDownImageNames: skin.kubbDownImageNames,
                kingImageName: skin.kingImageName,
                kingImageNames: skin.kingImageNames,
                kingDownImageName: skin.kingDownImageName,
                kingDownImageNames: skin.kingDownImageNames,
                kubbImageScale: skin.kubbImageScale,
                kingImageScale: skin.kingImageScale,
                batonColor: skin.batonColor,
                batonAccentColor: skin.batonAccentColor,
                batonImageName: skin.batonImageName,
                batonImageNames: skin.batonImageNames,
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
        
        // For unified skins (like Star Wars), also set the baton skin
        if let batonSkin = packageSkins.first(where: { $0.id == packageId }) {
            selectBatonSkin(batonSkin)
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
