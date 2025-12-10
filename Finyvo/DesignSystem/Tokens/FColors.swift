//
//  FColors.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/5/25.
//

import SwiftUI

// MARK: - Finyvo Color System
/// Sistema de colores de Finyvo que combina colores de marca
/// con colores semánticos de iOS para adaptarse a light/dark mode

enum FColors {
    
    // MARK: - Brand Colors
    /// Color principal de la marca Finyvo
    static let brand = Color(hex: "0EA5E9")
    
    /// Variantes del color de marca para diferentes estados
    static let brandLight = Color(hex: "7DD3FC")
    static let brandDark = Color(hex: "0284C7")
    
    // MARK: - Semantic Colors (iOS Native)
    /// Estos colores se adaptan automáticamente a light/dark mode
    
    /// Color principal para texto importante
    static let textPrimary = Color.primary
    
    /// Color secundario para texto menos importante
    static let textSecondary = Color.secondary
    
    /// Color para texto terciario o hints
    static let textTertiary = Color(uiColor: .tertiaryLabel)
    
    // MARK: - Background Colors
    /// Fondo principal de la app
    static let background = Color(uiColor: .systemBackground)
    
    /// Fondo secundario (para cards, secciones)
    static let backgroundSecondary = Color(uiColor: .secondarySystemBackground)
    
    /// Fondo terciario (para elementos anidados)
    static let backgroundTertiary = Color(uiColor: .tertiarySystemBackground)
    
    /// Fondo agrupado (para listas con estilo inset)
    static let backgroundGrouped = Color(uiColor: .systemGroupedBackground)
    
    // MARK: - Surface Colors (Cards, Sheets)
    /// Color para cards y superficies elevadas
    static let surface = Color(uiColor: .secondarySystemBackground)
    
    /// Color para superficies con glass effect
    static let surfaceGlass = Color(uiColor: .systemBackground).opacity(0.8)
    
    // MARK: - Utility Colors
    /// Separadores y bordes sutiles
    static let separator = Color(uiColor: .separator)
    
    /// Bordes más visibles
    static let border = Color(uiColor: .opaqueSeparator)
    
    // MARK: - Status Colors (iOS Native)
    /// Éxito - para transacciones positivas, ingresos
    static let success = Color.green
    
    /// Peligro - para gastos, eliminar, alertas
    static let danger = Color.red
    
    /// Advertencia - para avisos
    static let warning = Color.orange
    
    /// Info - información neutral
    static let info = Color.blue
    
    // MARK: - Transaction Colors
    /// Color para ingresos
    static let income = Color.green
    
    /// Color para gastos
    static let expense = Color.red
    
    /// Color para transferencias
    static let transfer = Color.blue
}

// MARK: - Color Extension for Hex Support
extension Color {
    /// Inicializa un Color desde un string hexadecimal
    /// - Parameter hex: String hexadecimal (con o sin #)
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
