//
//  MainMenuView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import SwiftUI

struct MainMenuView: View {
    @State private var selectedMode: TrainingMode?
    @State private var showingEightMeterTraining = false
    @State private var showingOptions = false
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
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
                                    }
                                }
                            }
                        }
                    }
                    
                    // Coming Soon Notice
                    ComingSoonNoticeView()
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Options") {
                        showingOptions = true
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingEightMeterTraining) {
            EightMeterTrainingView()
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
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.title2)
                .foregroundColor(.orange)
            
            Text("More Training Modes Coming Soon!")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("We're working on adding Inkast/Blast training and Full Game Simulation. Stay tuned for updates!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.1))
        )
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
                    Text("Enable this option to show debug tools in the 8-meter training overview. These tools are useful for troubleshooting CloudKit sync issues.")
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
