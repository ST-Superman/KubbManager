//
//  HitRecordingView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 1/15/25.
//

import SwiftUI

struct HitRecordingView: View {
    let kubbs: [KubbState]
    let penaltyKubbs: [KubbState]
    let skin: KubbSkin
    let onKubbTap: (Int) -> Void
    let onPenaltyKubbTap: (Int) -> Void
    let onConfirm: (Int, Int) -> Void // (kubbsHit, penaltyKubbsHit)
    let onCancel: () -> Void
    
    @State private var knockedDownKubbs: Set<Int> = []
    @State private var knockedDownPenaltyKubbs: Set<Int> = []
    
    var body: some View {
        VStack(spacing: 24) {
            // Title
            Text("Record Hit Results")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Penalty kubbs (top of screen)
            if !penaltyKubbs.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                        Text("Penalty Kubbs")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    KubbField(
                        kubbs: penaltyKubbs.enumerated().map { index, kubb in
                            let isPreviouslyKnockedDown = !kubb.isTappable && kubb.isKnockedDown
                            let isCurrentlyKnockedDown = knockedDownPenaltyKubbs.contains(index)
                            let isTappable = kubb.isTappable
                            
                            return KubbState(
                                isKnockedDown: isPreviouslyKnockedDown || isCurrentlyKnockedDown,
                                isTappable: isTappable
                            )
                        },
                        skin: skin,
                        onKubbTap: { index in
                            if penaltyKubbs[index].isTappable {
                                if knockedDownPenaltyKubbs.contains(index) {
                                    knockedDownPenaltyKubbs.remove(index)
                                } else {
                                    knockedDownPenaltyKubbs.insert(index)
                                }
                            }
                        }
                    )
                }
                .padding()
                .background(Color.red.opacity(0.05))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
            }
            
            // Regular kubbs (center of screen)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.blue)
                    Text("Field Kubbs")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                KubbField(
                    kubbs: kubbs.enumerated().map { index, kubb in
                        let isPreviouslyKnockedDown = !kubb.isTappable && kubb.isKnockedDown
                        let isCurrentlyKnockedDown = knockedDownKubbs.contains(index)
                        let isTappable = kubb.isTappable
                        
                        return KubbState(
                            isKnockedDown: isPreviouslyKnockedDown || isCurrentlyKnockedDown,
                            isTappable: isTappable
                        )
                    },
                    skin: skin,
                    onKubbTap: { index in
                        if kubbs[index].isTappable {
                            if knockedDownKubbs.contains(index) {
                                knockedDownKubbs.remove(index)
                            } else {
                                knockedDownKubbs.insert(index)
                            }
                        }
                    }
                )
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
            
