//
//  GameView.swift
//  DF768
//

import SwiftUI

struct GameView: View {
    let trail: TrailType
    let level: Int
    let difficulty: Difficulty
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var gameManager = GameManager.shared
    @State private var showingPauseMenu = false
    @State private var gameCompleted = false
    
    private var accentColor: Color {
        switch trail {
        case .shiftingPathways: return .primaryAccent
        case .pulseOfReflections: return .secondaryAccent
        case .fallingEchoLines: return Color(red: 0.6, green: 0.5, blue: 1.0)
        }
    }
    
    var body: some View {
        ZStack {
            // Game content based on trail type
            gameContent
            
            // Pause button overlay
            VStack {
                HStack {
                    Button(action: {
                        showingPauseMenu = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.primaryBackground.opacity(0.8))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "pause.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.textPrimary)
                        }
                    }
                    .padding(.leading, 20)
                    .padding(.top, 16)
                    
                    Spacer()
                }
                
                Spacer()
            }
            
            // Pause menu
            if showingPauseMenu {
                PauseMenuView(
                    accentColor: accentColor,
                    onResume: {
                        showingPauseMenu = false
                    },
                    onQuit: {
                        dismiss()
                    }
                )
            }
        }
        .navigationBarHidden(true)
    }
    
    @ViewBuilder
    private var gameContent: some View {
        switch trail {
        case .shiftingPathways:
            ShiftingPathwaysGame(level: level, difficulty: difficulty) { success, score, timeSpent in
                handleGameComplete(success: success, score: score, timeSpent: timeSpent)
            }
        case .pulseOfReflections:
            PulseOfReflectionsGame(level: level, difficulty: difficulty) { success, score, timeSpent in
                handleGameComplete(success: success, score: score, timeSpent: timeSpent)
            }
        case .fallingEchoLines:
            FallingEchoLinesGame(level: level, difficulty: difficulty) { success, score, timeSpent in
                handleGameComplete(success: success, score: score, timeSpent: timeSpent)
            }
        }
    }
    
    private func handleGameComplete(success: Bool, score: Int, timeSpent: TimeInterval) {
        if success {
            let fragments = calculateFragments(score: score)
            gameManager.completeLevel(
                trail: trail,
                level: level,
                difficulty: difficulty,
                fragments: fragments,
                timeSpent: timeSpent,
                score: score
            )
        }
        dismiss()
    }
    
    private func calculateFragments(score: Int) -> Int {
        let baseFragments = 5
        let difficultyBonus = difficulty == .hard ? 10 : (difficulty == .normal ? 5 : 0)
        let scoreBonus = score / 50
        return baseFragments + difficultyBonus + scoreBonus
    }
}

// MARK: - Pause Menu View
struct PauseMenuView: View {
    let accentColor: Color
    let onResume: () -> Void
    let onQuit: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.primaryBackground.opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Pause icon
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(accentColor)
                }
                .scaleEffect(isAnimating ? 1 : 0.8)
                .opacity(isAnimating ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isAnimating)
                
                Text("Paused")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .opacity(isAnimating ? 1 : 0)
                    .animation(.easeOut.delay(0.1), value: isAnimating)
                
                VStack(spacing: 16) {
                    Button(action: onResume) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Resume")
                        }
                        .primaryButtonStyle()
                    }
                    
                    Button(action: onQuit) {
                        HStack {
                            Image(systemName: "xmark")
                            Text("Quit Trail")
                        }
                        .secondaryButtonStyle()
                    }
                }
                .padding(.horizontal, 40)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                .animation(.easeOut.delay(0.2), value: isAnimating)
            }
        }
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
    }
}

#Preview {
    GameView(trail: .shiftingPathways, level: 1, difficulty: .easy)
}

