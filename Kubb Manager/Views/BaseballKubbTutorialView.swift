//
//  BaseballKubbTutorialView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import SwiftUI

struct BaseballKubbTutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var showingFullRules = false
    
    private let tutorialSteps = [
        TutorialStep(
            title: "Welcome to Baseball Kubb",
            content: "Baseball Kubb was created by Andy Terveer as an innovative variation of traditional Kubb. This game combines elements of baseball with the throwing skills required in Kubb, creating an engaging format that is a lot of fun to play!",
            imageName: "baseball_kubb",
            isCustomImage: true
        ),
        TutorialStep(
            title: "Game Concept & Credit",
            content: "**Created by Andy Terveer**\n\nBaseball Kubb combines elements of baseball with Kubb throwing skills. It's designed to improve accuracy and consistency through game-like pressure situations.",
            imageName: "person.circle",
            hasYouTubeLink: true
        ),
        TutorialStep(
            title: "Equipment Setup",
            content: "You'll need:\n• 10 kubbs total (5 for each team's baseline)\n• 1 king kubb (placed at centerline)\n• 6 batons\n• Standard Kubb pitch dimensions (8 meters by 5 meters)",
            imageName: "kubbEquipment",
            isCustomImage: true
        ),
        TutorialStep(
            title: "Game Structure",
            content: "**9 Innings Total**\n\nEach inning has 2 half-innings:\n• **Top half**: Away team throws\n• **Bottom half**: Home team throws\n\nTeams alternate throwing each half-inning. The away team always throwing first.\n\nA traditional king toss is used to determine Home and Away teams.",
            imageName: "9.circle"
        ),
        TutorialStep(
            title: "Scoring System",
            content: "**Runs (Primary Scoring)**\n• 1 Run = 1 baseline kubb or king knocked down\n• Runs scored immediately when hit\n\n**Kings (Tiebreaker)**\n• 1 King Point = 1 king kubb knocked down\n• King hits = 1 run + 1 king point\n• Used as tiebreakers if teams are tied",
            imageName: "crown"
        ),
        TutorialStep(
            title: "Hit Priority System",
            content: "**Must follow this order:**\n\n1. **Field Kubbs First**\n   Must clear all field kubbs before hitting baseline kubbs\n\n2. **Baseline Kubbs Second**\n   Can only hit baseline kubbs when no field kubbs remain\n\n3. **King Last**\n   Can only hit king when ALL other kubbs are cleared",
            imageName: "list.number"
        ),
        TutorialStep(
            title: "Half-Inning Rules",
            content: "**Innings 1-8:**\n• 6 batons per half-inning\n• OR end after 3 misses\n\n**9th Inning:**\n• Unlimited batons until 3 misses\n• Walk-off win possible for home team\n\n**Valid Throws:**\n• Underarm throws only\n• Vertical rotation required",
            imageName: "hand.raised"
        ),
        TutorialStep(
            title: "Field Kubb System",
            content: "**Each half-inning (except top of 1st) starts by inkasting kubbs:**\n\n• Kubbs knocked down in the previous half-inning are inkast by the \"at-bat\" team\n• Field kubbs are stood up by the defending team\n• If an inkast kubb cannot be stood up in bounds, it becomes a penalty kubb (traditional kubb rule)\n\nField kubbs must be cleared before baseline kubbs!",
            imageName: "arrow.triangle.2.circlepath"
        ),
        TutorialStep(
            title: "King Hit Effects",
            content: "**When King is hit:**\n\n• **Immediate reset**: All kubbs return to baselines (5 on each side and the king kubb is stood back up)\n• **Score tracking**: Only kubbs hit AFTER king reset count toward the next half inning's field kubbs\n\nThis creates exciting momentum swings!",
            imageName: "arrow.clockwise"
        ),
        TutorialStep(
            title: "Winning Conditions",
            content: "**Regular Win:**\n• Most runs after 9 innings\n• If tied in runs, most kings wins\n• If still tied, continue playing (three strike rule applies in extra innings)\n\n**Walk-off Win:**\n• Home team wins immediately if leading after bottom 9th\n• Can occur mid-inning if home team takes lead",
            imageName: "trophy"
        ),
        TutorialStep(
            title: "No Advantage Line Rule",
            content: "**Important Rule:**\n\nThere is no advantage line in Baseball Kubb!\n\nIf a team fails to knock down all field kubbs on their turn, those kubbs are then added to the baseline that team is attacking. The defending team does not need to inkast those kubbs.",
            imageName: "exclamationmark.triangle"
        ),
        TutorialStep(
            title: "Training Benefits",
            content: "**Skill Development:**\n• Accuracy improvement through consistent throwing\n• Strategic thinking under pressure\n• Distance control for different targets\n\n**Game Preparation:**\n• Real game simulation with pressure\n• Score management practice\n• Mental toughness development",
            imageName: "chart.line.uptrend.xyaxis"
        ),
        TutorialStep(
            title: "You're Ready!",
            content: "You now understand:\n• Game structure and scoring\n• Hit priority system\n• Field kubb mechanics and inkasting\n• No advantage line rule\n• Winning conditions\n\nStart your first Baseball Kubb game and experience this fun format created by Andy Terveer!",
            imageName: "checkmark.circle"
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: Double(currentStep + 1), total: Double(tutorialSteps.count))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .padding()
                
                // Content
                TabView(selection: $currentStep) {
                    ForEach(0..<tutorialSteps.count, id: \.self) { index in
                        BaseballKubbTutorialStepView(step: tutorialSteps[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Previous") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentStep -= 1
                            }
                        }
                        .buttonStyle(TutorialButtonStyle(isSecondary: true))
                    }
                    
                    Spacer()
                    
                    if currentStep < tutorialSteps.count - 1 {
                        Button("Next") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentStep += 1
                            }
                        }
                        .buttonStyle(TutorialButtonStyle(isSecondary: false))
                    } else {
                        Button("Start Playing") {
                            dismiss()
                        }
                        .buttonStyle(TutorialButtonStyle(isSecondary: false))
                    }
                }
                .padding()
            }
            .navigationTitle("Baseball Kubb Tutorial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Skip") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button("Full Rules") {
                            showingFullRules = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        
                        Text("\(currentStep + 1) of \(tutorialSteps.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingFullRules) {
            BaseballKubbFullRulesView()
        }
    }
}


