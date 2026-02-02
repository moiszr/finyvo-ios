//
//  TransactionsView.swift
//  Finyvo
//
//  Created by Moises Núñez on 01/15/26.
//  Refactored on 01/18/26 - Clean architecture with @Query
//  Updated on 01/30/26 - Liquid Glass pills (iOS 26+), fallback for earlier versions
//
//  Architecture:
//    - @Query for data (SwiftData handles reactivity)
//    - @State viewModel for filters, navigation, business logic
//    - Liquid Glass on iOS 26+, material fallback on earlier
//    - NO manual refresh patterns
//

import SwiftUI
import SwiftData

// MARK: - Transactions View

struct TransactionsView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Data
    
    @Query(sort: \Transaction.date, order: .reverse)
    private var allTransactions: [Transaction]
    
    // MARK: - State
        
    @State private var viewModel = TransactionsViewModel()
    @State private var selectedQuickFilter: QuickFilter = .all
    @State private var showFilters = false
    @State private var pendingDuplicateTransaction: Transaction?
    
    // MARK: - Animation
    
    @Namespace private var pillAnimationNamespace
    
    // MARK: - Computed Properties
    
    private var filteredTransactions: [Transaction] {
        viewModel.filterTransactions(allTransactions)
    }
    
    private var groupedTransactions: [TransactionGroup] {
        viewModel.groupTransactions(filteredTransactions)
    }
    
    private var statistics: TransactionStatistics {
        viewModel.calculateStatistics(from: filteredTransactions)
    }
    
    private var hasTransactions: Bool {
        !allTransactions.isEmpty
    }
    
    private var isFilteredEmpty: Bool {
        hasTransactions && filteredTransactions.isEmpty
    }
    
    // MARK: - Body
        
    var body: some View {
        ZStack {
            FColors.background.ignoresSafeArea()
            scrollContent
        }
        .navigationTitle("Transacciones")
        .toolbarTitleDisplayMode(.inlineLarge)
        .toolbar { toolbarContent }
        .sheet(isPresented: $viewModel.isEditorPresented) {
            TransactionEditorSheet(viewModel: viewModel, mode: viewModel.editorMode)
        }
        .sheet(isPresented: $viewModel.isDetailPresented) {
            if let transaction = viewModel.selectedTransaction {
                TransactionDetailSheet(
                    transaction: transaction,
                    viewModel: viewModel,
                    modelContext: modelContext
                )
            }
        }
        .sheet(isPresented: $showFilters) {
            TransactionFiltersSheet(filter: $viewModel.filter)
        }
        .alert("Error", isPresented: errorBinding, presenting: viewModel.error) { _ in
            Button("OK", role: .cancel) {}
        } message: { error in
            Text(error.localizedDescription)
        }
        .onChange(of: pendingDuplicateTransaction) { _, newValue in
            guard let transaction = newValue else { return }
            
            pendingDuplicateTransaction = nil
            
            Task { @MainActor in
                // Más tiempo para que el swipe se cierre completamente
                try? await Task.sleep(for: .milliseconds(700))
                
                _ = withAnimation(Constants.Animation.smoothSpring) {
                    viewModel.duplicateTransactionAnimated(transaction, in: modelContext)
                }
                
                try? await Task.sleep(for: .milliseconds(100))
                Constants.Haptic.success()
            }
        }
    }
    
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )
    }
    
    // MARK: - Scroll Content
    
    private var scrollContent: some View {
        List {
            // Summary Card
            TransactionSummaryCard(
                statistics: statistics,
                periodTitle: viewModel.filter.dateRange.shortTitle,
                onIncomeTap: { selectFilter(.income) },
                onExpenseTap: { selectFilter(.expense) }
            )
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: FSpacing.sm, leading: FSpacing.lg, bottom: FSpacing.sm, trailing: FSpacing.lg))
            .listRowSeparator(.hidden)
            
            // Filter Pills
            filterPillsSection
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: FSpacing.sm, leading: 0, bottom: FSpacing.sm, trailing: 0))
                .listRowSeparator(.hidden)
            
            // Main Content
            mainContentSection
        }
        .listStyle(.plain)
        .listSectionSpacing(0)
        .listRowSpacing(0)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .environment(\.defaultMinListHeaderHeight, 0)
        .environment(\.defaultMinListRowHeight, 0)
    }
    
    // MARK: - Filter Pills Section
    
    private var filterPillsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(QuickFilter.allCases) { filter in
                    QuickFilterPill(
                        filter: filter,
                        isSelected: selectedQuickFilter == filter,
                        namespace: pillAnimationNamespace,
                        onTap: { selectFilter(filter) }
                    )
                }
            }
            .padding(.horizontal, FSpacing.lg)
        }
        .scrollClipDisabled()
    }
    
    // MARK: - Main Content Section
    
    @ViewBuilder
    private var mainContentSection: some View {
        if viewModel.isLoading {
            // Skeleton loading state
            ForEach(0..<5, id: \.self) { _ in
                TransactionRowSkeleton()
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: FSpacing.lg, bottom: 4, trailing: FSpacing.lg))
                    .listRowSeparator(.hidden)
            }
        } else if !hasTransactions {
            EmptyStateView(
                icon: "arrow.up.arrow.down",
                title: "Sin transacciones",
                message: "Registra tu primer ingreso o gasto para comenzar a gestionar tus finanzas.",
                actionTitle: "Crear ahora",
                action: { viewModel.presentCreate(type: .expense) }
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: FSpacing.xxxl, leading: FSpacing.lg, bottom: FSpacing.xxxl, trailing: FSpacing.lg))
        } else if isFilteredEmpty {
            EmptyStateView(
                icon: "line.3.horizontal.decrease.circle",
                title: "Sin resultados",
                message: "No hay transacciones que coincidan con los filtros seleccionados.",
                actionTitle: "Limpiar filtros",
                action: clearFilters
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: FSpacing.xxxl, leading: FSpacing.lg, bottom: FSpacing.xxxl, trailing: FSpacing.lg))
        } else {
            transactionsListSection
        }
    }
    
    // MARK: - Transactions List
    
    @ViewBuilder
    private var transactionsListSection: some View {
        if viewModel.grouping != .none {
            ForEach(groupedTransactions) { group in
                // Header como ROW (no sticky)
                TransactionGroupHeader(group: group)
                    .textCase(nil)
                    .listRowInsets(EdgeInsets(top: 0, leading: FSpacing.md, bottom: 2, trailing: FSpacing.md))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                ForEach(group.transactions, id: \.id) { transaction in
                    transactionRowView(for: transaction, showDate: false)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            .animation(Constants.Animation.smoothSpring,
                       value: groupedTransactions.flatMap { $0.transactions.map(\.id) })
        } else {
            ForEach(filteredTransactions, id: \.id) { transaction in
                transactionRowView(for: transaction, showDate: true)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
            .animation(Constants.Animation.smoothSpring, value: filteredTransactions.map(\.id))
        }
    }
    
    private func transactionRowView(for transaction: Transaction, showDate: Bool) -> some View {
        TransactionRowView(
            transaction: transaction,
            showDate: showDate,
            onTap: { viewModel.presentDetail(transaction) }
        )
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 2, leading: FSpacing.lg, bottom: 8, trailing: FSpacing.lg))
        .listRowSeparator(.hidden)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation(Constants.Animation.smoothSpring) {
                    Constants.Haptic.warning()
                    viewModel.deleteTransaction(transaction, in: modelContext)
                }
            } label: {
                Image(systemName: "trash")
            }
            .tint(.red)
            
            Button {
                Constants.Haptic.light()
                viewModel.presentEdit(transaction)
            } label: {
                Image(systemName: "pencil")
            }
            .tint(.orange)
            
            Button {
                pendingDuplicateTransaction = transaction
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .tint(FColors.brand)
        }
    }
    
    // MARK: - Filter Actions
    
    private func selectFilter(_ filter: QuickFilter) {
        withAnimation(Constants.Animation.quickSpring) {
            selectedQuickFilter = filter
        }
        viewModel.setTypeFilter(filter.transactionTypes)
    }
    
    private func clearFilters() {
        withAnimation(Constants.Animation.defaultSpring) {
            selectedQuickFilter = .all
        }
        viewModel.clearFilters()
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Transacciones")
                .font(.headline.weight(.semibold))
                .foregroundStyle(FColors.textPrimary)
        }
        
        ToolbarItem(placement: .primaryAction) {
            addButton
        }
        
        ToolbarItem(placement: .primaryAction) {
            optionsMenu
        }
    }
    
    private var addButton: some View {
        Button {
            Constants.Haptic.light()
            viewModel.presentCreate(type: .expense)
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .bold))
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(FColors.brand)
    }
    
    private var optionsMenu: some View {
        Menu {
            filterOptionsSection
            clearFiltersSection
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(FColors.textPrimary)
        }
    }
    
    @ViewBuilder
    private var filterOptionsSection: some View {
        Section {
            groupingMenu
            sortMenu
            periodMenu
            Button { showFilters = true } label: {
                Label("Más filtros", systemImage: "line.3.horizontal.decrease.circle")
            }
        }
    }
    
    private var groupingMenu: some View {
        Menu {
            ForEach(TransactionGrouping.allCases, id: \.rawValue) { grouping in
                Button {
                    viewModel.grouping = grouping
                } label: {
                    if viewModel.grouping == grouping {
                        Label(grouping.title, systemImage: "checkmark")
                    } else {
                        Text(grouping.title)
                    }
                }
            }
        } label: {
            Label("Agrupar", systemImage: "rectangle.3.group")
        }
    }
    
    private var sortMenu: some View {
        Menu {
            ForEach(SortOption.allCases, id: \.rawValue) { option in
                Button {
                    viewModel.filter.sortBy = option
                } label: {
                    if viewModel.filter.sortBy == option {
                        Label(option.title, systemImage: "checkmark")
                    } else {
                        Text(option.title)
                    }
                }
            }
        } label: {
            Label("Ordenar", systemImage: "arrow.up.arrow.down")
        }
    }
    
    private var periodMenu: some View {
        Menu {
            ForEach(DateRange.quickOptions, id: \.rawValue) { range in
                Button {
                    viewModel.setDateRange(range)
                } label: {
                    if viewModel.filter.dateRange == range {
                        Label(range.title, systemImage: "checkmark")
                    } else {
                        Text(range.title)
                    }
                }
            }
        } label: {
            Label("Período", systemImage: "calendar")
        }
    }
    
    @ViewBuilder
    private var clearFiltersSection: some View {
        if viewModel.filter.hasActiveFilters {
            Divider()
            Button(role: .destructive, action: clearFilters) {
                Label("Limpiar filtros", systemImage: "xmark.circle")
                    .tint(Color.red)
            }
        }
    }
}

