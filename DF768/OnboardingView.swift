//
//  OnboardingView.swift
//  DF768
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject private var gameManager = GameManager.shared
    @State private var currentPage = 0
    @State private var isAnimating = false
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground()
            
            // Falling particles
            FallingParticlesView()
            
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    OnboardingPageView(
                        title: "Master Your Path",
                        description: "Every choice shapes the outcome. Guide objects through obstacles and discover the art of controlled trajectories.",
                        iconName: "arrow.down.forward.and.arrow.up.backward",
                        shapeType: .hexagon
                    )
                    .tag(0)
                    
                    OnboardingPageView(
                        title: "Perfect Your Timing",
                        description: "Precision matters. Split signals, release orbs, and make decisions at the exact right moment.",
                        iconName: "point.topleft.down.to.point.bottomright.curvepath",
                        shapeType: .circle
                    )
                    .tag(1)
                    
                    OnboardingPageView(
                        title: "Track Your Growth",
                        description: "Watch your skills evolve. Collect fragments, marks, and points as you progress through challenges.",
                        iconName: "chart.line.uptrend.xyaxis",
                        shapeType: .diamond
                    )
                    .tag(2)
                    
                    OnboardingPageView(
                        title: "Find Your Focus",
                        description: "Engage your mind with elegant mini-games designed for calm concentration and satisfying mastery.",
                        iconName: "brain.head.profile",
                        shapeType: .hexagon
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                // Page indicators and navigation
                VStack(spacing: 28) {
                    // Custom page indicators
                    HStack(spacing: 10) {
                        ForEach(0..<4, id: \.self) { index in
                            Capsule()
                                .fill(currentPage == index ? Color.brightCyan : Color.textPrimary.opacity(0.3))
                                .frame(width: currentPage == index ? 28 : 10, height: 10)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    
                    // Navigation buttons
                    HStack(spacing: 16) {
                        if currentPage > 0 {
                            Button(action: {
                                withAnimation { currentPage -= 1 }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.textSecondary)
                                .frame(width: 100, height: 50)
                            }
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                        }
                        
                        Button(action: {
                            if currentPage < 3 {
                                withAnimation { currentPage += 1 }
                            } else {
                                completeOnboarding()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text(currentPage == 3 ? "Start Exploring" : "Next")
                                Image(systemName: currentPage == 3 ? "arrow.right" : "chevron.right")
                            }
                            .primaryButtonStyle()
                        }
                        .scaleEffect(isAnimating && currentPage == 3 ? 1.02 : 1.0)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isAnimating)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    private func completeOnboarding() {
        gameManager.hasCompletedOnboarding = true
        onComplete()
    }
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let title: String
    let description: String
    let iconName: String
    let shapeType: OnboardingShapeType
    
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Animated shape with icon
            ZStack {
                OnboardingShape(type: shapeType)
                    .fill(
                        LinearGradient(
                            colors: [Color.brightCyan.opacity(0.25), Color.softMint.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                    .glowEffect(color: .brightCyan, radius: 20)
                    .rotationEffect(.degrees(isVisible ? 360 : 0))
                    .animation(.linear(duration: 35).repeatForever(autoreverses: false), value: isVisible)
                
                OnboardingShape(type: shapeType)
                    .stroke(Color.softMint.opacity(0.5), lineWidth: 1.5)
                    .frame(width: 185, height: 185)
                    .rotationEffect(.degrees(isVisible ? -360 : 0))
                    .animation(.linear(duration: 45).repeatForever(autoreverses: false), value: isVisible)
                
                Image(systemName: iconName)
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.textPrimary)
                    .glowEffect(color: .softMint, radius: 10)
            }
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.5)
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isVisible)
            
            VStack(spacing: 18) {
                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.15), value: isVisible)
                
                Text(description)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 36)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: isVisible)
            }
            
            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation { isVisible = true }
        }
        .onDisappear {
            isVisible = false
        }
    }
}

// MARK: - Shape Types
enum OnboardingShapeType {
    case hexagon, circle, diamond
}

struct OnboardingShape: Shape {
    let type: OnboardingShapeType
    
    func path(in rect: CGRect) -> Path {
        switch type {
        case .hexagon:
            return hexagonPath(in: rect)
        case .circle:
            return Path(ellipseIn: rect)
        case .diamond:
            return diamondPath(in: rect)
        }
    }
    
    private func hexagonPath(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3 - .pi / 2
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
    
    private func diamondPath(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Animated Gradient Background
struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color.deepMidnightBlue,
                Color.deepMidnightBlue.opacity(0.95),
                Color.brightCyan.opacity(0.12),
                Color.deepMidnightBlue
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - Falling Particles View
struct FallingParticlesView: View {
    @State private var particles: [AnimatedParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            generateParticles()
        }
    }
    
    private func generateParticles() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        particles = (0..<20).map { index in
            AnimatedParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...screenWidth),
                    y: CGFloat.random(in: 0...screenHeight)
                ),
                size: CGFloat.random(in: 2...7),
                color: index % 2 == 0 ? Color.brightCyan.opacity(0.25) : Color.softMint.opacity(0.2),
                opacity: Double.random(in: 0.15...0.4)
            )
        }
    }
}

struct AnimatedParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let size: CGFloat
    let color: Color
    let opacity: Double
}

#Preview {
    OnboardingView(onComplete: {})
}

