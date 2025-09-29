//
//  SkinSelectionView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import SwiftUI

struct SkinSelectionView: View {
    @StateObject private var skinManager = SkinManager.shared
    @State private var showingKubbSkinPicker = false
    @State private var showingKingSkinPicker = false
    
    var body: some View {
        List {
            // Current Selection Section
            Section {
                VStack(spacing: 16) {
                    // Current Kubb Skin
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Kubb Skin")
                                .font(.headline)
                            
                            Text(skinManager.selectedKubbSkin.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        KubbPiecePreview(skin: skinManager.selectedKubbSkin, size: 50)
                        
                        Button("Change") {
                            showingKubbSkinPicker = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Current King Skin
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("King Skin")
                                .font(.headline)
                            
                            Text(skinManager.selectedKingSkin.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        KingPiecePreview(skin: skinManager.selectedKingSkin, size: 50)
                        
                        Button("Change") {
                            showingKingSkinPicker = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            } header: {
                Text("Current Selection")
            }
            
            // Skin Packages Grid
            Section {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(skinManager.getAvailablePackages(), id: \.self) { packageId in
                        if let packageSkin = skinManager.availableSkins.first(where: { $0.id == packageId }) {
                            SkinPackageCard(
                                skin: packageSkin,
                                isHighlighted: skinManager.isPackageHighlighted(packageId)
                            ) {
                                skinManager.selectSkinPackage(packageId)
                            }
                        }
                    }
                }
            } header: {
                Text("Available Skin Packages")
            } footer: {
                Text("Tap on a package to select both kubb and king skins. Mix and match individual skins using the Change buttons above.")
            }
        }
        .navigationTitle("Kubb Skins")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingKubbSkinPicker) {
            SkinPickerView(
                title: "Select Kubb Skin",
                selectedSkin: skinManager.selectedKubbSkin,
                onSelection: { skin in
                    skinManager.selectKubbSkin(skin)
                    showingKubbSkinPicker = false
                }
            )
        }
        .sheet(isPresented: $showingKingSkinPicker) {
            SkinPickerView(
                title: "Select King Skin",
                selectedSkin: skinManager.selectedKingSkin,
                onSelection: { skin in
                    skinManager.selectKingSkin(skin)
                    showingKingSkinPicker = false
                }
            )
        }
    }
    
}

struct SkinPackageCard: View {
    let skin: KubbSkin
    let isHighlighted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Skin Package Preview
                SkinPreview(skin: skin, size: 60)
                
                // Skin Info
                VStack(spacing: 4) {
                    Text(skin.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(skin.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isHighlighted ? Color.blue : Color.gray, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SkinCard: View {
    let skin: KubbSkin
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Skin Preview
                SkinPreview(skin: skin, size: 60)
                
                // Skin Info
                VStack(spacing: 4) {
                    Text(skin.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(skin.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SkinPickerView: View {
    let title: String
    let selectedSkin: KubbSkin
    let onSelection: (KubbSkin) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var skinManager = SkinManager.shared
    
    var body: some View {
        NavigationView {
            List {
                // Skins List
                Section {
                    ForEach(skinManager.availableSkins, id: \.id) { skin in
                        HStack {
                            SkinPreview(skin: skin, size: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(skin.name)
                                    .font(.headline)
                                
                                Text(skin.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            if skin.id == selectedSkin.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelection(skin)
                        }
                    }
                } header: {
                    Text("Available Skins")
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
}

#Preview {
    NavigationView {
        SkinSelectionView()
    }
}
