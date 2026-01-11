//
//  WalletsViewModel.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/24/25.
//  Updated on 01/11/26 - Production-ready:
//    - Front wallet (highest sortOrder) = default wallet
//    - Restored wallets go to back (lowest sortOrder)
//    - Optimized reordering with auto-default sync
//    - Clean task cancellation patterns
//

import SwiftUI
import SwiftData

// MARK: - Wallets ViewModel

@Observable
@MainActor
final class WalletsViewModel {
    
    // MARK: - Dependencies
    
    private var modelContext: ModelContext?
    
    // MARK: - Data State
    
    private(set) var wallets: [Wallet] = []
    private(set) var archivedWallets: [Wallet] = []
    
    // MARK: - Error State
    
    var error: WalletError? = nil
    
    // MARK: - Selection State
    
    var selectedWallet: Wallet? = nil
    var selectedWalletID: UUID? = nil
    private var walletPendingAction: Wallet? = nil
    
    // MARK: - Navigation State
    
    var isDetailPresented: Bool = false
    var isEditorPresented: Bool = false
    var isBalanceAdjustmentPresented: Bool = false
    private(set) var editorMode: WalletEditorMode = .create
    
    // MARK: - Alert State
    
    var isArchiveAlertPresented: Bool = false
    var isDeleteAlertPresented: Bool = false
    
    // MARK: - Computed Properties
    
    var isConfigured: Bool { modelContext != nil }
    var isEmpty: Bool { wallets.isEmpty }
    var walletsCount: Int { wallets.count }
    var archivedCount: Int { archivedWallets.count }
    var isLimitReached: Bool { walletsCount >= AppConfig.Limits.maxWallets }
    
    /// Default wallet = front wallet (last in sortOrder)
    var defaultWallet: Wallet? { wallets.last }
    
    // MARK: - Balance Calculations
    
    var totalBalance: Double {
        wallets.reduce(0) { $0 + $1.currentBalance }
    }
    
    var formattedTotalBalance: String {
        totalBalance.asCurrency()
    }
    
    var monthlyIncome: Double { 0 } // TODO: Calculate from transactions
    var monthlyExpenses: Double { 0 } // TODO: Calculate from transactions
    var monthlyNetBalance: Double { monthlyIncome - monthlyExpenses }
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Configuration
    
    func configure(with context: ModelContext) {
        guard modelContext == nil else { return }
        modelContext = context
        loadWallets()
        normalizeDefaultWallet()
    }
    
    // MARK: - Data Loading
    
    func loadWallets() {
        guard let context = modelContext else { return }
        
        var activeDescriptor = FetchDescriptor<Wallet>(
            predicate: #Predicate { !$0.isArchived }
        )
        activeDescriptor.sortBy = [
            SortDescriptor(\Wallet.sortOrder, order: .forward),
            SortDescriptor(\Wallet.createdAt, order: .forward)
        ]
        
        var archivedDescriptor = FetchDescriptor<Wallet>(
            predicate: #Predicate { $0.isArchived }
        )
        archivedDescriptor.sortBy = [SortDescriptor(\Wallet.updatedAt, order: .reverse)]
        
        do {
            wallets = try context.fetch(activeDescriptor)
            archivedWallets = try context.fetch(archivedDescriptor)
            
            if AppConfig.isDebugMode {
                print("✅ WalletsViewModel: Loaded \(wallets.count) active, \(archivedWallets.count) archived")
            }
        } catch {
            self.error = .loadFailed
            print("❌ WalletsViewModel: Load error - \(error)")
        }
    }
    
    // MARK: - Default Wallet Normalization
    
    /// Ensures exactly one wallet (the front/last one) is marked as default
    private func normalizeDefaultWallet() {
        guard !wallets.isEmpty else { return }
        
        // Clear all defaults
        for wallet in wallets where wallet.isDefault {
            wallet.isDefault = false
            wallet.updatedAt = .now
        }
        
        // Set last (front) as default
        wallets.last?.isDefault = true
        wallets.last?.updatedAt = .now
        
        save()
        
        if AppConfig.isDebugMode {
            print("✅ WalletsViewModel: Default normalized to '\(wallets.last?.name ?? "nil")'")
        }
    }
    
    // MARK: - CRUD Operations
    
    enum CreateWalletResult: Sendable {
        case success(walletID: UUID)
        case limitReached
        case saveFailed
        case contextNotConfigured
    }
    
