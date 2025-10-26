//
//  WatchConnectivityManager.swift
//  Kubb Manager Watch
//
//  Created by AI Assistant on 10/8/25.
//  Enhanced for production reliability on 10/11/25
//

import Foundation
import WatchConnectivity
#if canImport(WatchKit)
import WatchKit
#endif

/// Manages communication between Apple Watch and iPhone with robust error handling
class WatchConnectivityManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = WatchConnectivityManager()
    
    // MARK: - Published Properties
    
    @Published var isPhoneReachable = false
    @Published var currentSessionState: WatchSessionState?
    @Published var pendingBatonContext: BatonThrowContext?
    @Published var pendingInkastContext: InkastContext?
    @Published var lastError: String?
    @Published var isWatchMode: Bool = false
    @Published var isSendingResult: Bool = false // Track if we're currently sending
    
    // MARK: - Properties
    
    private var session: WCSession?
    private var messageRetryTimer: Timer?
    private var pendingResultMessage: [String: Any]?
    private var resultSendAttempts = 0
    private let maxRetries = 3
    
    var hasPendingInput: Bool {
        return pendingBatonContext != nil || pendingInkastContext != nil
    }
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
            log("⌚️ Watch session initializing...")
        } else {
            log("❌ WCSession not supported")
        }
        
        // Request session state when app launches
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.requestSessionState()
        }
    }
    
    // MARK: - Logging

    private func log(_ message: String) {
        print("⌚️ [Watch] \(message)")
    }

    // MARK: - Haptic Feedback

    #if canImport(WatchKit)
    private func playHaptic(_ type: WKHapticType) {
        WKInterfaceDevice.current().play(type)
    }
    #else
    private func playHaptic(_ type: Int) {
        // Haptics not available
    }
    #endif

    // MARK: - Session State
    
    var isSessionActive: Bool {
        return session?.activationState == .activated
    }
    
    var canSendMessages: Bool {
        return isSessionActive && isPhoneReachable
    }
    
    // MARK: - Send Results to Phone
    
    /// Sends a baton throw result to the phone
    func sendBatonThrowResult(_ result: BatonThrowResult) {
        var message = result.toDictionary()
        message["messageType"] = WatchMessage.batonThrowResult.rawValue
        message["timestamp"] = Date().timeIntervalSince1970
        
        // Store message for retry
        pendingResultMessage = message
        resultSendAttempts = 0
        isSendingResult = true
        
        sendResultWithRetry()
        
        log("Sending baton throw result: isHit=\(result.isHit), kubbs=\(result.kubbsHit)")
    }
    
    /// Sends an inkast result to the phone
    func sendInkastResult(_ result: InkastResult) {
        var message = result.toDictionary()
        message["messageType"] = WatchMessage.inkastResult.rawValue
        message["timestamp"] = Date().timeIntervalSince1970
        
        // Store message for retry
        pendingResultMessage = message
        resultSendAttempts = 0
        isSendingResult = true
        
        sendResultWithRetry()
        
        log("Sending inkast result: count=\(result.count), type=\(result.inkastType)")
    }
    
    private func sendResultWithRetry() {
        guard let message = pendingResultMessage else { return }
        guard canSendMessages else {
            log("❌ Cannot send result: Phone not reachable")
            // Retry after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.sendResultWithRetry()
            }
            return
        }
        
        guard let session = session else { return }
        
        resultSendAttempts += 1
        log("Sending result (attempt \(resultSendAttempts)/\(maxRetries))...")
        
        session.sendMessage(message, replyHandler: { [weak self] reply in
            DispatchQueue.main.async {
                self?.log("✅ Result delivered successfully")
                self?.handleResultSent()
                self?.handleReply(reply)
            }
        }, errorHandler: { [weak self] error in
            DispatchQueue.main.async {
                self?.log("❌ Error sending result: \(error.localizedDescription)")
                self?.handleResultSendError(error)
            }
        })
    }
    
    private func handleResultSent() {
        // Clear pending result
        pendingResultMessage = nil
        isSendingResult = false
        resultSendAttempts = 0
        
        // Clear pending input contexts
        pendingBatonContext = nil
        pendingInkastContext = nil
        
        // Provide haptic feedback
        #if canImport(WatchKit)
        playHaptic(.success)
        #endif
        
        log("✅ Result sent and cleared")
        
        // In Watch Mode, phone will automatically send next input
        // No need to request it here
    }
    
    private func handleResultSendError(_ error: Error) {
        lastError = error.localizedDescription
        
        // Retry if we haven't exceeded max attempts
        if resultSendAttempts < maxRetries {
            log("🔄 Retrying result send...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.sendResultWithRetry()
            }
        } else {
            log("❌ Failed to send result after \(maxRetries) attempts")
            isSendingResult = false
            pendingResultMessage = nil
            
            // Show error to user
            #if canImport(WatchKit)
            playHaptic(.failure)
            #endif
            
            // Clear the pending contexts so user can try again manually
            // Don't clear them - let user see what they entered
        }
    }
    
    /// Requests current session state from phone
    func requestSessionState() {
        guard canSendMessages else {
            log("⏸️ Cannot request state: Phone not reachable")
            return
        }
        
        let message: [String: Any] = [
            "messageType": WatchMessage.requestSessionState.rawValue
        ]
        
        sendMessageAsync(message)
        log("Requested session state from phone")
    }
    
    // MARK: - Watch Mode Actions
    
    /// Requests to advance to next phase
    func requestNextPhase() {
        let message: [String: Any] = [
            "messageType": WatchMessage.nextPhase.rawValue
        ]
        
        sendMessageAsync(message)
        log("Requested next phase from phone")
    }
    
    /// Requests to start next round
    func requestNextRound() {
        let message: [String: Any] = [
            "messageType": WatchMessage.nextRound.rawValue
        ]
        
        sendMessageAsync(message)
        log("Requested next round from phone")
    }
    
    /// Requests to end the session
    func requestEndSession() {
        let message: [String: Any] = [
            "messageType": WatchMessage.endSession.rawValue
        ]
        
        sendMessageAsync(message)
        log("Requested to end session")
    }
    
    /// Ends the current session (convenience method)
    func endSession() {
        requestEndSession()
    }
    
    /// Continues to the next round (convenience method)
    func continueToNextRound() {
        requestNextRound()
    }
    
    // MARK: - Send Messages
    
    /// Sends a message asynchronously without blocking
    private func sendMessageAsync(_ message: [String: Any]) {
        guard let session = session, session.isReachable else {
            lastError = "iPhone is not reachable"
            log("❌ Cannot send message: iPhone not reachable")
            return
        }
        
        // Send message without waiting for reply
        session.sendMessage(message, replyHandler: { reply in
            self.log("📱 Received reply from phone")
            DispatchQueue.main.async {
                self.handleReply(reply)
            }
        }, errorHandler: { error in
            DispatchQueue.main.async {
                self.lastError = error.localizedDescription
                self.log("❌ Error sending message: \(error.localizedDescription)")
            }
        })
    }
    
    // MARK: - Handle Replies
    
    private func handleReply(_ reply: [String: Any]) {
        guard let messageType = reply["messageType"] as? String else {
            log("❌ Invalid reply: missing messageType")
            return
        }
        
        if messageType == WatchMessage.acknowledgment.rawValue {
            log("✅ Phone acknowledged message")
        }
    }
    
    // MARK: - Handle Incoming Messages
    
    private func handleIncomingMessage(_ message: [String: Any]) {
        guard let messageTypeString = message["messageType"] as? String,
              let messageType = WatchMessage(rawValue: messageTypeString) else {
            log("❌ Invalid message: missing or invalid messageType")
            return
        }
        
        DispatchQueue.main.async {
            switch messageType {
            case .sessionStarted:
                self.handleSessionStarted(message)
                
            case .sessionEnded:
                self.handleSessionEnded()
                
            case .requestInput:
                self.handleInputRequest(message)
                
            case .sessionStateUpdate:
                self.handleSessionStateUpdate(message)
                
            case .enableWatchMode:
                self.handleEnableWatchMode()
                
            case .disableWatchMode:
                self.handleDisableWatchMode()
                
            case .acknowledgment:
                // Acknowledgment received
                break
                
            case .error:
                if let errorMessage = message["error"] as? String {
                    self.lastError = errorMessage
                    self.log("❌ Phone error: \(errorMessage)")
                }
                
            default:
                self.log("⚠️ Unhandled message type: \(messageType)")
            }
        }
    }
    
    private func handleSessionStarted(_ message: [String: Any]) {
        if let state = WatchSessionState.fromDictionary(message) {
            currentSessionState = state
            isWatchMode = state.isWatchMode
            log("Session started: \(state.sessionType), watch mode: \(state.isWatchMode)")
            
            // Haptic feedback
            #if canImport(WatchKit)
            playHaptic(.start)
            #endif
        }
    }
    
    private func handleSessionEnded() {
        currentSessionState = nil
        pendingBatonContext = nil
        pendingInkastContext = nil
        isWatchMode = false
        isSendingResult = false
        pendingResultMessage = nil
        log("Session ended")
        
        // Haptic feedback
        #if canImport(WatchKit)
        playHaptic(.stop)
        #endif
    }
    
    private func handleInputRequest(_ message: [String: Any]) {
        guard let inputType = message["inputType"] as? String else {
            log("❌ Invalid input request: missing inputType")
            return
        }
        
        // Don't accept new input if we're still sending a result
        if isSendingResult {
            log("⚠️ Ignoring input request while sending result")
            return
        }
        
        if inputType == "batonThrow" {
            handleBatonThrowRequest(message)
        } else if inputType == "inkast" {
            handleInkastRequest(message)
        }
    }
    
    private func handleBatonThrowRequest(_ message: [String: Any]) {
        guard let promptText = message["promptText"] as? String,
              let allowKubbCount = message["allowKubbCount"] as? Bool else {
            log("❌ Invalid baton throw request")
            return
        }
        
        let context = BatonThrowContext(
            promptText: promptText,
            allowKubbCount: allowKubbCount,
            maxKubbs: message["maxKubbs"] as? Int,
            batonNumber: message["batonNumber"] as? Int,
            totalBatons: message["totalBatons"] as? Int
        )
        
        pendingBatonContext = context
        pendingInkastContext = nil
        
        // Haptic notification
        #if canImport(WatchKit)
        playHaptic(.notification)
        #endif

        log("Received baton throw request: \(promptText)")
    }
    
    private func handleInkastRequest(_ message: [String: Any]) {
        guard let promptText = message["promptText"] as? String,
              let maxCount = message["maxCount"] as? Int,
              let inkastTypeString = message["inkastType"] as? String,
              let inkastType = InkastInputType(rawValue: inkastTypeString) else {
            log("❌ Invalid inkast request")
            return
        }
        
        let context = InkastContext(
            promptText: promptText,
            maxCount: maxCount,
            inkastType: inkastType
        )
        
        pendingInkastContext = context
        pendingBatonContext = nil
        
        // Haptic notification
        #if canImport(WatchKit)
        playHaptic(.notification)
        #endif

        log("Received inkast request: \(promptText)")
    }
    
    private func handleSessionStateUpdate(_ message: [String: Any]) {
        if let state = WatchSessionState.fromDictionary(message) {
            currentSessionState = state
            isWatchMode = state.isWatchMode
            log("Session state updated: \(state.sessionType), active: \(state.isActive), watch mode: \(state.isWatchMode)")
        }
    }
    
    private func handleEnableWatchMode() {
        isWatchMode = true
        log("Watch Mode enabled - watch will drive session flow")
        #if canImport(WatchKit)
        playHaptic(.success)
        #endif
    }
    
    private func handleDisableWatchMode() {
        isWatchMode = false
        log("Watch Mode disabled - phone controls session flow")
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.lastError = error.localizedDescription
                self.log("❌ Watch session activation error: \(error.localizedDescription)")
            } else {
                self.log("✅ Watch session activated: \(activationState.rawValue)")
            }
            
            self.updatePhoneState()
            
            // Request current session state on activation
            if activationState == .activated && session.isReachable {
                // Delay to ensure phone session is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.requestSessionState()
                }
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.updatePhoneState()
            self.log("📱 Phone reachability changed: \(session.isReachable)")
            
            // Request session state when phone becomes reachable
            if session.isReachable {
                // Delay slightly to allow phone to be ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.requestSessionState()
                }
                
                // Retry sending pending result if we have one
                if self.pendingResultMessage != nil && !self.isSendingResult {
                    self.log("🔄 Phone reachable - retrying pending result send")
                    self.isSendingResult = true
                    self.resultSendAttempts = 0
                    self.sendResultWithRetry()
                }
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        log("Received message from phone")
        handleIncomingMessage(message)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        log("Received message from phone (with reply handler)")
        handleIncomingMessage(message)

        // Send acknowledgment reply
        replyHandler([
            "messageType": WatchMessage.acknowledgment.rawValue
        ])
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        log("Received application context from phone")
        DispatchQueue.main.async {
            // Try to parse as session state
            if let state = WatchSessionState.fromDictionary(applicationContext) {
                self.currentSessionState = state
                self.isWatchMode = state.isWatchMode
                self.log("✅ Session state received via application context: \(state.sessionType)")
            } else {
                self.log("⚠️ Received application context but couldn't parse as session state")
            }
        }
    }

    // MARK: - Helper Methods
    
    private func updatePhoneState() {
        guard let session = session else { return }
        isPhoneReachable = session.isReachable
    }
}
