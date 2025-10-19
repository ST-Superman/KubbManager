//
//  WatchConnectivityManager.swift
//  Kubb Manager Watch
//
//  Created by AI Assistant on 10/8/25.
//

import Foundation
import WatchConnectivity
import WatchKit

/// Manages communication between Apple Watch and iPhone
class WatchConnectivityManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = WatchConnectivityManager()
    
    // MARK: - Published Properties
    
    @Published var isPhoneReachable = false
    @Published var currentSessionState: WatchSessionState?
    @Published var pendingBatonContext: BatonThrowContext?
    @Published var pendingInkastContext: InkastContext?
    @Published var lastError: String?
    
    // MARK: - Properties
    
    private var session: WCSession?
    
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
        }
    }
    
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
        
        sendMessage(message)
        
        // Clear pending context
        pendingBatonContext = nil
        
        print("⌚️ Sent baton throw result to phone: isHit=\(result.isHit), kubbs=\(result.kubbsHit)")
    }
    
    /// Sends an inkast result to the phone
    func sendInkastResult(_ result: InkastResult) {
        var message = result.toDictionary()
        message["messageType"] = WatchMessage.inkastResult.rawValue
        
        sendMessage(message)
        
        // Clear pending context
        pendingInkastContext = nil
        
        print("⌚️ Sent inkast result to phone: count=\(result.count), type=\(result.inkastType)")
    }
    
    /// Requests current session state from phone
    func requestSessionState() {
        let message: [String: Any] = [
            "messageType": WatchMessage.requestSessionState.rawValue
        ]
        
        sendMessage(message)
        
        print("⌚️ Requested session state from phone")
    }
    
    // MARK: - Send Messages
    
    /// Sends a message to the phone
    private func sendMessage(_ message: [String: Any]) {
        guard let session = session, session.isReachable else {
            lastError = "iPhone is not reachable"
            print("❌ Cannot send message: iPhone not reachable")
            return
        }
        
        session.sendMessage(message, replyHandler: { reply in
            print("⌚️ Received reply from phone: \(reply)")
            self.handleReply(reply)
        }, errorHandler: { error in
            self.lastError = error.localizedDescription
            print("❌ Error sending message to phone: \(error.localizedDescription)")
        })
    }
    
    // MARK: - Handle Replies
    
    private func handleReply(_ reply: [String: Any]) {
        guard let messageType = reply["messageType"] as? String else {
            print("❌ Invalid reply: missing messageType")
            return
        }
        
        if messageType == WatchMessage.acknowledgment.rawValue {
            print("✅ Phone acknowledged message")
        }
    }
    
    // MARK: - Handle Incoming Messages
    
    private func handleIncomingMessage(_ message: [String: Any]) {
        guard let messageTypeString = message["messageType"] as? String,
              let messageType = WatchMessage(rawValue: messageTypeString) else {
            print("❌ Invalid message: missing or invalid messageType")
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
                
            case .error:
                if let errorMessage = message["error"] as? String {
                    self.lastError = errorMessage
                    print("❌ Phone error: \(errorMessage)")
                }
                
            default:
                print("⚠️ Unhandled message type: \(messageType)")
            }
        }
    }
    
    private func handleSessionStarted(_ message: [String: Any]) {
        if let state = WatchSessionState.fromDictionary(message) {
            currentSessionState = state
            print("⌚️ Session started: \(state.sessionType)")
        }
    }
    
    private func handleSessionEnded() {
        currentSessionState = nil
        pendingBatonContext = nil
        pendingInkastContext = nil
        print("⌚️ Session ended")
    }
    
    private func handleInputRequest(_ message: [String: Any]) {
        guard let inputType = message["inputType"] as? String else {
            print("❌ Invalid input request: missing inputType")
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
            print("❌ Invalid baton throw request")
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
        WKInterfaceDevice.current().play(.notification)
        
        print("⌚️ Received baton throw request: \(promptText)")
    }
    
    private func handleInkastRequest(_ message: [String: Any]) {
        guard let promptText = message["promptText"] as? String,
              let maxCount = message["maxCount"] as? Int,
              let inkastTypeString = message["inkastType"] as? String,
              let inkastType = InkastInputType(rawValue: inkastTypeString) else {
            print("❌ Invalid inkast request")
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
        WKInterfaceDevice.current().play(.notification)
        
        print("⌚️ Received inkast request: \(promptText)")
    }
    
    private func handleSessionStateUpdate(_ message: [String: Any]) {
        if let state = WatchSessionState.fromDictionary(message) {
            currentSessionState = state
            print("⌚️ Session state updated: \(state.sessionType), active: \(state.isActive)")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.lastError = error.localizedDescription
                print("❌ Watch session activation error: \(error.localizedDescription)")
            } else {
                print("✅ Watch session activated: \(activationState.rawValue)")
            }
            
            self.updatePhoneState()
            
            // Request current session state on activation
            if activationState == .activated && session.isReachable {
                self.requestSessionState()
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.updatePhoneState()
            
            print("⌚️ Phone reachability changed: \(session.isReachable)")
            
            // Request session state when phone becomes reachable
            if session.isReachable {
                self.requestSessionState()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("⌚️ Received message from phone: \(message)")
        handleIncomingMessage(message)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("⌚️ Received message from phone (with reply): \(message)")
        handleIncomingMessage(message)
        
        // Send acknowledgment reply
        replyHandler([
            "messageType": WatchMessage.acknowledgment.rawValue
        ])
    }
    
    // MARK: - Helper Methods
    
    private func updatePhoneState() {
        guard let session = session else { return }
        isPhoneReachable = session.isReachable
    }
}
