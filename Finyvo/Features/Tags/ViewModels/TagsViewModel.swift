//
//  TagsViewModel.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/24/25.
//  ViewModel para gestión de etiquetas.
//  Integrated with Constants.Haptic and AppConfig.
//

import SwiftUI
import SwiftData

// MARK: - Tags ViewModel

/// ViewModel para la gestión de etiquetas.
///
/// ## Responsabilidades
/// - CRUD de tags via SwiftData
/// - Estado del sheet de tags
/// - Validación de nombres
///
/// ## Uso
/// ```swift
/// @State private var tagsVM = TagsViewModel()
///
/// .onAppear {
///     tagsVM.configure(with: modelContext)
/// }
/// ```
@Observable
final class TagsViewModel {
    
    // MARK: - Dependencies
    
    private var modelContext: ModelContext?
    
    // MARK: - State
    
    /// Tags disponibles (cargados desde SwiftData)
    private(set) var tags: [Tag] = []
    
    /// Input para nueva etiqueta
    var newTagInput: String = ""
    
    /// Color seleccionado para nueva etiqueta
    var selectedColor: FCardColor = .blue
    
    /// Error actual
    var error: TagError? = nil
    
    /// Estado de carga
    private(set) var isLoading: Bool = false
    
    /// `true` si el ViewModel está configurado
    var isConfigured: Bool {
        modelContext != nil
    }
    
    // MARK: - Sheet State
    
    /// Controla visibilidad del sheet de tags
    var isPresented: Bool = false
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Configuration
    
    /// Configura el ModelContext.
    func configure(with context: ModelContext) {
        // Permitir reconfiguración si es el mismo contexto
        if modelContext === context { return }
        
        modelContext = context
        loadTags()
    }
    
    // MARK: - Load Tags
    
    /// Carga todos los tags desde SwiftData.
    func loadTags() {
        guard let context = modelContext else {
            if AppConfig.isDebugMode {
                print("⚠️ TagsViewModel: ModelContext no configurado, saltando loadTags")
            }
            return
        }
        
        let descriptor = FetchDescriptor<Tag>(
            sortBy: [SortDescriptor(\Tag.name, order: .forward)]
        )
        
        do {
            tags = try context.fetch(descriptor)
        } catch {
            if AppConfig.isDebugMode {
                print("❌ TagsViewModel: Error cargando tags - \(error)")
            }
            self.error = .loadFailed
        }
    }
    
    // MARK: - CRUD Operations
    
    /// Crea una nueva etiqueta.
    ///
    /// - Parameters:
    ///   - name: Nombre de la etiqueta
    ///   - color: Color opcional (default: selectedColor)
    /// - Returns: Tag creado o nil si falló
    @discardableResult
    func createTag(name: String, color: FCardColor? = nil) -> Tag? {
        guard let context = modelContext else {
            if AppConfig.isDebugMode {
                print("❌ TagsViewModel: No se puede crear tag - ModelContext no configurado")
            }
            error = .saveFailed
            return nil
        }
        
        // Normalizar nombre
        guard let normalized = Tag.normalize(name) else {
            error = .invalidName
            Task { @MainActor in Constants.Haptic.error() }
            return nil
        }
        
        // Verificar duplicado
        if tags.contains(where: { $0.name == normalized }) {
            error = .duplicateName
            Task { @MainActor in Constants.Haptic.warning() }
            return nil
        }
        
        let tag = Tag(
            name: normalized,
            color: color ?? selectedColor
        )
        
        context.insert(tag)
        save()
        loadTags()
        
        // Reset input
        newTagInput = ""
        // No resetear color para permitir crear varios del mismo color
        
        Task { @MainActor in Constants.Haptic.success() }
        return tag
    }
    
    /// Crea un tag desde el input actual.
    @discardableResult
    func createTagFromInput() -> Tag? {
        createTag(name: newTagInput)
    }
    
    /// Elimina una etiqueta.
    ///
    /// - Parameter tag: Etiqueta a eliminar
    func deleteTag(_ tag: Tag) {
        guard let context = modelContext else {
            if AppConfig.isDebugMode {
                print("❌ TagsViewModel: No se puede eliminar tag - ModelContext no configurado")
            }
            return
        }
        
        context.delete(tag)
        save()
        loadTags()
        Task { @MainActor in Constants.Haptic.success() }
    }
    
    /// Actualiza el color de una etiqueta.
    ///
    /// - Parameters:
    ///   - tag: Etiqueta a actualizar
    ///   - color: Nuevo color
    func updateColor(_ tag: Tag, to color: FCardColor) {
        tag.color = color
        tag.updatedAt = .now
        save()
        loadTags()
        Task { @MainActor in Constants.Haptic.light() }
    }
    
    /// Actualiza el nombre de una etiqueta.
    ///
    /// - Parameters:
    ///   - tag: Etiqueta a actualizar
    ///   - name: Nuevo nombre
    /// - Returns: `true` si se actualizó correctamente
    @discardableResult
    func updateName(_ tag: Tag, to name: String) -> Bool {
        guard let normalized = Tag.normalize(name) else {
            error = .invalidName
            return false
        }
        
        // Verificar duplicado (excluyendo el tag actual)
        if tags.contains(where: { $0.id != tag.id && $0.name == normalized }) {
            error = .duplicateName
            return false
        }
        
        tag.name = normalized
        tag.updatedAt = .now
        save()
        loadTags()
        Task { @MainActor in Constants.Haptic.light() }
        return true
    }
    
    // MARK: - Presentation
    
    /// Presenta el sheet de tags.
    func present() {
        loadTags() // Refresh
        isPresented = true
    }
    
    /// Cierra el sheet de tags.
    func dismiss() {
        isPresented = false
        newTagInput = ""
        error = nil
    }
    
    // MARK: - Validation
    
    /// `true` si el input actual es válido para crear tag
    var isInputValid: Bool {
        Tag.isValid(newTagInput)
    }
    
    /// `true` si el input ya existe como tag
    var inputAlreadyExists: Bool {
        guard let normalized = Tag.normalize(newTagInput) else { return false }
        return tags.contains { $0.name == normalized }
    }
    
    /// Límite de tags por transacción
    var maxTagsPerTransaction: Int {
        AppConfig.Limits.maxTagsPerTransaction
    }
    
    // MARK: - Private Helpers
    
    private func save() {
        guard let context = modelContext else {
            if AppConfig.isDebugMode {
                print("❌ TagsViewModel: No se puede guardar - ModelContext no configurado")
            }
            error = .saveFailed
            return
        }
        
        do {
            try context.save()
        } catch {
            self.error = .saveFailed
            if AppConfig.isDebugMode {
                print("❌ TagsViewModel: Error al guardar - \(error)")
            }
        }
    }
}

// MARK: - Tag Error

enum TagError: Error, LocalizedError, Identifiable {
    case invalidName
    case duplicateName
    case saveFailed
    case loadFailed
    case limitReached
    
    var id: String { localizedDescription }
    
    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "El nombre debe tener entre \(AppConfig.Limits.minTagNameLength) y \(AppConfig.Limits.maxTagNameLength) caracteres"
        case .duplicateName:
            return "Ya existe una etiqueta con ese nombre"
        case .saveFailed:
            return "Error al guardar los cambios"
        case .loadFailed:
            return "Error al cargar las etiquetas"
        case .limitReached:
            return "Máximo \(AppConfig.Limits.maxTagsPerTransaction) etiquetas por transacción"
        }
    }
}
