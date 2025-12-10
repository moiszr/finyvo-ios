//
//  FSpacing.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/5/25.
//

import SwiftUI

// MARK: - Finyvo Spacing System
/// Sistema de espaciado consistente basado en múltiplos de 4
/// Esto asegura que todo esté alineado visualmente

enum FSpacing {
    /// 4pt - Espaciado mínimo (entre iconos y texto inline)
    static let xs: CGFloat = 4
    
    /// 8pt - Espaciado pequeño (padding interno de elementos)
    static let sm: CGFloat = 8
    
    /// 12pt - Espaciado medio-pequeño
    static let md: CGFloat = 12
    
    /// 16pt - Espaciado estándar (padding de cards, separación entre elementos)
    static let lg: CGFloat = 16
    
    /// 20pt - Espaciado medio-grande
    static let xl: CGFloat = 20
    
    /// 24pt - Espaciado grande (separación entre secciones)
    static let xxl: CGFloat = 24
    
    /// 32pt - Espaciado extra grande (márgenes de pantalla)
    static let xxxl: CGFloat = 32
}

// MARK: - Corner Radius
/// Radios de esquina consistentes para la app
enum FRadius {
    /// 12pt - Radio pequeño (badges, chips)
    static let sm: CGFloat = 12
    
    /// 16pt - Radio medio (botones, inputs)
    static let md: CGFloat = 16
    
    /// 22pt - Radio grande (cards, botones grandes)
    static let lg: CGFloat = 22
    
    /// 28pt - Radio extra grande (modales, sheets)
    static let xl: CGFloat = 28
    
    /// Radio completo (círculos, pills)
    static let full: CGFloat = 9999
}
