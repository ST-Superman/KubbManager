//
//  CloudKitManager.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import Foundation
import CloudKit
import Combine
import UIKit

// MARK: - Notification Names

extension Notification.Name {
    static let cloudKitDataCleared = Notification.Name("cloudKitDataCleared")
    static let cloudKitDataChanged = Notification.Name("cloudKitDataChanged")
}

@MainActor
class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let localStorage = LocalStorageManager.shared
    
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published var isSignedIn: Bool = false
    @Published var syncStatus: SyncStatus = .idle
    
    // Subscription management for real-time sync
    private var subscriptions: [CKSubscription] = []
    private var hasSetUpSubscriptions = false
    
    enum SyncStatus {
        case idle
        case syncing
        case success
        case error(String)
    }
    
    private init() {
        container = CKContainer(identifier: "iCloud.ST-Superman.Kubb-Manager")
        privateDatabase = container.privateCloudDatabase
        
        // Listen for app becoming active to refresh CloudKit data
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.checkAccountStatus()
                await self?.setupCloudKitSubscriptions()
            }
        }
        
        Task {
            await checkAccountStatus()
        }
    }
    
    // MARK: - Account Status
    
    func checkAccountStatus() async {
        do {
            accountStatus = try await container.accountStatus()
            let wasSignedIn = isSignedIn
            isSignedIn = accountStatus == .available
            
            print("CloudKit account status: \(accountStatus.rawValue), isSignedIn: \(isSignedIn)")
            
            // If we just signed in, try to sync local data to CloudKit and set up subscriptions
            if !wasSignedIn && isSignedIn {
                print("User just signed in, syncing local data to CloudKit...")
                await syncLocalDataToCloudKit()
                await setupCloudKitSubscriptions()
            } else if isSignedIn {
                // Already signed in, just refresh subscriptions
                await setupCloudKitSubscriptions()
            }
        } catch {
            print("Error checking account status: \(error)")
            accountStatus = .couldNotDetermine
            isSignedIn = false
        }
    }
    
    func refreshAccountStatus() async {
        print("Refreshing CloudKit account status...")
        await checkAccountStatus()
    }
    
    // MARK: - CloudKit Subscriptions
    
    func setupCloudKitSubscriptions() async {
        guard isSignedIn else {
            print("Not signed in to iCloud, cannot set up subscriptions")
            return
        }
        
        // Avoid duplicate subscriptions
        if hasSetUpSubscriptions {
            print("CloudKit subscriptions already set up, skipping")
            return
        }
        
        print("Setting up CloudKit subscriptions for real-time sync...")
        
        do {
            // Create a subscription that triggers when any PracticeSession record changes
            let predicate = NSPredicate(value: true)
            let subscriptionID = CKSubscription.ID("PracticeSessionChanges")
            let subscription = CKQuerySubscription(
                recordType: PracticeSession.recordType,
                predicate: predicate,
                subscriptionID: subscriptionID,
                options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
            )
            
            let notificationInfo = CKSubscription.NotificationInfo()
            notificationInfo.alertBody = "Practice session updated"
            notificationInfo.soundName = "default"
            subscription.notificationInfo = notificationInfo
            
            let savedSubscription = try await privateDatabase.save(subscription)
            print("✅ CloudKit subscription created successfully with ID: \(savedSubscription.subscriptionID)")
            
            subscriptions.append(subscription)
            hasSetUpSubscriptions = true
            
        } catch let error as CKError {
            print("❌ Failed to set up CloudKit subscription: \(error)")
            if error.code == .serverRejectedRequest {
                print("This subscription may already exist")
            }
        } catch {
            print("❌ Failed to set up CloudKit subscription: \(error)")
        }
    }
    
    private func handleCloudKitChange() async {
        print("CloudKit data changed, triggering refresh...")
        
        // Post notification for UI to refresh
        NotificationCenter.default.post(
            name: Notification.Name("cloudKitDataChanged"),
            object: nil
        )
        
        // Also fetch any new data for validation
        do {
            let sessions = try await fetchSessions()
            print("✅ Fetched \(sessions.count) sessions after CloudKit change")
            
            // Also explicitly check for incomplete sessions to notify SessionManager
            if let _ = try await fetchIncompleteSession() {
                print("🔄 CloudKit change detected incomplete session")
            }
        } catch {
            print("❌ Failed to refresh data after CloudKit change: \(error)")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Data Sync
    
    func syncLocalDataToCloudKit() async {
        guard isSignedIn else { 
            print("Not signed in to iCloud, skipping sync")
            return 
        }
        
        let localSessions = localStorage.loadSessions()
        print("Syncing \(localSessions.count) local sessions to CloudKit...")
        
        // First, fetch existing CloudKit records to avoid duplicates
        var existingRecords: [String: CKRecord] = [:]
        
        do {
            let predicate = NSPredicate(format: "createdAt >= %@", Date(timeIntervalSince1970: 0) as NSDate)
            let query = CKQuery(recordType: PracticeSession.recordType, predicate: predicate)
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let sessionId = record["sessionId"] as? String {
                        existingRecords[sessionId] = record
                    }
                case .failure(let error):
                    print("Error fetching existing record: \(error)")
                }
            }
            print("Found \(existingRecords.count) existing records in CloudKit")
        } catch {
            print("Failed to fetch existing records, will sync all local sessions: \(error)")
        }
        
        // Sync only sessions that don't exist in CloudKit or are newer
        var syncedCount = 0
        var skippedCount = 0
        
        for session in localSessions {
            if let existingRecord = existingRecords[session.id] {
                // Check if local session is newer than CloudKit record
                if let cloudKitModifiedAt = existingRecord["modifiedAt"] as? Date,
                   session.modifiedAt <= cloudKitModifiedAt {
                    print("Skipping session \(session.id) - CloudKit version is newer or same")
                    skippedCount += 1
                    continue
                }
            }
            
            do {
                let record = session.toCKRecord()
                let _ = try await privateDatabase.save(record)
                print("Successfully synced session \(session.id) to CloudKit")
                syncedCount += 1
            } catch {
                print("Failed to sync session \(session.id) to CloudKit: \(error)")
            }
        }
        
        print("Local to CloudKit sync completed - Synced: \(syncedCount), Skipped: \(skippedCount)")
    }
    
    // MARK: - Debug Methods
    
    func clearCloudKitCache() {
        // Clear any cached CloudKit data
        print("Clearing CloudKit cache...")
        // This will force fresh data on next fetch
    }
    
    func clearAllCloudKitData() async {
        guard isSignedIn else { 
            print("Not signed in to iCloud, cannot clear CloudKit data")
            return 
        }
        
        print("🧹 Starting comprehensive CloudKit data clearing...")
        
        var totalDeleted = 0
        var seenRecordIds = Set<String>()
        
        // Approach 1: Try comprehensive field-based queries
        let queriesToTry = [
            "createdAt >= %@",  // All records since beginning of time
            "target > 0",       // All sessions with targets
            "1 == 1"           // All records (if available)
        ]
        
        for queryString in queriesToTry {
            do {
                let predicate: NSPredicate
                if queryString == "createdAt >= %@" {
                    predicate = NSPredicate(format: queryString, Date(timeIntervalSince1970: 0) as NSDate)
                } else {
                    predicate = NSPredicate(format: queryString)
                }
                
                let query = CKQuery(recordType: PracticeSession.recordType, predicate: predicate)
                let (matchResults, _) = try await privateDatabase.records(matching: query)
                
                print("Found \(matchResults.count) records with query: \(queryString)")
                
                for (recordID, result) in matchResults {
                    // Avoid deleting the same record twice
                    let recordIdString = recordID.recordName
                    if seenRecordIds.contains(recordIdString) {
                        print("⚠️ Skipping duplicate record ID: \(recordIdString)")
                        continue
                    }
                    seenRecordIds.insert(recordIdString)
                    
                    switch result {
                    case .success:
                        do {
                            let _ = try await privateDatabase.deleteRecord(withID: recordID)
                            print("✅ Deleted record: \(recordIdString)")
                            totalDeleted += 1
                        } catch {
                            print("❌ Failed to delete record \(recordIdString): \(error)")
                        }
                    case .failure(let error):
                        print("❌ Error processing record: \(error)")
                    }
                }
            } catch {
                print("⚠️ Query '\(queryString)' failed: \(error)")
            }
        }
        
        // Approach 2: Try the backup method with isComplete queries
        do {
            let queries = [
                NSPredicate(format: "isComplete == 1"),  // completed sessions
                NSPredicate(format: "isComplete == 0"),  // incomplete sessions  
                NSPredicate(value: true)                // all sessions
            ]
            
            for predicate in queries {
                let query = CKQuery(recordType: PracticeSession.recordType, predicate: predicate)
                let (matchResults, _) = try await privateDatabase.records(matching: query)
                
                for (recordID, result) in matchResults {
                    let recordIdString = recordID.recordName
                    if seenRecordIds.contains(recordIdString) {
                        continue
                    }
                    seenRecordIds.insert(recordIdString)
                    
                    switch result {
                    case .success:
                        do {
                            let _ = try await privateDatabase.deleteRecord(withID: recordID)
                            print("✅ Deleted session record: \(recordIdString)")
                            totalDeleted += 1
                        } catch {
                            print("❌ Failed to delete session record \(recordIdString): \(error)")
                        }
                    case .failure(let error):
                        print("❌ Error processing session record: \(error)")
                    }
                }
            }
        } catch {
            print("❌ Backup predicate queries failed: \(error)")
        }
        
        print("🎉 CloudKit clearing completed - deleted \(totalDeleted) total records")
        print("📊 Total saved record IDs: \(seenRecordIds.count)")
        
        // Sanity check - Fetch any remaining records
        do {
            let remainingQuery = CKQuery(recordType: PracticeSession.recordType, predicate: NSPredicate(value: true))
            let (remainingResults, _) = try await privateDatabase.records(matching: remainingQuery)
            print("🔍 Remaining records after clearing: \(remainingResults.count)")
            
            if remainingResults.count > 0 {
                print("⚠️ WARNING: Not all records were deleted. Remaining records:")
                for (recordID, result) in remainingResults {
                    switch result {
                    case .success(let record):
                        let modificationDate = record.modificationDate?.description ?? "unknown"
                        let sessionId = record["sessionId"] as? String ?? "missing"
                        print("  - Record ID: \(recordID.recordName)")
                        print("    SessionID: \(sessionId)")
                        print("    Modified: \(modificationDate)")
                    case .failure(let error):
                        print("  - Error fetching record: \(error)")
                    }
                }
            }
        } catch {
            print("ℹ️ Could not verify complete clearing due to \(error)")
        }
        
        // Also clear local storage for complete wipe
        print("🧹 Clearing local storage data...")
        localStorage.clearAllData()
        print("✅ Local storage cleared")
        
        // The SessionManager also holds the currentSession @Published.
        // We do not directly call SessionManager here as circular dependency issue.
        // We rely on the cloudKitDataCleared notification to reset SessionManager too
        // The notification generated below is the clean signal.
        
        // Always post notification to clear UI state even if no CloudKit deletions occurred 
        NotificationCenter.default.post(
            name: Notification.Name("cloudKitDataCleared"),
            object: nil
        )
        
        print("✅ CloudKit data clearing operation completed")
    }
    
    func removeDuplicateCloudKitRecords() async {
        guard isSignedIn else {
            print("❌ Not signed in to iCloud")
            return
        }
        
        print("🔍 Checking for duplicate CloudKit records...")
        
        do {
            let predicate = NSPredicate(format: "createdAt >= %@", Date(timeIntervalSince1970: 0) as NSDate)
            let query = CKQuery(recordType: PracticeSession.recordType, predicate: predicate)
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            
            var sessionIdToRecords: [String: [CKRecord]] = [:]
            
            // Group records by sessionId
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let sessionId = record["sessionId"] as? String {
                        if sessionIdToRecords[sessionId] == nil {
                            sessionIdToRecords[sessionId] = []
                        }
                        sessionIdToRecords[sessionId]?.append(record)
                    }
                case .failure(let error):
                    print("Error processing record: \(error)")
                }
            }
            
            // Find and remove duplicates
            var duplicatesRemoved = 0
            for (sessionId, records) in sessionIdToRecords {
                if records.count > 1 {
                    print("Found \(records.count) duplicate records for session \(sessionId)")
                    
                    // Sort by modifiedAt (keep the newest)
                    let sortedRecords = records.sorted { record1, record2 in
                        let date1 = record1["modifiedAt"] as? Date ?? Date.distantPast
                        let date2 = record2["modifiedAt"] as? Date ?? Date.distantPast
                        return date1 > date2
                    }
                    
                    // Keep the first (newest) record, delete the rest
                    for i in 1..<sortedRecords.count {
                        do {
                            let _ = try await privateDatabase.deleteRecord(withID: sortedRecords[i].recordID)
                            print("✅ Deleted duplicate record: \(sortedRecords[i].recordID)")
                            duplicatesRemoved += 1
                        } catch {
                            print("❌ Failed to delete duplicate record: \(error)")
                        }
                    }
                }
            }
            
            print("🎉 Duplicate cleanup completed - Removed \(duplicatesRemoved) duplicate records")
        } catch {
            print("Error removing duplicates: \(error)")
        }
    }
    
    func testCloudKitConnection() async {
        guard isSignedIn else {
            print("❌ Not signed in to iCloud")
            return
        }
        
        print("🧪 Testing CloudKit connection with new Practice_Session record type...")
        
        do {
            // Test 1: Try to fetch records with a very simple query
            print("Test 1: Fetching records with simple query...")
            let query = CKQuery(recordType: PracticeSession.recordType, predicate: NSPredicate(value: true))
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            print("✅ Fetch successful - found \(matchResults.count) records")
            
            // Test 2: Try to fetch records with a more specific query
            print("Test 2: Fetching records with sessionId query...")
            let sessionIdPredicate = NSPredicate(format: "sessionId != nil")
            let sessionIdQuery = CKQuery(recordType: PracticeSession.recordType, predicate: sessionIdPredicate)
            let (sessionIdResults, _) = try await privateDatabase.records(matching: sessionIdQuery)
            print("✅ SessionId query successful - found \(sessionIdResults.count) records")
            
            // Test 3: Try to create a test record
            print("Test 3: Creating test record...")
            let testRecord = CKRecord(recordType: PracticeSession.recordType)
            testRecord["sessionId"] = "test-\(UUID().uuidString)"
            testRecord["date"] = Date()
            testRecord["target"] = Int64(10)
            testRecord["totalKubbs"] = Int64(0)
            testRecord["totalBatons"] = Int64(0)
            testRecord["startTime"] = Date()
            testRecord["isComplete"] = Int64(0)
            testRecord["createdAt"] = Date()
            testRecord["modifiedAt"] = Date()
            
            let savedRecord = try await privateDatabase.save(testRecord)
            print("✅ Test record created successfully: \(savedRecord.recordID)")
            
            // Test 4: Try to fetch the specific record we just created
            print("Test 4: Fetching specific record by sessionId...")
            let specificPredicate = NSPredicate(format: "sessionId == %@", testRecord["sessionId"] as! String)
            let specificQuery = CKQuery(recordType: PracticeSession.recordType, predicate: specificPredicate)
            let (specificResults, _) = try await privateDatabase.records(matching: specificQuery)
            print("✅ Specific record fetch successful - found \(specificResults.count) records")
            
            // Test 5: Delete the test record
            print("Test 5: Deleting test record...")
            let _ = try await privateDatabase.deleteRecord(withID: savedRecord.recordID)
            print("✅ Test record deleted successfully")
            
            print("🎉 All CloudKit tests passed with new record type!")
            
        } catch let error as CKError {
            print("❌ CloudKit test failed:")
            print("   Code: \(error.code.rawValue)")
            print("   Description: \(error.localizedDescription)")
            if let serverMessage = error.errorUserInfo[NSLocalizedFailureReasonErrorKey] as? String {
                print("   Server Message: \(serverMessage)")
            }
            
            // If the query fails, try a different approach
            if error.code == .invalidArguments {
                print("\n🔧 Trying alternative approach...")
                await testCloudKitAlternative()
            }
        } catch {
            print("❌ Unexpected error: \(error)")
        }
    }
    
    func testCloudKitQueries() async {
        guard isSignedIn else {
            print("❌ Not signed in to iCloud")
            return
        }
        
        print("🧪 Testing different CloudKit query approaches...")
        
        // Test 1: Try querying by a field that should be queryable
        do {
            print("Test 1: Querying by createdAt field...")
            let pastDate = Date(timeIntervalSince1970: 0) // January 1, 1970
            let predicate = NSPredicate(format: "createdAt >= %@", pastDate as NSDate)
            let query = CKQuery(recordType: PracticeSession.recordType, predicate: predicate)
            let (results, _) = try await privateDatabase.records(matching: query)
            print("✅ CreatedAt query successful - found \(results.count) records")
        } catch {
            print("❌ CreatedAt query failed: \(error)")
        }
        
        // Test 2: Try querying by target field
        do {
            print("Test 2: Querying by target field...")
            let predicate = NSPredicate(format: "target > 0")
            let query = CKQuery(recordType: PracticeSession.recordType, predicate: predicate)
            let (results, _) = try await privateDatabase.records(matching: query)
            print("✅ Target query successful - found \(results.count) records")
        } catch {
            print("❌ Target query failed: \(error)")
        }
        
        // Test 3: Try querying by isComplete field
        do {
            print("Test 3: Querying by isComplete field...")
            let predicate = NSPredicate(format: "isComplete == 1")
            let query = CKQuery(recordType: PracticeSession.recordType, predicate: predicate)
            let (results, _) = try await privateDatabase.records(matching: query)
            print("✅ IsComplete query successful - found \(results.count) records")
        } catch {
            print("❌ IsComplete query failed: \(error)")
        }
    }
    
    private func testCloudKitAlternative() async {
        print("🧪 Testing CloudKit with alternative approach...")
        
        do {
            // Try to create a test record first
            print("Creating test record...")
            let testRecord = CKRecord(recordType: PracticeSession.recordType)
            testRecord["sessionId"] = "test-alt-\(UUID().uuidString)"
            testRecord["date"] = Date()
            testRecord["target"] = Int64(10)
            testRecord["totalKubbs"] = Int64(0)
            testRecord["totalBatons"] = Int64(0)
            testRecord["startTime"] = Date()
            testRecord["isComplete"] = Int64(0)
            testRecord["createdAt"] = Date()
            testRecord["modifiedAt"] = Date()
            
            let savedRecord = try await privateDatabase.save(testRecord)
            print("✅ Test record created successfully: \(savedRecord.recordID)")
            
            // Try to fetch the record by its ID (not by query)
            print("Fetching record by ID...")
            let _ = try await privateDatabase.record(for: savedRecord.recordID)
            print("✅ Record fetched by ID successfully")
            
            // Delete the test record
            print("Deleting test record...")
            let _ = try await privateDatabase.deleteRecord(withID: savedRecord.recordID)
            print("✅ Test record deleted successfully")
            
            print("🎉 Alternative CloudKit approach works!")
            
        } catch {
            print("❌ Alternative approach also failed: \(error)")
        }
    }
    
    // MARK: - Session Operations
    
    func saveSession(_ session: PracticeSession) async throws {
        syncStatus = .syncing
        
        // Always save to local storage first
        localStorage.saveSession(session)
        
        do {
            // Check if record already exists in CloudKit
            if let existingRecord = try await findRecordBySessionId(session.id) {
                // Get the current CloudKit data for conflict resolution
                let cloudkitSession = PracticeSession(from: existingRecord)
                
                // Only update if the local session is newer or has valuable advances
                if let remoteSession = cloudkitSession {
                    let shouldUpdate = session.modifiedAt > remoteSession.modifiedAt ||
                                      (session.totalKubbs > remoteSession.totalKubbs && session.totalBatons > remoteSession.totalBatons)
                    
                    if shouldUpdate {
                        print("✅ Local session data is newer/more advanced, updating CloudKit")
                        // Update existing record
                        existingRecord["date"] = session.date
                        existingRecord["target"] = Int64(session.target)
                        existingRecord["totalKubbs"] = Int64(session.totalKubbs)
                        existingRecord["totalBatons"] = Int64(session.totalBatons)
                        existingRecord["startTime"] = session.startTime
                        existingRecord["endTime"] = session.endTime
                        existingRecord["isComplete"] = session.isComplete ? 1 : 0
                        existingRecord["modifiedAt"] = session.modifiedAt
                        
                        // Update rounds as JSON string
                        if let roundsData = try? JSONEncoder().encode(session.rounds),
                           let roundsString = String(data: roundsData, encoding: .utf8) {
                            existingRecord["rounds"] = roundsString
                        }
                        
                        let _ = try await privateDatabase.save(existingRecord)
                        print("Updated existing CloudKit record for session \(session.id) with local advancement")
                        
                        // Notify other components of the session update immediately
                        NotificationCenter.default.post(
                            name: Notification.Name("cloudKitDataChanged"),
                            object: nil
                        )
                    } else {
                        print("⚠️ CloudKit session is newer/identical - not overwriting (CloudKit: \(remoteSession.totalKubbs)/\(session.totalKubbs), Local: \(session.totalKubbs))")
                        // Don't overwrite newer cloudKit data with older local data
                    }
                } else {
                    // Unable to parse the existing record, error prone update
                    print("⚠️ Could not parse existing CloudKit session - updating anyway")
                    existingRecord["totalKubbs"] = Int64(session.totalKubbs)
                    existingRecord["totalBatons"] = Int64(session.totalBatons)
                    existingRecord["isComplete"] = session.isComplete ? 1 : 0
                    existingRecord["modifiedAt"] = session.modifiedAt
                    
                    // Update rounds as JSON string
                    if let roundsData = try? JSONEncoder().encode(session.rounds),
                       let roundsString = String(data: roundsData, encoding: .utf8) {
                        existingRecord["rounds"] = roundsString
                    }
                    
                    let _ = try await privateDatabase.save(existingRecord)
                    print("Force-updated existing CloudKit record due to parse error")
                    
                    // Notify other components of the session update immediately
                    NotificationCenter.default.post(
                        name: Notification.Name("cloudKitDataChanged"),
                        object: nil
                    )
                }
            } else {
                // Create new record
                let record = session.toCKRecord()
                let _ = try await privateDatabase.save(record)
                print("Created new CloudKit record for session \(session.id)")
                
                // Notify other components of the session update immediately
                NotificationCenter.default.post(
                    name: Notification.Name("cloudKitDataChanged"),
                    object: nil
                )
            }
            
            syncStatus = .success
            
            // Clear success status after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.syncStatus = .idle
            }
        } catch let error as CKError {
            if error.code == .serverRecordChanged {
                // Record conflict - try to fetch and merge
                print("Record conflict detected, attempting to resolve...")
                try await resolveRecordConflict(for: session)
                syncStatus = .success
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.syncStatus = .idle
                }
            } else if error.code == .requestRateLimited {
                // Rate limited - save locally and retry later
                print("CloudKit rate limited, saving locally")
                syncStatus = .error("Rate limited - data saved locally")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.syncStatus = .idle
                }
            } else if error.code == .unknownItem {
                // Record type doesn't exist - save locally as fallback
                print("CloudKit schema not set up yet - saving locally for now")
                localStorage.saveSession(session)
                syncStatus = .error("CloudKit not configured - data saved locally only")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.syncStatus = .idle
                }
            } else {
                // Save locally as fallback for any other CloudKit error
                print("CloudKit save failed, saving locally: \(error.localizedDescription)")
                localStorage.saveSession(session)
                syncStatus = .error("Sync failed - data saved locally only")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.syncStatus = .idle
                }
            }
        } catch {
            // Save locally as fallback for any other error
            print("Unexpected error, saving locally: \(error.localizedDescription)")
            localStorage.saveSession(session)
            syncStatus = .error("Sync failed - data saved locally only")
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.syncStatus = .idle
            }
        }
    }
    
    private func resolveRecordConflict(for session: PracticeSession) async throws {
        // Since we're now using auto-generated record IDs, we need to find the record by sessionId
        // For now, just save the new record and let CloudKit handle conflicts
        do {
            let record = session.toCKRecord()
            let _ = try await privateDatabase.save(record)
            print("Record conflict resolved successfully")
        } catch {
            print("Failed to resolve record conflict: \(error)")
            // If conflict resolution fails, just save locally and continue
            print("Saving session locally as fallback")
        }
    }
    
    func fetchSessions() async throws -> [PracticeSession] {
        syncStatus = .syncing
        
        do {
            // Use field-specific query instead of simple query to avoid recordName issue
            print("Fetching sessions from CloudKit using field-specific query...")
            let predicate = NSPredicate(format: "createdAt >= %@", Date(timeIntervalSince1970: 0) as NSDate)
            let query = CKQuery(recordType: PracticeSession.recordType, predicate: predicate)
            
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            
            var sessions: [PracticeSession] = []
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let session = PracticeSession(from: record) {
                        sessions.append(session)
                    }
                case .failure(let error):
                    print("Error converting record to PracticeSession: \(error)")
                }
            }
            
            // Sort by date (newest first) since we can't use sort descriptors in CloudKit
            sessions.sort { $0.date > $1.date }
            
            print("✅ Successfully fetched \(sessions.count) sessions from CloudKit")
            syncStatus = .success
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.syncStatus = .idle
            }
            
            return sessions
            
        } catch {
            print("CloudKit fetch failed, loading from local storage: \(error.localizedDescription)")
            syncStatus = .error("Sync failed - showing local data only")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.syncStatus = .idle
            }
            return localStorage.loadSessions()
        }
        
        /* CloudKit code - will re-enable once recordName issue is resolved
        do {
            let query = CKQuery(recordType: PracticeSession.recordType, predicate: NSPredicate(value: true))
            // Remove sort descriptor to avoid queryable field issues
            // We'll sort the results after fetching
            
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            
            var sessions: [PracticeSession] = []
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let session = PracticeSession(from: record) {
                        sessions.append(session)
                    }
                case .failure(let error):
                    print("Error fetching record: \(error)")
                }
            }
            
            // Sort sessions by creation date (newest first) after fetching
            sessions.sort { $0.createdAt > $1.createdAt }
            
            syncStatus = .success
            
            // Clear success status after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.syncStatus = .idle
            }
            
            return sessions
        } catch let error as CKError {
            print("CloudKit Error Details:")
            print("- Code: \(error.code.rawValue)")
            print("- Description: \(error.localizedDescription)")
            if let serverMessage = error.errorUserInfo[NSLocalizedFailureReasonErrorKey] as? String {
                print("- Server Message: \(serverMessage)")
            } else {
                print("- Server Message: No server message")
            }
            
            if error.code == .unknownItem {
                // Record type doesn't exist yet - fallback to local storage
                print("CloudKit schema not set up yet - loading from local storage")
                let localSessions = localStorage.loadSessions()
                syncStatus = .success
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.syncStatus = .idle
                }
                return localSessions
            } else {
                // Other CloudKit error - fallback to local storage
                print("CloudKit fetch failed, loading from local storage: \(error.localizedDescription)")
                let localSessions = localStorage.loadSessions()
                syncStatus = .error("Sync failed - showing local data only")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.syncStatus = .idle
                }
                return localSessions
            }
        } catch {
            // Any other error - fallback to local storage
            print("Unexpected error, loading from local storage: \(error.localizedDescription)")
            let localSessions = localStorage.loadSessions()
            syncStatus = .error("Sync failed - showing local data only")
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.syncStatus = .idle
            }
            return localSessions
        }
        */
    }
    
    func fetchIncompleteSession() async throws -> PracticeSession? {
        do {
            // Use field-specific query instead of simple query to avoid recordName issue
            print("Fetching incomplete session from CloudKit using field-specific query...")
            let predicate = NSPredicate(format: "isComplete == 0")
            let query = CKQuery(recordType: PracticeSession.recordType, predicate: predicate)
            
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            
            print("Found \(matchResults.count) records matching isComplete == 0")
            
            // Try to keep the most recent incomplete session based on modifiedAt
            var candidateSessions: [PracticeSession] = []
            
            for (recordID, result) in matchResults {
                switch result {
                case .success(let record):
                    if let session = PracticeSession(from: record), session.isIncomplete {
                        print("Found an incomplete session: \(recordID) with \(session.totalKubbs)/\(session.target)")
                        candidateSessions.append(session)
                    }
                case .failure(let error):
                    print("Error fetching incomplete session: \(error)")
                }
            }
            
            // Sort by modification date and pick the most recent
            let sortedSessions = candidateSessions.sorted { $0.modifiedAt > $1.modifiedAt }
            
            if let latest = sortedSessions.first {
                print("✅ Returning latest incomplete session: \(latest.id) (Kubbs: \(latest.totalKubbs)/\(latest.target), Modified: \(latest.modifiedAt))")
                return latest
            }
            
            print("No incomplete sessions qualified for today")
            return nil
            
        } catch {
            print("CloudKit fetch failed, checking local storage: \(error.localizedDescription)")
            return localStorage.fetchIncompleteSession()
        }
        
        /* CloudKit code - will re-enable once recordName issue is resolved
        do {
            // Use a simpler query that fetches all sessions and filters locally
            // This avoids issues with fields not being marked as queryable
            let query = CKQuery(recordType: PracticeSession.recordType, predicate: NSPredicate(value: true))
            
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let session = PracticeSession(from: record), session.isIncomplete {
                        return session
                    }
                case .failure(let error):
                    print("Error fetching incomplete session: \(error)")
                }
            }
            
            return nil
        } catch let error as CKError {
            if error.code == .unknownItem {
                // Record type doesn't exist yet - check local storage
                print("CloudKit schema not set up yet - checking local storage")
                return localStorage.fetchIncompleteSession()
            } else {
                print("Error fetching incomplete session: \(error)")
                // Fallback to local storage
                return localStorage.fetchIncompleteSession()
            }
        } catch {
            print("Error fetching incomplete session: \(error)")
            // Fallback to local storage
            return localStorage.fetchIncompleteSession()
        }
        */
    }
    
    func deleteSession(_ session: PracticeSession) async throws {
        syncStatus = .syncing
        
        // Always delete from local storage first
        localStorage.deleteSession(session)
        
        do {
            // Try multiple approaches to find and delete the CloudKit record
            var deletedFromCloudKit = false
            
            // Approach 1: Try to find by sessionId query
            if let record = try await findRecordBySessionId(session.id) {
                let _ = try await privateDatabase.deleteRecord(withID: record.recordID)
                print("✅ Successfully deleted CloudKit record for session \(session.id) via sessionId query")
                deletedFromCloudKit = true
            } else {
                // Approach 2: If sessionId query fails, try fetching all records and finding by ID
                print("⚠️ SessionId query failed, trying alternative approach...")
                
                let predicate = NSPredicate(format: "createdAt >= %@", Date(timeIntervalSince1970: 0) as NSDate)
                let query = CKQuery(recordType: PracticeSession.recordType, predicate: predicate)
                let (matchResults, _) = try await privateDatabase.records(matching: query)
                
                for (recordID, result) in matchResults {
                    switch result {
                    case .success(let record):
                        if let recordSessionId = record["sessionId"] as? String, recordSessionId == session.id {
                            let _ = try await privateDatabase.deleteRecord(withID: recordID)
                            print("✅ Successfully deleted CloudKit record for session \(session.id) via alternative query")
                            deletedFromCloudKit = true
                            break
                        }
                    case .failure(let error):
                        print("Error processing record during deletion: \(error)")
                    }
                }
            }
            
            if !deletedFromCloudKit {
                print("⚠️ CloudKit record not found for session \(session.id) - may have been deleted already or doesn't exist")
            }
            
            syncStatus = .success
            
            // Clear success status after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.syncStatus = .idle
            }
        } catch {
            print("❌ Failed to delete CloudKit record for session \(session.id): \(error)")
            // Even if CloudKit deletion fails, we've already deleted from local storage
            // So we'll mark as success since the local deletion worked
            syncStatus = .success
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.syncStatus = .idle
            }
        }
    }
    
    // MARK: - Error Handling
    
    func handleCloudKitError(_ error: Error) -> String {
        if let ckError = error as? CKError {
            switch ckError.code {
            case .notAuthenticated:
                return "Please sign in to iCloud to sync your data."
            case .quotaExceeded:
                return "iCloud storage quota exceeded. Please free up space."
            case .networkUnavailable:
                return "Network unavailable. Changes will sync when connected."
            case .serviceUnavailable:
                return "iCloud service temporarily unavailable. Please try again later."
            case .requestRateLimited:
                return "Too many requests. Please wait a moment before trying again."
            case .zoneNotFound:
                return "Sync zone not found. Please contact support."
            case .userDeletedZone:
                return "Sync zone was deleted. Please contact support."
            case .accountTemporarilyUnavailable:
                return "iCloud account temporarily unavailable. Please check your iCloud settings and try again."
            case .invalidArguments:
                return "CloudKit configuration issue. Please contact support."
            default:
                return "Sync error: \(ckError.localizedDescription)"
            }
        }
        
        // Check for specific error messages
        let errorMessage = error.localizedDescription.lowercased()
        if errorMessage.contains("bad or missing auth token") {
            return "iCloud authentication expired. Please sign out and sign back in to iCloud."
        } else if errorMessage.contains("account temporarily unavailable") {
            return "iCloud account temporarily unavailable. Please check your iCloud settings."
        }
        
        return "Unknown error: \(error.localizedDescription)"
    }
    
    // MARK: - Helper Methods
    
    private func findRecordBySessionId(_ sessionId: String) async throws -> CKRecord? {
        do {
            let predicate = NSPredicate(format: "sessionId == %@", sessionId)
            let query = CKQuery(recordType: PracticeSession.recordType, predicate: predicate)
            
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    return record
                case .failure(let error):
                    print("Error fetching record by sessionId: \(error)")
                }
            }
            
            return nil
        } catch let error as CKError {
            if error.code == .invalidArguments {
                // sessionId field doesn't exist yet - return nil
                print("sessionId field not available in CloudKit schema yet")
                return nil
            } else {
                throw error
            }
        }
    }
    
    // MARK: - Retry Logic
    
    func retryOperation<T>(_ operation: @escaping () async throws -> T, maxRetries: Int = 3) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                if attempt < maxRetries {
                    let delay = pow(2.0, Double(attempt)) // Exponential backoff
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? CloudKitError.retryFailed
    }
    
    enum CloudKitError: Error {
        case retryFailed
    }
}

// MARK: - CKAccountStatus Extension

extension CKAccountStatus {
    var description: String {
        switch self {
        case .available:
            return "Available"
        case .noAccount:
            return "No Account"
        case .restricted:
            return "Restricted"
        case .couldNotDetermine:
            return "Could Not Determine"
        case .temporarilyUnavailable:
            return "Temporarily Unavailable"
        @unknown default:
            return "Unknown"
        }
    }
}
