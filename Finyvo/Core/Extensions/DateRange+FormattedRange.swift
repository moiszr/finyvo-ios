//
//  DateRange+FormattedRange.swift
//  Finyvo
//
//  Created by Moises Núñez on 01/17/26.
//  Extension to provide formatted date range string for UI display.
//  Uses existing DateFormatter extensions from Date+Formatting.swift.
//

import Foundation

extension DateRange {
    
    // MARK: - Formatted Range for UI
    
    /// Returns a formatted string representing the date range for display in headers.
    ///
    /// Examples:
    /// - `.today` → "Hoy, 17 Ene"
    /// - `.thisMonth` → "Enero 2026"
    /// - `.last7Days` → "11 - 17 Enero"
    /// - `.custom` (with filter dates) → "6 - 16 Enero"
    var formattedRange: String {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .allTime:
            return "Todo el tiempo"
            
        case .today:
            return "Hoy, \(now.dayMonthString)"
            
        case .yesterday:
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
            return "Ayer, \(yesterday.dayMonthString)"
            
        case .thisWeek:
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
            return formatDateRange(from: startOfWeek, to: now)
            
        case .thisMonth:
            return now.monthYearString.capitalized
            
        case .lastMonth:
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return lastMonth.monthYearString.capitalized
            
        case .thisYear:
            let year = calendar.component(.year, from: now)
            return "Año \(year)"
            
        case .last7Days:
            let start = calendar.date(byAdding: .day, value: -6, to: now) ?? now
            return formatDateRange(from: start, to: now)
            
        case .last30Days:
            let start = calendar.date(byAdding: .day, value: -29, to: now) ?? now
            return formatDateRange(from: start, to: now)
            
        case .last90Days:
            let start = calendar.date(byAdding: .day, value: -89, to: now) ?? now
            return formatDateRange(from: start, to: now)
            
        case .custom:
            // Para custom, retornamos un placeholder
            // El caller debe usar formattedRange(start:end:) con las fechas reales
            return "Personalizado"
        }
    }
    
    /// Returns a formatted string for custom date range with specific dates.
    ///
    /// Use this when `dateRange == .custom` and you have the actual dates from the filter.
    ///
    /// - Parameters:
    ///   - start: Start date of the range
    ///   - end: End date of the range
    /// - Returns: Formatted string like "6 - 16 Enero" or "6 Ene - 16 Feb"
    func formattedRange(start: Date, end: Date) -> String {
        formatDateRange(from: start, to: end)
    }
    
    // MARK: - Private Helpers
    
    /// Formats a date range as "d - d Mes" or "d Mes - d Mes" depending on whether same month.
    private func formatDateRange(from start: Date, to end: Date) -> String {
        let calendar = Calendar.current
        
        let startComponents = calendar.dateComponents([.day, .month, .year], from: start)
        let endComponents = calendar.dateComponents([.day, .month, .year], from: end)
        
        let startDay = startComponents.day ?? 1
        let endDay = endComponents.day ?? 1
        
        // Same month and year → "6 - 16 Enero"
        if startComponents.month == endComponents.month && startComponents.year == endComponents.year {
            let monthFormatter = DateFormatter.finyvo("MMMM")
            let monthName = monthFormatter.string(from: start).capitalized
            return "\(startDay) - \(endDay) \(monthName)"
        }
        
        // Different months but same year → "6 Ene - 16 Feb"
        if startComponents.year == endComponents.year {
            return "\(start.dayMonthString) - \(end.dayMonthString)"
        }
        
        // Different years → "6 Ene 24 - 16 Feb 25"
        let yearFormatter = DateFormatter.finyvo("d MMM yy")
        return "\(yearFormatter.string(from: start)) - \(yearFormatter.string(from: end))"
    }
}

// MARK: - TransactionFilter Extension

extension TransactionFilter {
    
    /// Returns a formatted string representing the active date range.
    ///
    /// Handles `.custom` case by using the actual `customStartDate` and `customEndDate`.
    var formattedDateRange: String {
        switch dateRange {
        case .custom:
            if let start = customStartDate, let end = customEndDate {
                return dateRange.formattedRange(start: start, end: end)
            }
            return "Personalizado"
        default:
            return dateRange.formattedRange
        }
    }
}
