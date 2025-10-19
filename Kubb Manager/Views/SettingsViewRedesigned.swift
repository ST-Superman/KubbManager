//
//  SettingsViewRedesigned.swift
//  Kubb Manager
//
//  Redesigned Settings view with modern UI and better organization
//

import SwiftUI

// MARK: - Main Settings View

struct SettingsViewRedesigned: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingSkinSelection = false
    @State private var showingReminderTimePicker = false
    @State private var showingAbout = false

    var body: some View {
        NavigationView {
            ScrollView {
                settingsContent
            }
            .background(AppTheme.surface)
            .navigationTitle("Settings")
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
        .sheet(isPresented: $showingSkinSelection) {
            SkinSelectionViewRedesigned()
        }
        .sheet(isPresented: $showingReminderTimePicker) {
            ReminderTimePickerViewRedesigned(selectedTime: $settingsManager.reminderTime)
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }

    private var settingsContent: some View {
        VStack(spacing: Spacing.sectionSpacing) {
            // Quick Access - Skins
            SkinsQuickAccessCard(showingSkinSelection: $showingSkinSelection)

            // Training Section
            TrainingSettingsSection(
                settingsManager: settingsManager,
                showingReminderTimePicker: $showingReminderTimePicker
            )

                    // Appearance Section
                    SettingsSectionCard(
                        title: "Appearance",
                        icon: "paintbrush.fill",
                        color: AppTheme.accent
                    ) {
                        VStack(spacing: Spacing.md) {
                            // Color Scheme Picker
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "circle.lefthalf.filled")
                                    .font(.body)
                                    .foregroundColor(AppTheme.accent)

                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text("Color Scheme")
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    Text("Adjust app theme")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                }

                                Spacer()

                                Picker("", selection: $settingsManager.colorScheme) {
                                    ForEach(SettingsManager.ColorSchemeOption.allCases, id: \.self) { option in
                                        Text(option.displayName).tag(option)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(AppTheme.accent)
                            }
                            .padding(.horizontal, Spacing.md)

                            Divider()
                                .padding(.horizontal, Spacing.md)

                            // Haptic Feedback
                            SettingsToggleRow(
                                title: "Haptic Feedback",
                                subtitle: "Vibration on button taps",
                                icon: "waveform",
                                isOn: $settingsManager.hapticFeedbackEnabled
                            )
                        }
                        .padding(.vertical, Spacing.sm)
                    }

                    // Cloud Sync Section
                    SettingsSectionCard(
                        title: "Cloud Sync",
                        icon: "icloud.fill",
                        color: AppTheme.primary
                    ) {
                        VStack(spacing: Spacing.md) {
                            // Cloud Sync Toggle
                            SettingsToggleRow(
                                title: "iCloud Sync",
                                subtitle: "Sync data across devices",
                                icon: "icloud.fill",
                                isOn: $settingsManager.cloudSyncEnabled
                            )

                            if settingsManager.cloudSyncEnabled {
                                Divider()
                                    .padding(.horizontal, Spacing.md)

                                // WiFi Only
                                SettingsToggleRow(
                                    title: "WiFi Only",
                                    subtitle: "Sync only on WiFi networks",
                                    icon: "wifi",
                                    isOn: $settingsManager.syncOverWiFiOnly
                                )

                                Divider()
                                    .padding(.horizontal, Spacing.md)

                                // Data Retention
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    HStack {
                                        Image(systemName: "calendar")
                                            .font(.caption)
                                            .foregroundColor(AppTheme.primary)
                                        Text("Data Retention")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Spacer()
                                        Text("\(settingsManager.dataRetentionDays) days")
                                            .font(.headline)
                                            .foregroundColor(AppTheme.primary)
                                            .monospacedDigit()
                                    }

                                    HStack(spacing: Spacing.sm) {
                                        Text("30")
                                            .font(.caption2)
                                            .foregroundColor(AppTheme.textTertiary)

                                        Slider(
                                            value: Binding(
                                                get: { Double(settingsManager.dataRetentionDays) },
                                                set: { settingsManager.dataRetentionDays = Int($0) }
                                            ),
                                            in: 30...1095,
                                            step: 30
                                        )
                                        .tint(AppTheme.primary)

                                        Text("3y")
                                            .font(.caption2)
                                            .foregroundColor(AppTheme.textTertiary)
                                    }

                                    Text("Keep training history for \(settingsManager.dataRetentionDays) days")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                .padding(.horizontal, Spacing.md)
                            }
                        }
                        .padding(.vertical, Spacing.sm)
                    }

                    // Developer Section
                    SettingsSectionCard(
                        title: "Developer",
                        icon: "hammer.fill",
                        color: AppTheme.textSecondary
                    ) {
                        VStack(spacing: Spacing.md) {
                            SettingsToggleRow(
                                title: "Debug Tools",
                                subtitle: "Show debugging options",
                                icon: "ant.fill",
                                isOn: $settingsManager.showDebugTools
                            )
                        }
                        .padding(.vertical, Spacing.sm)
                    }

                    // About Section
                    Button(action: { showingAbout = true }) {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "info.circle.fill")
                                .font(.title3)
                                .foregroundColor(AppTheme.primary)

                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("About Kubb Manager")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppTheme.textPrimary)

                                Text("Version, credits & support")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(AppTheme.textTertiary)
                        }
                        .padding(Spacing.md)
                        .background(AppTheme.cardBackground)
                        .cornerRadius(AppTheme.cornerRadiusMedium)
                        .shadow(color: AppTheme.shadowLight, radius: 2, y: 1)
                    }
            }
            .padding(Spacing.screenPadding)
        }
    }

