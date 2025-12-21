//
//  CategoriesView.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/11/25.
//  Refactored: Uses simplified Category model with FCategoryIcon and FCardColor.
//

import SwiftUI
import SwiftData

// MARK: - Categories View

/// Vista principal de categorías con diseño premium Finyvo.
struct CategoriesView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - State
    
    @State private var viewModel = CategoriesViewModel()
    @State private var hasInitialized = false
    
    // MARK: - Queries
    
    @Query private var expenseCategories: [Category]
    @Query private var incomeCategories: [Category]
    @Query private var archivedExpenseCategories: [Category]
    @Query private var archivedIncomeCategories: [Category]
    
    init() {
        let sortDescriptors: [SortDescriptor<Category>] = [
            SortDescriptor(\Category.sortOrder, order: .forward),
            SortDescriptor(\Category.name, order: .forward)
        ]
        
        let activeExpensePredicate: Predicate<Category> = #Predicate { category in
            category.parent == nil &&
            !category.isArchived &&
            category.typeRaw == "expense"
        }
        
        _expenseCategories = Query(
            filter: activeExpensePredicate,
            sort: sortDescriptors
        )
        
        let activeIncomePredicate: Predicate<Category> = #Predicate { category in
            category.parent == nil &&
            !category.isArchived &&
            category.typeRaw == "income"
        }
        
        _incomeCategories = Query(
            filter: activeIncomePredicate,
            sort: sortDescriptors
        )
        
        let archivedExpensePredicate: Predicate<Category> = #Predicate { category in
            category.parent == nil &&
            category.isArchived &&
            category.typeRaw == "expense"
        }
        
        _archivedExpenseCategories = Query(
            filter: archivedExpensePredicate,
            sort: sortDescriptors
        )
        
        let archivedIncomePredicate: Predicate<Category> = #Predicate { category in
            category.parent == nil &&
            category.isArchived &&
            category.typeRaw == "income"
        }
        
        _archivedIncomeCategories = Query(
            filter: archivedIncomePredicate,
            sort: sortDescriptors
        )
    }
    
    // MARK: - Computed
    
    private var filteredCategories: [Category] {
        if viewModel.showArchived {
            return archivedExpenseCategories + archivedIncomeCategories
        }
        
        switch viewModel.selectedType {
        case .expense:
            return expenseCategories
        case .income:
            return incomeCategories
        case .none:
            return expenseCategories
        }
    }
    
    private var isEmpty: Bool {
        expenseCategories.isEmpty && incomeCategories.isEmpty
    }
    
    private var expenseCount: Int {
        expenseCategories.count
    }
    
    private var incomeCount: Int {
        incomeCategories.count
    }
    
    private var archivedCount: Int {
        archivedExpenseCategories.count + archivedIncomeCategories.count
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                FColors.background.ignoresSafeArea()
                content
            }
            .navigationTitle("Categorías")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.presentCreate()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .accessibilityLabel("Crear categoría")
                }
            }
            .sheet(isPresented: $viewModel.isEditorPresented) {
                CategoryEditorSheet(
                    viewModel: viewModel,
                    mode: viewModel.editorMode
                )
            }
            .sheet(isPresented: $viewModel.isDetailPresented) {
                if let category = viewModel.selectedCategory {
                    CategoryDetailSheet(category: category, viewModel: viewModel)
                }
            }
            .alert("Archivar categoría", isPresented: $viewModel.isArchiveAlertPresented) {
                Button("Cancelar", role: .cancel) {}
                Button("Archivar", role: .destructive) {
                    viewModel.confirmArchive()
                }
            } message: {
                Text("La categoría se ocultará pero sus transacciones se mantendrán intactas.")
            }
            .alert("Eliminar categoría", isPresented: $viewModel.isDeleteAlertPresented) {
                Button("Cancelar", role: .cancel) {}
                Button("Eliminar", role: .destructive) {
                    viewModel.confirmDelete()
                }
            } message: {
                Text("Esta acción no se puede deshacer.")
            }
            .overlay(alignment: .top) {
                if let error = viewModel.error {
                    ErrorBanner(message: error.localizedDescription) {
                        viewModel.error = nil
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 4)
                }
            }
        }
        .onAppear {
            viewModel.configure(with: modelContext)
            
            if !hasInitialized {
                viewModel.setTypeFilter(.expense)
                hasInitialized = true
            }
        }
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var content: some View {
        if isEmpty && !viewModel.showArchived {
            emptyState(
                icon: "square.grid.2x2.fill",
                title: "Crea tu primera categoría",
                message: "Empieza con algo simple: Comida, Transporte, Suscripciones… Luego Finyvo hará el resto.",
                showButton: true
            )
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: FSpacing.xxl) {
                    filterSection
                        .padding(.top, FSpacing.md)
                    
                    if viewModel.showArchived && archivedCount == 0 {
                        emptyState(
                            icon: "archivebox",
                            title: "Sin categorías archivadas",
                            message: "Las categorías que archives aparecerán aquí. Podrás restaurarlas cuando quieras.",
                            showButton: false
                        )
                        .padding(.top, FSpacing.lg)
                    } else if filteredCategories.isEmpty {
                        emptyState(
                            icon: "tray",
                            title: "Sin categorías",
                            message: "No tienes categorías de este tipo. Crea una para empezar a organizar tus finanzas.",
                            showButton: true
                        )
                        .padding(.top, FSpacing.lg)
                    } else {
                        categoriesGrid
                    }
                }
                .padding(.bottom, 100)
            }
        }
    }
    
    // MARK: - Filter Section
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FSpacing.sm) {
                FilterPill(
                    title: "Gastos",
                    count: expenseCount,
                    isSelected: !viewModel.showArchived && viewModel.selectedType == .expense
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        viewModel.showArchived = false
                        viewModel.setTypeFilter(.expense)
                    }
                }
                
                FilterPill(
                    title: "Ingresos",
                    count: incomeCount,
                    isSelected: !viewModel.showArchived && viewModel.selectedType == .income
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        viewModel.showArchived = false
                        viewModel.setTypeFilter(.income)
                    }
                }
                
                FilterPill(
                    title: "Archivadas",
                    count: archivedCount,
                    isSelected: viewModel.showArchived
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        viewModel.showArchived = true
                        viewModel.setTypeFilter(nil)
                    }
                }
            }
            .padding(.horizontal, FSpacing.lg)
            .padding(.vertical, FSpacing.sm)
        }
    }
    
    // MARK: - Categories Grid
    
    private var categoriesGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: FSpacing.md),
                GridItem(.flexible(), spacing: FSpacing.md)
            ],
            spacing: FSpacing.md
        ) {
            ForEach(filteredCategories) { category in
                CategoryCardWrapper(category: category, viewModel: viewModel)
            }
        }
        .padding(.horizontal, FSpacing.lg)
        .padding(.bottom, FSpacing.lg)
    }
    
    // MARK: - Empty State
    
    private func emptyState(
        icon: String,
        title: String,
        message: String,
        showButton: Bool
    ) -> some View {
        VStack(spacing: FSpacing.xxl) {
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 32)
                    .fill(
                        LinearGradient(
                            colors: [
                                FColors.backgroundSecondary,
                                FColors.backgroundSecondary.opacity(colorScheme == .dark ? 0.2 : 0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(FColors.separator.opacity(0.4), lineWidth: 1)
                    )
                
                VStack(spacing: FSpacing.lg) {
                    ZStack {
                        Circle()
                            .fill(FColors.brand.opacity(0.12))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: icon)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(FColors.brand)
                    }
                    
                    VStack(spacing: FSpacing.sm) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(FColors.textPrimary)
                        
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(FColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, FSpacing.lg)
                    }
                    
                    if showButton {
                        FButton("Crear categoría", variant: .brand, isFullWidth: false) {
                            viewModel.presentCreate()
                        }
                        .padding(.top, FSpacing.sm)
                    }
                }
                .padding(.vertical, FSpacing.xxxl)
                .padding(.horizontal, FSpacing.xxxl)
            }
            .padding(.horizontal, FSpacing.lg)
            
            Spacer()
        }
    }
}

