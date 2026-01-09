//
//  Wallet.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/24/25.
//  Modelo principal de billeteras/cuentas con soporte multi-currency.
//

import SwiftUI
import SwiftData

// MARK: - Wallet Model

/// Modelo principal de billetera/cuenta con soporte para SwiftData.
///
/// ## Arquitectura
/// - `typeRaw`: String persistido → `type`: WalletType computed
/// - `iconRaw`: String persistido → `icon`: FWalletIcon computed
/// - `colorRaw`: String persistido → `color`: FCardColor computed
///
/// ## Balance
/// - `initialBalance`: Balance al crear la wallet
/// - `currentBalance`: Balance actual (calculado de transacciones o ajustado manualmente)
///
/// ## Multi-Currency
/// - Cada wallet tiene su propia moneda (`currencyCode`)
/// - Los totales se convierten a la moneda preferida del usuario
@Model
final class Wallet {
    
    // MARK: - Persisted Properties
    
    /// Identificador único
    @Attribute(.unique)
    var id: UUID
    
    /// Nombre de la billetera (ej: "Banco Popular", "Efectivo")
    var name: String
    
    /// Tipo - almacena rawValue de WalletType
    var typeRaw: String
    
    /// Icono - almacena rawValue de FWalletIcon
    var iconRaw: String
    
    /// Color - almacena rawValue de FCardColor
    var colorRaw: String
    
    /// Código de moneda ISO 4217 (ej: "USD", "DOP")
    var currencyCode: String
    
    /// Balance inicial al crear la wallet
    var initialBalance: Double
    
    /// Balance actual (actualizado por transacciones o ajustes)
    var currentBalance: Double
    
    /// `true` si es la billetera principal/por defecto
    var isDefault: Bool
    
    /// `true` si está archivada (soft delete)
    var isArchived: Bool
    
    /// Orden de visualización en la lista
    var sortOrder: Int
    
    /// Día del mes para recordatorio de pago (1-28, solo para tarjetas de crédito)
    /// `nil` si no tiene recordatorio configurado
    var paymentReminderDay: Int?
    
    /// Notas opcionales del usuario
    var notes: String?
    
    /// Últimos 4 dígitos (opcional, para identificación visual)
    var lastFourDigits: String?
    
    /// Fecha de creación
    var createdAt: Date
    
    /// Fecha de última actualización
    var updatedAt: Date
    
    // MARK: - Relationships (Future)
    
    // var transactions: [Transaction]?
    
    // MARK: - Computed Properties (Type-Safe Access)
    
    /// Tipo de billetera
    var type: WalletType {
        get { WalletType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }
    
    /// Icono de la billetera
    var icon: FWalletIcon {
        get { FWalletIcon(rawValue: iconRaw) ?? .wallet }
        set { iconRaw = newValue.rawValue }
    }
    
    /// Color de la billetera
    var color: FCardColor {
        get { FCardColor(rawValue: colorRaw) ?? .blue }
        set { colorRaw = newValue.rawValue }
    }
    
    /// Nombre del SF Symbol para `Image(systemName:)`
    var systemImageName: String {
        icon.systemName
    }
    
    /// Moneda completa desde CurrencyConfig
    var currency: Currency? {
        CurrencyConfig.currency(for: currencyCode)
    }
    
    /// Símbolo de la moneda
    var currencySymbol: String {
        currency?.symbol ?? currencyCode
    }
    
    // MARK: - Display Helpers
    
    /// Balance formateado con moneda
    var formattedBalance: String {
        currentBalance.asCurrency(code: currencyCode)
    }
    
    /// Balance formateado compacto
    var formattedBalanceCompact: String {
        currentBalance.asCompactCurrency(code: currencyCode)
    }
    
    /// `true` si el balance es negativo (deuda)
    var isNegativeBalance: Bool {
        currentBalance < 0
    }
    
    /// `true` si es una tarjeta de crédito
    var isCreditCard: Bool {
        type == .creditCard
    }
    
    /// `true` si tiene recordatorio de pago configurado
    var hasPaymentReminder: Bool {
        paymentReminderDay != nil
    }
    
    /// Descripción corta del tipo
    var typeDescription: String {
        type.title
    }
    
    /// Nombre para mostrar (incluye últimos 4 dígitos si existe)
    var displayName: String {
        if let lastFour = lastFourDigits, !lastFour.isEmpty {
            return "\(name) •••• \(lastFour)"
        }
        return name
    }
    
    // MARK: - Validation
    
    /// `true` si el nombre es válido
    var hasValidName: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 2 && trimmed.count <= AppConfig.Limits.maxWalletNameLength
    }
    
