//
//  GameDetailView.swift
//  DF768
//

import SwiftUI

struct GameDetailView: View {
    let gameType: GameType
    
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var gameManager = GameManager.shared
    @State private var selectedDifficulty: Difficulty = .calm
    @State private var selectedLevel: Int? = nil
    @State private var navigateToGame = false
    @State private var isAnimating = false
    
    private var accentColor: Color {
        switch gameType {
        case .pathDrop: return .brightCyan
        case .signalSplit: return .softMint
        case .orbitControl: return Color(red: 0.5, green: 0.7, blue: 1.0)
        }
    }
    
    var body: some View {
        ZStack {
            GameDetailBackground(accentColor: accentColor)
                .allowsHitTesting(false)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Game info
                    gameInfoSection
                    
                    // Difficulty selector
                    difficultySection
                    
                    // Level grid
                    levelGridSection
                    
                    // Hidden NavigationLink
                    NavigationLink(
                        destination: Group {
                            if let level = selectedLevel {
                                GamePlayView(gameType: gameType, level: level, difficulty: selectedDifficulty)
                            }
                        },
                        isActive: $navigateToGame
                    ) {
                        EmptyView()
                    }
                    .hidden()
                    
                    Spacer().frame(height: 30)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation { isAnimating = true }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                }
                .foregroundColor(accentColor)
            }
            
            Spacer()
        }
        .padding(.top, 16)
    }
    
    // MARK: - Game Info
    private var gameInfoSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 90, height: 90)
                    .glowEffect(color: accentColor, radius: 18)
                
                Image(systemName: gameType.icon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(accentColor)
            }
            
            Text(gameType.rawValue)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            
            Text(gameType.description)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            // Reward info
            HStack(spacing: 8) {
                Image(systemName: "gift.fill")
                    .foregroundColor(.softMint)
                Text("Earn \(gameType.rewardName)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.softMint)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.softMint.opacity(0.15))
            )
        }
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.1), value: isAnimating)
    }
    
    // MARK: - Difficulty Section
    private var difficultySection: some View {
        VStack(spacing: 12) {
            Text("Select Difficulty")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.textSecondary)
            
            HStack(spacing: 10) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    DifficultyButton(
                        difficulty: difficulty,
                        isSelected: selectedDifficulty == difficulty,
                        accentColor: accentColor
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedDifficulty = difficulty
                        }
                    }
                }
            }
        }
        .padding(.top, 10)
        .opacity(isAnimating ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.2), value: isAnimating)
    }
    
    // MARK: - Level Grid
    private var levelGridSection: some View {
        VStack(spacing: 16) {
            Text("Choose Level")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.textSecondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(1...gameType.levelCount, id: \.self) { level in
                    LevelButton(
                        level: level,
                        isCompleted: gameManager.isLevelCompleted(
                            gameType: gameType,
                            level: level,
                            difficulty: selectedDifficulty
                        ),
                        accentColor: accentColor
                    ) {
                        selectedLevel = level
                        navigateToGame = true
                    }
                    .opacity(isAnimating ? 1 : 0)
                    .scaleEffect(isAnimating ? 1 : 0.8)
                    .animation(.spring(response: 0.4).delay(0.3 + Double(level) * 0.04), value: isAnimating)
                }
            }
        }
        .padding(.top, 10)
    }
}

// MARK: - Difficulty Button
struct DifficultyButton: View {
    let difficulty: Difficulty
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(difficulty.rawValue)
                .font(.system(size: 14, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundColor(isSelected ? .deepMidnightBlue : .textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? accentColor : Color.darkSlate)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(accentColor.opacity(isSelected ? 0 : 0.4), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Level Button
struct LevelButton: View {
    let level: Int
    let isCompleted: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isCompleted ? accentColor : Color.darkSlate)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(accentColor.opacity(isCompleted ? 0 : 0.4), lineWidth: 2)
                    )
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.deepMidnightBlue)
                } else {
                    Text("\(level)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                }
            }
            .glowEffect(color: isCompleted ? accentColor : .clear, radius: 8)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Game Detail Background
struct GameDetailBackground: View {
    let accentColor: Color
    
    var body: some View {
        ZStack {
            Color.deepMidnightBlue
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [accentColor.opacity(0.18), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 250
                            )
                        )
                        .frame(width: 500, height: 500)
                        .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.2)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [accentColor.opacity(0.08), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 180
                            )
                        )
                        .frame(width: 350, height: 350)
                        .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.8)
                }
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    GameDetailView(gameType: .pathDrop)
}

