//
//  WatchConnectivityManager.swift
//  Kubb Manager
//
//  Created by AI Assistant on 10/8/25.
//

import Foundation
import WatchConnectivity

/// Manages communication between iPhone and Apple Watch
class WatchConnectivityManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = WatchConnectivityManager()
    
    // MARK: - Published Properties
    
    @Published var isWatchReachable = false
    @Published var isWatchPaired = false
    @Published var isWatchAppInstalled = false
    @Published var lastError: String?
    
    // MARK: - Properties
    
    weak var delegate: WatchCommunicationDelegate? {
        didSet {
            if delegate == nil {
                print("⚠️ WatchConnectivityManager delegate was set to nil")
            } else {
                print("✅ WatchConnectivityManager delegate set to: \(String(describing: type(of: delegate)))")
            }
        }
    }
    private var session: WCSession?
    private var pendingInputRequest: WatchInputType?
    @Published var isWatchMode: Bool = false
    
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
        return isSessionActive && isWatchReachable
    }
    
    // MARK: - Send Session Updates
    
    /// Notifies watch that a session has started
    func notifySessionStarted(sessionType: String) {
        let state = WatchSessionState(
            sessionType: sessionType,
            isActive: true
        )
        sendSessionState(state)
        
        print("📱 Notified watch: Session started - \(sessionType)")
    }
    
    /// Notifies watch that a session has ended
    func notifySessionEnded() {
        let message: [String: Any] = [
            "messageType": WatchMessage.sessionEnded.rawValue
        ]
        sendMessage(message)
        
        print("📱 Notified watch: Session ended")
    }
    
    /// Sends current session state to watch
    func sendSessionState(_ state: WatchSessionState) {
        var message: [String: Any] = [
            "messageType": WatchMessage.sessionStateUpdate.rawValue
        ]
        message.merge(state.toDictionary()) { (_, new) in new }
        
        sendMessage(message)
    }
    
    // MARK: - Watch Mode Management
    
    /// Enables Watch Mode - watch will drive the session flow
    func enableWatchMode() {
        isWatchMode = true
        
        // Ensure delegate is set before enabling watch mode
        if delegate == nil {
            print("⚠️ WARNING: Enabling Watch Mode but no delegate is set!")
            print("⚠️ Make sure the session is resumed/started before enabling Watch Mode")
        }
        
        let message: [String: Any] = [
            "messageType": WatchMessage.enableWatchMode.rawValue
        ]
        sendMessage(message)
        print("📱 Watch Mode enabled - watch will drive session flow")
    }
    
    /// Disables Watch Mode - phone controls the session flow
    func disableWatchMode() {
        isWatchMode = false
        let message: [String: Any] = [
            "messageType": WatchMessage.disableWatchMode.rawValue
        ]
        sendMessage(message)
        print("📱 Watch Mode disabled - phone controls session flow")
    }
    
    // MARK: - Request Input from Watch
    
    /// Requests a baton throw input from the watch
    func requestBatonThrowInput(context: BatonThrowContext) {
        let inputType = WatchInputType.batonThrow(context: context)
        requestInput(inputType)
    }
    
    /// Requests an inkast input from the watch
    func requestInkastInput(context: InkastContext) {
        let inputType = WatchInputType.inkast(context: context)
        requestInput(inputType)
    }
    
    /// Requests input from the watch
    private func requestInput(_ inputType: WatchInputType) {
        guard canSendMessages else {
            lastError = "Watch is not reachable"
            print("❌ Cannot send input request: Watch not reachable")
            return
        }
        
        pendingInputRequest = inputType
        
        var message: [String: Any] = [
            "messageType": WatchMessage.requestInput.rawValue
        ]
        
        // Add input type data
        switch inputType {
        case .batonThrow(let context):
            message["inputType"] = "batonThrow"
            message["promptText"] = context.promptText
            message["allowKubbCount"] = context.allowKubbCount
            if let maxKubbs = context.maxKubbs {
                message["maxKubbs"] = maxKubbs
            }
            if let batonNumber = context.batonNumber {
                message["batonNumber"] = batonNumber
            }
            if let totalBatons = context.totalBatons {
                message["totalBatons"] = totalBatons
            }
            
        case .inkast(let context):
            message["inputType"] = "inkast"
            message["promptText"] = context.promptText
            message["maxCount"] = context.maxCount
            message["inkastType"] = context.inkastType.rawValue
        }
        
        sendMessage(message)
        
        print("📱 Requested input from watch: \(inputType)")
    }
    
    // MARK: - Send Messages
    
    /// Sends a message to the watch
    private func sendMessage(_ message: [String: Any]) {
        guard let session = session, session.isReachable else {
            lastError = "Watch is not reachable"
            print("❌ Cannot send message: Watch not reachable")
            return
        }
        
        session.sendMessage(message, replyHandler: { reply in
            print("📱 Received reply from watch: \(reply)")
            self.handleReply(reply)
        }, errorHandler: { error in
            self.lastError = error.localizedDescription
            print("❌ Error sending message to watch: \(error.localizedDescription)")
        })
    }
    
    /// Sends message using transfer user info (for when watch is not reachable)
    private func transferUserInfo(_ userInfo: [String: Any]) {
        guard let session = session else { return }
        session.transferUserInfo(userInfo)
        print("📱 Transferred user info to watch (queued)")
    }
    
    // MARK: - Handle Replies
    
    private func handleReply(_ reply: [String: Any]) {
        guard let messageType = reply["messageType"] as? String else {
            print("❌ Invalid reply: missing messageType")
            return
        }
        
        if messageType == WatchMessage.acknowledgment.rawValue {
            print("✅ Watch acknowledged message")
        }
    }
    
    // MARK: - Handle Incoming Messages
    
    private func handleIncomingMessage(_ message: [String: Any]) {
        guard let messageTypeString = message["messageType"] as? String,
              let messageType = WatchMessage(rawValue: messageTypeString) else {
            print("❌ Invalid message: missing or invalid messageType")
            return
        }
        
        switch messageType {
        case .batonThrowResult:
            handleBatonThrowResult(message)
            
        case .inkastResult:
            handleInkastResult(message)
            
        case .requestSessionState:
            delegate?.didRequestSessionState()
            
        case .nextPhase:
            delegate?.didRequestNextPhase()
            
        case .nextRound:
            delegate?.didRequestNextRound()
            
        case .endSession:
            delegate?.didRequestEndSession()
            
        case .error:
            if let errorMessage = message["error"] as? String {
                lastError = errorMessage
                print("❌ Watch error: \(errorMessage)")
            }
            
        default:
            print("⚠️ Unhandled message type: \(messageType)")
        }
    }
    
    private func handleBatonThrowResult(_ message: [String: Any]) {
        guard let result = BatonThrowResult.fromDictionary(message) else {
            print("❌ Invalid baton throw result")
            return
        }
        
        print("📱 WatchConnectivityManager received baton throw result: isHit=\(result.isHit), kubbs=\(result.kubbsHit)")
        
        // Check if delegate is set
        if delegate == nil {
            print("❌ ERROR: No delegate set! Cannot process baton throw result!")
        } else {
            print("📱 Delegate is set, notifying delegate...")
        }
        
        // Clear pending request
        pendingInputRequest = nil
        
        // Notify delegate on main thread
        DispatchQueue.main.async {
            self.delegate?.didReceiveBatonThrowResult(result)
            print("📱 Delegate notified of baton throw result")
        }
        
        // Send acknowledgment
        sendAcknowledgment()
    }
    
    private func handleInkastResult(_ message: [String: Any]) {
        guard let result = InkastResult.fromDictionary(message) else {
            print("❌ Invalid inkast result")
            return
        }
        
        print("📱 Received inkast result: count=\(result.count), type=\(result.inkastType)")
        
        // Clear pending request
        pendingInputRequest = nil
        
        // Notify delegate on main thread
        DispatchQueue.main.async {
            self.delegate?.didReceiveInkastResult(result)
        }
        
        // Send acknowledgment
        sendAcknowledgment()
    }
    
    private func sendAcknowledgment() {
        let message: [String: Any] = [
            "messageType": WatchMessage.acknowledgment.rawValue
        ]
        
        guard let session = session, session.isReachable else { return }
        
        session.sendMessage(message, replyHandler: nil, errorHandler: { error in
            print("❌ Error sending acknowledgment: \(error.localizedDescription)")
        })
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
            
            self.updateWatchState()
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.updateWatchState()
            self.delegate?.watchConnectivityDidChange(isReachable: session.isReachable)
            
            print("⌚️ Watch reachability changed: \(session.isReachable)")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("📱 Received message from watch: \(message)")
        handleIncomingMessage(message)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("📱 Received message from watch (with reply): \(message)")
        handleIncomingMessage(message)
        
        // Send acknowledgment reply
        replyHandler([
            "messageType": WatchMessage.acknowledgment.rawValue
        ])
    }
    
    // iOS-specific delegate methods
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("⌚️ Watch session became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("⌚️ Watch session deactivated")
        // Reactivate the session
        session.activate()
    }
    #endif
    
    // MARK: - Helper Methods
    
    private func updateWatchState() {
        guard let session = session else { return }
        
        isWatchReachable = session.isReachable
        
        #if os(iOS)
        isWatchPaired = session.isPaired
        isWatchAppInstalled = session.isWatchAppInstalled
        #endif
    }
}