    // MARK: - Initializer
    
    init(
        id: UUID = UUID(),
        name: String,
        type: WalletType,
        icon: FWalletIcon? = nil,
        color: FCardColor = .blue,
        currencyCode: String = AppConfig.Defaults.currencyCode,
        initialBalance: Double = 0,
        currentBalance: Double? = nil,
        isDefault: Bool = false,
        isArchived: Bool = false,
        sortOrder: Int = 0,
        paymentReminderDay: Int? = nil,
        notes: String? = nil,
        lastFourDigits: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = String(name.prefix(AppConfig.Limits.maxWalletNameLength))
        self.typeRaw = type.rawValue
        self.iconRaw = (icon ?? type.defaultIcon).rawValue
        self.colorRaw = color.rawValue
        self.currencyCode = currencyCode
        self.initialBalance = initialBalance
        self.currentBalance = currentBalance ?? initialBalance
        self.isDefault = isDefault
        self.isArchived = isArchived
        self.sortOrder = sortOrder
        self.paymentReminderDay = paymentReminderDay
        self.notes = notes
        self.lastFourDigits = lastFourDigits
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Wallet Type

/// Tipo de billetera/cuenta.
enum WalletType: String, CaseIterable, Codable, Identifiable, Sendable {
    case cash           // Efectivo
    case checking       // Cuenta corriente
    case savings        // Cuenta de ahorros
    case creditCard     // Tarjeta de crédito
    case debitCard      // Tarjeta de débito
    case digitalWallet  // PayPal, Venmo, etc.
    case investment     // Inversiones
    case crypto         // Criptomonedas
    case other          // Otros
    
    var id: String { rawValue }
    
    /// Título localizado
    var title: String {
        switch self {
        case .cash:          return "Efectivo"
        case .checking:      return "Cuenta Corriente"
        case .savings:       return "Cuenta de Ahorros"
        case .creditCard:    return "Tarjeta de Crédito"
        case .debitCard:     return "Tarjeta de Débito"
        case .digitalWallet: return "Billetera Digital"
        case .investment:    return "Inversiones"
        case .crypto:        return "Criptomonedas"
        case .other:         return "Otro"
        }
    }
    
    /// Título corto para UI compacta
    var shortTitle: String {
        switch self {
        case .cash:          return "Efectivo"
        case .checking:      return "Corriente"
        case .savings:       return "Ahorros"
        case .creditCard:    return "Crédito"
        case .debitCard:     return "Débito"
        case .digitalWallet: return "Digital"
        case .investment:    return "Inversión"
        case .crypto:        return "Crypto"
        case .other:         return "Otro"
        }
    }
    
    /// Icono por defecto para este tipo
    var defaultIcon: FWalletIcon {
        switch self {
        case .cash:          return .cash
        case .checking:      return .bank
        case .savings:       return .piggyBank
        case .creditCard:    return .creditCard
        case .debitCard:     return .creditCard
        case .digitalWallet: return .phone
        case .investment:    return .chart
        case .crypto:        return .crypto
        case .other:         return .wallet
        }
    }
    
    /// Color sugerido por defecto
    var defaultColor: FCardColor {
        switch self {
        case .cash:          return .green
        case .checking:      return .blue
        case .savings:       return .teal
        case .creditCard:    return .purple
        case .debitCard:     return .blue
        case .digitalWallet: return .orange
        case .investment:    return .teal
        case .crypto:        return .yellow
        case .other:         return .gray
        }
    }
    
    /// `true` si este tipo puede tener recordatorio de pago
    var supportsPaymentReminder: Bool {
        self == .creditCard
    }
    
    /// `true` si el balance típicamente es negativo (deuda)
    var isDebtType: Bool {
        self == .creditCard
    }
    
    /// Descripción para ayudar al usuario
    var helpDescription: String {
        switch self {
        case .cash:
            return "Dinero físico que tienes a mano"
        case .checking:
            return "Cuenta bancaria para uso diario"
        case .savings:
            return "Cuenta de ahorros o fondo de emergencia"
        case .creditCard:
            return "Tarjeta de crédito (el balance es lo que debes)"
        case .debitCard:
            return "Tarjeta de débito vinculada a tu banco"
        case .digitalWallet:
            return "PayPal, Venmo, Apple Cash, etc."
        case .investment:
            return "Cuentas de inversión o corretaje"
        case .crypto:
            return "Criptomonedas y tokens digitales"
        case .other:
            return "Otro tipo de cuenta"
        }
    }
}

// MARK: - Wallet Icon

/// Iconos SF Symbols para billeteras.
enum FWalletIcon: String, CaseIterable, Codable, Sendable {
    case cash = "banknote.fill"
    case bank = "building.columns.fill"
    case creditCard = "creditcard.fill"
    case wallet = "wallet.pass.fill"
    case phone = "iphone"
    case piggyBank = "dollarsign.circle.fill"
    case chart = "chart.line.uptrend.xyaxis"
    case crypto = "bitcoinsign.circle.fill"
    case globe = "globe.americas.fill"
    case briefcase = "briefcase.fill"
    case cart = "cart.fill"
    case gift = "gift.fill"
    case house = "house.fill"
    case car = "car.fill"
    case airplane = "airplane"
    case star = "star.fill"
    case heart = "heart.fill"
    case sparkles = "sparkles"
    
    var systemName: String { rawValue }
    
    /// Nombre legible para el usuario
    var displayName: String {
        switch self {
        case .cash:       return "Efectivo"
        case .bank:       return "Banco"
        case .creditCard: return "Tarjeta"
        case .wallet:     return "Billetera"
        case .phone:      return "Teléfono"
        case .piggyBank:  return "Ahorro"
        case .chart:      return "Inversión"
        case .crypto:     return "Crypto"
        case .globe:      return "Internacional"
        case .briefcase:  return "Negocios"
        case .cart:       return "Compras"
        case .gift:       return "Regalos"
        case .house:      return "Hogar"
        case .car:        return "Auto"
        case .airplane:   return "Viajes"
        case .star:       return "Favorito"
        case .heart:      return "Personal"
        case .sparkles:   return "Especial"
        }
    }
    
    /// Lista ordenada para selectores
    static var allOrdered: [FWalletIcon] {
        [
            .creditCard, .bank, .cash, .wallet, .piggyBank,
            .phone, .chart, .crypto, .globe, .briefcase,
            .cart, .gift, .house, .car, .airplane, .star,
            .heart, .sparkles
        ]
    }
}

// MARK: - Default Wallets

extension Wallet {
    
    /// Billeteras sugeridas para onboarding
    static func suggestedWallets() -> [Wallet] {
        [
            Wallet(
                name: "Efectivo",
                type: .cash,
                color: .green,
                isDefault: true,
                sortOrder: 0
            ),
            Wallet(
                name: "Banco Principal",
                type: .checking,
                color: .blue,
                sortOrder: 1
            ),
            Wallet(
                name: "Tarjeta de Crédito",
                type: .creditCard,
                color: .purple,
                sortOrder: 2
            )
        ]
    }
}
