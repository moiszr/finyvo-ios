//
//  FCardColor.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/22/25.
//  Global color palette for cards and tags.
//

import SwiftUI

/// Colores disponibles para las cards de categoría.
enum FCardColor: String, CaseIterable, Identifiable, Codable, Sendable {
    case white
    case gray
    case blue
    case red
    case yellow
    case teal
    case orange
    case pink
    case green
    case purple

    var id: String { rawValue }

    /// Nombre "base" (por si lo necesitas en logs / analytics)
    var baseName: String {
        switch self {
        case .white:  return "Neutro"
        case .gray:   return "Gris"
        case .blue:   return "Azul"
        case .red:    return "Rojo"
        case .yellow: return "Amarillo"
        case .teal:   return "Teal"
        case .orange: return "Naranja"
        case .pink:   return "Rosa"
        case .green:  return "Verde"
        case .purple: return "Morado"
        }
    }

    /// ✅ Nombre visible en UI, adaptado al tema cuando aplica
    func displayName(for scheme: ColorScheme) -> String {
        switch self {
        case .white:
            // En light tu "white" es near-black, en dark es near-white.
            return (scheme == .light) ? "Negro" : "Blanco"
        default:
            return baseName
        }
    }

    var color: Color {
        switch self {
        case .white:  return FColors.white
        case .gray:   return FColors.gray
        case .blue:   return FColors.blue
        case .red:    return FColors.red
        case .yellow: return FColors.yellow
        case .teal:   return FColors.teal
        case .orange: return FColors.orange
        case .pink:   return FColors.pink
        case .green:  return FColors.green
        case .purple: return FColors.purple
        }
    }

    // MARK: - Helper Methods for UI

    /// ✅ Contraste correcto con tu paleta adaptativa
    func contrastContentColor(for scheme: ColorScheme) -> Color {
        switch self {
        case .white:
            // Light: near-black -> contenido blanco
            // Dark: near-white  -> contenido negro
            return (scheme == .light) ? .white : Color.black.opacity(0.85)

        case .yellow:
            return Color.black.opacity(0.85)

        case .gray:
            // Tu gray también es adaptativo y puede ser oscuro en light,
            // mejor hacerlo dependiente del scheme para que siempre se lea.
            return (scheme == .light) ? .white : Color.black.opacity(0.85)

        default:
            return .white
        }
    }

    func cardBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? color.opacity(0.15) : color.opacity(0.12)
    }

    func textColor(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : Color(hex: "#1A1A1A")
    }
}