            // Instructions
            Text("Tap kubbs to knock them down, tap again to stand them up")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Action buttons
            HStack(spacing: 16) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Button("Confirm") {
                    onConfirm(knockedDownKubbs.count, knockedDownPenaltyKubbs.count)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(knockedDownKubbs.isEmpty && knockedDownPenaltyKubbs.isEmpty)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

struct InkastRecordingView: View {
    let totalKubbs: Int
    let skin: KubbSkin
    let onComplete: (Int, Int, Int) -> Void // (firstAttemptOut, secondAttemptOut, neighborKubbs)
    
    @State private var kubbsOutFirstAttempt: Int = 0
    @State private var kubbsOutSecondAttempt: Int = 0
    @State private var neighborKubbs: Int = 0
    @State private var currentPhase: InkastPhase = .firstAttempt
    
    enum InkastPhase {
        case firstAttempt
        case secondAttempt
        case neighborCheck
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Phase-specific content
            switch currentPhase {
            case .firstAttempt:
                firstAttemptView
            case .secondAttempt:
                secondAttemptView
            case .neighborCheck:
                neighborCheckView
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
    
    private func getOutOfBoundsCount() -> Int {
        switch currentPhase {
        case .firstAttempt:
            return kubbsOutFirstAttempt
        case .secondAttempt:
            return kubbsOutSecondAttempt
        case .neighborCheck:
            return 0 // No out-of-bounds kubbs shown during neighbor check
        }
    }
    
    private func getTotalKubbsToShow() -> Int {
        switch currentPhase {
        case .firstAttempt:
            return totalKubbs // Show all original kubbs
        case .secondAttempt:
            return totalKubbs // Show all kubbs since re-thrown kubbs can affect the entire field
        case .neighborCheck:
            return totalKubbs // Show all kubbs for neighbor check
        }
    }
    
    private func numberOfLinesForKubbs(_ kubbCount: Int) -> Int {
        (kubbCount + 4) / 5 // Round up division
    }
    
    private func kubbsForLineCount(_ totalKubbs: Int, _ lineIndex: Int) -> Int {
        let startIndex = lineIndex * 5
        let endIndex = min(startIndex + 5, totalKubbs)
        return endIndex - startIndex
    }
    
    private func getPenaltyKubbs() -> Set<Int> {
        // Penalty kubbs are those that were out of bounds after the second attempt
        // This would be calculated based on kubbsOutSecondAttempt
        // For now, return empty set - this will be populated when we have the data
        return Set<Int>()
    }
    
    private var firstAttemptView: some View {
        VStack(spacing: 24) {
            firstAttemptHeader
            firstAttemptPitchView
            firstAttemptCounter
            firstAttemptButton
        }
    }
    
    private var firstAttemptHeader: some View {
        VStack(spacing: 8) {
            Text("First Attempt Results")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            
            Text("How many kubbs went out of bounds?")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
    }
    
    private var firstAttemptPitchView: some View {
        VStack(spacing: 16) {
            Text("Pitch View")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                firstAttemptMainPitch
                firstAttemptOutOfBoundsArea
            }
        }
    }
    
    private var firstAttemptMainPitch: some View {
        VStack(spacing: 12) {
            ForEach(0..<numberOfLinesForKubbs(getTotalKubbsToShow()), id: \.self) { lineIndex in
                HStack(spacing: 12) {
                    ForEach(0..<kubbsForLineCount(getTotalKubbsToShow(), lineIndex), id: \.self) { kubbIndex in
                        let actualIndex = (lineIndex * 5) + kubbIndex
                        let isOutOfBounds = getOutOfBoundsCount() > 0 && actualIndex < getOutOfBoundsCount()
                        let isPenalty = getPenaltyKubbs().contains(actualIndex)
                        
                        if !isOutOfBounds {
                            KubbVisualLarge(
                                skin: skin,
                                isKnockedDown: false,
                                isOutOfBounds: false,
                                isPenalty: isPenalty,
                                isNeighbor: false,
                                isNewlyKnockedDown: false,
                                size: 50
                            )
                            .foregroundColor(.primary)
                        } else {
                            Spacer()
                                .frame(width: 50, height: 50)
                        }
                    }
                    
                    let currentLineCount = kubbsForLineCount(getTotalKubbsToShow(), lineIndex)
                    if currentLineCount < 5 {
                        ForEach(0..<(5 - currentLineCount), id: \.self) { _ in
                            Spacer()
                                .frame(width: 50, height: 50)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var firstAttemptOutOfBoundsArea: some View {
        Group {
            if getOutOfBoundsCount() > 0 {
                outOfBoundsContainer
            }
        }
    }
    
    private var outOfBoundsContainer: some View {
        VStack(spacing: 8) {
            Text("Out of Bounds")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.red)
            
            outOfBoundsKubbsGrid
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.3), lineWidth: 2)
        )
    }
    
    private var outOfBoundsKubbsGrid: some View {
        VStack(spacing: 12) {
            ForEach(0..<numberOfLinesForKubbs(getOutOfBoundsCount()), id: \.self) { lineIndex in
                outOfBoundsKubbsLine(lineIndex: lineIndex)
            }
        }
    }
    
    private func outOfBoundsKubbsLine(lineIndex: Int) -> some View {
        HStack(spacing: 12) {
            ForEach(0..<kubbsForLineCount(getOutOfBoundsCount(), lineIndex), id: \.self) { kubbIndex in
                KubbVisualLarge(
                    skin: skin,
                    isKnockedDown: false,
                    isOutOfBounds: true,
                    isPenalty: false,
                    isNeighbor: false,
                    isNewlyKnockedDown: false,
                    size: 50
                )
                .foregroundColor(.red)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: true)
            }
            
            let currentLineCount = kubbsForLineCount(getOutOfBoundsCount(), lineIndex)
            if currentLineCount < 5 {
                ForEach(0..<(5 - currentLineCount), id: \.self) { _ in
                    Spacer()
                        .frame(width: 50, height: 50)
                }
            }
        }
    }
    
    private var firstAttemptCounter: some View {
        VStack(spacing: 16) {
            Text("Out of Bounds")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("\(kubbsOutFirstAttempt)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                Button(action: { 
                    if kubbsOutFirstAttempt > 0 {
                        kubbsOutFirstAttempt -= 1
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                .frame(width: 60, height: 60)
                .background(kubbsOutFirstAttempt > 0 ? Color.red : Color.gray)
                .cornerRadius(30)
                .disabled(kubbsOutFirstAttempt <= 0)
                
                Button(action: { 
                    if kubbsOutFirstAttempt < totalKubbs {
                        kubbsOutFirstAttempt += 1
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                .frame(width: 60, height: 60)
                .background(kubbsOutFirstAttempt < totalKubbs ? Color.green : Color.gray)
                .cornerRadius(30)
                .disabled(kubbsOutFirstAttempt >= totalKubbs)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var firstAttemptButton: some View {
        Button(kubbsOutFirstAttempt > 0 ? "Continue to Second Attempt" : "Continue to Neighbor Check") {
            if kubbsOutFirstAttempt > 0 {
                currentPhase = .secondAttempt
            } else {
                currentPhase = .neighborCheck
            }
        }
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.blue)
        .cornerRadius(16)
    }
    
    private var secondAttemptView: some View {
        VStack(spacing: 24) {
            secondAttemptHeader
            firstAttemptPitchView // Reuse the same pitch view
            secondAttemptCounter
            secondAttemptButton
        }
    }
    
    private var secondAttemptHeader: some View {
        VStack(spacing: 8) {
            Text("Second Attempt Results")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            
            Text("You re-threw \(kubbsOutFirstAttempt) kubbs. How many are still out of bounds?")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var secondAttemptCounter: some View {
        VStack(spacing: 16) {
            Text("Still Out of Bounds")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("\(kubbsOutSecondAttempt)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                Button(action: { 
                    if kubbsOutSecondAttempt > 0 {
                        kubbsOutSecondAttempt -= 1
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                .frame(width: 60, height: 60)
                .background(kubbsOutSecondAttempt > 0 ? Color.red : Color.gray)
                .cornerRadius(30)
                .disabled(kubbsOutSecondAttempt <= 0)
                
                Button(action: { 
                    if kubbsOutSecondAttempt < kubbsOutFirstAttempt {
                        kubbsOutSecondAttempt += 1
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                .frame(width: 60, height: 60)
                .background(kubbsOutSecondAttempt < kubbsOutFirstAttempt ? Color.green : Color.gray)
                .cornerRadius(30)
                .disabled(kubbsOutSecondAttempt >= kubbsOutFirstAttempt)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var secondAttemptButton: some View {
        Button("Continue to Neighbor Check") {
            currentPhase = .neighborCheck
        }
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.blue)
        .cornerRadius(16)
    }
    
    private var neighborCheckView: some View {
        VStack(spacing: 24) {
            neighborCheckHeader
            firstAttemptPitchView // Reuse the same pitch view
            neighborCheckCounter
            neighborCheckButton
        }
    }
    
    private var neighborCheckHeader: some View {
        VStack(spacing: 8) {
            Text("Neighbor Check")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            
            Text("Any kubbs landed on top of each other?")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var neighborCheckCounter: some View {
        VStack(spacing: 16) {
            Text("Neighbor Kubbs")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("\(neighborKubbs)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                Button(action: { 
                    if neighborKubbs > 0 {
                        neighborKubbs -= 1
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                .frame(width: 60, height: 60)
                .background(neighborKubbs > 0 ? Color.red : Color.gray)
                .cornerRadius(30)
                .disabled(neighborKubbs <= 0)
                
                Button(action: { 
                    if neighborKubbs < totalKubbs {
                        neighborKubbs += 1
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                .frame(width: 60, height: 60)
                .background(neighborKubbs < totalKubbs ? Color.green : Color.gray)
                .cornerRadius(30)
                .disabled(neighborKubbs >= totalKubbs)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var neighborCheckButton: some View {
        Button("Start Blasting") {
            onComplete(kubbsOutFirstAttempt, kubbsOutSecondAttempt, neighborKubbs)
        }
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.blue)
        .cornerRadius(16)
    }
}

// MARK: - New Visual Hit Recording Modal

struct VisualHitRecordingView: View {
    let totalKubbs: Int
    let skin: KubbSkin
    let previouslyKnockedDownKubbs: Set<Int> // Kubbs knocked down in previous throws
    let onConfirm: (Int) -> Void // Number of kubbs hit this throw
    let onCancel: () -> Void
    
    @State private var kubbsHit: Int = 1 // Start with 1 since we already indicated a hit
    @State private var animationOffset: CGFloat = 0
    @State private var animationRotation: Double = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                Text("Confirm the number of kubbs knocked down")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top)
                
                // Large visual representation of the pitch
                VStack(spacing: 16) {
                    Text("Pitch View")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    // Visual kubb field with larger kubbs
                    VStack(spacing: 12) {
                        ForEach(0..<numberOfLines, id: \.self) { lineIndex in
                            HStack(spacing: 12) {
                                ForEach(0..<kubbsForLine(lineIndex).count, id: \.self) { kubbIndex in
                                    let actualIndex = (lineIndex * 5) + kubbIndex
                                    let wasPreviouslyKnockedDown = previouslyKnockedDownKubbs.contains(actualIndex)
                                    let isNewlyKnockedDown = !wasPreviouslyKnockedDown && actualIndex < (previouslyKnockedDownKubbs.count + kubbsHit)
                                    let isKnockedDown = wasPreviouslyKnockedDown || isNewlyKnockedDown
                                    
                                    KubbVisualLarge(
                                        skin: skin,
                                        isKnockedDown: isKnockedDown,
                                        isOutOfBounds: false,
                                        isPenalty: false,
                                        isNeighbor: false,
                                        isNewlyKnockedDown: isNewlyKnockedDown,
                                        size: 50
                                    )
                                    .opacity(wasPreviouslyKnockedDown ? 0.6 : 1.0) // Dim previously knocked down kubbs
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isKnockedDown)
                                }
                                
                                // Fill remaining space if needed
                                if kubbsForLine(lineIndex).count < 5 {
                                    ForEach(0..<(5 - kubbsForLine(lineIndex).count), id: \.self) { _ in
                                        Spacer()
                                            .frame(width: 50, height: 50)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }
                
                // Summary
                VStack(spacing: 12) {
                    Text("This Throw: \(kubbsHit) kubbs")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Previously: \(previouslyKnockedDownKubbs.count) kubbs")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Total: \(previouslyKnockedDownKubbs.count + kubbsHit) of \(totalKubbs) kubbs")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Large counter with +/- buttons
                VStack(spacing: 16) {
                    Text("Kubbs Hit This Throw")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("\(kubbsHit)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 20) {
                        Button(action: { 
                            if kubbsHit > 1 {
                                kubbsHit -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        .frame(width: 60, height: 60)
                        .background(kubbsHit > 1 ? Color.red : Color.gray)
                        .cornerRadius(30)
                        .disabled(kubbsHit <= 1)
                        
                        Button(action: { 
                            if kubbsHit < (totalKubbs - previouslyKnockedDownKubbs.count) {
                                kubbsHit += 1
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        .frame(width: 60, height: 60)
                        .background(kubbsHit < (totalKubbs - previouslyKnockedDownKubbs.count) ? Color.green : Color.gray)
                        .cornerRadius(30)
                        .disabled(kubbsHit >= (totalKubbs - previouslyKnockedDownKubbs.count))
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                // Action buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button("Confirm") {
                        onConfirm(kubbsHit)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding()
            .navigationTitle("Record Hit")
            .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Large Kubb Visual Component

struct KubbVisualLarge: View {
    let skin: KubbSkin
    let isKnockedDown: Bool
    let isOutOfBounds: Bool
    let isPenalty: Bool
    let isNeighbor: Bool
    let isNewlyKnockedDown: Bool // New parameter to distinguish newly knocked down kubbs
    let size: CGFloat
    @State private var selectedImageName: String?
    @State private var animationOffset: CGFloat = 0
    @State private var animationRotation: Double = 0
    
    var body: some View {
        ZStack {
            // Kubb visual
            if let kubbImageName = selectedImageName {
                // Image-based kubb
                Image(kubbImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size * 0.6, height: size)
                    .scaleEffect(skin.kubbImageScale)
                    .opacity(isOutOfBounds ? 0.6 : (isKnockedDown ? 0.3 : 1.0))
                    .rotationEffect(.degrees(isKnockedDown && !isOutOfBounds ? animationRotation : 0))
                    .offset(y: isKnockedDown && !isOutOfBounds ? animationOffset : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isKnockedDown)
            } else {
                // Color-based kubb
                RoundedRectangle(cornerRadius: 6)
                    .fill(kubbColor)
                    .frame(width: size * 0.4, height: size)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
                    )
                    .opacity(isOutOfBounds ? 0.6 : (isKnockedDown ? 0.3 : 1.0))
                    .rotationEffect(.degrees(isKnockedDown && !isOutOfBounds ? animationRotation : 0))
                    .offset(y: isKnockedDown && !isOutOfBounds ? animationOffset : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isKnockedDown)
            }
            
            // Status indicator
            if isOutOfBounds {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                    .background(Color.white)
                    .clipShape(Circle())
            } else if isKnockedDown && isNewlyKnockedDown {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            
            // Penalty indicator (small red dot in corner)
            if isPenalty {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .offset(x: size * 0.3, y: -size * 0.3)
            }
            
            // Neighbor indicator (small green dot in opposite corner)
            if isNeighbor {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .offset(x: -size * 0.3, y: -size * 0.3)
            }
        }
        .frame(width: size, height: size)
        .onChange(of: isKnockedDown) { _, newValue in
            if newValue && !isOutOfBounds {
                // Trigger knock-over animation only for hit kubbs, not out-of-bounds
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    animationOffset = 15
                    animationRotation = 90
                }
            } else if !newValue {
                // Reset animation when kubb is reset
                animationOffset = 0
                animationRotation = 0
            }
        }
        .onAppear {
            selectImage()
            // Initialize animation state based on initial isKnockedDown value (only if not out of bounds)
            if isKnockedDown && !isOutOfBounds {
                animationOffset = 15
                animationRotation = 90
            }
        }
    }
    
    private var kubbColor: Color {
        return skin.kubbColor.color
    }
    
    private func selectImage() {
        selectedImageName = skin.kubbImageName
    }
}
