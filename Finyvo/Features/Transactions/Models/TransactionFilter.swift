//
//  TransactionFilter.swift
//  Finyvo
//
//  Created by Moises Núñez on 01/15/26.
//  Updated on 01/18/26 - Added formattedDateRange for UI display
//  Sistema de filtros para transacciones.
//
//  Features:
//    - Filter by type (income/expense/transfer)
//    - Filter by date range
//    - Filter by category
//    - Filter by wallet
//    - Filter by tags
//    - Text search
//    - Sorting options
//

import Foundation

// MARK: - Transaction Filter

/// Filtros para consultar transacciones.
///
/// ## Uso
/// ```swift
/// var filter = TransactionFilter()
/// filter.types = [.expense]
/// filter.dateRange = .thisMonth
/// filter.categories = [foodCategory.id]
///
/// let filtered = viewModel.transactions(matching: filter)
/// ```
struct TransactionFilter: Equatable, Sendable {
    
    // MARK: - Properties
    
    /// Tipos de transacción a incluir (vacío = todos)
    var types: Set<TransactionType> = []
    
    /// Rango de fechas
    var dateRange: DateRange = .thisMonth
    
    /// Fecha personalizada de inicio (solo si dateRange == .custom)
    var customStartDate: Date?
    
    /// Fecha personalizada de fin (solo si dateRange == .custom)
    var customEndDate: Date?
    
    /// IDs de categorías a incluir (vacío = todas)
    var categoryIDs: Set<UUID> = []
    
    /// IDs de wallets a incluir (vacío = todas)
    var walletIDs: Set<UUID> = []
    
    /// IDs de tags a incluir (vacío = todas)
    var tagIDs: Set<UUID> = []
    
    /// Texto de búsqueda (busca en nota y nombre de comercio)
    var searchText: String = ""
    
    /// Solo transacciones confirmadas
    var confirmedOnly: Bool = false
    
    /// Solo transacciones recurrentes
    var recurringOnly: Bool = false
    
    /// Rango de montos
    var minAmount: Double?
    var maxAmount: Double?
    
    /// Ordenamiento
    var sortBy: SortOption = .dateDescending
    
    // MARK: - Computed Properties
    
    /// `true` si hay algún filtro activo
    var hasActiveFilters: Bool {
        !types.isEmpty ||
        dateRange != .thisMonth ||
        !categoryIDs.isEmpty ||
        !walletIDs.isEmpty ||
        !tagIDs.isEmpty ||
        !searchText.isEmpty ||
        confirmedOnly ||
        recurringOnly ||
        minAmount != nil ||
        maxAmount != nil
    }
    
    /// Número de filtros activos
    var activeFilterCount: Int {
        var count = 0
        if !types.isEmpty { count += 1 }
        if dateRange != .thisMonth { count += 1 }
        if !categoryIDs.isEmpty { count += 1 }
        if !walletIDs.isEmpty { count += 1 }
        if !tagIDs.isEmpty { count += 1 }
        if !searchText.isEmpty { count += 1 }
        if confirmedOnly { count += 1 }
        if recurringOnly { count += 1 }
        if minAmount != nil || maxAmount != nil { count += 1 }
        return count
    }
    
