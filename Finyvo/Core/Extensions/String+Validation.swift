//
//  String+Validation.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/24/25.
//

import Foundation

// MARK: - String Validation Extensions

extension String {
    
    /// `true` si es un email válido
    var isValidEmail: Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", Constants.Patterns.email)
        return predicate.evaluate(with: self)
    }
    
    /// `true` si contiene solo números
    var isNumeric: Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", Constants.Patterns.numbersOnly)
        return predicate.evaluate(with: self)
    }
    
    /// `true` si es un monto válido (números con hasta 2 decimales)
    var isValidAmount: Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", Constants.Patterns.amount)
        return predicate.evaluate(with: self)
    }
    
    /// Limpia el string para usar como nombre de tag
    var asTagName: String {
        self.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: " ", with: "_")
    }
}
