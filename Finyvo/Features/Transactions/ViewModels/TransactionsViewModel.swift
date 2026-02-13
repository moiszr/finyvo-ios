//
//  TransactionsViewModel.swift
//  Finyvo
//
//  Created by Moises Núñez on 01/15/26.
//  Refactored on 01/18/26 - Clean architecture with @Query-driven data
//  Updated on 01/30/26 - Added isLoading state for skeleton support
//
//  Architecture:
//    - @Observable for navigation and filter state only
//    - Data comes from @Query in the View (SwiftData handles reactivity)
//    - ViewModel handles: filters, navigation, CRUD operations
//    - NO manual refresh patterns - SwiftData is reactive by design
//

import SwiftUI
import SwiftData

// MARK: - Transactions ViewModel

/// ViewModel para la gestión de transacciones.
///
/// ## Arquitectura
/// - **Data**: Viene de `@Query` en la vista (SwiftData maneja la reactividad)
/// - **ViewModel**: Maneja filtros, navegación y operaciones CRUD
/// - **Sin refresh manual**: SwiftData actualiza las vistas automáticamente
///
/// ## Uso
/// ```swift
/// // En la vista:
/// @Query private var transactions: [Transaction]
/// @State private var viewModel = TransactionsViewModel()
///
/// // Para crear:
/// viewModel.createTransaction(in: modelContext, ...)
/// ```
@Observable
final class TransactionsViewModel {
    
    // MARK: - Loading State
    
    /// `true` mientras se cargan datos iniciales
    var isLoading: Bool = false
    
    // MARK: - Filter State
    
    /// Filtro activo
    var filter: TransactionFilter = .thisMonth
    
    /// Agrupación activa
    var grouping: TransactionGrouping = .day
    
    /// Texto de búsqueda
    var searchText: String = ""
    
    // MARK: - Navigation State
    
    /// Transacción seleccionada para detalle
    var selectedTransaction: Transaction?
    
    /// `true` si el detalle está visible
    var isDetailPresented: Bool = false
    
    /// `true` si el editor está visible
    var isEditorPresented: Bool = false
    
    /// Modo del editor
    var editorMode: TransactionEditorMode = .create(type: .expense)
    
    /// Error actual (si existe)
    var error: TransactionError?
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - CRUD Operations
    
    /// Crea una nueva transacción.
    @MainActor
    @discardableResult
    func createTransaction(
        in context: ModelContext,
        amount: Double,
        type: TransactionType,
        note: String? = nil,
        date: Date = .now,
        category: Category? = nil,
        wallet: Wallet?,
        destinationWallet: Wallet? = nil,
        tags: [Tag]? = nil
    ) -> Transaction? {
        // Validaciones
        guard amount > 0 else {
            error = .invalidAmount
            Constants.Haptic.error()
            return nil
        }
        
        guard let wallet else {
            error = .walletRequired
            Constants.Haptic.error()
            return nil
        }
        
        if type.requiresCategory && category == nil {
            error = .categoryRequired
            Constants.Haptic.error()
            return nil
        }
        
        if type == .transfer {
            guard let destinationWallet else {
                error = .destinationWalletRequired
                Constants.Haptic.error()
                return nil
            }
            guard wallet.id != destinationWallet.id else {
                error = .sameWalletTransfer
                Constants.Haptic.error()
                return nil
            }
        }
        
        // Crear transacción
        let transaction = Transaction(
            amount: amount,
            type: type,
            note: note,
            date: date,
            category: category,
            wallet: wallet,
            destinationWallet: destinationWallet,
            tags: tags
        )
        
        context.insert(transaction)
        
        // Actualizar balance del wallet
        updateWalletBalance(for: transaction, isCreating: true)
        
        // Guardar
        do {
            try context.save()
            Constants.Haptic.success()
            
            if AppConfig.isDebugMode {
                print("✅ Created transaction: \(transaction.displayTitle)")
            }
            
            return transaction
        } catch {
            self.error = .saveFailed
            Constants.Haptic.error()
            return nil
        }
    }
    
    /// Elimina una transacción.
    @MainActor
    func deleteTransaction(_ transaction: Transaction, in context: ModelContext) {
        // Revertir el balance
        updateWalletBalance(for: transaction, isCreating: false)
        
        context.delete(transaction)
        
        do {
            try context.save()
            Constants.Haptic.success()
            
            if AppConfig.isDebugMode {
                print("✅ Deleted transaction: \(transaction.displayTitle)")
            }
        } catch {
            self.error = .saveFailed
            Constants.Haptic.error()
        }
    }
    
