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
            // Animated background
            AnimatedGradientBackground()
            
            // Floating shapes
            FloatingShapesView()
            
            VStack(spacing: 0) {
                // Content
                TabView(selection: $currentPage) {
                    OnboardingPageView(
                        title: "Discover Hidden Trails",
                        description: "Embark on a journey through abstract pathways filled with unique challenges and visual harmony.",
                        iconName: "sparkles",
                        shapeType: .hexagon
                    )
                    .tag(0)
                    
                    OnboardingPageView(
                        title: "Master Each Challenge",
                        description: "Progress through carefully crafted puzzles that evolve from simple interactions to layered experiences.",
                        iconName: "puzzlepiece.fill",
                        shapeType: .circle
                    )
                    .tag(1)
                    
                    OnboardingPageView(
                        title: "Collect & Progress",
                        description: "Earn luminous fragments as you complete trails. Track your achievements and unlock new difficulties.",
                        iconName: "star.fill",
                        shapeType: .diamond
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                // Page indicators and button
                VStack(spacing: 32) {
                    // Custom page indicator
                    HStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { index in
                            Capsule()
                                .fill(currentPage == index ? Color.primaryAccent : Color.textPrimary.opacity(0.3))
                                .frame(width: currentPage == index ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    
                    // Navigation buttons
                    HStack(spacing: 16) {
                        if currentPage > 0 {
                            Button(action: {
                                withAnimation {
                                    currentPage -= 1
                                }
                            }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .secondaryButtonStyle()
                            }
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                        }
                        
                        Button(action: {
                            if currentPage < 2 {
                                withAnimation {
                                    currentPage += 1
                                }
                            } else {
                                completeOnboarding()
                            }
                        }) {
                            HStack {
                                Text(currentPage == 2 ? "Begin" : "Next")
                                if currentPage < 2 {
                                    Image(systemName: "chevron.right")
                                } else {
                                    Image(systemName: "arrow.right")
                                }
                            }
                            .primaryButtonStyle()
                        }
                        .scaleEffect(isAnimating ? 1.02 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 60)
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
                            colors: [Color.primaryAccent.opacity(0.3), Color.secondaryAccent.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                    .glowEffect(color: .primaryAccent, radius: 20)
                    .rotationEffect(.degrees(isVisible ? 360 : 0))
                    .animation(.linear(duration: 30).repeatForever(autoreverses: false), value: isVisible)
                
                OnboardingShape(type: shapeType)
                    .stroke(Color.secondaryAccent, lineWidth: 2)
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(isVisible ? -360 : 0))
                    .animation(.linear(duration: 40).repeatForever(autoreverses: false), value: isVisible)
                
                Image(systemName: iconName)
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.textPrimary)
                    .glowEffect(color: .secondaryAccent, radius: 10)
            }
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.5)
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isVisible)
            
            VStack(spacing: 20) {
                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: isVisible)
                
                Text(description)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundColor(.textPrimary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: isVisible)
            }
            
            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation {
                isVisible = true
            }
        }
        .onDisappear {
            isVisible = false
        }
    }
}

// MARK: - Shape Type
enum OnboardingShapeType {
    case hexagon, circle, diamond
}

// MARK: - Custom Shape
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
                Color.primaryBackground,
                Color.primaryBackground.opacity(0.95),
                Color.primaryAccent.opacity(0.15),
                Color.primaryBackground
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - Floating Shapes View
struct FloatingShapesView: View {
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<8, id: \.self) { index in
                    FloatingShape(index: index, screenSize: geometry.size)
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct FloatingShape: View {
    let index: Int
    let screenSize: CGSize
    
    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0
    
    private var shapeSize: CGFloat {
        CGFloat.random(in: 20...60)
    }
    
    private var initialPosition: CGPoint {
        CGPoint(
            x: CGFloat.random(in: 0...screenSize.width),
            y: CGFloat.random(in: 0...screenSize.height)
        )
    }
    
    var body: some View {
        Group {
            if index % 3 == 0 {
                Circle()
                    .fill(Color.primaryAccent.opacity(0.1))
            } else if index % 3 == 1 {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondaryAccent.opacity(0.08))
            } else {
                OnboardingShape(type: .hexagon)
                    .fill(Color.primaryAccent.opacity(0.06))
            }
        }
        .frame(width: shapeSize + CGFloat(index * 5), height: shapeSize + CGFloat(index * 5))
        .position(x: screenSize.width * CGFloat(index % 4 + 1) / 5, 
                  y: screenSize.height * CGFloat(index / 2 + 1) / 5)
        .offset(offset)
        .opacity(opacity)
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(.easeInOut(duration: Double.random(in: 3...6)).repeatForever(autoreverses: true)) {
                offset = CGSize(
                    width: CGFloat.random(in: -30...30),
                    height: CGFloat.random(in: -40...40)
                )
            }
            withAnimation(.easeIn(duration: 1)) {
                opacity = Double.random(in: 0.3...0.6)
            }
            withAnimation(.linear(duration: Double.random(in: 20...40)).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}


