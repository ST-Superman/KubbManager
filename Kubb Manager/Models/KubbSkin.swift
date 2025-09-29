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
    let kingImageName: String?
    let kubbImageScale: Double
    let kingImageScale: Double
    
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
        kingImageName: String? = nil,
        kubbImageScale: Double = 1.0,
        kingImageScale: Double = 1.0,
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
        self.kingImageName = kingImageName
        self.kubbImageScale = kubbImageScale
        self.kingImageScale = kingImageScale
        self.iconName = iconName
        self.previewImageName = previewImageName
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
            iconName: "flag.se",
            previewImageName: "swedish_kubb_preview"
        )
        
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

// MARK: - Skin Preview Helper

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
            if let kubbImageName = skin.kubbImageName {
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
            if let kingImageName = skin.kingImageName {
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