    /// Duplica una transacción (versión para animación controlada desde la vista).
        @MainActor
        @discardableResult
        func duplicateTransactionAnimated(_ transaction: Transaction, in context: ModelContext) -> Transaction? {
            let newTransaction = Transaction(
                amount: transaction.amount,
                type: transaction.type,
                note: transaction.note,
                date: .now,
                isConfirmed: transaction.isConfirmed,
                isRecurring: false,
                category: transaction.category,
                wallet: transaction.wallet,
                destinationWallet: transaction.destinationWallet,
                tags: transaction.tags
            )
            
            context.insert(newTransaction)
            
            // Actualizar balance
            switch newTransaction.type {
            case .income:
                newTransaction.wallet?.currentBalance += newTransaction.amount
            case .expense:
                newTransaction.wallet?.currentBalance -= newTransaction.amount
            case .transfer:
                newTransaction.wallet?.currentBalance -= newTransaction.amount
                newTransaction.destinationWallet?.currentBalance += newTransaction.amount
            }
            
            newTransaction.wallet?.updatedAt = .now
            newTransaction.destinationWallet?.updatedAt = .now
            
            do {
                try context.save()
                
                if AppConfig.isDebugMode {
                    print("✅ Duplicated transaction: \(newTransaction.displayTitle)")
                }
                
                return newTransaction
            } catch {
                self.error = .saveFailed
                Constants.Haptic.error()
                return nil
            }
        }
    
    // MARK: - Wallet Balance Updates
    
    /// Actualiza el balance del wallet según la transacción.
    private func updateWalletBalance(for transaction: Transaction, isCreating: Bool) {
        let multiplier: Double = isCreating ? 1 : -1
        
        switch transaction.type {
        case .income:
            transaction.wallet?.currentBalance += transaction.amount * multiplier
            
        case .expense:
            transaction.wallet?.currentBalance -= transaction.amount * multiplier
            
        case .transfer:
            transaction.wallet?.currentBalance -= transaction.amount * multiplier
            transaction.destinationWallet?.currentBalance += transaction.amount * multiplier
        }
        
        transaction.wallet?.updatedAt = .now
        transaction.destinationWallet?.updatedAt = .now
    }
    
    // MARK: - Navigation Actions
    
    /// Presenta el editor en modo crear.
    @MainActor
    func presentCreate(type: TransactionType = .expense) {
        editorMode = .create(type: type)
        selectedTransaction = nil
        isEditorPresented = true
    }
    
    /// Presenta el editor en modo editar.
    @MainActor
    func presentEdit(_ transaction: Transaction) {
        editorMode = .edit(transaction)
        selectedTransaction = transaction
        isEditorPresented = true
    }
    
    /// Presenta el detalle de una transacción.
    @MainActor
    func presentDetail(_ transaction: Transaction) {
        selectedTransaction = transaction
        withAnimation(Constants.Animation.smoothSpring) {
            isDetailPresented = true
        }
    }
    
