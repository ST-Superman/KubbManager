//
//  SkinSelectionViewRedesigned.swift
//  Kubb Manager
//
//  Redesigned Skin Selection with beautiful visual presentation
//

import SwiftUI

// MARK: - Main Skin Selection View

struct SkinSelectionViewRedesigned: View {
    @StateObject private var skinManager = SkinManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPieceType: PieceType = .kubb
    @State private var showingPackageInfo = false

    enum PieceType: String, CaseIterable {
        case kubb = "Kubb"
        case king = "King"
        case baton = "Baton"

        var icon: String {
            switch self {
            case .kubb: return "square.fill"
            case .king: return "crown.fill"
            case .baton: return "minus.rectangle.fill"
            }
        }

        var color: Color {
            switch self {
            case .kubb: return AppTheme.primary
            case .king: return AppTheme.warning
            case .baton: return AppTheme.accent
            }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.sectionSpacing) {
                    // Current Selection Preview
                    CurrentSelectionCard()

                    // Skin Packages Section
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            SectionHeader.simple("Skin Packages")
                            Spacer()
                            Button(action: { showingPackageInfo = true }) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(AppTheme.primary)
                            }
                        }
                        .padding(.horizontal, Spacing.screenPadding)

                        Text("Select a package to apply matching kubb and king skins")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.horizontal, Spacing.screenPadding)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.md) {
                                ForEach(skinManager.getAvailablePackages(), id: \.self) { packageId in
                                    if let packageSkin = skinManager.availableSkins.first(where: { $0.id == packageId }) {
                                        SkinPackageCardRedesigned(
                                            skin: packageSkin,
                                            isSelected: skinManager.isPackageHighlighted(packageId)
                                        ) {
                                            withAnimation(.spring(response: 0.3)) {
                                                skinManager.selectSkinPackage(packageId)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, Spacing.screenPadding)
                        }
                    }

                    // Piece Type Segmented Control - moved below Skin Packages
                    Picker("Piece Type", selection: $selectedPieceType) {
                        ForEach(PieceType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, Spacing.screenPadding)

                    // Individual Skins Section
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        SectionHeader.simple("Individual \(selectedPieceType.rawValue) Skins")
                            .padding(.horizontal, Spacing.screenPadding)

                        Text("Mix and match to create your custom look")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.horizontal, Spacing.screenPadding)

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: Spacing.md),
                                GridItem(.flexible(), spacing: Spacing.md)
                            ],
                            spacing: Spacing.md
                        ) {
                            ForEach(skinManager.availableSkins, id: \.id) { skin in
                                IndividualSkinCard(
                                    skin: skin,
                                    pieceType: selectedPieceType,
                                    isSelected: isSelected(skin: skin, for: selectedPieceType)
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectSkin(skin, for: selectedPieceType)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.screenPadding)
                    }

                    // Unlock Info
                    UnlockInfoCard()
                        .padding(.horizontal, Spacing.screenPadding)
                }
                .padding(.vertical, Spacing.screenPadding)
            }
            .background(AppTheme.surface)
            .navigationTitle("Customize Skins")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.body)
                    .fontWeight(.medium)
                }
            }
        }
        .alert("Skin Packages", isPresented: $showingPackageInfo) {
            Button("Got it!", role: .cancel) { }
        } message: {
            Text("Skin packages apply matching kubb and king skins for a cohesive look. You can also mix and match individual skins to create your own unique style!")
        }
    }

    // MARK: - Helper Methods

    private func isSelected(skin: KubbSkin, for type: PieceType) -> Bool {
        switch type {
        case .kubb:
            return skin.id == skinManager.selectedKubbSkin.id
        case .king:
            return skin.id == skinManager.selectedKingSkin.id
        case .baton:
            return skin.id == skinManager.selectedBatonSkin.id
        }
    }

    private func selectSkin(_ skin: KubbSkin, for type: PieceType) {
        switch type {
        case .kubb:
            skinManager.selectKubbSkin(skin)
        case .king:
            skinManager.selectKingSkin(skin)
        case .baton:
            skinManager.selectBatonSkin(skin)
        }
    }
}

// MARK: - Current Selection Card

struct CurrentSelectionCard: View {
    @StateObject private var skinManager = SkinManager.shared

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(AppTheme.success)

