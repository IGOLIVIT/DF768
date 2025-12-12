//
//  ShiftingPathwaysGame.swift
//  DF768
//

import SwiftUI

struct ShiftingPathwaysGame: View {
    let level: Int
    let difficulty: Difficulty
    let onComplete: (Bool, Int, TimeInterval) -> Void
    
    @State private var gridSize: Int = 3
    @State private var tiles: [TileData] = []
    @State private var targetTiles: Set<Int> = []
    @State private var tappedTargets: Set<Int> = []
    @State private var score: Int = 0
    @State private var timeRemaining: TimeInterval = 30
    @State private var initialTime: TimeInterval = 30
    @State private var gameStarted = false
    @State private var gameEnded = false
    @State private var shuffleTimer: Timer?
    @State private var gameTimer: Timer?
    @State private var showingCountdown = true
    @State private var countdownValue = 3
    @State private var startTime: Date?
    
    private var shuffleInterval: TimeInterval {
        // Level 1-10: от 2.5 до 0.8 секунд
        let baseInterval: TimeInterval = max(0.8, 2.5 - Double(level - 1) * 0.19)
        return baseInterval / difficulty.speedMultiplier
    }
    
    private var targetCount: Int {
        // Level 1: 2 targets, Level 10: 6 targets
        let base = 2 + (level - 1) / 2
        return min(base + difficulty.countMultiplier - 1, 8)
    }
    
    private var hasDecoys: Bool {
        level >= 4
    }
    
    private var gameTime: TimeInterval {
        // Level 1: 30 sec, Level 10: 45 sec
        return 30 + Double(level - 1) * 1.5
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.primaryBackground
                    .ignoresSafeArea()
                
                if showingCountdown {
                    CountdownView(value: countdownValue)
                } else {
                    VStack(spacing: 20) {
                        // Game stats
                        HStack {
                            // Score
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.secondaryAccent)
                                Text("\(score)")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.textPrimary)
                            }
                            
                            Spacer()
                            
                            // Timer
                            HStack(spacing: 8) {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(timeRemaining < 10 ? .red : .primaryAccent)
                                Text(String(format: "%.1f", timeRemaining))
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(timeRemaining < 10 ? .red : .textPrimary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Instructions
                        Text("Tap the glowing targets!")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.textPrimary.opacity(0.7))
                        
                        // Progress
                        HStack(spacing: 4) {
                            ForEach(0..<targetCount, id: \.self) { index in
                                Circle()
                                    .fill(index < tappedTargets.count ? Color.secondaryAccent : Color.textPrimary.opacity(0.3))
                                    .frame(width: 10, height: 10)
                            }
                        }
                        
                        Spacer()
                        
                        // Game grid
                        let tileSize = min((geometry.size.width - 60) / CGFloat(gridSize), 100)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(tileSize), spacing: 8), count: gridSize), spacing: 8) {
                            ForEach(tiles) { tile in
                                TileView(
                                    tile: tile,
                                    size: tileSize,
                                    isTarget: targetTiles.contains(tile.id),
                                    isTapped: tappedTargets.contains(tile.id),
                                    isDecoy: tile.isDecoy
                                ) {
                                    handleTileTap(tile)
                                }
                            }
                        }
                        .padding(20)
                        
                        Spacer()
                    }
                }
                
                // Game over overlay
                if gameEnded {
                    GameEndOverlay(
                        won: tappedTargets.count >= targetCount,
                        score: score,
                        onDismiss: {
                            let timeSpent = Date().timeIntervalSince(startTime ?? Date())
                            onComplete(tappedTargets.count >= targetCount, score, timeSpent)
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
    
    private func setupGame() {
        // Grid size: Level 1-3: 3x3, Level 4-6: 4x4, Level 7-10: 5x5
        if level <= 3 {
            gridSize = 3
        } else if level <= 6 {
            gridSize = 4
        } else {
            gridSize = 5
        }
        
        initialTime = gameTime
        timeRemaining = gameTime
        
        let totalTiles = gridSize * gridSize
        tiles = (0..<totalTiles).map { index in
            TileData(
                id: index,
                isDecoy: hasDecoys && Bool.random() && index % 4 == 0
            )
        }
        
        generateTargets()
    }
    
    private func generateTargets() {
        targetTiles.removeAll()
        tappedTargets.removeAll()
        
        var availableIndices = Set(tiles.filter { !$0.isDecoy }.map { $0.id })
        
        while targetTiles.count < targetCount && !availableIndices.isEmpty {
            if let randomIndex = availableIndices.randomElement() {
                targetTiles.insert(randomIndex)
                availableIndices.remove(randomIndex)
            }
        }
    }
    
    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            countdownValue -= 1
            if countdownValue <= 0 {
                timer.invalidate()
                showingCountdown = false
                startGame()
            }
        }
    }
    
    private func startGame() {
        gameStarted = true
        startTime = Date()
        
        // Game timer
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            timeRemaining -= 0.1
            if timeRemaining <= 0 {
                endGame()
            }
        }
        
        // Shuffle timer
        shuffleTimer = Timer.scheduledTimer(withTimeInterval: shuffleInterval, repeats: true) { _ in
            shuffleTiles()
        }
    }
    
    private func shuffleTiles() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            tiles.shuffle()
        }
    }
    
    private func handleTileTap(_ tile: TileData) {
        guard gameStarted && !gameEnded else { return }
        
        if tile.isDecoy {
            // Penalty for tapping decoy
            score = max(0, score - 5)
            timeRemaining = max(0, timeRemaining - 2)
            return
        }
        
        if targetTiles.contains(tile.id) && !tappedTargets.contains(tile.id) {
            tappedTargets.insert(tile.id)
            score += 10 * difficulty.countMultiplier
            
            if tappedTargets.count >= targetCount {
                // Generate new targets
                generateTargets()
                score += 20 // Bonus for completing set
            }
        }
    }
    
    private func endGame() {
        gameEnded = true
        cleanupTimers()
    }
    
    private func cleanupTimers() {
        shuffleTimer?.invalidate()
        shuffleTimer = nil
        gameTimer?.invalidate()
        gameTimer = nil
    }
}

