//
//  MainMenuView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import SwiftUI

// MARK: - Main Menu View
// This view serves as the central hub for selecting different training modes
// It displays available training options and handles navigation to specific training views

struct MainMenuView: View {
    // MARK: - State Management
    @State private var selectedMode: TrainingMode?              // Currently selected training mode
    @State private var showingEightMeterTraining = false        // Controls 8-meter training modal
    @State private var showingInkastBlast = false              // Controls inkast blast training modal
    @State private var showingFullGameSim = false              // Controls full game simulation modal
    @State private var showingOptions = false                  // Controls options sheet presentation
    @StateObject private var settingsManager = SettingsManager.shared  // Manages app settings
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 32) {
                    // App Header
                    AppHeaderView()

                    // Training Mode Buttons
                    VStack(spacing: 20) {
                        ForEach(TrainingMode.allCases, id: \.self) { mode in
                            TrainingModeButton(
                                mode: mode,
                                isSelected: selectedMode == mode
                            ) {
                                if mode.isAvailable {
                                    selectedMode = mode
                                    if mode == .eightMeter {
                                        showingEightMeterTraining = true
                                    } else if mode == .inkastBlast {
                                        showingInkastBlast = true
                                    } else if mode == .fullGameSim {
                                        showingFullGameSim = true
                                    }
                                }
                            }
                        }
                    }
                    
                    // Coming Soon Notice
                    ComingSoonNoticeView()
                    
                    // Always visible debug info
                    VStack {
                        Text("🔍 DEBUG INFO")
                            .font(.headline)
                            .foregroundColor(.blue)
                        Text("SettingsManager.showDebugTools = \(settingsManager.showDebugTools ? "true" : "false")")
                            .font(.caption)
                            .foregroundColor(.primary)
                        Text("This should always be visible at the bottom of Main Menu")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Debug Section (conditional)
                    if settingsManager.showDebugTools {
                        DebugSectionView()
                            .environmentObject(CloudKitManager.shared)
                    } else {
                        // Debug info to help troubleshoot
                        VStack {
                            Text("Debug Tools Status: OFF")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text("Go to Options → Debug Options → Enable 'Include Debug Tools'")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Options") {
                        showingOptions = true
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingEightMeterTraining) {
            EightMeterTrainingViewRedesigned()
                .environmentObject(SessionManager.shared)
        }
        .fullScreenCover(isPresented: $showingInkastBlast) {
            InkastBlastView(
                persistenceController: PersistenceController.shared,
                cloudKitManager: CloudKitManager.shared
            )
        }
        .fullScreenCover(isPresented: $showingFullGameSim) {
            FullGameSimView(
                persistenceController: PersistenceController.shared,
                cloudKitManager: CloudKitManager.shared
            )
        }
        .sheet(isPresented: $showingOptions) {
            OptionsView()
                .environmentObject(settingsManager)
        }
    }
}

struct AppHeaderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image("kubb1024")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
            
            Text("Kubb Training Manager")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Choose your training mode to get started")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
}

struct TrainingModeButton: View {
    let mode: TrainingMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                if mode == .eightMeter {
                    Image("kubb_crosshair")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                } else if mode == .inkastBlast {
                    Image("inkastblast")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                } else if mode == .fullGameSim {
                    Image("king")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                } else {
                    Image(systemName: mode.icon)
                        .font(.system(size: 30))
                        .foregroundColor(mode.isAvailable ? .blue : .gray)
                        .frame(width: 60, height: 60)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(mode.rawValue)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(mode.isAvailable ? .primary : .secondary)
                        
                        if !mode.isAvailable {
                            Text("Coming Soon")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                    
                    Text(mode.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                // Arrow
                if mode.isAvailable {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .disabled(!mode.isAvailable)
        .buttonStyle(PlainButtonStyle())
    }
}

struct ComingSoonNoticeView: View {
    @State private var showingMailComposer = false
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)

            Text("New Feature Available!")
                .font(.headline)
                .foregroundColor(.green)
                .fontWeight(.semibold)
            
            Text("Full Game Sim training is now available! Experience complete kubb game simulation with inkast, blast, and 8-meter phases. Please send me any feedback or new training session ideas.")
                .font(.subheadline)
                .foregroundColor(.green)
                .multilineTextAlignment(.center)
            
            Button("Send Feedback") {
                showingMailComposer = true
            }
            .buttonStyle(.bordered)
            .foregroundColor(.purple)
            .fontWeight(.semibold)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.1))
        )
        .sheet(isPresented: $showingMailComposer) {
            MailComposerView()
        }
    }
}

