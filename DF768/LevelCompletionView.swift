//
//  LevelCompletionView.swift
//  DF768
//

import SwiftUI

struct LevelCompletionView: View {
    let won: Bool
    let score: Int
    let rewardName: String
    let rewardAmount: Int
    let onContinue: () -> Void
    
    @State private var isAnimating = false
    @State private var showRewards = false
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.deepMidnightBlue.opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                Spacer()
                
                // Result icon
                resultIcon
                
                // Result text
                VStack(spacing: 10) {
                    Text(won ? "Challenge Complete!" : "Keep Practicing")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    
                    Text("Score: \(score)")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(.brightCyan)
                }
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: isAnimating)
                
                // Rewards
                if won && showRewards {
                    rewardsSection
                }
                
                Spacer()
                
                // Continue button
                Button(action: onContinue) {
                    Text("Continue")
                        .primaryButtonStyle()
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
                .opacity(isAnimating ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.5), value: isAnimating)
            }
        }
        .onAppear {
            withAnimation { isAnimating = true }
            
            if won {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.spring(response: 0.5)) {
                        showRewards = true
                    }
                }
            }
        }
    }
    
    private var resultIcon: some View {
        ZStack {
            // Outer rings for success
            if won {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(Color.softMint.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                        .frame(width: 130 + CGFloat(index) * 20, height: 130 + CGFloat(index) * 20)
                        .scaleEffect(isAnimating ? 1.1 : 0.9)
                        .opacity(isAnimating ? 0.6 : 1)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                            value: isAnimating
                        )
                }
            }
            
            Circle()
                .fill(won ? Color.softMint.opacity(0.2) : Color.red.opacity(0.2))
                .frame(width: 120, height: 120)
            
            Image(systemName: won ? "checkmark.circle.fill" : "arrow.clockwise.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(won ? .softMint : .red.opacity(0.8))
        }
        .scaleEffect(isAnimating ? 1 : 0.5)
        .opacity(isAnimating ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isAnimating)
    }
    
    private var rewardsSection: some View {
        VStack(spacing: 16) {
            Text("Rewards Earned")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.textSecondary)
            
            HStack(spacing: 24) {
                // Animated reward icons
                ForEach(0..<min(rewardAmount, 5), id: \.self) { index in
                    Image(systemName: rewardIcon)
                        .font(.system(size: 28))
                        .foregroundColor(.softMint)
                        .rotationEffect(.degrees(showRewards ? 0 : -180))
                        .scaleEffect(showRewards ? 1 : 0)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.6)
                            .delay(Double(index) * 0.1),
                            value: showRewards
                        )
                        .glowEffect(color: .softMint, radius: 8)
                }
            }
            
            HStack(spacing: 6) {
                Text("+\(rewardAmount)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.softMint)
                Text(rewardName)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.darkSlate)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.softMint.opacity(0.3), lineWidth: 1)
                )
        )
        .transition(.scale.combined(with: .opacity))
    }
    
    private var rewardIcon: String {
        switch rewardName {
        case "Pattern Fragments": return "square.grid.3x3.fill"
        case "Energy Marks": return "bolt.fill"
        case "Stability Points": return "circle.hexagongrid.fill"
        default: return "star.fill"
        }
    }
}

#Preview {
    LevelCompletionView(
        won: true,
        score: 350,
        rewardName: "Pattern Fragments",
        rewardAmount: 15,
        onContinue: {}
    )
}

