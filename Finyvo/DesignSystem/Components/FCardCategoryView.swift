//
//  FCardCategoryView.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/13/25.
//
//  Card de categoría premium con diseño neutro (estilo Editor).
//  Solo el icono y la barra de progreso aportan color.
//  Integrated with CurrencyConfig for proper formatting.
//

import SwiftUI

// MARK: - Card Data Model

struct FCardData {
    let name: String
    let icon: FCategoryIcon
    let color: FCardColor
    let budget: Double?
    let spent: Double
    let isFavorite: Bool
    let transactionCount: Int
    
    /// Código de moneda para formateo (usa default de AppConfig si nil)
    var currencyCode: String?
    
    // MARK: - Computed Properties
    
    var hasBudget: Bool {
        guard let budget else { return false }
        return budget > 0
    }
    
    var progress: Double {
        guard let budget, budget > 0 else { return 0 }
        return min(spent / budget, 1.0)
    }
    
    var progressPercentage: Int {
        Int(progress * 100)
    }
    
    var remaining: Double {
        guard let budget else { return 0 }
        return max(budget - spent, 0)
    }
    
    /// `true` si el progreso supera el umbral de alerta
    var isOverBudgetAlert: Bool {
        progress >= AppConfig.Defaults.budgetAlertPercentage
    }
    
    // MARK: - Formatted Values
    
    /// Monto gastado formateado
    var formattedSpent: String {
        spent.asCurrency(code: currencyCode)
    }
    
    /// Monto gastado compacto
    var formattedSpentCompact: String {
        spent.asCompactCurrency(code: currencyCode)
    }
    
    /// Presupuesto formateado
    var formattedBudget: String {
        guard let budget else { return "" }
        return budget.asCurrency(code: currencyCode)
    }
    
    /// Presupuesto compacto
    var formattedBudgetCompact: String {
        guard let budget else { return "" }
        return budget.asCompactCurrency(code: currencyCode)
    }
    
    /// Restante formateado
    var formattedRemaining: String {
        remaining.asCurrency(code: currencyCode)
    }
    
    /// Restante compacto
    var formattedRemainingCompact: String {
        remaining.asCompactCurrency(code: currencyCode)
    }
    
    // MARK: - Initializer
    
    init(
        name: String,
        icon: FCategoryIcon,
        color: FCardColor,
        budget: Double?,
        spent: Double,
        isFavorite: Bool,
        transactionCount: Int,
        currencyCode: String? = nil
    ) {
        self.name = name
        self.icon = icon
        self.color = color
        self.budget = budget
        self.spent = spent
        self.isFavorite = isFavorite
        self.transactionCount = transactionCount
        self.currencyCode = currencyCode
    }
}

// MARK: - Main Card Component

struct FCardCategoryView: View {
    let data: FCardData
    
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Design Constants
    
    private let cardRadius: CGFloat = 24
    private let padding: CGFloat = 16
    private let iconSize: CGFloat = 20
    private let iconBadgeSize: CGFloat = 44
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // 1. Header (Icono y Favorito)
            HStack(alignment: .top) {
                iconBadge
                Spacer()
                if data.isFavorite {
                    favoriteIndicator
                }
            }
            .padding(.bottom, 12)
            
            // 2. Nombre Categoría
            Text(data.name)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(FColors.textPrimary)
                .lineLimit(1)
                .padding(.bottom, 4)
            
            // 3. Info Transacciones (Si no hay presupuesto)
            if !data.hasBudget {
                Text("\(data.transactionCount) transacciones")
                    .font(.caption)
                    .foregroundStyle(FColors.textSecondary)
            }
            
            Spacer(minLength: 12)
            
