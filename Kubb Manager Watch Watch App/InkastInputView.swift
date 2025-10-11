//
//  InkastInputView.swift
//  Kubb Manager Watch
//
//  Created by AI Assistant on 10/8/25.
//

import SwiftUI

enum InkastInputState {
    case initial(context: InkastContext)
    case firstAttempt(context: InkastContext)
    case secondAttempt(context: InkastContext)
    case neighbors(context: InkastContext)
    case confirmation
}

struct InkastInputView: View {
    let context: InkastContext
    
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentState: InkastInputState
    @State private var count = 0
    @State private var isSending = false
    @State private var resultSent = false
    
    init(context: InkastContext) {
        self.context = context
        self._currentState = State(initialValue: .initial(context: context))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.purple.opacity(0.3),
                        Color.blue.opacity(0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    switch currentState {
                    case .initial:
                        initialInkastView
                    case .firstAttempt, .secondAttempt:
                        attemptInputView
                    case .neighbors:
                        neighborInputView
                    case .confirmation:
                        confirmationView
                    }
                }
                .padding(.horizontal, 12)
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Initial Inkast View
    
    private var initialInkastView: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 3) {
                Text("Inkast")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                if let roundNumber = getRoundNumber() {
                    Text("Round \(roundNumber)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Text("Inkast \(context.maxCount) kubbs")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 12)
            
            Spacer()
            
            // Tap to record button
            Button(action: {
                WKInterfaceDevice.current().play(.click)
                proceedToFirstAttempt()
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("Tap to record")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.blue)
                        .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                )
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
    }
    
    // MARK: - Attempt Input View
    
    private var attemptInputView: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 3) {
                Text(getAttemptTitle())
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Out?")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 12)
            
            Spacer()
            
            // Count display with +/- buttons
            VStack(spacing: 16) {
                // Large count display
                Text("\(count)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                // +/- buttons
                HStack(spacing: 20) {
                    Button(action: {
                        if count > 0 {
                            count -= 1
                            WKInterfaceDevice.current().play(.click)
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(count > 0 ? .blue : .gray.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .disabled(count <= 0)
                    
                    Button(action: {
                        if count < context.maxCount {
                            count += 1
                            WKInterfaceDevice.current().play(.click)
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(count < context.maxCount ? .blue : .gray.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .disabled(count >= context.maxCount)
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                Button(action: {
                    dismiss()
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
                    confirmAttempt()
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
    
    // MARK: - Neighbor Input View
    
    private var neighborInputView: some View {
        VStack(spacing: 0) {
            // Header
            Text("Neighbors?")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.top, 12)
            
            Spacer()
            
            // Count display with +/- buttons
            VStack(spacing: 16) {
                // Large count display
                Text("\(count)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                // +/- buttons
                HStack(spacing: 20) {
                    Button(action: {
                        if count > 0 {
                            count -= 1
                            WKInterfaceDevice.current().play(.click)
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(count > 0 ? .blue : .gray.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .disabled(count <= 0)
                    
                    Button(action: {
                        if count < context.maxCount {
                            count += 1
                            WKInterfaceDevice.current().play(.click)
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(count < context.maxCount ? .blue : .gray.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .disabled(count >= context.maxCount)
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                Button(action: {
                    dismiss()
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
                    confirmNeighbors()
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
    
    // MARK: - Helper Methods
    
    private func getRoundNumber() -> Int? {
        return connectivityManager.currentSessionState?.currentRound
    }
    
    private func getAttemptTitle() -> String {
        switch currentState {
        case .firstAttempt:
            return "1st Attempt"
        case .secondAttempt:
            return "2nd Attempt"
        default:
            return ""
        }
    }
    
    private func proceedToFirstAttempt() {
        currentState = .firstAttempt(context: context)
        count = 0
    }
    
    private func confirmAttempt() {
        // Prevent double-submission
        guard !isSending else { return }
        isSending = true
        
        let result = InkastResult(
            count: count,
            inkastType: getInkastTypeForCurrentState()
        )
        
        WKInterfaceDevice.current().play(.success)
        connectivityManager.sendInkastResult(result)
        
        if case .firstAttempt = currentState, count > 0 {
            currentState = .secondAttempt(context: context)
            count = 0
            isSending = false // Reset for next step
        } else {
            currentState = .neighbors(context: context)
            count = 0
            isSending = false // Reset for next step
        }
    }
    
    private func confirmNeighbors() {
        // Prevent double-submission
        guard !isSending else { return }
        isSending = true
        
        let result = InkastResult(
            count: count,
            inkastType: .neighbors
        )
        
        WKInterfaceDevice.current().play(.success)
        connectivityManager.sendInkastResult(result)
        
        // Show confirmation screen instead of dismissing
        currentState = .confirmation
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
                    
                    Text("Inkast Complete!")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.top, 8)
                    
                    Text("Results sent")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
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
    
    private func getInkastTypeForCurrentState() -> InkastInputType {
        switch currentState {
        case .firstAttempt:
            return .firstAttemptOut
        case .secondAttempt:
            return .secondAttemptOut
        case .neighbors:
            return .neighbors
        default:
            return .firstAttemptOut
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
