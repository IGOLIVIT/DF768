//
//  StatisticsView.swift
//  DF768
//

import SwiftUI

struct StatisticsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var gameManager = GameManager.shared
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background
            AnimatedMenuBackground()
                .allowsHitTesting(false)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.primaryAccent)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Title
                    VStack(spacing: 8) {
                        Text("Your Journey")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        
                        Text("Track your progress across all trails")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(.textPrimary.opacity(0.6))
                    }
                    .padding(.top, 10)
                    
                    // Main stats grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            icon: "checkmark.circle.fill",
                            value: "\(gameManager.statistics.totalLevelsCompleted)",
                            label: "Levels Completed",
                            color: .secondaryAccent,
                            delay: 0
                        )
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                        .animation(.spring(response: 0.5).delay(0.1), value: isAnimating)
                        
                        StatCard(
                            icon: "diamond.fill",
                            value: "\(gameManager.statistics.totalFragments)",
                            label: "Fragments Collected",
                            color: .primaryAccent,
                            delay: 0.1
                        )
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                        .animation(.spring(response: 0.5).delay(0.15), value: isAnimating)
                        
                        StatCard(
                            icon: "star.fill",
                            value: gameManager.statistics.bestDifficultyAchieved.rawValue,
                            label: "Best Difficulty",
                            color: Color(red: 1.0, green: 0.8, blue: 0.3),
                            delay: 0.2
                        )
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                        .animation(.spring(response: 0.5).delay(0.2), value: isAnimating)
                        
                        StatCard(
                            icon: "clock.fill",
                            value: formatTotalTime(),
                            label: "Total Time",
                            color: Color(red: 0.6, green: 0.5, blue: 1.0),
                            delay: 0.3
                        )
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                        .animation(.spring(response: 0.5).delay(0.25), value: isAnimating)
                    }
                    .padding(.horizontal, 20)
                    
                    // Trail breakdown
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Trail Progress")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            ForEach(Array(TrailType.allCases.enumerated()), id: \.element.id) { index, trail in
                                TrailStatRow(
                                    trail: trail,
                                    completedLevels: gameManager.getCompletedLevelsCount(for: trail),
                                    timeSpent: gameManager.statistics.timeSpentPerTrail[trail.rawValue] ?? 0,
                                    accentColor: trailColor(for: index)
                                )
                                .opacity(isAnimating ? 1 : 0)
                                .offset(x: isAnimating ? 0 : -20)
                                .animation(.spring(response: 0.5).delay(0.3 + Double(index) * 0.1), value: isAnimating)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 16)
                    
                    // Achievements preview
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Milestones")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                MilestoneCard(
                                    icon: "1.circle.fill",
                                    title: "First Steps",
                                    description: "Complete your first level",
                                    isAchieved: gameManager.statistics.totalLevelsCompleted >= 1
                                )
                                
                                MilestoneCard(
                                    icon: "5.circle.fill",
                                    title: "Pathfinder",
                                    description: "Complete 5 levels",
                                    isAchieved: gameManager.statistics.totalLevelsCompleted >= 5
                                )
                                
                                MilestoneCard(
                                    icon: "flame.fill",
                                    title: "Challenger",
                                    description: "Beat a level on Normal",
                                    isAchieved: gameManager.statistics.bestDifficultyAchieved != .easy
                                )
                                
                                MilestoneCard(
                                    icon: "bolt.fill",
                                    title: "Master",
                                    description: "Beat a level on Hard",
                                    isAchieved: gameManager.statistics.bestDifficultyAchieved == .hard
                                )
                                
                                MilestoneCard(
                                    icon: "diamond.fill",
                                    title: "Collector",
                                    description: "Collect 100 fragments",
                                    isAchieved: gameManager.statistics.totalFragments >= 100
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 16)
                    .opacity(isAnimating ? 1 : 0)
                    .animation(.spring(response: 0.5).delay(0.5), value: isAnimating)
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
    }
    
    private func trailColor(for index: Int) -> Color {
        switch index {
        case 0: return .primaryAccent
        case 1: return .secondaryAccent
        default: return Color(red: 0.6, green: 0.5, blue: 1.0)
        }
    }
    
    private func formatTotalTime() -> String {
        let totalSeconds = gameManager.statistics.timeSpentPerTrail.values.reduce(0, +)
        let minutes = Int(totalSeconds) / 60
        let seconds = Int(totalSeconds) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let delay: Double
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.textPrimary.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.primaryBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Trail Stat Row
struct TrailStatRow: View {
    let trail: TrailType
    let completedLevels: Int
    let timeSpent: TimeInterval
    let accentColor: Color
    
    private var totalLevels: Int {
        trail.levelCount * 3
    }
    
    private var progressValue: CGFloat {
        guard totalLevels > 0 else { return 0 }
        return CGFloat(completedLevels) / CGFloat(totalLevels)
    }
    
    private var percentageText: String {
        let percentage = Int(progressValue * 100)
        return "\(percentage)%"
    }
    
    private var progressText: String {
        "\(completedLevels)/\(totalLevels)"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            trailIcon
            trailInfo
            Spacer()
            progressRing
        }
        .padding(16)
        .background(rowBackground)
    }
    
    private var trailIcon: some View {
        ZStack {
            Circle()
                .fill(accentColor.opacity(0.2))
                .frame(width: 44, height: 44)
            
            Image(systemName: trail.icon)
                .font(.system(size: 18))
                .foregroundColor(accentColor)
        }
    }
    
    private var trailInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(trail.rawValue)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.textPrimary)
            
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 12))
                    Text(progressText)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                }
                .foregroundColor(.textPrimary.opacity(0.6))
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text(formatTime(timeSpent))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                }
                .foregroundColor(.textPrimary.opacity(0.6))
            }
        }
    }
    
    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.textPrimary.opacity(0.1), lineWidth: 4)
                .frame(width: 40, height: 40)
            
            Circle()
                .trim(from: 0, to: progressValue)
                .stroke(accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(-90))
            
            Text(percentageText)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
        }
    }
    
    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.primaryBackground.opacity(0.5))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(accentColor.opacity(0.2), lineWidth: 1)
            )
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Milestone Card
struct MilestoneCard: View {
    let icon: String
    let title: String
    let description: String
    let isAchieved: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isAchieved ? Color.secondaryAccent.opacity(0.2) : Color.textPrimary.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isAchieved ? .secondaryAccent : .textPrimary.opacity(0.3))
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(isAchieved ? .textPrimary : .textPrimary.opacity(0.5))
                
                Text(description)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.textPrimary.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            if isAchieved {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.secondaryAccent)
            }
        }
        .frame(width: 120)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.primaryBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isAchieved ? Color.secondaryAccent.opacity(0.3) : Color.textPrimary.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#Preview {
    StatisticsView()
}