    /// Cierra el detalle.
    @MainActor
    func dismissDetail() {
        withAnimation(Constants.Animation.smoothSpring) {
            isDetailPresented = false
        }
        
        // Limpiar después de la animación
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.3))
            selectedTransaction = nil
        }
    }
    
    // MARK: - Filter Actions
    
    /// Aplica filtro rápido por tipo
    @MainActor
    func setTypeFilter(_ types: Set<TransactionType>) {
        filter.types = types
        Constants.Haptic.selection()
    }
    
    /// Cambia el rango de fechas
    @MainActor
    func setDateRange(_ range: DateRange) {
        filter.dateRange = range
        Constants.Haptic.selection()
    }
    
    /// Limpia todos los filtros
    @MainActor
    func clearFilters() {
        filter.reset()
        searchText = ""
        Constants.Haptic.light()
    }
    
    // MARK: - Filtering Logic (Pure Functions)
    
    /// Filtra transacciones según el filtro actual.
    /// Esta es una función pura - recibe datos y retorna datos filtrados.
    func filterTransactions(_ transactions: [Transaction]) -> [Transaction] {
        var result = transactions
        
        // Filtrar por tipo
        if !filter.types.isEmpty {
            result = result.filter { filter.types.contains($0.type) }
        }
        
        // Filtrar por rango de fechas
        if let dateRange = filter.effectiveDateRange {
            result = result.filter { $0.date >= dateRange.start && $0.date <= dateRange.end }
        }
        
        // Filtrar por categorías
        if !filter.categoryIDs.isEmpty {
            result = result.filter { tx in
                guard let categoryID = tx.category?.id else { return false }
                return filter.categoryIDs.contains(categoryID)
            }
        }
        
        // Filtrar por wallets
        if !filter.walletIDs.isEmpty {
            result = result.filter { tx in
                guard let walletID = tx.wallet?.id else { return false }
                return filter.walletIDs.contains(walletID)
            }
        }
        
        // Filtrar por tags
        if !filter.tagIDs.isEmpty {
            result = result.filter { tx in
                guard let tags = tx.tags else { return false }
                return tags.contains { filter.tagIDs.contains($0.id) }
            }
        }
        
        // Filtrar por texto de búsqueda
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { tx in
                tx.displayTitle.lowercased().contains(query) ||
                tx.category?.name.lowercased().contains(query) == true ||
                tx.safeWalletName?.lowercased().contains(query) == true ||
                tx.note?.lowercased().contains(query) == true
            }
        }
        
        // Filtrar solo confirmadas
        if filter.confirmedOnly {
            result = result.filter { $0.isConfirmed }
        }
        
        // Filtrar solo recurrentes
        if filter.recurringOnly {
            result = result.filter { $0.isRecurring }
        }
        
        // Filtrar por rango de montos
        if let minAmount = filter.minAmount {
            result = result.filter { $0.amount >= minAmount }
        }
        if let maxAmount = filter.maxAmount {
            result = result.filter { $0.amount <= maxAmount }
        }
        
        // Ordenar
        return sortTransactions(result)
    }
    
    /// Ordena las transacciones según la opción seleccionada.
    private func sortTransactions(_ transactions: [Transaction]) -> [Transaction] {
        switch filter.sortBy {
        case .dateDescending:
            return transactions.sorted { $0.date > $1.date }
        case .dateAscending:
            return transactions.sorted { $0.date < $1.date }
        case .amountDescending:
            return transactions.sorted { $0.amount > $1.amount }
        case .amountAscending:
            return transactions.sorted { $0.amount < $1.amount }
        case .categoryName:
            return transactions.sorted { ($0.category?.name ?? "") < ($1.category?.name ?? "") }
        }
    }
    
    /// Agrupa transacciones por fecha.
    func groupTransactions(_ transactions: [Transaction]) -> [TransactionGroup] {
        guard grouping != .none else { return [] }
        
        let calendar = Calendar.current
        var groups: [String: TransactionGroup] = [:]
        
        for transaction in transactions {
            let (key, title, subtitle) = groupKey(for: transaction.date, calendar: calendar)
            
            if var group = groups[key] {
                group.transactions.append(transaction)
                groups[key] = group
            } else {
                groups[key] = TransactionGroup(
                    id: key,
                    date: transaction.date.startOfDay,
                    title: title,
                    subtitle: subtitle,
                    transactions: [transaction]
                )
            }
        }
        
        return groups.values.sorted { $0.date > $1.date }
    }
    
    /// Genera la clave y títulos para agrupar una fecha.
    private func groupKey(for date: Date, calendar: Calendar) -> (key: String, title: String, subtitle: String?) {
        switch grouping {
        case .none:
            return ("", "", nil)
            
        case .day:
            let key = date.startOfDay.timeIntervalSince1970.description
            let title = date.isToday ? "Hoy" : (calendar.isDateInYesterday(date) ? "Ayer" : date.fullDayString)
            let subtitle = date.isThisYear ? nil : date.formatted(as: "yyyy")
            return (key, title, subtitle)
            
        case .week:
            let weekOfYear = calendar.component(.weekOfYear, from: date)
            let year = calendar.component(.year, from: date)
            let key = "\(year)-W\(weekOfYear)"
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
            let title = "Semana del \(weekStart.dayMonthString)"
            let subtitle = "\(weekStart.dayMonthString) - \(weekEnd.dayMonthString)"
            return (key, title, subtitle)
            
        case .month:
            let month = calendar.component(.month, from: date)
            let year = calendar.component(.year, from: date)
            let key = "\(year)-\(month)"
            let title = date.monthYearString.capitalized
            return (key, title, nil)
        }
    }
    
    /// Calcula estadísticas de un conjunto de transacciones.
    func calculateStatistics(from transactions: [Transaction]) -> TransactionStatistics {
        TransactionStatistics.calculate(from: transactions)
    }

    /// Calcula estadísticas convirtiendo cada transacción a la moneda preferida.
    @MainActor
    func calculateConvertedStatistics(
        from transactions: [Transaction],
        preferredCurrency: String,
        fxService: FXService
    ) -> TransactionStatistics {
        let engine = FXEngine(service: fxService)

        var totalIncome: Double = 0
        var totalExpenses: Double = 0
        var totalTransfers: Double = 0
        var incomeCount = 0
        var expenseCount = 0
        var transferCount = 0
        var largestExpense: Double = 0
        var largestIncome: Double = 0

        for tx in transactions {
            let txCurrency = tx.safeCurrencyCode
            let converted: Double

            if txCurrency == preferredCurrency {
                converted = tx.amount
            } else if let result = engine.convertLocallyIfPossible(amount: tx.amount, from: txCurrency, to: preferredCurrency) {
                converted = result.convertedAmount
            } else {
                converted = tx.amount
            }

            switch tx.type {
            case .income:
                totalIncome += converted
                incomeCount += 1
                if converted > largestIncome { largestIncome = converted }
            case .expense:
                totalExpenses += converted
                expenseCount += 1
                if converted > largestExpense { largestExpense = converted }
            case .transfer:
                totalTransfers += converted
                transferCount += 1
            }
        }

        let averageExpense = expenseCount > 0 ? totalExpenses / Double(expenseCount) : 0

        return TransactionStatistics(
            totalIncome: totalIncome,
            totalExpenses: totalExpenses,
            totalTransfers: totalTransfers,
            transactionCount: transactions.count,
            incomeCount: incomeCount,
            expenseCount: expenseCount,
            transferCount: transferCount,
            averageExpense: averageExpense,
            largestExpense: largestExpense,
            largestIncome: largestIncome
        )
    }
}

