//
//  WalletEditorViewModel.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/24/25.
//  ViewModel para el formulario de crear/editar billetera.
//
//  v2.3 - Production Optimizations:
//  - hasChanges mejorado para modo create (detecta TODOS los cambios)
//  - Limpieza de lastFourDigits al cambiar tipo que no soporta tarjeta
//  - trim whitespacesAndNewlines para mejor sanitización
//  - Sanitización decimal alineada a moneda
//  - Haptics delegados a la View layer
//

import SwiftUI

// MARK: - Wallet Editor ViewModel

@Observable
@MainActor
final class WalletEditorViewModel {
    
    // MARK: - Mode
    
    let mode: WalletEditorMode
    
    // MARK: - Form Fields
    
    var name: String = "" {
        didSet {
            if name.count > AppConfig.Limits.maxWalletNameLength {
                name = String(name.prefix(AppConfig.Limits.maxWalletNameLength))
            }
        }
    }
    
    var type: WalletType = .checking {
        didSet {
            guard oldValue != type else { return }
            
            // Auto-update icon/color si no fueron modificados manualmente
            if !iconSetManually {
                icon = type.defaultIcon
            }
            if !colorSetManually {
                color = type.defaultColor
            }
            
            // Reset payment reminder si el tipo no lo soporta
            if !type.supportsPaymentReminder {
                paymentReminderEnabled = false
                paymentReminderDay = 15
            }
            
            // Limpiar lastFourDigits si el tipo no soporta tarjeta
            if !type.supportsLastFourDigits {
                lastFourDigits = ""
                lastFourEnabled = false
            }
        }
    }
    
    var icon: FWalletIcon = .bank
    var color: FCardColor = .blue
    var currencyCode: String = AppConfig.Defaults.currencyCode
    
    var initialBalanceString: String = "" {
        didSet {
            let sanitized = sanitizeDecimalInput(initialBalanceString)
            if sanitized != initialBalanceString {
                initialBalanceString = sanitized
            }
        }
    }
    
    var lastFourDigits: String = "" {
        didSet {
            let sanitized = String(lastFourDigits.filter(\.isNumber).prefix(4))
            if sanitized != lastFourDigits {
                lastFourDigits = sanitized
            }
        }
    }
    
    var notes: String = "" {
        didSet {
            if notes.count > AppConfig.Limits.maxWalletNotesLength {
                notes = String(notes.prefix(AppConfig.Limits.maxWalletNotesLength))
            }
        }
    }
    
    var isDefault: Bool = false
    var paymentReminderEnabled: Bool = false
    var paymentReminderDay: Int = 15
    
    // Toggle states para secciones expandibles
    var balanceEnabled: Bool = false
    var lastFourEnabled: Bool = false
    
    // MARK: - Manual Selection Tracking
    
    private(set) var iconSetManually: Bool = false
    private(set) var colorSetManually: Bool = false
    
    // MARK: - Initial Values for Change Detection (Create Mode)
    
    private let initialType: WalletType
    private let initialIcon: FWalletIcon
    private let initialColor: FCardColor
    private let initialCurrencyCode: String
    private let initialIsDefault: Bool
    private let initialPaymentReminderEnabled: Bool
    private let initialPaymentReminderDay: Int
    
    // MARK: - Computed Properties
    
    var isEditing: Bool {
        mode.isEditing
    }
    
    var initialBalance: Double {
        let currency = CurrencyConfig.currency(for: currencyCode) ?? CurrencyConfig.defaultCurrency
        return currency.parse(initialBalanceString) ?? 0
    }
    
    var selectedCurrency: Currency? {
        CurrencyConfig.currency(for: currencyCode)
    }
    
    var currencySymbol: String {
        selectedCurrency?.symbol ?? currencyCode
    }
    
