//
//  StatisticsSettingsView.swift
//  DF768
//

import SwiftUI

struct StatisticsSettingsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var gameManager = GameManager.shared
    @State private var showResetConfirmation = false
    @State private var isAnimating = false
    @State private var resetComplete = false
    
    var body: some View {
        ZStack {
            // Background
            HubBackground()
                .allowsHitTesting(false)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Statistics Section
                    statisticsSection
                    
                    // Game Progress Section
                    gameProgressSection
                    
                    // Settings Section
                    settingsSection
                    
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 20)
            }
            
            // Reset confirmation modal
            if showResetConfirmation {
                ResetConfirmationModal(
                    onConfirm: {
                        performReset()
                    },
                    onCancel: {
                        withAnimation(.spring(response: 0.3)) {
                            showResetConfirmation = false
                        }
                    }
                )
            }
            
            // Reset complete notification
            if resetComplete {
                ResetCompleteNotification()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation { isAnimating = true }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                }
                .foregroundColor(.brightCyan)
            }
            
            Spacer()
        }
        .padding(.top, 16)
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Progress")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 14) {
                StatCard(
                    icon: "play.circle.fill",
                    value: "\(gameManager.statistics.totalSessionsPlayed)",
                    label: "Sessions Played",
                    color: .brightCyan
                )
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: isAnimating)
                
                StatCard(
                    icon: "checkmark.circle.fill",
                    value: "\(gameManager.statistics.levelsCompleted)",
                    label: "Levels Completed",
                    color: .softMint
                )
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.15), value: isAnimating)
                
                StatCard(
                    icon: "target",
                    value: "\(Int(gameManager.statistics.averageAccuracy))%",
                    label: "Accuracy",
                    color: .brightCyan
                )
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: isAnimating)
                
                StatCard(
                    icon: "clock.fill",
                    value: gameManager.statistics.formattedTimeSpent,
                    label: "Time Spent",
                    color: .softMint
                )
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.25), value: isAnimating)
            }
        }
        .padding(.top, 10)
    }
    
    // MARK: - Game Progress Section
    private var gameProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rewards Collected")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            
            HStack(spacing: 12) {
                RewardCard(
                    icon: "square.grid.3x3.fill",
                    value: gameManager.statistics.patternFragments,
                    label: "Pattern Fragments",
                    color: .brightCyan
                )
                
                RewardCard(
                    icon: "bolt.fill",
                    value: gameManager.statistics.energyMarks,
                    label: "Energy Marks",
                    color: .softMint
                )
                
                RewardCard(
                    icon: "circle.hexagongrid.fill",
                    value: gameManager.statistics.stabilityPoints,
                    label: "Stability Points",
                    color: Color(red: 0.5, green: 0.7, blue: 1.0)
                )
            }
        }
        .opacity(isAnimating ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.3), value: isAnimating)
    }
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    showResetConfirmation = true
                }
            }) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Reset Progress")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        
                        Text("Clear all saved data")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red.opacity(0.6))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.darkSlate)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.red.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .opacity(isAnimating ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.4), value: isAnimating)
    }
    
    private func performReset() {
        gameManager.resetAllProgress()
        
        withAnimation(.spring(response: 0.3)) {
            showResetConfirmation = false
            resetComplete = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring(response: 0.3)) {
                resetComplete = false
            }
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 46, height: 46)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.darkSlate)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

// MARK: - Reward Card
struct RewardCard: View {
    let icon: String
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text("\(value)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.darkSlate)
        )
    }
}

// MARK: - Reset Confirmation Modal
struct ResetConfirmationModal: View {
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.red)
                }
                .scaleEffect(isAnimating ? 1 : 0.5)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isAnimating)
                
                VStack(spacing: 10) {
                    Text("Reset All Progress?")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    
                    Text("This will permanently delete all your saved data, including completed levels and collected rewards. This action cannot be undone.")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 10)
                }
                
                VStack(spacing: 12) {
                    Button(action: onConfirm) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Reset Everything")
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                    
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.darkSlate)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.deepMidnightBlue)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 30)
            .opacity(isAnimating ? 1 : 0)
            .scaleEffect(isAnimating ? 1 : 0.9)
            .animation(.spring(response: 0.3), value: isAnimating)
        }
        .onAppear {
            withAnimation { isAnimating = true }
        }
    }
}

// MARK: - Reset Complete Notification
struct ResetCompleteNotification: View {
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.softMint)
                
                Text("Progress reset successfully")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.textPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.darkSlate)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.softMint.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 10)
            )
            .padding(.top, 60)
            
            Spacer()
        }
    }
}

#Preview {
    StatisticsSettingsView()
}

