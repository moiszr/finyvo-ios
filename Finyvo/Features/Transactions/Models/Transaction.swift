//
//  Transaction.swift
//  Finyvo
//
//  Created by Moises Núñez on 01/15/26.
//  Updated on 01/18/26 - Added safeWalletName for crash prevention
//  Modelo principal de transacciones con soporte SwiftData.
//
//  Architecture:
//    - SwiftData @Model with computed type-safe accessors
//    - Relationships: Category (1:1), Wallet (1:1), Tags (N:M)
//    - Support for transfers between wallets
//    - Recurrence linking for subscriptions
//

import SwiftUI
import SwiftData

// MARK: - Transaction Model

/// Modelo principal de transacción financiera.
///
/// ## Arquitectura
/// - `typeRaw`: String persistido → `type`: TransactionType computed
/// - Relaciones opcionales con Category, Wallet, Tags
/// - Soporte para transferencias entre wallets
///
/// ## Tipos
/// - `.income`: Dinero que entra (salario, freelance, etc.)
/// - `.expense`: Dinero que sale (compras, servicios, etc.)
/// - `.transfer`: Movimiento entre wallets propias
///
/// ## Uso
/// ```swift
/// let transaction = Transaction(
///     amount: 1500,
///     type: .expense,
///     note: "Almuerzo con amigos",
///     date: .now
/// )
/// transaction.category = foodCategory
/// transaction.wallet = cashWallet
/// ```
@Model
final class Transaction {
    
    // MARK: - Persisted Properties
    
    /// Identificador único
    @Attribute(.unique)
    var id: UUID
    
    /// Monto de la transacción (siempre positivo, el tipo determina dirección)
    var amount: Double
    
    /// Tipo - almacena rawValue de TransactionType
    var typeRaw: String
    
    /// Nota/descripción opcional
    var note: String?
    
    /// Fecha de la transacción
    var date: Date
    
    /// Útil cuando el wallet es eliminado - stores the currency code
    var currencyCode: String?
    
    /// `true` si está confirmada/procesada
    var isConfirmed: Bool
    
    /// `true` si es parte de una transacción recurrente
    var isRecurring: Bool
    
    /// ID de la suscripción/recurrencia asociada (futuro)
    var subscriptionID: UUID?
    
    /// Nombre del lugar/comercio (opcional)
    var merchantName: String?
    
    /// Ruta a imagen del recibo (opcional)
    var receiptImagePath: String?
    
    /// Fecha de creación del registro
    var createdAt: Date
    
    /// Fecha de última actualización
    var updatedAt: Date
    
    // MARK: - Relationships
    
    /// Categoría de la transacción (obligatoria para income/expense)
    var category: Category?
    
    /// Wallet de origen (de donde sale el dinero o entra)
    var wallet: Wallet?
    
    /// Wallet destino (solo para transferencias)
    var destinationWallet: Wallet?
    
    /// Tags adicionales (many-to-many)
    var tags: [Tag]?
    
    // MARK: - Computed Properties (Type-Safe Access)
    
    /// Tipo de transacción
    var type: TransactionType {
        get { TransactionType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }
    
    // MARK: - Display Helpers
    
    /// Monto con signo según el tipo
    var signedAmount: Double {
        switch type {
        case .income:
            return amount
        case .expense, .transfer:
            return -amount
        }
    }
    
    /// Monto formateado con la moneda del wallet
    var formattedAmount: String {
        return amount.asCurrency(code: safeCurrencyCode)
    }
    
    /// Monto formateado con signo
    var formattedSignedAmount: String {
        let prefix = type == .income ? "+" : (type == .expense ? "-" : "")
        return "\(prefix)\(amount.asCurrency(code: safeCurrencyCode))"
    }
    
    /// Monto formateado compacto
    var formattedAmountCompact: String {
        return amount.asCompactCurrency(code: safeCurrencyCode)
    }
    
    /// Título para mostrar (nota o nombre de categoría)
    var displayTitle: String {
        if let note = note, !note.isEmpty {
            return note
        }
        if let categoryName = category?.name {
            return categoryName
        }
        return type.defaultTitle
    }
    
    /// Subtítulo (categoría si hay nota, o wallet)
    var displaySubtitle: String? {
        if note != nil, let categoryName = category?.name {
            return categoryName
        }
        if type == .transfer, let dest = destinationWallet?.name {
            return "→ \(dest)"
        }
        return safeWalletName
    }
    
    /// Icono para mostrar (de categoría o tipo)
    var displayIcon: String {
        category?.systemImageName ?? type.systemImageName
    }
    
    /// Color para mostrar (de categoría o tipo)
    var displayColor: FCardColor {
        category?.color ?? type.defaultColor
    }
    
    /// `true` si es una transacción de hoy
    var isToday: Bool {
        date.isToday
    }
    
    /// `true` si es de este mes
    var isThisMonth: Bool {
        date.isThisMonth
    }
    
    /// `true` si es una transferencia
    var isTransfer: Bool {
        type == .transfer
    }
    
    /// `true` si tiene tags
    var hasTags: Bool {
        guard let tags else { return false }
        return !tags.isEmpty
    }
    
    /// Número de tags
    var tagCount: Int {
        tags?.count ?? 0
    }
    
    // MARK: - Validation
    
    /// `true` si la transacción es válida para guardar
    var isValid: Bool {
        guard amount > 0 else { return false }
        
        switch type {
        case .income, .expense:
            return category != nil && wallet != nil
        case .transfer:
            return wallet != nil && destinationWallet != nil && wallet?.id != destinationWallet?.id
        }
    }
    
    /// `true` si la nota es válida
    var hasValidNote: Bool {
        guard let note else { return true }
        return note.count <= AppConfig.Limits.maxTransactionNoteLength
    }
    
    // MARK: - Initializer
    
    init(
        id: UUID = UUID(),
        amount: Double,
        type: TransactionType,
        note: String? = nil,
        date: Date = .now,
        isConfirmed: Bool = true,
        isRecurring: Bool = false,
        subscriptionID: UUID? = nil,
        merchantName: String? = nil,
        receiptImagePath: String? = nil,
        category: Category? = nil,
        wallet: Wallet? = nil,
        destinationWallet: Wallet? = nil,
        tags: [Tag]? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.amount = abs(amount) // Siempre positivo
        self.typeRaw = type.rawValue
        self.note = note?.prefix(AppConfig.Limits.maxTransactionNoteLength).description
        self.date = date
        self.isConfirmed = isConfirmed
        self.isRecurring = isRecurring
        self.subscriptionID = subscriptionID
        self.merchantName = merchantName
        self.receiptImagePath = receiptImagePath
        self.category = category
        self.wallet = wallet
        self.destinationWallet = destinationWallet
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        // Store currency code from wallet for safety
        self.currencyCode = wallet?.currencyCode
    }
}

// MARK: - Transaction Type

/// Tipo de transacción financiera.
enum TransactionType: String, CaseIterable, Codable, Identifiable, Sendable {
    case income     // Ingreso
    case expense    // Gasto
    case transfer   // Transferencia entre wallets
    
