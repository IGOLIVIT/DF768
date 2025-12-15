//
//  TrailsView.swift
//  DF768
//

import SwiftUI

struct TrailsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var gameManager = GameManager.shared
    @State private var selectedTrail: TrailType?
    @State private var isAnimating = false
    @State private var navigateToTrail = false
    
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
                        
                        // Fragment counter
                        HStack(spacing: 6) {
                            Image(systemName: "diamond.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.secondaryAccent)
                            Text("\(gameManager.statistics.totalFragments)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.textPrimary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.primaryBackground.opacity(0.8))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.secondaryAccent.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Title
                    VStack(spacing: 8) {
                        Text("Choose Your Trail")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        
                        Text("Select a pathway to begin your challenge")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(.textPrimary.opacity(0.6))
                    }
                    .padding(.top, 20)
                    
                    // Trails list
                    VStack(spacing: 20) {
                        ForEach(Array(TrailType.allCases.enumerated()), id: \.element.id) { index, trail in
                            NavigationLink(destination: TrailDetailView(trail: trail)) {
                                TrailCardContent(
                                    trail: trail,
                                    completedLevels: gameManager.getCompletedLevelsCount(for: trail),
                                    index: index
                                )
                            }
                            .buttonStyle(TrailCardButtonStyle())
                            .opacity(isAnimating ? 1 : 0)
                            .offset(y: isAnimating ? 0 : 30)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.1), value: isAnimating)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                        .frame(height: 40)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
    }
}

// MARK: - Trail Card Content
struct TrailCardContent: View {
    let trail: TrailType
    let completedLevels: Int
    let index: Int
    
    private var accentColor: Color {
        switch index {
        case 0: return .primaryAccent
        case 1: return .secondaryAccent
        default: return Color(red: 0.6, green: 0.5, blue: 1.0)
        }
    }
    
    private var gradientColors: [Color] {
        switch index {
        case 0: return [Color.primaryAccent.opacity(0.3), Color.primaryBackground]
        case 1: return [Color.secondaryAccent.opacity(0.25), Color.primaryBackground]
        default: return [Color(red: 0.6, green: 0.5, blue: 1.0).opacity(0.25), Color.primaryBackground]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                // Icon
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: trail.icon)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(accentColor)
                }
                .glowEffect(color: accentColor, radius: 8)
                
                Spacer()
                
                // Progress indicator
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(completedLevels)/\(trail.levelCount * 3)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(accentColor)
                    
                    Text("completed")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.textPrimary.opacity(0.5))
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(trail.rawValue)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Text(trail.description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.textPrimary.opacity(0.7))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Progress bar
            TrailProgressBar(
                completedLevels: completedLevels,
                totalLevels: trail.levelCount * 3,
                accentColor: accentColor
            )
            
            // Enter button
            HStack {
                Spacer()
                
                HStack(spacing: 8) {
                    Text("Enter Trail")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(accentColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(accentColor.opacity(0.15))
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Trail Progress Bar
struct TrailProgressBar: View {
    let completedLevels: Int
    let totalLevels: Int
    let accentColor: Color
    
    private var progress: CGFloat {
        guard totalLevels > 0 else { return 0 }
        return CGFloat(completedLevels) / CGFloat(totalLevels)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.textPrimary.opacity(0.1))
                    .frame(height: 6)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(accentColor)
                    .frame(width: geometry.size.width * progress, height: 6)
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Trail Card Button Style
struct TrailCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

// MARK: - Trail Detail View
struct TrailDetailView: View {
    let trail: TrailType
    
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var gameManager = GameManager.shared
    @State private var selectedDifficulty: Difficulty = .easy
    @State private var selectedLevel: Int? = nil
    @State private var isAnimating = false
    @State private var navigateToGame = false
    
    private var accentColor: Color {
        switch trail {
        case .shiftingPathways: return .primaryAccent
        case .pulseOfReflections: return .secondaryAccent
        case .fallingEchoLines: return Color(red: 0.6, green: 0.5, blue: 1.0)
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            TrailBackground(trailType: trail)
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
                            .foregroundColor(accentColor)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Trail title with glow
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(accentColor.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .glowEffect(color: accentColor, radius: 15)
                            
                            Image(systemName: trail.icon)
                                .font(.system(size: 36, weight: .medium))
                                .foregroundColor(accentColor)
                        }
                        
                        Text(trail.rawValue)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                            .glowEffect(color: accentColor, radius: 5)
                        
                        Text(trail.description)
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(.textPrimary.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 20)
                    
                    // Difficulty selector
                    VStack(spacing: 12) {
                        Text("Select Difficulty")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.textPrimary.opacity(0.8))
                        
                        HStack(spacing: 12) {
                            ForEach(Difficulty.allCases, id: \.self) { difficulty in
                                DifficultyButton(
                                    difficulty: difficulty,
                                    isSelected: selectedDifficulty == difficulty,
                                    accentColor: accentColor
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedDifficulty = difficulty
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Level grid
                    VStack(spacing: 16) {
                        Text("Choose Level")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.textPrimary.opacity(0.8))
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(1...trail.levelCount, id: \.self) { level in
                                LevelButton(
                                    level: level,
                                    isCompleted: gameManager.isLevelCompleted(
                                        trail: trail,
                                        level: level,
                                        difficulty: selectedDifficulty
                                    ),
                                    accentColor: accentColor
                                ) {
                                    selectedLevel = level
                                    navigateToGame = true
                                }
                                .opacity(isAnimating ? 1 : 0)
                                .scaleEffect(isAnimating ? 1 : 0.8)
                                .animation(.spring(response: 0.4).delay(Double(level) * 0.05), value: isAnimating)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Hidden NavigationLink
                    NavigationLink(
                        destination: Group {
                            if let level = selectedLevel {
                                GameView(trail: trail, level: level, difficulty: selectedDifficulty)
                            }
                        },
                        isActive: $navigateToGame
                    ) {
                        EmptyView()
                    }
                    .hidden()
                    
                    Spacer()
                        .frame(height: 40)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
    }
}

// MARK: - Difficulty Button
struct DifficultyButton: View {
    let difficulty: Difficulty
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(difficulty.rawValue)
                .font(.system(size: 14, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundColor(isSelected ? .primaryBackground : .textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? accentColor : Color.primaryBackground.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(accentColor.opacity(isSelected ? 0 : 0.5), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Level Button
struct LevelButton: View {
    let level: Int
    let isCompleted: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? accentColor : Color.primaryBackground.opacity(0.5))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(accentColor.opacity(isCompleted ? 0 : 0.5), lineWidth: 2)
                        )
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primaryBackground)
                    } else {
                        Text("\(level)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                    }
                }
                .glowEffect(color: isCompleted ? accentColor : .clear, radius: 6)
                
                Text("\(level)")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.textPrimary.opacity(0.6))
            }
        }
        .buttonStyle(LevelButtonStyle())
    }
}

// MARK: - Level Button Style
struct LevelButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Trail Background
struct TrailBackground: View {
    let trailType: TrailType
    
    @State private var phase: CGFloat = 0
    
    private var primaryColor: Color {
        switch trailType {
        case .shiftingPathways: return .primaryAccent
        case .pulseOfReflections: return .secondaryAccent
        case .fallingEchoLines: return Color(red: 0.6, green: 0.5, blue: 1.0)
        }
    }
    
    var body: some View {
        ZStack {
            Color.primaryBackground
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                ZStack {
                    // Animated gradient
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [primaryColor.opacity(0.2), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 250
                            )
                        )
                        .frame(width: 500, height: 500)
                        .offset(x: sin(phase) * 50, y: cos(phase) * 30)
                        .position(x: geometry.size.width * 0.3, y: geometry.size.height * 0.25)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [primaryColor.opacity(0.1), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                        .frame(width: 400, height: 400)
                        .offset(x: cos(phase) * 40, y: sin(phase) * 50)
                        .position(x: geometry.size.width * 0.7, y: geometry.size.height * 0.7)
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                phase = .pi * 2
            }
        }
    }
}

#Preview {
    NavigationView {
        TrailsView()
    }
}
