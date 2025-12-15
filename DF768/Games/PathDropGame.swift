//
//  PathDropGame.swift
//  DF768
//

import SwiftUI

struct PathDropGame: View {
    let level: Int
    let difficulty: Difficulty
    let onComplete: (Bool, Int, Double, TimeInterval) -> Void
    
    @State private var ball: Ball = Ball(position: CGPoint(x: 0.5, y: 0.05))
    @State private var pegs: [Peg] = []
    @State private var targets: [Target] = []
    @State private var score: Int = 0
    @State private var dropsRemaining: Int = 5
    @State private var successfulDrops: Int = 0
    @State private var gameStarted = false
    @State private var gameEnded = false
    @State private var showingCountdown = true
    @State private var countdownValue = 3
    @State private var countdownTimer: Timer?
    @State private var gameTimer: Timer?
    @State private var startTime: Date?
    @State private var isBallFalling = false
    
    private var pegRows: Int {
        min(4 + level, 8)
    }
    
    private var targetCount: Int {
        min(3 + (level / 3), 6)
    }
    
    private var fallSpeed: Double {
        0.012 * difficulty.speedMultiplier
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.deepMidnightBlue
                    .ignoresSafeArea()
                
                if showingCountdown {
                    GameCountdownView(value: countdownValue)
                } else {
                    VStack(spacing: 0) {
                        // Stats bar
                        statsBar
                        
                        // Game area
                        ZStack {
                            // Pegs
                            ForEach(pegs) { peg in
                                PegView(peg: peg, size: geometry.size)
                            }
                            
                            // Targets at bottom
                            ForEach(targets) { target in
                                TargetView(target: target, size: geometry.size)
                            }
                            
                            // Ball
                            if isBallFalling {
                                BallView(ball: ball, size: geometry.size)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    if !isBallFalling && dropsRemaining > 0 {
                                        let xPosition = value.location.x / geometry.size.width
                                        dropBall(at: xPosition)
                                    }
                                }
                        )
                        
                        // Instructions
                        Text(isBallFalling ? "Watch the path..." : "Tap to drop")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.textSecondary)
                            .padding(.bottom, 20)
                    }
                }
                
                if gameEnded {
                    LevelCompletionView(
                        won: successfulDrops >= (dropsRemaining + successfulDrops) / 2,
                        score: score,
                        rewardName: "Pattern Fragments",
                        rewardAmount: score / 20,
                        onContinue: {
                            let timeSpent = Date().timeIntervalSince(startTime ?? Date())
                            let accuracy = Double(successfulDrops) / Double(successfulDrops + (5 - dropsRemaining)) * 100
                            onComplete(successfulDrops >= 3, score, accuracy, timeSpent)
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
                Image(systemName: "star.fill")
                    .foregroundColor(.softMint)
                Text("\(score)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(index < dropsRemaining ? Color.brightCyan : Color.darkSlate)
                        .frame(width: 12, height: 12)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private func setupGame() {
        generatePegs()
        generateTargets()
    }
    
    private func generatePegs() {
        var newPegs: [Peg] = []
        
        for row in 0..<pegRows {
            let pegsInRow = row % 2 == 0 ? 5 : 4
            let offset: CGFloat = row % 2 == 0 ? 0 : 0.1
            
            for col in 0..<pegsInRow {
                let x = offset + CGFloat(col + 1) / CGFloat(pegsInRow + 1)
                let y = 0.15 + CGFloat(row) * 0.08
                
                newPegs.append(Peg(
                    position: CGPoint(x: x, y: y),
                    isBonus: Bool.random() && level >= 3 && col == pegsInRow / 2
                ))
            }
        }
        
        pegs = newPegs
    }
    
    private func generateTargets() {
        targets = (0..<targetCount).map { index in
            let x = CGFloat(index + 1) / CGFloat(targetCount + 1)
            let points = (index == targetCount / 2) ? 100 : (index == 0 || index == targetCount - 1 ? 20 : 50)
            return Target(
                position: CGPoint(x: x, y: 0.92),
                points: points,
                width: 0.8 / CGFloat(targetCount)
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
                gameStarted = true
            }
        }
    }
    
    private func dropBall(at xPosition: CGFloat) {
        guard !isBallFalling && dropsRemaining > 0 else { return }
        
        ball = Ball(position: CGPoint(x: xPosition.clamped(to: 0.1...0.9), y: 0.05))
        isBallFalling = true
        dropsRemaining -= 1
        
        startBallPhysics()
    }
    
    private func startBallPhysics() {
        var velocity = CGPoint(x: 0, y: 0)
        let gravity: CGFloat = 0.0004 * CGFloat(difficulty.speedMultiplier)
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            velocity.y += gravity
            
            // Random horizontal drift
            velocity.x += CGFloat.random(in: -0.0008...0.0008)
            
            // Bounce off walls
            if ball.position.x < 0.05 || ball.position.x > 0.95 {
                velocity.x *= -0.7
                ball.position.x = ball.position.x.clamped(to: 0.05...0.95)
            }
            
            // Check peg collisions
            for peg in pegs {
                let distance = hypot(ball.position.x - peg.position.x, ball.position.y - peg.position.y)
                if distance < 0.04 {
                    // Bounce
                    let bounceDirection = CGFloat.random(in: -0.01...0.01)
                    velocity.x = bounceDirection + (ball.position.x > peg.position.x ? 0.005 : -0.005)
                    velocity.y *= 0.5
                    
                    if peg.isBonus {
                        score += 10
                    }
                }
            }
            
            ball.position.x += velocity.x
            ball.position.y += velocity.y
            
            // Check if ball reached targets
            if ball.position.y >= 0.88 {
                checkTargetHit()
                return
            }
        }
    }
    
    private func checkTargetHit() {
        gameTimer?.invalidate()
        gameTimer = nil
        
        for target in targets {
            let halfWidth = target.width / 2
            if ball.position.x >= target.position.x - halfWidth &&
               ball.position.x <= target.position.x + halfWidth {
                score += target.points * difficulty.rewardMultiplier
                successfulDrops += 1
                break
            }
        }
        
        isBallFalling = false
        
        if dropsRemaining == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                gameEnded = true
            }
        }
    }
    
    private func cleanupTimers() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        gameTimer?.invalidate()
        gameTimer = nil
    }
}