    /// Rango de fechas efectivo
    var effectiveDateRange: (start: Date, end: Date)? {
        switch dateRange {
        case .allTime:
            return nil
        case .today:
            let today = Date()
            return (today.startOfDay, today.endOfDay)
        case .yesterday:
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            return (yesterday.startOfDay, yesterday.endOfDay)
        case .thisWeek:
            let calendar = Calendar.current
            let today = Date()
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
            return (weekStart, today.endOfDay)
        case .thisMonth:
            let today = Date()
            return (today.startOfMonth, today.endOfDay)
        case .lastMonth:
            let today = Date()
            let lastMonthEnd = today.startOfMonth.addingTimeInterval(-1)
            let lastMonthStart = lastMonthEnd.startOfMonth
            return (lastMonthStart, lastMonthEnd)
        case .thisYear:
            let calendar = Calendar.current
            let today = Date()
            let yearStart = calendar.date(from: calendar.dateComponents([.year], from: today))!
            return (yearStart, today.endOfDay)
        case .last7Days:
            let today = Date()
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: today)!
            return (weekAgo.startOfDay, today.endOfDay)
        case .last30Days:
            let today = Date()
            let monthAgo = Calendar.current.date(byAdding: .day, value: -30, to: today)!
            return (monthAgo.startOfDay, today.endOfDay)
        case .last90Days:
            let today = Date()
            let threeMonthsAgo = Calendar.current.date(byAdding: .day, value: -90, to: today)!
            return (threeMonthsAgo.startOfDay, today.endOfDay)
        case .custom:
            guard let start = customStartDate, let end = customEndDate else { return nil }
            return (start.startOfDay, end.endOfDay)
        }
    }
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Factory Methods
    
    /// Filtro para transacciones de hoy
    static var today: TransactionFilter {
        var filter = TransactionFilter()
        filter.dateRange = .today
        return filter
    }
    
    /// Filtro para este mes
    static var thisMonth: TransactionFilter {
        var filter = TransactionFilter()
        filter.dateRange = .thisMonth
        return filter
    }
    
    /// Filtro para gastos de este mes
    static var expensesThisMonth: TransactionFilter {
        var filter = TransactionFilter()
        filter.types = [.expense]
        filter.dateRange = .thisMonth
        return filter
    }
    
    /// Filtro para ingresos de este mes
    static var incomeThisMonth: TransactionFilter {
        var filter = TransactionFilter()
        filter.types = [.income]
        filter.dateRange = .thisMonth
        return filter
    }
    
    /// Filtro para una categoría específica
    static func forCategory(_ categoryID: UUID) -> TransactionFilter {
        var filter = TransactionFilter()
        filter.categoryIDs = [categoryID]
        filter.dateRange = .thisMonth
        return filter
    }
    
    /// Filtro para un wallet específico
    static func forWallet(_ walletID: UUID) -> TransactionFilter {
        var filter = TransactionFilter()
        filter.walletIDs = [walletID]
        return filter
    }
    
    // MARK: - Mutating Methods
    
    /// Limpia todos los filtros
    mutating func reset() {
        self = TransactionFilter()
    }
    
    /// Toggle un tipo de transacción
    mutating func toggle(type: TransactionType) {
        if types.contains(type) {
            types.remove(type)
        } else {
            types.insert(type)
        }
    }
    
    /// Toggle una categoría
    mutating func toggle(categoryID: UUID) {
        if categoryIDs.contains(categoryID) {
            categoryIDs.remove(categoryID)
        } else {
            categoryIDs.insert(categoryID)
        }
    }
    
    /// Toggle un wallet
    mutating func toggle(walletID: UUID) {
        if walletIDs.contains(walletID) {
            walletIDs.remove(walletID)
        } else {
            walletIDs.insert(walletID)
        }
    }
    
    /// Toggle un tag
    mutating func toggle(tagID: UUID) {
        if tagIDs.contains(tagID) {
            tagIDs.remove(tagID)
        } else {
            tagIDs.insert(tagID)
        }
    }
}

// MARK: - Date Range

/// Rangos de fecha predefinidos para filtrar.
enum DateRange: String, CaseIterable, Identifiable, Sendable {
    case allTime = "all_time"
    case today = "today"
    case yesterday = "yesterday"
    case thisWeek = "this_week"
    case thisMonth = "this_month"
    case lastMonth = "last_month"
    case thisYear = "this_year"
    case last7Days = "last_7_days"
    case last30Days = "last_30_days"
    case last90Days = "last_90_days"
    case custom = "custom"
    
    var id: String { rawValue }
    
