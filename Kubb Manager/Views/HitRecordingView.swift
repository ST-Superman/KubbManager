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
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Penalty Kubbs")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                    
                    KubbField(
                        kubbs: penaltyKubbs.enumerated().map { index, kubb in
                            KubbState(
                                isKnockedDown: knockedDownPenaltyKubbs.contains(index),
                                isTappable: kubb.isTappable
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
    let onFirstAttemptResults: (Int) -> Void
    let onSecondAttemptResults: (Int) -> Void
    let onNeighborResults: (Int) -> Void
    
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
            // Title
            Text("Inkast Results")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Visual representation of all kubbs
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.blue)
                    Text("Inkasted Kubbs")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                KubbField(
                    kubbs: Array(0..<totalKubbs).map { _ in
                        KubbState(isKnockedDown: false, isTappable: false)
                    },
                    skin: skin,
                    onKubbTap: { _ in }
                )
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
            
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
    
    private var firstAttemptView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("How many kubbs went out of bounds?")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("Tap the stepper to adjust the count")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 16) {
                Stepper("Out of bounds: \(kubbsOutFirstAttempt)", 
                       value: $kubbsOutFirstAttempt, 
                       in: 0...totalKubbs)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Button("Continue") {
                    onFirstAttemptResults(kubbsOutFirstAttempt)
                    if kubbsOutFirstAttempt > 0 {
                        currentPhase = .secondAttempt
                    } else {
                        currentPhase = .neighborCheck
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }
    
    private var secondAttemptView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Re-throw Results")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("How many kubbs are still out of bounds?")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                Stepper("Still out: \(kubbsOutSecondAttempt)", 
                       value: $kubbsOutSecondAttempt, 
                       in: 0...kubbsOutFirstAttempt)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Button("Continue") {
                    onSecondAttemptResults(kubbsOutSecondAttempt)
                    currentPhase = .neighborCheck
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }
    
    private var neighborCheckView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Neighbor Check")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("Any kubbs landed on top of each other?")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                Stepper("Neighbor kubbs: \(neighborKubbs)", 
                       value: $neighborKubbs, 
                       in: 0...totalKubbs)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Button("Start Blasting") {
                    onNeighborResults(neighborKubbs)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HitRecordingView(
            kubbs: Array(0..<5).map { _ in
                KubbState(isKnockedDown: false, isTappable: true)
            },
            penaltyKubbs: Array(0..<2).map { _ in
                KubbState(isKnockedDown: false, isTappable: true)
            },
            skin: KubbSkin.defaultSkins[0],
            onKubbTap: { _ in },
            onPenaltyKubbTap: { _ in },
            onConfirm: { _, _ in },
            onCancel: { }
        )
        
        InkastRecordingView(
            totalKubbs: 5,
            skin: KubbSkin.defaultSkins[1],
            onFirstAttemptResults: { _ in },
            onSecondAttemptResults: { _ in },
            onNeighborResults: { _ in }
        )
    }
    .padding()
}
