//
//  BatonThrowInputView.swift
//  Kubb Manager Watch
//
//  Created by AI Assistant on 10/8/25.
//

import SwiftUI

struct BatonThrowInputView: View {
    let context: BatonThrowContext
    
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var isHit = false
    @State private var kubbsHit = 1
    @State private var showingKubbCount = false
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
                    
                    // Baton Number Indicator
                    if let batonNumber = context.batonNumber,
                       let totalBatons = context.totalBatons {
                        Text("Baton \(batonNumber) of \(totalBatons)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Hit/Miss Selection
                    if !showingKubbCount {
                        hitMissSelectionView
                    } else {
                        kubbCountSelectionView
                    }
                }
                .padding()
            }
            .navigationTitle("Record Throw")
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
    
    // MARK: - Hit/Miss Selection View
    
    private var hitMissSelectionView: some View {
        VStack(spacing: 16) {
            Text("Result?")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // MISS Button
            Button(action: {
                isHit = false
                if context.allowKubbCount {
                    kubbsHit = 0
                }
                sendResult()
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                    
                    Text("MISS")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(Color.red)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .disabled(isSending)
            
            // HIT Button
            Button(action: {
                isHit = true
                if context.allowKubbCount && (context.maxKubbs ?? 1) > 1 {
                    // Show kubb count selection
                    showingKubbCount = true
                } else {
                    // Simple hit (8-meter style)
                    kubbsHit = 1
                    sendResult()
                }
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                    
                    Text("HIT")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(Color.green)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .disabled(isSending)
        }
    }
    
    // MARK: - Kubb Count Selection View
    
    private var kubbCountSelectionView: some View {
        VStack(spacing: 20) {
            Text("How many kubbs?")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Digital Crown Picker
            Picker("Kubbs Hit", selection: $kubbsHit) {
                ForEach(1...(context.maxKubbs ?? 5), id: \.self) { count in
                    Text("\(count)")
                        .font(.title2)
                        .tag(count)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 100)
            
            // +/- Buttons
            HStack(spacing: 20) {
                Button(action: {
                    if kubbsHit > 1 {
                        kubbsHit -= 1
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundColor(kubbsHit > 1 ? .blue : .gray)
                }
                .buttonStyle(.plain)
                .disabled(kubbsHit <= 1)
                
                Text("\(kubbsHit)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .frame(minWidth: 60)
                
                Button(action: {
                    if kubbsHit < (context.maxKubbs ?? 5) {
                        kubbsHit += 1
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(kubbsHit < (context.maxKubbs ?? 5) ? .blue : .gray)
                }
                .buttonStyle(.plain)
                .disabled(kubbsHit >= (context.maxKubbs ?? 5))
            }
            
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
            
            // Back Button
            Button(action: {
                showingKubbCount = false
            }) {
                Text("Back")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            .disabled(isSending)
        }
    }
    
    // MARK: - Send Result
    
    private func sendResult() {
        isSending = true
        
        let result = BatonThrowResult(
            isHit: isHit,
            kubbsHit: kubbsHit
        )
        
        // Haptic feedback
        WKInterfaceDevice.current().play(.success)
        
        // Send to phone
        connectivityManager.sendBatonThrowResult(result)
        
        // Dismiss after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}

#Preview {
    BatonThrowInputView(
        context: BatonThrowContext(
            promptText: "Baton 1 of 6",
            allowKubbCount: true,
            maxKubbs: 5,
            batonNumber: 1,
            totalBatons: 6
        )
    )
    .environmentObject(WatchConnectivityManager.shared)
}
