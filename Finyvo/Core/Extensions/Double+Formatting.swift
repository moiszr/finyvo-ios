//
//  Double+Formatting.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/24/25.
//

import Foundation

// MARK: - Double Extension for Currency Formatting

extension Double {
    
    /// Formatea como moneda usando la configuración por defecto.
    ///
    /// - Parameter code: Código de moneda opcional (usa default si nil)
    /// - Returns: String formateado (ej: "RD$1,500.00")
    func asCurrency(code: String? = nil) -> String {
        CurrencyConfig.format(self, code: code)
    }
    
    /// Formatea como moneda compacta.
    ///
    /// - Parameter code: Código de moneda opcional
    /// - Returns: String compacto (ej: "RD$1.5K")
    func asCompactCurrency(code: String? = nil) -> String {
        CurrencyConfig.format(self, code: code, compact: true)
    }
    
    /// Formatea como porcentaje.
    ///
    /// - Returns: String (ej: "75%")
    func asPercentage() -> String {
        "\(Int(self * 100))%"
    }
}

