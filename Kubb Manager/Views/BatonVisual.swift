//
//  BatonVisual.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 1/15/25.
//

import SwiftUI

struct BatonVisual: View {
    let skin: KubbSkin
    let isActive: Bool
    let isThrown: Bool
    let batonNumber: Int
    
    var body: some View {
        ZStack {
            // Baton body
            let skinManager = SkinManager.shared
            if let batonImageName = skinManager.getRandomBatonImageName(for: batonNumber - 1) {
                Image(batonImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 60)
                    .scaleEffect(skin.batonImageScale)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(batonColor)
                    .frame(width: 20, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(batonAccentColor, lineWidth: 1)
                    )
            }
            
            // Baton number
            Text("\(batonNumber)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1)
        }
        .scaleEffect(isActive ? 1.1 : 1.0)
        .opacity(isThrown ? 0.3 : 1.0)
        .overlay(
            // Highlight effect for active baton
            Group {
                if isActive && !isThrown {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(highlightColor, lineWidth: 2)
                        .scaleEffect(1.2)
                        .opacity(highlightOpacity)
                }
            }
        )
        .animation(.easeInOut(duration: 0.3), value: isActive)
        .animation(.easeInOut(duration: 0.2), value: isThrown)
    }
    
    private var batonColor: Color {
        Color(
            red: skin.batonColor.red,
            green: skin.batonColor.green,
            blue: skin.batonColor.blue
        )
    }
    
    private var batonAccentColor: Color {
        if let accentColor = skin.batonAccentColor {
            return Color(
                red: accentColor.red,
                green: accentColor.green,
                blue: accentColor.blue
            )
        }
        return batonColor.opacity(0.3)
    }
    
    private var highlightColor: Color {
        Color(
            red: skin.batonHighlightColor.red,
            green: skin.batonHighlightColor.green,
            blue: skin.batonHighlightColor.blue
        )
    }
    
    private var highlightOpacity: Double {
        switch skin.batonHighlightStyle {
        case .glow:
            return 0.8
        case .border:
            return 1.0
        case .pulse:
            return 0.6
        case .scale:
            return 0.7
        case .shimmer:
            return 0.5
        }
    }
}

struct BatonRow: View {
    let skin: KubbSkin
    let currentBaton: Int
    let totalBatons: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.blue)
                Text("Baton Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 8) {
                ForEach(1...6, id: \.self) { batonNumber in
                    BatonVisual(
                        skin: skin,
                        isActive: batonNumber == currentBaton,
                        isThrown: batonNumber < currentBaton,
                        batonNumber: batonNumber
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    VStack(spacing: 20) {
        BatonRow(
            skin: KubbSkin.defaultSkins[0],
            currentBaton: 3,
            totalBatons: 6
        )
        
        BatonRow(
            skin: KubbSkin.defaultSkins[1],
            currentBaton: 1,
            totalBatons: 6
        )
        
        BatonRow(
            skin: KubbSkin.defaultSkins[2],
            currentBaton: 6,
            totalBatons: 6
        )
    }
    .padding()
}