// MARK: - Filter Pill

private struct FilterPill: View {
    let title: String
    var count: Int? = nil
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var backgroundColor: Color {
        if isSelected {
            return FColors.brand
        }
        return colorScheme == .dark
            ? FColors.backgroundSecondary
            : Color.white
    }
    
    private var borderColor: Color {
        if isSelected {
            return Color.clear
        }
        return colorScheme == .dark
            ? Color.white.opacity(0.10)
            : Color.black.opacity(0.06)
    }
    
    private var textColor: Color {
        isSelected ? .white : FColors.textSecondary
    }
    
    private var countBackgroundColor: Color {
        if isSelected {
            return Color.white.opacity(0.24)
        }
        return colorScheme == .dark
            ? Color.white.opacity(0.06)
            : Color.black.opacity(0.04)
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                
                if let count = count {
                    Text("\(count)")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(countBackgroundColor))
                }
            }
            .foregroundStyle(textColor)
            .padding(.horizontal, FSpacing.md)
            .padding(.vertical, FSpacing.sm)
            .background(
                Capsule()
                    .fill(backgroundColor)
                    .overlay(Capsule().stroke(borderColor, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Card Wrapper

private struct CategoryCardWrapper: View {
    let category: Category
    let viewModel: CategoriesViewModel
    
    // MARK: - Card Data
    
    /// Ahora es directo - el modelo ya tiene icon y color correctos
    private var cardData: FCardData {
        category.toCardData(
            spent: 0,              // TODO: Conectar con transacciones reales
            transactionCount: 0    // TODO: Conectar con transacciones reales
        )
    }
    
    // MARK: - Body
    
    var body: some View {
        FCardCategoryView(data: cardData)
            .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 22))
            .onTapGesture {
                viewModel.presentDetail(category)
            }
            .contextMenu {
                contextMenuContent
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: category.id)
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private var contextMenuContent: some View {
        Button {
            viewModel.presentEdit(category)
        } label: {
            Label("Editar", systemImage: "pencil")
        }
        
        Button {
            viewModel.toggleFavorite(category)
        } label: {
            Label(
                category.isFavorite ? "Quitar favorito" : "Favorito",
                systemImage: category.isFavorite ? "star.slash" : "star"
            )
        }
        
        Button {
            viewModel.duplicateCategory(category)
        } label: {
            Label("Duplicar", systemImage: "doc.on.doc")
        }
        
        Divider()
        
        if category.isArchived {
            Button {
                viewModel.restoreCategory(category)
            } label: {
                Label("Restaurar", systemImage: "arrow.uturn.backward")
            }
        }
        
        if !category.isSystem {
            if category.isArchived {
                Button(role: .destructive) {
                    viewModel.presentDeleteAlert(category)
                } label: {
                    Label("Eliminar", systemImage: "trash")
                }
            } else {
                Button(role: .destructive) {
                    viewModel.presentArchiveAlert(category)
                } label: {
                    Label("Archivar", systemImage: "archivebox")
                }
            }
        }
    }
}

// MARK: - Error Banner

private struct ErrorBanner: View {
    let message: String
    let onClose: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
                .imageScale(.small)
            
            Text(message)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white)
                .lineLimit(2)
            
            Spacer(minLength: 8)
            
            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, FSpacing.lg)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.red.opacity(0.95),
                            Color.red.opacity(0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .shadow(color: Color.red.opacity(0.35), radius: 18, x: 0, y: 10)
        .padding(.horizontal, FSpacing.lg)
    }
}

// MARK: - Preview

#Preview {
    CategoriesView()
        .modelContainer(for: Category.self, inMemory: true)
}

#Preview("Dark Mode") {
    CategoriesView()
        .modelContainer(for: Category.self, inMemory: true)
        .preferredColorScheme(.dark)
}