    /// Título localizado
    var title: String {
        switch self {
        case .allTime:    return "Todo el tiempo"
        case .today:      return "Hoy"
        case .yesterday:  return "Ayer"
        case .thisWeek:   return "Esta semana"
        case .thisMonth:  return "Este mes"
        case .lastMonth:  return "Mes pasado"
        case .thisYear:   return "Este año"
        case .last7Days:  return "Últimos 7 días"
        case .last30Days: return "Últimos 30 días"
        case .last90Days: return "Últimos 90 días"
        case .custom:     return "Personalizado"
        }
    }
    
    /// Título corto para UI compacta
    var shortTitle: String {
        switch self {
        case .allTime:    return "Todo"
        case .today:      return "Hoy"
        case .yesterday:  return "Ayer"
        case .thisWeek:   return "Semana"
        case .thisMonth:  return "Mes"
        case .lastMonth:  return "Mes ant."
        case .thisYear:   return "Año"
        case .last7Days:  return "7 días"
        case .last30Days: return "30 días"
        case .last90Days: return "90 días"
        case .custom:     return "Custom"
        }
    }
    
    /// SF Symbol
    var systemImageName: String {
        switch self {
        case .allTime:    return "infinity"
        case .today:      return "sun.max.fill"
        case .yesterday:  return "moon.fill"
        case .thisWeek:   return "calendar"
        case .thisMonth:  return "calendar.badge.clock"
        case .lastMonth:  return "calendar.badge.minus"
        case .thisYear:   return "calendar.circle"
        case .last7Days:  return "7.square.fill"
        case .last30Days: return "30.square.fill"
        case .last90Days: return "90.square.fill"
        case .custom:     return "calendar.badge.plus"
        }
    }
    
    /// Formatted title for display (handles custom dates)
    func formattedTitle(customStart: Date? = nil, customEnd: Date? = nil) -> String {
        switch self {
        case .allTime:
            return "Todo el tiempo"
        case .today:
            return Date().formatted(date: .abbreviated, time: .omitted)
        case .yesterday:
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            return yesterday.formatted(date: .abbreviated, time: .omitted)
        case .thisWeek:
            return "Esta semana"
        case .thisMonth:
            return Date().formatted(.dateTime.month(.wide).year())
        case .lastMonth:
            let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
            return lastMonth.formatted(.dateTime.month(.wide).year())
        case .thisYear:
            return String(Calendar.current.component(.year, from: Date()))
        case .last7Days:
            return "Últimos 7 días"
        case .last30Days:
            return "Últimos 30 días"
        case .last90Days:
            return "Últimos 90 días"
        case .custom:
            if let start = customStart, let end = customEnd {
                let startStr = start.formatted(date: .abbreviated, time: .omitted)
                let endStr = end.formatted(date: .abbreviated, time: .omitted)
                return "\(startStr) - \(endStr)"
            }
            return "Personalizado"
        }
    }
    
    /// Opciones comunes para mostrar en picker rápido
    static var quickOptions: [DateRange] {
        [.today, .thisWeek, .thisMonth, .last30Days]
    }
    
    /// Todas las opciones para filtro completo
    static var allOptions: [DateRange] {
        [.allTime, .today, .yesterday, .thisWeek, .thisMonth, .lastMonth, .thisYear, .last7Days, .last30Days, .last90Days, .custom]
    }
}

// MARK: - Sort Option

/// Opciones de ordenamiento para transacciones.
enum SortOption: String, CaseIterable, Identifiable, Sendable {
    case dateDescending = "date_desc"
    case dateAscending = "date_asc"
    case amountDescending = "amount_desc"
    case amountAscending = "amount_asc"
    case categoryName = "category_name"
    
    var id: String { rawValue }
    
