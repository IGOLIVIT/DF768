//
//  OrbitControlGame.swift
//  DF768
//

import SwiftUI

struct OrbitControlGame: View {
    let level: Int
    let difficulty: Difficulty
    let onComplete: (Bool, Int, Double, TimeInterval) -> Void
    
    @State private var orbiters: [Orbiter] = []
    @State private var targetZone: TargetZoneData = TargetZoneData(startAngle: 0, endAngle: 0.5)
    @State private var score: Int = 0
    @State private var successfulReleases: Int = 0
    @State private var missedReleases: Int = 0
    @State private var targetReleases: Int = 8
    @State private var maxMisses: Int = 4
    @State private var currentRound: Int = 0
    @State private var gameStarted = false
    @State private var gameEnded = false
    @State private var showingCountdown = true
    @State private var countdownValue = 3
    @State private var countdownTimer: Timer?
    @State private var gameTimer: Timer?
    @State private var startTime: Date?
    @State private var showFeedback: FeedbackType? = nil
    
    private var orbitSpeed: Double {
        (0.02 + Double(level) * 0.003) * difficulty.speedMultiplier
    }
    
    private var orbiterCount: Int {
        min(1 + level / 3, 3)
    }
    
    private var targetZoneSize: Double {
        max(0.15, 0.3 - Double(level) * 0.015)
    }
    
    enum FeedbackType {
        case perfect, good, miss
    }
    
    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2 - 50
            let orbitRadius = min(geometry.size.width, geometry.size.height) * 0.35
            
            ZStack {
                Color.deepMidnightBlue
                    .ignoresSafeArea()
                
                if showingCountdown {
                    GameCountdownView(value: countdownValue)
                } else {
                    VStack(spacing: 0) {
                        // Stats bar
                        statsBar
                        
                        Spacer()
                        
                        // Orbit area
                        ZStack {
                            // Orbit ring
                            Circle()
                                .stroke(Color.darkSlate, lineWidth: 3)
                                .frame(width: orbitRadius * 2, height: orbitRadius * 2)
                            
                            // Target zone arc
                            TargetZoneArc(
                                startAngle: targetZone.startAngle,
                                endAngle: targetZone.endAngle,
                                radius: orbitRadius
                            )
                            .stroke(Color.softMint.opacity(0.6), lineWidth: 20)
                            .frame(width: orbitRadius * 2, height: orbitRadius * 2)
                            
                            // Center circle
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.brightCyan.opacity(0.3), Color.deepMidnightBlue],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 40
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            // Orbiters
                            ForEach(orbiters) { orbiter in
                                OrbiterView(orbiter: orbiter, radius: orbitRadius)
                            }
                            
                            // Feedback
                            if let feedback = showFeedback {
                                FeedbackView(type: feedback)
                            }
                        }
                        .position(x: centerX, y: centerY)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            releaseOrbiters()
                        }
                        
                        Spacer()
                        
                        // Instructions
                        Text("Tap when orbiters are in the green zone")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.textSecondary)
                            .padding(.bottom, 30)
                        
