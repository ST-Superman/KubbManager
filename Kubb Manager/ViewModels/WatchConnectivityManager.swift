//
//  WatchConnectivityManager.swift
//  Kubb Manager
//
//  Created by AI Assistant on 10/8/25.
//  Enhanced for production reliability on 10/11/25
//

import Foundation
import WatchConnectivity

/// Manages communication between iPhone and Apple Watch with robust error handling and retry logic
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
                log("⚠️ Delegate was set to nil")
            } else {
                log("✅ Delegate set to: \(String(describing: type(of: delegate)))")
            }
        }
    }
    
    private var session: WCSession?
    private var pendingInputRequest: WatchInputType?
    @Published var isWatchMode: Bool = false
    
    // Message reliability improvements
    private var messageQueue: [PendingMessage] = []
    private var messageRetryTimer: Timer?
    private let maxRetries = 3
    private let messageTimeout: TimeInterval = 5.0
    private var isProcessingQueue = false
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
            log("📱 Watch session initializing...")
        } else {
            log("❌ WCSession not supported on this device")
        }
        
        // Start message queue processor
        startMessageQueueProcessor()
    }
    
    // MARK: - Session State
    
    var isSessionActive: Bool {
        return session?.activationState == .activated
    }
    
    var canSendMessages: Bool {
        return isSessionActive && isWatchReachable
    }
    
    // MARK: - Logging
    
    private func log(_ message: String) {
        print("📱 [iPhone] \(message)")
    }
    
    // MARK: - Send Session Updates
    
    /// Notifies watch that a session has started
    func notifySessionStarted(sessionType: String) {
        let state = WatchSessionState(
            sessionType: sessionType,
            isActive: true,
            isWatchMode: isWatchMode
        )
        sendSessionState(state)
        log("Notified watch: Session started - \(sessionType)")
    }
    
    /// Notifies watch that a session has ended
    func notifySessionEnded() {
        let message: [String: Any] = [
            "messageType": WatchMessage.sessionEnded.rawValue
        ]
        queueMessage(message, priority: .high, requiresReply: false)
        log("Notified watch: Session ended")
    }
    
    /// Sends current session state to watch
    func sendSessionState(_ state: WatchSessionState) {
        var message: [String: Any] = [
            "messageType": WatchMessage.sessionStateUpdate.rawValue
        ]
        message.merge(state.toDictionary()) { (_, new) in new }
        
        queueMessage(message, priority: .high, requiresReply: false)
        log("Sending session state update")
    }
    
    // MARK: - Watch Mode Management
    
    /// Enables Watch Mode - watch will drive the session flow
    func enableWatchMode() {
        isWatchMode = true
        
        if delegate == nil {
            log("⚠️ WARNING: Enabling Watch Mode but no delegate is set!")
        }
        
        let message: [String: Any] = [
            "messageType": WatchMessage.enableWatchMode.rawValue
        ]
        queueMessage(message, priority: .high, requiresReply: true)
        log("Watch Mode enabled - watch will drive session flow")
    }
    
    /// Disables Watch Mode - phone controls the session flow
    func disableWatchMode() {
        isWatchMode = false
        let message: [String: Any] = [
            "messageType": WatchMessage.disableWatchMode.rawValue
        ]
        queueMessage(message, priority: .high, requiresReply: false)
        log("Watch Mode disabled - phone controls session flow")
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
            log("❌ Cannot send input request: Watch not reachable")
            // Fall back to transfer user info for when watch wakes up
            return
        }
        
        pendingInputRequest = inputType
        
        var message: [String: Any] = [
            "messageType": WatchMessage.requestInput.rawValue,
            "timestamp": Date().timeIntervalSince1970
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
        
        // Queue with high priority and require acknowledgment
        queueMessage(message, priority: .high, requiresReply: true)
        log("Requested input from watch: \(inputType)")
    }
    
    // MARK: - Message Queue System
    
    private struct PendingMessage {
        let id: UUID
        let message: [String: Any]
        let priority: MessagePriority
        let requiresReply: Bool
        var retryCount: Int
        let timestamp: Date
        var timeoutDate: Date
        
        init(message: [String: Any], priority: MessagePriority, requiresReply: Bool) {
            self.id = UUID()
            self.message = message
            self.priority = priority
            self.requiresReply = requiresReply
            self.retryCount = 0
            self.timestamp = Date()
            self.timeoutDate = Date().addingTimeInterval(5.0)
        }
    }
    
    private enum MessagePriority: Int, Comparable {
        case low = 0
        case normal = 1
        case high = 2
        
        static func < (lhs: MessagePriority, rhs: MessagePriority) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }
    
    private func queueMessage(_ message: [String: Any], priority: MessagePriority, requiresReply: Bool) {
        let pendingMessage = PendingMessage(message: message, priority: priority, requiresReply: requiresReply)
        
        DispatchQueue.main.async {
            // Insert based on priority
            if let index = self.messageQueue.firstIndex(where: { $0.priority < priority }) {
                self.messageQueue.insert(pendingMessage, at: index)
            } else {
                self.messageQueue.append(pendingMessage)
            }
            
            self.log("Queued message (priority: \(priority), queue size: \(self.messageQueue.count))")
            self.processMessageQueue()
        }
    }
    
    private func startMessageQueueProcessor() {
        // Process queue every 0.5 seconds
        messageRetryTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.processMessageQueue()
        }
    }
    
    private func processMessageQueue() {
        guard !isProcessingQueue else { return }
        guard !messageQueue.isEmpty else { return }
        guard canSendMessages else {
            log("⏸️ Cannot process queue: Watch not reachable")
            return
        }
        
        isProcessingQueue = true
        
        // Get highest priority message
        guard var pendingMessage = messageQueue.first else {
            isProcessingQueue = false
            return
        }
        
        // Check for timeout
        if Date() > pendingMessage.timeoutDate {
            log("⏱️ Message timed out, retry count: \(pendingMessage.retryCount)")
            messageQueue.removeFirst()
            
            if pendingMessage.retryCount < maxRetries {
                pendingMessage.retryCount += 1
                pendingMessage.timeoutDate = Date().addingTimeInterval(messageTimeout)
                messageQueue.append(pendingMessage)
                log("📤 Retrying message (attempt \(pendingMessage.retryCount + 1)/\(maxRetries))")
            } else {
                log("❌ Message failed after \(maxRetries) retries")
                lastError = "Failed to communicate with watch after \(maxRetries) attempts"
            }
            
            isProcessingQueue = false
            return
        }
        
        // Send the message
        sendMessageNow(pendingMessage)
    }
    
    private func sendMessageNow(_ pendingMessage: PendingMessage) {
        guard let session = session, session.isReachable else {
            log("❌ Session not reachable when trying to send")
            isProcessingQueue = false
            return
        }
        
        let messageId = pendingMessage.id
        
        // Send with timeout handling
        session.sendMessage(pendingMessage.message, replyHandler: { [weak self] reply in
            DispatchQueue.main.async {
                self?.log("✅ Received reply for message")
                self?.handleReply(reply)
                self?.removeMessageFromQueue(messageId)
                self?.isProcessingQueue = false
                // Process next message
                self?.processMessageQueue()
            }
        }, errorHandler: { [weak self] error in
            DispatchQueue.main.async {
                self?.log("❌ Error sending message: \(error.localizedDescription)")
                self?.lastError = error.localizedDescription
                
                // Don't remove from queue - will retry
                self?.isProcessingQueue = false
                
                // If it's a critical error, remove from queue
                if (error as NSError).code == 7012 { // Message not delivered
                    self?.removeMessageFromQueue(messageId)
                }
            }
        })
        
        // If message doesn't require reply, remove it immediately
        if !pendingMessage.requiresReply {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.removeMessageFromQueue(messageId)
                self?.isProcessingQueue = false
                self?.processMessageQueue()
            }
        }
    }
    
    private func removeMessageFromQueue(_ messageId: UUID) {
        messageQueue.removeAll { $0.id == messageId }
        log("📭 Message removed from queue (remaining: \(messageQueue.count))")
    }
    
    // MARK: - Handle Replies
    
    private func handleReply(_ reply: [String: Any]) {
        guard let messageType = reply["messageType"] as? String else {
            log("❌ Invalid reply: missing messageType")
            return
        }
        
        if messageType == WatchMessage.acknowledgment.rawValue {
            log("✅ Watch acknowledged message")
        }
    }
    
    // MARK: - Handle Incoming Messages
    
    private func handleIncomingMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?) {
        guard let messageTypeString = message["messageType"] as? String,
              let messageType = WatchMessage(rawValue: messageTypeString) else {
            log("❌ Invalid message: missing or invalid messageType")
            replyHandler?(["messageType": WatchMessage.error.rawValue, "error": "Invalid message type"])
            return
        }
        
        // Send acknowledgment immediately
        replyHandler?([
            "messageType": WatchMessage.acknowledgment.rawValue
        ])
        
        DispatchQueue.main.async {
            switch messageType {
            case .batonThrowResult:
                self.handleBatonThrowResult(message)
                
            case .inkastResult:
                self.handleInkastResult(message)
                
            case .requestSessionState:
                self.handleSessionStateRequest()
                
            case .nextPhase:
                self.handleNextPhaseRequest()
                
            case .nextRound:
                self.handleNextRoundRequest()
                
            case .endSession:
                self.handleEndSessionRequest()
                
            default:
                self.log("⚠️ Unhandled message type: \(messageType)")
            }
        }
    }
    
    private func handleBatonThrowResult(_ message: [String: Any]) {
        guard let result = BatonThrowResult.fromDictionary(message) else {
            log("❌ Invalid baton throw result")
            return
        }
        
        log("Received baton throw result: isHit=\(result.isHit), kubbs=\(result.kubbsHit)")
        
        // Clear pending request
        pendingInputRequest = nil
        
        // Notify delegate
        delegate?.didReceiveBatonThrowResult(result)
    }
    
    private func handleInkastResult(_ message: [String: Any]) {
        guard let result = InkastResult.fromDictionary(message) else {
            log("❌ Invalid inkast result")
            return
        }
        
        log("Received inkast result: count=\(result.count), type=\(result.inkastType)")
        
        // Clear pending request
        pendingInputRequest = nil
        
        // Notify delegate
        delegate?.didReceiveInkastResult(result)
    }
    
    private func handleSessionStateRequest() {
        log("Watch requested session state")
        delegate?.didRequestSessionState()
    }
    
    private func handleNextPhaseRequest() {
        log("Watch requested next phase")
        delegate?.didRequestNextPhase()
    }
    
    private func handleNextRoundRequest() {
        log("Watch requested next round")
        delegate?.didRequestNextRound()
    }
    
    private func handleEndSessionRequest() {
        log("Watch requested to end session")
        delegate?.didRequestEndSession()
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        log("⚠️ Session became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        log("⚠️ Session deactivated, reactivating...")
        session.activate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.lastError = error.localizedDescription
                self.log("❌ Session activation error: \(error.localizedDescription)")
            } else {
                self.log("✅ Session activated: \(activationState.rawValue)")
            }
            
            self.updateWatchState()
            
            // Process any queued messages
            if activationState == .activated {
                self.processMessageQueue()
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.updateWatchState()
            self.log("⌚️ Watch reachability changed: \(session.isReachable)")
            
            // Process queued messages when watch becomes reachable
            if session.isReachable {
                self.processMessageQueue()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        log("Received message from watch (no reply handler)")
        handleIncomingMessage(message, replyHandler: nil)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        log("Received message from watch (with reply handler)")
        handleIncomingMessage(message, replyHandler: replyHandler)
    }
    
    // MARK: - Helper Methods
    
    private func updateWatchState() {
        guard let session = session else { return }
        isWatchReachable = session.isReachable
        isWatchPaired = session.isPaired
        isWatchAppInstalled = session.isWatchAppInstalled
    }
}
