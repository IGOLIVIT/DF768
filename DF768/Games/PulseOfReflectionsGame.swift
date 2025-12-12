//
//  PulseOfReflectionsGame.swift
//  DF768
//

import SwiftUI

struct PulseOfReflectionsGame: View {
    let level: Int
    let difficulty: Difficulty
    let onComplete: (Bool, Int, TimeInterval) -> Void
    
    @State private var nodes: [PulseNode] = []
    @State private var sequence: [Int] = []
    @State private var playerSequence: [Int] = []
    @State private var currentDisplayIndex: Int = 0
    @State private var isShowingSequence = false
    @State private var isPlayerTurn = false
    @State private var activeNodeId: Int?
    @State private var score: Int = 0
    @State private var round: Int = 1
    @State private var maxRounds: Int = 5
    
    private func updateMaxRounds() {
        maxRounds = roundCount
    }
    @State private var gameEnded = false
    @State private var won = false
    @State private var showingCountdown = true
    @State private var countdownValue = 3
    @State private var startTime: Date?
    
    private var nodeCount: Int {
        // Level 1-3: 4 nodes, Level 4-6: 5 nodes, Level 7-10: 6 nodes
        if level <= 3 {
            return 4
        } else if level <= 6 {
            return 5
        } else {
            return 6
        }
    }
    
    private var sequenceLength: Int {
        // Base sequence length increases with level: 3-7
        let baseLength = 3 + (level - 1) / 2
        let roundBonus = round - 1
        let difficultyBonus: Int
        switch difficulty {
        case .hard: difficultyBonus = 2
        case .normal: difficultyBonus = 1
        case .easy: difficultyBonus = 0
        }
        return min(baseLength + roundBonus + difficultyBonus, 12)
    }
    
    private var displaySpeed: TimeInterval {
        // Level 1: 0.8s, Level 10: 0.4s
        let base = max(0.4, 0.8 - Double(level - 1) * 0.045)
        return base / difficulty.speedMultiplier
    }
    
    private var roundCount: Int {
        // More rounds at higher levels
        return 3 + level / 3
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundLayer
                
                if showingCountdown {
                    CountdownView(value: countdownValue)
                } else {
                    gameContentView(geometry: geometry)
                }
                
                if gameEnded {
                    gameOverLayer
                }
            }
        }
        .onAppear {
            setupGame()
            startCountdown()
        }
    }
    
    private var backgroundLayer: some View {
        Color.primaryBackground
            .ignoresSafeArea()
    }
    
    private var gameOverLayer: some View {
        GameEndOverlay(
            won: won,
            score: score,
            onDismiss: {
                let timeSpent = Date().timeIntervalSince(startTime ?? Date())
                onComplete(won, score, timeSpent)
            }
        )
    }
    
    private func gameContentView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 20) {
            statsBar
            statusText
            
            if isPlayerTurn {
                sequenceProgressIndicator
            }
            
            Spacer()
            
            nodesView(geometry: geometry)
            
            Spacer()
        }
    }
    
    private var statsBar: some View {
        HStack {
            roundInfo
            Spacer()
            scoreInfo
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var roundInfo: some View {
        HStack(spacing: 8) {
            Text("Round")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.textPrimary.opacity(0.7))
            Text("\(round)/\(maxRounds)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
        }
    }
    
    private var scoreInfo: some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .foregroundColor(.secondaryAccent)
            Text("\(score)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
        }
    }
    
    private var statusText: some View {
        Text(statusMessage)
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundColor(isPlayerTurn ? .secondaryAccent : .primaryAccent)
            .animation(.easeInOut, value: isPlayerTurn)
    }
    
    private var sequenceProgressIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<sequenceLength, id: \.self) { index in
                let isFilled = index < playerSequence.count
                Circle()
                    .fill(isFilled ? Color.secondaryAccent : Color.textPrimary.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    private func nodesView(geometry: GeometryProxy) -> some View {
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height / 2 - 50
        let center = CGPoint(x: centerX, y: centerY)
        let radius = min(geometry.size.width, geometry.size.height) * 0.32
        
        return ZStack {
            ForEach(nodes) { node in
                nodePositioned(node: node, center: center, radius: radius)
            }
            
            centerIndicator(at: center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func nodePositioned(node: PulseNode, center: CGPoint, radius: CGFloat) -> some View {
        let angleStep = (2.0 * Double.pi) / Double(nodeCount)
        let angle = angleStep * Double(node.id) - Double.pi / 2.0
        let x = center.x + radius * cos(angle)
        let y = center.y + radius * sin(angle)
        
        return PulseNodeView(
            node: node,
            isActive: activeNodeId == node.id,
            isEnabled: isPlayerTurn
        ) {
            handleNodeTap(node.id)
        }
        .position(x: x, y: y)
    }
    
    private func centerIndicator(at center: CGPoint) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.secondaryAccent.opacity(0.3), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 50
                )
            )
            .frame(width: 100, height: 100)
            .position(center)
    }
    
    private var statusMessage: String {
        if isShowingSequence {
            return "Watch the pattern..."
        } else if isPlayerTurn {
            return "Repeat the sequence!"
        } else {
            return "Get ready..."
        }
    }
    
    private func setupGame() {
        maxRounds = roundCount
        nodes = (0..<nodeCount).map { PulseNode(id: $0, color: nodeColor(for: $0)) }
    }
    
    private func nodeColor(for index: Int) -> Color {
        let colors: [Color] = [
            .primaryAccent,
            .secondaryAccent,
            Color(red: 0.6, green: 0.5, blue: 1.0),
            Color(red: 1.0, green: 0.6, blue: 0.4),
            Color(red: 0.4, green: 0.8, blue: 0.6),
            Color(red: 1.0, green: 0.8, blue: 0.3)
        ]
        return colors[index % colors.count]
    }
    
    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            countdownValue -= 1
            if countdownValue <= 0 {
                timer.invalidate()
                showingCountdown = false
                startTime = Date()
                startRound()
            }
        }
    }
    
    private func startRound() {
        generateSequence()
        showSequence()
    }
    
    private func generateSequence() {
        sequence = (0..<sequenceLength).map { _ in Int.random(in: 0..<nodeCount) }
        playerSequence = []
    }
    
    private func showSequence() {
        isShowingSequence = true
        isPlayerTurn = false
        currentDisplayIndex = 0
        
        displayNextInSequence()
    }
    
    private func displayNextInSequence() {
        guard currentDisplayIndex < sequence.count else {
            isShowingSequence = false
            isPlayerTurn = true
            return
        }
        
        let nodeId = sequence[currentDisplayIndex]
        
        withAnimation(.easeInOut(duration: 0.2)) {
            activeNodeId = nodeId
        }
        
        let hideDelay = displaySpeed * 0.6
        let nextDelay = displaySpeed * 0.4
        
        DispatchQueue.main.asyncAfter(deadline: .now() + hideDelay) {
            withAnimation(.easeInOut(duration: 0.2)) {
                activeNodeId = nil
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + nextDelay) {
                currentDisplayIndex += 1
                displayNextInSequence()
            }
        }
    }
    
    private func handleNodeTap(_ nodeId: Int) {
        guard isPlayerTurn && !gameEnded else { return }
        
        withAnimation(.easeInOut(duration: 0.15)) {
            activeNodeId = nodeId
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.15)) {
                activeNodeId = nil
            }
        }
        
        playerSequence.append(nodeId)
        
        let index = playerSequence.count - 1
        if playerSequence[index] != sequence[index] {
            endGame(success: false)
            return
        }
        
        if playerSequence.count == sequence.count {
            score += sequenceLength * 10 * difficulty.countMultiplier
            
            if round >= maxRounds {
                won = true
                endGame(success: true)
            } else {
                round += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    startRound()
                }
            }
        }
    }
    
    private func endGame(success: Bool) {
        won = success
        gameEnded = true
    }
}

