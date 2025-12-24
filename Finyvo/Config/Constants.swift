//
//  Constants.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/24/25.
//  Constantes globales de la aplicación.
//

import SwiftUI

// MARK: - Constants

enum Constants {
    
    // MARK: - Date Formats
    
    enum DateFormat {
        /// "24 Dic 2025"
        static let display = "d MMM yyyy"
        
        /// "Diciembre 2025"
        static let monthYear = "MMMM yyyy"
        
        /// "Dic 2025"
        static let shortMonthYear = "MMM yyyy"
        
        /// "24 Dic"
        static let dayMonth = "d MMM"
        
        /// "Lunes, 24 de diciembre"
        static let fullDay = "EEEE, d 'de' MMMM"
        
        /// "3:45 PM"
        static let time = "h:mm a"
        
        /// "24/12/2025"
        static let numeric = "dd/MM/yyyy"
        
        /// ISO 8601 para APIs
        static let iso8601 = "yyyy-MM-dd'T'HH:mm:ssZ"
    }
    
    // MARK: - Animations
    
    enum Animation {
        /// Spring estándar para la mayoría de animaciones
        static let defaultSpring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.8)
        
        /// Spring rápido para feedback inmediato
        static let quickSpring = SwiftUI.Animation.spring(response: 0.2, dampingFraction: 0.7)
        
        /// Spring suave para transiciones grandes
        static let smoothSpring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.85)
        
        /// Ease out para entradas
        static let easeOut = SwiftUI.Animation.easeOut(duration: 0.25)
        
        /// Ease in out para transiciones
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.3)
        
        /// Para charts y gráficos
        static let chartSpring = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.75)
    }
    
    // MARK: - Haptics
    
    enum Haptic {
        /// Feedback ligero (selección, toggle)
        @MainActor
        static func light() {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        
        /// Feedback medio (botones importantes)
        @MainActor
        static func medium() {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        
        /// Feedback de éxito
        @MainActor
        static func success() {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        
        /// Feedback de error
        @MainActor
        static func error() {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        
        /// Feedback de advertencia
        @MainActor
        static func warning() {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
        
        /// Feedback de selección
        @MainActor
        static func selection() {
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
    
    // MARK: - Accessibility
    
    enum Accessibility {
        /// Duración mínima para animaciones con Reduce Motion
        static let reducedMotionDuration: Double = 0.01
        
        /// Tamaño mínimo de touch target (44pt según Apple HIG)
        static let minTouchTarget: CGFloat = 44
    }
    
    // MARK: - Storage Keys
    
    enum StorageKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let preferredCurrencyCode = "preferredCurrencyCode"
        static let fiscalMonthStartDay = "fiscalMonthStartDay"
        static let lastSyncDate = "lastSyncDate"
        static let notificationsEnabled = "notificationsEnabled"
    }
    
    // MARK: - Regex Patterns
    
    enum Patterns {
        /// Email válido
        static let email = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        /// Solo números
        static let numbersOnly = "^[0-9]+$"
        
        /// Monto válido (con decimales opcionales)
        static let amount = "^[0-9]+(\\.[0-9]{1,2})?$"
    }
}

// MARK: - Date Formatter Extensions

extension DateFormatter {
    
    /// Formatter reutilizable con locale configurado.
    static func finyvo(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: AppConfig.Defaults.localeIdentifier)
        return formatter
    }
    
    /// Formatter para display: "24 Dic 2025"
    static let display = finyvo(Constants.DateFormat.display)
    
    /// Formatter para mes/año: "Diciembre 2025"
    static let monthYear = finyvo(Constants.DateFormat.monthYear)
    
    /// Formatter para día/mes: "24 Dic"
    static let dayMonth = finyvo(Constants.DateFormat.dayMonth)
    
    /// Formatter para día completo: "Lunes, 24 de diciembre"
    static let fullDay = finyvo(Constants.DateFormat.fullDay)
    
    /// Formatter numérico: "24/12/2025"
    static let numeric = finyvo(Constants.DateFormat.numeric)
}

// MARK: - Date Extensions

extension Date {
    
    /// Formatea para display: "24 Dic 2025"
    func formatted(as format: String) -> String {
        DateFormatter.finyvo(format).string(from: self)
    }
    
    /// "24 Dic 2025"
    var displayString: String {
        DateFormatter.display.string(from: self)
    }
    
    /// "Diciembre 2025"
    var monthYearString: String {
        DateFormatter.monthYear.string(from: self)
    }
    
    /// "24 Dic"
    var dayMonthString: String {
        DateFormatter.dayMonth.string(from: self)
    }
    
    /// "Lunes, 24 de diciembre"
    var fullDayString: String {
        DateFormatter.fullDay.string(from: self)
    }
    
    /// "24/12/2025"
    var numericString: String {
        DateFormatter.numeric.string(from: self)
    }
    
    // MARK: - Date Helpers
    
    /// Inicio del día actual
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// Fin del día actual (23:59:59)
    var endOfDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)?.addingTimeInterval(-1) ?? self
    }
    
    /// Inicio del mes actual
    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }
    
    /// Fin del mes actual
    var endOfMonth: Date {
        Calendar.current.date(byAdding: .month, value: 1, to: startOfMonth)?.addingTimeInterval(-1) ?? self
    }
    
    /// Días restantes en el mes
    var daysRemainingInMonth: Int {
        let calendar = Calendar.current
        guard let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else { return 0 }
        return calendar.dateComponents([.day], from: self, to: endOfMonth).day ?? 0
    }
    
    /// `true` si es hoy
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// `true` si es este mes
    var isThisMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }
    
    /// `true` si es este año
    var isThisYear: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }
}

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
