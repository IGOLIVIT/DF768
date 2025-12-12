//
//  SettingsView.swift
//  DF768
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var gameManager = GameManager.shared
    @State private var showResetConfirmation = false
    @State private var showStatistics = false
    @State private var isAnimating = false
    @State private var resetComplete = false
    
    var body: some View {
        ZStack {
            // Background
            AnimatedMenuBackground()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.primaryAccent)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Title
                    VStack(spacing: 8) {
                        Text("Settings")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        
                        Text("Configure your experience")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(.textPrimary.opacity(0.6))
                    }
                    .padding(.top, 10)
                    
                    // Settings options
                    VStack(spacing: 16) {
                        // View Statistics
                        SettingsButton(
                            icon: "chart.bar.fill",
                            title: "View Statistics",
                            subtitle: "Check your progress and achievements",
                            color: .secondaryAccent
                        ) {
                            showStatistics = true
                        }
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                        .animation(.spring(response: 0.5).delay(0.1), value: isAnimating)
                        
                        // Reset Progress
                        SettingsButton(
                            icon: "arrow.counterclockwise",
                            title: "Reset Progress",
                            subtitle: "Clear all saved data and start fresh",
                            color: .red
                        ) {
                            showResetConfirmation = true
                        }
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                        .animation(.spring(response: 0.5).delay(0.2), value: isAnimating)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Info section
                    VStack(spacing: 16) {
                        Divider()
                            .background(Color.textPrimary.opacity(0.2))
                            .padding(.horizontal, 20)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.textPrimary)
                            
                            Text("Explore abstract trails filled with unique challenges. Progress through levels, collect luminous fragments, and master each pathway.")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.textPrimary.opacity(0.7))
                                .lineSpacing(4)
                            
                            HStack(spacing: 16) {
                                InfoPill(icon: "sparkles", text: "3 Trails")
                                InfoPill(icon: "square.stack.fill", text: "9 Levels")
                                InfoPill(icon: "slider.horizontal.3", text: "3 Difficulties")
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    .opacity(isAnimating ? 1 : 0)
                    .animation(.spring(response: 0.5).delay(0.3), value: isAnimating)
                    
                    // Version info
                    VStack(spacing: 4) {
                        Text("Version 1.0.0")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.textPrimary.opacity(0.4))
                        
                        Text("Made with ♥")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.textPrimary.opacity(0.3))
                    }
                    .padding(.top, 40)
                    
                    Spacer()
                        .frame(height: 40)
                }
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
        .navigationDestination(isPresented: $showStatistics) {
            StatisticsView()
        }
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
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

// MARK: - Settings Button
struct SettingsButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(color)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.textPrimary.opacity(0.6))
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color.opacity(0.6))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.primaryBackground.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Info Pill
struct InfoPill: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.primaryAccent)
            
            Text(text)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.textPrimary.opacity(0.7))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.primaryAccent.opacity(0.1))
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
            // Backdrop
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            // Modal content
            VStack(spacing: 24) {
                // Warning icon
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
                
                VStack(spacing: 12) {
                    Text("Reset All Progress?")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    
                    Text("This will permanently delete all your saved data, including completed levels, fragments, and statistics. This action cannot be undone.")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.textPrimary.opacity(0.7))
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
                            .foregroundColor(.textPrimary.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.textPrimary.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.primaryBackground)
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
            withAnimation {
                isAnimating = true
            }
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
                    .foregroundColor(.secondaryAccent)
                
                Text("Progress reset successfully")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.textPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.primaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.secondaryAccent.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 10)
            )
            .padding(.top, 60)
            
            Spacer()
        }
    }
}

#Preview {
    SettingsView()
}

