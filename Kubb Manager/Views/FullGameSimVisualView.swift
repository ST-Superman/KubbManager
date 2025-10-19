//
//  FullGameSimVisualView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 1/15/25.
//

import SwiftUI

// MARK: - Visual Components for Full Game Sim

struct FullGameSimVisualView: View {
    let phase: FullGamePhase
    let roundData: FullGameSimRoundStruct
    let onKubbHit: (Int) -> Void
    let onKubbMiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            switch phase {
            case .attacking:
                AttackingVisualView(
                    roundData: roundData,
                    onKubbHit: onKubbHit,
                    onMiss: onKubbMiss
                )
            case .inkast:
                InkastVisualView(
                    roundData: roundData.inkastData,
                    onKubbHit: onKubbHit,
                    onMiss: onKubbMiss
                )
            case .roundComplete:
                RoundCompleteView(roundData: roundData)
            }
        }
    }
}

// MARK: - Main Round Visual View (New Design)

struct FullGameRoundVisualView: View {
    let roundData: FullGameSimRoundStruct
    let currentPhase: FullGamePhase
    let sessionData: FullGameSimSessionStruct
    let skinManager: SkinManager
    let onHit: (Int) -> Void
    let onMiss: () -> Void
    @State private var selectedKubbsHit: Int = 1
    
    var body: some View {
        VStack(spacing: 0) {
            // Top: Baseline Kubbs (show when in attacking phase)
            if currentPhase == .attacking {
                BaselineKubbsSection(
                    totalBaselineKubbs: 5, // Always 5 baseline kubbs total
                    knockedDownBaselineKubbs: roundData.baselineKubbsHit, // Baseline kubbs hit this round
                    fieldKubbsCleared: roundData.blastData.kubbsClearedFirstThrow,
                    skin: skinManager.selectedKubbSkin,
                    attackingTeam: sessionData.currentAttackingTeam
                )
                
                Spacer()
            }
            
            // Middle: Field Kubbs (only show when in blast phase)
            if currentPhase == .attacking && roundData.inkastData.inkastKubbs > 0 {
                FieldKubbsSection(
                    totalFieldKubbs: roundData.inkastData.inkastKubbs,
                    knockedDownFieldKubbs: roundData.blastData.kubbsClearedFirstThrow,
                    skin: skinManager.selectedKubbSkin
                )
                
                Spacer()
            }
            
            // Inkast Phase: Show kubbs to inkast
            if currentPhase == .inkast {
                InkastPhaseSection(
                    totalInkastKubbs: roundData.inkastData.inkastKubbs,
                    kubbsOutFirstAttempt: roundData.inkastData.kubbsOutFirstAttempt,
                    kubbsOutSecondAttempt: roundData.inkastData.kubbsOutSecondAttempt,
                    penaltyKubbs: roundData.inkastData.penaltyKubbs,
                    neighborKubbs: roundData.inkastData.neighborKubbs
                )
                
                Spacer()
            }
            
            // Bottom: King Kubb (only visible when all others are down)
            if allFieldKubbsCleared && allBaselineKubbsCleared {
                KingKubbSection(
                    isKingHit: roundData.eightMeterData.hits > 5, // King is hit after baseline kubbs
                    skin: skinManager.selectedKingSkin,
                    onKingHit: { onHit(1) }
                )
                
                Spacer()
            }
            
            // Bottom: Batons and Hit/Miss Controls
            FullGameBatonControlsSection(
                totalBatons: getBatonLimit(),
                usedBatons: getUsedBatons(),
                selectedKubbsHit: $selectedKubbsHit,
                skin: skinManager.selectedBatonSkin,
                onHit: onHit,
                onMiss: onMiss,
                canHitFieldKubbs: currentPhase == .attacking && !allFieldKubbsCleared,
                canHitBaselineKubbs: currentPhase == .attacking && allFieldKubbsCleared && !allBaselineKubbsCleared,
                canHitKing: currentPhase == .attacking && allFieldKubbsCleared && allBaselineKubbsCleared,
                canHitInkast: currentPhase == .inkast
            )
        }
        .padding()
    }
    
    private var allFieldKubbsCleared: Bool {
        roundData.blastData.kubbsClearedFirstThrow >= roundData.inkastData.inkastKubbs
    }
    
    private var allBaselineKubbsCleared: Bool {
        sessionData.currentBaselineKubbs <= 0
    }
    
