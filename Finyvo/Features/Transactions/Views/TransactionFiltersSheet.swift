//
//  TransactionFiltersSheet.swift
//  Finyvo
//
//  Created by Moises Núñez on 01/15/26.
//  Sheet de filtros avanzados para transacciones.
//

import SwiftUI
import SwiftData

// MARK: - Transaction Filters Sheet

struct TransactionFiltersSheet: View {

    // MARK: - Properties

    @Binding var filter: TransactionFilter

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Local State

    @State private var localFilter: TransactionFilter
    @State private var showCustomDatePicker = false

    // Queries
    @Query(filter: #Predicate<Wallet> { !$0.isArchived })
    private var wallets: [Wallet]

    @Query(filter: #Predicate<Category> { !$0.isArchived })
    private var categories: [Category]

    @Query
    private var tags: [Tag]

    private var isDark: Bool { colorScheme == .dark }

    init(filter: Binding<TransactionFilter>) {
        _filter = filter
        _localFilter = State(initialValue: filter.wrappedValue)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: FSpacing.xl) {
                    dateRangeSection
                    amountRangeSection

                    if !wallets.isEmpty {
                        walletsSection
                    }

                    if !categories.isEmpty {
                        categoriesSection
                    }

                    if !tags.isEmpty {
                        tagsSection
                    }
                }
                .padding(.horizontal, FSpacing.lg)
                .padding(.vertical, FSpacing.md)
                .padding(.bottom, 100)
            }
            .background(FColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .safeAreaInset(edge: .bottom) {
                bottomActionBar
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(FColors.background)
    }

    // MARK: - Date Range Section

    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: FSpacing.sm) {
            FilterSectionHeader(title: "Período", icon: "calendar")

            FlowLayout(spacing: FSpacing.sm) {
                ForEach(DateRange.allCases, id: \.rawValue) { range in
                    dateRangePill(range)
                }
            }

            if showCustomDatePicker || localFilter.dateRange == .custom {
                customDatePickers
            }
        }
        .animation(Constants.Animation.defaultSpring, value: showCustomDatePicker)
    }

    private func dateRangePill(_ range: DateRange) -> some View {
        let isSelected = localFilter.dateRange == range

        return Button {
            Constants.Haptic.selection()
            localFilter.dateRange = range
            showCustomDatePicker = range == .custom
        } label: {
            Text(range.shortTitle)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? (isDark ? .white : .primary) : .secondary)
                .padding(.horizontal, TransactionUI.pillPaddingH)
                .padding(.vertical, TransactionUI.pillPaddingV)
                .background {
                    if isSelected {
                        dateRangePillSelectedBackground
                    } else {
                        Capsule()
                            .fill(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                    }
                }
        }
        .buttonStyle(ScaleButtonStyle())
        .animation(Constants.Animation.quickSpring, value: isSelected)
    }