// MARK: - Ball
struct Ball: Identifiable {
    let id = UUID()
    var position: CGPoint
}

struct BallView: View {
    let ball: Ball
    let size: CGSize
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.brightCyan, Color.brightCyan.opacity(0.6)],
                    center: .center,
                    startRadius: 0,
                    endRadius: 12
                )
            )
            .frame(width: 24, height: 24)
            .shadow(color: .brightCyan.opacity(0.8), radius: 10)
            .position(
                x: ball.position.x * size.width,
                y: ball.position.y * size.height
            )
    }
}

// MARK: - Peg
struct Peg: Identifiable {
    let id = UUID()
    let position: CGPoint
    let isBonus: Bool
}

struct PegView: View {
    let peg: Peg
    let size: CGSize
    
    var body: some View {
        Circle()
            .fill(peg.isBonus ? Color.softMint : Color.darkSlate)
            .frame(width: 16, height: 16)
            .overlay(
                Circle()
                    .stroke(peg.isBonus ? Color.softMint : Color.brightCyan.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: peg.isBonus ? .softMint.opacity(0.5) : .clear, radius: 5)
            .position(
                x: peg.position.x * size.width,
                y: peg.position.y * size.height
            )
    }
}

// MARK: - Target
struct Target: Identifiable {
    let id = UUID()
    let position: CGPoint
    let points: Int
    let width: CGFloat
}

struct TargetView: View {
    let target: Target
    let size: CGSize
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(targetColor)
                .frame(width: target.width * size.width - 8, height: 50)
            
            Text("\(target.points)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.deepMidnightBlue)
        }
        .position(
            x: target.position.x * size.width,
            y: target.position.y * size.height
        )
    }
    
    private var targetColor: Color {
        switch target.points {
        case 100: return .softMint
        case 50: return .brightCyan
        default: return .brightCyan.opacity(0.5)
        }
    }
}

// MARK: - Game Countdown
struct GameCountdownView: View {
    let value: Int
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.brightCyan.opacity(0.2))
                .frame(width: 140, height: 140)
                .glowEffect(color: .brightCyan, radius: 25)
            
            Text("\(value)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(.brightCyan)
        }
    }
}

// MARK: - CGFloat Extension
extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    PathDropGame(level: 1, difficulty: .calm) { _, _, _, _ in }
}

