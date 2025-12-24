//
//  CategoryEditorViewModel.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/11/25.
//  Refactored for Swift 6 with FCategoryIcon and FCardColor support.
//  Integrated with Constants.Haptic and AppConfig.Limits.
//

import SwiftUI

// MARK: - Category Editor ViewModel

/// ViewModel para el formulario de crear/editar categoría.
///
/// ## Características
/// - Usa `FCategoryIcon` (SF Symbols) en lugar de emojis
/// - Usa `FCardColor` (10 colores) en lugar de colorHex
/// - Autosugerencia de icono basada en nombre
/// - Validación de formulario con `AppConfig.Limits`
///
/// ## Uso
/// ```swift
/// @State private var editorVM = CategoryEditorViewModel(mode: .create)
/// // o
/// @State private var editorVM = CategoryEditorViewModel(editing: category)
/// ```
@Observable
final class CategoryEditorViewModel {
    
    // MARK: - Mode
    
    /// Modo del editor (crear o editar)
    let mode: CategoryEditorMode
    
    // MARK: - Form Fields
    
    /// Nombre de la categoría
    var name: String = "" {
        didSet {
            guard oldValue != name else { return }
            
            // Limitar longitud
            if name.count > AppConfig.Limits.maxCategoryNameLength {
                name = String(name.prefix(AppConfig.Limits.maxCategoryNameLength))
            }
            
            // Auto-sugerir icono si no fue seleccionado manualmente
            if !iconSetManually {
                updateSuggestedIcon()
            }
        }
    }
    
    /// Icono SF Symbol seleccionado
    var icon: FCategoryIcon = .other {
        didSet {
            guard oldValue != icon else { return }
        }
    }
    
    /// Color seleccionado
    var color: FCardColor = .blue
    
    /// Tipo de categoría (ingreso/gasto)
    var type: CategoryType = .expense {
        didSet {
            guard oldValue != type else { return }
            // El tipo solo cambia el tipo, el color se mantiene.
        }
    }
    
    /// Presupuesto habilitado
    var budgetEnabled: Bool = false
    
    /// Monto del presupuesto como string (para input)
    var budgetAmount: String = ""
    
    /// Keywords para auto-categorización
    var keywords: [String] = []
    
    /// Input actual para nueva keyword
    var newKeywordInput: String = ""
    
    // MARK: - Manual Selection Tracking
    
    /// `true` si el usuario seleccionó el icono manualmente
    private(set) var iconSetManually: Bool = false
    
    /// `true` si el usuario seleccionó el color manualmente
    private(set) var colorSetManually: Bool = false
    
    // MARK: - UI State
    
    /// Controla visibilidad del picker de icono
    var isIconPickerPresented: Bool = false
    
    /// Controla visibilidad del picker de color
    var isColorPickerPresented: Bool = false
    
    /// Error de validación actual
    var validationError: String? = nil
    
    // MARK: - Computed Properties
    
    /// `true` si estamos editando una categoría existente
    var isEditing: Bool {
        mode.isEditing
    }
    
    /// `true` si es una categoría del sistema (no editable en tipo)
    var isSystemCategory: Bool {
        mode.category?.isSystem ?? false
    }
    
    /// Presupuesto como Double (nil si no habilitado o inválido)
    var budget: Double? {
        guard budgetEnabled else { return nil }
        
        // Usar el parser de la moneda actual para manejar separadores correctamente
        let currency = CurrencyConfig.defaultCurrency
        if let parsed = currency.parse(budgetAmount), parsed > 0 {
            return parsed
        }
        
        // Fallback: normalización básica
        let normalized = budgetAmount
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        
        guard !normalized.isEmpty,
              let value = Double(normalized),
              value > 0 else { return nil }
        
        return value
    }
    
