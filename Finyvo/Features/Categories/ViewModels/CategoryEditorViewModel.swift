//
//  CategoryEditorViewModel.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/11/25.
//  Refactored for Swift 6 with FCategoryIcon and FCardColor support.
//

import SwiftUI

// MARK: - Category Editor ViewModel

/// ViewModel para el formulario de crear/editar categoría.
///
/// ## Características
/// - Usa `FCategoryIcon` (SF Symbols) en lugar de emojis
/// - Usa `FCardColor` (8 colores) en lugar de colorHex
/// - Autosugerencia de icono basada en nombre
/// - Autosugerencia de color basada en tipo
/// - Validación de formulario
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
            
            // Auto-sugerir color si no fue seleccionado manualmente
            if !colorSetManually {
                updateSuggestedColor()
            }
        }
    }
    
    /// Color seleccionado
    var color: FCardColor = .blue
    
    /// Tipo de categoría (ingreso/gasto)
    var type: CategoryType = .expense {
        didSet {
            guard oldValue != type else { return }
            
            // Actualizar color sugerido si no fue manual
            if !colorSetManually {
                updateSuggestedColor()
            }
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
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    /// `true` si hay cambios respecto al estado original
    var hasChanges: Bool {
        guard let original = mode.category else {
            // Modo crear: hay cambios si tiene nombre
            return !name.trimmingCharacters(in: .whitespaces).isEmpty
        }
        
        // Modo editar: comparar con original
        return name.trimmingCharacters(in: .whitespaces) != original.name ||
               icon != original.icon ||
               color != original.color ||
               type != original.type ||
               budget != original.budget ||
               Set(keywords) != Set(original.keywords)
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
        updateSuggestedColor()
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
        color = .blue
        type = .expense
        iconSetManually = false
        colorSetManually = false
    }
    
    private func formatBudgetForInput(_ value: Double) -> String {
        if value == floor(value) {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }
    
    // MARK: - Icon Actions
    
    /// Selecciona un icono manualmente.
    ///
    /// - Parameter newIcon: Icono a seleccionar
    func selectIcon(_ newIcon: FCategoryIcon) {
        icon = newIcon
        iconSetManually = true
        isIconPickerPresented = false
        hapticLight()
    }
    
    /// Resetea el icono a la sugerencia automática.
    func resetIconToSuggestion() {
        iconSetManually = false
        updateSuggestedIcon()
        
        if !colorSetManually {
            updateSuggestedColor()
        }
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
        hapticLight()
    }
    
    /// Resetea el color a la sugerencia automática.
    func resetColorToSuggestion() {
        colorSetManually = false
        updateSuggestedColor()
    }
    
    /// Actualiza el color basándose en el icono y tipo.
    private func updateSuggestedColor() {
        color = IconSuggestionEngine.suggestColor(for: icon, type: type)
    }
    
    // MARK: - Type Actions
    
    /// Selecciona el tipo de categoría.
    ///
    /// - Parameter newType: Tipo a seleccionar
    func selectType(_ newType: CategoryType) {
        guard !isSystemCategory else { return }
        type = newType
        hapticLight()
    }
    
    // MARK: - Keyword Actions
    
    /// Agrega la keyword actual del input.
    func addKeyword() {
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
        hapticLight()
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
        
        category.name = name.trimmingCharacters(in: .whitespaces)
        category.icon = icon
        category.color = color
        
        if !isSystemCategory {
            category.type = type
        }
        
        category.budget = budget
        category.keywords = keywords
        category.updatedAt = .now
        
        return true
    }
    
    /// Construye los datos para crear una nueva categoría.
    ///
    /// - Returns: Tupla con los datos validados, o `nil` si inválido
    func buildNewCategoryData() -> NewCategoryData? {
        guard validate() else { return nil }
        
        return NewCategoryData(
            name: name.trimmingCharacters(in: .whitespaces),
            icon: icon,
            color: color,
            type: type,
            budget: budget,
            keywords: keywords
        )
    }
    
    // MARK: - Haptics
    
    private func hapticLight() {
        Task { @MainActor in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
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

/// Motor de sugerencias para iconos y colores basado en el nombre.
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
    
    // MARK: - Color Suggestions
    
    /// Sugiere un color basándose en el icono y tipo.
    ///
    /// - Parameters:
    ///   - icon: Icono seleccionado
    ///   - type: Tipo de categoría
    /// - Returns: Color sugerido
    static func suggestColor(for icon: FCategoryIcon, type: CategoryType) -> FCardColor {
        // Primero intentar por icono
        switch icon {
        case .food:
            return .orange
        case .transport:
            return .blue
        case .entertainment:
            return .purple
        case .shopping:
            return .pink
        case .services:
            return .yellow
        case .health:
            return .red
        case .education:
            return .teal
        case .home:
            return .orange
        case .clothing:
            return .pink
        case .salary:
            return .green
        case .freelance:
            return .blue
        case .investments:
            return .teal
        case .gifts:
            return .pink
        case .refund:
            return .yellow
        case .other:
            // Fallback por tipo
            return type == .income ? .green : .blue
        }
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