// MARK: - Skins Quick Access Card

struct SkinsQuickAccessCard: View {
    @StateObject private var skinManager = SkinManager.shared
    @Binding var showingSkinSelection: Bool

    var body: some View {
        Button(action: { showingSkinSelection = true }) {
            VStack(spacing: Spacing.md) {
                // Header
                HStack {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "paintpalette.fill")
                            .font(.title3)
                            .foregroundColor(AppTheme.accent)

                        Text("Kubb Skins")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.textPrimary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AppTheme.textTertiary)
                }

                Divider()

                // Current Skins Preview
                HStack(spacing: Spacing.lg) {
                    // Kubb
                    VStack(spacing: Spacing.xs) {
                        KubbPiecePreview(skin: skinManager.selectedKubbSkin, size: 50)
                        Text("Kubb")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        Text(skinManager.selectedKubbSkin.name)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.textPrimary)
                    }

                    // King
                    VStack(spacing: Spacing.xs) {
                        KingPiecePreview(skin: skinManager.selectedKingSkin, size: 50)
                        Text("King")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        Text(skinManager.selectedKingSkin.name)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.textPrimary)
                    }

                    // Baton
                    VStack(spacing: Spacing.xs) {
                        BatonPreview(skin: skinManager.selectedBatonSkin, size: 50)
                        Text("Baton")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        Text(skinManager.selectedBatonSkin.name)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity)

                // Tap to customize hint
                Text("Tap to customize")
                    .font(.caption)
                    .foregroundColor(AppTheme.accent)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(AppTheme.accent.opacity(0.1))
                    .cornerRadius(AppTheme.cornerRadiusSmall)
            }
            .padding(Spacing.md)
            .background(
                LinearGradient(
                    colors: [
                        AppTheme.accent.opacity(0.05),
                        AppTheme.accent.opacity(0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(AppTheme.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                    .stroke(AppTheme.accent.opacity(0.2), lineWidth: 1.5)
            )
            .shadow(color: AppTheme.shadowMedium, radius: 4, y: 2)
        }
    }
}

// MARK: - Settings Section Card

struct SettingsSectionCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Section Header
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)

            Divider()
                .padding(.horizontal, Spacing.md)

            // Content
            content
        }
        .padding(.bottom, Spacing.sm)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
        .shadow(color: AppTheme.shadowLight, radius: 2, y: 1)
    }
}

// MARK: - Settings Toggle Row

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(isOn ? AppTheme.success : AppTheme.textTertiary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppTheme.success)
        }
        .padding(.horizontal, Spacing.md)
    }
}

// MARK: - Reminder Time Picker

