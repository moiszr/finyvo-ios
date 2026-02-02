//
//  TransactionSummaryCard.swift
//  Finyvo
//
//  Created by Moises Núñez on 01/15/26.
//  Updated on 01/30/26 - Liquid Glass (iOS 26+), material fallback for earlier
//
//  Financial summary card with adaptive glass design.
//
//  Architecture:
//    - iOS 26+: Native Liquid Glass API
//    - iOS < 26: UltraThinMaterial fallback
//    - Semantic colors for automatic light/dark adaptation
//    - Pure computed properties, no side effects
//

import SwiftUI

// MARK: - Transaction Summary Card

struct TransactionSummaryCard: View {
    
    // MARK: - Properties
    
    let statistics: TransactionStatistics
    var currencyCode: String = AppConfig.Defaults.currencyCode
    var periodTitle: String = "Este mes"
    var onIncomeTap: (() -> Void)?
    var onExpenseTap: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            periodHeaderView
            summaryContentView
        }
        .background(cardBackground)
    }
    
    // MARK: - Card Background
    
    @ViewBuilder
    private var cardBackground: some View {
        if #available(iOS 26.0, *) {
            // iOS 26+: Liquid Glass nativo
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.clear)
                .glassEffect(.regular, in: .rect(cornerRadius: 24))
        } else {
            // iOS < 26: Fallback con material
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: colorScheme == .dark
                                    ? [Color.white.opacity(0.06), Color.white.opacity(0.02)]
                                    : [Color.white.opacity(0.6), Color.white.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: colorScheme == .dark
                                    ? [Color.white.opacity(0.15), Color.white.opacity(0.05)]
                                    : [Color.white.opacity(0.7), Color.black.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.08),
                    radius: colorScheme == .dark ? 16 : 12,
                    y: colorScheme == .dark ? 6 : 4
                )
        }
    }
    
    // MARK: - Period Header
    
    private var periodHeaderView: some View {
        Text(periodTitle.uppercased())
            .font(.caption.weight(.bold))
            .foregroundStyle(.secondary)
            .tracking(0.5)
            .padding(.top, FSpacing.md)
            .padding(.bottom, FSpacing.sm)
    }
    
    // MARK: - Summary Content
    
    private var summaryContentView: some View {
        HStack(spacing: 0) {
            SummaryItemButton(
                title: "Ingresos",
                amount: statistics.totalIncome,
                color: FColors.green,
                icon: "arrow.down.circle.fill",
                count: statistics.incomeCount,
                currencyCode: currencyCode,
                action: onIncomeTap
            )
            
            verticalDivider
            
            SummaryItemButton(
                title: "Gastos",
                amount: statistics.totalExpenses,
                color: FColors.red,
                icon: "arrow.up.circle.fill",
                count: statistics.expenseCount,
                currencyCode: currencyCode,
                action: onExpenseTap
            )
        }
        .padding(.vertical, FSpacing.md)
    }
    
    private var verticalDivider: some View {
        Rectangle()
            .fill(.secondary.opacity(0.2))
            .frame(width: 1, height: 50)
    }
}

// MARK: - Summary Item Button

private struct SummaryItemButton: View {
    
    let title: String
    let amount: Double
    let color: Color
    let icon: String
    let count: Int
    let currencyCode: String
    let action: (() -> Void)?
    
    private var isInteractive: Bool { action != nil }
    
    private var countLabel: String {
        count == 1 ? "1 transacción" : "\(count) transacciones"
    }
    
    var body: some View {
        Button {
            guard let action else { return }
            Constants.Haptic.light()
            action()
        } label: {
            contentStack
        }
        .buttonStyle(.plain)
        .disabled(!isInteractive)
    }
    
    private var contentStack: some View {
        VStack(spacing: FSpacing.xs) {
            headerRow
            amountText
            countText
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
    
    private var headerRow: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }
    
    private var amountText: some View {
        Text(amount.asCurrency(code: currencyCode))
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.primary)
            .monospacedDigit()
            .contentTransition(.numericText())
            .animation(Constants.Animation.numericTransition, value: amount)
    }
    