    var id: String { rawValue }
    
    /// Título localizado
    var title: String {
        switch self {
        case .income:   return "Ingreso"
        case .expense:  return "Gasto"
        case .transfer: return "Transferencia"
        }
    }
    
    /// Título en plural
    var pluralTitle: String {
        switch self {
        case .income:   return "Ingresos"
        case .expense:  return "Gastos"
        case .transfer: return "Transferencias"
        }
    }
    
    /// Título por defecto cuando no hay nota
    var defaultTitle: String {
        switch self {
        case .income:   return "Ingreso"
        case .expense:  return "Gasto"
        case .transfer: return "Transferencia"
        }
    }
    
    /// SF Symbol representativo
    var systemImageName: String {
        switch self {
        case .income:   return "arrow.down.circle.fill"
        case .expense:  return "arrow.up.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        }
    }
    
    /// Color por defecto
    var defaultColor: FCardColor {
        switch self {
        case .income:   return .green
        case .expense:  return .red
        case .transfer: return .blue
        }
    }
    
    /// Color del monto en UI
    var amountColor: FCardColor {
        switch self {
        case .income:   return .green
        case .expense:  return .red
        case .transfer: return .blue
        }
    }
    
    /// Descripción de ayuda
    var helpDescription: String {
        switch self {
        case .income:
            return "Dinero que recibes (salario, ventas, etc.)"
        case .expense:
            return "Dinero que gastas (compras, servicios, etc.)"
        case .transfer:
            return "Mover dinero entre tus propias cuentas"
        }
    }
    
    /// `true` si requiere categoría
    var requiresCategory: Bool {
        self != .transfer
    }
    
    /// `true` si afecta el balance negativamente
    var isOutflow: Bool {
        self == .expense || self == .transfer
    }
}

// MARK: - Transaction Extensions

extension Transaction {
    
    /// Crea una copia de la transacción (para duplicar)
    func duplicate() -> Transaction {
        Transaction(
            amount: amount,
            type: type,
            note: note,
            date: .now,
            isConfirmed: isConfirmed,
            isRecurring: false,
            category: category,
            wallet: wallet,
            destinationWallet: destinationWallet,
            tags: tags
        )
    }
}

// MARK: - Sample Data (Debug)

#if DEBUG
extension Transaction {
    
    /// Transacciones de ejemplo para previews
    static func sampleTransactions() -> [Transaction] {
        [
            Transaction(
                amount: 5000,
                type: .income,
                note: "Pago quincenal",
                date: .now
            ),
            Transaction(
                amount: 350,
                type: .expense,
                note: "Almuerzo con amigos",
                date: Calendar.current.date(byAdding: .day, value: -1, to: .now)!
            ),
            Transaction(
                amount: 1200,
                type: .expense,
                note: "Supermercado",
                date: Calendar.current.date(byAdding: .day, value: -2, to: .now)!
            ),
            Transaction(
                amount: 500,
                type: .transfer,
                note: "Ahorro mensual",
                date: Calendar.current.date(byAdding: .day, value: -3, to: .now)!
            ),
        ]
    }
}
#endif