// MARK: - Tile Data
struct TileData: Identifiable {
    let id: Int
    let isDecoy: Bool
}

// MARK: - Tile View
struct TileView: View {
    let tile: TileData
    let size: CGFloat
    let isTarget: Bool
    let isTapped: Bool
    let isDecoy: Bool
    let onTap: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .frame(width: size, height: size)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: isTarget ? 3 : 1)
                    )
                    .shadow(color: isTarget ? Color.primaryAccent.opacity(0.5) : .clear, radius: isTarget ? 10 : 0)
                
                if isTarget && !isTapped {
                    Image(systemName: "sparkle")
                        .font(.system(size: size * 0.3))
                        .foregroundColor(.primaryAccent)
                        .scaleEffect(isAnimating ? 1.2 : 0.9)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isAnimating)
                }
                
                if isTapped {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.3, weight: .bold))
                        .foregroundColor(.secondaryAccent)
                }
                
                if isDecoy {
                    Image(systemName: "xmark")
                        .font(.system(size: size * 0.25))
                        .foregroundColor(.red.opacity(0.6))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if isTarget {
                isAnimating = true
            }
        }
    }
    
    private var backgroundColor: Color {
        if isTapped {
            return Color.secondaryAccent.opacity(0.3)
        } else if isTarget {
            return Color.primaryAccent.opacity(0.2)
        } else if isDecoy {
            return Color.red.opacity(0.1)
        }
        return Color.primaryBackground.opacity(0.8)
    }
    
    private var borderColor: Color {
        if isTapped {
            return Color.secondaryAccent
        } else if isTarget {
            return Color.primaryAccent
        } else if isDecoy {
            return Color.red.opacity(0.3)
        }
        return Color.textPrimary.opacity(0.2)
    }
}

// MARK: - Countdown View
struct CountdownView: View {
    let value: Int
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.primaryAccent.opacity(0.2))
                .frame(width: 150, height: 150)
                .glowEffect(color: .primaryAccent, radius: 20)
            
            Text("\(value)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(.primaryAccent)
        }
    }
}

// MARK: - Game End Overlay
struct GameEndOverlay: View {
    let won: Bool
    let score: Int
    let onDismiss: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.primaryBackground.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Icon
                ZStack {
                    Circle()
                        .fill(won ? Color.secondaryAccent.opacity(0.2) : Color.red.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: won ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(won ? .secondaryAccent : .red)
                }
                .scaleEffect(isAnimating ? 1 : 0.5)
                .opacity(isAnimating ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isAnimating)
                
                VStack(spacing: 12) {
                    Text(won ? "Trail Complete!" : "Time's Up!")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    
                    Text("Score: \(score)")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.primaryAccent)
                }
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: isAnimating)
                
                if won {
                    // Reward animation
                    HStack(spacing: 16) {
                        ForEach(0..<3, id: \.self) { index in
                            Image(systemName: "diamond.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.secondaryAccent)
                                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                                .animation(.linear(duration: 2).repeatForever(autoreverses: false).delay(Double(index) * 0.2), value: isAnimating)
                                .glowEffect(color: .secondaryAccent, radius: 8)
                        }
                    }
                    .padding(.top, 10)
                }
                
                Button(action: onDismiss) {
                    Text("Continue")
                        .primaryButtonStyle()
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
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
    ShiftingPathwaysGame(level: 1, difficulty: .easy) { _, _, _ in }
}

