//
//  CategoriesView.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/11/25.
//  Refactored: Premium "Silent Canvas" design aligned with Editor.
//  Integrated with Constants.Haptic and Constants.Animation.
//

import SwiftUI
import SwiftData

// MARK: - Categories View

struct CategoriesView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - State
    
    @State private var viewModel = CategoriesViewModel()
    @State private var hasInitialized = false
    @State private var tagsViewModel = TagsViewModel()
    
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
            category.parent == nil && !category.isArchived && category.typeRaw == "expense"
        }
        _expenseCategories = Query(filter: activeExpensePredicate, sort: sortDescriptors)
        
        let activeIncomePredicate: Predicate<Category> = #Predicate { category in
            category.parent == nil && !category.isArchived && category.typeRaw == "income"
        }
        _incomeCategories = Query(filter: activeIncomePredicate, sort: sortDescriptors)
        
        let archivedExpensePredicate: Predicate<Category> = #Predicate { category in
            category.parent == nil && category.isArchived && category.typeRaw == "expense"
        }
        _archivedExpenseCategories = Query(filter: archivedExpensePredicate, sort: sortDescriptors)
        
        let archivedIncomePredicate: Predicate<Category> = #Predicate { category in
            category.parent == nil && category.isArchived && category.typeRaw == "income"
        }
        _archivedIncomeCategories = Query(filter: archivedIncomePredicate, sort: sortDescriptors)
    }
    
    // MARK: - Computed Properties
    
    private var filteredCategories: [Category] {
        if viewModel.showArchived {
            return archivedExpenseCategories + archivedIncomeCategories
        }
        switch viewModel.selectedType {
        case .expense: return expenseCategories
        case .income: return incomeCategories
        case .none: return expenseCategories
        }
    }
    
    private var isEmpty: Bool { expenseCategories.isEmpty && incomeCategories.isEmpty }
    private var expenseCount: Int { expenseCategories.count }
    private var incomeCount: Int { incomeCategories.count }
    private var archivedCount: Int { archivedExpenseCategories.count + archivedIncomeCategories.count }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo General
                FColors.background.ignoresSafeArea()
                
                // Contenido Principal
                if isEmpty && !viewModel.showArchived {
                    emptyState(
                        icon: "square.grid.2x2.fill",
                        title: "Tu espacio está vacío",
                        message: "Crea tu primera categoría para empezar a organizar tus finanzas.",
                        showButton: true
                    )
                } else {
                    mainScrollView
                }
            }
            .navigationTitle("Categorías")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        // TODO: Implementar lógica de Atras.
                    } label: {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(FColors.textPrimary)
                    }
                    .accessibilityLabel("Atras")
                }
                
                // Botón Tags
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        tagsViewModel.present()
                    } label: {
                        Image(systemName: "tag")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(FColors.textPrimary)
                    }
                    .accessibilityLabel("Etiquetas")
                }
                 
                // Botón Crear Categoría
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.presentCreate()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(FColors.textPrimary)
                    }
                    .accessibilityLabel("Crear categoría")
                }
            }
            // Sheets y Alertas
            .sheet(isPresented: $viewModel.isEditorPresented) {
                CategoryEditorSheet(viewModel: viewModel, mode: viewModel.editorMode)
            }
            .sheet(isPresented: $viewModel.isDetailPresented) {
                if let category = viewModel.selectedCategory {
                    CategoryDetailSheet(category: category, viewModel: viewModel)
                }
            }
            .sheet(isPresented: $tagsViewModel.isPresented) {
                TagsSheet(viewModel: tagsViewModel)
            }
            .alert("Archivar categoría", isPresented: $viewModel.isArchiveAlertPresented) {
                Button("Cancelar", role: .cancel) {}
                Button("Archivar", role: .destructive) { viewModel.confirmArchive() }
            } message: {
                Text("La categoría se ocultará pero sus transacciones se mantendrán intactas.")
            }
            .alert("Eliminar categoría", isPresented: $viewModel.isDeleteAlertPresented) {
                Button("Cancelar", role: .cancel) {}
                Button("Eliminar", role: .destructive) { viewModel.confirmDelete() }
            } message: {
                Text("Esta acción no se puede deshacer.")
            }
            .overlay(alignment: .top) {
                if let error = viewModel.error {
                    ErrorBanner(message: error.localizedDescription) { viewModel.error = nil }
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 4)
                }
            }
        }
        .onAppear {
            viewModel.configure(with: modelContext)
            tagsViewModel.configure(with: modelContext)
            if !hasInitialized {
                viewModel.setTypeFilter(.expense)
                hasInitialized = true
            }
        }
    }
    
    // MARK: - Main Scroll Content
    
    private var mainScrollView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: FSpacing.xl) {
                
                // Filtros (Pills)
                filterSection
                    .padding(.top, FSpacing.sm)
                
                // Contenido Variable
                if viewModel.showArchived && archivedCount == 0 {
                    emptyState(
                        icon: "archivebox",
                        title: "Nada archivado",
                        message: "Las categorías que archives aparecerán aquí.",
                        showButton: false
                    )
                    .padding(.top, FSpacing.xl)
                    
                } else if filteredCategories.isEmpty {
                    emptyState(
                        icon: "tray",
                        title: "Sin categorías",
                        message: "No hay categorías de este tipo.",
                        showButton: true
                    )
                    .padding(.top, FSpacing.xl)
                    
                } else {
                    categoriesGrid
                }
            }
        }
    }
    
    // MARK: - Filter Section (Premium)
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterPill(
                    title: "Gastos",
                    count: expenseCount,
                    isSelected: !viewModel.showArchived && viewModel.selectedType == .expense
                ) {
                    filterAction(.expense)
                }
                
                FilterPill(
                    title: "Ingresos",
                    count: incomeCount,
                    isSelected: !viewModel.showArchived && viewModel.selectedType == .income
                ) {
                    filterAction(.income)
                }
                
                // Separador visual sutil
                Rectangle()
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 1, height: 20)
                    .padding(.horizontal, 4)
                
                FilterPill(
                    title: "Archivadas",
                    count: archivedCount,
                    isSelected: viewModel.showArchived
                ) {
                    filterAction(nil, archived: true)
                }
            }
            .padding(.horizontal, FSpacing.lg)
            .padding(.vertical, 8)
        }
    }
    
    private func filterAction(_ type: CategoryType?, archived: Bool = false) {
        withAnimation(Constants.Animation.defaultSpring) {
            viewModel.showArchived = archived
            viewModel.setTypeFilter(type)
        }
        Task { @MainActor in Constants.Haptic.light() }
    }
    
    // MARK: - Grid
    
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
    
    // MARK: - Empty State (Minimalista)
    
    private func emptyState(icon: String, title: String, message: String, showButton: Bool) -> some View {
        VStack(spacing: FSpacing.md) {
            Spacer(minLength: 40)
            
            Image(systemName: icon)
                .font(.system(size: 40))
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
            
            if showButton {
                Button {
                    viewModel.presentCreate()
                } label: {
                    Text("Crear ahora")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FColors.textPrimary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .stroke(FColors.border, lineWidth: 1)
                        )
                }
                .padding(.top, FSpacing.sm)
            }
            
            Spacer()
        }
    }
}

