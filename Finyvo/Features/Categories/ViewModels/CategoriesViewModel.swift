//
//  CategoriesViewModel.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/11/25.
//  Refactored for Swift 6 with FCategoryIcon and FCardColor support.
//  Integrated with Constants.Haptic and AppConfig.Limits.
//

import SwiftUI
import SwiftData

// MARK: - Categories ViewModel

/// ViewModel principal para la gestión de categorías.
///
/// ## Responsabilidades
/// - CRUD de categorías via SwiftData
/// - Estado de filtros (tipo, archivadas)
/// - Coordinación de navegación (sheets, alerts)
/// - Seeding de categorías por defecto
///
/// ## Uso
/// ```swift
/// @State private var viewModel = CategoriesViewModel()
///
/// .onAppear {
///     viewModel.configure(with: modelContext)
/// }
/// ```
@Observable
final class CategoriesViewModel {
    
    // MARK: - Dependencies
    
    private var modelContext: ModelContext?
    
    // MARK: - Filter State
    
    /// Filtro de tipo activo (`nil` = mostrar tipo por defecto)
    private(set) var selectedType: CategoryType? = nil
    
    /// Mostrar categorías archivadas
    var showArchived: Bool = false
    
    // MARK: - Loading & Error State
    
    /// Estado de carga para operaciones async
    private(set) var isLoading: Bool = false
    
    /// Error actual para mostrar en UI
    var error: CategoryError? = nil
    
    // MARK: - Selection State
    
    /// Categoría seleccionada para detalle/edición
    var selectedCategory: Category? = nil
    
    /// Categoría pendiente de acción destructiva
    private var categoryPendingAction: Category? = nil
    
    // MARK: - Sheet State
    
    /// Controla visibilidad del editor (crear/editar)
    var isEditorPresented: Bool = false
    
    /// Controla visibilidad del sheet de detalle
    var isDetailPresented: Bool = false
    
    /// Modo actual del editor
    private(set) var editorMode: CategoryEditorMode = .create
    
    // MARK: - Alert State
    
    /// Controla alert de confirmación de archivo
    var isArchiveAlertPresented: Bool = false
    
    /// Controla alert de confirmación de eliminación
    var isDeleteAlertPresented: Bool = false
    
    // MARK: - Create Mode Configuration
    
    /// Parent para nueva subcategoría
    private(set) var parentForNewCategory: Category? = nil
    
    /// Tipo sugerido para nueva categoría
    private(set) var suggestedTypeForNewCategory: CategoryType = .expense
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Configuration
    
    /// Configura el ModelContext. Llamar desde `onAppear` de la vista.
    ///
    /// - Parameter context: ModelContext de SwiftData
    func configure(with context: ModelContext) {
        guard modelContext == nil else { return } // Ya configurado
        
        modelContext = context
        seedDefaultCategoriesIfNeeded()
    }
    
    // MARK: - Filter Actions
    
    /// Establece el filtro de tipo de categoría.
    ///
    /// - Parameter type: Tipo a filtrar, o `nil` para limpiar
    func setTypeFilter(_ type: CategoryType?) {
        withAnimation(Constants.Animation.defaultSpring) {
            selectedType = type
            
            // Si cambiamos de tipo, salir de modo archivadas
            if type != nil {
                showArchived = false
            }
        }
        Task { @MainActor in Constants.Haptic.light() }
    }
    
    /// Activa/desactiva el modo de archivadas.
    func toggleArchivedMode() {
        withAnimation(Constants.Animation.defaultSpring) {
            showArchived.toggle()
            if showArchived {
                selectedType = nil
            }
        }
        Task { @MainActor in Constants.Haptic.light() }
    }
    
    /// Limpia todos los filtros.
    func clearFilters() {
        withAnimation(Constants.Animation.defaultSpring) {
            selectedType = .expense
            showArchived = false
        }
    }
    
    // MARK: - CRUD Operations
    
    /// Crea una nueva categoría.
    ///
    /// - Parameters:
    ///   - name: Nombre de la categoría
    ///   - icon: Icono SF Symbol
    ///   - color: Color de la paleta
    ///   - type: Tipo (ingreso/gasto)
    ///   - budget: Presupuesto opcional
    ///   - keywords: Keywords para auto-categorización
    ///   - parent: Categoría padre (para subcategorías)
    func createCategory(
        name: String,
        icon: FCategoryIcon,
        color: FCardColor,
        type: CategoryType,
        budget: Double? = nil,
        keywords: [String] = [],
        parent: Category? = nil
    ) {
        guard let context = requireContext() else { return }
        
        // Validar límite de categorías
        let currentCount = countCategories(ofType: type, in: context)
        guard currentCount < AppConfig.Limits.maxCategoriesPerType else {
            error = .limitReached
            Task { @MainActor in Constants.Haptic.error() }
            return
        }
        
        // Validar límite de keywords
        let validatedKeywords = Array(keywords.prefix(AppConfig.Limits.maxKeywordsPerCategory))
        
        let category = Category(
            name: String(name.prefix(AppConfig.Limits.maxCategoryNameLength)),
            icon: icon,
            color: color,
            type: type,
            budget: budget,
            keywords: validatedKeywords,
            parent: parent
        )
        
        // Calcular sortOrder
        category.sortOrder = nextSortOrder(for: type, in: context)
        
        context.insert(category)
        save()
        Task { @MainActor in Constants.Haptic.success() }
    }
    
