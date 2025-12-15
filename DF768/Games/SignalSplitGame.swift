//
//  SignalSplitGame.swift
//  DF768
//

import SwiftUI

struct SignalSplitGame: View {
    let level: Int
    let difficulty: Difficulty
    let onComplete: (Bool, Int, Double, TimeInterval) -> Void
    
    @State private var signals: [Signal] = []
    @State private var splitZones: [SplitZone] = []
    @State private var score: Int = 0
    @State private var successfulSplits: Int = 0
    @State private var missedSignals: Int = 0
    @State private var maxMisses: Int = 5
    @State private var targetSplits: Int = 10
    @State private var gameStarted = false
    @State private var gameEnded = false
    @State private var showingCountdown = true
    @State private var countdownValue = 3
    @State private var countdownTimer: Timer?
    @State private var gameTimer: Timer?
    @State private var spawnTimer: Timer?
    @State private var startTime: Date?
    
    private var signalSpeed: CGFloat {
        CGFloat(0.003 * difficulty.speedMultiplier) + CGFloat(level) * 0.0003
    }
    
    private var spawnInterval: TimeInterval {
        max(0.8, 2.0 - Double(level) * 0.12) / difficulty.speedMultiplier
    }
    
    private var zoneCount: Int {
        min(2 + level / 3, 4)
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
                            // Split zones
                            ForEach(splitZones) { zone in
                                SplitZoneView(zone: zone, size: geometry.size) {
                                    handleSplit(at: zone)
                                }
                            }
                            
                            // Signals
                            ForEach(signals) { signal in
                                SignalView(signal: signal, size: geometry.size)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        // Progress bar
                        progressBar
                    }
                }
                
                if gameEnded {
                    LevelCompletionView(
                        won: successfulSplits >= targetSplits,
                        score: score,
                        rewardName: "Energy Marks",
                        rewardAmount: score / 25,
                        onContinue: {
                            let timeSpent = Date().timeIntervalSince(startTime ?? Date())
                            let accuracy = Double(successfulSplits) / Double(successfulSplits + missedSignals) * 100
                            onComplete(successfulSplits >= targetSplits, score, accuracy, timeSpent)
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
                Image(systemName: "bolt.fill")
                    .foregroundColor(.softMint)
                Text("\(score)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
            }
            
            Spacer()
            
            // Lives
            HStack(spacing: 5) {
                ForEach(0..<maxMisses, id: \.self) { index in
                    Circle()
                        .fill(index < (maxMisses - missedSignals) ? Color.softMint : Color.darkSlate)
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
                Text("Splits: \(successfulSplits)/\(targetSplits)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.textSecondary)
                Spacer()
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.darkSlate)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.softMint)
                        .frame(width: geo.size.width * CGFloat(successfulSplits) / CGFloat(targetSplits), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private func setupGame() {
        targetSplits = 8 + level * 2
        maxMisses = max(3, 6 - difficulty.rewardMultiplier)
        generateZones()
    }
    
    private func generateZones() {
        splitZones = (0..<zoneCount).map { index in
            let y = CGFloat(index + 1) / CGFloat(zoneCount + 1)
            return SplitZone(
                position: CGPoint(x: 0.85, y: y),
                size: CGSize(width: 0.12, height: 0.15)
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
        
        // Spawn timer
        spawnTimer = Timer.scheduledTimer(withTimeInterval: spawnInterval, repeats: true) { _ in
            spawnSignal()
        }
        
        // Game update timer
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            updateGame()
        }
    }
    
    private func spawnSignal() {
        guard !gameEnded else { return }
        
        let zoneIndex = Int.random(in: 0..<splitZones.count)
        let zone = splitZones[zoneIndex]
        
        let signal = Signal(
            position: CGPoint(x: 0.02, y: zone.position.y),
            targetZoneId: zone.id,
            speed: signalSpeed
        )
        
        signals.append(signal)
    }
    
    private func updateGame() {
        guard !gameEnded else { return }
        
        var signalsToRemove: [UUID] = []
        
        for index in signals.indices {
            signals[index].position.x += signals[index].speed
            
            // Check if signal passed without being split
            if signals[index].position.x > 0.98 && !signals[index].wasSplit {
                signalsToRemove.append(signals[index].id)
                missedSignals += 1
                
                if missedSignals >= maxMisses {
                    endGame()
                    return
                }
            }
        }
        
        signals.removeAll { signalsToRemove.contains($0.id) }
    }
    
    private func handleSplit(at zone: SplitZone) {
        guard !gameEnded else { return }
        
        // Find signals in the zone
        let hitRange: ClosedRange<CGFloat> = (zone.position.x - zone.size.width / 2)...(zone.position.x + zone.size.width / 2)
        
        if let index = signals.firstIndex(where: {
            $0.targetZoneId == zone.id &&
            !$0.wasSplit &&
            hitRange.contains($0.position.x)
        }) {
            // Calculate accuracy bonus
            let centerDistance = abs(signals[index].position.x - zone.position.x)
            let accuracyBonus = centerDistance < 0.03 ? 20 : (centerDistance < 0.06 ? 10 : 0)
            
            signals[index].wasSplit = true
            signals[index].splitAnimation = true
            
            score += (15 + accuracyBonus) * difficulty.rewardMultiplier
            successfulSplits += 1
            
            // Remove after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                signals.removeAll { $0.id == signals[safe: index]?.id }
            }
            
            // Check win condition
            if successfulSplits >= targetSplits {
                endGame()
            }
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
        spawnTimer?.invalidate()
        spawnTimer = nil
    }
}

// MARK: - Signal
struct Signal: Identifiable {
    let id = UUID()
    var position: CGPoint
    let targetZoneId: UUID
    let speed: CGFloat
    var wasSplit: Bool = false
    var splitAnimation: Bool = false
}

struct SignalView: View {
    let signal: Signal
    let size: CGSize
    
    var body: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [Color.brightCyan, Color.softMint],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 40, height: 12)
            .shadow(color: .brightCyan.opacity(0.6), radius: 8)
            .scaleEffect(signal.splitAnimation ? 2 : 1)
            .opacity(signal.splitAnimation ? 0 : 1)
            .position(
                x: signal.position.x * size.width,
                y: signal.position.y * size.height
            )
            .animation(.easeOut(duration: 0.3), value: signal.splitAnimation)
    }
}

// MARK: - Split Zone
struct SplitZone: Identifiable {
    let id = UUID()
    let position: CGPoint
    let size: CGSize
}

struct SplitZoneView: View {
    let zone: SplitZone
    let size: CGSize
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.softMint.opacity(isPressed ? 0.4 : 0.15))
                .frame(
                    width: zone.size.width * size.width,
                    height: zone.size.height * size.height
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.softMint.opacity(0.5), lineWidth: 2)
                )
                .overlay(
                    Image(systemName: "scissors")
                        .font(.system(size: 24))
                        .foregroundColor(.softMint.opacity(0.7))
                )
        }
        .buttonStyle(PlainButtonStyle())
        .position(
            x: zone.position.x * size.width,
            y: zone.position.y * size.height
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
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
    SignalSplitGame(level: 1, difficulty: .calm) { _, _, _, _ in }
}

