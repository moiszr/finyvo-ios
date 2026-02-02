//
//  Date+Formatting.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/24/25.
//  Updated on 01/17/26 - Added additional helpers and relative date formatting
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
    
    /// Formatter para mes/año corto: "Dic 2025"
    static let shortMonthYear = finyvo(Constants.DateFormat.shortMonthYear)
    
    /// Formatter para día/mes: "24 Dic"
    static let dayMonth = finyvo(Constants.DateFormat.dayMonth)
    
    /// Formatter para día completo: "Lunes, 24 de diciembre"
    static let fullDay = finyvo(Constants.DateFormat.fullDay)
    
    /// Formatter numérico: "24/12/2025"
    static let numeric = finyvo(Constants.DateFormat.numeric)
    
    /// Formatter para hora: "3:45 PM"
    static let time = finyvo(Constants.DateFormat.time)
}

// MARK: - Date Extensions

extension Date {
    
    // MARK: - Formatted Strings
    
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
    
    /// "Dic 2025"
    var shortMonthYearString: String {
        DateFormatter.shortMonthYear.string(from: self)
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
    
    /// "3:45 PM"
    var timeString: String {
        DateFormatter.time.string(from: self)
    }
    
    // MARK: - Relative Formatting
    
    /// Returns a relative string like "Hoy", "Ayer", "Hace 3 días", "24 Dic"
    var relativeString: String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(self) {
            return "Hoy"
        }
        
        if calendar.isDateInYesterday(self) {
            return "Ayer"
        }
        
        if calendar.isDateInTomorrow(self) {
            return "Mañana"
        }
        
        let now = Date()
        let components = calendar.dateComponents([.day], from: self.startOfDay, to: now.startOfDay)
        
        if let days = components.day {
            if days > 0 && days <= 7 {
                return "Hace \(days) día\(days == 1 ? "" : "s")"
            }
            if days < 0 && days >= -7 {
                return "En \(abs(days)) día\(abs(days) == 1 ? "" : "s")"
            }
        }
        
        // For dates more than a week away, show the date
        if isThisYear {
            return dayMonthString
        }
        
        return displayString
    }
    
    /// Returns a smart relative string for transaction lists
    /// Groups: "Hoy", "Ayer", "Esta semana", "La semana pasada", "Este mes", "Mes pasado", etc.
    var transactionGroupString: String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(self) {
            return "Hoy"
        }
        
        if calendar.isDateInYesterday(self) {
            return "Ayer"
        }
        
        // Check if same week
        if calendar.isDate(self, equalTo: now, toGranularity: .weekOfYear) {
            return "Esta semana"
        }
        
        // Check if last week
        let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        if calendar.isDate(self, equalTo: lastWeek, toGranularity: .weekOfYear) {
            return "La semana pasada"
        }
        
        // Check if same month
        if calendar.isDate(self, equalTo: now, toGranularity: .month) {
            return "Este mes"
        }
        
        // Check if last month
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        if calendar.isDate(self, equalTo: lastMonth, toGranularity: .month) {
            return "Mes pasado"
        }
        
        // Check if same year - show month name
        if isThisYear {
            return monthYearString.capitalized
        }
        
        // Different year
        return monthYearString.capitalized
    }
    
    // MARK: - Date Components
    
    /// Day of month (1-31)
    var day: Int {
        Calendar.current.component(.day, from: self)
    }
    
    /// Month (1-12)
    var month: Int {
        Calendar.current.component(.month, from: self)
    }
    
    /// Year
    var year: Int {
        Calendar.current.component(.year, from: self)
    }
    
    /// Week of year
    var weekOfYear: Int {
        Calendar.current.component(.weekOfYear, from: self)
    }
    
    /// Day of week (1 = Sunday, 7 = Saturday in US locale)
    var dayOfWeek: Int {
        Calendar.current.component(.weekday, from: self)
    }
    
    /// Name of the day ("Lunes", "Martes", etc.)
    var dayName: String {
        let formatter = DateFormatter.finyvo("EEEE")
        return formatter.string(from: self).capitalized
    }
    
    /// Short name of the day ("Lun", "Mar", etc.)
    var shortDayName: String {
        let formatter = DateFormatter.finyvo("EEE")
        return formatter.string(from: self).capitalized
    }
    
    /// Name of the month ("Enero", "Febrero", etc.)
    var monthName: String {
        let formatter = DateFormatter.finyvo("MMMM")
        return formatter.string(from: self).capitalized
    }
    
    /// Short name of the month ("Ene", "Feb", etc.)
    var shortMonthName: String {
        let formatter = DateFormatter.finyvo("MMM")
        return formatter.string(from: self).capitalized
    }
    
    // MARK: - Date Boundaries
    
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
    
    /// Inicio de la semana
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// Fin de la semana
    var endOfWeek: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek)?.endOfDay ?? self
    }
    
    /// Inicio del año
    var startOfYear: Date {
        let components = Calendar.current.dateComponents([.year], from: self)
        return Calendar.current.date(from: components) ?? self
    }
    
    /// Fin del año
    var endOfYear: Date {
        Calendar.current.date(byAdding: .year, value: 1, to: startOfYear)?.addingTimeInterval(-1) ?? self
    }
    
    // MARK: - Date Calculations
    
    /// Días restantes en el mes
    var daysRemainingInMonth: Int {
        let calendar = Calendar.current
        guard let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else { return 0 }
        return calendar.dateComponents([.day], from: self, to: endOfMonth).day ?? 0
    }
    
    /// Días transcurridos en el mes
    var daysElapsedInMonth: Int {
        day
    }
    
    /// Total de días en el mes
    var daysInMonth: Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: self)
        return range?.count ?? 30
    }
    
    /// Days between this date and another
    func days(to date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self.startOfDay, to: date.startOfDay)
        return components.day ?? 0
    }
    
    /// Months between this date and another
    func months(to date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: self.startOfMonth, to: date.startOfMonth)
        return components.month ?? 0
    }
    
    // MARK: - Date Comparisons
    
    /// `true` si es hoy
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// `true` si es ayer
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    /// `true` si es mañana
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }
    
    /// `true` si es esta semana
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    /// `true` si es este mes
    var isThisMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }
    
    /// `true` si es este año
    var isThisYear: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }
    
    /// `true` si es un fin de semana
    var isWeekend: Bool {
        Calendar.current.isDateInWeekend(self)
    }
    
    /// `true` si es en el pasado
    var isPast: Bool {
        self < Date()
    }
    
    /// `true` si es en el futuro
    var isFuture: Bool {
        self > Date()
    }
    
    // MARK: - Date Manipulation
    
    /// Adds days to the date
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    /// Adds weeks to the date
    func adding(weeks: Int) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: self) ?? self
    }
    
    /// Adds months to the date
    func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }
    
    /// Adds years to the date
    func adding(years: Int) -> Date {
        Calendar.current.date(byAdding: .year, value: years, to: self) ?? self
    }
}
