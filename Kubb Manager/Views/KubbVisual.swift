//
//  KubbVisual.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 1/15/25.
//

import SwiftUI

struct KubbVisual: View {
    let skin: KubbSkin
    let isKnockedDown: Bool
    let isTappable: Bool
    let onTap: (() -> Void)?
    @State private var selectedImageName: String?
    
    var body: some View {
        Button(action: {
            if isTappable {
                onTap?()
            }
        }) {
            ZStack {
                // Kubb base
                if let kubbImageName = selectedImageName {
                    Image(kubbImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .scaleEffect(skin.kubbImageScale)
                } else {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(kubbColor)
                        .frame(width: 30, height: 30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(kubbAccentColor, lineWidth: 1)
                        )
                }
            }
            .rotationEffect(.degrees(isKnockedDown ? 45 : 0))
            .opacity(isKnockedDown ? (isTappable ? 0.6 : 0.3) : 1.0)
        }
        .disabled(!isTappable)
        .animation(.easeInOut(duration: 0.3), value: isKnockedDown)
        .onAppear {
            selectImage()
        }
    }
    
    private func selectImage() {
        // Use SkinManager for consistent multi-skin selection across all views
        let skinManager = SkinManager.shared
        selectedImageName = skinManager.getRandomKubbImageName(for: 0) // Default to index 0 for KubbVisual
    }
    
    private var kubbColor: Color {
        Color(
            red: skin.kubbColor.red,
            green: skin.kubbColor.green,
            blue: skin.kubbColor.blue
        )
    }
    
    private var kubbAccentColor: Color {
        if let accentColor = skin.kubbAccentColor {
            return Color(
                red: accentColor.red,
                green: accentColor.green,
                blue: accentColor.blue
            )
        }
        return kubbColor.opacity(0.3)
    }
}

struct KubbLine: View {
    let kubbs: [KubbState]
    let skin: KubbSkin
    let onKubbTap: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(kubbs.enumerated()), id: \.offset) { index, kubb in
                KubbVisual(
                    skin: skin,
                    isKnockedDown: kubb.isKnockedDown,
                    isTappable: kubb.isTappable,
                    onTap: {
                        onKubbTap(index)
                    }
                )
            }
        }
    }
}

struct KubbField: View {
    let kubbs: [KubbState]
    let skin: KubbSkin
    let onKubbTap: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<numberOfLines, id: \.self) { lineIndex in
                KubbLine(
                    kubbs: kubbsForLine(lineIndex),
                    skin: skin,
                    onKubbTap: { kubbIndex in
                        let actualIndex = (lineIndex * 5) + kubbIndex
                        onKubbTap(actualIndex)
                    }
                )
            }
        }
    }
    
    private var numberOfLines: Int {
        (kubbs.count + 4) / 5 // Round up division
    }
    
    private func kubbsForLine(_ lineIndex: Int) -> [KubbState] {
        let startIndex = lineIndex * 5
        let endIndex = min(startIndex + 5, kubbs.count)
        return Array(kubbs[startIndex..<endIndex])
    }
}

struct KubbState {
    let isKnockedDown: Bool
    let isTappable: Bool
}

#Preview {
    VStack(spacing: 20) {
        // Regular kubbs
        KubbField(
            kubbs: [
                KubbState(isKnockedDown: false, isTappable: true),
                KubbState(isKnockedDown: false, isTappable: true),
                KubbState(isKnockedDown: false, isTappable: true),
                KubbState(isKnockedDown: false, isTappable: true),
                KubbState(isKnockedDown: false, isTappable: true)
            ],
            skin: KubbSkin.defaultSkins[0],
            onKubbTap: { _ in }
        )
        
        // Mixed state kubbs
        KubbField(
            kubbs: [
                KubbState(isKnockedDown: true, isTappable: false),
                KubbState(isKnockedDown: false, isTappable: true),
                KubbState(isKnockedDown: true, isTappable: false),
                KubbState(isKnockedDown: false, isTappable: true),
                KubbState(isKnockedDown: false, isTappable: true)
            ],
            skin: KubbSkin.defaultSkins[1],
            onKubbTap: { _ in }
        )
        
        // Many kubbs (multiple lines)
        KubbField(
            kubbs: Array(0..<8).map { _ in
                KubbState(isKnockedDown: false, isTappable: true)
            },
            skin: KubbSkin.defaultSkins[2],
            onKubbTap: { _ in }
        )
    }
    .padding()
}