struct BaseballKubbTutorialStepView: View {
    let step: TutorialStep
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Icon
                if step.isCustomImage {
                    Image(step.imageName)
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: step.imageName)
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                }
                
                // Title
                Text(step.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Content
                Text(step.content)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                
                // YouTube Link
                if step.hasYouTubeLink {
                    Link("Watch Andy's YouTube Playlist", destination: URL(string: "https://www.youtube.com/playlist?list=PLeqH7gfCa66ptEKuilFX_wlmpeFYbcvJO")!)
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
                
                Spacer(minLength: 50)
            }
            .padding(.horizontal, 32)
            .padding(.top, 20)
        }
    }
}

struct BaseballKubbFullRulesView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image("baseball_kubb")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue)
                        
                        Text("Baseball Kubb Rules")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Created by Andy Terveer")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom)
                    
                    // Rules sections
                    RulesSection(
                        title: "Game Concept",
                        content: "Baseball Kubb combines elements of baseball with the throwing skills required in Kubb, creating an engaging format that is a lot of fun to play!"
                    )
                    
                    // YouTube Link
                    Link("Watch Andy's YouTube Playlist", destination: URL(string: "https://www.youtube.com/playlist?list=PLeqH7gfCa66ptEKuilFX_wlmpeFYbcvJO")!)
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    
                    RulesSection(
                        title: "Equipment Setup",
                        content: "• 10 kubbs total (5 for each team's baseline)\n• 1 king kubb (placed at centerline)\n• 6 batons per half-inning (unlimited in 9th)\n• Field kubbs (variable number)\n• Standard Kubb pitch dimensions\n• 5 baseline kubbs set along each baseline"
                    )
                    
                    RulesSection(
                        title: "Game Structure",
                        content: "• 9 innings total\n• Each inning has 2 half-innings (top/bottom)\n• Away team always throws first\n• A traditional king toss is used to determine Home and Away teams\n• Home team has walk-off advantage"
                    )
                    
                    RulesSection(
                        title: "Scoring System",
                        content: "Runs (Primary):\n• 1 Run = 1 baseline kubb knocked down\n• Runs scored immediately when hit\n\nKings (Tiebreaker):\n• 1 King Point = 1 king kubb knocked down\n• King hits = 1 run + 1 king point\n• Used as tiebreakers if teams are tied"
                    )
                    
                    RulesSection(
                        title: "Hit Priority System",
                        content: "Must follow this order:\n\n1. Field Kubbs First\n   Must clear all field kubbs before hitting baseline kubbs\n\n2. Baseline Kubbs Second\n   Can only hit baseline kubbs when no field kubbs remain\n\n3. King Last\n   Can only hit king when ALL other kubbs are cleared"
                    )
                    
                    RulesSection(
                        title: "Half-Inning Rules",
                        content: "Innings 1-8:\n• 6 batons per half-inning\n• OR end after 3 misses\n\n9th Inning:\n• Unlimited batons until 3 misses\n• Walk-off win possible for home team\n\nValid Throws:\n• Underarm throws only\n• Vertical rotation required"
                    )
                    
                    RulesSection(
                        title: "Field Kubb System",
                        content: "Each half-inning (except top of 1st) starts by inkasting kubbs:\n\n• Kubbs knocked down in the previous half-inning are inkast by the \"at-bat\" team\n• Field kubbs are stood up by the defending team\n• If an inkast kubb cannot be stood up in bounds, it becomes a penalty kubb (traditional kubb rule)\n\nField kubbs must be cleared before baseline kubbs!"
                    )
                    
                    RulesSection(
                        title: "King Hit Effects",
                        content: "When King is hit:\n\n• Immediate reset: All kubbs return to baselines (5 on each side and the king kubb is stood back up)\n• Score tracking: Only kubbs hit AFTER king reset count toward the next half inning's field kubbs\n\nThis creates exciting momentum swings!"
                    )
                    
                    RulesSection(
                        title: "Winning Conditions",
                        content: "Regular Win:\n• Most runs after 9 innings\n• If tied in runs, most kings wins\n• If still tied, continue playing (three strike rule applies in extra innings)\n\nWalk-off Win:\n• Home team wins immediately if leading after bottom 9th\n• Can occur mid-inning if home team takes lead"
                    )
                    
                    RulesSection(
                        title: "No Advantage Line Rule",
                        content: "There is no advantage line in Baseball Kubb!\n\nIf a team fails to knock down all field kubbs on their turn, those kubbs are then added to the baseline that team is attacking. The defending team does not need to inkast those kubbs."
                    )
                    
                    RulesSection(
                        title: "Training Benefits",
                        content: "Skill Development:\n• Accuracy improvement through consistent throwing\n• Strategic thinking under pressure\n• Distance control for different targets\n\nGame Preparation:\n• Real game simulation with pressure\n• Score management practice\n• Mental toughness development"
                    )
                }
                .padding()
            }
            .navigationTitle("Full Rules")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct RulesSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    BaseballKubbTutorialView()
}