struct MailComposerView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("This would open your email app to send feedback to sathomps@gmail.com")
                    .padding()
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        // This would open the mail composer
                        if let url = URL(string: "mailto:sathomps@gmail.com?subject=Kubb Manager Feedback") {
                            UIApplication.shared.open(url)
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

struct OptionsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingReminderTimePicker = false
    
    var body: some View {
        NavigationView {
            List {
                // Training Reminders Section
                Section {
                    Toggle("Enable Training Reminders", isOn: $settingsManager.trainingRemindersEnabled)
                        .toggleStyle(SwitchToggleStyle())
                    
                    if settingsManager.trainingRemindersEnabled {
                        HStack {
                            Text("Training Frequency")
                            Spacer()
                            Text(settingsManager.weeklyTrainingDescription)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sessions per week: \(settingsManager.weeklyTrainingTarget)")
                                .font(.subheadline)
                            Slider(value: Binding(
                                get: { Double(settingsManager.weeklyTrainingTarget) },
                                set: { settingsManager.weeklyTrainingTarget = Int($0) }
                            ), in: 1...7, step: 1)
                        }
                        
                        Button("Reminder Time: \(settingsManager.reminderTime, formatter: timeFormatter)") {
                            showingReminderTimePicker = true
                        }
                        .foregroundColor(.blue)
                    }
                } header: {
                    Text("Training Reminders")
                } footer: {
                    Text("Set how often you want to train each week. You'll receive reminders at your chosen time.")
                }
                
                // Visual Preferences Section
                Section {
                    HStack {
                        Text("Color Scheme")
                        Spacer()
                        Picker("Color Scheme", selection: $settingsManager.colorScheme) {
                            ForEach(SettingsManager.ColorSchemeOption.allCases, id: \.self) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    Toggle("Haptic Feedback", isOn: $settingsManager.hapticFeedbackEnabled)
                        .toggleStyle(SwitchToggleStyle())
                } header: {
                    Text("Visual Preferences")
                } footer: {
                    Text("Customize the app's appearance and feedback preferences.")
                }
                
                // Kubb Skins Section
                Section {
                    NavigationLink("Kubb Skins") {
                        SkinSelectionView()
                    }
                } header: {
                    Text("Kubb Skins")
                } footer: {
                    Text("Customize the appearance of your kubb pieces. Unlock new skins through achievements!")
                }
                
                // 8 Meters Section
                Section {
                    HStack {
                        Text("8 Meter Accuracy target")
                        Spacer()
                        Text("\(Int(settingsManager.chartTargetAccuracy * 100))%")
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Slider(value: $settingsManager.chartTargetAccuracy, in: 0.1...1.0, step: 0.05)
                        Text("Set the target accuracy shown as a line on charts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("8 Meters")
                } footer: {
                    Text("Configure chart visualization settings.")
                }
                
                // Cloud Sync Section
                Section {
                    Toggle("Enable Cloud Sync", isOn: $settingsManager.cloudSyncEnabled)
                        .toggleStyle(SwitchToggleStyle())
                    
                    if settingsManager.cloudSyncEnabled {
                        Toggle("Sync over WiFi only", isOn: $settingsManager.syncOverWiFiOnly)
                            .toggleStyle(SwitchToggleStyle())
                        
                        HStack {
                            Text("Data Retention")
                            Spacer()
                            Text("\(settingsManager.dataRetentionDays) days")
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Slider(value: Binding(
                                get: { Double(settingsManager.dataRetentionDays) },
                                set: { settingsManager.dataRetentionDays = Int($0) }
                            ), in: 30...1095, step: 30)
                            Text("Keep training data for \(settingsManager.dataRetentionDays) days")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Cloud Sync")
                } footer: {
                    Text("Control how your training data syncs to iCloud and how long it's stored.")
                }
                
                // Debug Section
                Section {
                    Toggle("Include Debug Tools", isOn: $settingsManager.showDebugTools)
                        .toggleStyle(SwitchToggleStyle())
                } header: {
                    Text("Debug Options")
                } footer: {
                    Text("Enable this option to show debug tools on the main menu. These tools are useful for troubleshooting CloudKit sync issues.")
                }
            }
            .navigationTitle("Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingReminderTimePicker) {
            ReminderTimePickerView(selectedTime: $settingsManager.reminderTime)
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

struct ReminderTimePickerView: View {
    @Binding var selectedTime: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Choose Reminder Time")
                    .font(.headline)
                    .padding()
                
                DatePicker("Reminder Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
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
    MainMenuView()
}
