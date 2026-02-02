//
//  TransactionEditorViewModel.swift
//  Finyvo
//
//  Created by Moises Núñez on 01/15/26.
//  ViewModel para el editor de transacciones.
//
//  Features:
//    - Create and edit modes
//    - Form validation
//    - Change tracking for edit mode
//    - Amount parsing with currency support
//    - Date/time selection
//

import SwiftUI
import SwiftData

// MARK: - Transaction Editor ViewModel

/// ViewModel para el editor de transacciones.
///
/// ## Responsabilidades
/// - Gestionar estado del formulario
/// - Validación en tiempo real
/// - Parseo de montos
/// - Detección de cambios
///
/// ## Uso
/// ```swift
/// let editor = TransactionEditorViewModel(mode: .create(type: .expense))
/// editor.amountString = "150.00"
/// editor.note = "Almuerzo"
///
/// if editor.isValid {
///     viewModel.createTransaction(...)
/// }
/// ```
@Observable
final class TransactionEditorViewModel {
    
    // MARK: - Form State
    
    /// Tipo de transacción
    var type: TransactionType {
        didSet {
            // Limpiar campos que no aplican al nuevo tipo
            if type == .transfer {
                category = nil
            } else {
                destinationWallet = nil
            }
        }
    }
    
    /// String del monto (para input)
    var amountString: String = "" {
        didSet {
            updateParsedAmount()
        }
    }
    
    /// Monto parseado
    private(set) var amount: Double = 0
    
    /// Nota/descripción
    var note: String = ""
    
    /// Fecha de la transacción
    var date: Date = .now
    
    /// Hora de la transacción
    var time: Date = .now
    
    /// Categoría seleccionada
    var category: Category?
    
    /// Wallet de origen
    var wallet: Wallet?
    
    /// Wallet destino (para transferencias)
    var destinationWallet: Wallet?
    
    /// Tags seleccionados
    var selectedTags: [Tag] = []
    
    /// Nombre del comercio (opcional)
    var merchantName: String = ""
    
    /// `true` si la transacción está confirmada
    var isConfirmed: Bool = true
    
    // MARK: - Mode
    
    /// Modo del editor
    let mode: TransactionEditorMode
    
    /// Transacción original (solo en modo edit)
    private let originalTransaction: Transaction?
    
    // MARK: - Original Values (for change detection)
    
    private let originalType: TransactionType
    private let originalAmount: Double
    private let originalNote: String
    private let originalDate: Date
    private let originalCategoryID: UUID?
    private let originalWalletID: UUID?
    private let originalDestinationWalletID: UUID?
    private let originalTagIDs: Set<UUID>
    private let originalMerchantName: String
    private let originalIsConfirmed: Bool
    
    // MARK: - Computed Properties
    
    /// `true` si es modo creación
    var isCreating: Bool {
        mode.isCreating
    }
    
    /// `true` si es modo edición
    var isEditing: Bool {
        mode.isEditing
    }
    
    /// Moneda del wallet seleccionado
    var currency: Currency? {
        wallet?.currency ?? CurrencyConfig.defaultCurrency
    }
    
    /// Símbolo de la moneda
    var currencySymbol: String {
        currency?.symbol ?? "$"
    }
    
