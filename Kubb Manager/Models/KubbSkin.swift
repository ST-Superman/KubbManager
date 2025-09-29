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
            description: "The traditional blue kubb pieces",
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
        
        // Wooden Theme
        KubbSkin(
            id: "wooden_classic",
            name: "Wooden Classic",
            description: "Natural wood finish for authentic feel",
            category: .classic,
            unlockType: .achievement,
            unlockRequirement: "Complete 10 practice sessions",
            kubbColor: SkinColor(red: 0.6, green: 0.4, blue: 0.2),
            kubbAccentColor: SkinColor(red: 0.8, green: 0.6, blue: 0.4),
            kingColor: SkinColor(red: 0.7, green: 0.5, blue: 0.3),
            kingAccentColor: SkinColor(red: 0.9, green: 0.7, blue: 0.5),
            texture: .wood,
            iconName: "tree.fill",
            previewImageName: "wooden_classic_preview"
        ),
        
        // Modern Gradient
        KubbSkin(
            id: "modern_gradient",
            name: "Modern Gradient",
            description: "Sleek gradient design for modern players",
            category: .modern,
            unlockType: .achievement,
            unlockRequirement: "Achieve 80% accuracy in 8-meter training",
            kubbColor: SkinColor(red: 0.2, green: 0.6, blue: 0.9),
            kubbAccentColor: SkinColor(red: 0.0, green: 0.8, blue: 1.0),
            kingColor: SkinColor(red: 0.8, green: 0.2, blue: 0.6),
            kingAccentColor: SkinColor(red: 1.0, green: 0.4, blue: 0.8),
            pattern: .gradient,
            iconName: "hexagon.fill",
            previewImageName: "modern_gradient_preview"
        ),
        
        // Fantasy Crystal
        KubbSkin(
            id: "fantasy_crystal",
            name: "Crystal Fantasy",
            description: "Magical crystal pieces that sparkle",
            category: .fantasy,
            unlockType: .achievement,
            unlockRequirement: "Hit 100 king kubbs",
            kubbColor: SkinColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 0.8),
            kubbAccentColor: SkinColor(red: 1.0, green: 1.0, blue: 1.0),
            kingColor: SkinColor(red: 1.0, green: 0.8, blue: 1.0, alpha: 0.9),
            kingAccentColor: SkinColor(red: 1.0, green: 1.0, blue: 1.0),
            texture: .glass,
            iconName: "sparkles",
            previewImageName: "fantasy_crystal_preview"
        ),
        
        // Sports Team Colors
        KubbSkin(
            id: "sports_team",
            name: "Team Colors",
            description: "Show your team spirit",
            category: .sports,
            unlockType: .achievement,
            unlockRequirement: "Win 5 baseball kubb games",
            kubbColor: SkinColor(red: 1.0, green: 0.3, blue: 0.0),
            kubbAccentColor: SkinColor(red: 1.0, green: 0.6, blue: 0.0),
            kingColor: SkinColor(red: 0.0, green: 0.0, blue: 0.0),
            kingAccentColor: SkinColor(red: 1.0, green: 1.0, blue: 1.0),
            pattern: .stripes,
            iconName: "sportscourt.fill",
            previewImageName: "sports_team_preview"
        ),
        
        // Seasonal Autumn
        KubbSkin(
            id: "autumn_leaves",
            name: "Autumn Leaves",
            description: "Warm autumn colors for fall training",
            category: .seasonal,
            unlockType: .achievement,
            unlockRequirement: "Train for 30 consecutive days",
            kubbColor: SkinColor(red: 0.8, green: 0.4, blue: 0.0),
            kubbAccentColor: SkinColor(red: 1.0, green: 0.6, blue: 0.0),
            kingColor: SkinColor(red: 0.6, green: 0.2, blue: 0.0),
            kingAccentColor: SkinColor(red: 0.8, green: 0.4, blue: 0.0),
            pattern: .dots,
            iconName: "leaf.fill",
            previewImageName: "autumn_leaves_preview"
        ),
        
        // Premium Gold
        KubbSkin(
            id: "premium_gold",
            name: "Golden Premium",
            description: "Luxurious gold finish for champions",
            category: .premium,
            unlockType: .purchase,
            unlockRequirement: "Available for purchase",
            kubbColor: SkinColor(red: 1.0, green: 0.8, blue: 0.0),
            kubbAccentColor: SkinColor(red: 1.0, green: 1.0, blue: 0.5),
            kingColor: SkinColor(red: 1.0, green: 0.6, blue: 0.0),
            kingAccentColor: SkinColor(red: 1.0, green: 0.9, blue: 0.3),
            texture: .metal,
            iconName: "star.fill",
            previewImageName: "premium_gold_preview"
        ),
        
        // Neon Cyber (Example of new skin)
        KubbSkin(
            id: "neon_cyber",
            name: "Neon Cyber",
            description: "Futuristic neon glow for tech-savvy players",
            category: .modern,
            unlockType: .achievement,
            unlockRequirement: "Achieve 90% accuracy in 5 consecutive sessions",
            kubbColor: SkinColor(red: 0.0, green: 1.0, blue: 0.5),
            kubbAccentColor: SkinColor(red: 0.0, green: 1.0, blue: 1.0),
            kingColor: SkinColor(red: 1.0, green: 0.0, blue: 1.0),
            kingAccentColor: SkinColor(red: 1.0, green: 1.0, blue: 1.0),
            texture: .glass,
            pattern: .gradient,
            iconName: "hexagon.fill",
            previewImageName: "neon_cyber_preview"
        ),
        // Swedish kubb
        KubbSkin(
            id: "swedish_kubb",
            name: "Swedish Kubb",
            description: "Swedish kubb pieces",
            category: .classic,
            unlockType: .defaultSkin,
            unlockRequirement: "Default skin",
            isUnlocked: true,
            isDefault: true,
            kubbColor: SkinColor(red: 0.0, green: 0.5, blue: 1.0),
            kingColor: SkinColor(red: 0.5, green: 0.0, blue: 0.8),
            iconName: "rectangle.fill",
            previewImageName: "swedish_kubb_preview"
        ),
        
        // Wooden Kubb (Image-based)
        KubbSkin(
            id: "wooden_kubb_image",
            name: "Wooden Kubb",
            description: "Authentic wooden kubb pieces with natural grain",
            category: .classic,
            unlockType: .achievement,
            unlockRequirement: "Complete 5 practice sessions",
            kubbColor: SkinColor(red: 0.6, green: 0.4, blue: 0.2),
            kingColor: SkinColor(red: 0.7, green: 0.5, blue: 0.3),
            kubbImageName: "wooden_kubb",
            kingImageName: "wooden_king",
            kubbImageScale: 1.0,
            kingImageScale: 1.2,
            iconName: "tree.fill",
            previewImageName: "wooden_kubb_preview"
        ),
        
        // Marble Kubb (Image-based)
        KubbSkin(
            id: "marble_kubb",
            name: "Marble Kubb",
            description: "Elegant marble kubb pieces with natural veining",
            category: .premium,
            unlockType: .achievement,
            unlockRequirement: "Achieve 85% accuracy in 10 sessions",
            kubbColor: SkinColor(red: 0.9, green: 0.9, blue: 0.9),
            kingColor: SkinColor(red: 0.8, green: 0.8, blue: 0.8),
            kubbImageName: "marble_kubb",
            kingImageName: "marble_king",
            kubbImageScale: 1.0,
            kingImageScale: 1.3,
            iconName: "star.fill",
            previewImageName: "marble_kubb_preview"
        ),
        
        // Swedish .png
        KubbSkin(
            id: "swedish_kubb_png",
            name: "Swedish Kubb too",
            description: "Authentic Swedish kubb pieces",
            category: .classic,
            unlockType: .defaultSkin,
            unlockRequirement: "free",
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
        ),
        
        // Viking Kubb (Image-based)
        KubbSkin(
            id: "viking_kubb",
            name: "Viking Kubb",
            description: "Ancient Viking-style kubb pieces with runes",
            category: .fantasy,
            unlockType: .achievement,
            unlockRequirement: "Hit 50 king kubbs",
            kubbColor: SkinColor(red: 0.4, green: 0.2, blue: 0.1),
            kingColor: SkinColor(red: 0.6, green: 0.3, blue: 0.2),
            kubbImageName: "viking_kubb",
            kingImageName: "viking_king",
            kubbImageScale: 1.0,
            kingImageScale: 1.4,
            iconName: "sparkles",
            previewImageName: "viking_kubb_preview"
        )
        
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
