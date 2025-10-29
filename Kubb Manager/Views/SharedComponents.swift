//
//  SharedComponents.swift
//  Kubb Manager
//
//  Shared UI components used across multiple views
//

import SwiftUI

// MARK: - Button Styles

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.orange)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Kubb View
// Individual kubb piece display with animation and skin support
struct KubbView: View {
    let number: Int                    // Kubb piece number (1-5)
    let isKnockedDown: Bool           // Whether this kubb has been hit
    let skin: KubbSkin?               // Optional skin for customization

    @StateObject private var skinManager = SkinManager.shared  // Skin management
    @State private var animationOffset: CGFloat = 0           // Vertical offset for knockdown animation
    @State private var animationRotation: Double = 0          // Rotation for knockdown animation
    @State private var selectedImageName: String?             // Selected image for upright state
    @State private var selectedDownImageName: String?         // Selected image for knocked down state

    init(number: Int, isKnockedDown: Bool, skin: KubbSkin? = nil) {
        self.number = number
        self.isKnockedDown = isKnockedDown
        self.skin = skin

        // Initialize images immediately for better performance
        let skinManager = SkinManager.shared
        self._selectedImageName = State(initialValue: skinManager.getRandomKubbImageName(for: number - 1))
        self._selectedDownImageName = State(initialValue: skinManager.getRandomKubbDownImageName(for: number - 1))
    }

    var body: some View {
        ZStack {
            // Image-based kubb rendering (if skin has images)
            if let imageName = getCurrentImageName() {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 50)
                    .scaleEffect(skin?.kubbImageScale ?? 1.0)
                    .rotationEffect(.degrees(isKnockedDown ? animationRotation : 0))
                    .offset(y: isKnockedDown ? animationOffset : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isKnockedDown)
                    .onAppear {
                        selectImages()
                    }
            } else {
                // Color-based kubb rendering (fallback/default)
                RoundedRectangle(cornerRadius: 4)
                    .fill(kubbColor)
                    .frame(width: 20, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(accentColor, lineWidth: 1)
                    )
                    .rotationEffect(.degrees(isKnockedDown ? animationRotation : 0))
                    .offset(y: isKnockedDown ? animationOffset : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isKnockedDown)
                    .onAppear {
                        selectImages()
                    }
            }

            // Kubb number display (only for color-based kubbs)
            if skin?.kubbImageName == nil {
                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isKnockedDown ? animationRotation : 0))
                    .offset(y: isKnockedDown ? animationOffset : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isKnockedDown)
            }
        }
        .frame(width: 60, height: 60)
        // Monitor knockdown state changes to trigger animations
        .onChange(of: isKnockedDown) { _, newValue in
            if newValue {
                // Trigger knock-over animation
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    animationOffset = 15
                    animationRotation = 90
                }
            } else {
                // Reset animation when kubb is reset
                animationOffset = 0
                animationRotation = 0
            }
        }
        .accessibilityLabel("Kubb \(number), \(isKnockedDown ? "knocked down" : "standing")")
        .accessibilityHint("Kubb number \(number) in the practice round")
    }

    private var kubbColor: Color {
        if isKnockedDown {
            return Color.green
        } else {
            return skin?.kubbColor.color ?? Color.blue
        }
    }

    private var accentColor: Color {
        return skin?.kubbAccentColor?.color ?? Color.white
    }

    // MARK: - Multi-Image Helper Methods

    private func selectImages() {
        // Always use SkinManager for random selection to ensure multi-skin packages work correctly
        selectedImageName = skinManager.getRandomKubbImageName(for: number - 1)
        selectedDownImageName = skinManager.getRandomKubbDownImageName(for: number - 1)
    }

    private func getCurrentImageName() -> String? {
        // If we have custom down images and kubb is knocked down, use down image
        if isKnockedDown, let downImageName = selectedDownImageName {
            return downImageName
        }

        // Otherwise use standing image
        return selectedImageName
    }
}

// MARK: - King Kubb View
// King kubb piece display with animation and skin support (larger than regular kubbs)
struct KingKubbView: View {
    let isKnockedDown: Bool           // Whether the king has been hit
    let skin: KubbSkin?               // Optional skin for customization

    @StateObject private var skinManager = SkinManager.shared  // Skin management
    @State private var animationOffset: CGFloat = 0           // Vertical offset for knockdown animation
    @State private var animationRotation: Double = 0          // Rotation for knockdown animation
    @State private var selectedImageName: String?             // Selected image for upright state
    @State private var selectedDownImageName: String?         // Selected image for knocked down state

    init(isKnockedDown: Bool, skin: KubbSkin? = nil) {
        self.isKnockedDown = isKnockedDown
        self.skin = skin

        // Initialize images immediately for better performance
        let skinManager = SkinManager.shared
        self._selectedImageName = State(initialValue: skinManager.getRandomKingImageName())
        self._selectedDownImageName = State(initialValue: skinManager.getRandomKingDownImageName())
    }

    var body: some View {
        ZStack {
            // Image-based king rendering (if skin has images)
            if let imageName = getCurrentImageName() {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 100)
                    .scaleEffect(skin?.kingImageScale ?? 1.0)
                    .rotationEffect(.degrees(isKnockedDown ? animationRotation : 0))
                    .offset(y: isKnockedDown ? animationOffset : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isKnockedDown)
                    .onAppear {
                        selectImages()
                    }
            } else {
                // Color-based king rendering (fallback/default)
                RoundedRectangle(cornerRadius: 8)
                    .fill(kingColor)
                    .frame(width: 40, height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(accentColor, lineWidth: 2)
                    )
                    .rotationEffect(.degrees(isKnockedDown ? animationRotation : 0))
                    .offset(y: isKnockedDown ? animationOffset : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isKnockedDown)

                // King crown icon (only for color-based kings)
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isKnockedDown ? animationRotation : 0))
                    .offset(y: isKnockedDown ? animationOffset : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isKnockedDown)
            }
        }
        .frame(width: 120, height: 120)
        // Monitor knockdown state changes to trigger animations
        .onChange(of: isKnockedDown) { _, newValue in
            if newValue {
                // Trigger knock-over animation with larger movement for king
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    animationOffset = 20
                    animationRotation = 90
                }
            } else {
                // Reset animation when kubb is reset
                animationOffset = 0
                animationRotation = 0
            }
        }
        .accessibilityLabel("King kubb, \(isKnockedDown ? "knocked down" : "standing")")
        .accessibilityHint("King kubb - available for king throw")
    }

    private var kingColor: Color {
        if isKnockedDown {
            return Color.green
        } else {
            return skin?.kingColor.color ?? Color.purple
        }
    }

    private var accentColor: Color {
        return skin?.kingAccentColor?.color ?? Color.white
    }

    // MARK: - Multi-Image Helper Methods

    private func selectImages() {
        // Always use SkinManager for random selection to ensure multi-skin packages work correctly
        selectedImageName = skinManager.getRandomKingImageName()
        selectedDownImageName = skinManager.getRandomKingDownImageName()
    }

    private func getCurrentImageName() -> String? {
        // If we have custom down images and king is knocked down, use down image
        if isKnockedDown, let downImageName = selectedDownImageName {
            return downImageName
        }

        // Otherwise use standing image
        return selectedImageName
    }
}