    /// Actualiza una categoría existente.
    ///
    /// - Parameter category: Categoría a actualizar (ya modificada)
    func updateCategory(_ category: Category) {
        category.updatedAt = .now
        save()
        Task { @MainActor in Constants.Haptic.light() }
    }
    
    /// Archiva una categoría y sus subcategorías.
    ///
    /// - Parameter category: Categoría a archivar
    func archiveCategory(_ category: Category) {
        category.isArchived = true
        category.updatedAt = .now
        
        // Archivar subcategorías activas
        for child in category.activeChildren {
            child.isArchived = true
            child.updatedAt = .now
        }
        
        save()
        Task { @MainActor in Constants.Haptic.success() }
    }
    
    /// Restaura una categoría archivada.
    ///
    /// - Parameter category: Categoría a restaurar
    func restoreCategory(_ category: Category) {
        category.isArchived = false
        category.updatedAt = .now
        save()
        Task { @MainActor in Constants.Haptic.success() }
    }
    
    /// Elimina permanentemente una categoría.
    ///
    /// - Parameter category: Categoría a eliminar
    func deleteCategory(_ category: Category) {
        guard let context = requireContext() else { return }
        
        guard !category.isSystem else {
            error = .cannotDeleteSystem
            Task { @MainActor in Constants.Haptic.error() }
            return
        }
        
        context.delete(category)
        save()
        Task { @MainActor in Constants.Haptic.success() }
    }
    
    /// Duplica una categoría.
    ///
    /// - Parameter category: Categoría a duplicar
    func duplicateCategory(_ category: Category) {
        guard let context = requireContext() else { return }
        
        // Validar límite de categorías
        let currentCount = countCategories(ofType: category.type, in: context)
        guard currentCount < AppConfig.Limits.maxCategoriesPerType else {
            error = .limitReached
            Task { @MainActor in Constants.Haptic.error() }
            return
        }
        
        let duplicate = Category(
            name: "\(category.name) (copia)".prefix(AppConfig.Limits.maxCategoryNameLength).description,
            icon: category.icon,
            color: category.color,
            type: category.type,
            budget: category.budget,
            keywords: category.keywords,
            parent: category.parent
        )
        
        duplicate.sortOrder = nextSortOrder(for: category.type, in: context)
        
        context.insert(duplicate)
        save()
        Task { @MainActor in Constants.Haptic.success() }
    }
    
    /// Alterna el estado de favorito.
    ///
    /// - Parameter category: Categoría a modificar
    func toggleFavorite(_ category: Category) {
        category.isFavorite.toggle()
        category.updatedAt = .now
        save()
        Task { @MainActor in Constants.Haptic.light() }
    }
    
    // MARK: - Keyword Management
    
    /// Agrega una keyword a una categoría.
    ///
    /// - Parameters:
    ///   - keyword: Keyword a agregar
    ///   - category: Categoría destino
    func addKeyword(_ keyword: String, to category: Category) {
        // Validar límite
        guard category.keywords.count < AppConfig.Limits.maxKeywordsPerCategory else {
            return
        }
        
        let normalized = keyword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        guard !normalized.isEmpty,
              !category.keywords.contains(normalized) else { return }
        
        category.keywords.append(normalized)
        category.updatedAt = .now
        save()
    }
    
    /// Elimina una keyword de una categoría.
    ///
    /// - Parameters:
    ///   - keyword: Keyword a eliminar
    ///   - category: Categoría origen
    func removeKeyword(_ keyword: String, from category: Category) {
        category.keywords.removeAll { $0 == keyword }
        category.updatedAt = .now
        save()
    }
    
    // MARK: - Navigation Actions
    
    /// Presenta el editor en modo crear.
    ///
    /// - Parameters:
    ///   - type: Tipo sugerido para la nueva categoría
    ///   - parent: Categoría padre (para subcategorías)
    func presentCreate(type: CategoryType = .expense, parent: Category? = nil) {
        editorMode = .create
        parentForNewCategory = parent
        suggestedTypeForNewCategory = type
        selectedCategory = nil
        isEditorPresented = true
    }
    