// MARK: - Quick Filter Enum

private enum QuickFilter: String, CaseIterable, Identifiable {
    case all, expense, income, transfer
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .all: return "Todo"
        case .expense: return "Gastos"
        case .income: return "Ingresos"
        case .transfer: return "Transf."
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "rectangle.stack.fill"
        case .expense: return "arrow.up.circle.fill"
        case .income: return "arrow.down.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        }
    }
    
    var transactionTypes: Set<TransactionType> {
        switch self {
        case .all: return []
        case .expense: return [.expense]
        case .income: return [.income]
        case .transfer: return [.transfer]
        }
    }
}

// MARK: - Quick Filter Pill

private struct QuickFilterPill: View {
    
    let filter: QuickFilter
    let isSelected: Bool
    let namespace: Namespace.ID
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button {
            Constants.Haptic.light()
            onTap()
        } label: {
            pillLabel
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var pillLabel: some View {
        HStack(spacing: 6) {
            if isSelected {
                Image(systemName: filter.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .transition(.scale.combined(with: .opacity))
            }
            
            Text(filter.title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(isSelected ? selectedForeground : .secondary)
        .padding(.horizontal, isSelected ? 16 : 14)
        .padding(.vertical, 10)
        .background(pillBackground)
        .animation(Constants.Animation.quickSpring, value: isSelected)
    }
    
    private var selectedForeground: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    @ViewBuilder
    private var pillBackground: some View {
        if isSelected {
            if #available(iOS 26.0, *) {
                // iOS 26+: Liquid Glass nativo
                Capsule()
                    .fill(.clear)
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .matchedGeometryEffect(id: "selectedPill", in: namespace)
            } else {
                // iOS < 26: Fallback con material
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.08))
                    )
                    .matchedGeometryEffect(id: "selectedPill", in: namespace)
            }
        }
    }
}

// MARK: - Empty State View

private struct EmptyStateView: View {
    
    let icon: String
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: FSpacing.md) {
            Spacer(minLength: 40)
            
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(FColors.textTertiary)
                .padding(.bottom, 8)
            
            Text(title)
                .font(.headline)
                .foregroundStyle(FColors.textPrimary)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(FColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, FSpacing.xxxl)
            
            Button(action: action) {
                Text(actionTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FColors.textPrimary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().stroke(FColors.border, lineWidth: 1))
            }
            .padding(.top, FSpacing.sm)
            
            Spacer(minLength: 40)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Transactions View") {
    NavigationStack {
        TransactionsView()
    }
    .modelContainer(for: [Transaction.self, Category.self, Wallet.self, Tag.self])
}

#Preview("Dark Mode") {
    NavigationStack {
        TransactionsView()
    }
    .modelContainer(for: [Transaction.self, Category.self, Wallet.self, Tag.self])
    .preferredColorScheme(.dark)
}
#endif