// MARK: - Editor Mode

/// Modo del editor de transacciones.
enum TransactionEditorMode: Equatable {
    case create(type: TransactionType)
    case edit(Transaction)
    
    var isCreating: Bool {
        if case .create = self { return true }
        return false
    }
    
    var isEditing: Bool {
        if case .edit = self { return true }
        return false
    }
    
    var title: String {
        switch self {
        case .create(let type):
            return "Nuevo \(type.title)"
        case .edit:
            return "Editar"
        }
    }
    
    var initialType: TransactionType {
        switch self {
        case .create(let type):
            return type
        case .edit(let transaction):
            return transaction.type
        }
    }
    
    static func == (lhs: TransactionEditorMode, rhs: TransactionEditorMode) -> Bool {
        switch (lhs, rhs) {
        case (.create(let t1), .create(let t2)):
            return t1 == t2
        case (.edit(let tx1), .edit(let tx2)):
            return tx1.id == tx2.id
        default:
            return false
        }
    }
}

// MARK: - Transaction Errors

/// Errores específicos de transacciones.
enum TransactionError: LocalizedError, Identifiable {
    case loadFailed
    case saveFailed
    case invalidAmount
    case categoryRequired
    case walletRequired
    case destinationWalletRequired
    case sameWalletTransfer
    case notFound
    case invalidCategoryForType
    
    var id: String { localizedDescription }
    
    var errorDescription: String? {
        switch self {
        case .loadFailed:
            return "No se pudieron cargar las transacciones"
        case .saveFailed:
            return "No se pudo guardar la transacción"
        case .invalidAmount:
            return "El monto debe ser mayor a cero"
        case .categoryRequired:
            return "Debes seleccionar una categoría"
        case .walletRequired:
            return "Debes seleccionar una billetera"
        case .destinationWalletRequired:
            return "Debes seleccionar la billetera destino"
        case .sameWalletTransfer:
            return "No puedes transferir a la misma billetera"
        case .notFound:
            return "Transacción no encontrada"
        case .invalidCategoryForType:
            return "La categoría no corresponde al tipo de transacción"
        }
    }
}
