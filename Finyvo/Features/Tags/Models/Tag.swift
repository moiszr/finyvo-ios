//
//  Tag.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/24/25.
//  Modelo de etiquetas transversales para transacciones.
//  Integrated with AppConfig.Limits.
//

import SwiftUI
import SwiftData

// MARK: - Tag Model

/// Etiquetas adicionales para clasificar transacciones.
///
/// ## Diferencia con Category
/// - **Category**: Clasificación principal obligatoria (1 por transacción)
/// - **Tag**: Etiquetas opcionales múltiples (N por transacción)
///
/// ## Ejemplos
/// - `#arroz`, `#lissa`, `#urgente`, `#trabajo`, `#vacaciones`
///
/// ## Uso
/// ```swift
/// let tag = Tag(name: "urgente", color: .red)
/// transaction.tags?.append(tag)
/// ```
@Model
final class Tag {
    
    // MARK: - Persisted Properties
    
    /// Identificador único
    @Attribute(.unique)
    var id: UUID
    
    /// Nombre de la etiqueta (sin #, se agrega en display)
    var name: String
    
    /// Color - almacena rawValue de FCardColor
    var colorRaw: String
    
    /// Fecha de creación
    var createdAt: Date
    
    /// Fecha de última actualización
    var updatedAt: Date
    
    // MARK: - Relationships
    
    /// Transacciones que tienen esta etiqueta (many-to-many)
    /// Se define la relación inversa en Transaction.tags
    // @Relationship(inverse: \Transaction.tags)
    // var transactions: [Transaction]? = []
    
    // MARK: - Computed Properties
    
    /// Color de la etiqueta
    var color: FCardColor {
        get { FCardColor(rawValue: colorRaw) ?? .blue }
        set { colorRaw = newValue.rawValue }
    }
    
    /// Nombre con # para display
    var displayName: String {
        "#\(name)"
    }
    
    /// `true` si el nombre tiene longitud válida
    var hasValidName: Bool {
        name.count >= AppConfig.Limits.minTagNameLength &&
        name.count <= AppConfig.Limits.maxTagNameLength
    }
    
    // MARK: - Initializer
    
    init(
        id: UUID = UUID(),
        name: String,
        color: FCardColor = .blue,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        // Normalizar el nombre al crear
        self.name = Tag.normalize(name) ?? name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        self.colorRaw = color.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Tag Validation

extension Tag {
    
    /// Valida que el nombre sea válido para una etiqueta.
    ///
    /// - Parameter name: Nombre a validar
    /// - Returns: Nombre normalizado o nil si inválido
    static func normalize(_ name: String) -> String? {
        var normalized = name
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: " ", with: "_")
        
        // Remover caracteres especiales excepto underscore y guión
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
        normalized = normalized.unicodeScalars
            .filter { allowed.contains($0) }
            .map { String($0) }
            .joined()
        
        // Usar límites de AppConfig
        guard normalized.count >= AppConfig.Limits.minTagNameLength else { return nil }
        
        // Máximo caracteres
        if normalized.count > AppConfig.Limits.maxTagNameLength {
            normalized = String(normalized.prefix(AppConfig.Limits.maxTagNameLength))
        }
        
        return normalized
    }
    
    /// `true` si el nombre es válido
    static func isValid(_ name: String) -> Bool {
        normalize(name) != nil
    }
    
    /// Mensaje de error para validación
    static var validationHint: String {
        "Entre \(AppConfig.Limits.minTagNameLength) y \(AppConfig.Limits.maxTagNameLength) caracteres"
    }
}

// MARK: - Default Tags

extension Tag {
    
    /// Etiquetas sugeridas para onboarding
    static func suggestedTags() -> [Tag] {
        [
            Tag(name: "urgente", color: .red),
            Tag(name: "trabajo", color: .blue),
            Tag(name: "personal", color: .purple),
            Tag(name: "familia", color: .pink),
            Tag(name: "ahorro", color: .green),
            Tag(name: "vacaciones", color: .teal),
        ]
    }
}
