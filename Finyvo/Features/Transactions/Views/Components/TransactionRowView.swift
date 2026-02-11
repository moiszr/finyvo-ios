//
//  TransactionRowView.swift
//  Finyvo
//
//  Created by Moises Núñez on 01/15/26.
//  Updated on 01/17/26 - Premium redesign with wallet display
//  Updated on 01/18/26 - Added +N tags display
//  Updated on 01/30/26 - Transfer type shows "Transferencia" label, code optimization
//
//  Premium transaction row with refined design.
//
//  Features:
//    - Premium card design (20pt corner radius)
//    - Safe wallet access (handles deleted wallets)
//    - Tags with +N counter
//    - Transfer type shows "Transferencia" instead of category
//    - Swipe actions for delete/duplicate
//

import SwiftUI

// MARK: - Transaction Row View

struct TransactionRowView: View {
    
    // MARK: - Properties
    
    let transaction: Transaction
    var showDate: Bool = false
    var onTap: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Layout Constants
    
    private enum Layout {
        static let cornerRadius: CGFloat = 20
        static let iconSize: CGFloat = 48
        static let iconCornerRadius: CGFloat = 14
        static let verticalPadding: CGFloat = 14
        static let horizontalPadding: CGFloat = 14
        static let contentSpacing: CGFloat = 12
    }
    
    // MARK: - Computed Properties

    private var safeWalletName: String? {
        guard let wallet = transaction.wallet,
              !wallet.isArchived,
              !wallet.name.isEmpty else {
            return nil
        }
        return wallet.name
    }

    private var firstTag: Tag? {
        transaction.tags?.first
    }
    
    private var additionalTagsCount: Int {
        max(0, (transaction.tags?.count ?? 0) - 1)
    }
    
    private var hasTags: Bool {
        !(transaction.tags?.isEmpty ?? true)
    }
    
    // MARK: - Body
    
    var body: some View {
        rowContent
            .contentShape(Rectangle())
            .onTapGesture {
                Constants.Haptic.light()
                onTap?()
            }
    }
    
    // MARK: - Row Content
    
    private var rowContent: some View {
        HStack(spacing: Layout.contentSpacing) {
            categoryIconView
            mainInfoView
            Spacer(minLength: 8)
            amountSectionView
        }
        .padding(.vertical, Layout.verticalPadding)
        .padding(.horizontal, Layout.horizontalPadding)
        .background(cardBackgroundView)
    }
    
    // MARK: - Category Icon
    
    private var categoryIconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Layout.iconCornerRadius, style: .continuous)
                .fill(transaction.displayColor.color.opacity(colorScheme == .dark ? 0.2 : 0.12))
                .frame(width: Layout.iconSize, height: Layout.iconSize)
            
            Image(systemName: transaction.displayIcon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(transaction.displayColor.color)
        }
    }
    
    // MARK: - Main Info
    
    private var mainInfoView: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(transaction.displayTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FColors.textPrimary)
                .lineLimit(1)
            
            subtitleRowView
        }
    }
    
    private var subtitleRowView: some View {
        HStack(spacing: 4) {
            if let subtitle = transaction.subtitleText {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(FColors.textSecondary)
                    .lineLimit(1)
            }
            
            if showDate {
                if transaction.subtitleText != nil {
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(FColors.textTertiary)
                }
                
                Text(transaction.date.relativeString)
                    .font(.caption)
                    .foregroundStyle(FColors.textTertiary)
            }
            
            if transaction.isRecurring {
                Image(systemName: "repeat")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(FColors.textTertiary)
            }
            
            if hasTags {
                tagsView
            }
        }
    }
    
    // MARK: - Tags View
    
    @ViewBuilder
    private var tagsView: some View {
        if let tag = firstTag {
            HStack(spacing: 2) {
                Text(tag.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(tag.color.color)
                
                if additionalTagsCount > 0 {
                    Text("+\(additionalTagsCount)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(FColors.textTertiary)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(tag.color.color.opacity(colorScheme == .dark ? 0.15 : 0.1))
            )
        }
    }
    
    // MARK: - Amount Section
    
    private var amountSectionView: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(transaction.safeFormattedSignedAmount)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(transaction.amountDisplayColor)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .contentTransition(.numericText())
            
            if let walletName = safeWalletName {
                walletLabelView(name: walletName)
            }
        }
    }
    
    private func walletLabelView(name: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 8, weight: .semibold))
            
            Text(name)
                .font(.caption2)
                .lineLimit(1)
                .underline(true, color: FColors.textTertiary.opacity(0.5))
        }
        .foregroundStyle(FColors.textTertiary)
    }
    
    // MARK: - Card Background
    
    private var cardBackgroundView: some View {
        RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
            .fill(colorScheme == .dark ? FColors.backgroundSecondary : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
                    .stroke(
                        colorScheme == .dark
                            ? Color.white.opacity(0.08)
                            : Color.black.opacity(0.05),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.04),
                radius: 8,
                y: 4
            )
    }
}

