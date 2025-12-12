//
//  GameManager.swift
//  DF768
//

import SwiftUI
import Combine

// MARK: - Difficulty Enum
enum Difficulty: String, CaseIterable, Codable {
    case easy = "Easy"
    case normal = "Normal"
    case hard = "Hard"
    
    var speedMultiplier: Double {
        switch self {
        case .easy: return 1.0
        case .normal: return 1.5
        case .hard: return 2.0
        }
    }
    
    var countMultiplier: Int {
        switch self {
        case .easy: return 1
        case .normal: return 2
        case .hard: return 3
        }
    }
}

// MARK: - Trail Type
enum TrailType: String, CaseIterable, Codable, Identifiable {
    case shiftingPathways = "Shifting Pathways"
    case pulseOfReflections = "Pulse of Reflections"
    case fallingEchoLines = "Falling Echo Lines"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .shiftingPathways: return "square.grid.3x3"
        case .pulseOfReflections: return "waveform.path"
        case .fallingEchoLines: return "arrow.down.to.line"
        }
    }
    
    var description: String {
        switch self {
        case .shiftingPathways: return "Tap the shifting targets before time runs out"
        case .pulseOfReflections: return "Follow the pulsing light patterns"
        case .fallingEchoLines: return "Match the falling lines at the right moment"
        }
    }
    
    var levelCount: Int { 10 }
}

// MARK: - Level Progress
struct LevelProgress: Codable, Identifiable {
    var id: String { "\(trail.rawValue)-\(level)-\(difficulty.rawValue)" }
    let trail: TrailType
    let level: Int
    let difficulty: Difficulty
    var completed: Bool
    var fragmentsEarned: Int
    var timeSpent: TimeInterval
    var bestScore: Int
}

// MARK: - Game Statistics
struct GameStatistics: Codable {
    var totalLevelsCompleted: Int = 0
    var bestDifficultyAchieved: Difficulty = .easy
    var totalFragments: Int = 0
    var timeSpentPerTrail: [String: TimeInterval] = [:]
    var levelsProgress: [LevelProgress] = []
    
    mutating func updateBestDifficulty(_ difficulty: Difficulty) {
        let difficultyOrder: [Difficulty] = [.easy, .normal, .hard]
        if let currentIndex = difficultyOrder.firstIndex(of: bestDifficultyAchieved),
           let newIndex = difficultyOrder.firstIndex(of: difficulty),
           newIndex > currentIndex {
            bestDifficultyAchieved = difficulty
        }
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
    
    private init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        if let data = UserDefaults.standard.data(forKey: "gameStatistics"),
           let stats = try? JSONDecoder().decode(GameStatistics.self, from: data) {
            self.statistics = stats
        } else {
            self.statistics = GameStatistics()
        }
    }
    
    private func saveStatistics() {
        if let data = try? JSONEncoder().encode(statistics) {
            UserDefaults.standard.set(data, forKey: "gameStatistics")
        }
    }
    
    func completeLevel(trail: TrailType, level: Int, difficulty: Difficulty, fragments: Int, timeSpent: TimeInterval, score: Int) {
        let progress = LevelProgress(
            trail: trail,
            level: level,
            difficulty: difficulty,
            completed: true,
            fragmentsEarned: fragments,
            timeSpent: timeSpent,
            bestScore: score
        )
        
        // Check if level was already completed
        if let existingIndex = statistics.levelsProgress.firstIndex(where: {
            $0.trail == trail && $0.level == level && $0.difficulty == difficulty
        }) {
            let existing = statistics.levelsProgress[existingIndex]
            if score > existing.bestScore {
                statistics.levelsProgress[existingIndex] = progress
            }
            // Don't add fragments if already completed at this difficulty
        } else {
            statistics.levelsProgress.append(progress)
            statistics.totalLevelsCompleted += 1
            statistics.totalFragments += fragments
        }
        
        // Update time spent
        let trailKey = trail.rawValue
        statistics.timeSpentPerTrail[trailKey] = (statistics.timeSpentPerTrail[trailKey] ?? 0) + timeSpent
        
        // Update best difficulty
        statistics.updateBestDifficulty(difficulty)
    }
    
    func isLevelCompleted(trail: TrailType, level: Int, difficulty: Difficulty) -> Bool {
        statistics.levelsProgress.contains {
            $0.trail == trail && $0.level == level && $0.difficulty == difficulty && $0.completed
        }
    }
    
    func getCompletedLevelsCount(for trail: TrailType) -> Int {
        statistics.levelsProgress.filter { $0.trail == trail && $0.completed }.count
    }
    
    func resetAllProgress() {
        statistics = GameStatistics()
        hasCompletedOnboarding = false
        UserDefaults.standard.removeObject(forKey: "gameStatistics")
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    }
}

// MARK: - Color Extension
extension Color {
    static let textPrimary = Color(red: 0.96, green: 0.96, blue: 0.96)
}

// MARK: - View Extensions
extension View {
    func glowEffect(color: Color = .primaryAccent, radius: CGFloat = 10) -> some View {
        self.shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
    }
    
    func primaryButtonStyle() -> some View {
        self
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundColor(.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.primaryAccent)
            .cornerRadius(14)
            .glowEffect(radius: 8)
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(.textPrimary)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.secondaryAccent.opacity(0.3))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondaryAccent, lineWidth: 1)
            )
    }
}