    private func getBatonLimit() -> Int {
        switch roundData.roundNumber {
        case 1:
            return 2
        case 2:
            return 4
        default:
            return 6
        }
    }
    
    private func getUsedBatons() -> Int {
        switch currentPhase {
        case .inkast:
            return roundData.inkastData.batonsUsed
        case .attacking:
            // For attacking phase, return the total of both blast and 8-meter batons used
            return roundData.blastData.batonsUsed + roundData.eightMeterData.batonsUsed
        case .roundComplete:
            return roundData.totalBatonsUsed
        }
    }
}

// MARK: - 8 Meter Visual View

struct EightMeterVisualView: View {
    let roundData: EightMeterRoundDataStruct
    let onHit: () -> Void
    let onMiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("8-Meter Training")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            // Target kubbs (simplified representation)
            VStack(spacing: 16) {
                Text("Target Kubbs")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 20) {
                    ForEach(0..<2, id: \.self) { index in
                        EightMeterKubbView(
                            isHit: index < roundData.hits,
                            isEnabled: index < roundData.batonsUsed,
                            onTap: index == roundData.batonsUsed ? (roundData.hits > index ? onHit : onMiss) : nil
                        )
                    }
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(16)
            
            // Stats
            HStack(spacing: 30) {
                FullGameStatItem(title: "Hits", value: "\(roundData.hits)", color: .green)
                FullGameStatItem(title: "Misses", value: "\(roundData.misses)", color: .red)
                FullGameStatItem(title: "Accuracy", value: "\(Int(roundData.accuracy * 100))%", color: .blue)
            }
        }
    }
}

// MARK: - Inkast Visual View

struct InkastVisualView: View {
    let roundData: InkastRoundDataStruct
    let onKubbHit: (Int) -> Void
    let onMiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Inkast Phase")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.orange)
            
            // Inkast kubbs to throw
            VStack(spacing: 16) {
                Text("Kubbs to Inkast")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                    ForEach(0..<roundData.inkastKubbs, id: \.self) { index in
                        InkastKubbView(
                            isHit: index < roundData.kubbsOutFirstAttempt,
                            isSecondAttempt: index >= roundData.kubbsOutFirstAttempt && index < (roundData.kubbsOutFirstAttempt + roundData.kubbsOutSecondAttempt),
                            isPenalty: index >= (roundData.kubbsOutFirstAttempt + roundData.kubbsOutSecondAttempt) && index < (roundData.kubbsOutFirstAttempt + roundData.kubbsOutSecondAttempt + roundData.penaltyKubbs),
                            isNeighbor: index >= (roundData.kubbsOutFirstAttempt + roundData.kubbsOutSecondAttempt + roundData.penaltyKubbs) && index < (roundData.kubbsOutFirstAttempt + roundData.kubbsOutSecondAttempt + roundData.penaltyKubbs + roundData.neighborKubbs),
                            onTap: { onKubbHit(1) }
                        )
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(16)
            }
            
            // Stats
            VStack(spacing: 12) {
                HStack(spacing: 20) {
                    FullGameStatItem(title: "First Attempt", value: "\(roundData.kubbsOutFirstAttempt)", color: .green)
                    FullGameStatItem(title: "Second Attempt", value: "\(roundData.kubbsOutSecondAttempt)", color: .yellow)
                }
                HStack(spacing: 20) {
                    FullGameStatItem(title: "Penalties", value: "\(roundData.penaltyKubbs)", color: .red)
                    FullGameStatItem(title: "Neighbors", value: "\(roundData.neighborKubbs)", color: .purple)
                }
            }
        }
    }
}

// MARK: - Blast Visual View

struct BlastVisualView: View {
    let roundData: BlastRoundDataStruct
    let onKubbHit: (Int) -> Void
    let onMiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Blast Phase")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.red)
            
            // Field kubbs (5 kubbs to clear)
            VStack(spacing: 16) {
                Text("Field Kubbs")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { index in
                        BlastKubbView(
                            isCleared: index < roundData.kubbsClearedFirstThrow,
                            isEnabled: index == roundData.kubbsClearedFirstThrow,
                            onTap: index == roundData.kubbsClearedFirstThrow ? { onKubbHit(1) } : nil
                        )
                    }
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(16)
            }
            
