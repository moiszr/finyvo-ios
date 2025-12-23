//
//  Category.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/11/25.
//  Refactored for Swift 6: Uses SF Symbols (FCategoryIcon) and FCardColor.
//

import SwiftUI
import SwiftData

// MARK: - Category Model

/// Modelo principal de categoría con soporte para SwiftData.
///
/// ## Arquitectura
/// - `iconRaw`: String persistido → `icon`: FCategoryIcon computed
/// - `colorRaw`: String persistido → `color`: FCardColor computed
/// - `typeRaw`: String persistido → `type`: CategoryType computed
///
/// ## Relaciones
/// - `parent`: Categoría padre (para subcategorías)
/// - `children`: Subcategorías (cascade delete)
@Model
final class Category {
    
    // MARK: - Persisted Properties
    
    /// Identificador único
    @Attribute(.unique)
    var id: UUID
    
    /// Nombre de la categoría
    var name: String
    
    /// SF Symbol - almacena rawValue de FCategoryIcon
    var iconRaw: String
    
    /// Color - almacena rawValue de FCardColor
    var colorRaw: String
    
    /// Tipo - almacena rawValue de CategoryType ("income" | "expense")
    var typeRaw: String
    
    /// Presupuesto mensual (opcional)
    var budget: Double?
    
    /// Keywords para auto-categorización
    var keywords: [String] = []
    
    /// `true` si es una categoría del sistema (no eliminable)
    var isSystem: Bool = false
    
    /// `true` si está archivada (soft delete)
    var isArchived: Bool = false
    
    /// `true` si está marcada como favorita
    var isFavorite: Bool = false
    
    /// Orden de visualización
    var sortOrder: Int = 0
    
    /// Fecha de creación
    var createdAt: Date
    
    /// Fecha de última actualización
    var updatedAt: Date
    
    // MARK: - Relationships
    
    /// Categoría padre (nil si es raíz)
    var parent: Category?
    
    /// Subcategorías
    @Relationship(deleteRule: .cascade, inverse: \Category.parent)
    var children: [Category]? = []
    
    // MARK: - Computed Properties (Type-Safe Access)
    
    /// Icono SF Symbol
    var icon: FCategoryIcon {
        get { FCategoryIcon(rawValue: iconRaw) ?? .other }
        set { iconRaw = newValue.rawValue }
    }
    
    /// Color de la categoría
    var color: FCardColor {
        get { FCardColor(rawValue: colorRaw) ?? .white }
        set { colorRaw = newValue.rawValue }
    }
    
