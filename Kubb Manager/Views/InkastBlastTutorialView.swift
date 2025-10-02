//
//  InkastBlastTutorialView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 1/15/25.
//

import SwiftUI

struct InkastBlastTutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    
    private let tutorialPages = [
        TutorialPage(
            title: "Inkast & Blast Training",
            content: "Practice the essential skills of inkasting kubbs and efficiently clearing them from the field.",
            image: "inkastblast"
        ),
        TutorialPage(
            title: "Game Phases",
            content: "Choose your training phase:\n\n• Early Game (1-3 kubbs)\n• Mid Game (4-7 kubbs)\n• End Game (8-10 kubbs)\n• All Phases (1-10 kubbs)",
            image: "target"
        ),
        TutorialPage(
            title: "Inkast Phase",
            content: "Throw the specified number of kubbs past the midline. If any go out of bounds, you get one more attempt to get them in bounds.",
            image: "kubbEquipment"
        ),
        TutorialPage(
            title: "Neighbor Kubbs",
            content: "Check if any kubbs landed on top of each other. These are called 'neighbor kubbs' and are tracked as a statistic.",
            image: "swedish_kubb"
        ),
        TutorialPage(
            title: "Blasting Phase",
            content: "Stand up the kubbs and try to clear them with as few batons as possible. Record each throw as a hit or miss.",
            image: "king"
        ),
        TutorialPage(
            title: "Target Scoring",
            content: "Target batons for clearing:\n\n• 1 kubb = 1 baton\n• 2 kubbs = 1 baton\n• 3-4 kubbs = 2 batons\n• 5-7 kubbs = 3 batons\n• 8-10 kubbs = 4 batons",
            image: "kubb_crosshair"
        ),
        TutorialPage(
            title: "Statistics Tracked",
            content: "The app tracks:\n\n• Kubbs cleared with first throw\n• Total batons used\n• Penalty kubbs (out after 2 attempts)\n• Neighbor kubbs\n• Misses\n• Performance vs target",
            image: "baseball_kubb"
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Page Content
                TabView(selection: $currentPage) {
                    ForEach(0..<tutorialPages.count, id: \.self) { index in
                        tutorialPageView(tutorialPages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Page Indicator and Navigation
                VStack(spacing: 20) {
                    // Page Indicator
                    HStack(spacing: 8) {
                        ForEach(0..<tutorialPages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    // Navigation Buttons
                    HStack {
                        if currentPage > 0 {
                            Button("Previous") {
                                withAnimation {
                                    currentPage -= 1
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Spacer()
                        
                        if currentPage < tutorialPages.count - 1 {
                            Button("Next") {
                                withAnimation {
                                    currentPage += 1
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button("Get Started") {
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .navigationTitle("Tutorial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Back to Main Menu") {
                        navigationCoordinator.returnToMainApp(tab: 0)
                    }
                }
            }
        }
    }
    
    private func tutorialPageView(_ page: TutorialPage) -> some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Image
            Image(page.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(page.content)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

struct TutorialPage {
    let title: String
    let content: String
    let image: String
}

#Preview {
    InkastBlastTutorialView()
}
