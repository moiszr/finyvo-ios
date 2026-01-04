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

// MARK: - Flow Cell Button Style

/// Estilo de botón con escala sutil para celdas interactivas.
struct FlowCellButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Flow Scale Button Style

// Estilo de botón con escala más pronunciada.
//struct FlowScaleButtonStyle: ButtonStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .scaleEffect(configuration.isPressed ? 0.96 : 1)
//            .opacity(configuration.isPressed ? 0.9 : 1)
//            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
//    }
//}
struct FlowScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Section Header

/// Header reutilizable para secciones en formularios.
struct FlowSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var iconColor: Color = FColors.brand
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: FSpacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(iconColor)
                }
                
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(FColors.textPrimary)
            }
            
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(FColors.textTertiary)
            }
        }
    }
}

// MARK: - Empty Search State

/// Estado vacío para búsquedas sin resultados.
struct FlowEmptySearchState: View {
    var message: String = "No se encontraron resultados"
    var hint: String? = "Intenta con otro término"
    
    var body: some View {
        VStack(spacing: FSpacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(FColors.textTertiary)
            
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(FColors.textSecondary)
            
            if let hint {
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(FColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FSpacing.xxl)
    }
}

// MARK: - Animated Check

/// Checkmark animado para selecciones.
struct AnimatedCheck: View {
    var isSelected: Bool
    var color: Color = FColors.brand
    var size: CGFloat = 20
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? color : Color.clear)
                .frame(width: size, height: size)
            
            Circle()
                .stroke(isSelected ? color : FColors.textTertiary.opacity(0.3), lineWidth: 1.5)
                .frame(width: size, height: size)
            
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundStyle(.white)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Glow Background

/// Fondo con efecto glow animado.
struct GlowBackground: View {
    var color: Color
    var intensity: Double = 0.3
    var radius: CGFloat = 200
    var offset: CGPoint = .zero
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        color.opacity(colorScheme == .dark ? intensity : intensity * 0.6),
                        color.opacity(colorScheme == .dark ? intensity * 0.3 : intensity * 0.15),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 30,
                    endRadius: radius
                )
            )
            .frame(width: radius * 2, height: radius * 2)
            .offset(x: offset.x, y: offset.y)
            .blur(radius: radius * 0.3)
    }
}

// MARK: - Preview

#Preview("Components") {
    ScrollView {
        VStack(spacing: FSpacing.xl) {
            FlowInputCard {
                VStack(alignment: .leading, spacing: FSpacing.md) {
                    FlowSectionHeader(
                        title: "Nombre",
                        subtitle: "¿Cómo quieres llamar tu billetera?",
                        icon: "pencil"
                    )
                    
                    Text("Content goes here")
                        .foregroundStyle(FColors.textSecondary)
                }
            }
            
            HStack(spacing: FSpacing.md) {
                AnimatedCheck(isSelected: true)
                AnimatedCheck(isSelected: false)
                AnimatedCheck(isSelected: true, color: .purple)
            }
            
            FlowEmptySearchState()
        }
        .padding()
    }
    .background(FColors.background)
}