    /// `true` si el formulario tiene datos válidos
    var isValid: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 2 && trimmed.count <= AppConfig.Limits.maxCategoryNameLength
    }
    
    /// `true` si hay cambios respecto al estado original
    var hasChanges: Bool {
        guard let original = mode.category else {
            // Modo crear: hay cambios si tiene nombre válido
            return name.trimmingCharacters(in: .whitespaces).count >= 2
        }
        
        // Modo editar: comparar con original
        return name.trimmingCharacters(in: .whitespaces) != original.name ||
               icon != original.icon ||
               color != original.color ||
               type != original.type ||
               budget != original.budget ||
               Set(keywords) != Set(original.keywords)
    }
    
    /// Contador de keywords para UI
    var keywordsCount: Int {
        keywords.count
    }
    
    /// Límite de keywords
    var keywordsLimit: Int {
        AppConfig.Limits.maxKeywordsPerCategory
    }
    
    /// `true` si se alcanzó el límite de keywords
    var isKeywordsLimitReached: Bool {
        keywords.count >= AppConfig.Limits.maxKeywordsPerCategory
    }
    
    // MARK: - Initialization
    
    /// Inicializa el ViewModel con un modo específico.
    ///
    /// - Parameter mode: Modo del editor (.create o .edit)
    init(mode: CategoryEditorMode) {
        self.mode = mode
        
        if let category = mode.category {
            populateFromCategory(category)
        } else {
            applyDefaults()
        }
    }
    
    /// Inicializa en modo crear.
    convenience init() {
        self.init(mode: .create)
    }
    
    /// Inicializa en modo crear con tipo sugerido.
    ///
    /// - Parameter suggestedType: Tipo inicial para la categoría
    convenience init(suggestedType: CategoryType) {
        self.init(mode: .create)
        self.type = suggestedType
    }
    
    /// Inicializa en modo editar.
    ///
    /// - Parameter category: Categoría a editar
    convenience init(editing category: Category) {
        self.init(mode: .edit(category))
    }
    
    // MARK: - Setup Helpers
    
    private func populateFromCategory(_ category: Category) {
        name = category.name
        icon = category.icon
        color = category.color
        type = category.type
        keywords = category.keywords
        
        if category.hasBudget, let existingBudget = category.budget {
            budgetEnabled = true
            budgetAmount = formatBudgetForInput(existingBudget)
        }
        
        // En modo edición, asumimos selección manual
        iconSetManually = true
        colorSetManually = true
    }
    
    private func applyDefaults() {
        icon = .other
        color = .white
        type = .expense
        iconSetManually = false
        colorSetManually = false
    }
    
    private func formatBudgetForInput(_ value: Double) -> String {
        // Usar dígitos decimales de la moneda actual
        let currency = CurrencyConfig.defaultCurrency
        if value == floor(value) {
            return String(format: "%.0f", value)
        }
        return String(format: "%.\(currency.decimalDigits)f", value)
    }
    
    // MARK: - Icon Actions
    
    /// Selecciona un icono manualmente.
    ///
    /// - Parameter newIcon: Icono a seleccionar
    func selectIcon(_ newIcon: FCategoryIcon) {
        icon = newIcon
        iconSetManually = true
        isIconPickerPresented = false
        Task { @MainActor in Constants.Haptic.light() }
    }
    
    /// Resetea el icono a la sugerencia automática.
    func resetIconToSuggestion() {
        iconSetManually = false
        updateSuggestedIcon()
    }
    
    /// Actualiza el icono basándose en el nombre.
    private func updateSuggestedIcon() {
        let suggested = IconSuggestionEngine.suggestIcon(for: name)
        if suggested != icon {
            icon = suggested
        }
    }
    
    // MARK: - Color Actions
    
    /// Selecciona un color manualmente.
    ///
    /// - Parameter newColor: Color a seleccionar
    func selectColor(_ newColor: FCardColor) {
        color = newColor
        colorSetManually = true
        isColorPickerPresented = false
        Task { @MainActor in Constants.Haptic.light() }
    }
    
    /// Resetea el color a la sugerencia automática.
    func resetColorToSuggestion() {
        colorSetManually = false
    }
    
    // MARK: - Type Actions
    
    /// Selecciona el tipo de categoría.
    ///
    /// - Parameter newType: Tipo a seleccionar
    func selectType(_ newType: CategoryType) {
        guard !isSystemCategory else { return }
        type = newType
        Task { @MainActor in Constants.Haptic.light() }
    }
    
    // MARK: - Keyword Actions
    
    /// Agrega la keyword actual del input.
    func addKeyword() {
        // Verificar límite
        guard !isKeywordsLimitReached else {
            Task { @MainActor in Constants.Haptic.warning() }
            return
        }
        
        let normalized = newKeywordInput
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        
        guard !normalized.isEmpty,
              !keywords.contains(normalized) else {
            newKeywordInput = ""
            return
        }
        
        keywords.append(normalized)
        newKeywordInput = ""
        Task { @MainActor in Constants.Haptic.light() }
    }
    
    /// Elimina una keyword.
    ///
    /// - Parameter keyword: Keyword a eliminar
    func removeKeyword(_ keyword: String) {
        keywords.removeAll { $0 == keyword }
    }
    
    // MARK: - Validation
    
    /// Valida el formulario.
    ///
    /// - Returns: `true` si es válido
    @discardableResult
    func validate() -> Bool {
        clearError()
        
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        
        if trimmedName.isEmpty {
            validationError = "El nombre es requerido"
            return false
        }
        
        if trimmedName.count < 2 {
            validationError = "El nombre debe tener al menos 2 caracteres"
            return false
        }
        
        if trimmedName.count > AppConfig.Limits.maxCategoryNameLength {
            validationError = "El nombre no puede exceder \(AppConfig.Limits.maxCategoryNameLength) caracteres"
            return false
        }
        
        if budgetEnabled && budget == nil && !budgetAmount.isEmpty {
            validationError = "El presupuesto debe ser un número válido mayor a 0"
            return false
        }
        
        return true
    }
    
    /// Limpia el error de validación.
    func clearError() {
        validationError = nil
    }
    
    // MARK: - Save Actions
    
    /// Aplica los cambios a una categoría existente.
    ///
    /// - Parameter category: Categoría a actualizar
    /// - Returns: `true` si se aplicaron los cambios
    func applyChanges(to category: Category) -> Bool {
        guard validate() else { return false }
        
        category.name = String(name.trimmingCharacters(in: .whitespaces).prefix(AppConfig.Limits.maxCategoryNameLength))
        category.icon = icon
        category.color = color
        
        if !isSystemCategory {
            category.type = type
        }
        
        category.budget = budget
        category.keywords = Array(keywords.prefix(AppConfig.Limits.maxKeywordsPerCategory))
        category.updatedAt = .now
        
        return true
    }
    
    /// Construye los datos para crear una nueva categoría.
    ///
    /// - Returns: Tupla con los datos validados, o `nil` si inválido
    func buildNewCategoryData() -> NewCategoryData? {
        guard validate() else { return nil }
        
        return NewCategoryData(
            name: String(name.trimmingCharacters(in: .whitespaces).prefix(AppConfig.Limits.maxCategoryNameLength)),
            icon: icon,
            color: color,
            type: type,
            budget: budget,
            keywords: Array(keywords.prefix(AppConfig.Limits.maxKeywordsPerCategory))
        )
    }
}

