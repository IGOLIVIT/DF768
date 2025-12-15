//
//  GameManager.swift
//  DF768
//

import SwiftUI
import Combine

// MARK: - Difficulty
enum Difficulty: String, CaseIterable, Codable {
    case calm = "Calm"
    case focused = "Focused"
    case intense = "Intense"
    
    var speedMultiplier: Double {
        switch self {
        case .calm: return 1.0
        case .focused: return 1.4
        case .intense: return 1.8
        }
    }
    
    var rewardMultiplier: Int {
        switch self {
        case .calm: return 1
        case .focused: return 2
        case .intense: return 3
        }
    }
}

// MARK: - Game Type
enum GameType: String, CaseIterable, Codable, Identifiable {
    case pathDrop = "Path Drop"
    case signalSplit = "Signal Split"
    case orbitControl = "Orbit Control"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .pathDrop: return "arrow.down.forward.and.arrow.up.backward"
        case .signalSplit: return "point.topleft.down.to.point.bottomright.curvepath"
        case .orbitControl: return "circle.dotted"
        }
    }
    
    var description: String {
        switch self {
        case .pathDrop: return "Guide falling objects through obstacles"
        case .signalSplit: return "Split signals with precise timing"
        case .orbitControl: return "Release orbiting elements at the right moment"
        }
    }
    
    var rewardName: String {
        switch self {
        case .pathDrop: return "Pattern Fragments"
        case .signalSplit: return "Energy Marks"
        case .orbitControl: return "Stability Points"
        }
    }
    
    var levelCount: Int { 8 }
}

// MARK: - Level Progress
struct LevelProgress: Codable, Identifiable {
    var id: String { "\(gameType.rawValue)-\(level)-\(difficulty.rawValue)" }
    let gameType: GameType
    let level: Int
    let difficulty: Difficulty
    var completed: Bool
    var rewardsEarned: Int
    var accuracy: Double
    var timeSpent: TimeInterval
}

// MARK: - Statistics
struct GameStatistics: Codable {
    var totalSessionsPlayed: Int = 0
    var levelsCompleted: Int = 0
    var totalAccuracy: Double = 0
    var accuracyCount: Int = 0
    var totalTimeSpent: TimeInterval = 0
    var patternFragments: Int = 0
    var energyMarks: Int = 0
    var stabilityPoints: Int = 0
    var levelsProgress: [LevelProgress] = []
    
    var averageAccuracy: Double {
        guard accuracyCount > 0 else { return 0 }
        return totalAccuracy / Double(accuracyCount)
    }
    
    var formattedTimeSpent: String {
        let hours = Int(totalTimeSpent) / 3600
        let minutes = (Int(totalTimeSpent) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Game Manager
class GameManager: ObservableObject {
    static let shared = GameManager()
    
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    @Published var statistics: GameStatistics {
        didSet {
            saveStatistics()
        }
    }
    
    @Published var dailyFocusGame: GameType = .pathDrop
    
    private init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        if let data = UserDefaults.standard.data(forKey: "gameStatistics"),
           let stats = try? JSONDecoder().decode(GameStatistics.self, from: data) {
            self.statistics = stats
        } else {
            self.statistics = GameStatistics()
        }
        
        // Set daily focus based on day
        let dayIndex = Calendar.current.component(.day, from: Date()) % GameType.allCases.count
        self.dailyFocusGame = GameType.allCases[dayIndex]
    }
    
    private func saveStatistics() {
        if let data = try? JSONEncoder().encode(statistics) {
            UserDefaults.standard.set(data, forKey: "gameStatistics")
        }
    }
    
    func completeLevel(gameType: GameType, level: Int, difficulty: Difficulty, rewards: Int, accuracy: Double, timeSpent: TimeInterval) {
        let progress = LevelProgress(
            gameType: gameType,
            level: level,
            difficulty: difficulty,
            completed: true,
            rewardsEarned: rewards,
            accuracy: accuracy,
            timeSpent: timeSpent
        )
        
        // Check if level was already completed
        if let existingIndex = statistics.levelsProgress.firstIndex(where: {
            $0.gameType == gameType && $0.level == level && $0.difficulty == difficulty
        }) {
            statistics.levelsProgress[existingIndex] = progress
        } else {
            statistics.levelsProgress.append(progress)
            statistics.levelsCompleted += 1
            
            // Add rewards based on game type
            switch gameType {
            case .pathDrop:
                statistics.patternFragments += rewards
            case .signalSplit:
                statistics.energyMarks += rewards
            case .orbitControl:
                statistics.stabilityPoints += rewards
            }
        }
        
        statistics.totalSessionsPlayed += 1
        statistics.totalAccuracy += accuracy
        statistics.accuracyCount += 1
        statistics.totalTimeSpent += timeSpent
    }
    
    func isLevelCompleted(gameType: GameType, level: Int, difficulty: Difficulty) -> Bool {
        statistics.levelsProgress.contains {
            $0.gameType == gameType && $0.level == level && $0.difficulty == difficulty && $0.completed
        }
    }
    
    func getCompletedLevelsCount(for gameType: GameType) -> Int {
        statistics.levelsProgress.filter { $0.gameType == gameType && $0.completed }.count
    }
    
    func resetAllProgress() {
        statistics = GameStatistics()
        hasCompletedOnboarding = false
        UserDefaults.standard.removeObject(forKey: "gameStatistics")
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    }
}

// MARK: - Color Extensions
extension Color {
    // Colors are auto-generated from Assets.xcassets
    // Use .deepMidnightBlue, .brightCyan, .softMint, .darkSlate directly
    
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
}

// MARK: - View Extensions
extension View {
    func glowEffect(color: Color = .brightCyan, radius: CGFloat = 10) -> some View {
        self.shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
    }
    
    func cardStyle(accentColor: Color = .brightCyan) -> some View {
        self
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.darkSlate)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(accentColor.opacity(0.3), lineWidth: 1)
                    )
            )
    }
    
    func primaryButtonStyle() -> some View {
        self
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundColor(.deepMidnightBlue)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [Color.brightCyan, Color.softMint],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(.brightCyan)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.darkSlate)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.brightCyan.opacity(0.5), lineWidth: 1)
            )
    }
}

