//
//  WalletFlowComponents.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/29/25.
//  Componentes compartidos para el flujo de billeteras.
//

import SwiftUI

// MARK: - Flow Input Card

/// Card contenedor premium para inputs y contenido en flujos.
/// Usa glassmorphism sutil y bordes suaves.
struct FlowInputCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(FSpacing.lg)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: FRadius.lg, style: .continuous))
            .overlay(cardBorder)
    }
    
    private var cardBackground: some View {
        ZStack {
            // Base
            colorScheme == .dark
                ? FColors.backgroundSecondary
                : Color.white
            
            // Subtle gradient overlay
            LinearGradient(
                colors: [
                    colorScheme == .dark ? Color.white.opacity(0.03) : Color.white.opacity(0.8),
                    colorScheme == .dark ? Color.white.opacity(0.01) : Color.white.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: FRadius.lg, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05),
                        colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}

// MARK: - Flow Scale Button Style

struct FlowScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Components") {
    ScrollView {
        VStack(spacing: FSpacing.xl) {
            FlowInputCard {
                VStack(alignment: .leading, spacing: FSpacing.md) {
                    Text("Content goes here")
                        .foregroundStyle(FColors.textSecondary)
                }
            }

        }
        .padding()
    }
    .background(FColors.background)
}