// MARK: - Filter Pill (Diseño Neutro Premium)

private struct FilterPill: View {
    let title: String
    var count: Int? = nil
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                
                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? (colorScheme == .dark ? .black : .white) : FColors.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected
                                      ? (colorScheme == .dark ? Color.white.opacity(0.9) : Color.white.opacity(0.3))
                                      : FColors.backgroundTertiary)
                        )
                }
            }
            .foregroundStyle(isSelected ? (colorScheme == .dark ? .black : .white) : FColors.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        isSelected
                        ? FColors.textPrimary
                        : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Category Card Wrapper

private struct CategoryCardWrapper: View {
    let category: Category
    let viewModel: CategoriesViewModel
    
    // Mapeo directo al nuevo FCardData
    private var cardData: FCardData {
        category.toCardData(spent: 0, transactionCount: 0) // TODO: Conectar real data
    }
    
    var body: some View {
        FCardCategoryView(data: cardData)
            .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 24, style: .continuous))
            .onTapGesture { viewModel.presentDetail(category) }
            .contextMenu { contextMenuContent }
            .transition(.scale(scale: 0.95).combined(with: .opacity))
    }
    
    @ViewBuilder
    private var contextMenuContent: some View {
        Button { viewModel.presentEdit(category) } label: {
            Label("Editar", systemImage: "pencil")
        }
        Button { viewModel.toggleFavorite(category) } label: {
            Label(
                category.isFavorite ? "Quitar favorito" : "Favorito",
                systemImage: category.isFavorite ? "star.slash" : "star"
            )
        }
        Button { viewModel.duplicateCategory(category) } label: {
            Label("Duplicar", systemImage: "plus.square.on.square")
        }
        Divider()
        if !category.isSystem {
            Button(role: .destructive) {
                category.isArchived
                    ? viewModel.presentDeleteAlert(category)
                    : viewModel.presentArchiveAlert(category)
            } label: {
                Label(
                    category.isArchived ? "Eliminar" : "Archivar",
                    systemImage: category.isArchived ? "trash" : "archivebox"
                )
            }
        }
    }
}

// MARK: - Error Banner (Flotante)

private struct ErrorBanner: View {
    let message: String
    let onClose: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.white)
            
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .lineLimit(2)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.red.opacity(0.95))
                .shadow(color: Color.red.opacity(0.3), radius: 10, y: 5)
        )
        .padding(.horizontal, 24)
        .onTapGesture { onClose() }
    }
}

// MARK: - Helper: Scale Button Style

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(Constants.Animation.quickSpring, value: configuration.isPressed)
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
