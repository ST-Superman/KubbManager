//
//  InkastInputView.swift
//  Kubb Manager Watch
//
//  Created by AI Assistant on 10/8/25.
//

import SwiftUI

struct InkastInputView: View {
    let context: InkastContext
    
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var count = 0
    @State private var isSending = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Prompt Text
                    Text(context.promptText)
                        .font(.headline)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                    
                    // Context Info
                    Text(contextDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Divider()
                    
                    // Count Selection
                    countSelectionView
                    
                    // Confirm Button
                    Button(action: {
                        sendResult()
                    }) {
                        Text("Confirm")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSending)
                }
                .padding()
            }
            .navigationTitle("Inkast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSending)
                }
            }
        }
    }
    
    // MARK: - Count Selection View
    
    private var countSelectionView: some View {
        VStack(spacing: 20) {
            // Digital Crown Picker
            Picker("Count", selection: $count) {
                ForEach(0...context.maxCount, id: \.self) { number in
                    Text("\(number)")
                        .font(.title2)
                        .tag(number)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 100)
            
            // +/- Buttons
            HStack(spacing: 20) {
                Button(action: {
                    if count > 0 {
                        count -= 1
                        WKInterfaceDevice.current().play(.click)
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundColor(count > 0 ? .blue : .gray)
                }
                .buttonStyle(.plain)
                .disabled(count <= 0)
                
                Text("\(count)")
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .frame(minWidth: 80)
                
                Button(action: {
                    if count < context.maxCount {
                        count += 1
                        WKInterfaceDevice.current().play(.click)
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(count < context.maxCount ? .blue : .gray)
                }
                .buttonStyle(.plain)
                .disabled(count >= context.maxCount)
            }
            
            // Quick Select Buttons (0, max/2, max)
            if context.maxCount > 2 {
                HStack(spacing: 12) {
                    quickSelectButton(value: 0, label: "0")
                    
                    if context.maxCount >= 4 {
                        quickSelectButton(value: context.maxCount / 2, label: "\(context.maxCount / 2)")
                    }
                    
                    quickSelectButton(value: context.maxCount, label: "All")
                }
            }
        }
    }
    
    // MARK: - Quick Select Button
    
    private func quickSelectButton(value: Int, label: String) -> some View {
        Button(action: {
            count = value
            WKInterfaceDevice.current().play(.click)
        }) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(count == value ? .white : .blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(count == value ? Color.blue : Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Context Description
    
    private var contextDescription: String {
        switch context.inkastType {
        case .firstAttemptOut:
            return "Count kubbs that went out of bounds on the first attempt"
        case .secondAttemptOut:
            return "Count kubbs that went out of bounds on the second attempt"
        case .neighbors:
            return "Count kubbs that landed on top of each other"
        }
    }
    
    // MARK: - Send Result
    
    private func sendResult() {
        isSending = true
        
        let result = InkastResult(
            count: count,
            inkastType: context.inkastType
        )
        
        // Haptic feedback
        WKInterfaceDevice.current().play(.success)
        
        // Send to phone
        connectivityManager.sendInkastResult(result)
        
        // Dismiss after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}

#Preview {
    InkastInputView(
        context: InkastContext(
            promptText: "Out of bounds\n(1st attempt)?",
            maxCount: 5,
            inkastType: .firstAttemptOut
        )
    )
    .environmentObject(WatchConnectivityManager.shared)
}