// MARK: - Pulse Node
struct PulseNode: Identifiable {
    let id: Int
    let color: Color
}

// MARK: - Pulse Node View
struct PulseNodeView: View {
    let node: PulseNode
    let isActive: Bool
    let isEnabled: Bool
    let onTap: () -> Void
    
    @State private var isPulsing = false
    
    var body: some View {
        Button(action: onTap) {
            nodeContent
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
        .onAppear {
            if isActive {
                startPulsing()
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                startPulsing()
            } else {
                isPulsing = false
            }
        }
    }
    
    private var nodeContent: some View {
        ZStack {
            if isActive {
                outerGlow
            }
            
            mainNode
            
            if isActive {
                sparkle
            }
        }
        .scaleEffect(isActive ? 1.15 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
    }
    
    private var outerGlow: some View {
        Circle()
            .fill(node.color.opacity(0.3))
            .frame(width: 90, height: 90)
            .scaleEffect(isPulsing ? 1.3 : 1.0)
    }
    
    private var mainNode: some View {
        let activeOpacity: Double = isActive ? 1.0 : 0.6
        let inactiveOpacity: Double = isActive ? 0.8 : 0.3
        
        return Circle()
            .fill(
                RadialGradient(
                    colors: [node.color.opacity(activeOpacity), node.color.opacity(inactiveOpacity)],
                    center: .center,
                    startRadius: 0,
                    endRadius: 35
                )
            )
            .frame(width: 70, height: 70)
            .overlay(
                Circle()
                    .stroke(node.color, lineWidth: isActive ? 3 : 1)
            )
            .shadow(color: isActive ? node.color.opacity(0.8) : .clear, radius: isActive ? 15 : 0)
    }
    
    private var sparkle: some View {
        Image(systemName: "sparkle")
            .font(.system(size: 24))
            .foregroundColor(.white)
    }
    
    private func startPulsing() {
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            isPulsing = true
        }
    }
}

#Preview {
    PulseOfReflectionsGame(level: 1, difficulty: .easy) { _, _, _ in }
}
