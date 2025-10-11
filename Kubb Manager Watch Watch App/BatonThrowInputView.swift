//
//  BatonThrowInputView.swift
//  Kubb Manager Watch
//
//  Created by AI Assistant on 10/8/25.
//

import SwiftUI

enum BatonThrowState {
    case hitMiss
    case kubbCount
    case confirmation
}

struct BatonThrowInputView: View {
    let context: BatonThrowContext
    
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentState: BatonThrowState = .hitMiss
    @State private var isHit = false
    @State private var kubbsHit = 1
    @State private var isSending = false
    @State private var resultSent = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.orange.opacity(0.3),
                        Color.blue.opacity(0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    switch currentState {
                    case .hitMiss:
                        hitMissView
                    case .kubbCount:
                        kubbCountView
                    case .confirmation:
                        confirmationView
                    }
                }
                .padding(.horizontal, 12)
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Hit/Miss View
    
    private var hitMissView: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 3) {
                Text("Record Throw")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                if let batonNumber = context.batonNumber,
                   let totalBatons = context.totalBatons {
                    if totalBatons == 2 {
                        Text("8-Meter Training")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    } else {
                        Text("Baton \(batonNumber) of \(totalBatons)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Throwing Position Badge
                if context.promptText.contains("👑 King Shot") {
                    // King shot only - purple badge
                    HStack(spacing: 3) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 8, weight: .bold))
                        Text("KING")
                            .font(.system(size: 8, weight: .black))
                            .tracking(0.5)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.purple)
                    )
                    .padding(.top, 4)
                } else if context.promptText.contains("⚡ A-Line") {
                    // A-Line - yellow badge
                    HStack(spacing: 3) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 8, weight: .bold))
                        Text("A-LINE")
                            .font(.system(size: 8, weight: .black))
                            .tracking(0.5)
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.yellow)
                    )
                    .padding(.top, 4)
                } else if context.promptText.contains("📏 Baseline") {
                    // Baseline - gray badge
                    HStack(spacing: 3) {
                        Image(systemName: "ruler")
                            .font(.system(size: 8, weight: .medium))
                        Text("BASELINE")
                            .font(.system(size: 8, weight: .semibold))
                            .tracking(0.3)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.6))
                    )
                    .padding(.top, 4)
                }
            }
            .padding(.top, 12)
            
            Spacer()
            
            // Hit/Miss buttons
            HStack(spacing: 12) {
                // MISS Button
                Button(action: {
                    isHit = false
                    kubbsHit = 0
                    sendResult()
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("MISS")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 70, height: 70)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red)
                            .shadow(color: Color.red.opacity(0.3), radius: 4, x: 0, y: 2)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isSending)
                
                // HIT Button
                Button(action: {
                    isHit = true
                    if context.allowKubbCount && (context.maxKubbs ?? 1) > 1 {
                        currentState = .kubbCount
                        kubbsHit = 1
                    } else {
                        kubbsHit = 1
                        sendResult()
                    }
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("HIT")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 70, height: 70)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green)
                            .shadow(color: Color.green.opacity(0.3), radius: 4, x: 0, y: 2)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isSending)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Kubb Count View
    
    private var kubbCountView: some View {
        VStack(spacing: 0) {
            // Header
            Text("How many kubbs?")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.top, 12)
            
            Spacer()
            
            // Count display with +/- buttons
            VStack(spacing: 16) {
                // Large count display
                Text("\(kubbsHit)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                // +/- buttons
                HStack(spacing: 20) {
                    Button(action: {
                        if kubbsHit > 1 {
                            kubbsHit -= 1
                            WKInterfaceDevice.current().play(.click)
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(kubbsHit > 1 ? .blue : .gray.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .disabled(kubbsHit <= 1)
                    
                    Button(action: {
                        if kubbsHit < (context.maxKubbs ?? 5) {
                            kubbsHit += 1
                            WKInterfaceDevice.current().play(.click)
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(kubbsHit < (context.maxKubbs ?? 5) ? .blue : .gray.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .disabled(kubbsHit >= (context.maxKubbs ?? 5))
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                Button(action: {
                    currentState = .hitMiss
                }) {
                    Text("Cancel")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                        )
                }
                .buttonStyle(.plain)
                .disabled(isSending)
                
                Button(action: {
                    sendResult()
                }) {
                    Text("Confirm")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue)
                        )
                }
                .buttonStyle(.plain)
                .disabled(isSending)
            }
            .padding(.bottom, 8)
        }
    }
    
    // MARK: - Confirmation View
    
    private var confirmationView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Success icon
            VStack(spacing: 12) {
                if connectivityManager.isSendingResult {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.blue)
                    
                    Text("Sending...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                } else if resultSent {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundColor(.green)
                    
                    Text("Result Sent!")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.top, 8)
                    
                    if isHit {
                        Text("Hit \(kubbsHit) kubb\(kubbsHit != 1 ? "s" : "")")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    } else {
                        Text("Recorded miss")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Continue button (only show after result is sent)
            if resultSent && !connectivityManager.isSendingResult {
                Button(action: {
                    WKInterfaceDevice.current().play(.click)
                    dismiss()
                }) {
                    HStack(spacing: 6) {
                        Text("Done")
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue)
                    )
                }
                .buttonStyle(.plain)
                .padding(.bottom, 8)
            }
        }
        .onAppear {
            // Watch for result to be sent
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if !connectivityManager.isSendingResult {
                    resultSent = true
                } else {
                    // Check again in a moment
                    checkIfSent()
                }
            }
        }
    }
    
    private func checkIfSent() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if !connectivityManager.isSendingResult {
                resultSent = true
            } else {
                // Keep checking
                checkIfSent()
            }
        }
    }
    
    // MARK: - Send Result
    
    private func sendResult() {
        // Prevent double-submission
        guard !isSending else { return }
        isSending = true
        
        let result = BatonThrowResult(
            isHit: isHit,
            kubbsHit: kubbsHit
        )
        
        WKInterfaceDevice.current().play(.success)
        connectivityManager.sendBatonThrowResult(result)
        
        // Show confirmation screen instead of dismissing
        currentState = .confirmation
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