            // 4. Sección Inferior
            bottomSection
        }
        .padding(padding)
        .background(neutralBackground)
        .clipShape(RoundedRectangle(cornerRadius: cardRadius, style: .continuous))
        .overlay(neutralBorder)
        // Sombra suave neutra (elevación física)
        .shadow(
            color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.05),
            radius: 10,
            x: 0,
            y: 5
        )
    }
    
    // MARK: - Neutral Background & Border (Igual que el Editor)
    
    private var neutralBackground: some View {
        ZStack {
            // Fondo base neutro
            (colorScheme == .dark ? FColors.backgroundSecondary : Color(white: 0.98))
            
            // Gradiente sutil de "papel/superficie" para dar volumen
            LinearGradient(
                colors: [
                    colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.9),
                    colorScheme == .dark ? Color.white.opacity(0.01) : Color.white.opacity(0.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var neutralBorder: some View {
        RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        // Borde superior con luz
                        colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06),
                        // Borde inferior con sombra
                        colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
    
    // MARK: - Icon Badge (Con toque de color)
    
    private var iconBadge: some View {
        ZStack {
            // Fondo suave tintado con el color de la categoría
            Circle()
                .fill(data.color.color.opacity(colorScheme == .dark ? 0.2 : 0.12))
            
            // Borde sutil del color para definir
            Circle()
                .stroke(data.color.color.opacity(0.3), lineWidth: 1)
            
            // Icono vibrante
            Image(systemName: data.icon.systemName)
                .font(.system(size: iconSize, weight: .semibold))
                // Usamos el color directo porque el fondo es suave
                .foregroundStyle(data.color.color)
        }
        .frame(width: iconBadgeSize, height: iconBadgeSize)
    }
    
    // MARK: - Favorite Indicator
    
    private var favoriteIndicator: some View {
        Image(systemName: "star.fill")
            .font(.system(size: 12))
            .foregroundStyle(FColors.yellow)
            .padding(6)
            .background(
                Circle()
                    .fill(FColors.yellow.opacity(0.15))
            )
    }
    
    // MARK: - Bottom Section Logic
    
    @ViewBuilder
    private var bottomSection: some View {
        if data.hasBudget {
            progressSection
        } else {
            // Si no hay presupuesto, mostramos el total gastado grande
            if data.spent > 0 {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total gastado")
                        .font(.caption2)
                        .foregroundStyle(FColors.textTertiary)
                    
                    Text(data.formattedSpent)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(FColors.textPrimary)
                }
            } else {
                Text("Sin movimientos")
                    .font(.caption)
                    .foregroundStyle(FColors.textTertiary)
                    .frame(height: 36, alignment: .bottom)
            }
        }
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: 8) {
            // Barra de progreso
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track (Fondo de la barra - Neutro)
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                    
                    // Fill (Relleno - Con Color Vibrante)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [data.color.color, data.color.color.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: min(geo.size.width * data.progress, geo.size.width))
                        // Sombra del color para efecto neón/brillo
                        .shadow(color: data.color.color.opacity(0.3), radius: 2, x: 0, y: 1)
                }
            }
            .frame(height: 6) // Fina y elegante
            
            // Textos de Presupuesto
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(data.formattedSpentCompact)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(FColors.textPrimary)
                    
                    Text("de \(data.formattedBudgetCompact)")
                        .font(.caption2)
                        .foregroundStyle(FColors.textTertiary)
                }
                
                Spacer()
                
                // Porcentaje o Alerta
                if data.progress >= 1.0 {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(FColors.red)
                        .font(.caption)
                } else {
                    Text("\(data.progressPercentage)%")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        // El porcentaje mantiene el color para conectar visualmente con la barra
                        .foregroundStyle(data.color.color)
                }
            }
        }
    }
}

// MARK: - Previews

private let cardWidth: CGFloat = 170

#Preview("Single Card - Dark") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        FCardCategoryView(
            data: FCardData(
                name: "Comida",
                icon: .food,
                color: .orange,
                budget: 5000,
                spent: 3200,
                isFavorite: true,
                transactionCount: 12
            )
        )
        .frame(width: cardWidth)
    }
    .preferredColorScheme(.dark)
}

#Preview("Single Card - Light") {
    ZStack {
        FColors.background.ignoresSafeArea()
        
        FCardCategoryView(
            data: FCardData(
                name: "Transporte",
                icon: .transport,
                color: .blue,
                budget: 3000,
                spent: 1200,
                isFavorite: false,
                transactionCount: 8
            )
        )
        .frame(width: cardWidth)
    }
    .preferredColorScheme(.light)
}

#Preview("Grid - Light") {
    ScrollView {
        LazyVGrid(
            columns: [GridItem(.fixed(cardWidth)), GridItem(.fixed(cardWidth))],
            spacing: 16
        ) {
            FCardCategoryView(
                data: FCardData(
                    name: "Entretenimiento",
                    icon: .entertainment,
                    color: .purple,
                    budget: 5000,
                    spent: 4500,
                    isFavorite: false,
                    transactionCount: 5
                )
            )
            
            FCardCategoryView(
                data: FCardData(
                    name: "Salud",
                    icon: .health,
                    color: .red,
                    budget: nil,
                    spent: 1500,
                    isFavorite: false,
                    transactionCount: 2
                )
            )
            
            FCardCategoryView(
                data: FCardData(
                    name: "Freelance",
                    icon: .freelance,
                    color: .teal,
                    budget: nil,
                    spent: 8500,
                    isFavorite: true,
                    transactionCount: 4
                )
            )
            
            FCardCategoryView(
                data: FCardData(
                    name: "Hogar",
                    icon: .home,
                    color: .yellow,
                    budget: 10000,
                    spent: 10000,
                    isFavorite: false,
                    transactionCount: 8
                )
            )
        }
        .padding()
    }
    .background(FColors.background)
}