    /// Creates a new wallet at the front (becomes default)
    @discardableResult
    func createWallet(
        name: String,
        type: WalletType,
        icon: FWalletIcon? = nil,
        color: FCardColor,
        currencyCode: String,
        initialBalance: Double,
        isDefault: Bool = false,
        paymentReminderDay: Int? = nil,
        notes: String? = nil,
        lastFourDigits: String? = nil
    ) -> CreateWalletResult {
        guard let context = modelContext else {
            return .contextNotConfigured
        }
        
        guard !isLimitReached else {
            error = .limitReached
            return .limitReached
        }
        
        clearDefaultStatus()
        
        let wallet = Wallet(
            name: name,
            type: type,
            icon: icon,
            color: color,
            currencyCode: currencyCode,
            initialBalance: initialBalance,
            isDefault: true, // New wallet goes to front = default
            sortOrder: nextSortOrder(),
            paymentReminderDay: paymentReminderDay,
            notes: notes,
            lastFourDigits: lastFourDigits
        )
        
        context.insert(wallet)
        
        do {
            try context.save()
            loadWallets()
            
            if AppConfig.isDebugMode {
                print("✅ WalletsViewModel: Created '\(name)' at front")
            }
            
            return .success(walletID: wallet.id)
        } catch {
            self.error = .saveFailed
            return .saveFailed
        }
    }
    
    @discardableResult
    func updateWallet(_ wallet: Wallet) -> Bool {
        wallet.updatedAt = .now
        
        if save() {
            loadWallets()
            return true
        }
        return false
    }
    
    /// Sets wallet as default by moving it to front
    @discardableResult
    func setAsDefault(_ wallet: Wallet) -> Bool {
        guard let currentIndex = wallets.firstIndex(where: { $0.id == wallet.id }) else {
            return false
        }
        
        let lastIndex = wallets.count - 1
        
        if currentIndex == lastIndex {
            // Already at front, just ensure isDefault flag
            if !wallet.isDefault {
                clearDefaultStatus()
                wallet.isDefault = true
                wallet.updatedAt = .now
                return save()
            }
            return true
        }
        
        // Move to front
        moveWallet(from: IndexSet(integer: currentIndex), to: lastIndex + 1)
        return true
    }
    
    @discardableResult
    func adjustBalance(_ wallet: Wallet, newBalance: Double, reason: String? = nil) -> Bool {
        wallet.currentBalance = newBalance
        wallet.updatedAt = .now
        
        if save() {
            loadWallets()
            return true
        }
        return false
    }
    
    @discardableResult
    func archiveWallet(_ wallet: Wallet) -> Bool {
        // Cannot archive the front (default) wallet
        guard wallet.id != wallets.last?.id else {
            error = .cannotArchiveDefault
            return false
        }
        
        wallet.isArchived = true
        wallet.isDefault = false
        wallet.updatedAt = .now
        
        if save() {
            loadWallets()
            normalizeDefaultWallet()
            return true
        }
        return false
    }
    
    /// Restores a wallet to the BACK (lowest sortOrder), preserving current default
    @discardableResult
    func restoreWallet(_ wallet: Wallet) -> Bool {
        // Shift all existing wallets up by 1
        for w in wallets {
            w.sortOrder += 1
            w.updatedAt = .now
        }
        
        // Place restored wallet at the back (sortOrder 0)
        wallet.isArchived = false
        wallet.isDefault = false // NOT default - keep current default
        wallet.sortOrder = 0
        wallet.updatedAt = .now
        
        if save() {
            loadWallets()
            return true
        }
        return false
    }
    
    @discardableResult
    func deleteWallet(_ wallet: Wallet) -> Bool {
        guard let context = modelContext else { return false }
        
        context.delete(wallet)
        
        if save() {
            loadWallets()
            normalizeDefaultWallet()
            return true
        }
        return false
    }
    
    // MARK: - Reordering
    
    /// Moves wallet and auto-syncs default to front wallet
    func moveWallet(from source: IndexSet, to destination: Int) {
        var reorderedWallets = wallets
        reorderedWallets.move(fromOffsets: source, toOffset: destination)
        
        for (index, wallet) in reorderedWallets.enumerated() {
            wallet.sortOrder = index
            wallet.updatedAt = .now
        }
        
        // Front wallet is default
        clearDefaultStatus()
        reorderedWallets.last?.isDefault = true
        
        _ = save()
        loadWallets()
        
        if AppConfig.isDebugMode {
            print("✅ WalletsViewModel: Reordered. Default: '\(wallets.last?.name ?? "nil")'")
        }
    }
    
    // MARK: - Navigation Actions
    