    /// Tipo de categoría
    var type: CategoryType {
        get { CategoryType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }
    
    /// Nombre del SF Symbol para `Image(systemName:)`
    var systemImageName: String {
        icon.systemName
    }
    
    // MARK: - Hierarchy Helpers
    
    /// `true` si tiene subcategorías
    var hasChildren: Bool {
        guard let children else { return false }
        return !children.isEmpty
    }
    
    /// `true` si es una subcategoría
    var isChild: Bool {
        parent != nil
    }
    
    /// Subcategorías activas (no archivadas), ordenadas
    var activeChildren: [Category] {
        (children ?? [])
            .filter { !$0.isArchived }
            .sorted { $0.sortOrder < $1.sortOrder }
    }
    
    // MARK: - Budget Helpers
    
    /// `true` si tiene presupuesto definido
    var hasBudget: Bool {
        guard let budget else { return false }
        return budget > 0
    }
    
    // MARK: - Display Helpers
    
    /// Nombre completo incluyendo padre
    var fullName: String {
        if let parent {
            return "\(parent.name) > \(name)"
        }
        return name
    }
    
    /// Nombre para mostrar en listas
    var displayName: String {
        name
    }
    
    // MARK: - Initializer
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: FCategoryIcon,
        color: FCardColor,
        type: CategoryType,
        budget: Double? = nil,
        keywords: [String] = [],
        isSystem: Bool = false,
        isArchived: Bool = false,
        isFavorite: Bool = false,
        sortOrder: Int = 0,
        parent: Category? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.iconRaw = icon.rawValue
        self.colorRaw = color.rawValue
        self.typeRaw = type.rawValue
        self.budget = budget
        self.keywords = keywords
        self.isSystem = isSystem
        self.isArchived = isArchived
        self.isFavorite = isFavorite
        self.sortOrder = sortOrder
        self.parent = parent
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Category Type

/// Tipo de categoría: ingreso o gasto.
enum CategoryType: String, CaseIterable, Codable, Identifiable, Sendable {
    case income
    case expense
    
    var id: String { rawValue }
    
    /// Título localizado
    var title: String {
        switch self {
        case .income:  return "Ingresos"
        case .expense: return "Gastos"
        }
    }
    
    /// Título en singular
    var singularTitle: String {
        switch self {
        case .income:  return "Ingreso"
        case .expense: return "Gasto"
        }
    }
    
    /// Icono representativo
    var icon: FCategoryIcon {
        switch self {
        case .income:  return .salary
        case .expense: return .shopping
        }
    }
    
    /// SF Symbol name
    var systemImageName: String {
        switch self {
        case .income:  return "arrow.down.circle.fill"
        case .expense: return "arrow.up.circle.fill"
        }
    }
    
    /// Color sugerido por defecto
    var defaultColor: FCardColor {
        switch self {
        case .income:  return .green
        case .expense: return .red
        }
    }
}

// MARK: - Default Categories

extension Category {
    
    /// Categorías predeterminadas de gastos
    static func defaultExpenseCategories() -> [Category] {
        [
            Category(
                name: "Comida",
                icon: .food,
                color: .orange,
                type: .expense,
                keywords: ["restaurante", "uber eats", "rappi", "didi food", "supermercado"],
                isSystem: true,
                sortOrder: 0
            ),
            Category(
                name: "Transporte",
                icon: .transport,
                color: .blue,
                type: .expense,
                keywords: ["uber", "didi", "cabify", "gasolina", "gas", "metro"],
                isSystem: true,
                sortOrder: 1
            ),
            Category(
                name: "Entretenimiento",
                icon: .entertainment,
                color: .purple,
                type: .expense,
                keywords: ["netflix", "spotify", "disney", "hbo", "prime", "cine"],
                isSystem: true,
                sortOrder: 2
            ),
            Category(
                name: "Compras",
                icon: .shopping,
                color: .pink,
                type: .expense,
                keywords: ["amazon", "mercadolibre", "shein", "tienda"],
                isSystem: true,
                sortOrder: 3
            ),
            Category(
                name: "Servicios",
                icon: .services,
                color: .yellow,
                type: .expense,
                keywords: ["luz", "agua", "internet", "telefono", "celular", "cable"],
                isSystem: true,
                sortOrder: 4
            ),
            Category(
                name: "Salud",
                icon: .health,
                color: .red,
                type: .expense,
                keywords: ["farmacia", "doctor", "hospital", "medicina", "seguro"],
                isSystem: true,
                sortOrder: 5
            ),
            Category(
                name: "Educación",
                icon: .education,
                color: .teal,
                type: .expense,
                keywords: ["curso", "libro", "universidad", "escuela", "udemy"],
                isSystem: true,
                sortOrder: 6
            ),
            Category(
                name: "Hogar",
                icon: .home,
                color: .orange,
                type: .expense,
                keywords: ["renta", "alquiler", "hipoteca", "muebles", "decoracion"],
                isSystem: true,
                sortOrder: 7
            ),
            Category(
                name: "Ropa",
                icon: .clothing,
                color: .pink,
                type: .expense,
                keywords: ["zara", "h&m", "nike", "adidas", "ropa"],
                isSystem: true,
                sortOrder: 8
            ),
            Category(
                name: "Otros",
                icon: .other,
                color: .blue,
                type: .expense,
                isSystem: true,
                sortOrder: 99
            )
        ]
    }
    
    /// Categorías predeterminadas de ingresos
    static func defaultIncomeCategories() -> [Category] {
        [
            Category(
                name: "Salario",
                icon: .salary,
                color: .green,
                type: .income,
                keywords: ["nomina", "sueldo", "pago", "quincena"],
                isSystem: true,
                sortOrder: 0
            ),
            Category(
                name: "Freelance",
                icon: .freelance,
                color: .blue,
                type: .income,
                keywords: ["proyecto", "cliente", "consultoría"],
                isSystem: true,
                sortOrder: 1
            ),
            Category(
                name: "Inversiones",
                icon: .investments,
                color: .teal,
                type: .income,
                keywords: ["dividendo", "intereses", "rendimiento", "acciones"],
                isSystem: true,
                sortOrder: 2
            ),
            Category(
                name: "Regalos",
                icon: .gifts,
                color: .pink,
                type: .income,
                keywords: ["regalo", "cumpleaños", "navidad"],
                isSystem: true,
                sortOrder: 3
            ),
            Category(
                name: "Reembolsos",
                icon: .refund,
                color: .yellow,
                type: .income,
                keywords: ["devolucion", "reembolso", "cashback"],
                isSystem: true,
                sortOrder: 4
            ),
            Category(
                name: "Otros",
                icon: .other,
                color: .blue,
                type: .income,
                isSystem: true,
                sortOrder: 99
            )
        ]
    }
    
    /// Todas las categorías predeterminadas
    static func allDefaults() -> [Category] {
        defaultExpenseCategories() + defaultIncomeCategories()
    }
}

// MARK: - FCardData Conversion

extension Category {
    
    /// Convierte la categoría a FCardData para usar en FCardCategoryView
    func toCardData(spent: Double = 0, transactionCount: Int = 0) -> FCardData {
        FCardData(
            name: name,
            icon: icon,
            color: color,
            budget: budget,
            spent: spent,
            isFavorite: isFavorite,
            transactionCount: transactionCount
        )
    }
}