struct ReminderTimePickerViewRedesigned: View {
    @Binding var selectedTime: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.lg) {
                // Visual Header
                VStack(spacing: Spacing.md) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.primary)

                    Text("Training Reminder")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)

                    Text("Choose when you'd like to receive your training reminder")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Spacing.xl)

                // Time Picker
                DatePicker(
                    "Reminder Time",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()

                Spacer()

                // Done Button
                Button(action: { dismiss() }) {
                    Text("Set Reminder Time")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(AppTheme.primary)
                        .cornerRadius(AppTheme.cornerRadiusMedium)
                }
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.bottom, Spacing.lg)
            }
            .background(AppTheme.surface)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.sectionSpacing) {
                    // App Icon & Version
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "figure.throw")
                            .font(.system(size: 80))
                            .foregroundColor(AppTheme.primary)

                        Text("Kubb Manager")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.top, Spacing.xl)

                    // Description
                    Text("Track your kubb training, improve your skills, and become a better player.")
                        .font(.body)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.screenPadding)

                    // Links
                    VStack(spacing: Spacing.sm) {
                        AboutLinkButton(
                            title: "Privacy Policy",
                            icon: "hand.raised.fill",
                            action: { }
                        )

                        AboutLinkButton(
                            title: "Terms of Service",
                            icon: "doc.text.fill",
                            action: { }
                        )

                        AboutLinkButton(
                            title: "Contact Support",
                            icon: "envelope.fill",
                            action: { }
                        )

                        AboutLinkButton(
                            title: "Rate on App Store",
                            icon: "star.fill",
                            action: { }
                        )
                    }
                    .padding(.horizontal, Spacing.screenPadding)

                    // Copyright
                    Text("© 2025 Kubb Manager\nAll rights reserved")
                        .font(.caption)
                        .foregroundColor(AppTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, Spacing.xl)
                }
                .padding(.bottom, Spacing.xl)
            }
            .background(AppTheme.surface)
            .navigationTitle("About")
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

struct AboutLinkButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.primary)
                    .frame(width: 24)

                Text(title)
                    .font(.body)
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
            }
            .padding(Spacing.md)
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadiusMedium)
        }
    }
}

// MARK: - Training Settings Section

struct TrainingSettingsSection: View {
    @ObservedObject var settingsManager: SettingsManager
    @Binding var showingReminderTimePicker: Bool

    var body: some View {
        SettingsSectionCard(
            title: "Training",
            icon: "figure.run",
            color: AppTheme.primary
        ) {
            VStack(spacing: Spacing.md) {
                SettingsToggleRow(
                    title: "Training Reminders",
                    subtitle: "Get notified to train regularly",
                    icon: "bell.fill",
                    isOn: $settingsManager.trainingRemindersEnabled
                )

                if settingsManager.trainingRemindersEnabled {
                    reminderSettings
                }

                Divider()
                    .padding(.horizontal, Spacing.md)

                targetAccuracySection
            }
            .padding(.vertical, Spacing.sm)
        }
    }

    private var reminderSettings: some View {
        Group {
            Divider()
                .padding(.horizontal, Spacing.md)

            frequencySlider

            Divider()
                .padding(.horizontal, Spacing.md)

            reminderTimeButton
        }
    }

    private var frequencySlider: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(AppTheme.primary)
                Text("Frequency")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(settingsManager.weeklyTrainingDescription)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            HStack(spacing: Spacing.sm) {
                Text("1x")
                    .font(.caption2)
                    .foregroundColor(AppTheme.textTertiary)

                Slider(
                    value: Binding(
                        get: { Double(settingsManager.weeklyTrainingTarget) },
                        set: { settingsManager.weeklyTrainingTarget = Int($0) }
                    ),
                    in: 1...7,
                    step: 1
                )
                .tint(AppTheme.primary)

                Text("7x")
                    .font(.caption2)
                    .foregroundColor(AppTheme.textTertiary)
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    private var reminderTimeButton: some View {
        Button(action: {
            showingReminderTimePicker = true
        }) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "clock.fill")
                    .font(.body)
                    .foregroundColor(AppTheme.primary)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Reminder Time")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.textPrimary)

                    Text(settingsManager.reminderTime, formatter: timeFormatter)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
        }
    }

    private var targetAccuracySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "scope")
                    .font(.caption)
                    .foregroundColor(AppTheme.eightMeterTraining)
                Text("8-Meter Accuracy Target")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(settingsManager.chartTargetAccuracy * 100))%")
                    .font(.headline)
                    .foregroundColor(AppTheme.eightMeterTraining)
                    .monospacedDigit()
            }

            Slider(
                value: $settingsManager.chartTargetAccuracy,
                in: 0.1...1.0,
                step: 0.05
            )
            .tint(AppTheme.eightMeterTraining)

            Text("Target line shown on accuracy charts")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(.horizontal, Spacing.md)
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Preview

#Preview {
    SettingsViewRedesigned()
        .environmentObject(SettingsManager.shared)
}
