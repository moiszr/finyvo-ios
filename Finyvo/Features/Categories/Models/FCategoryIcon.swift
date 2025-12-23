//
//  FCategoryIcon.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/22/25.
//  Global definition of category icons.
//

import SwiftUI

/// Iconos SF Symbols para categorías
enum FCategoryIcon: String, CaseIterable, Codable, Sendable {
    // Gastos
    case food = "fork.knife"
    case transport = "car.fill"
    case entertainment = "tv.fill"
    case shopping = "bag.fill"
    case services = "bolt.fill"
    case health = "heart.fill"
    case education = "book.fill"
    case home = "house.fill"
    case clothing = "tshirt.fill"
    
    // Ingresos
    case salary = "banknote.fill"
    case freelance = "laptopcomputer"
    case investments = "chart.line.uptrend.xyaxis"
    case gifts = "gift.fill"
    case refund = "arrow.uturn.backward"
    
    // Genérico
    case other = "square.grid.2x2.fill"
    
    var systemName: String { rawValue }
    
    /// Nombre legible para el usuario
    var displayName: String {
        switch self {
        case .food: return "Comida"
        case .transport: return "Transporte"
        case .entertainment: return "Ocio"
        case .shopping: return "Compras"
        case .services: return "Servicios"
        case .health: return "Salud"
        case .education: return "Educación"
        case .home: return "Hogar"
        case .clothing: return "Ropa"
        case .salary: return "Salario"
        case .freelance: return "Freelance"
        case .investments: return "Inversiones"
        case .gifts: return "Regalos"
        case .refund: return "Reembolsos"
        case .other: return "Otros"
        }
    }
    
    /// Lista ordenada personalizada para selectores
    static var allOrdered: [FCategoryIcon] {
        [
            .food, .transport, .entertainment, .shopping, .services,
            .health, .education, .home, .clothing,
            .salary, .freelance, .investments, .gifts, .refund,
            .other
        ]
    }
}
