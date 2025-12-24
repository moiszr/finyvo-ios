//
//  Currency.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/24/25.
//

import Foundation

// MARK: - Currency Model

/// Representa una moneda con toda su información de formateo.
struct Currency: Identifiable, Hashable, Codable {
    let code: String           // ISO 4217: "USD", "EUR", "DOP"
    let symbol: String         // "$", "€", "RD$"
    let name: String           // "Dólar Estadounidense"
    let namePlural: String     // "Dólares Estadounidenses"
    let decimalDigits: Int     // 2 para mayoría, 0 para JPY, etc.
    let symbolPosition: SymbolPosition
    let groupingSeparator: String  // "," o "."
    let decimalSeparator: String   // "." o ","
    let flag: String           // Emoji de bandera "🇺🇸"
    
    var id: String { code }
    
    enum SymbolPosition: String, Codable {
        case before  // $100
        case after   // 100€
    }
    
    /// Formatea un valor Double a String con el formato de esta moneda.
    ///
    /// - Parameters:
    ///   - value: Valor a formatear
    ///   - showSymbol: Si debe incluir el símbolo (default: true)
    ///   - compact: Si debe usar formato compacto K/M (default: false)
    /// - Returns: String formateado
    func format(_ value: Double, showSymbol: Bool = true, compact: Bool = false) -> String {
        if compact {
            return formatCompact(value, showSymbol: showSymbol)
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimalDigits
        formatter.maximumFractionDigits = decimalDigits
        formatter.groupingSeparator = groupingSeparator
        formatter.decimalSeparator = decimalSeparator
        
        let formattedNumber = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.\(decimalDigits)f", value)
        
        guard showSymbol else { return formattedNumber }
        
        switch symbolPosition {
        case .before:
            return "\(symbol)\(formattedNumber)"
        case .after:
            return "\(formattedNumber) \(symbol)"
        }
    }
    
    /// Formatea en formato compacto (1.5K, 2.3M)
    private func formatCompact(_ value: Double, showSymbol: Bool) -> String {
        let absValue = abs(value)
        let sign = value < 0 ? "-" : ""
        
        let (number, suffix): (Double, String) = {
            if absValue >= 1_000_000_000 {
                return (absValue / 1_000_000_000, "B")
            } else if absValue >= 1_000_000 {
                return (absValue / 1_000_000, "M")
            } else if absValue >= 1_000 {
                return (absValue / 1_000, "K")
            } else {
                return (absValue, "")
            }
        }()
        
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = number >= 10 ? 0 : 1
        formatter.minimumFractionDigits = 0
        
        let formattedNumber = formatter.string(from: NSNumber(value: number)) ?? String(format: "%.1f", number)
        
        guard showSymbol else { return "\(sign)\(formattedNumber)\(suffix)" }
        
        switch symbolPosition {
        case .before:
            return "\(sign)\(symbol)\(formattedNumber)\(suffix)"
        case .after:
            return "\(sign)\(formattedNumber)\(suffix) \(symbol)"
        }
    }
    
    /// Parsea un string de input a Double.
    ///
    /// - Parameter input: String del usuario (puede tener separadores locales)
    /// - Returns: Double o nil si no es válido
    func parse(_ input: String) -> Double? {
        var normalized = input
            .replacingOccurrences(of: symbol, with: "")
            .replacingOccurrences(of: groupingSeparator, with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        // Normalizar separador decimal a "."
        if decimalSeparator != "." {
            normalized = normalized.replacingOccurrences(of: decimalSeparator, with: ".")
        }
        
        return Double(normalized)
    }
}