            // Stats
            HStack(spacing: 20) {
                FullGameStatItem(title: "Cleared", value: "\(roundData.kubbsClearedFirstThrow)/5", color: .green)
                FullGameStatItem(title: "Hits", value: "\(roundData.hits)", color: .blue)
                FullGameStatItem(title: "Misses", value: "\(roundData.misses)", color: .red)
            }
        }
    }
}

// MARK: - Round Complete View

struct RoundCompleteView: View {
    let roundData: FullGameSimRoundStruct
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Round Complete!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.green)
            
            // Summary stats
            VStack(spacing: 16) {
                Text("Round Summary")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 12) {
                    HStack {
                        Text("8-Meter Hits:")
                        Spacer()
                        Text("\(roundData.eightMeterData.hits)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Inkast Kubbs:")
                        Spacer()
                        Text("\(roundData.inkastData.kubbsOutFirstAttempt)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Blast Kubbs Cleared:")
                        Spacer()
                        Text("\(roundData.blastData.kubbsClearedFirstThrow)")
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(16)
            }
        }
    }
}

// MARK: - Individual Kubb Views

struct EightMeterKubbView: View {
    let isHit: Bool
    let isEnabled: Bool
    let onTap: (() -> Void)?
    
    var body: some View {
        Button(action: onTap ?? {}) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHit ? Color.green : Color.blue)
                    .frame(width: 60, height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black.opacity(0.2), lineWidth: 2)
                    )
                    .opacity(isHit ? 0.3 : 1.0)
                    .rotationEffect(.degrees(isHit ? 90 : 0))
                    .animation(.easeInOut(duration: 0.3), value: isHit)
                
                if isHit {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                        .background(Color.white)
                        .clipShape(Circle())
                }
            }
        }
        .disabled(onTap == nil)
        .opacity(isEnabled ? 1.0 : 0.5)
        .scaleEffect(isEnabled ? 1.0 : 0.9)
    }
}

struct InkastKubbView: View {
    let isHit: Bool
    let isSecondAttempt: Bool
    let isPenalty: Bool
    let isNeighbor: Bool
    let onTap: () -> Void
    
    var kubbColor: Color {
        if isPenalty { return .red }
        if isNeighbor { return .purple }
        if isSecondAttempt { return .yellow }
        return .orange
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(kubbColor)
                    .frame(width: 40, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
                    )
                    .opacity(isHit ? 0.3 : 1.0)
                    .rotationEffect(.degrees(isHit ? 90 : 0))
                    .animation(.easeInOut(duration: 0.3), value: isHit)
                
                if isHit {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                        .background(Color.white)
                        .clipShape(Circle())
                }
            }
        }
    }
}

struct BlastKubbView: View {
    let isCleared: Bool
    let isEnabled: Bool
    let onTap: (() -> Void)?
    
    var body: some View {
        Button(action: onTap ?? {}) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isCleared ? Color.green : Color.red)
                    .frame(width: 50, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
                    )
                    .opacity(isCleared ? 0.3 : 1.0)
                    .rotationEffect(.degrees(isCleared ? 90 : 0))
                    .animation(.easeInOut(duration: 0.3), value: isCleared)
                
                if isCleared {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                        .background(Color.white)
                        .clipShape(Circle())
                }
            }
        }
        .disabled(onTap == nil)
        .opacity(isEnabled ? 1.0 : 0.5)
        .scaleEffect(isEnabled ? 1.0 : 0.9)
    }
}

// MARK: - Stat Item

struct FullGameStatItem: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - New Section Components

struct BaselineKubbsSection: View {
    let totalBaselineKubbs: Int
    let knockedDownBaselineKubbs: Int
    let fieldKubbsCleared: Int
    let skin: KubbSkin
    let attackingTeam: Int
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Baseline Kubbs - Team \(attackingTeam)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text("\(totalBaselineKubbs - knockedDownBaselineKubbs) remaining")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Field kubbs must be cleared first")
                .font(.caption)
                .foregroundColor(.secondary)
                .opacity(fieldKubbsCleared < 1 ? 1.0 : 0.0)
            
            HStack(spacing: 12) {
                // Show all 5 baseline kubbs, with the ones knocked down this round marked as knocked down
                ForEach(0..<5, id: \.self) { index in
                    let isKnockedDown = index < knockedDownBaselineKubbs
                    let isTappable = fieldKubbsCleared >= 1 && !isKnockedDown && index == knockedDownBaselineKubbs
                    
                    KubbVisual(
                        skin: skin,
                        isKnockedDown: isKnockedDown,
                        isTappable: isTappable,
                        onTap: nil
                    )
                    .frame(width: 30, height: 30)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(16)
        }
    }
}