    var isValid: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2 && trimmed.count <= AppConfig.Limits.maxWalletNameLength
    }
    
    /// Detecta si hay cambios sin guardar (incluye TODOS los campos en modo create)
    var hasChanges: Bool {
        guard let original = mode.wallet else {
            // En modo crear: detectar CUALQUIER cambio desde valores iniciales
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            
            return !trimmedName.isEmpty ||
                   type != initialType ||
                   iconSetManually ||
                   colorSetManually ||
                   currencyCode != initialCurrencyCode ||
                   !initialBalanceString.isEmpty ||
                   !lastFourDigits.isEmpty ||
                   isDefault != initialIsDefault ||
                   paymentReminderEnabled != initialPaymentReminderEnabled ||
                   paymentReminderDay != initialPaymentReminderDay ||
                   !notes.isEmpty
        }
        
        // En modo editar, comparar con valores originales
        return name.trimmingCharacters(in: .whitespacesAndNewlines) != original.name ||
               type != original.type ||
               icon != original.icon ||
               color != original.color ||
               currencyCode != original.currencyCode ||
               initialBalance != original.initialBalance ||
               isDefault != original.isDefault ||
               paymentReminderDay != (original.paymentReminderDay ?? 15) ||
               paymentReminderEnabled != original.hasPaymentReminder ||
               lastFourDigits != (original.lastFourDigits ?? "") ||
               notes != (original.notes ?? "")
    }
    
    var supportsPaymentReminder: Bool {
        type.supportsPaymentReminder
    }
    
    var availableReminderDays: [Int] {
        Array(1...28)
    }
    
    // MARK: - Initialization
    
    init(mode: WalletEditorMode) {
        self.mode = mode
        
        let defaultType: WalletType = .checking
        self.initialType = defaultType
        self.initialIcon = defaultType.defaultIcon
        self.initialColor = defaultType.defaultColor
        self.initialCurrencyCode = AppConfig.Defaults.currencyCode
        self.initialIsDefault = false
        self.initialPaymentReminderEnabled = false
        self.initialPaymentReminderDay = 15
        
        if let wallet = mode.wallet {
            populateFromWallet(wallet)
        } else {
            applyDefaults()
        }
    }
    
    convenience init() {
        self.init(mode: .create)
    }
    
    convenience init(editing wallet: Wallet) {
        self.init(mode: .edit(wallet))
    }
    
    // MARK: - Setup Helpers
    
    private func populateFromWallet(_ wallet: Wallet) {
        name = wallet.name
        type = wallet.type
        icon = wallet.icon
        color = wallet.color
        currencyCode = wallet.currencyCode
        initialBalanceString = formatBalanceForInput(wallet.initialBalance)
        isDefault = wallet.isDefault
        lastFourDigits = wallet.lastFourDigits ?? ""
        notes = wallet.notes ?? ""
        
        balanceEnabled = wallet.initialBalance != 0
        lastFourEnabled = !(wallet.lastFourDigits ?? "").isEmpty
        
        if let reminderDay = wallet.paymentReminderDay {
            paymentReminderEnabled = true
            paymentReminderDay = reminderDay
        }
        
        iconSetManually = true
        colorSetManually = true
    }
    
    private func applyDefaults() {
        type = .checking
        icon = type.defaultIcon
        color = type.defaultColor
        currencyCode = AppConfig.Defaults.currencyCode
        iconSetManually = false
        colorSetManually = false
        balanceEnabled = false
        lastFourEnabled = false
    }
    
    private func formatBalanceForInput(_ value: Double) -> String {
        if value == 0 { return "" }
        if value == floor(value) {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }
    
    /// Sanitiza input decimal considerando los decimales de la moneda actual
    private func sanitizeDecimalInput(_ input: String) -> String {
        var result = ""
        var hasDecimalSeparator = false
        var decimalCount = 0
        
        let maxDecimals = selectedCurrency?.decimalDigits ?? 2
        
        for char in input {
            if char.isNumber {
                if hasDecimalSeparator {
                    guard decimalCount < maxDecimals else { continue }
                    decimalCount += 1
                }
                result.append(char)
            } else if char == "." || char == "," {
                guard !hasDecimalSeparator else { continue }
                guard maxDecimals > 0 else { continue }
                hasDecimalSeparator = true
                result.append(".")
            } else if char == "-" && result.isEmpty {
                result.append(char)
            }
        }
        
        return result
    }
    
    // MARK: - Actions
    // Note: Haptics are handled by the View layer for better separation of concerns
    
    func selectIcon(_ newIcon: FWalletIcon) {
        icon = newIcon
        iconSetManually = true
        Constants.Haptic.light()
    }
    
    func selectColor(_ newColor: FCardColor) {
        color = newColor
        colorSetManually = true
        Constants.Haptic.light()
    }
    
    func selectCurrency(_ code: String) {
        currencyCode = code
        Constants.Haptic.light()
    }
    
    func selectType(_ newType: WalletType) {
        type = newType
        Constants.Haptic.light()
    }
    
    // MARK: - Save Actions
    
    @discardableResult
    func applyChanges(to wallet: Wallet) -> Bool {
        wallet.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        wallet.type = type
        wallet.icon = icon
        wallet.color = color
        wallet.currencyCode = currencyCode
        wallet.initialBalance = balanceEnabled ? initialBalance : 0
        wallet.isDefault = isDefault
        
        // Solo guardar lastFour si el tipo lo soporta Y está habilitado
        if type.supportsLastFourDigits && lastFourEnabled && !lastFourDigits.isEmpty {
            wallet.lastFourDigits = lastFourDigits
        } else {
            wallet.lastFourDigits = nil
        }
        
        wallet.notes = notes.isEmpty ? nil : notes
        wallet.paymentReminderDay = paymentReminderEnabled ? paymentReminderDay : nil
        wallet.updatedAt = .now
        
        return true
    }
    
    func buildNewWalletData() -> NewWalletData? {
        guard isValid else { return nil }
        
        // Solo incluir lastFour si el tipo lo soporta
        let finalLastFour: String?
        if type.supportsLastFourDigits && lastFourEnabled && !lastFourDigits.isEmpty {
            finalLastFour = lastFourDigits
        } else {
            finalLastFour = nil
        }
        
        return NewWalletData(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            type: type,
            icon: icon,
            color: color,
            currencyCode: currencyCode,
            initialBalance: balanceEnabled ? initialBalance : 0,
            isDefault: isDefault,
            paymentReminderDay: paymentReminderEnabled ? paymentReminderDay : nil,
            notes: notes.isEmpty ? nil : notes,
            lastFourDigits: finalLastFour
        )
    }
}

// MARK: - New Wallet Data

struct NewWalletData: Sendable {
    let name: String
    let type: WalletType
    let icon: FWalletIcon
    let color: FCardColor
    let currencyCode: String
    let initialBalance: Double
    let isDefault: Bool
    let paymentReminderDay: Int?
    let notes: String?
    let lastFourDigits: String?
}

// MARK: - WalletType Extension

extension WalletType {
    /// `true` si este tipo soporta últimos 4 dígitos (tarjetas)
    var supportsLastFourDigits: Bool {
        self == .creditCard || self == .debitCard
    }
}
