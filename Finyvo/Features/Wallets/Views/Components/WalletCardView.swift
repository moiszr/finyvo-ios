//
//  WalletCardView.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/24/25.
//  Tarjeta visual premium estilo Apple Wallet.
//

import SwiftUI

// MARK: - Wallet Card View

/// Tarjeta visual de billetera con diseño premium.
///
/// ## Características
/// - Diseño de tarjeta física abstracta
/// - Gradientes y glassmorphism
/// - Animaciones suaves
/// - Soporte para light/dark mode
struct WalletCardView: View {
    
    // MARK: - Properties
    
    let wallet: Wallet
    var isExpanded: Bool = false
    var showFullDetails: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Design Constants
    
    private let cardAspectRatio: CGFloat = 1.586 // Proporción tarjeta de crédito estándar
    private let cornerRadius: CGFloat = 20
    private let expandedCornerRadius: CGFloat = 28
    private let liveTextAnimation: Animation = .spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.15)
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            let cardHeight = geometry.size.width / cardAspectRatio
            
            ZStack {
                // Fondo con gradiente
                cardBackground
                
                // Contenido de la tarjeta
                cardContent
                    .padding(20)
            }
            .frame(width: geometry.size.width, height: isExpanded ? nil : cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: isExpanded ? expandedCornerRadius : cornerRadius, style: .continuous))
            .overlay(cardBorder)
            .shadow(
                color: wallet.color.color.opacity(colorScheme == .dark ? 0.3 : 0.2),
                radius: isExpanded ? 20 : 12,
                x: 0,
                y: isExpanded ? 10 : 6
            )
        }
        .aspectRatio(cardAspectRatio, contentMode: .fit)
    }
    
    // MARK: - Card Background
    
    private var cardBackground: some View {
        ZStack {
            // Base color
            wallet.color.color
            
            // Gradiente principal
            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.15 : 0.25),
                    Color.clear,
                    Color.black.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Patrón decorativo sutil
            cardPattern
            
            // Brillo superior
            VStack {
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.1 : 0.2),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 60)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Card Pattern
    
    private var cardPattern: some View {
        GeometryReader { geo in
            // Círculos decorativos estilo tarjeta premium
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: geo.size.width * 0.8)
                    .offset(x: geo.size.width * 0.4, y: -geo.size.height * 0.3)
                
                Circle()
                    .fill(Color.black.opacity(0.05))
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: -geo.size.width * 0.3, y: geo.size.height * 0.4)
            }
        }
    }
    
    // MARK: - Card Content
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: Icono y tipo
            HStack(alignment: .top) {
                // Icono de la billetera
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: wallet.systemImageName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(contentColor)
                }
                
                Spacer()
                
                // Badge de tipo
                Text(wallet.type.shortTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(contentColor.opacity(0.8))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                    )
            }
            
            Spacer()
            
            // Balance
            VStack(alignment: .leading, spacing: 4) {
                Text("Balance")
                    .font(.caption)
                    .foregroundStyle(contentColor.opacity(0.7))
                
                Text(wallet.formattedBalance)
                    .font(.system(size: isExpanded ? 32 : 26, weight: .bold, design: .rounded))
                    .foregroundStyle(contentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .transaction { tx in
                        tx.animation = liveTextAnimation
                    }
            }
            
            Spacer()
            
            // Footer: Nombre y moneda
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    if let lastFour = wallet.lastFourDigits, !lastFour.isEmpty {
                        HStack(spacing: 4) {
                            Text("••••")
                                .font(.caption.monospaced())
                                .foregroundStyle(contentColor.opacity(0.6))

                            Text(lastFour)
                                .font(.caption.monospaced())
                                .foregroundStyle(contentColor.opacity(0.6))
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .transaction { tx in
                                    tx.animation = liveTextAnimation
                                }
                        }
                    }
                    
                    Text(wallet.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(contentColor)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Moneda con bandera
                if let currency = wallet.currency {
                    HStack(spacing: 4) {
                        Text(currency.flag)
                            .font(.caption)
                        Text(currency.code)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(contentColor.opacity(0.8))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                    )
                }
            }
        }
    }
    
    // MARK: - Card Border
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: isExpanded ? expandedCornerRadius : cornerRadius, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.3 : 0.5),
                        Color.white.opacity(0.1),
                        Color.black.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
    
    // MARK: - Helpers
    
    private var contentColor: Color {
        wallet.color.contrastContentColor(for: colorScheme)
    }
}

// MARK: - Compact Wallet Card

/// Versión compacta de la tarjeta para listas.
struct WalletCardCompact: View {
    let wallet: Wallet
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Icono con color
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(wallet.color.color)
                    .frame(width: 48, height: 48)
                
                Image(systemName: wallet.systemImageName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(wallet.color.contrastContentColor(for: colorScheme))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(wallet.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(FColors.textPrimary)
                
                Text(wallet.type.shortTitle)
                    .font(.caption)
                    .foregroundStyle(FColors.textSecondary)
            }
            
            Spacer()
            
            // Balance
            VStack(alignment: .trailing, spacing: 4) {
                Text(wallet.formattedBalanceCompact)
                    .font(.body.weight(.bold))
                    .foregroundStyle(wallet.isNegativeBalance ? FColors.red : FColors.textPrimary)
                
                if let currency = wallet.currency {
                    Text(currency.code)
                        .font(.caption)
                        .foregroundStyle(FColors.textTertiary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? FColors.backgroundSecondary : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Mini Wallet Card (Para selección)

/// Versión mini de la tarjeta para pickers.
struct WalletCardMini: View {
    let wallet: Wallet
    var isSelected: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Mini tarjeta visual
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(wallet.color.color)
                    .frame(width: 32, height: 20)
                
                // Patrón decorativo mini
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 3, height: 3)
                    }
                }
            }
            
            Text(wallet.name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(FColors.textPrimary)
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.body)
                    .foregroundStyle(FColors.brand)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? FColors.brand.opacity(0.1) : Color.clear)
        )
    }
}

// MARK: - Previews

#Preview("Wallet Card") {
    VStack(spacing: 20) {
        WalletCardView(
            wallet: Wallet(
                name: "Banco Popular",
                type: .checking,
                color: .blue,
                currencyCode: "DOP",
                initialBalance: 45000,
                lastFourDigits: "4532"
            )
        )
        .frame(width: 320)
        
        WalletCardView(
            wallet: Wallet(
                name: "Tarjeta de Crédito",
                type: .creditCard,
                color: .purple,
                currencyCode: "USD",
                initialBalance: -1250.50
            )
        )
        .frame(width: 320)
    }
    .padding()
    .background(FColors.background)
}

#Preview("Wallet Card - Dark") {
    VStack(spacing: 20) {
        WalletCardView(
            wallet: Wallet(
                name: "Efectivo",
                type: .cash,
                color: .green,
                currencyCode: "DOP",
                initialBalance: 5000
            )
        )
        .frame(width: 320)
        
        WalletCardView(
            wallet: Wallet(
                name: "PayPal",
                type: .digitalWallet,
                color: .orange,
                currencyCode: "USD",
                initialBalance: 320.75
            )
        )
        .frame(width: 320)
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("Compact Cards") {
    VStack(spacing: 12) {
        WalletCardCompact(
            wallet: Wallet(
                name: "Banco Popular",
                type: .checking,
                color: .blue,
                initialBalance: 45000
            )
        )
        
        WalletCardCompact(
            wallet: Wallet(
                name: "Tarjeta AMEX",
                type: .creditCard,
                color: .purple,
                initialBalance: -1250.50
            )
        )
    }
    .padding()
    .background(FColors.background)
}