struct FieldKubbsSection: View {
    let totalFieldKubbs: Int
    let knockedDownFieldKubbs: Int
    let skin: KubbSkin
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Field Kubbs")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.orange)
            
            Text("\(knockedDownFieldKubbs)/\(totalFieldKubbs) cleared")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                ForEach(0..<totalFieldKubbs, id: \.self) { index in
                    KubbVisual(
                        skin: skin,
                        isKnockedDown: index < knockedDownFieldKubbs,
                        isTappable: index == knockedDownFieldKubbs,
                        onTap: nil
                    )
                    .frame(width: 30, height: 30)
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(16)
        }
    }
}

struct InkastPhaseSection: View {
    let totalInkastKubbs: Int
    let kubbsOutFirstAttempt: Int
    let kubbsOutSecondAttempt: Int
    let penaltyKubbs: Int
    let neighborKubbs: Int
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Inkast Phase")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.orange)
            
            Text("Throw kubbs to establish field kubbs")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Visual representation of inkast results
            VStack(spacing: 12) {
                HStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("First Attempt")
                            .font(.headline)
                            .foregroundColor(.green)
                        Text("\(kubbsOutFirstAttempt)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Second Attempt")
                            .font(.headline)
                            .foregroundColor(.yellow)
                        Text("\(kubbsOutSecondAttempt)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Penalties")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text("\(penaltyKubbs)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Neighbors")
                            .font(.headline)
                            .foregroundColor(.purple)
                        Text("\(neighborKubbs)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                    }
                }
                
                // Total field kubbs
                VStack(spacing: 8) {
                    Text("Total Field Kubbs")
                        .font(.headline)
                        .foregroundColor(.orange)
                    Text("\(totalInkastKubbs)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(16)
        }
    }
}

struct KingKubbSection: View {
    let isKingHit: Bool
    let skin: KubbSkin
    let onKingHit: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("King Kubb")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.purple)
            
            Button(action: onKingHit) {
                KubbVisual(
                    skin: skin,
                    isKnockedDown: isKingHit,
                    isTappable: !isKingHit,
                    onTap: onKingHit
                )
                .frame(width: 60, height: 60)
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(16)
        }
    }
}

struct FullGameBatonControlsSection: View {
    let totalBatons: Int
    let usedBatons: Int
    @Binding var selectedKubbsHit: Int
    let skin: KubbSkin
    let onHit: (Int) -> Void
    let onMiss: () -> Void
    let canHitFieldKubbs: Bool
    let canHitBaselineKubbs: Bool
    let canHitKing: Bool
    let canHitInkast: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Baton Visual
            HStack(spacing: 8) {
                ForEach(0..<totalBatons, id: \.self) { index in
                    BatonVisual(
                        skin: skin,
                        isActive: index == usedBatons,
                        isThrown: index < usedBatons,
                        batonNumber: index + 1
                    )
                }
            }
            
            // Hit/Miss Controls
            HStack(spacing: 20) {
                // Miss Button
                Button(action: onMiss) {
                    VStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                        Text("MISS")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .frame(width: 120, height: 120)
                    .background(Color.red)
                    .cornerRadius(16)
                }
                
                // Hit Button
                Button(action: { onHit(selectedKubbsHit) }) {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                        Text("HIT")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .frame(width: 120, height: 120)
                    .background(hitButtonColor)
                    .cornerRadius(16)
                }
                .disabled(!canHit)
            }
            
