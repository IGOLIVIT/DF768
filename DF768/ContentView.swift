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
                    MainMenuView()
                        .transition(.opacity)
                }
            } else {
                // Splash screen
                SplashView()
            }
        }
        .onAppear {
            // Small delay for splash effect
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
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            Color.primaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Logo
                ZStack {
                    // Outer rings
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.primaryAccent.opacity(0.3 - Double(index) * 0.1), Color.secondaryAccent.opacity(0.2 - Double(index) * 0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 120 + CGFloat(index) * 30, height: 120 + CGFloat(index) * 30)
                            .scaleEffect(pulseAnimation ? 1.1 : 0.9)
                            .opacity(pulseAnimation ? 0.5 : 0.8)
                            .animation(
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: pulseAnimation
                            )
                    }
                    
                    // Inner circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.primaryAccent.opacity(0.3), Color.primaryBackground],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    // Icon
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(.primaryAccent)
                        .glowEffect(color: .primaryAccent, radius: 15)
                }
                .scaleEffect(isAnimating ? 1 : 0.8)
                .opacity(isAnimating ? 1 : 0)
                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: isAnimating)
                
                // Loading indicator
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.primaryAccent)
                            .frame(width: 8, height: 8)
                            .scaleEffect(pulseAnimation ? 1.2 : 0.6)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: pulseAnimation
                            )
                    }
                }
                .opacity(isAnimating ? 1 : 0)
                .animation(.easeIn.delay(0.3), value: isAnimating)
            }
        }
        .onAppear {
            isAnimating = true
            pulseAnimation = true
        }
    }
}

#Preview {
    ContentView()
}