                Text("Current Selection")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
            }

            Divider()

            // Pieces Display
            HStack(spacing: Spacing.xl) {
                // Kubb
                VStack(spacing: Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.primary.opacity(0.1))
                            .frame(width: 80, height: 80)

                        KubbPiecePreview(skin: skinManager.selectedKubbSkin, size: 60)
                    }

                    VStack(spacing: Spacing.xs) {
                        Text("Kubb")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        Text(skinManager.selectedKubbSkin.name)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.primary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)

                // King
                VStack(spacing: Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.warning.opacity(0.1))
                            .frame(width: 80, height: 80)

                        KingPiecePreview(skin: skinManager.selectedKingSkin, size: 60)
                    }

                    VStack(spacing: Spacing.xs) {
                        Text("King")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        Text(skinManager.selectedKingSkin.name)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.warning)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)

                // Baton
                VStack(spacing: Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accent.opacity(0.1))
                            .frame(width: 80, height: 80)

                        BatonPreview(skin: skinManager.selectedBatonSkin, size: 60)
                    }

                    VStack(spacing: Spacing.xs) {
                        Text("Baton")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        Text(skinManager.selectedBatonSkin.name)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.accent)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(Spacing.md)
        .background(
            LinearGradient(
                colors: [
                    AppTheme.success.opacity(0.05),
                    AppTheme.success.opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(AppTheme.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                .stroke(AppTheme.success.opacity(0.2), lineWidth: 1.5)
        )
        .shadow(color: AppTheme.shadowMedium, radius: 4, y: 2)
        .padding(.horizontal, Spacing.screenPadding)
    }
}

// MARK: - Skin Package Card

struct SkinPackageCardRedesigned: View {
    let skin: KubbSkin
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.sm) {
                // Package Name
                Text(skin.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)

                // Three pieces horizontally
                HStack(spacing: Spacing.md) {
                    // Kubb
                    VStack(spacing: Spacing.xs) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.primary.opacity(0.1))
                                .frame(width: 50, height: 50)

                            KubbPiecePreview(skin: skin, size: 38)
                        }

                        Text("Kubb")
                            .font(.caption2)
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    // King
                    VStack(spacing: Spacing.xs) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.warning.opacity(0.1))
                                .frame(width: 50, height: 50)

                            KingPiecePreview(skin: skin, size: 38)
                        }

                        Text("King")
                            .font(.caption2)
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    // Baton
                    VStack(spacing: Spacing.xs) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.accent.opacity(0.1))
                                .frame(width: 50, height: 50)

                            BatonPreview(skin: skin, size: 38)
                        }

                        Text("Baton")
                            .font(.caption2)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding(.vertical, Spacing.xs)

                // Description
                Text(skin.description)
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 28)

                // Selected Badge
                if isSelected {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                        Text("Active")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 4)
                    .background(AppTheme.success)
                    .cornerRadius(AppTheme.cornerRadiusSmall)
                } else {
                    // Spacer to maintain consistent height
                    Color.clear
                        .frame(height: 24)
                }
            }
            .padding(Spacing.md)
            .frame(width: 200)
            .background(
                LinearGradient(
                    colors: [
                        isSelected ? AppTheme.success.opacity(0.05) : AppTheme.cardBackground,
                        AppTheme.cardBackground
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(AppTheme.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                    .stroke(
                        isSelected ? AppTheme.success : AppTheme.textTertiary.opacity(0.2),
                        lineWidth: isSelected ? 2.5 : 1
                    )
            )
            .shadow(
                color: isSelected ? AppTheme.success.opacity(0.3) : AppTheme.shadowLight,
                radius: isSelected ? 8 : 3,
                y: isSelected ? 4 : 2
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Individual Skin Card

struct IndividualSkinCard: View {
    let skin: KubbSkin
    let pieceType: SkinSelectionViewRedesigned.PieceType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.sm) {
                // Preview
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                        .fill(pieceType.color.opacity(0.08))
                        .frame(height: 120)

                    piecePreview
                }

                // Name
                VStack(spacing: Spacing.xs) {
                    Text(skin.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)

                    if isSelected {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                            Text("Active")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(pieceType.color)
                    }
                }
            }
            .padding(Spacing.sm)
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                    .stroke(
                        isSelected ? pieceType.color : AppTheme.textTertiary.opacity(0.15),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? pieceType.color.opacity(0.25) : AppTheme.shadowLight,
                radius: isSelected ? 6 : 2,
                y: isSelected ? 3 : 1
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var piecePreview: some View {
        switch pieceType {
        case .kubb:
            KubbPiecePreview(skin: skin, size: 60)
        case .king:
            KingPiecePreview(skin: skin, size: 60)
        case .baton:
            BatonPreview(skin: skin, size: 60)
        }
    }
}

// MARK: - Unlock Info Card

struct UnlockInfoCard: View {
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "trophy.fill")
                .font(.title)
                .foregroundColor(AppTheme.warning)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Unlock More Skins")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)

                Text("Complete training sessions and achieve milestones to unlock new skin options!")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.md)
        .background(
            LinearGradient(
                colors: [
                    AppTheme.warning.opacity(0.08),
                    AppTheme.warning.opacity(0.03)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(AppTheme.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                .stroke(AppTheme.warning.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    SkinSelectionViewRedesigned()
}