    /// Presenta el editor en modo editar.
    ///
    /// - Parameter category: Categoría a editar
    func presentEdit(_ category: Category) {
        editorMode = .edit(category)
        selectedCategory = category
        parentForNewCategory = nil
        isEditorPresented = true
    }
    
    /// Presenta el sheet de detalle de categoría.
    ///
    /// - Parameter category: Categoría a mostrar
    func presentDetail(_ category: Category) {
        selectedCategory = category
        isDetailPresented = true
    }
    
    /// Presenta el alert de confirmación de archivo.
    ///
    /// - Parameter category: Categoría a archivar
    func presentArchiveAlert(_ category: Category) {
        categoryPendingAction = category
        isArchiveAlertPresented = true
    }
    
    /// Presenta el alert de confirmación de eliminación.
    ///
    /// - Parameter category: Categoría a eliminar
    func presentDeleteAlert(_ category: Category) {
        categoryPendingAction = category
        isDeleteAlertPresented = true
    }
    
    /// Cierra el editor y limpia estado.
    func dismissEditor() {
        isEditorPresented = false
        selectedCategory = nil
        parentForNewCategory = nil
        suggestedTypeForNewCategory = .expense
        editorMode = .create
    }
    
    /// Confirma y ejecuta el archivo pendiente.
    func confirmArchive() {
        guard let category = categoryPendingAction else { return }
        archiveCategory(category)
        cleanupPendingAction()
        isArchiveAlertPresented = false
    }
    
    /// Confirma y ejecuta la eliminación pendiente.
    func confirmDelete() {
        guard let category = categoryPendingAction else { return }
        deleteCategory(category)
        cleanupPendingAction()
        isDeleteAlertPresented = false
    }
    
    /// Cancela la acción pendiente.
    func cancelPendingAction() {
        cleanupPendingAction()
        isArchiveAlertPresented = false
        isDeleteAlertPresented = false
    }
    
    // MARK: - Private Helpers
    
    private func cleanupPendingAction() {
        categoryPendingAction = nil
    }
    
    @discardableResult
    private func requireContext() -> ModelContext? {
        guard let context = modelContext else {
            print("❌ CategoriesViewModel: ModelContext no configurado")
            return nil
        }
        return context
    }
    
    private func save() {
        do {
            try modelContext?.save()
        } catch {
            self.error = .saveFailed
            print("❌ CategoriesViewModel: Error al guardar - \(error)")
        }
    }
    
    /// Cuenta categorías de un tipo específico.
    private func countCategories(ofType type: CategoryType, in context: ModelContext) -> Int {
        let typeRaw = type.rawValue
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { category in
                category.parent == nil && category.typeRaw == typeRaw && !category.isArchived
            }
        )
        return (try? context.fetchCount(descriptor)) ?? 0
    }
    
    /// Calcula el siguiente sortOrder para una categoría.
    private func nextSortOrder(for type: CategoryType, in context: ModelContext) -> Int {
        let typeRaw = type.rawValue
        var descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { category in
                category.parent == nil && category.typeRaw == typeRaw
            }
        )
        descriptor.sortBy = [SortDescriptor(\Category.sortOrder, order: .reverse)]
        descriptor.fetchLimit = 1
        
        let existing = (try? context.fetch(descriptor)) ?? []
        return (existing.first?.sortOrder ?? -1) + 1
    }
    
    /// Crea categorías por defecto si es primera ejecución.
    private func seedDefaultCategoriesIfNeeded() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<Category>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        
        guard count == 0 else { return }
        
        // Primera vez: insertar categorías por defecto
        for category in Category.allDefaults() {
            context.insert(category)
        }
        
        save()
        
        if AppConfig.isDebugMode {
            print("✅ CategoriesViewModel: Categorías por defecto creadas")
        }
    }
}

// MARK: - Category Error

/// Errores posibles en operaciones de categoría.
enum CategoryError: Error, LocalizedError, Identifiable {
    case notFound
    case duplicateName
    case hasTransactions
    case cannotDeleteSystem
    case saveFailed
    case invalidData
    case limitReached
    
    var id: String { localizedDescription }
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Categoría no encontrada"
        case .duplicateName:
            return "Ya existe una categoría con ese nombre"
        case .hasTransactions:
            return "No puedes eliminar una categoría con transacciones. Archívala en su lugar."
        case .cannotDeleteSystem:
            return "Las categorías del sistema no se pueden eliminar"
        case .saveFailed:
            return "Error al guardar los cambios"
        case .invalidData:
            return "Datos inválidos"
        case .limitReached:
            return "Has alcanzado el límite de \(AppConfig.Limits.maxCategoriesPerType) categorías"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .hasTransactions:
            return "Usa la opción 'Archivar' en lugar de eliminar"
        case .saveFailed:
            return "Intenta de nuevo o reinicia la app"
        case .limitReached:
            return "Archiva algunas categorías que no uses"
        default:
            return nil
        }
    }
}
