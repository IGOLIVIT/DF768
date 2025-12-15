//
//  FallingEchoLinesGame.swift
//  DF768
//

import SwiftUI

struct FallingEchoLinesGame: View {
    let level: Int
    let difficulty: Difficulty
    let onComplete: (Bool, Int, TimeInterval) -> Void
    
    @State private var lanes: [Lane] = []
    @State private var fallingLines: [FallingLine] = []
    @State private var score: Int = 0
    @State private var combo: Int = 0
    @State private var maxCombo: Int = 0
    @State private var missedLines: Int = 0
    @State private var maxMisses: Int = 10
    @State private var gameStarted = false
    @State private var gameEnded = false
    @State private var won = false
    @State private var showingCountdown = true
    @State private var countdownValue = 3
    @State private var countdownTimer: Timer?
    @State private var startTime: Date?
    @State private var spawnTimer: Timer?
    @State private var gameTimer: Timer?
    @State private var targetScore: Int = 500
    
    private var laneCount: Int {
        // Level 1-3: 3 lanes, Level 4-6: 4 lanes, Level 7-10: 5 lanes
        if level <= 3 {
            return 3
        } else if level <= 6 {
            return 4
        } else {
            return 5
        }
    }
    
    private var fallSpeed: Double {
        // Level 1: 3.0s, Level 10: 1.5s (faster fall = harder)
        let base = max(1.5, 3.0 - Double(level - 1) * 0.17)
        return base / difficulty.speedMultiplier
    }
    
    private var spawnInterval: TimeInterval {
        // Level 1: 1.2s, Level 10: 0.5s (more frequent spawns)
        let base = max(0.5, 1.2 - Double(level - 1) * 0.08)
        return base / difficulty.speedMultiplier
    }
    
    private var hasMixedSpeed: Bool {
        level >= 5
    }
    
    private var calculatedTargetScore: Int {
        // Level 1: 300, Level 10: 800
        let base = 300 + (level - 1) * 55
        return base + (difficulty.countMultiplier - 1) * 100
    }
    