    /// Título localizado
    var title: String {
        switch self {
        case .dateDescending:   return "Más recientes"
        case .dateAscending:    return "Más antiguas"
        case .amountDescending: return "Mayor monto"
        case .amountAscending:  return "Menor monto"
        case .categoryName:     return "Por categoría"
        }
    }
    
    /// SF Symbol
    var systemImageName: String {
        switch self {
        case .dateDescending:   return "arrow.down.circle"
        case .dateAscending:    return "arrow.up.circle"
        case .amountDescending: return "arrow.down.circle.fill"
        case .amountAscending:  return "arrow.up.circle.fill"
        case .categoryName:     return "folder.fill"
        }
    }
}

// MARK: - Transaction Grouping

/// Agrupación de transacciones por fecha.
enum TransactionGrouping: String, CaseIterable, Identifiable, Sendable {
    case none = "none"
    case day = "day"
    case week = "week"
    case month = "month"
    
    var id: String { rawValue }
    
    /// Título localizado
    var title: String {
        switch self {
        case .none:  return "Sin agrupar"
        case .day:   return "Por día"
        case .week:  return "Por semana"
        case .month: return "Por mes"
        }
    }
}

// MARK: - Grouped Transactions

/// Grupo de transacciones con su fecha representativa.
struct TransactionGroup: Identifiable, Sendable {
    let id: String
    let date: Date
    let title: String
    let subtitle: String?
    var transactions: [Transaction]
    
    /// Total de ingresos del grupo
    var totalIncome: Double {
        transactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Total de gastos del grupo
    var totalExpenses: Double {
        transactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Balance neto del grupo
    var netBalance: Double {
        totalIncome - totalExpenses
    }
    
    /// Número de transacciones
    var count: Int {
        transactions.count
    }
}

// MARK: - Transaction Statistics

/// Estadísticas calculadas de un conjunto de transacciones.
struct TransactionStatistics: Sendable {
    let totalIncome: Double
    let totalExpenses: Double
    let totalTransfers: Double
    let transactionCount: Int
    let incomeCount: Int
    let expenseCount: Int
    let transferCount: Int
    let averageExpense: Double
    let largestExpense: Double
    let largestIncome: Double
    
    /// Balance neto
    var netBalance: Double {
        totalIncome - totalExpenses
    }
    
    /// `true` si hay superávit
    var isPositive: Bool {
        netBalance >= 0
    }
    
    /// Estadísticas vacías
    static var empty: TransactionStatistics {
        TransactionStatistics(
            totalIncome: 0,
            totalExpenses: 0,
            totalTransfers: 0,
            transactionCount: 0,
            incomeCount: 0,
            expenseCount: 0,
            transferCount: 0,
            averageExpense: 0,
            largestExpense: 0,
            largestIncome: 0
        )
    }
    
    /// Calcula estadísticas de una lista de transacciones
    static func calculate(from transactions: [Transaction]) -> TransactionStatistics {
        let income = transactions.filter { $0.type == .income }
        let expenses = transactions.filter { $0.type == .expense }
        let transfers = transactions.filter { $0.type == .transfer }
        
        let totalIncome = income.reduce(0) { $0 + $1.amount }
        let totalExpenses = expenses.reduce(0) { $0 + $1.amount }
        let totalTransfers = transfers.reduce(0) { $0 + $1.amount }
        
        let averageExpense = expenses.isEmpty ? 0 : totalExpenses / Double(expenses.count)
        let largestExpense = expenses.max(by: { $0.amount < $1.amount })?.amount ?? 0
        let largestIncome = income.max(by: { $0.amount < $1.amount })?.amount ?? 0
        
        return TransactionStatistics(
            totalIncome: totalIncome,
            totalExpenses: totalExpenses,
            totalTransfers: totalTransfers,
            transactionCount: transactions.count,
            incomeCount: income.count,
            expenseCount: expenses.count,
            transferCount: transfers.count,
            averageExpense: averageExpense,
            largestExpense: largestExpense,
            largestIncome: largestIncome
        )
    }
}
