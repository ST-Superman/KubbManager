//
//  EightMeterTutorialView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import SwiftUI

struct EightMeterTutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    
    private let tutorialSteps = [
        TutorialStep(
            title: "Welcome to 8-Meter Training",
            content: "This tutorial will walk you through setting up your practice pitch and running your first training session.",
            imageName: "target"
        ),
        TutorialStep(
            title: "Equipment Needed",
            content: "You'll need:\n• 10 kubbs (5 for each baseline)\n• 1 king kubb (for centerline)\n• 6 batons\n• Measuring device (4m and 8m)\n• Recommended: Quick pitch system or Pitch Pal",
            imageName: "kubbEquipment",
            isCustomImage: true
        ),
        TutorialStep(
            title: "Pitch Setup",
            content: "Choose your setup option:\n\n**Option 1: Full Pitch**\nSet up a standard kubb pitch with proper boundaries\n\n**Option 2: Three Markers**\n• Place 2 markers 8 meters apart (baselines)\n• Place 1 marker at the midpoint (centerline)\n• Ensure at least 12 meters total length for safety",
            imageName: "rectangle.split.2x1"
        ),
        TutorialStep(
            title: "Safety First",
            content: "Important safety considerations:\n• Ensure plenty of space around the practice area\n• Make sure no one can be hit by stray batons\n• Clear the area of any obstacles\n• Have a clear path between baselines",
            imageName: "exclamationmark.triangle"
        ),
        TutorialStep(
            title: "Throwing Rules",
            content: "Proper throwing technique:\n• Batons must be thrown with vertical rotation\n• Throw underarm only\n• NO sideways or horizontal tosses\n• NO 'helicopter' spins\n• These are illegal throws and won't count",
            imageName: "hand.raised"
        ),
        TutorialStep(
            title: "Round 1: Start Your Practice",
            content: "Here's how each round works:\n\n1. Start from behind one baseline\n2. Throw all 6 batons at the kubbs on the opposite baseline\n3. Track which batons hit and which missed\n4. Enter these results in the app\n\n**Special Rule:** If your first 5 batons all hit kubbs, use your 6th baton to try to knock over the king!",
            imageName: "1.circle"
        ),
        TutorialStep(
            title: "Round 2: Reset and Continue",
            content: "After recording your throws:\n\n1. Walk to the opposite baseline\n2. Reset all knocked-down kubbs to standing position\n3. Gather your batons\n4. You will now be throwing from behind this baseline, towards your original baseline\n5. Prepare for the next round",
            imageName: "2.circle"
        ),
        TutorialStep(
            title: "Continue Until Target Reached",
            content: "Keep repeating the process:\n• Throw 6 batons\n• Record hits/misses in the app\n• Reset kubbs and gather batons\n• Begin next round by throwing at opposite baseline\n\nContinue until you reach your daily target number of kubbs!",
            imageName: "repeat"
        ),
        TutorialStep(
            title: "You're Ready!",
            content: "That's it! You now know how to:\n• Set up your 8-meter training pitch\n• Throw batons properly\n• Track your progress\n• Complete training rounds\n\nStart your first session and begin improving your 8-meter accuracy!",
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
                        TutorialStepView(step: tutorialSteps[index])
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
                        Button("Get Started") {
                            dismiss()
                        }
                        .buttonStyle(TutorialButtonStyle(isSecondary: false))
                    }
                }
                .padding()
            }
            .navigationTitle("8-Meter Training Tutorial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Skip") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("\(currentStep + 1) of \(tutorialSteps.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct TutorialStep {
    let title: String
    let content: String
    let imageName: String
    let isCustomImage: Bool
    
    init(title: String, content: String, imageName: String, isCustomImage: Bool = false) {
        self.title = title
        self.content = content
        self.imageName = imageName
        self.isCustomImage = isCustomImage
    }
}

struct TutorialStepView: View {
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
                
                Spacer(minLength: 50)
            }
            .padding(.horizontal, 32)
            .padding(.top, 20)
        }
    }
}

struct TutorialButtonStyle: ButtonStyle {
    let isSecondary: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(isSecondary ? .blue : .white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(isSecondary ? Color.clear : Color.blue)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: isSecondary ? 2 : 0)
            )
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    EightMeterTutorialView()
}