    private var calculatedMaxMisses: Int {
        // Easy: 10, Normal: 8, Hard: 6 - reduces slightly with level
        let base = 10 - (difficulty == .hard ? 4 : (difficulty == .normal ? 2 : 0))
        return max(4, base - (level - 1) / 3)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.primaryBackground
                    .ignoresSafeArea()
                
                if showingCountdown {
                    CountdownView(value: countdownValue)
                } else {
                    VStack(spacing: 0) {
                        // Game stats
                        HStack {
                            // Score
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Score")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.textPrimary.opacity(0.6))
                                Text("\(score)/\(targetScore)")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.textPrimary)
                            }
                            
                            Spacer()
                            
                            // Combo
                            if combo > 1 {
                                HStack(spacing: 4) {
                                    Image(systemName: "flame.fill")
                                        .foregroundColor(.orange)
                                    Text("x\(combo)")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.orange)
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                            
                            Spacer()
                            
                            // Misses
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Lives")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.textPrimary.opacity(0.6))
                                HStack(spacing: 4) {
                                    ForEach(0..<maxMisses, id: \.self) { index in
                                        Circle()
                                            .fill(index < (maxMisses - missedLines) ? Color.secondaryAccent : Color.red.opacity(0.3))
                                            .frame(width: 8, height: 8)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 20)
                        
                        // Game area
                        ZStack {
                            // Lane backgrounds
                            HStack(spacing: 4) {
                                ForEach(lanes) { lane in
                                    LaneView(lane: lane, width: (geometry.size.width - 40 - CGFloat(laneCount - 1) * 4) / CGFloat(laneCount))
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Falling lines
                            ForEach(fallingLines) { line in
                                FallingLineView(
                                    line: line,
                                    laneWidth: (geometry.size.width - 40 - CGFloat(laneCount - 1) * 4) / CGFloat(laneCount),
                                    totalWidth: geometry.size.width - 40,
                                    laneCount: laneCount,
                                    height: geometry.size.height - 200
                                )
                            }
                            
                            // Hit zone
                            VStack {
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    ForEach(0..<laneCount, id: \.self) { index in
                                        HitZoneButton(
                                            laneIndex: index,
                                            color: laneColor(for: index),
                                            width: (geometry.size.width - 40 - CGFloat(laneCount - 1) * 4) / CGFloat(laneCount)
                                        ) {
                                            handleTap(lane: index, hitY: geometry.size.height - 200 - 60)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .frame(height: geometry.size.height - 200)
                    }
                }
                
                // Game over overlay
                if gameEnded {
                    GameEndOverlay(
                        won: won,
                        score: score,
                        onDismiss: {
                            let timeSpent = Date().timeIntervalSince(startTime ?? Date())
                            onComplete(won, score, timeSpent)
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
    
    private func laneColor(for index: Int) -> Color {
        let colors: [Color] = [.primaryAccent, .secondaryAccent, Color(red: 0.6, green: 0.5, blue: 1.0), Color(red: 1.0, green: 0.6, blue: 0.4), Color(red: 0.4, green: 0.8, blue: 0.6)]
        return colors[index % colors.count]
    }
    
    private func setupGame() {
        lanes = (0..<laneCount).map { Lane(id: $0, color: laneColor(for: $0)) }
        targetScore = calculatedTargetScore
        maxMisses = calculatedMaxMisses
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
        
        // Spawn timer
        spawnTimer = Timer.scheduledTimer(withTimeInterval: spawnInterval, repeats: true) { _ in
            spawnLine()
        }
        
        // Game update timer
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            updateGame()
        }
    }
    
    private func spawnLine() {
        guard !gameEnded else { return }
        
        let lane = Int.random(in: 0..<laneCount)
        let speed = hasMixedSpeed ? Double.random(in: fallSpeed * 0.7...fallSpeed * 1.3) : fallSpeed
        
        let newLine = FallingLine(
            id: UUID(),
            lane: lane,
            progress: 0,
            speed: speed,
            color: laneColor(for: lane)
        )
        
        withAnimation(.none) {
            fallingLines.append(newLine)
        }
    }
    
    private func updateGame() {
        guard !gameEnded else { return }
        
        var linesToRemove: [UUID] = []
        
        for index in fallingLines.indices {
            fallingLines[index].progress += 0.016 / fallingLines[index].speed
            
            // Check if line passed without being hit
            if fallingLines[index].progress > 1.1 && !fallingLines[index].wasHit {
                linesToRemove.append(fallingLines[index].id)
                missedLines += 1
                combo = 0
                
                if missedLines >= maxMisses {
                    endGame(success: false)
                    return
                }
            }
        }
        
        fallingLines.removeAll { linesToRemove.contains($0.id) }
        
        // Check win condition
        if score >= targetScore {
            endGame(success: true)
        }
    }
    
    private func handleTap(lane: Int, hitY: CGFloat) {
        guard !gameEnded else { return }
        
        // Find lines in the hit zone
        let hitZoneStart: CGFloat = 0.85
        let hitZoneEnd: CGFloat = 1.05
        
        if let index = fallingLines.firstIndex(where: {
            $0.lane == lane &&
            !$0.wasHit &&
            $0.progress >= hitZoneStart &&
            $0.progress <= hitZoneEnd
        }) {
            // Perfect or good hit based on accuracy
            let accuracy = abs(fallingLines[index].progress - 0.95)
            let points: Int
            
            if accuracy < 0.03 {
                // Perfect
                points = 20 + combo * 2
            } else if accuracy < 0.06 {
                // Great
                points = 15 + combo
            } else {
                // Good
                points = 10
            }
            
            fallingLines[index].wasHit = true
            
            // Visual feedback
            withAnimation(.spring(response: 0.2)) {
                fallingLines[index].hitAnimation = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                fallingLines.removeAll { $0.id == fallingLines[safe: index]?.id }
            }
            
            score += points * difficulty.countMultiplier
            combo += 1
            maxCombo = max(maxCombo, combo)
        }
    }
    
    private func endGame(success: Bool) {
        won = success
        gameEnded = true
        cleanupTimers()
    }
    
    private func cleanupTimers() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        spawnTimer?.invalidate()
        spawnTimer = nil
        gameTimer?.invalidate()
        gameTimer = nil
    }
}

// MARK: - Lane
struct Lane: Identifiable {
    let id: Int
    let color: Color
}

// MARK: - Falling Line
struct FallingLine: Identifiable {
    let id: UUID
    let lane: Int
    var progress: CGFloat
    let speed: Double
    let color: Color
    var wasHit: Bool = false
    var hitAnimation: Bool = false
}

// MARK: - Lane View
struct LaneView: View {
    let lane: Lane
    let width: CGFloat
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [lane.color.opacity(0.05), lane.color.opacity(0.02)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: width)
            .overlay(
                Rectangle()
                    .stroke(lane.color.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Falling Line View
struct FallingLineView: View {
    let line: FallingLine
    let laneWidth: CGFloat
    let totalWidth: CGFloat
    let laneCount: Int
    let height: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(
                LinearGradient(
                    colors: [line.color, line.color.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: laneWidth - 8, height: 40)
            .shadow(color: line.color.opacity(0.6), radius: line.wasHit ? 20 : 8)
            .scaleEffect(line.hitAnimation ? 1.5 : 1.0)
            .opacity(line.hitAnimation ? 0 : 1)
            .position(
                x: 20 + laneWidth / 2 + CGFloat(line.lane) * (laneWidth + 4),
                y: height * line.progress
            )
    }
}

// MARK: - Hit Zone Button
struct HitZoneButton: View {
    let laneIndex: Int
    let color: Color
    let width: CGFloat
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(isPressed ? 0.6 : 0.3))
                    .frame(width: width, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color, lineWidth: 2)
                    )
                    .shadow(color: color.opacity(0.5), radius: isPressed ? 15 : 8)
                
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        onTap()
                    }
                }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Safe Array Access
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    FallingEchoLinesGame(level: 1, difficulty: .easy) { _, _, _ in }
}

