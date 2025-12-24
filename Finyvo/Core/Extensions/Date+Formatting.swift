//
//  Date+Formatting.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/24/25.
//

import Foundation

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