    private var countText: some View {
        Text(countLabel)
            .font(.caption2)
            .foregroundStyle(.tertiary)
    }
}

// MARK: - Compact Summary Card

struct TransactionSummaryCompact: View {
    
    let income: Double
    let expenses: Double
    var currencyCode: String = AppConfig.Defaults.currencyCode
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var balance: Double { income - expenses }
    private var isPositive: Bool { balance >= 0 }
    
    var body: some View {
        HStack(spacing: FSpacing.lg) {
            CompactIndicator(
                icon: "arrow.down.circle.fill",
                color: FColors.green,
                value: income.asCompactCurrency(code: currencyCode)
            )
            
            CompactIndicator(
                icon: "arrow.up.circle.fill",
                color: FColors.red,
                value: expenses.asCompactCurrency(code: currencyCode)
            )
            
            balanceIndicator
        }
        .padding(.horizontal, FSpacing.md)
        .padding(.vertical, FSpacing.sm)
        .background(compactBackground)
    }
    
    @ViewBuilder
    private var compactBackground: some View {
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(.clear)
                .glassEffect(.regular, in: .capsule)
        } else {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                )
        }
    }
    
    private var balanceIndicator: some View {
        HStack(spacing: 4) {
            Text("=")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            
            Text(formattedBalance)
                .font(.caption.weight(.bold))
                .foregroundStyle(isPositive ? FColors.green : FColors.red)
                .monospacedDigit()
        }
    }
    
    private var formattedBalance: String {
        let prefix = isPositive ? "+" : ""
        return "\(prefix)\(balance.asCompactCurrency(code: currencyCode))"
    }
}

// MARK: - Compact Indicator

private struct CompactIndicator: View {
    
    let icon: String
    let color: Color
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
            
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()
        }
    }
}

// MARK: - Mini Balance Indicator

struct BalanceIndicatorMini: View {
    
    let balance: Double
    var currencyCode: String = AppConfig.Defaults.currencyCode
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var isPositive: Bool { balance >= 0 }
    private var tintColor: Color { isPositive ? FColors.green : FColors.red }
    private var directionIcon: String { isPositive ? "arrow.up.right" : "arrow.down.right" }
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: directionIcon)
                .font(.system(size: 10, weight: .bold))
            
            Text(balance.asCompactCurrency(code: currencyCode))
                .font(.caption.weight(.bold))
                .monospacedDigit()
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(miniBackground)
    }
    
    @ViewBuilder
    private var miniBackground: some View {
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(.clear)
                .glassEffect(.regular.tint(tintColor), in: .capsule)
        } else {
            Capsule()
                .fill(tintColor.opacity(colorScheme == .dark ? 0.2 : 0.15))
                .overlay(
                    Capsule()
                        .stroke(tintColor.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Summary Card") {
    ZStack {
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack(spacing: FSpacing.lg) {
            TransactionSummaryCard(
                statistics: TransactionStatistics(
                    totalIncome: 15000,
                    totalExpenses: 8500,
                    totalTransfers: 500,
                    transactionCount: 45,
                    incomeCount: 3,
                    expenseCount: 40,
                    transferCount: 2,
                    averageExpense: 212.50,
                    largestExpense: 1500,
                    largestIncome: 10000
                )
            )
            
            TransactionSummaryCompact(income: 15000, expenses: 8500)
            
            HStack(spacing: FSpacing.md) {
                BalanceIndicatorMini(balance: 6500)
                BalanceIndicatorMini(balance: -2300)
            }
        }
        .padding()
    }
}

#Preview("Dark Mode") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        TransactionSummaryCard(
            statistics: TransactionStatistics(
                totalIncome: 5000,
                totalExpenses: 8500,
                totalTransfers: 0,
                transactionCount: 25,
                incomeCount: 2,
                expenseCount: 23,
                transferCount: 0,
                averageExpense: 370,
                largestExpense: 2000,
                largestIncome: 3000
            )
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
#endif
