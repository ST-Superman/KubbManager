//
//  SkinSelectionView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import SwiftUI

struct SkinSelectionView: View {
    @StateObject private var skinManager = SkinManager.shared
    @State private var selectedCategory: SkinCategory = .classic
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
                        
                        SkinPreview(skin: skinManager.selectedKubbSkin, size: 50)
                        
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
                        
                        SkinPreview(skin: skinManager.selectedKingSkin, size: 50)
                        
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
            
            // Category Selection
            Section {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(SkinCategory.allCases, id: \.self) { category in
                        HStack {
                            Image(systemName: category.icon)
                            Text(category.displayName)
                        }
                        .tag(category)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            } header: {
                Text("Skin Categories")
            }
            
            // Skins Grid
            Section {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(skinsForCurrentCategory, id: \.id) { skin in
                        SkinCard(skin: skin) {
                            if selectedCategory == .classic || selectedCategory == .modern {
                                skinManager.selectKubbSkin(skin)
                            } else {
                                skinManager.selectKingSkin(skin)
                            }
                        }
                    }
                }
            } header: {
                Text("Available Skins")
            } footer: {
                Text("Tap on skins to select them. All skins are available!")
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
    
    private var skinsForCurrentCategory: [KubbSkin] {
        return skinManager.skinsForCategory(selectedCategory)
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
    @State private var selectedCategory: SkinCategory = .classic
    
    var body: some View {
        NavigationView {
            List {
                // Category Selection
                Section {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(SkinCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.displayName)
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                } header: {
                    Text("Categories")
                }
                
                // Skins List
                Section {
                    ForEach(availableSkinsForCategory, id: \.id) { skin in
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
    
    private var availableSkinsForCategory: [KubbSkin] {
        return skinManager.skinsForCategory(selectedCategory)
    }
}

#Preview {
    NavigationView {
        SkinSelectionView()
    }
}