    @ViewBuilder
    private var dateRangePillSelectedBackground: some View {
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(.clear)
                .glassEffect(.regular.tint(FColors.brand.opacity(0.2)).interactive(), in: .capsule)
        } else {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().fill(FColors.brand.opacity(isDark ? 0.18 : 0.14)))
                .overlay(Capsule().stroke(FColors.brand.opacity(isDark ? 0.25 : 0.18), lineWidth: 1))
        }
    }

    private var customDatePickers: some View {
        VStack(spacing: FSpacing.md) {
            DatePicker(
                "Desde",
                selection: Binding(
                    get: { localFilter.customStartDate ?? Date.now.addingTimeInterval(-30 * 24 * 3600) },
                    set: { localFilter.customStartDate = $0 }
                ),
                displayedComponents: .date
            )

            DatePicker(
                "Hasta",
                selection: Binding(
                    get: { localFilter.customEndDate ?? Date.now },
                    set: { localFilter.customEndDate = $0 }
                ),
                displayedComponents: .date
            )
        }
        .padding(FSpacing.lg)
        .background(GlassCardBackground())
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Amount Range Section

    private var amountRangeSection: some View {
        VStack(alignment: .leading, spacing: FSpacing.sm) {
            FilterSectionHeader(title: "Monto", icon: "dollarsign.circle")

            VStack(spacing: FSpacing.md) {
                HStack {
                    Text("Mínimo")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(FColors.textSecondary)

                    Spacer()

                    TextField("0", value: $localFilter.minAmount, format: .currency(code: AppConfig.Defaults.currencyCode))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(FColors.textPrimary)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 120)
                }

                Rectangle()
                    .fill(.secondary.opacity(0.15))
                    .frame(height: 0.5)

                HStack {
                    Text("Máximo")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(FColors.textSecondary)

                    Spacer()

                    TextField("Sin límite", value: $localFilter.maxAmount, format: .currency(code: AppConfig.Defaults.currencyCode))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(FColors.textPrimary)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 120)
                }
            }
            .padding(FSpacing.lg)
            .background(GlassCardBackground())
        }
    }

    // MARK: - Wallets Section

    private var walletsSection: some View {
        VStack(alignment: .leading, spacing: FSpacing.sm) {
            FilterSectionHeader(title: "Billeteras", icon: "wallet.pass")

            FlowLayout(spacing: FSpacing.sm) {
                ForEach(wallets, id: \.id) { wallet in
                    FilterChipView(
                        title: wallet.name,
                        icon: wallet.icon.rawValue,
                        color: wallet.color.color,
                        isSelected: localFilter.walletIDs.contains(wallet.id)
                    ) {
                        toggleWallet(wallet)
                    }
                }
            }
        }
    }

    // MARK: - Categories Section

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: FSpacing.sm) {
            FilterSectionHeader(title: "Categorías", icon: "square.grid.2x2")

            FlowLayout(spacing: FSpacing.sm) {
                ForEach(categories, id: \.id) { category in
                    FilterChipView(
                        title: category.name,
                        icon: category.icon.rawValue,
                        color: category.color.color,
                        isSelected: localFilter.categoryIDs.contains(category.id)
                    ) {
                        toggleCategory(category)
                    }
                }
            }
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: FSpacing.sm) {
            FilterSectionHeader(title: "Etiquetas", icon: "tag")

            FlowLayout(spacing: FSpacing.sm) {
                ForEach(tags, id: \.id) { tag in
                    FilterChipView(
                        title: tag.displayName,
                        icon: nil,
                        color: tag.color.color,
                        isSelected: localFilter.tagIDs.contains(tag.id)
                    ) {
                        toggleTag(tag)
                    }
                }
            }
        }
    }

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        HStack(spacing: 12) {
            if localFilter.hasActiveFilters {
                Button {
                    Constants.Haptic.selection()
                    localFilter.reset()
                    showCustomDatePicker = false
                } label: {
                    Text("Limpiar")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FColors.red)
                        .frame(height: TransactionUI.buttonHeight)
                        .padding(.horizontal, FSpacing.lg)
                        .background(
                            Capsule()
                                .fill(isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.06))
                        )
                }
                .buttonStyle(ScaleButtonStyle())
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            Button {
                applyFilters()
            } label: {
                Text("Aplicar filtros")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isDark ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: TransactionUI.buttonHeight)
                    .background(
                        Capsule()
                            .fill(isDark ? Color.white : Color.black)
                            .shadow(color: Color.black.opacity(isDark ? 0.12 : 0.25), radius: 8, y: 4)
                    )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, FSpacing.lg)
        .padding(.vertical, FSpacing.sm)
        .background(.ultraThinMaterial)
        .animation(Constants.Animation.quickSpring, value: localFilter.hasActiveFilters)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Filtros")
                .font(.headline.weight(.semibold))
                .foregroundStyle(FColors.textPrimary)
        }

        ToolbarItem(placement: .confirmationAction) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FColors.textSecondary)
            }
        }
    }

    // MARK: - Actions

    private func toggleWallet(_ wallet: Wallet) {
        Constants.Haptic.selection()
        if localFilter.walletIDs.contains(wallet.id) {
            localFilter.walletIDs.remove(wallet.id)
        } else {
            localFilter.walletIDs.insert(wallet.id)
        }
    }

    private func toggleCategory(_ category: Category) {
        Constants.Haptic.selection()
        if localFilter.categoryIDs.contains(category.id) {
            localFilter.categoryIDs.remove(category.id)
        } else {
            localFilter.categoryIDs.insert(category.id)
        }
    }

    private func toggleTag(_ tag: Tag) {
        Constants.Haptic.selection()
        if localFilter.tagIDs.contains(tag.id) {
            localFilter.tagIDs.remove(tag.id)
        } else {
            localFilter.tagIDs.insert(tag.id)
        }
    }

    private func applyFilters() {
        Constants.Haptic.success()
        filter = localFilter
        dismiss()
    }
}

// MARK: - Filter Section Header

private struct FilterSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(FColors.textTertiary)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FColors.textSecondary)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Filter Chip View

private struct FilterChipView: View {
    let title: String
    let icon: String?
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : color)
                } else {
                    Circle()
                        .fill(isSelected ? .white : color)
                        .frame(width: 8, height: 8)
                }

                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? .white : FColors.textPrimary)
            }
            .padding(.horizontal, TransactionUI.pillPaddingH)
            .padding(.vertical, TransactionUI.pillPaddingV)
            .background {
                if isSelected {
                    chipSelectedBackground
                } else {
                    Capsule()
                        .fill(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .animation(Constants.Animation.quickSpring, value: isSelected)
    }

    @ViewBuilder
    private var chipSelectedBackground: some View {
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(color)
                .glassEffect(.regular.tint(color.opacity(0.15)), in: .capsule)
        } else {
            Capsule()
                .fill(color)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Filters Sheet") {
    TransactionFiltersSheet(filter: .constant(TransactionFilter()))
        .modelContainer(for: [Wallet.self, Category.self, Tag.self])
}
#endif
