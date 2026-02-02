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
                applyButton
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(FColors.background)
    }
    
    // MARK: - Date Range Section
    
    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: FSpacing.sm) {
            FilterSectionHeader(title: "Período", icon: "calendar")
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: FSpacing.sm) {
                ForEach(DateRange.allCases, id: \.rawValue) { range in
                    FilterDateRangeOption(
                        title: range.shortTitle,
                        isSelected: localFilter.dateRange == range
                    ) {
                        localFilter.dateRange = range
                        showCustomDatePicker = range == .custom
                    }
                }
            }
            
            if showCustomDatePicker || localFilter.dateRange == .custom {
                customDatePickers
            }
        }
        .animation(Constants.Animation.defaultSpring, value: showCustomDatePicker)
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
        .padding(FSpacing.md)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(cardBorder)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // MARK: - Amount Range Section
    
    private var amountRangeSection: some View {
        VStack(alignment: .leading, spacing: FSpacing.sm) {
            FilterSectionHeader(title: "Monto", icon: "dollarsign.circle")
            
            VStack(spacing: FSpacing.md) {
                HStack {
                    Text("Mínimo")
                        .font(.subheadline)
                        .foregroundStyle(FColors.textSecondary)
                    
                    Spacer()
                    
                    TextField("0", value: $localFilter.minAmount, format: .currency(code: AppConfig.Defaults.currencyCode))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(FColors.textPrimary)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 120)
                }
                
                Divider()
                
                HStack {
                    Text("Máximo")
                        .font(.subheadline)
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
            .padding(FSpacing.md)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(cardBorder)
        }
    }
    
    // MARK: - Wallets Section
    
    private var walletsSection: some View {
        VStack(alignment: .leading, spacing: FSpacing.sm) {
            FilterSectionHeader(title: "Billeteras", icon: "wallet.pass")
            
            FlowLayout(spacing: 8) {
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
            
            FlowLayout(spacing: 8) {
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
            
            FlowLayout(spacing: 8) {
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
    
    // MARK: - Apply Button
    
    private var applyButton: some View {
        Button {
            applyFilters()
        } label: {
            Text("Aplicar filtros")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(FColors.brand)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(.horizontal, FSpacing.lg)
        .padding(.vertical, FSpacing.md)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FColors.textPrimary)
            }
        }
        
        ToolbarItem(placement: .principal) {
            Text("Filtros")
                .font(.headline.weight(.semibold))
                .foregroundStyle(FColors.textPrimary)
        }
        
        ToolbarItem(placement: .primaryAction) {
            if localFilter.hasActiveFilters {
                Button {
                    localFilter.reset()
                } label: {
                    Text("Limpiar")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(FColors.red)
                }
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
    
    // MARK: - Helpers
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(colorScheme == .dark ? FColors.backgroundSecondary : Color.white)
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(
                colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04),
                lineWidth: 1
            )
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

// MARK: - Filter Date Range Option

private struct FilterDateRangeOption: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: {
            Constants.Haptic.selection()
            action()
        }) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? (colorScheme == .dark ? .black : .white) : FColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            isSelected
                            ? FColors.textPrimary
                            : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                        )
                )
        }
        .buttonStyle(.plain)
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
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : color)
                } else {
                    Circle()
                        .fill(isSelected ? .white : color)
                        .frame(width: 8, height: 8)
                }
                
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isSelected ? .white : FColors.textPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(
                        isSelected
                        ? color
                        : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(Constants.Animation.quickSpring, value: isSelected)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Filters Sheet") {
    TransactionFiltersSheet(filter: .constant(TransactionFilter()))
        .modelContainer(for: [Wallet.self, Category.self, Tag.self])
}
#endif