                        // Progress
                        progressBar
                    }
                }
                
                if gameEnded {
                    LevelCompletionView(
                        won: successfulReleases >= targetReleases,
                        score: score,
                        rewardName: "Stability Points",
                        rewardAmount: score / 20,
                        onContinue: {
                            let timeSpent = Date().timeIntervalSince(startTime ?? Date())
                            let total = successfulReleases + missedReleases
                            let accuracy = total > 0 ? Double(successfulReleases) / Double(total) * 100 : 0
                            onComplete(successfulReleases >= targetReleases, score, accuracy, timeSpent)
                        }
                    )
                }
            }
        }
        .onAppear {
            setupGame()
            startCountdown()
        }
        .onDisappear {
            cleanupTimers()
        }
    }
    
    private var statsBar: some View {
        HStack {
            // Spacer for pause button area
            Spacer()
                .frame(width: 50)
            
            HStack(spacing: 8) {
                Image(systemName: "circle.hexagongrid.fill")
                    .foregroundColor(.brightCyan)
                Text("\(score)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
            }
            
            Spacer()
            
            // Lives
            HStack(spacing: 5) {
                ForEach(0..<maxMisses, id: \.self) { index in
                    Circle()
                        .fill(index < (maxMisses - missedReleases) ? Color.brightCyan : Color.darkSlate)
                        .frame(width: 10, height: 10)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var progressBar: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Round \(currentRound + 1)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.textSecondary)
                Spacer()
                Text("\(successfulReleases)/\(targetReleases)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.brightCyan)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.darkSlate)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.brightCyan)
                        .frame(width: geo.size.width * CGFloat(successfulReleases) / CGFloat(targetReleases), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private func setupGame() {
        targetReleases = 6 + level
        maxMisses = max(3, 5 - difficulty.rewardMultiplier + 1)
        generateRound()
    }
    
    private func generateRound() {
        // Generate target zone
        let startAngle = Double.random(in: 0..<(2 * .pi - targetZoneSize))
        targetZone = TargetZoneData(
            startAngle: startAngle,
            endAngle: startAngle + targetZoneSize * 2 * .pi
        )
        
        // Generate orbiters
        orbiters = (0..<orbiterCount).map { index in
            let baseAngle = Double(index) * (2 * .pi / Double(orbiterCount))
            let direction: Double = index % 2 == 0 ? 1 : -1
            return Orbiter(
                angle: baseAngle,
                speed: orbitSpeed * direction,
                isActive: true
            )
        }
    }
    
    private func startCountdown() {
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            countdownValue -= 1
            if countdownValue <= 0 {
                timer.invalidate()
                countdownTimer = nil
                showingCountdown = false
                startTime = Date()
                startGame()
            }
        }
    }
    
    private func startGame() {
        gameStarted = true
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            updateOrbiters()
        }
    }
    
    private func updateOrbiters() {
        guard !gameEnded else { return }
        
        for index in orbiters.indices where orbiters[index].isActive {
            orbiters[index].angle += orbiters[index].speed
            
            // Normalize angle
            if orbiters[index].angle > 2 * .pi {
                orbiters[index].angle -= 2 * .pi
            } else if orbiters[index].angle < 0 {
                orbiters[index].angle += 2 * .pi
            }
        }
    }
    
    private func releaseOrbiters() {
        guard gameStarted && !gameEnded else { return }
        
        var allInZone = true
        var perfectCount = 0
        
        for orbiter in orbiters where orbiter.isActive {
            let normalizedAngle = orbiter.angle.truncatingRemainder(dividingBy: 2 * .pi)
            let inZone = isAngleInZone(normalizedAngle)
            
            if inZone {
                let zoneMid = (targetZone.startAngle + targetZone.endAngle) / 2
                let distance = abs(normalizedAngle - zoneMid)
                if distance < targetZoneSize * .pi * 0.3 {
                    perfectCount += 1
                }
            } else {
                allInZone = false
            }
        }
        
        if allInZone {
            let isPerfect = perfectCount == orbiters.count
            let points = isPerfect ? 30 : 15
            score += points * difficulty.rewardMultiplier
            successfulReleases += 1
            showFeedback = isPerfect ? .perfect : .good
            
            if successfulReleases >= targetReleases {
                endGame()
            } else {
                nextRound()
            }
        } else {
            missedReleases += 1
            showFeedback = .miss
            
            if missedReleases >= maxMisses {
                endGame()
            } else {
                nextRound()
            }
        }
        
        // Hide feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showFeedback = nil
        }
    }
    
    private func isAngleInZone(_ angle: Double) -> Bool {
        let start = targetZone.startAngle
        let end = targetZone.endAngle
        
        if end > 2 * .pi {
            return angle >= start || angle <= (end - 2 * .pi)
        }
        return angle >= start && angle <= end
    }
    
    private func nextRound() {
        currentRound += 1
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            generateRound()
        }
    }
    
    private func endGame() {
        gameEnded = true
        cleanupTimers()
    }
    
    private func cleanupTimers() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        gameTimer?.invalidate()
        gameTimer = nil
    }
}

// MARK: - Target Zone Data
struct TargetZoneData {
    var startAngle: Double
    var endAngle: Double
}

// MARK: - Target Zone Arc
struct TargetZoneArc: Shape {
    let startAngle: Double
    let endAngle: Double
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .radians(startAngle - .pi / 2),
            endAngle: .radians(endAngle - .pi / 2),
            clockwise: false
        )
        
        return path
    }
}

// MARK: - Orbiter
struct Orbiter: Identifiable {
    let id = UUID()
    var angle: Double
    var speed: Double
    var isActive: Bool
}

struct OrbiterView: View {
    let orbiter: Orbiter
    let radius: CGFloat
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.brightCyan, Color.brightCyan.opacity(0.5)],
                    center: .center,
                    startRadius: 0,
                    endRadius: 15
                )
            )
            .frame(width: 30, height: 30)
            .shadow(color: .brightCyan.opacity(0.8), radius: 12)
            .offset(
                x: cos(orbiter.angle - .pi / 2) * radius,
                y: sin(orbiter.angle - .pi / 2) * radius
            )
    }
}

// MARK: - Feedback View
struct FeedbackView: View {
    let type: OrbitControlGame.FeedbackType
    
    var body: some View {
        Text(feedbackText)
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundColor(feedbackColor)
            .glowEffect(color: feedbackColor, radius: 15)
            .transition(.scale.combined(with: .opacity))
    }
    
    private var feedbackText: String {
        switch type {
        case .perfect: return "PERFECT!"
        case .good: return "GOOD!"
        case .miss: return "MISS"
        }
    }
    
    private var feedbackColor: Color {
        switch type {
        case .perfect: return .softMint
        case .good: return .brightCyan
        case .miss: return .red
        }
    }
}

#Preview {
    OrbitControlGame(level: 1, difficulty: .calm) { _, _, _, _ in }
}

