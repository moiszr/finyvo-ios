//
//  CategoryEditorMode.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/11/25.
//  Refactored for Swift 6 and simplified Category model.
//

import Foundation

// MARK: - Category Editor Mode

/// Modo del editor de categorías.
///
/// Determina si estamos creando una nueva categoría o editando una existente.
/// Usado por `CategoryEditorViewModel` para configurar el formulario.
enum CategoryEditorMode: Equatable {
    case create
    case edit(Category)
    
    // MARK: - Computed Properties
    
    /// `true` si estamos editando una categoría existente.
    var isEditing: Bool {
        if case .edit = self { return true }
        return false
    }
    
    /// `true` si estamos creando una nueva categoría.
    var isCreating: Bool {
        self == .create
    }
    
    /// Categoría que se está editando (`nil` en modo crear).
    var category: Category? {
        if case .edit(let category) = self {
            return category
        }
        return nil
    }
    
    /// Título para la navegación.
    var navigationTitle: String {
        switch self {
        case .create:
            return "Nueva categoría"
        case .edit:
            return "Editar categoría"
        }
    }
    
    /// Texto del botón de acción principal.
    var actionButtonTitle: String {
        switch self {
        case .create:
            return "Crear"
        case .edit:
            return "Guardar"
        }
    }
    
    // MARK: - Equatable
    
    static func == (lhs: CategoryEditorMode, rhs: CategoryEditorMode) -> Bool {
        switch (lhs, rhs) {
        case (.create, .create):
            return true
        case (.edit(let lhsCategory), .edit(let rhsCategory)):
            return lhsCategory.id == rhsCategory.id
        default:
            return false
        }
    }
}
