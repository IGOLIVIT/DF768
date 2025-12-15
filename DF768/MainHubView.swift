//
//  MainHubView.swift
//  DF768
//

import SwiftUI

struct MainHubView: View {
    @ObservedObject private var gameManager = GameManager.shared
    @State private var isAnimating = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated background
                HubBackground()
                    .allowsHitTesting(false)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        Spacer().frame(height: 20)
                        
                        // Header with rewards
                        headerSection
                        
                        // Daily Focus Section
                        dailyFocusSection
                        
                        // Choose a Challenge Section
                        challengeSection
                        
                        // Progress Overview Section
                        progressSection
                        
                        Spacer().frame(height: 30)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .onAppear {
            withAnimation { isAnimating = true }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: 12) {
            RewardPill(icon: "square.grid.3x3.fill", value: gameManager.statistics.patternFragments, color: .brightCyan)
            RewardPill(icon: "bolt.fill", value: gameManager.statistics.energyMarks, color: .softMint)
            RewardPill(icon: "circle.hexagongrid.fill", value: gameManager.statistics.stabilityPoints, color: .brightCyan.opacity(0.8))
            
            Spacer()
            
            NavigationLink(destination: StatisticsSettingsView()) {
                ZStack {
                    Circle()
                        .fill(Color.darkSlate)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.brightCyan)
                }
            }
        }
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : -20)
        .animation(.easeOut(duration: 0.5).delay(0.1), value: isAnimating)
    }
    
    // MARK: - Daily Focus Section
    private var dailyFocusSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.softMint)
                Text("Daily Focus")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
            }
            
            NavigationLink(destination: GameDetailView(gameType: gameManager.dailyFocusGame)) {
                DailyFocusCard(gameType: gameManager.dailyFocusGame)
            }
            .buttonStyle(CardButtonStyle())
        }
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.2), value: isAnimating)
    }
    
    // MARK: - Challenge Section
    private var challengeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Choose a Challenge")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            
            VStack(spacing: 14) {
                ForEach(Array(GameType.allCases.enumerated()), id: \.element.id) { index, gameType in
                    NavigationLink(destination: GameDetailView(gameType: gameType)) {
                        GameCard(
                            gameType: gameType,
                            completedLevels: gameManager.getCompletedLevelsCount(for: gameType),
                            accentColor: cardColor(for: index)
                        )
                    }
                    .buttonStyle(CardButtonStyle())
                    .opacity(isAnimating ? 1 : 0)
                    .offset(x: isAnimating ? 0 : -30)
                    .animation(.easeOut(duration: 0.5).delay(0.3 + Double(index) * 0.1), value: isAnimating)
                }
            }
        }
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Progress Overview")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            
            HStack(spacing: 12) {
                ProgressCard(
                    icon: "checkmark.circle.fill",
                    value: "\(gameManager.statistics.levelsCompleted)",
                    label: "Completed",
                    color: .softMint
                )
                
                ProgressCard(
                    icon: "target",
                    value: "\(Int(gameManager.statistics.averageAccuracy))%",
                    label: "Accuracy",
                    color: .brightCyan
                )
                
                ProgressCard(
                    icon: "clock.fill",
                    value: gameManager.statistics.formattedTimeSpent,
                    label: "Time",
                    color: .softMint.opacity(0.8)
                )
            }
        }
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.6), value: isAnimating)
    }
    
    private func cardColor(for index: Int) -> Color {
        switch index {
        case 0: return .brightCyan
        case 1: return .softMint
        default: return Color(red: 0.5, green: 0.7, blue: 1.0)
        }
    }
}

// MARK: - Reward Pill
struct RewardPill: View {
    let icon: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            Text("\(value)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.darkSlate)
        )
    }
}

// MARK: - Daily Focus Card
struct DailyFocusCard: View {
    let gameType: GameType
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.brightCyan.opacity(0.3), Color.softMint.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: gameType.icon)
                    .font(.system(size: 26))
                    .foregroundColor(.brightCyan)
            }
            .glowEffect(color: .brightCyan, radius: 10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(gameType.rawValue)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Text("Today's recommended challenge")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.softMint)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.darkSlate)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [Color.softMint.opacity(0.4), Color.brightCyan.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Game Card
struct GameCard: View {
    let gameType: GameType
    let completedLevels: Int
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 52, height: 52)
                
                Image(systemName: gameType.icon)
                    .font(.system(size: 22))
                    .foregroundColor(accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(gameType.rawValue)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Text(gameType.description)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(completedLevels)/\(gameType.levelCount * 3)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(accentColor)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(accentColor.opacity(0.7))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.darkSlate)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accentColor.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

// MARK: - Progress Card
struct ProgressCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.darkSlate)
        )
    }
}

// MARK: - Card Button Style
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Hub Background
struct HubBackground: View {
    var body: some View {
        ZStack {
            Color.deepMidnightBlue
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.brightCyan.opacity(0.12), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                        .frame(width: 400, height: 400)
                        .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.15)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.softMint.opacity(0.08), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 180
                            )
                        )
                        .frame(width: 350, height: 350)
                        .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.75)
                }
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    MainHubView()
}

