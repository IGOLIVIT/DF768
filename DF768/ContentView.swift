//
//  ContentView.swift
//  DF768
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var gameManager = GameManager.shared
    @State private var showOnboarding: Bool = false
    @State private var isInitialized = false
    
    var body: some View {
        ZStack {
            if isInitialized {
                if showOnboarding {
                    OnboardingView {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showOnboarding = false
                        }
                    }
                    .transition(.opacity)
                } else {
                    MainHubView()
                        .transition(.opacity)
                }
            } else {
                SplashView()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showOnboarding = !gameManager.hasCompletedOnboarding
                    isInitialized = true
                }
            }
        }
    }
}

// MARK: - Splash View
struct SplashView: View {
    @State private var isAnimating = false
    @State private var particles: [FallingParticle] = []
    
    var body: some View {
        ZStack {
            Color.deepMidnightBlue
                .ignoresSafeArea()
            
            // Falling particles
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
            
            VStack(spacing: 24) {
                // Logo animation
                ZStack {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.brightCyan.opacity(0.4 - Double(index) * 0.1), Color.softMint.opacity(0.3 - Double(index) * 0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 100 + CGFloat(index) * 25, height: 100 + CGFloat(index) * 25)
                            .scaleEffect(isAnimating ? 1.1 : 0.9)
                            .opacity(isAnimating ? 0.6 : 0.9)
                            .animation(
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.15),
                                value: isAnimating
                            )
                    }
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.brightCyan.opacity(0.4), Color.deepMidnightBlue],
                                center: .center,
                                startRadius: 0,
                                endRadius: 45
                            )
                        )
                        .frame(width: 90, height: 90)
                    
                    Image(systemName: "arrow.down.forward.and.arrow.up.backward")
                        .font(.system(size: 36, weight: .light))
                        .foregroundColor(.brightCyan)
                        .glowEffect(color: .brightCyan, radius: 15)
                }
                .scaleEffect(isAnimating ? 1 : 0.8)
                .opacity(isAnimating ? 1 : 0)
                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: isAnimating)
                
                // Loading dots
                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.softMint)
                            .frame(width: 10, height: 10)
                            .scaleEffect(isAnimating ? 1.2 : 0.6)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }
                }
                .opacity(isAnimating ? 1 : 0)
            }
        }
        .onAppear {
            isAnimating = true
            generateParticles()
        }
    }
    
    private func generateParticles() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        particles = (0..<15).map { _ in
            FallingParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...screenWidth),
                    y: CGFloat.random(in: 0...screenHeight)
                ),
                size: CGFloat.random(in: 3...8),
                color: Bool.random() ? Color.brightCyan.opacity(0.3) : Color.softMint.opacity(0.2),
                opacity: Double.random(in: 0.2...0.5)
            )
        }
    }
}

struct FallingParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let size: CGFloat
    let color: Color
    let opacity: Double
}

#Preview {
    ContentView()
}

