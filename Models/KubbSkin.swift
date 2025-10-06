//
//  KubbSkin.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import Foundation
import SwiftUI

// MARK: - Kubb Skin System

struct KubbSkin: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let category: SkinCategory
    let unlockType: UnlockType
    let unlockRequirement: String
    let isUnlocked: Bool
    let isDefault: Bool
    
    // Visual properties
    let kubbColor: SkinColor
    let kubbAccentColor: SkinColor?
    let kingColor: SkinColor
    let kingAccentColor: SkinColor?
    let texture: SkinTexture?
    let pattern: SkinPattern?
    
    // Image-based skin properties
    let kubbImageName: String?
    let kubbImageNames: [String] // Multiple kubb images (1-10)
    let kubbDownImageName: String?
    let kubbDownImageNames: [String] // Multiple kubb down images (1-10)
    let kingImageName: String?
    let kingImageNames: [String] // Multiple king images (1+)
    let kingDownImageName: String?
    let kingDownImageNames: [String] // Multiple king down images (1+)
    let kubbImageScale: Double
    let kingImageScale: Double
    
    // Baton skin properties
    let batonColor: SkinColor
    let batonAccentColor: SkinColor?
    let batonImageName: String?
    let batonImageNames: [String] // Multiple baton images (1-6)
    let batonImageScale: Double
    let batonHighlightColor: SkinColor
    let batonHighlightStyle: BatonHighlightStyle
    
    // Icon and preview
    let iconName: String
    let previewImageName: String?
    
    init(
        id: String,
        name: String,
        description: String,
        category: SkinCategory,
        unlockType: UnlockType,
        unlockRequirement: String,
        isUnlocked: Bool = false,
        isDefault: Bool = false,
        kubbColor: SkinColor,
        kubbAccentColor: SkinColor? = nil,
        kingColor: SkinColor,
        kingAccentColor: SkinColor? = nil,
        texture: SkinTexture? = nil,
        pattern: SkinPattern? = nil,
        kubbImageName: String? = nil,
        kubbImageNames: [String] = [],
        kubbDownImageName: String? = nil,
        kubbDownImageNames: [String] = [],
        kingImageName: String? = nil,
        kingImageNames: [String] = [],
        kingDownImageName: String? = nil,
        kingDownImageNames: [String] = [],
        kubbImageScale: Double = 1.0,
        kingImageScale: Double = 1.0,
        batonColor: SkinColor,
        batonAccentColor: SkinColor? = nil,
        batonImageName: String? = nil,
        batonImageNames: [String] = [],
        batonImageScale: Double = 1.0,
        batonHighlightColor: SkinColor,
        batonHighlightStyle: BatonHighlightStyle = .glow,
        iconName: String,
        previewImageName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.unlockType = unlockType
        self.unlockRequirement = unlockRequirement
        self.isUnlocked = isUnlocked
        self.isDefault = isDefault
        self.kubbColor = kubbColor
        self.kubbAccentColor = kubbAccentColor
        self.kingColor = kingColor
        self.kingAccentColor = kingAccentColor
        self.texture = texture
        self.pattern = pattern
        self.kubbImageName = kubbImageName
        self.kubbImageNames = kubbImageNames
        self.kubbDownImageName = kubbDownImageName
        self.kubbDownImageNames = kubbDownImageNames
        self.kingImageName = kingImageName
        self.kingImageNames = kingImageNames
        self.kingDownImageName = kingDownImageName
        self.kingDownImageNames = kingDownImageNames
        self.kubbImageScale = kubbImageScale
        self.kingImageScale = kingImageScale
        self.batonColor = batonColor
        self.batonAccentColor = batonAccentColor
        self.batonImageName = batonImageName
        self.batonImageNames = batonImageNames
        self.batonImageScale = batonImageScale
        self.batonHighlightColor = batonHighlightColor
        self.batonHighlightStyle = batonHighlightStyle
        self.iconName = iconName
        self.previewImageName = previewImageName
    }
    
    // MARK: - Multi-Image Helper Methods
    
    /// Get a random kubb image name for the given index (0-9)
    func getKubbImageName(for index: Int) -> String? {
        // Use multiple images if available, otherwise fall back to single image
        if !kubbImageNames.isEmpty {
            let imageIndex = index % kubbImageNames.count
            return kubbImageNames[imageIndex]
        }
        return kubbImageName
    }
    
    /// Get a random kubb down image name for the given index (0-9)
    func getKubbDownImageName(for index: Int) -> String? {
        // Use multiple down images if available, otherwise fall back to single down image
        if !kubbDownImageNames.isEmpty {
            let imageIndex = index % kubbDownImageNames.count
            return kubbDownImageNames[imageIndex]
        }
        return kubbDownImageName
    }
    
    /// Get a random king image name
    func getKingImageName() -> String? {
        // Use multiple images if available, otherwise fall back to single image
        if !kingImageNames.isEmpty {
            let randomIndex = Int.random(in: 0..<kingImageNames.count)
            return kingImageNames[randomIndex]
        }
        return kingImageName
    }
    
    /// Get a random king down image name
    func getKingDownImageName() -> String? {
        // Use multiple down images if available, otherwise fall back to single down image
        if !kingDownImageNames.isEmpty {
            let randomIndex = Int.random(in: 0..<kingDownImageNames.count)
            return kingDownImageNames[randomIndex]
        }
        return kingDownImageName
    }
    
    /// Get a random baton image name for the given index (0-5)
    func getBatonImageName(for index: Int) -> String? {
        // Use multiple images if available, otherwise fall back to single image
        if !batonImageNames.isEmpty {
            let imageIndex = index % batonImageNames.count
            return batonImageNames[imageIndex]
        }
        return batonImageName
    }
    
    /// Check if this skin has custom down images
    var hasCustomDownImages: Bool {
        return kubbDownImageName != nil || !kubbDownImageNames.isEmpty || 
               kingDownImageName != nil || !kingDownImageNames.isEmpty
    }
    
    /// Check if this skin has multiple kubb images
    var hasMultipleKubbImages: Bool {
        return !kubbImageNames.isEmpty
    }
    
    /// Check if this skin has multiple king images
    var hasMultipleKingImages: Bool {
        return !kingImageNames.isEmpty
    }
    
    /// Check if this skin has multiple baton images
    var hasMultipleBatonImages: Bool {
        return !batonImageNames.isEmpty
    }
}