// MARK: - Compact Transaction Row

struct TransactionRowCompact: View {
    
    let transaction: Transaction
    var onTap: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            Constants.Haptic.light()
            onTap?()
        } label: {
            HStack(spacing: FSpacing.sm) {
                miniIconView
                titleAndSubtitleView
                Spacer()
                amountTextView
            }
            .padding(.vertical, FSpacing.xs + 2)
        }
        .buttonStyle(.plain)
    }
    
    private var miniIconView: some View {
        ZStack {
            Circle()
                .fill(transaction.displayColor.color.opacity(colorScheme == .dark ? 0.2 : 0.12))
                .frame(width: 36, height: 36)
            
            Image(systemName: transaction.displayIcon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(transaction.displayColor.color)
        }
    }
    
    private var titleAndSubtitleView: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(transaction.displayTitle)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(FColors.textPrimary)
                .lineLimit(1)
            
            if let subtitle = transaction.subtitleText {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(FColors.textTertiary)
                    .lineLimit(1)
            }
        }
    }

    private var amountTextView: some View {
        Text(transaction.safeFormattedSignedAmount)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(transaction.amountDisplayColor)
            .monospacedDigit()
            .lineLimit(1)
    }
}

// MARK: - Transaction Row Skeleton

struct TransactionRowSkeleton: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    private enum Layout {
        static let cornerRadius: CGFloat = 20
        static let iconSize: CGFloat = 48
        static let verticalPadding: CGFloat = 14
        static let horizontalPadding: CGFloat = 14
    }
    
    var body: some View {
        HStack(spacing: 12) {
            iconPlaceholder
            titlePlaceholders
            Spacer()
            amountPlaceholders
        }
        .padding(.vertical, Layout.verticalPadding)
        .padding(.horizontal, Layout.horizontalPadding)
        .background(backgroundView)
        .shimmer()
    }
    
    private var iconPlaceholder: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(FColors.textTertiary.opacity(0.12))
            .frame(width: Layout.iconSize, height: Layout.iconSize)
    }
    
    private var titlePlaceholders: some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 4)
                .fill(FColors.textTertiary.opacity(0.12))
                .frame(width: 130, height: 14)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(FColors.textTertiary.opacity(0.08))
                .frame(width: 80, height: 10)
        }
    }
    
    private var amountPlaceholders: some View {
        VStack(alignment: .trailing, spacing: 4) {
            RoundedRectangle(cornerRadius: 4)
                .fill(FColors.textTertiary.opacity(0.12))
                .frame(width: 70, height: 14)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(FColors.textTertiary.opacity(0.08))
                .frame(width: 50, height: 10)
        }
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
            .fill(colorScheme == .dark ? FColors.backgroundSecondary : Color.white)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Transaction Rows") {
    VStack(spacing: FSpacing.sm) {
        TransactionRowView(
            transaction: Transaction(
                amount: 1350.50,
                type: .expense,
                note: "Almuerzo con el equipo"
            ),
            showDate: true
        )
        
        TransactionRowView(
            transaction: Transaction(
                amount: 85000,
                type: .income,
                note: "Pago quincenal"
            ),
            showDate: true
        )
        
        TransactionRowView(
            transaction: Transaction(
                amount: 5000,
                type: .transfer,
                note: "Ahorro mensual"
            ),
            showDate: true
        )
    }
    .padding()
    .background(FColors.background)
}

#Preview("Compact Rows") {
    VStack(spacing: FSpacing.xs) {
        TransactionRowCompact(
            transaction: Transaction(amount: 150, type: .expense, note: "Café")
        )
        TransactionRowCompact(
            transaction: Transaction(amount: 5000, type: .transfer, note: "Ahorro")
        )
    }
    .padding()
    .background(FColors.background)
}

#Preview("Skeleton") {
    VStack(spacing: FSpacing.sm) {
        TransactionRowSkeleton()
        TransactionRowSkeleton()
        TransactionRowSkeleton()
    }
    .padding()
    .background(FColors.background)
}
#endif
