//
//  MainMenuView.swift
//  DF768
//

import SwiftUI

struct MainMenuView: View {
    @StateObject private var gameManager = GameManager.shared
    @State private var showTrails = false
    @State private var showStatistics = false
    @State private var showSettings = false
    @State private var isAnimating = false
    @State private var buttonScale: [Int: Bool] = [:]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Animated background
                AnimatedMenuBackground()
                
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: 80)
                        
                        // Logo area with animated glow
                        VStack(spacing: 16) {
                            ZStack {
                                // Outer glow ring
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.primaryAccent, Color.secondaryAccent],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                                    .frame(width: 140, height: 140)
                                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                                    .opacity(isAnimating ? 0.5 : 0.8)
                                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                                
                                // Inner circle
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [Color.primaryAccent.opacity(0.3), Color.primaryBackground],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 60
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                
                                // Icon
                                Image(systemName: "waveform.path.ecg")
                                    .font(.system(size: 50, weight: .light))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.primaryAccent, Color.secondaryAccent],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .glowEffect(color: .primaryAccent, radius: 15)
                            }
                            
                            // Decorative lines
                            HStack(spacing: 20) {
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.clear, Color.secondaryAccent],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 60, height: 2)
                                
                                Circle()
                                    .fill(Color.secondaryAccent)
                                    .frame(width: 6, height: 6)
                                
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.secondaryAccent, Color.clear],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 60, height: 2)
                            }
                            .opacity(0.6)
                        }
                        .padding(.bottom, 60)
                        
                        // Menu buttons
                        VStack(spacing: 20) {
                            MenuButton(
                                title: "Trails",
                                subtitle: "Explore game worlds",
                                icon: "arrow.triangle.branch",
                                accentColor: .primaryAccent,
                                isPressed: buttonScale[0] ?? false
                            ) {
                                showTrails = true
                            }
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in buttonScale[0] = true }
                                    .onEnded { _ in buttonScale[0] = false }
                            )
                            
                            MenuButton(
                                title: "Statistics",
                                subtitle: "View your progress",
                                icon: "chart.bar.fill",
                                accentColor: .secondaryAccent,
                                isPressed: buttonScale[1] ?? false
                            ) {
                                showStatistics = true
                            }
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in buttonScale[1] = true }
                                    .onEnded { _ in buttonScale[1] = false }
                            )
                            
                            MenuButton(
                                title: "Settings",
                                subtitle: "Configure options",
                                icon: "gearshape.fill",
                                accentColor: .primaryAccent.opacity(0.7),
                                isPressed: buttonScale[2] ?? false
                            ) {
                                showSettings = true
                            }
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in buttonScale[2] = true }
                                    .onEnded { _ in buttonScale[2] = false }
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer()
                            .frame(height: 80)
                        
                        // Fragment counter
                        HStack(spacing: 12) {
                            Image(systemName: "diamond.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.secondaryAccent)
                                .glowEffect(color: .secondaryAccent, radius: 5)
                            
                            Text("\(gameManager.statistics.totalFragments)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.textPrimary)
                            
                            Text("fragments")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.textPrimary.opacity(0.6))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.primaryBackground.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.secondaryAccent.opacity(0.3), lineWidth: 1)
                                )
                        )
                        
                        Spacer()
                            .frame(height: 40)
                    }
                }
            }
            .navigationDestination(isPresented: $showTrails) {
                TrailsView()
            }
            .navigationDestination(isPresented: $showStatistics) {
                StatisticsView()
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Menu Button
struct MenuButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let isPressed: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(accentColor)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.textPrimary.opacity(0.6))
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(accentColor.opacity(0.8))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.primaryBackground.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [accentColor.opacity(0.5), accentColor.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Animated Menu Background
struct AnimatedMenuBackground: View {
    @State private var phase1: CGFloat = 0
    @State private var phase2: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Base gradient
            Color.primaryBackground
                .ignoresSafeArea()
            
            // Animated gradient orbs
            GeometryReader { geometry in
                ZStack {
                    // Primary orb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.primaryAccent.opacity(0.15), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                        .frame(width: 400, height: 400)
                        .offset(x: sin(phase1) * 50, y: cos(phase1) * 30)
                        .position(x: geometry.size.width * 0.3, y: geometry.size.height * 0.2)
                    
                    // Secondary orb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.secondaryAccent.opacity(0.1), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 180
                            )
                        )
                        .frame(width: 350, height: 350)
                        .offset(x: cos(phase2) * 40, y: sin(phase2) * 50)
                        .position(x: geometry.size.width * 0.7, y: geometry.size.height * 0.7)
                    
                    // Third orb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.primaryAccent.opacity(0.08), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .offset(x: sin(phase2 + 1) * 30, y: cos(phase1 + 2) * 40)
                        .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.5)
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                phase1 = .pi * 2
            }
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                phase2 = .pi * 2
            }
        }
    }
}

#Preview {
    MainMenuView()
}

