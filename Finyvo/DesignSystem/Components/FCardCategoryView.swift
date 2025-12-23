//
//  FCardCategoryView.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/13/25.
//
//  Card de categoría premium con diseño de doble capa.
//  VARIANTE NEUTRA: Inner card sin color, solo el icono conserva el color.
//

import SwiftUI

// MARK: - Card Data Model

/// Modelo de datos para el card
struct FCardData {
    let name: String
    let icon: FCategoryIcon
    let color: FCardColor
    let budget: Double?
    let spent: Double
    let isFavorite: Bool
    let transactionCount: Int
    
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
}

// MARK: - Main Card Component

/// Card de categoría con diseño de doble capa - VARIANTE NEUTRA
struct FCardCategoryView: View {
    let data: FCardData
    
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Design Constants
    
    private let containerPadding: CGFloat = 6
    private let containerRadius: CGFloat = 22
    private let innerCardRadius: CGFloat = 16
    private let iconBadgeSize: CGFloat = 40
    private let iconSize: CGFloat = 18
    private let innerPadding: CGFloat = 14
    
    // MARK: - Colors
    
    private var containerColor: Color {
        colorScheme == .dark ? FColors.containerDark : FColors.containerLight
    }
    
    private var containerSecondaryColor: Color {
        colorScheme == .dark ? FColors.containerSecondaryDark : FColors.containerSecondaryLight
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            innerCard
            
            bottomSection
                .padding(.horizontal, innerPadding)
                .padding(.bottom, 10)
                .padding(.top, 6)
        }
        .background(containerBackground)
        .clipShape(RoundedRectangle(cornerRadius: containerRadius, style: .continuous))
        .overlay(containerBorder)
        .shadow(
            color: colorScheme == .dark
                ? Color.black.opacity(0.4)
                : Color.black.opacity(0.08),
            radius: 12,
            x: 0,
            y: 6
        )
    }
    
    // MARK: - Container Background
    
    private var containerBackground: some View {
        ZStack {
            containerColor
            
            LinearGradient(
                colors: [containerSecondaryColor.opacity(0.5), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack {
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.03 : 0.5),
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
    
    // MARK: - Container Border
    
    private var containerBorder: some View {
        RoundedRectangle(cornerRadius: containerRadius, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.08 : 0.8),
                        Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
    
    // MARK: - Inner Card
    
    private var innerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerRow
            Spacer(minLength: 2)
            footerRow
        }
        .padding(innerPadding)
        .background(innerCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: innerCardRadius, style: .continuous))
        .overlay(innerCardBorder)
        .padding(containerPadding)
    }
    
    // MARK: - Inner Card Background (NEUTRAL VERSION)
    
    /// Versión neutra: usa colores del sistema en lugar del color de categoría
    /// Similar al estilo del empty state de archivados
    private var innerCardBackground: some View {
        ZStack {
            // Base neutra
            colorScheme == .dark
                ? FColors.backgroundSecondary
                : Color(white: 0.97)
            
            // Gradiente sutil para profundidad - estilo empty state
            LinearGradient(
                colors: [
                    colorScheme == .dark
                        ? Color.white.opacity(0.04)
                        : Color.white.opacity(0.9),
                    colorScheme == .dark
                        ? Color.white.opacity(0.01)
                        : Color.white.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // MARK: - Inner Card Border (NEUTRAL VERSION)
    
    /// Borde neutro que complementa el fondo - similar al empty state
    private var innerCardBorder: some View {
        RoundedRectangle(cornerRadius: innerCardRadius, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        colorScheme == .dark
                            ? Color.white.opacity(0.10)
                            : Color.black.opacity(0.06),
                        colorScheme == .dark
                            ? Color.white.opacity(0.03)
                            : Color.black.opacity(0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
    
    // MARK: - Header Row
    
    private var headerRow: some View {
        HStack(alignment: .top) {
            iconBadge
            Spacer()
            if data.isFavorite {
                favoriteIndicator
            }
        }
    }
    
    // MARK: - Icon Badge (mantiene el color!)
    
    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(Circle().fill(data.color.color.opacity(0.2)))
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.2 : 0.6),
                                    Color.white.opacity(colorScheme == .dark ? 0.05 : 0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            
            Image(systemName: data.icon.systemName)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(data.color.color)
        }
        .frame(width: iconBadgeSize, height: iconBadgeSize)
        .shadow(color: data.color.color.opacity(0.35), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Favorite Indicator
    
    private var favoriteIndicator: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(Circle().stroke(Color.yellow.opacity(0.3), lineWidth: 1))
            
            Image(systemName: "star.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.yellow)
        }
        .frame(width: 24, height: 24)
    }
    
    // MARK: - Footer Row
    
    private var footerRow: some View {
        HStack(alignment: .bottom) {
            Text(data.name)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(data.color.textColor(for: colorScheme))
                .lineLimit(1)
            
            Spacer()
            
            if data.hasBudget {
                statusIndicator
            }
        }
    }
    
    // MARK: - Status Indicator
    
    private var statusIndicator: some View {
        HStack(spacing: 3) {
            Image(systemName: statusIcon)
                .font(.system(size: 9, weight: .bold))
            
            Text("\(data.progressPercentage)%")
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .foregroundStyle(statusColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(statusColor.opacity(0.15)))
    }
    
    private var statusIcon: String {
        if data.progress >= 0.9 { return "exclamationmark.triangle.fill" }
        if data.progress >= 0.75 { return "arrow.up.right" }
        return "checkmark"
    }
    
    private var statusColor: Color {
        if data.progress >= 0.9 { return FColors.red }
        if data.progress >= 0.75 { return FColors.yellow }
        return FColors.green
    }
    
    // MARK: - Bottom Section
    
    @ViewBuilder
    private var bottomSection: some View {
        if data.hasBudget {
            progressSection
        } else {
            transactionsSection
        }
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(colorScheme == .dark
                            ? Color.white.opacity(0.08)
                            : Color.black.opacity(0.06))
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [data.color.color, data.color.color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * data.progress)
                        .shadow(color: data.color.color.opacity(0.4), radius: 4, x: 0, y: 2)
                }
            }
            .frame(height: 6)
            
            HStack {
                Text("\(formatCurrency(data.spent)) de \(formatCompactCurrency(data.budget ?? 0))")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(colorScheme == .dark
                        ? Color.white.opacity(0.5)
                        : Color.black.opacity(0.45))
                
                Spacer()
                
                Text("Quedan \(formatCompactCurrency(data.remaining))")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(colorScheme == .dark
                        ? Color.white.opacity(0.7)
                        : Color.black.opacity(0.6))
            }
        }
    }
    
    // MARK: - Transactions Section
    
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 11, weight: .medium))
                
                Text("\(data.transactionCount) transacciones")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
            }
            .foregroundStyle(colorScheme == .dark
                ? Color.white.opacity(0.5)
                : Color.black.opacity(0.45))
            
            if data.spent > 0 {
                Text(formatCurrency(data.spent))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(colorScheme == .dark
                        ? Color.white.opacity(0.7)
                        : Color.black.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Currency Formatters
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "RD$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "RD$\(Int(value))"
    }
    
    private func formatCompactCurrency(_ value: Double) -> String {
        if value >= 1000 {
            return "RD$\(String(format: "%.1f", value / 1000))K"
        }
        return "RD$\(Int(value))"
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
        Color.white.ignoresSafeArea()
        
        FCardCategoryView(
            data: FCardData(
                name: "Transporte",
                icon: .transport,
                color: .blue,
                budget: 3000,
                spent: 2400,
                isFavorite: false,
                transactionCount: 8
            )
        )
        .frame(width: cardWidth)
    }
}
//
//#Preview("All Colors - Dark (Neutral Inner)") {
//    ScrollView {
//        LazyVGrid(
//            columns: [GridItem(.fixed(cardWidth)), GridItem(.fixed(cardWidth))],
//            spacing: 16
//        ) {
//            ForEach(FCardColor.allCases) { color in
//                FCardCategoryView(
//                    data: FCardData(
//                        name: color.displayName(for: colorScheme),
//                        icon: .other,
//                        color: color,
//                        budget: 5000,
//                        spent: Double.random(in: 1000...4500),
//                        isFavorite: color == .blue,
//                        transactionCount: Int.random(in: 3...20)
//                    )
//                )
//            }
//        }
//        .padding()
//    }
//    .background(Color.black)
//    .preferredColorScheme(.dark)
//}
//
//#Preview("All Colors - Light (Neutral Inner)") {
//    ScrollView {
//        LazyVGrid(
//            columns: [GridItem(.fixed(cardWidth)), GridItem(.fixed(cardWidth))],
//            spacing: 16
//        ) {
//            ForEach(FCardColor.allCases) { color in
//                FCardCategoryView(
//                    data: FCardData(
//                        name: color.displayName,
//                        icon: .other,
//                        color: color,
//                        budget: 5000,
//                        spent: Double.random(in: 1000...4500),
//                        isFavorite: color == .purple,
//                        transactionCount: Int.random(in: 3...20)
//                    )
//                )
//            }
//        }
//        .padding()
//    }
//    .background(Color.white)
//}

#Preview("With vs Without Budget") {
    HStack(spacing: 16) {
        FCardCategoryView(
            data: FCardData(
                name: "Sin presupuesto",
                icon: .shopping,
                color: .teal,
                budget: nil,
                spent: 2500,
                isFavorite: false,
                transactionCount: 8
            )
        )
        .frame(width: cardWidth)
        
        FCardCategoryView(
            data: FCardData(
                name: "Con presupuesto",
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
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("Progress States") {
    VStack(spacing: 16) {
        HStack(spacing: 16) {
            FCardCategoryView(
                data: FCardData(
                    name: "Bajo uso",
                    icon: .shopping,
                    color: .green,
                    budget: 5000,
                    spent: 1200,
                    isFavorite: false,
                    transactionCount: 3
                )
            )
            .frame(width: cardWidth)
            
            FCardCategoryView(
                data: FCardData(
                    name: "Uso medio",
                    icon: .entertainment,
                    color: .purple,
                    budget: 5000,
                    spent: 3800,
                    isFavorite: false,
                    transactionCount: 10
                )
            )
            .frame(width: cardWidth)
        }
        
        HStack(spacing: 16) {
            FCardCategoryView(
                data: FCardData(
                    name: "Casi límite",
                    icon: .food,
                    color: .yellow,
                    budget: 5000,
                    spent: 4200,
                    isFavorite: false,
                    transactionCount: 15
                )
            )
            .frame(width: cardWidth)
            
            FCardCategoryView(
                data: FCardData(
                    name: "Excedido",
                    icon: .transport,
                    color: .red,
                    budget: 5000,
                    spent: 5500,
                    isFavorite: true,
                    transactionCount: 20
                )
            )
            .frame(width: cardWidth)
        }
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("All Icons (Neutral)") {
    let icons: [(FCategoryIcon, String, FCardColor)] = [
        (.food, "Comida", .orange),
        (.transport, "Transporte", .blue),
        (.entertainment, "Ocio", .purple),
        (.shopping, "Compras", .pink),
        (.services, "Servicios", .yellow),
        (.health, "Salud", .red),
        (.education, "Educación", .teal),
        (.home, "Hogar", .orange),
        (.salary, "Salario", .green),
        (.investments, "Inversiones", .blue)
    ]
    
    ScrollView {
        LazyVGrid(
            columns: [GridItem(.fixed(cardWidth)), GridItem(.fixed(cardWidth))],
            spacing: 16
        ) {
            ForEach(icons, id: \.0.rawValue) { icon, name, color in
                FCardCategoryView(
                    data: FCardData(
                        name: name,
                        icon: icon,
                        color: color,
                        budget: Double.random(in: 2000...8000),
                        spent: Double.random(in: 500...6000),
                        isFavorite: Bool.random(),
                        transactionCount: Int.random(in: 1...25)
                    )
                )
            }
        }
        .padding()
    }
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("Light vs Dark Comparison (Neutral)") {
    HStack(spacing: 0) {
        ZStack {
            Color.white
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
            .frame(width: 160)
        }
        .environment(\.colorScheme, .light)
        
        ZStack {
            Color.black
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
            .frame(width: 160)
        }
        .environment(\.colorScheme, .dark)
    }
    .frame(height: 220)
}
