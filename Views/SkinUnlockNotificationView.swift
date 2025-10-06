//
//  SkinUnlockNotificationView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import SwiftUI

struct SkinUnlockNotificationView: View {
    let skin: KubbSkin
    @Binding var isPresented: Bool
    @State private var animationScale: CGFloat = 0.5
    @State private var animationOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissNotification()
                }
            
            // Notification card
            VStack(spacing: 20) {
                // Icon and title
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundColor(.yellow)
                    
                    Text("New Skin Unlocked!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                // Skin preview
                VStack(spacing: 12) {
                    SkinPreview(skin: skin, size: 80)
                    
                    Text(skin.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(skin.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Action buttons
                HStack(spacing: 16) {
                    Button("Later") {
                        dismissNotification()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("View Skins") {
                        // This would navigate to the skin selection view
                        dismissNotification()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 20)
            )
            .scaleEffect(animationScale)
            .opacity(animationOpacity)
            .padding(.horizontal, 32)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animationScale = 1.0
                animationOpacity = 1.0
            }
        }
    }
    
    private func dismissNotification() {
        withAnimation(.easeInOut(duration: 0.3)) {
            animationScale = 0.5
            animationOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

#Preview {
    SkinUnlockNotificationView(
        skin: KubbSkin.defaultSkins[1],
        isPresented: .constant(true)
    )
}
