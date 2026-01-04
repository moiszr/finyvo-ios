//
//  WalletEditorViewModel.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/24/25.
//  ViewModel para el formulario de crear/editar billetera.
//
//  v2.1 - Swift 6 refinements:
//  - Sendable conformance donde aplica
//  - MainActor isolation para operaciones UI
//  - Sanitización mejorada de inputs
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
        }
    }
    
    var icon: FWalletIcon = .bank
    var color: FCardColor = .blue
    var currencyCode: String = AppConfig.Defaults.currencyCode
    
    var initialBalanceString: String = "" {
        didSet {
            // Sanitización: permitir solo dígitos, punto y coma como separador decimal
            let sanitized = sanitizeDecimalInput(initialBalanceString)
            if sanitized != initialBalanceString {
                initialBalanceString = sanitized
            }
        }
    }
    
    var lastFourDigits: String = "" {
        didSet {
            // Solo dígitos, máximo 4
            let filtered = lastFourDigits.filter { $0.isNumber }
            if filtered != lastFourDigits || filtered.count > 4 {
                lastFourDigits = String(filtered.prefix(4))
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
    
    // MARK: - Computed Properties
    
    var isEditing: Bool {
        mode.isEditing
    }
    
    /// Balance inicial parseado como Double
    var initialBalance: Double {
        let currency = CurrencyConfig.currency(for: currencyCode) ?? CurrencyConfig.defaultCurrency
        return currency.parse(initialBalanceString) ?? 0
    }
    
    /// Currency object actual
    var selectedCurrency: Currency? {
        CurrencyConfig.currency(for: currencyCode)
    }
    
    /// Símbolo de la moneda actual
    var currencySymbol: String {
        selectedCurrency?.symbol ?? currencyCode
    }
    
    /// Validación: nombre tiene al menos 2 caracteres
    var isValid: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 2 && trimmed.count <= AppConfig.Limits.maxWalletNameLength
    }
    
    /// Detecta si hay cambios sin guardar
    var hasChanges: Bool {
        guard let original = mode.wallet else {
            // En modo crear, hay cambios si el nombre es válido
            return name.trimmingCharacters(in: .whitespaces).count >= 2
        }
        
        // En modo editar, comparar con valores originales
        return name.trimmingCharacters(in: .whitespaces) != original.name ||
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
        
        // Set toggle states basados en valores existentes
        balanceEnabled = wallet.initialBalance != 0
        lastFourEnabled = !(wallet.lastFourDigits ?? "").isEmpty
        
        if let reminderDay = wallet.paymentReminderDay {
            paymentReminderEnabled = true
            paymentReminderDay = reminderDay
        }
        
        // Marcar como manualmente seleccionados ya que vienen del wallet
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
    
    /// Formatea un balance para mostrar en el input
    private func formatBalanceForInput(_ value: Double) -> String {
        if value == 0 { return "" }
        // Si es número entero, no mostrar decimales
        if value == floor(value) {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }
    
    /// Sanitiza input decimal permitiendo solo caracteres válidos
    private func sanitizeDecimalInput(_ input: String) -> String {
        var result = ""
        var hasDecimalSeparator = false
        var decimalCount = 0
        
        for char in input {
            if char.isNumber {
                // Limitar decimales según la moneda (generalmente 2)
                if hasDecimalSeparator {
                    guard decimalCount < 2 else { continue }
                    decimalCount += 1
                }
                result.append(char)
            } else if char == "." || char == "," {
                // Solo permitir un separador decimal
                guard !hasDecimalSeparator else { continue }
                hasDecimalSeparator = true
                result.append(".")  // Normalizar a punto
            } else if char == "-" && result.isEmpty {
                // Permitir signo negativo solo al inicio
                result.append(char)
            }
        }
        
        return result
    }
    
    // MARK: - Actions
    
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
    
    /// Aplica los cambios a un wallet existente (modo edición)
    @discardableResult
    func applyChanges(to wallet: Wallet) -> Bool {
        wallet.name = name.trimmingCharacters(in: .whitespaces)
        wallet.type = type
        wallet.icon = icon
        wallet.color = color
        wallet.currencyCode = currencyCode
        wallet.initialBalance = balanceEnabled ? initialBalance : 0
        wallet.isDefault = isDefault
        wallet.lastFourDigits = lastFourEnabled ? (lastFourDigits.isEmpty ? nil : lastFourDigits) : nil
        wallet.notes = notes.isEmpty ? nil : notes
        wallet.paymentReminderDay = paymentReminderEnabled ? paymentReminderDay : nil
        wallet.updatedAt = .now
        
        return true
    }
    
    /// Construye los datos para crear un nuevo wallet
    func buildNewWalletData() -> NewWalletData? {
        guard isValid else { return nil }
        
        return NewWalletData(
            name: name.trimmingCharacters(in: .whitespaces),
            type: type,
            icon: icon,
            color: color,
            currencyCode: currencyCode,
            initialBalance: balanceEnabled ? initialBalance : 0,
            isDefault: isDefault,
            paymentReminderDay: paymentReminderEnabled ? paymentReminderDay : nil,
            notes: notes.isEmpty ? nil : notes,
            lastFourDigits: lastFourEnabled ? (lastFourDigits.isEmpty ? nil : lastFourDigits) : nil
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
