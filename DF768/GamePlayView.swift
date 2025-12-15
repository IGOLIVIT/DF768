//
//  GamePlayView.swift
//  DF768
//

import SwiftUI

struct GamePlayView: View {
    let gameType: GameType
    let level: Int
    let difficulty: Difficulty
    
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var gameManager = GameManager.shared
    @State private var showingPauseMenu = false
    
    private var accentColor: Color {
        switch gameType {
        case .pathDrop: return .brightCyan
        case .signalSplit: return .softMint
        case .orbitControl: return Color(red: 0.5, green: 0.7, blue: 1.0)
        }
    }
    
    var body: some View {
        ZStack {
            // Game content based on game type
            gameContent
            
            // Pause button overlay
            VStack {
                HStack {
                    Button(action: {
                        showingPauseMenu = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.darkSlate.opacity(0.9))
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
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
        .navigationBarHidden(true)
    }
    
    @ViewBuilder
    private var gameContent: some View {
        switch gameType {
        case .pathDrop:
            PathDropGame(level: level, difficulty: difficulty) { success, score, accuracy, timeSpent in
                handleGameComplete(success: success, score: score, accuracy: accuracy, timeSpent: timeSpent)
            }
        case .signalSplit:
            SignalSplitGame(level: level, difficulty: difficulty) { success, score, accuracy, timeSpent in
                handleGameComplete(success: success, score: score, accuracy: accuracy, timeSpent: timeSpent)
            }
        case .orbitControl:
            OrbitControlGame(level: level, difficulty: difficulty) { success, score, accuracy, timeSpent in
                handleGameComplete(success: success, score: score, accuracy: accuracy, timeSpent: timeSpent)
            }
        }
    }
    
    private func handleGameComplete(success: Bool, score: Int, accuracy: Double, timeSpent: TimeInterval) {
        if success {
            let rewards = calculateRewards(score: score)
            gameManager.completeLevel(
                gameType: gameType,
                level: level,
                difficulty: difficulty,
                rewards: rewards,
                accuracy: accuracy,
                timeSpent: timeSpent
            )
        }
        presentationMode.wrappedValue.dismiss()
    }
    
    private func calculateRewards(score: Int) -> Int {
        let baseRewards = 5
        let difficultyBonus = difficulty.rewardMultiplier * 3
        let scoreBonus = score / 40
        return baseRewards + difficultyBonus + scoreBonus
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
            Color.deepMidnightBlue.opacity(0.95)
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
                
                VStack(spacing: 14) {
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
                            Text("Quit Challenge")
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
            withAnimation { isAnimating = true }
        }
    }
}

#Preview {
    GamePlayView(gameType: .pathDrop, level: 1, difficulty: .calm)
}

