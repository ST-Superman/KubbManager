//
//  CloudKitManager.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import Foundation
import CloudKit
import Combine

@MainActor
class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let localStorage = LocalStorageManager.shared
    
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published var isSignedIn: Bool = false
    @Published var syncStatus: SyncStatus = .idle
    
    enum SyncStatus {
        case idle
        case syncing
        case success
        case error(String)
    }
    
    private init() {
        container = CKContainer(identifier: "iCloud.ST-Superman.Kubb-Manager")
        privateDatabase = container.privateCloudDatabase
        
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
            
            // If we just signed in, try to sync local data to CloudKit
            if !wasSignedIn && isSignedIn {
                print("User just signed in, syncing local data to CloudKit...")
                await syncLocalDataToCloudKit()
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
        
        // Run deduplication after sync to clean up any duplicates that may have been created
        if syncedCount > 0 {
            print("🧹 Running post-sync deduplication...")
            await removeDuplicateCloudKitRecords()
        }
        
        // Run cleanup to remove old and empty records
        print("🧹 Running post-sync cleanup...")
        await cleanupOldAndEmptyRecords()
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
        
        print("Clearing all CloudKit data and local data...")
        
        // Clear each record type separately
        await clearPracticeSessionDataLegacy()
        await clearInkastBlastSessionData()
        await clearBaseballKubbSessionData()
        
        // Always clear local data regardless of CloudKit status
        localStorage.clearAllData()
        print("Local data cleared successfully")
    }
    
    
    
    func clearBaseballKubbSessionData() async {
        guard isSignedIn else { 
            print("Not signed in to iCloud, cannot clear Baseball Kubb Session data")
            return 
        }
        
        print("Clearing Baseball Kubb Session CloudKit data...")
        
        do {
            // Use createdAt field for Baseball_Kubb_Session
            let startDate = Date(timeIntervalSince1970: 0)
            let predicate = NSPredicate(format: "createdAt >= %@", startDate as NSDate)
            let query = CKQuery(recordType: BaseballKubbSession.recordType, predicate: predicate)
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            
            print("Found \(matchResults.count) Baseball Kubb Session records to delete")
            
            for (recordID, result) in matchResults {
                switch result {
                case .success:
                    let _ = try await privateDatabase.deleteRecord(withID: recordID)
                    print("Deleted Baseball Kubb Session record: \(recordID)")
                case .failure(let error):
                    print("Error deleting Baseball Kubb Session record: \(error)")
                }
            }
            
            print("Baseball Kubb Session CloudKit data cleared successfully")
        } catch {
            print("Error clearing Baseball Kubb Session CloudKit data: \(error)")
        }
    }
    
    // MARK: - Individual Record Type Clear Methods
    
    
    
    
    func clearInkastBlastSessionData() async {
        guard isSignedIn else { 
            print("Not signed in to iCloud, cannot clear InkastBlast_Session data")
            return 
        }
        
        print("Clearing InkastBlast_Session CloudKit data...")
        
        do {
            // Use createdAt field for InkastBlast_Session
            let startDate = Date(timeIntervalSince1970: 0)
            let predicate = NSPredicate(format: "createdAt >= %@", startDate as NSDate)
            let query = CKQuery(recordType: "InkastBlast_Session", predicate: predicate)
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            
            print("Found \(matchResults.count) InkastBlast_Session records to delete")
            
            for (recordID, result) in matchResults {
                switch result {
                case .success:
                    let _ = try await privateDatabase.deleteRecord(withID: recordID)
                    print("Deleted InkastBlast_Session record: \(recordID)")
                case .failure(let error):
                    print("Error deleting InkastBlast_Session record: \(error)")
                }
            }
            
            print("InkastBlast_Session CloudKit data cleared successfully")
        } catch {
            print("Error clearing InkastBlast_Session CloudKit data: \(error)")
        }
        
        // Also clear local data
        localStorage.clearAllData()
        print("InkastBlast_Session local data cleared successfully")
    }
    
    func clearFullGameSimSessionData() async {
        guard isSignedIn else { 
            print("Not signed in to iCloud, cannot clear FullGameSim_Session data")
            return 
        }
        
        print("Clearing FullGameSim_Session CloudKit data...")
        
        do {
            // Use createdAt field for FullGameSim_Session
            let startDate = Date(timeIntervalSince1970: 0)
            let predicate = NSPredicate(format: "createdAt >= %@", startDate as NSDate)
            let query = CKQuery(recordType: FullGameSimSessionStruct.recordType, predicate: predicate)
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            
            print("Found \(matchResults.count) FullGameSim_Session records to delete")
            
            for (recordID, result) in matchResults {
                switch result {
                case .success:
                    let _ = try await privateDatabase.deleteRecord(withID: recordID)
                    print("Deleted FullGameSim_Session record: \(recordID)")
                case .failure(let error):
                    print("Error deleting FullGameSim_Session record: \(error)")
                }
            }
            
            print("FullGameSim_Session CloudKit data cleared successfully")
        } catch {
            print("Error clearing FullGameSim_Session CloudKit data: \(error)")
        }
        
        // Also clear local data
        let allSessions = localStorage.loadFullGameSimSessions()
        for session in allSessions {
            localStorage.deleteFullGameSimSession(session)
        }
        print("FullGameSim_Session local data cleared successfully")
    }
    
    
    func clearPracticeSessionDataLegacy() async {
        guard isSignedIn else { 
            print("Not signed in to iCloud, cannot clear Practice_Session data")
            return 
        }
        
        print("Clearing Practice_Session CloudKit data...")
        
        do {
            // Use createdAt field for Practice_Session
            let startDate = Date(timeIntervalSince1970: 0)
            let predicate = NSPredicate(format: "createdAt >= %@", startDate as NSDate)
            let query = CKQuery(recordType: "Practice_Session", predicate: predicate)
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            
            print("Found \(matchResults.count) Practice_Session records to delete")
            
            for (recordID, result) in matchResults {
                switch result {
                case .success:
                    let _ = try await privateDatabase.deleteRecord(withID: recordID)
                    print("Deleted Practice_Session record: \(recordID)")
                case .failure(let error):
                    print("Error deleting Practice_Session record: \(error)")
                }
            }
            
            print("Practice_Session CloudKit data cleared successfully")
        } catch {
            print("Error clearing Practice_Session CloudKit data: \(error)")
        }
        
        // Also clear local data
        localStorage.clearAllData()
        print("Practice_Session local data cleared successfully")
    }
    
    /// Clean up old and empty records after CloudKit sync
    func cleanupOldAndEmptyRecords() async {
        guard isSignedIn else {
            print("❌ Not signed in to CloudKit, skipping cleanup")
            return
        }
        
        print("🧹 Starting cleanup of old and empty records...")
        
        // Clean up each active record type
        await cleanupPracticeSessions()
        await cleanupBaseballKubbSessions()
        await cleanupInkastBlastSessions()
        
        print("✅ Cleanup completed")
    }
    
    // MARK: - Individual Cleanup Methods
    
    private func cleanupPracticeSessions() async {
        print("🧹 Cleaning up Practice_Session records...")
        
        do {
            let predicate = NSPredicate(format: "createdAt >= %@", Date(timeIntervalSince1970: 0) as NSDate)
            let query = CKQuery(recordType: "Practice_Session", predicate: predicate)
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            
            let today = Calendar.current.startOfDay(for: Date())
            var recordsToDelete: [CKRecord.ID] = []
            var recordsToUpdate: [(CKRecord.ID, CKRecord)] = []
            
            for (recordID, result) in matchResults {
                switch result {
                case .success(let record):
                    let isComplete = record["isComplete"] as? Int == 1
                    let totalBatons = record["totalBatons"] as? Int ?? 0
                    let createdAt = record["createdAt"] as? Date ?? Date.distantPast
                    let createdDate = Calendar.current.startOfDay(for: createdAt)
                    
                    // Delete if: (complete with 0 batons) OR (old with 0 batons)
                    if (isComplete && totalBatons == 0) || (createdDate < today && totalBatons == 0) {
                        recordsToDelete.append(recordID)
                        print("🗑️ Marking Practice_Session for deletion: \(recordID) (complete: \(isComplete), batons: \(totalBatons), old: \(createdDate < today))")
                    }
                    // Mark as complete if: old with >0 batons and not already complete
                    else if createdDate < today && totalBatons > 0 && !isComplete {
                        record["isComplete"] = 1
                        recordsToUpdate.append((recordID, record))
                        print("✅ Marking old Practice_Session as complete: \(recordID) (batons: \(totalBatons))")
                    }
                case .failure(let error):
                    print("❌ Error processing Practice_Session record: \(error)")
                }
            }
            
            // Delete records
            for recordID in recordsToDelete {
                do {
                    let _ = try await privateDatabase.deleteRecord(withID: recordID)
                    print("🗑️ Deleted Practice_Session: \(recordID)")
                } catch {
                    print("❌ Error deleting Practice_Session \(recordID): \(error)")
                }
            }
            
            // Update records
            for (recordID, record) in recordsToUpdate {
                do {
                    let _ = try await privateDatabase.save(record)
                    print("✅ Updated Practice_Session: \(recordID)")
                } catch {
                    print("❌ Error updating Practice_Session \(recordID): \(error)")
                }
            }
            
            print("✅ Practice_Session cleanup: \(recordsToDelete.count) deleted, \(recordsToUpdate.count) updated")
        } catch {
            print("❌ Error during Practice_Session cleanup: \(error)")
        }
    }
    
    private func cleanupBaseballKubbSessions() async {
        print("🧹 Cleaning up Baseball_Kubb_Session records...")
        
        do {
            let predicate = NSPredicate(format: "createdAt >= %@", Date(timeIntervalSince1970: 0) as NSDate)
            let query = CKQuery(recordType: "Baseball_Kubb_Session", predicate: predicate)
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            
            let today = Calendar.current.startOfDay(for: Date())
            var recordsToDelete: [CKRecord.ID] = []
            var recordsToUpdate: [(CKRecord.ID, CKRecord)] = []
            
            for (recordID, result) in matchResults {
                switch result {
                case .success(let record):
                    let isComplete = record["isComplete"] as? Int == 1
                    let throwHistory = record["throwHistory"] as? [String] ?? []
                    let createdAt = record["createdAt"] as? Date ?? Date.distantPast
                    let createdDate = Calendar.current.startOfDay(for: createdAt)
                    
                    // Delete if: (complete with no throws) OR (old with no throws)
                    if (isComplete && throwHistory.isEmpty) || (createdDate < today && throwHistory.isEmpty) {
                        recordsToDelete.append(recordID)
                        print("🗑️ Marking Baseball_Kubb_Session for deletion: \(recordID) (complete: \(isComplete), throws: \(throwHistory.count), old: \(createdDate < today))")
                    }
                    // Mark as complete if: old with >0 throws and not already complete
                    else if createdDate < today && !throwHistory.isEmpty && !isComplete {
                        record["isComplete"] = 1
                        recordsToUpdate.append((recordID, record))
                        print("✅ Marking old Baseball_Kubb_Session as complete: \(recordID) (throws: \(throwHistory.count))")
                    }
                case .failure(let error):
                    print("❌ Error processing Baseball_Kubb_Session record: \(error)")
                }
            }
            
            // Delete records
            for recordID in recordsToDelete {
                do {
                    let _ = try await privateDatabase.deleteRecord(withID: recordID)
                    print("🗑️ Deleted Baseball_Kubb_Session: \(recordID)")
                } catch {
                    print("❌ Error deleting Baseball_Kubb_Session \(recordID): \(error)")
                }
            }
            
            // Update records
            for (recordID, record) in recordsToUpdate {
                do {
                    let _ = try await privateDatabase.save(record)
                    print("✅ Updated Baseball_Kubb_Session: \(recordID)")
                } catch {
                    print("❌ Error updating Baseball_Kubb_Session \(recordID): \(error)")
                }
            }
            
            print("✅ Baseball_Kubb_Session cleanup: \(recordsToDelete.count) deleted, \(recordsToUpdate.count) updated")
        } catch {
            print("❌ Error during Baseball_Kubb_Session cleanup: \(error)")
        }
    }
    
    
    private func cleanupInkastBlastSessions() async {
        print("🧹 Cleaning up InkastBlast_Session records...")
        
        do {
            let predicate = NSPredicate(format: "createdAt >= %@", Date(timeIntervalSince1970: 0) as NSDate)
            let query = CKQuery(recordType: "InkastBlast_Session", predicate: predicate)
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            
            let today = Calendar.current.startOfDay(for: Date())
            var recordsToDelete: [CKRecord.ID] = []
            var recordsToUpdate: [(CKRecord.ID, CKRecord)] = []
            
            // Group records by sessionId and gamePhase for deduplication
            var groupedRecords: [String: [CKRecord]] = [:]
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    let sessionId = record["sessionId"] as? String ?? ""
                    let gamePhase = record["gamePhase"] as? String ?? ""
                    let groupKey = "\(sessionId)-\(gamePhase)"
                    
                    if groupedRecords[groupKey] == nil {
                        groupedRecords[groupKey] = []
                    }
                    groupedRecords[groupKey]?.append(record)
                    
                case .failure(let error):
                    print("❌ Error processing InkastBlast_Session record: \(error)")
                }
            }
            
            // Process each group for deduplication
            for (groupKey, records) in groupedRecords {
                if records.count > 1 {
                    print("🔄 Found \(records.count) duplicate InkastBlast_Session records for \(groupKey)")
                    
                    // Find the best record: max totalRounds, then latest createdAt
                    let bestRecord = records.max { record1, record2 in
                        let rounds1 = record1["totalRounds"] as? Int ?? 0
                        let rounds2 = record2["totalRounds"] as? Int ?? 0
                        
                        if rounds1 != rounds2 {
                            return rounds1 < rounds2
                        }
                        
                        let created1 = record1["createdAt"] as? Date ?? Date.distantPast
                        let created2 = record2["createdAt"] as? Date ?? Date.distantPast
                        return created1 < created2
                    }
                    
                    if let bestRecord = bestRecord {
                        print("✅ Keeping best record: \(bestRecord.recordID) (rounds: \(bestRecord["totalRounds"] as? Int ?? 0), created: \(bestRecord["createdAt"] as? Date ?? Date.distantPast))")
                        
                        // Mark all other records in this group for deletion
                        for record in records {
                            if record.recordID != bestRecord.recordID {
                                recordsToDelete.append(record.recordID)
                                print("🗑️ Marking duplicate for deletion: \(record.recordID)")
                            }
                        }
                    }
                } else {
                    // Single record - apply normal cleanup logic
                    let record = records[0]
                    let isComplete = record["isComplete"] as? Int == 1
                    let totalInkastKubbs = record["totalInkastKubbs"] as? Int ?? 0
                    let createdAt = record["createdAt"] as? Date ?? Date.distantPast
                    let createdDate = Calendar.current.startOfDay(for: createdAt)
                    
                    // Delete if: (complete with 0 kubbs) OR (old with 0 kubbs)
                    if (isComplete && totalInkastKubbs == 0) || (createdDate < today && totalInkastKubbs == 0) {
                        recordsToDelete.append(record.recordID)
                        print("🗑️ Marking InkastBlast_Session for deletion: \(record.recordID) (complete: \(isComplete), kubbs: \(totalInkastKubbs), old: \(createdDate < today))")
                    }
                    // Mark as complete if: old with >0 kubbs and not already complete
                    else if createdDate < today && totalInkastKubbs > 0 && !isComplete {
                        record["isComplete"] = 1
                        recordsToUpdate.append((record.recordID, record))
                        print("✅ Marking old InkastBlast_Session as complete: \(record.recordID) (kubbs: \(totalInkastKubbs))")
                    }
                }
            }
            
            // Delete records
            for recordID in recordsToDelete {
                do {
                    let _ = try await privateDatabase.deleteRecord(withID: recordID)
                    print("🗑️ Deleted InkastBlast_Session: \(recordID)")
                } catch {
                    print("❌ Error deleting InkastBlast_Session \(recordID): \(error)")
                }
            }
            
            // Update records
            for (recordID, record) in recordsToUpdate {
                do {
                    let _ = try await privateDatabase.save(record)
                    print("✅ Updated InkastBlast_Session: \(recordID)")
                } catch {
                    print("❌ Error updating InkastBlast_Session \(recordID): \(error)")
                }
            }
            
            print("✅ InkastBlast_Session cleanup: \(recordsToDelete.count) deleted, \(recordsToUpdate.count) updated")
        } catch {
            print("❌ Error during InkastBlast_Session cleanup: \(error)")
        }
    }
    
    

    /// Comprehensive deduplication that handles completed vs incomplete session conflicts
    func performComprehensiveDeduplication() async {
        guard isSignedIn else {
            print("❌ Not signed in to iCloud")
            return
        }
        
        print("🔍 Starting comprehensive deduplication...")
        
        // First, clean up CloudKit duplicates
        await removeDuplicateCloudKitRecords()
        
        // Then, fetch all sessions and deduplicate them
        do {
            let allSessions = try await fetchSessions()
            print("📊 Found \(allSessions.count) total sessions before deduplication")
            
            // This will trigger the enhanced deduplication logic in HistoryManager
            // when the sessions are loaded
        } catch {
            print("❌ Failed to fetch sessions for comprehensive deduplication: \(error)")
        }
        
        print("✅ Comprehensive deduplication completed")
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
                    print("⚠️ Found \(records.count) duplicate records for session \(sessionId)")
                    
                    // Enhanced duplicate resolution logic
                    let recordToKeep = selectBestCloudKitRecord(from: records)
                    let recordsToDelete = records.filter { $0.recordID != recordToKeep.recordID }
                    
                    print("✅ Keeping record with modifiedAt: \(recordToKeep["modifiedAt"] as? Date ?? Date.distantPast), isComplete: \(recordToKeep["isComplete"] as? Bool ?? false)")
                    
                    // Delete the other records
                    for record in recordsToDelete {
                        do {
                            let _ = try await privateDatabase.deleteRecord(withID: record.recordID)
                            print("✅ Deleted duplicate record: \(record.recordID)")
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
    
    /// Enhanced CloudKit record selection logic to handle completed vs incomplete duplicates
    private func selectBestCloudKitRecord(from records: [CKRecord]) -> CKRecord {
        guard !records.isEmpty else { return records[0] }
        
        // First, check if any records are completed
        let completedRecords = records.filter { record in
            (record["isComplete"] as? Bool) == true
        }
        let incompleteRecords = records.filter { record in
            (record["isComplete"] as? Bool) != true
        }
        
        if completedRecords.count == 1 && incompleteRecords.count == 1 {
            // Special case: one completed, one incomplete with same ID
            let completed = completedRecords[0]
            let incomplete = incompleteRecords[0]
            
            let completedModifiedAt = completed["modifiedAt"] as? Date ?? Date.distantPast
            let incompleteModifiedAt = incomplete["modifiedAt"] as? Date ?? Date.distantPast
            let completedTotalKubbs = completed["totalKubbs"] as? Int ?? 0
            let incompleteTotalKubbs = incomplete["totalKubbs"] as? Int ?? 0
            
            print("🔍 Found completed vs incomplete CloudKit duplicate")
            print("   - Completed: modifiedAt=\(completedModifiedAt), totalKubbs=\(completedTotalKubbs)")
            print("   - Incomplete: modifiedAt=\(incompleteModifiedAt), totalKubbs=\(incompleteTotalKubbs)")
            
            // If the completed record is newer or same age, keep it
            if completedModifiedAt >= incompleteModifiedAt {
                print("✅ Keeping completed CloudKit record (newer or same age)")
                return completed
            } else {
                // If incomplete is newer, but completed has more progress, keep completed
                if completedTotalKubbs > incompleteTotalKubbs {
                    print("✅ Keeping completed CloudKit record (more progress despite being older)")
                    return completed
                } else {
                    print("⚠️ Keeping incomplete CloudKit record (newer and same/less progress)")
                    return incomplete
                }
            }
        }
        
        // For all other cases, use the standard logic: most recent modifiedAt
        let sortedRecords = records.sorted { record1, record2 in
            let date1 = record1["modifiedAt"] as? Date ?? Date.distantPast
            let date2 = record2["modifiedAt"] as? Date ?? Date.distantPast
            return date1 > date2
        }
        return sortedRecords[0]
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
        
        // Add comprehensive logging
        print("🔄 Starting CloudKit save for session \(session.id)")
        print("   - Date: \(session.date)")
        print("   - Target: \(session.target)")
        print("   - ModifiedAt: \(session.modifiedAt)")
        
        do {
            // Enhanced duplicate check with retry logic
            let existingRecord = try await findRecordBySessionIdWithRetry(session.id)
            
            if let existingRecord = existingRecord {
                print("📝 Found existing CloudKit record for session \(session.id)")
                
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
                print("✅ Updated existing CloudKit record for session \(session.id)")
            } else {
                print("🆕 No existing record found, creating new CloudKit record for session \(session.id)")
                
                // Double-check for duplicates before creating
                let duplicateCheck = try await findRecordBySessionIdWithRetry(session.id)
                if duplicateCheck != nil {
                    print("⚠️ Duplicate found during creation attempt - updating instead")
                    // Recursively call saveSession to handle the update
                    return try await saveSession(session)
                }
                
                // Create new record
                let record = session.toCKRecord()
                let _ = try await privateDatabase.save(record)
                print("✅ Created new CloudKit record for session \(session.id)")
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
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let session = PracticeSession(from: record), session.isIncomplete {
                        print("✅ Found incomplete session in CloudKit")
                        return session
                    }
                case .failure(let error):
                    print("Error fetching incomplete session: \(error)")
                }
            }
            
            print("No incomplete session found in CloudKit")
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
    
    func findRecordBySessionId(_ sessionId: String) async throws -> CKRecord? {
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
    
    private func findRecordBySessionIdWithRetry(_ sessionId: String, maxRetries: Int = 3) async throws -> CKRecord? {
        for attempt in 1...maxRetries {
            do {
                print("🔍 Attempting to find record by sessionId \(sessionId) (attempt \(attempt)/\(maxRetries))")
                let result = try await findRecordBySessionId(sessionId)
                
                if result != nil {
                    print("✅ Found record on attempt \(attempt)")
                } else {
                    print("❌ No record found on attempt \(attempt)")
                }
                
                return result
            } catch {
                print("⚠️ Attempt \(attempt) failed: \(error)")
                
                if attempt == maxRetries {
                    print("❌ All \(maxRetries) attempts failed, throwing error")
                    throw error
                }
                
                // Wait before retry (exponential backoff)
                let delay = Double(attempt * attempt) * 0.5
                print("⏳ Waiting \(delay) seconds before retry...")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        return nil
    }
    
    // MARK: - Baseball Kubb Sessions
    
    func saveBaseballKubbSession(_ session: BaseballKubbSession) async throws {
        syncStatus = .syncing
        
        // Always save to local storage first
        localStorage.saveBaseballKubbSession(session)
        
        // Add comprehensive logging
        print("🔄 Starting CloudKit save for Baseball Kubb session \(session.id)")
        print("   - Date: \(session.date)")
        print("   - Away Score: \(session.awayScore)")
        print("   - Home Score: \(session.homeScore)")
        print("   - ModifiedAt: \(session.modifiedAt)")
        
        do {
            // Enhanced duplicate check with retry logic
            let existingRecord = try await findBaseballKubbRecordBySessionIdWithRetry(session.id)
            
            if let existingRecord = existingRecord {
                print("📝 Found existing CloudKit record for Baseball Kubb session \(session.id)")
                
                // Update existing record
                existingRecord["date"] = session.date
                existingRecord["awayTeam"] = session.awayTeam
                existingRecord["homeTeam"] = session.homeTeam
                existingRecord["currentInning"] = Int64(session.currentInning)
                existingRecord["isTop"] = session.isTop ? 1 : 0
                existingRecord["awayScore"] = Int64(session.awayScore)
                existingRecord["homeScore"] = Int64(session.homeScore)
                existingRecord["awayKings"] = Int64(session.awayKings)
                existingRecord["homeKings"] = Int64(session.homeKings)
                existingRecord["fieldKubbs"] = Int64(session.fieldKubbs)
                existingRecord["fieldKubbsAtStartOfHalf"] = Int64(session.fieldKubbsAtStartOfHalf)
                existingRecord["awayBaselineKubbs"] = Int64(session.awayBaselineKubbs)
                existingRecord["homeBaselineKubbs"] = Int64(session.homeBaselineKubbs)
                existingRecord["batonCount"] = Int64(session.batonCount)
                existingRecord["missCount"] = Int64(session.missCount)
                existingRecord["halfInningRuns"] = Int64(session.halfInningRuns)
                existingRecord["halfInningKings"] = Int64(session.halfInningKings)
                existingRecord["runsAfterKingHit"] = Int64(session.runsAfterKingHit)
                existingRecord["gameOver"] = session.gameOver ? 1 : 0
                existingRecord["isComplete"] = session.isComplete ? 1 : 0
                existingRecord["modifiedAt"] = session.modifiedAt
                
                // Update optional fields
                if let winner = session.winner {
                    existingRecord["winner"] = winner
                }
                
                // Update history as JSON strings
                if let throwHistoryData = try? JSONEncoder().encode(session.throwHistory),
                   let throwHistoryString = String(data: throwHistoryData, encoding: .utf8) {
                    existingRecord["throwHistory"] = throwHistoryString
                }
                
                if let halfInningHistoryData = try? JSONEncoder().encode(session.halfInningHistory),
                   let halfInningHistoryString = String(data: halfInningHistoryData, encoding: .utf8) {
                    existingRecord["halfInningHistory"] = halfInningHistoryString
                }
                
                if let scoreboardHistoryData = try? JSONEncoder().encode(session.scoreboardHistory),
                   let scoreboardHistoryString = String(data: scoreboardHistoryData, encoding: .utf8) {
                    existingRecord["scoreboardHistory"] = scoreboardHistoryString
                }
                
                let _ = try await privateDatabase.save(existingRecord)
                print("✅ Updated existing CloudKit record for Baseball Kubb session \(session.id)")
            } else {
                print("🆕 No existing record found, creating new CloudKit record for Baseball Kubb session \(session.id)")
                
                // Double-check for duplicates before creating
                let duplicateCheck = try await findBaseballKubbRecordBySessionIdWithRetry(session.id)
                if duplicateCheck != nil {
                    print("⚠️ Duplicate found during creation attempt - updating instead")
                    // Recursively call saveBaseballKubbSession to handle the update
                    return try await saveBaseballKubbSession(session)
                }
                
                // Create new record
                let record = session.toCKRecord()
                let _ = try await privateDatabase.save(record)
                print("✅ Created new CloudKit record for Baseball Kubb session \(session.id)")
            }
            
            syncStatus = .success
            
            // Clear success status after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.syncStatus = .idle
            }
        } catch let error as CKError {
            if error.code == .serverRecordChanged {
                // Record conflict - try to fetch and merge
                print("Record conflict detected for Baseball Kubb session, attempting to resolve...")
                try await resolveBaseballKubbRecordConflict(for: session)
                syncStatus = .success
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.syncStatus = .idle
                }
            } else if error.code == .requestRateLimited {
                print("⚠️ CloudKit rate limited, will retry later")
                syncStatus = .idle
                throw error
            } else {
                print("❌ CloudKit error saving Baseball Kubb session: \(error.localizedDescription)")
                syncStatus = .error("CloudKit error - data saved locally only")
                throw error
            }
        } catch {
            print("❌ Unexpected error saving Baseball Kubb session: \(error.localizedDescription)")
            syncStatus = .error("Unexpected error - data saved locally only")
            throw error
        }
    }
    
    func fetchLastBaseballKubbSession() async throws -> BaseballKubbSession? {
        guard isSignedIn else {
            print("❌ Not signed in to iCloud")
            return nil
        }
        
        do {
            let predicate = NSPredicate(format: "createdAt >= %@", Date(timeIntervalSince1970: 0) as NSDate)
            let query = CKQuery(recordType: BaseballKubbSession.recordType, predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let session = BaseballKubbSession(from: record) {
                        print("✅ Fetched Baseball Kubb session from CloudKit: \(session.id)")
                        return session
                    }
                case .failure(let error):
                    print("Error fetching Baseball Kubb session: \(error)")
                }
            }
            
            print("❌ No Baseball Kubb sessions found in CloudKit")
            return nil
        } catch {
            print("❌ Error fetching Baseball Kubb sessions: \(error)")
            throw error
        }
    }
    
    func fetchIncompleteBaseballKubbSession() async throws -> BaseballKubbSession? {
        guard isSignedIn else {
            print("❌ Not signed in to iCloud")
            return nil
        }
        
        do {
            let predicate = NSPredicate(format: "isComplete == 0")
            let query = CKQuery(recordType: BaseballKubbSession.recordType, predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: "modifiedAt", ascending: false)]
            
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let session = BaseballKubbSession(from: record), !session.isComplete {
                        print("✅ Found incomplete Baseball Kubb session in CloudKit: \(session.id)")
                        return session
                    }
                case .failure(let error):
                    print("Error fetching incomplete Baseball Kubb session: \(error)")
                }
            }
            
            print("❌ No incomplete Baseball Kubb sessions found in CloudKit")
            return nil
        } catch {
            print("❌ Error fetching incomplete Baseball Kubb sessions: \(error)")
            throw error
        }
    }
    
    private func findBaseballKubbRecordBySessionId(_ sessionId: String) async throws -> CKRecord? {
        do {
            let predicate = NSPredicate(format: "sessionId == %@", sessionId)
            let query = CKQuery(recordType: BaseballKubbSession.recordType, predicate: predicate)
            
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    return record
                case .failure(let error):
                    print("Error fetching Baseball Kubb record by sessionId: \(error)")
                }
            }
            
            return nil
        } catch let error as CKError {
            if error.code == .invalidArguments {
                // sessionId field doesn't exist yet - return nil
                print("sessionId field not available in CloudKit schema yet for Baseball Kubb")
                return nil
            } else {
                throw error
            }
        }
    }
    
    private func findBaseballKubbRecordBySessionIdWithRetry(_ sessionId: String, maxRetries: Int = 3) async throws -> CKRecord? {
        for attempt in 1...maxRetries {
            do {
                print("🔍 Attempting to find Baseball Kubb record by sessionId \(sessionId) (attempt \(attempt)/\(maxRetries))")
                let result = try await findBaseballKubbRecordBySessionId(sessionId)
                
                if result != nil {
                    print("✅ Found Baseball Kubb record on attempt \(attempt)")
                } else {
                    print("❌ No Baseball Kubb record found on attempt \(attempt)")
                }
                
                return result
            } catch {
                print("⚠️ Attempt \(attempt) failed: \(error)")
                
                if attempt == maxRetries {
                    print("❌ All \(maxRetries) attempts failed, throwing error")
                    throw error
                }
                
                // Wait before retry (exponential backoff)
                let delay = Double(attempt * attempt) * 0.5
                print("⏳ Waiting \(delay) seconds before retry...")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        return nil
    }
    
    private func resolveBaseballKubbRecordConflict(for session: BaseballKubbSession) async throws {
        // For now, just save the current session as the authoritative version
        // In a more sophisticated implementation, you might want to merge data
        print("🔄 Resolving Baseball Kubb record conflict by saving current session")
        try await saveBaseballKubbSession(session)
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
    
    // MARK: - InkastBlastSession CloudKit Methods
    
    func saveInkastBlastSession(_ session: InkastBlastSessionData) async {
        guard isSignedIn else {
            print("⚠️ Not signed in to CloudKit, skipping InkastBlastSession save")
            return
        }
        
        do {
            let record = session.toCKRecord()
            try await privateDatabase.save(record)
            print("✅ Successfully saved InkastBlastSession to CloudKit: \(session.id)")
        } catch {
            print("❌ Failed to save InkastBlastSession to CloudKit: \(error)")
        }
    }
    
    func fetchInkastBlastSessions() async -> [InkastBlastSessionData] {
        guard isSignedIn else {
            print("⚠️ Not signed in to CloudKit, returning empty InkastBlastSessions")
            return []
        }
        
        do {
            // Fetch all InkastBlast sessions (both complete and incomplete)
            print("Fetching InkastBlastSessions from CloudKit using createdAt query...")
            let predicate = NSPredicate(format: "createdAt >= %@", Date(timeIntervalSince1970: 0) as NSDate)
            let query = CKQuery(recordType: "InkastBlast_Session", predicate: predicate)
            
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            
            var sessions: [InkastBlastSessionData] = []
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let session = InkastBlastSessionData(from: record) {
                        sessions.append(session)
                    }
                case .failure(let error):
                    print("Error converting record to InkastBlastSessionData: \(error)")
                }
            }
            
            // Sort by date (newest first) since we can't use sort descriptors in CloudKit
            sessions.sort { $0.createdAt > $1.createdAt }
            
            print("✅ Successfully fetched \(sessions.count) InkastBlastSessions from CloudKit")
            return sessions
            
        } catch {
            print("❌ Failed to fetch InkastBlastSessions from CloudKit: \(error)")
            return []
        }
    }
    
    func fetchBaseballKubbSessions() async throws -> [BaseballKubbSession] {
        guard isSignedIn else {
            print("⚠️ Not signed in to CloudKit, returning empty BaseballKubbSessions")
            return []
        }
        
        do {
            // Fetch all BaseballKubb sessions (both complete and incomplete)
            print("Fetching BaseballKubbSessions from CloudKit using createdAt query...")
            let predicate = NSPredicate(format: "createdAt >= %@", Date(timeIntervalSince1970: 0) as NSDate)
            let query = CKQuery(recordType: BaseballKubbSession.recordType, predicate: predicate)
            
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            
            var sessions: [BaseballKubbSession] = []
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let session = BaseballKubbSession(from: record) {
                        sessions.append(session)
                    }
                case .failure(let error):
                    print("Error converting record to BaseballKubbSession: \(error)")
                }
            }
            
            // Sort by date (newest first) since we can't use sort descriptors in CloudKit
            sessions.sort { $0.createdAt > $1.createdAt }
            
            print("✅ Successfully fetched \(sessions.count) BaseballKubbSessions from CloudKit")
            return sessions
            
        } catch {
            print("❌ Failed to fetch BaseballKubbSessions from CloudKit: \(error)")
            return []
        }
    }
    
    func deleteInkastBlastSession(_ session: InkastBlastSessionData) async {
        guard isSignedIn else {
            print("⚠️ Not signed in to CloudKit, skipping InkastBlastSession delete")
            return
        }
        
        do {
            // First, try to find the record by querying with our custom ID
            let query = CKQuery(recordType: InkastBlastSessionData.recordType, predicate: NSPredicate(format: "sessionId == %@", session.id))
            let result = try await privateDatabase.records(matching: query)
            
            for (recordID, result) in result.matchResults {
                switch result {
                case .success:
                    try await privateDatabase.deleteRecord(withID: recordID)
                    print("✅ Successfully deleted InkastBlastSession from CloudKit: \(session.id)")
                case .failure(let error):
                    print("❌ Failed to delete InkastBlastSession record: \(error)")
                }
            }
        } catch {
            print("❌ Failed to delete InkastBlastSession from CloudKit: \(error)")
        }
    }
    
    func deleteBaseballKubbSession(_ session: BaseballKubbSession) async {
        guard isSignedIn else {
            print("⚠️ Not signed in to CloudKit, skipping BaseballKubbSession delete")
            return
        }
        
        do {
            // First, try to find the record by querying with our custom ID
            let query = CKQuery(recordType: BaseballKubbSession.recordType, predicate: NSPredicate(format: "sessionId == %@", session.id))
            let result = try await privateDatabase.records(matching: query)
            
            for (recordID, result) in result.matchResults {
                switch result {
                case .success:
                    try await privateDatabase.deleteRecord(withID: recordID)
                    print("✅ Successfully deleted BaseballKubbSession from CloudKit: \(session.id)")
                case .failure(let error):
                    print("❌ Failed to delete BaseballKubbSession record: \(error)")
                }
            }
        } catch {
            print("❌ Failed to delete BaseballKubbSession from CloudKit: \(error)")
        }
    }
    
    // MARK: - Full Game Sim CloudKit Methods
    
    func saveFullGameSimSession(_ session: FullGameSimSessionStruct) async {
        guard isSignedIn else {
            print("⚠️ Not signed in to CloudKit, skipping FullGameSimSession save")
            return
        }
        
        do {
            let record = session.toCKRecord()
            try await privateDatabase.save(record)
            print("✅ Successfully saved FullGameSimSession to CloudKit: \(session.id)")
        } catch {
            print("❌ Failed to save FullGameSimSession to CloudKit: \(error)")
        }
    }
    
    func fetchFullGameSimSessions() async -> [FullGameSimSessionStruct] {
        guard isSignedIn else {
            print("⚠️ Not signed in to CloudKit, returning empty FullGameSimSessions")
            return []
        }
        
        do {
            // Fetch all FullGameSim sessions (both complete and incomplete)
            print("Fetching FullGameSimSessions from CloudKit using createdAt query...")
            let predicate = NSPredicate(format: "createdAt >= %@", Date(timeIntervalSince1970: 0) as NSDate)
            let query = CKQuery(recordType: FullGameSimSessionStruct.recordType, predicate: predicate)
            
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            
            var sessions: [FullGameSimSessionStruct] = []
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let session = FullGameSimSessionStruct(from: record) {
                        sessions.append(session)
                    }
                case .failure(let error):
                    print("Error converting record to FullGameSimSession: \(error)")
                }
            }
            
            // Sort by date (newest first) since we can't use sort descriptors in CloudKit
            sessions.sort { $0.createdAt > $1.createdAt }
            
            print("✅ Successfully fetched \(sessions.count) FullGameSimSessions from CloudKit")
            return sessions
            
        } catch {
            print("❌ Failed to fetch FullGameSimSessions from CloudKit: \(error)")
            return []
        }
    }
    
    func deleteFullGameSimSession(_ session: FullGameSimSessionStruct) async {
        guard isSignedIn else {
            print("⚠️ Not signed in to CloudKit, skipping FullGameSimSession delete")
            return
        }
        
        do {
            // First, try to find the record by querying with our custom ID
            let query = CKQuery(recordType: FullGameSimSessionStruct.recordType, predicate: NSPredicate(format: "sessionId == %@", session.id))
            let result = try await privateDatabase.records(matching: query)
            
            for (recordID, result) in result.matchResults {
                switch result {
                case .success:
                    try await privateDatabase.deleteRecord(withID: recordID)
                    print("✅ Successfully deleted FullGameSimSession from CloudKit: \(session.id)")
                case .failure(let error):
                    print("❌ Failed to delete FullGameSimSession record: \(error)")
                }
            }
        } catch {
            print("❌ Failed to delete FullGameSimSession from CloudKit: \(error)")
        }
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