// MARK: - Supporting Types

enum SkinCategory: String, CaseIterable, Codable {
    case classic = "Classic"
    case modern = "Modern"
    case fantasy = "Fantasy"
    case sports = "Sports"
    case seasonal = "Seasonal"
    case premium = "Premium"
    
    var displayName: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .classic: return "rectangle.fill"
        case .modern: return "hexagon.fill"
        case .fantasy: return "sparkles"
        case .sports: return "sportscourt.fill"
        case .seasonal: return "leaf.fill"
        case .premium: return "star.fill"
        }
    }
}

enum UnlockType: String, CaseIterable, Codable {
    case defaultSkin = "default"
    case achievement = "achievement"
    case purchase = "purchase"
    case level = "level"
    case special = "special"
    
    var displayName: String {
        switch self {
        case .defaultSkin: return "Default"
        case .achievement: return "Achievement"
        case .purchase: return "Purchase"
        case .level: return "Level"
        case .special: return "Special"
        }
    }
}

struct SkinColor: Codable, Equatable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
    
    init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    init(_ color: Color) {
        // This is a simplified conversion - in a real app you'd want more sophisticated color handling
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.alpha = Double(a)
    }
    
    var color: Color {
        return Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

enum SkinTexture: String, CaseIterable, Codable {
    case none = "none"
    case wood = "wood"
    case metal = "metal"
    case stone = "stone"
    case fabric = "fabric"
    case glass = "glass"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

enum SkinPattern: String, CaseIterable, Codable {
    case none = "none"
    case stripes = "stripes"
    case dots = "dots"
    case chevron = "chevron"
    case diamond = "diamond"
    case gradient = "gradient"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

enum BatonHighlightStyle: String, CaseIterable, Codable {
    case glow = "glow"
    case border = "border"
    case pulse = "pulse"
    case scale = "scale"
    case shimmer = "shimmer"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Default Skins

extension KubbSkin {
    static let defaultSkins: [KubbSkin] = [
        // Classic Blue (Default)
        KubbSkin(
            id: "classic_blue",
            name: "Classic Blue",
            description: "Traditional blue kubb pieces",
            category: .classic,
            unlockType: .defaultSkin,
            unlockRequirement: "Default skin",
            isUnlocked: true,
            isDefault: true,
            kubbColor: SkinColor(red: 0.0, green: 0.5, blue: 1.0),
            kingColor: SkinColor(red: 0.5, green: 0.0, blue: 0.8),
            batonColor: SkinColor(red: 0.2, green: 0.2, blue: 0.2),
            batonAccentColor: SkinColor(red: 0.4, green: 0.4, blue: 0.4),
            batonHighlightColor: SkinColor(red: 1.0, green: 0.8, blue: 0.0),
            batonHighlightStyle: .glow,
            iconName: "rectangle.fill",
            previewImageName: "classic_blue_preview"
        ),
        
        // Wooden Classic
        KubbSkin(
            id: "wooden_classic",
            name: "Wooden Classic",
            description: "Natural wood finish for authentic feel",
            category: .classic,
            unlockType: .defaultSkin,
            unlockRequirement: "Default skin",
            isUnlocked: true,
            isDefault: true,
            kubbColor: SkinColor(red: 0.6, green: 0.4, blue: 0.2),
            kubbAccentColor: SkinColor(red: 0.8, green: 0.6, blue: 0.4),
            kingColor: SkinColor(red: 0.7, green: 0.5, blue: 0.3),
            kingAccentColor: SkinColor(red: 0.9, green: 0.7, blue: 0.5),
            texture: .wood,
            batonColor: SkinColor(red: 0.4, green: 0.3, blue: 0.2),
            batonAccentColor: SkinColor(red: 0.6, green: 0.5, blue: 0.4),
            batonHighlightColor: SkinColor(red: 1.0, green: 0.6, blue: 0.0),
            batonHighlightStyle: .border,
            iconName: "tree.fill",
            previewImageName: "wooden_classic_preview"
        ),
        
        // Swedish Kubb PNG
        KubbSkin(
            id: "swedish_kubb_png",
            name: "Swedish Kubb",
            description: "Authentic Swedish kubb pieces",
            category: .classic,
            unlockType: .defaultSkin,
            unlockRequirement: "Default skin",
            isUnlocked: true,
            isDefault: true,
            kubbColor: SkinColor(red: 0.2, green: 0.1, blue: 0.0),
            kingColor: SkinColor(red: 0.3, green: 0.2, blue: 0.1),
            kubbImageName: "swedish_kubb",
            kingImageName: "swedish_king",
            kubbImageScale: 1.0,
            kingImageScale: 1.2,
            batonColor: SkinColor(red: 0.1, green: 0.1, blue: 0.1),
            batonAccentColor: SkinColor(red: 0.3, green: 0.3, blue: 0.3),
            batonImageName: "swedish_baton",
            batonImageScale: 1.0,
            batonHighlightColor: SkinColor(red: 1.0, green: 0.0, blue: 0.0),
            batonHighlightStyle: .pulse,
            iconName: "flag.se",
            previewImageName: "swedish_kubb_preview"
        ),
        
        // Star Wars Theme
        KubbSkin(
            id: "star_wars_png",
            name: "Star Wars",
            description: "A long time ago... in a galaxy far, far away",
            category: .fantasy,
            unlockType: .defaultSkin,
            unlockRequirement: "Default skin",
            isUnlocked: true,
            isDefault: true,
            kubbColor: SkinColor(red: 0.2, green: 0.1, blue: 0.0),
            kingColor: SkinColor(red: 0.3, green: 0.2, blue: 0.1),
            kubbImageNames: [
                "sw_stormy", "sw_rebel"
            ],
            kingImageName: "sw_King",
            kubbImageScale: 1.0,
            kingImageScale: 1.2,
            batonColor: SkinColor(red: 0.1, green: 0.1, blue: 0.1),
            batonAccentColor: SkinColor(red: 0.3, green: 0.3, blue: 0.3),
            batonImageNames: [
                "sw_green", "sw_red"
            ],
            batonImageScale: 1.0,
            batonHighlightColor: SkinColor(red: 0.0, green: 0.0, blue: 0.5),
            batonHighlightStyle: .pulse,
            iconName: "moon.stars.circle.fill",
            previewImageName: "star_wars_preview"
        ),
        
        /*
         * SAMPLE SKIN CODE FOR FUTURE REFERENCE:
         * 
         * To add a new skin, follow this pattern:
         * 
         * KubbSkin(
         *     id: "unique_skin_id",                    // Unique identifier
         *     name: "Display Name",                    // Name shown in UI
         *     description: "Skin description",         // Description shown in UI
         *     category: .classic,                      // Category for grouping
         *     unlockType: .defaultSkin,                // Always use .defaultSkin for free skins
         *     unlockRequirement: "Default skin",       // Always use this text for free skins
         *     isUnlocked: true,                        // Always true for free skins
         *     isDefault: true,                         // Always true for free skins
         *     kubbColor: SkinColor(red: 0.0, green: 0.5, blue: 1.0),     // Base color for kubb pieces
         *     kubbAccentColor: SkinColor(red: 0.0, green: 0.8, blue: 1.0), // Optional accent color
         *     kingColor: SkinColor(red: 0.5, green: 0.0, blue: 0.8),      // Base color for king piece
         *     kingAccentColor: SkinColor(red: 0.7, green: 0.0, blue: 1.0), // Optional accent color
         *     texture: .wood,                          // Optional texture (wood, glass, metal)
         *     pattern: .gradient,                      // Optional pattern (gradient, stripes, dots)
         *     kubbImageName: "image_name",             // Optional: use custom image instead of colors
         *     kingImageName: "king_image_name",        // Optional: use custom image for king
         *     kubbImageScale: 1.0,                     // Scale for kubb image (1.0 = normal)
         *     kingImageScale: 1.2,                     // Scale for king image (1.0 = normal)
         *     iconName: "system.icon.name",            // SF Symbol icon name for UI
         *     previewImageName: "preview_image_name"   // Optional preview image
         * ),
         * 
         * NOTES:
         * - All skins are now free and unlocked by default
         * - Use unlockType: .defaultSkin and isUnlocked: true, isDefault: true
         * - You can use either colors OR images, not both for the same piece
         * - If using images, set kubbImageName and/or kingImageName
         * - If using colors, set kubbColor and/or kingColor (and optional accents)
         * - Icon name should be a valid SF Symbol (e.g., "star.fill", "tree.fill")
         */
        
    ]
}

// MARK: - Skin Preview Helpers

struct SkinPreview: View {
    let skin: KubbSkin
    let size: CGFloat
    
    init(skin: KubbSkin, size: CGFloat = 60) {
        self.skin = skin
        self.size = size
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Kubb preview
            let skinManager = SkinManager.shared
            if let kubbImageName = skinManager.getRandomKubbImageName(for: 0) {
                // Image-based kubb
                Image(kubbImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size * 0.3, height: size * 0.5)
                    .scaleEffect(skin.kubbImageScale)
            } else {
                // Color-based kubb
                RoundedRectangle(cornerRadius: 4)
                    .fill(skin.kubbColor.color)
                    .frame(width: size * 0.3, height: size * 0.5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(skin.kubbAccentColor?.color ?? Color.white, lineWidth: 1)
                    )
            }
            
            // King preview
            if let kingImageName = skinManager.getRandomKingImageName() {
                // Image-based king
                Image(kingImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size * 0.4, height: size * 0.6)
                    .scaleEffect(skin.kingImageScale)
            } else {
                // Color-based king
                RoundedRectangle(cornerRadius: 8)
                    .fill(skin.kingColor.color)
                    .frame(width: size * 0.4, height: size * 0.6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(skin.kingAccentColor?.color ?? Color.white, lineWidth: 2)
                    )
                    .overlay(
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                    )
            }
        }
    }
}

// Individual Kubb Piece Preview
struct KubbPiecePreview: View {
    let skin: KubbSkin
    let size: CGFloat
    
    init(skin: KubbSkin, size: CGFloat = 50) {
        self.skin = skin
        self.size = size
    }
    
    var body: some View {
        let skinManager = SkinManager.shared
        if let kubbImageName = skinManager.getRandomKubbImageName(for: 0) {
            // Image-based kubb
            Image(kubbImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size * 0.6, height: size)
                .scaleEffect(skin.kubbImageScale)
        } else {
            // Color-based kubb
            RoundedRectangle(cornerRadius: 6)
                .fill(skin.kubbColor.color)
                .frame(width: size * 0.6, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(skin.kubbAccentColor?.color ?? Color.white, lineWidth: 2)
                )
        }
    }
}

// Individual King Piece Preview
struct KingPiecePreview: View {
    let skin: KubbSkin
    let size: CGFloat
    
    init(skin: KubbSkin, size: CGFloat = 50) {
        self.skin = skin
        self.size = size
    }
    
    var body: some View {
        if let kingImageName = skin.kingImageName {
            // Image-based king
            Image(kingImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size * 0.7, height: size * 1.2)
                .scaleEffect(skin.kingImageScale)
        } else {
            // Color-based king
            RoundedRectangle(cornerRadius: 10)
                .fill(skin.kingColor.color)
                .frame(width: size * 0.7, height: size * 1.2)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(skin.kingAccentColor?.color ?? Color.white, lineWidth: 2)
                )
                .overlay(
                    Image(systemName: "crown.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                )
        }
    }
}
