//
//  BatonPreview.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 1/15/25.
//

import SwiftUI

struct BatonPreview: View {
    let skin: KubbSkin
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Baton body
            if let batonImageName = skin.batonImageName {
                Image(batonImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size * 0.3, height: size)
                    .scaleEffect(skin.batonImageScale)
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .fill(batonColor)
                    .frame(width: size * 0.3, height: size)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(batonAccentColor, lineWidth: 1)
                    )
            }
            
            // Highlight effect
            RoundedRectangle(cornerRadius: 2)
                .stroke(highlightColor, lineWidth: 2)
                .frame(width: size * 0.3, height: size)
                .opacity(0.8)
        }
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
}

#Preview {
    HStack(spacing: 20) {
        ForEach(KubbSkin.defaultSkins, id: \.id) { skin in
            VStack {
                BatonPreview(skin: skin, size: 60)
                Text(skin.name)
                    .font(.caption)
            }
        }
    }
    .padding()
}