// MARK: - New Category Data

/// Datos validados para crear una nueva categoría.
struct NewCategoryData {
    let name: String
    let icon: FCategoryIcon
    let color: FCardColor
    let type: CategoryType
    let budget: Double?
    let keywords: [String]
}

// MARK: - Icon Suggestion Engine

/// Motor de sugerencias para iconos basado en el nombre.
enum IconSuggestionEngine {
    
    // MARK: - Icon Suggestions
    
    /// Sugiere un icono basándose en el nombre de la categoría.
    ///
    /// - Parameter name: Nombre de la categoría
    /// - Returns: Icono sugerido
    static func suggestIcon(for name: String) -> FCategoryIcon {
        let lowercased = name.lowercased()
        
        // Comida
        if matches(lowercased, ["comida", "food", "restaurante", "almuerzo", "cena", "desayuno", "cafe", "coffee"]) {
            return .food
        }
        
        // Transporte
        if matches(lowercased, ["transporte", "transport", "uber", "taxi", "gasolina", "gas", "carro", "auto", "vehiculo"]) {
            return .transport
        }
        
        // Entretenimiento
        if matches(lowercased, ["entretenimiento", "entertainment", "netflix", "spotify", "cine", "peliculas", "juegos", "gaming"]) {
            return .entertainment
        }
        
        // Compras
        if matches(lowercased, ["compras", "shopping", "amazon", "tienda", "store", "mercado"]) {
            return .shopping
        }
        
        // Servicios
        if matches(lowercased, ["servicios", "services", "luz", "agua", "internet", "telefono", "celular", "utilities"]) {
            return .services
        }
        
        // Salud
        if matches(lowercased, ["salud", "health", "medico", "doctor", "farmacia", "medicina", "hospital", "gym", "gimnasio"]) {
            return .health
        }
        
        // Educación
        if matches(lowercased, ["educacion", "education", "curso", "escuela", "universidad", "libro", "books", "estudio"]) {
            return .education
        }
        
        // Hogar
        if matches(lowercased, ["hogar", "home", "casa", "renta", "alquiler", "hipoteca", "muebles", "decoracion"]) {
            return .home
        }
        
        // Ropa
        if matches(lowercased, ["ropa", "clothing", "vestimenta", "zapatos", "shoes", "moda", "fashion"]) {
            return .clothing
        }
        
        // Salario
        if matches(lowercased, ["salario", "salary", "sueldo", "nomina", "ingreso", "income", "pago"]) {
            return .salary
        }
        
        // Freelance
        if matches(lowercased, ["freelance", "proyecto", "project", "consultoria", "trabajo", "work"]) {
            return .freelance
        }
        
        // Inversiones
        if matches(lowercased, ["inversion", "investment", "acciones", "stocks", "dividendo", "crypto", "trading"]) {
            return .investments
        }
        
        // Regalos
        if matches(lowercased, ["regalo", "gift", "cumpleaños", "birthday", "navidad", "christmas"]) {
            return .gifts
        }
        
        // Reembolsos
        if matches(lowercased, ["reembolso", "refund", "devolucion", "return", "cashback"]) {
            return .refund
        }
        
        return .other
    }
    
    // MARK: - Helpers
    
    private static func matches(_ text: String, _ keywords: [String]) -> Bool {
        for keyword in keywords {
            if text.contains(keyword) {
                return true
            }
        }
        return false
    }
}