    /// Fecha y hora combinadas
    var dateTime: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        
        return calendar.date(from: combined) ?? date
    }
    
    /// `true` si el monto es válido
    var isAmountValid: Bool {
        amount > 0
    }
    
    /// `true` si la categoría es requerida y está presente
    var isCategoryValid: Bool {
        if type == .transfer { return true }
        return category != nil
    }
    
    /// `true` si el wallet es válido
    var isWalletValid: Bool {
        wallet != nil
    }
    
    /// `true` si el destino es válido (para transferencias)
    var isDestinationValid: Bool {
        if type != .transfer { return true }
        guard let destWallet = destinationWallet else { return false }
        return destWallet.id != wallet?.id
    }
    
    /// `true` si la nota está dentro del límite
    var isNoteValid: Bool {
        note.count <= AppConfig.Limits.maxTransactionNoteLength
    }
    
    /// `true` si los tags están dentro del límite
    var isTagsValid: Bool {
        selectedTags.count <= AppConfig.Limits.maxTagsPerTransaction
    }
    
    /// `true` si todo el formulario es válido
    var isValid: Bool {
        isAmountValid &&
        isCategoryValid &&
        isWalletValid &&
        isDestinationValid &&
        isNoteValid &&
        isTagsValid
    }
    
    /// `true` si hay cambios respecto al original (solo en edit mode)
    var hasChanges: Bool {
        guard isEditing else { return true }
        
        return type != originalType ||
               amount != originalAmount ||
               note != originalNote ||
               !Calendar.current.isDate(dateTime, equalTo: originalDate, toGranularity: .minute) ||
               category?.id != originalCategoryID ||
               wallet?.id != originalWalletID ||
               destinationWallet?.id != originalDestinationWalletID ||
               Set(selectedTags.map(\.id)) != originalTagIDs ||
               merchantName != originalMerchantName ||
               isConfirmed != originalIsConfirmed
    }
    
    /// Monto formateado para display
    var formattedAmount: String {
        guard amount > 0 else { return "\(currencySymbol) 0.00" }
        return currency?.format(amount) ?? amount.asCurrency()
    }
    
    /// Caracteres restantes para la nota
    var noteCharactersRemaining: Int {
        AppConfig.Limits.maxTransactionNoteLength - note.count
    }
    
    /// Tags restantes disponibles
    var tagsRemaining: Int {
        AppConfig.Limits.maxTagsPerTransaction - selectedTags.count
    }
    
    // MARK: - Validation Messages
    
    /// Mensaje de error para el monto
    var amountErrorMessage: String? {
        guard !amountString.isEmpty else { return nil }
        if amount <= 0 { return "Ingresa un monto válido" }
        return nil
    }
    
    /// Mensaje de error para la categoría
    var categoryErrorMessage: String? {
        guard type != .transfer else { return nil }
        if category == nil { return "Selecciona una categoría" }
        return nil
    }
    
    /// Mensaje de error para el wallet
    var walletErrorMessage: String? {
        if wallet == nil { return "Selecciona una billetera" }
        return nil
    }
    
    /// Mensaje de error para el destino
    var destinationErrorMessage: String? {
        guard type == .transfer else { return nil }
        if destinationWallet == nil { return "Selecciona el destino" }
        if destinationWallet?.id == wallet?.id { return "Debe ser diferente al origen" }
        return nil
    }
    
    // MARK: - Initialization
    
    init(mode: TransactionEditorMode) {
        self.mode = mode
        
        switch mode {
        case .create(let type):
            self.type = type
            self.originalTransaction = nil
            self.originalType = type
            self.originalAmount = 0
            self.originalNote = ""
            self.originalDate = .now
            self.originalCategoryID = nil
            self.originalWalletID = nil
            self.originalDestinationWalletID = nil
            self.originalTagIDs = []
            self.originalMerchantName = ""
            self.originalIsConfirmed = true
            
        case .edit(let transaction):
            self.type = transaction.type
            self.originalTransaction = transaction
            self.originalType = transaction.type
            self.originalAmount = transaction.amount
            self.originalNote = transaction.note ?? ""
            self.originalDate = transaction.date
            self.originalCategoryID = transaction.category?.id
            self.originalWalletID = transaction.wallet?.id
            self.originalDestinationWalletID = transaction.destinationWallet?.id
            self.originalTagIDs = Set(transaction.tags?.map(\.id) ?? [])
            self.originalMerchantName = transaction.merchantName ?? ""
            self.originalIsConfirmed = transaction.isConfirmed
            
            // Cargar valores actuales
            self.amountString = formatAmountForInput(transaction.amount)
            self.amount = transaction.amount
            self.note = transaction.note ?? ""
            self.date = transaction.date
            self.time = transaction.date
            self.category = transaction.category
            self.wallet = transaction.wallet
            self.destinationWallet = transaction.destinationWallet
            self.selectedTags = transaction.tags ?? []
            self.merchantName = transaction.merchantName ?? ""
            self.isConfirmed = transaction.isConfirmed
        }
    }
    
    // MARK: - Actions
    
    /// Aplica los cambios a la transacción (en modo edit).
    ///
    /// - Parameter transaction: Transacción a actualizar
    /// - Returns: `true` si se aplicaron cambios
    @discardableResult
    func applyChanges(to transaction: Transaction) -> Bool {
        guard isValid else { return false }
        
        transaction.type = type
        transaction.amount = amount
        transaction.note = note.isEmpty ? nil : note
        transaction.date = dateTime
        transaction.category = category
        transaction.wallet = wallet
        transaction.destinationWallet = destinationWallet
        transaction.tags = selectedTags.isEmpty ? nil : selectedTags
        transaction.merchantName = merchantName.isEmpty ? nil : merchantName
        transaction.isConfirmed = isConfirmed
        transaction.updatedAt = .now
        
        return true
    }
    
    /// Toggle un tag
    func toggleTag(_ tag: Tag) {
        if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
            selectedTags.remove(at: index)
        } else if selectedTags.count < AppConfig.Limits.maxTagsPerTransaction {
            selectedTags.append(tag)
        }
    }
    
    /// Remueve un tag
    func removeTag(_ tag: Tag) {
        selectedTags.removeAll { $0.id == tag.id }
    }
    
    /// Limpia todos los tags
    func clearTags() {
        selectedTags.removeAll()
    }
    
    /// Resetea el formulario (solo en modo create)
    func reset() {
        guard isCreating else { return }
        
        amountString = ""
        amount = 0
        note = ""
        date = .now
        time = .now
        category = nil
        destinationWallet = nil
        selectedTags = []
        merchantName = ""
        isConfirmed = true
        // Mantener wallet y type
    }
    
    // MARK: - Amount Parsing
    
    /// Actualiza el monto parseado desde el string.
    private func updateParsedAmount() {
        guard let currency else {
            amount = Double(amountString.replacingOccurrences(of: ",", with: ".")) ?? 0
            return
        }
        
        amount = currency.parse(amountString) ?? 0
    }
    
    /// Formatea un monto para input.
    private func formatAmountForInput(_ value: Double) -> String {
        if value == 0 { return "" }
        if value == floor(value) {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }
    
    // MARK: - Convenience Setters
    
    /// Establece el wallet y actualiza la moneda.
    func setWallet(_ newWallet: Wallet?) {
        wallet = newWallet
        // Re-parsear el monto con la nueva moneda
        updateParsedAmount()
    }
    
    /// Establece la fecha desde un DatePicker.
    func setDate(_ newDate: Date) {
        date = newDate
    }
    
    /// Establece la hora desde un DatePicker.
    func setTime(_ newTime: Date) {
        time = newTime
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension TransactionEditorViewModel {
    
    /// ViewModel de ejemplo para previews
    static var preview: TransactionEditorViewModel {
        let vm = TransactionEditorViewModel(mode: .create(type: .expense))
        vm.amountString = "150"
        vm.note = "Almuerzo con amigos"
        return vm
    }
    
    /// ViewModel de ejemplo en modo edición
    static var previewEdit: TransactionEditorViewModel {
        let transaction = Transaction(
            amount: 250,
            type: .expense,
            note: "Supermercado semanal",
            date: .now
        )
        return TransactionEditorViewModel(mode: .edit(transaction))
    }
}
#endif