    func presentCreate() {
        guard !isLimitReached else {
            error = .limitReached
            return
        }
        
        editorMode = .create
        selectedWallet = nil
        isEditorPresented = true
    }
    
    func presentEdit(_ wallet: Wallet) {
        editorMode = .edit(wallet)
        selectedWallet = wallet
        isEditorPresented = true
    }
    
    func presentDetail(_ wallet: Wallet) {
        selectedWallet = wallet
        selectedWalletID = wallet.id
        
        withAnimation(Constants.Animation.smoothSpring) {
            isDetailPresented = true
        }
    }
    
    func dismissDetail() {
        withAnimation(Constants.Animation.smoothSpring) {
            isDetailPresented = false
        }
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Constants.Timing.dismissCleanupDelay))
            selectedWallet = nil
            selectedWalletID = nil
        }
    }
    
    func presentBalanceAdjustment(_ wallet: Wallet) {
        selectedWallet = wallet
        isBalanceAdjustmentPresented = true
    }
    
    func presentArchiveAlert(_ wallet: Wallet) {
        walletPendingAction = wallet
        isArchiveAlertPresented = true
    }
    
    func presentDeleteAlert(_ wallet: Wallet) {
        walletPendingAction = wallet
        isDeleteAlertPresented = true
    }
    
    func dismissEditor() {
        isEditorPresented = false
        selectedWallet = nil
        editorMode = .create
    }
    
    func confirmArchive() {
        guard let wallet = walletPendingAction else { return }
        _ = archiveWallet(wallet)
        walletPendingAction = nil
        isArchiveAlertPresented = false
    }
    
    func confirmDelete() {
        guard let wallet = walletPendingAction else { return }
        _ = deleteWallet(wallet)
        walletPendingAction = nil
        isDeleteAlertPresented = false
    }
    
    func cancelPendingAction() {
        walletPendingAction = nil
        isArchiveAlertPresented = false
        isDeleteAlertPresented = false
    }
    
    // MARK: - Private Helpers
    
    @discardableResult
    private func save() -> Bool {
        do {
            try modelContext?.save()
            return true
        } catch {
            self.error = .saveFailed
            print("❌ WalletsViewModel: Save error - \(error)")
            return false
        }
    }
    
    private func nextSortOrder() -> Int {
        (wallets.map(\.sortOrder).max() ?? -1) + 1
    }
    
    private func clearDefaultStatus() {
        for wallet in wallets where wallet.isDefault {
            wallet.isDefault = false
            wallet.updatedAt = .now
        }
    }
}

// MARK: - Wallet Error

enum WalletError: Error, LocalizedError, Identifiable, Sendable {
    case notFound
    case duplicateName
    case saveFailed
    case loadFailed
    case invalidData
    case limitReached
    case cannotArchiveDefault
    case hasTransactions
    
    var id: String { localizedDescription }
    
    var errorDescription: String? {
        switch self {
        case .notFound: return "Billetera no encontrada"
        case .duplicateName: return "Ya existe una billetera con ese nombre"
        case .saveFailed: return "Error al guardar los cambios"
        case .loadFailed: return "Error al cargar las billeteras"
        case .invalidData: return "Datos inválidos"
        case .limitReached: return "Has alcanzado el límite de \(AppConfig.Limits.maxWallets) billeteras"
        case .cannotArchiveDefault: return "No puedes archivar la billetera principal"
        case .hasTransactions: return "Esta billetera tiene transacciones asociadas"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .limitReached: return "Archiva algunas billeteras que no uses"
        case .cannotArchiveDefault: return "Primero mueve otra billetera al frente"
        case .saveFailed, .loadFailed: return "Intenta de nuevo o reinicia la app"
        default: return nil
        }
    }
}

// MARK: - Wallet Editor Mode

enum WalletEditorMode: Equatable, Sendable {
    case create
    case edit(Wallet)
    
    var isEditing: Bool {
        if case .edit = self { return true }
        return false
    }
    
    var isCreating: Bool { self == .create }
    
    var wallet: Wallet? {
        if case .edit(let wallet) = self { return wallet }
        return nil
    }
    
    var navigationTitle: String {
        switch self {
        case .create: return "Nueva Billetera"
        case .edit: return "Editar Billetera"
        }
    }
    
    static func == (lhs: WalletEditorMode, rhs: WalletEditorMode) -> Bool {
        switch (lhs, rhs) {
        case (.create, .create): return true
        case (.edit(let l), .edit(let r)): return l.id == r.id
        default: return false
        }
    }
}