            // Kubbs Hit Counter (only show if hitting field kubbs)
            if canHitFieldKubbs {
                VStack(spacing: 8) {
                    Text("Kubbs Hit")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        Button(action: { if selectedKubbsHit > 1 { selectedKubbsHit -= 1 } }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .disabled(selectedKubbsHit <= 1)
                        
                        Text("\(selectedKubbsHit)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(minWidth: 40)
                        
                        Button(action: { selectedKubbsHit += 1 }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Button("Confirm Hit") {
                        onHit(selectedKubbsHit)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canHit)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    private var canHit: Bool {
        canHitFieldKubbs || canHitBaselineKubbs || canHitKing || canHitInkast
    }
    
    private var hitButtonColor: Color {
        if canHitInkast { return .orange }
        if canHitFieldKubbs { return .orange }
        if canHitBaselineKubbs { return .blue }
        if canHitKing { return .purple }
        return .gray
    }
}


// MARK: - Full Game Hit Recording View

struct FullGameHitRecordingView: View {
    let roundData: FullGameSimRoundStruct
    let sessionData: FullGameSimSessionStruct
    let skin: KubbSkin
    let onConfirm: (Int, Int, Bool) -> Void
    let onCancel: () -> Void
    
    @State private var kubbsHit = 1  // Pre-select one kubb
    @State private var kingHit = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private var fieldKubbsRemaining: Int {
        max(0, roundData.inkastData.totalFieldKubbsForAttacking - roundData.blastData.kubbsClearedFirstThrow)
    }
    
    private var baselineKubbsRemaining: Int {
        // currentBaselineKubbs already reflects all hits (from previous rounds AND this round)
        // so we don't need to subtract roundData.baselineKubbsHit again
        return sessionData.currentBaselineKubbs
    }
    
    private var canHitBaseline: Bool {
        // Can hit baseline kubbs only if all field kubbs are already cleared (current state)
        return fieldKubbsRemaining == 0
    }

    private var canHitKing: Bool {
        // Can hit king only if ALL field and baseline kubbs are already cleared (current state)
        // This prevents the king from becoming available while there are still baseline kubbs remaining
        return fieldKubbsRemaining == 0 && baselineKubbsRemaining == 0
    }
    
    
    // Computed properties to determine what type of kubbs are being hit based on targeting priorities
    private var fieldKubbsHitThisThrow: Int {
        return min(kubbsHit, fieldKubbsRemaining)
    }
    
    private var baselineKubbsHitThisThrow: Int {
        let remainingAfterField = kubbsHit - fieldKubbsHitThisThrow
        return min(remainingAfterField, baselineKubbsRemaining)
    }
    
    private var kingHitThisThrow: Bool {
        // Only consider king hit if there are actually 0 kubbs remaining
        if !canHitKing {
            return false
        }
        let remainingAfterFieldAndBaseline = kubbsHit - fieldKubbsHitThisThrow - baselineKubbsHitThisThrow
        return remainingAfterFieldAndBaseline > 0
    }
    
    private var maxKubbsCanHit: Int {
        // If all field and baseline kubbs are cleared, we can hit the king (1 kubb)
        if canHitKing {
            return 1 // Only the king can be hit
        }
        // Otherwise, we can hit field and baseline kubbs
        return fieldKubbsRemaining + baselineKubbsRemaining
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                Text("What was knocked down?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                visualHitRecordingView
            }
            .padding()
            .navigationTitle("Record Hit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                // Start with 0 kubbs - user must explicitly select what they hit
                kubbsHit = 0
                kingHit = false
            }
        }
    }
    
    private var visualHitRecordingView: some View {
        VStack(spacing: 24) {
            // King Hit (only after all other kubbs are cleared) - show only king section
            if canHitKing {
                VStack(spacing: 16) {
                    Text("King Hit")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)

                    // Visual King Kubb - use king-specific visual
                    ZStack {
                        if let kingImageName = skin.getKingImageName() {
                            // Image-based king
                            Image(kingImageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 80)
                                .scaleEffect(skin.kingImageScale)
                        } else {
                            // Color-based king
                            RoundedRectangle(cornerRadius: 8)
                                .fill(skin.kingColor.color)
                                .frame(width: 50, height: 70)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(skin.kingAccentColor?.color ?? Color.white, lineWidth: 2)
                                )
                                .overlay(
                                    Image(systemName: "crown.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    .opacity(kingHitThisThrow ? 0.3 : 1.0)
                    .rotationEffect(.degrees(kingHitThisThrow ? 90 : 0))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: kingHitThisThrow)
                }
                .padding()
                .background(kingHitThisThrow ? Color.green.opacity(0.1) : Color.purple.opacity(0.1))
                .cornerRadius(16)
            } else {
                // Show both Field Kubbs and Baseline Kubbs sections simultaneously
                
                // Baseline Kubbs Visual (further away - at top)
                // Show baseline section if there are any baseline kubbs remaining
                let totalBaselineKubbsToShow = 5 // Always show all 5 baseline kubbs for the team
                // Calculate how many were knocked down BEFORE this throw opened
                // sessionData.currentBaselineKubbs represents how many are currently standing (updated after each hit)
                let baselineKubbsKnockedBeforeThisThrow = 5 - sessionData.currentBaselineKubbs
                if baselineKubbsRemaining > 0 && !canHitKing {
                    FullGameVisualSection(
                        title: "Baseline Kubbs",
                        totalKubbs: totalBaselineKubbsToShow, // Show all 5 baseline kubbs
                        kubbsHit: .constant(baselineKubbsHitThisThrow), // How many will be hit in this throw
                        skin: skin,
                        color: .green,
                        previouslyKnockedDown: baselineKubbsKnockedBeforeThisThrow, // Kubbs knocked before THIS throw
                        maxSelectableKubbs: baselineKubbsRemaining // Limit selection to what's actually remaining
                    )
                }

                // Field Kubbs Visual (closer - in middle)
                if fieldKubbsRemaining > 0 {
                    FullGameVisualSection(
                        title: "Field Kubbs (Hit First)",
                        totalKubbs: roundData.inkastData.totalFieldKubbsForAttacking, // All inkast kubbs
                        kubbsHit: .constant(fieldKubbsHitThisThrow), // How many will be hit in this throw
                        skin: skin,
                        color: .blue,
                        previouslyKnockedDown: roundData.blastData.kubbsClearedFirstThrow, // Previously knocked down field kubbs
                        maxSelectableKubbs: fieldKubbsRemaining // Limit selection to what's actually remaining
                    )
                }
            }

            // Unified Kubbs Hit Input
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("This Throw: \(kubbsHit) kubbs")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    // Show breakdown of what types of kubbs are being hit
                    if fieldKubbsHitThisThrow > 0 || baselineKubbsHitThisThrow > 0 || kingHitThisThrow {
                        VStack(spacing: 2) {
                            if fieldKubbsHitThisThrow > 0 {
                                Text("Field: \(fieldKubbsHitThisThrow)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            if baselineKubbsHitThisThrow > 0 {
                                Text("Baseline: \(baselineKubbsHitThisThrow)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            if kingHitThisThrow {
                                Text("King: 1")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                }
                
                HStack(spacing: 20) {
                    Button(action: { 
                        if kubbsHit > 0 {
                            kubbsHit -= 1
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .frame(width: 60, height: 60)
                    .background(kubbsHit > 0 ? Color.red : Color.gray)
                    .cornerRadius(30)
                    .disabled(kubbsHit <= 0)
                    
                    Button(action: { 
                        if kubbsHit < maxKubbsCanHit {
                            kubbsHit += 1
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .frame(width: 60, height: 60)
                    .background(kubbsHit < maxKubbsCanHit ? Color.green : Color.gray)
                    .cornerRadius(30)
                    .disabled(kubbsHit >= maxKubbsCanHit)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)

            // Confirm Button
            Button("Confirm Hit") {
                confirmHit()
            }
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(16)
        }
    }
    
    private func confirmHit() {
        // Validation
        if kubbsHit <= 0 {
            errorMessage = "Must hit at least one kubb"
            showingError = true
            return
        }

        if kubbsHit > maxKubbsCanHit {
            errorMessage = "Cannot hit more than \(maxKubbsCanHit) kubbs"
            showingError = true
            return
        }

        // Process the hit using the computed properties
        onConfirm(fieldKubbsHitThisThrow, baselineKubbsHitThisThrow, kingHitThisThrow)

        // Reset modal state for next hit
        kubbsHit = 0  // Start fresh - user must select what they hit
        kingHit = false
    }
}

// MARK: - Full Game Visual Section Component

struct FullGameVisualSection: View {
    let title: String
    let totalKubbs: Int
    @Binding var kubbsHit: Int
    let skin: KubbSkin
    let color: Color
    let previouslyKnockedDown: Int // Number of kubbs already knocked down in previous throws
    var maxSelectableKubbs: Int? = nil // Optional: limit how many can be selected (defaults to totalKubbs - previouslyKnockedDown)
    
    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            // Visual kubb field
            VStack(spacing: 12) {
                ForEach(0..<numberOfLines, id: \.self) { lineIndex in
                    HStack(spacing: 12) {
                        ForEach(0..<kubbsForLine(lineIndex).count, id: \.self) { kubbIndex in
                            let actualIndex = (lineIndex * 5) + kubbIndex
                            let wasPreviouslyKnockedDown = actualIndex < previouslyKnockedDown
                            let isBeingHitThisThrow = actualIndex >= previouslyKnockedDown && actualIndex < (previouslyKnockedDown + kubbsHit)
                            let maxSelectable = maxSelectableKubbs ?? (totalKubbs - previouslyKnockedDown)
                            let isTappable = actualIndex == (previouslyKnockedDown + kubbsHit) && kubbsHit < maxSelectable
                            
                            ZStack {
                                KubbVisual(
                                    skin: skin,
                                    isKnockedDown: wasPreviouslyKnockedDown || isBeingHitThisThrow,
                                    isTappable: isTappable,
                                    onTap: { 
                                        if kubbsHit < maxSelectable {
                                            kubbsHit += 1
                                        }
                                    }
                                )
                                .frame(width: 30, height: 30)
                                .opacity(wasPreviouslyKnockedDown ? 0.4 : 1.0) // Dim previously knocked down kubbs
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isBeingHitThisThrow)
                                
                                // Green checkbox indicator for kubbs being hit in current throw
                                if isBeingHitThisThrow {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.green)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .offset(x: 12, y: -12)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isBeingHitThisThrow)
                                }
                            }
                        }
                        
                        // Fill remaining space if needed
                        if kubbsForLine(lineIndex).count < 5 {
                            ForEach(0..<(5 - kubbsForLine(lineIndex).count), id: \.self) { _ in
                                Spacer()
                                    .frame(width: 30, height: 30)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(16)
            
        }
    }
    
    private var numberOfLines: Int {
        (totalKubbs + 4) / 5 // Round up division
    }
    
    private func kubbsForLine(_ lineIndex: Int) -> [Int] {
        let startIndex = lineIndex * 5
        let endIndex = min(startIndex + 5, totalKubbs)
        return Array(startIndex..<endIndex)
    }
}

// MARK: - Full Game Pitch Visual View

struct FullGamePitchVisualView: View {
    let roundData: FullGameSimRoundStruct
    let sessionData: FullGameSimSessionStruct
    let skin: KubbSkin
    
    var body: some View {
        VStack(spacing: 24) {
            // Baseline Kubbs (further away - at top)
            VStack(spacing: 12) {
                Text("Baseline Kubbs - Team \(sessionData.currentAttackingTeam)")
                    .font(.headline)
                    .foregroundColor(.green)
                
                Text("\(sessionData.currentBaselineKubbs) remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    // Show all 5 baseline kubbs, with knocked down ones marked as knocked down
                    ForEach(0..<5, id: \.self) { index in
                        let remainingKubbs = sessionData.currentBaselineKubbs
                        let isKnockedDown = index >= remainingKubbs
                        
                        KubbVisual(
                            skin: skin,
                            isKnockedDown: isKnockedDown,
                            isTappable: false,
                            onTap: nil
                        )
                        .frame(width: 40, height: 40)
                    }
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(16)
            
            // Field Kubbs (closer - in middle)
            VStack(spacing: 12) {
                Text("Field Kubbs")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                if roundData.inkastData.totalFieldKubbsForAttacking > 0 {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(0..<roundData.inkastData.totalFieldKubbsForAttacking, id: \.self) { index in
                            KubbVisual(
                                skin: skin,
                                isKnockedDown: index < roundData.blastData.kubbsClearedFirstThrow,
                                isTappable: false,
                                onTap: nil
                            )
                            .frame(width: 30, height: 30)
                        }
                    }
                } else {
                    Text("No field kubbs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(16)
        }
    }
}

// MARK: - Attacking Visual View

struct AttackingVisualView: View {
    let roundData: FullGameSimRoundStruct
    let onKubbHit: (Int) -> Void
    let onMiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Show current game state
            VStack(spacing: 16) {
                Text("Current State")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Baseline Kubbs:")
                        Spacer()
                        Text("\(5 - roundData.eightMeterData.hits) remaining")
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Text("Field Kubbs:")
                        Spacer()
                        Text("\(roundData.inkastData.totalFieldKubbsForAttacking - roundData.blastData.kubbsClearedFirstThrow) remaining")
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Action buttons
            HStack(spacing: 20) {
                Button("Miss") {
                    onMiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .foregroundColor(.white)
                .background(Color.red)
                
                Button("Hit") {
                    // For now, just hit 1 kubb - the detailed recording will be handled by the hit recording view
                    onKubbHit(1)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .foregroundColor(.white)
                .background(Color.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    FullGameSimVisualView(
        phase: .attacking,
        roundData: FullGameSimRoundStruct(roundNumber: 1),
        onKubbHit: { _ in },
        onKubbMiss: { }
    )
}
