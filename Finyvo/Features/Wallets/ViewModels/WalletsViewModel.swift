//
//  WalletsViewModel.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/24/25.
//  ViewModel principal para la gestión de billeteras.
//

import SwiftUI
import SwiftData

// MARK: - Wallets ViewModel

/// ViewModel principal para la gestión de billeteras.
///
/// ## Responsabilidades
/// - CRUD de billeteras via SwiftData
/// - Cálculo de balance total (multi-currency)
/// - Coordinación de navegación y animaciones
/// - Ajuste de balance manual
///
/// ## Uso
/// ```swift
/// @State private var viewModel = WalletsViewModel()
///
/// .onAppear {
///     viewModel.configure(with: modelContext)
/// }
/// ```
@Observable
final class WalletsViewModel {
    
    // MARK: - Dependencies
    
    private var modelContext: ModelContext?
    
    // MARK: - Data State
    
    /// Todas las billeteras activas (no archivadas)
    private(set) var wallets: [Wallet] = []
    
    /// Billeteras archivadas
    private(set) var archivedWallets: [Wallet] = []
    
    // MARK: - Loading & Error State
    
    /// Estado de carga
    private(set) var isLoading: Bool = false
    
    /// Error actual para mostrar en UI
    var error: WalletError? = nil
    
    // MARK: - Selection State
    
    /// Billetera seleccionada para detalle/animación
    var selectedWallet: Wallet? = nil
    
    /// ID de la wallet seleccionada (para animaciones)
    var selectedWalletID: UUID? = nil
    
    /// Billetera pendiente de acción destructiva
    private var walletPendingAction: Wallet? = nil
    
    // MARK: - Navigation State
    
    /// Controla visibilidad del detalle (para animación hero)
    var isDetailPresented: Bool = false
    
    /// Controla visibilidad del editor
    var isEditorPresented: Bool = false
    
    /// Controla visibilidad del ajuste de balance
    var isBalanceAdjustmentPresented: Bool = false
    
    /// Modo actual del editor
    private(set) var editorMode: WalletEditorMode = .create
    
    // MARK: - Alert State
    
    /// Controla alert de confirmación de archivo
    var isArchiveAlertPresented: Bool = false
    
    /// Controla alert de confirmación de eliminación
    var isDeleteAlertPresented: Bool = false
    
    // MARK: - Computed Properties
    
    /// `true` si el contexto está configurado
    var isConfigured: Bool { modelContext != nil }
    
    /// `true` si no hay billeteras
    var isEmpty: Bool { wallets.isEmpty }
    
    /// Cantidad de billeteras activas
    var walletsCount: Int { wallets.count }
    
    /// Cantidad de billeteras archivadas
    var archivedCount: Int { archivedWallets.count }
    
    /// `true` si se alcanzó el límite de billeteras
    var isLimitReached: Bool { walletsCount >= AppConfig.Limits.maxWallets }
    
    /// Billetera por defecto
    var defaultWallet: Wallet? {
        wallets.first { $0.isDefault } ?? wallets.first
    }
    
    // MARK: - Balance Calculations
    
    /// Balance total en la moneda preferida del usuario.
    /// Convierte todas las wallets a una moneda común.
    var totalBalance: Double {
        // Por ahora, suma simple sin conversión
        // TODO: Implementar conversión de moneda real
        wallets.reduce(0) { $0 + $1.currentBalance }
    }
    
    /// Balance total formateado
    var formattedTotalBalance: String {
        totalBalance.asCurrency()
    }
    
    /// Total de ingresos del mes actual
    var monthlyIncome: Double {
        // TODO: Calcular desde transacciones
        0
    }
    
    /// Total de gastos del mes actual
    var monthlyExpenses: Double {
        // TODO: Calcular desde transacciones
        0
    }
    
    /// Balance neto del mes (ingresos - gastos)
    var monthlyNetBalance: Double {
        monthlyIncome - monthlyExpenses
    }
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Configuration
    
    /// Configura el ModelContext. Llamar desde `onAppear` de la vista.
    func configure(with context: ModelContext) {
        guard modelContext == nil else { return }
        
        modelContext = context
        loadWallets()
    }
    
    // MARK: - Data Loading
    
    /// Carga todas las billeteras desde SwiftData.
    func loadWallets() {
        guard let context = modelContext else { return }
        
        // Billeteras activas
        var activeDescriptor = FetchDescriptor<Wallet>(
            predicate: #Predicate { wallet in
                !wallet.isArchived
            }
        )
        activeDescriptor.sortBy = [
            SortDescriptor(\Wallet.sortOrder, order: .forward),
            SortDescriptor(\Wallet.createdAt, order: .forward)
        ]
        
        // Billeteras archivadas
        var archivedDescriptor = FetchDescriptor<Wallet>(
            predicate: #Predicate { wallet in
                wallet.isArchived
            }
        )
        archivedDescriptor.sortBy = [SortDescriptor(\Wallet.updatedAt, order: .reverse)]
        
        do {
            wallets = try context.fetch(activeDescriptor)
            archivedWallets = try context.fetch(archivedDescriptor)
            
            if AppConfig.isDebugMode {
                print("✅ WalletsViewModel: Cargadas \(wallets.count) wallets activas, \(archivedWallets.count) archivadas")
            }
        } catch {
            self.error = .loadFailed
            print("❌ WalletsViewModel: Error al cargar - \(error)")
        }
    }
    
    // MARK: - CRUD Operations
    
    /// Crea una nueva billetera.
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
    ) {
        guard let context = requireContext() else { return }
        
        // Validar límite
        guard !isLimitReached else {
            error = .limitReached
            Task { @MainActor in Constants.Haptic.error() }
            return
        }
        
        // Si es default, quitar default de las demás
        if isDefault {
            clearDefaultWallet()
        }
        
        let wallet = Wallet(
            name: name,
            type: type,
            icon: icon,
            color: color,
            currencyCode: currencyCode,
            initialBalance: initialBalance,
            isDefault: isDefault || wallets.isEmpty, // Primera wallet es default
            sortOrder: nextSortOrder(),
            paymentReminderDay: paymentReminderDay,
            notes: notes,
            lastFourDigits: lastFourDigits
        )
        
        context.insert(wallet)
        save()
        loadWallets()
        Task { @MainActor in Constants.Haptic.success() }
        
        if AppConfig.isDebugMode {
            print("✅ WalletsViewModel: Wallet '\(name)' creada")
        }
    }
    
    /// Actualiza una billetera existente.
    func updateWallet(_ wallet: Wallet) {
        wallet.updatedAt = .now
        save()
        loadWallets()
        Task { @MainActor in Constants.Haptic.light() }
    }
    
    /// Establece una billetera como default.
    func setAsDefault(_ wallet: Wallet) {
        clearDefaultWallet()
        wallet.isDefault = true
        wallet.updatedAt = .now
        save()
        loadWallets()
        Task { @MainActor in Constants.Haptic.success() }
    }
    
    /// Ajusta el balance de una billetera manualmente.
    /// Crea una transacción de ajuste implícita.
    func adjustBalance(_ wallet: Wallet, newBalance: Double, reason: String? = nil) {
        let difference = newBalance - wallet.currentBalance
        
        wallet.currentBalance = newBalance
        wallet.updatedAt = .now
        
        // TODO: Crear transacción de ajuste
        // let adjustment = Transaction(
        //     type: difference >= 0 ? .adjustment : .adjustment,
        //     amount: abs(difference),
        //     wallet: wallet,
        //     note: reason ?? "Ajuste de balance"
        // )
        
        save()
        loadWallets()
        Task { @MainActor in Constants.Haptic.success() }
        
        if AppConfig.isDebugMode {
            print("✅ WalletsViewModel: Balance ajustado de \(wallet.name): \(difference >= 0 ? "+" : "")\(difference)")
        }
    }
    
    /// Archiva una billetera.
    func archiveWallet(_ wallet: Wallet) {
        guard !wallet.isDefault else {
            error = .cannotArchiveDefault
            Task { @MainActor in Constants.Haptic.error() }
            return
        }
        
        wallet.isArchived = true
        wallet.updatedAt = .now
        save()
        loadWallets()
        Task { @MainActor in Constants.Haptic.success() }
    }
    
    /// Restaura una billetera archivada.
    func restoreWallet(_ wallet: Wallet) {
        wallet.isArchived = false
        wallet.updatedAt = .now
        save()
        loadWallets()
        Task { @MainActor in Constants.Haptic.success() }
    }
    
    /// Elimina permanentemente una billetera.
    func deleteWallet(_ wallet: Wallet) {
        guard let context = requireContext() else { return }
        
        // No permitir eliminar si tiene transacciones
        // TODO: Verificar transacciones vinculadas
        
        context.delete(wallet)
        save()
        loadWallets()
        Task { @MainActor in Constants.Haptic.success() }
    }
    
    // MARK: - Reordering
    
    /// Mueve una billetera en la lista.
    func moveWallet(from source: IndexSet, to destination: Int) {
        var reorderedWallets = wallets
        reorderedWallets.move(fromOffsets: source, toOffset: destination)
        
        for (index, wallet) in reorderedWallets.enumerated() {
            wallet.sortOrder = index
        }
        
        save()
        loadWallets()
        Task { @MainActor in Constants.Haptic.light() }
    }
    
    // MARK: - Navigation Actions
    
    /// Presenta el editor en modo crear.
    func presentCreate() {
        guard !isLimitReached else {
            error = .limitReached
            Task { @MainActor in Constants.Haptic.error() }
            return
        }
        
        editorMode = .create
        selectedWallet = nil
        isEditorPresented = true
    }
    
    /// Presenta el editor en modo editar.
    func presentEdit(_ wallet: Wallet) {
        editorMode = .edit(wallet)
        selectedWallet = wallet
        isEditorPresented = true
    }
    
    /// Presenta el detalle de una billetera con animación hero.
    func presentDetail(_ wallet: Wallet) {
        selectedWallet = wallet
        selectedWalletID = wallet.id
        
        withAnimation(Constants.Animation.smoothSpring) {
            isDetailPresented = true
        }
    }
    
    /// Cierra el detalle con animación.
    func dismissDetail() {
        withAnimation(Constants.Animation.smoothSpring) {
            isDetailPresented = false
        }
        
        // Limpiar selección después de la animación
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.selectedWallet = nil
            self.selectedWalletID = nil
        }
    }
    
    /// Presenta el ajuste de balance.
    func presentBalanceAdjustment(_ wallet: Wallet) {
        selectedWallet = wallet
        isBalanceAdjustmentPresented = true
    }
    
    /// Presenta el alert de confirmación de archivo.
    func presentArchiveAlert(_ wallet: Wallet) {
        walletPendingAction = wallet
        isArchiveAlertPresented = true
    }
    
    /// Presenta el alert de confirmación de eliminación.
    func presentDeleteAlert(_ wallet: Wallet) {
        walletPendingAction = wallet
        isDeleteAlertPresented = true
    }
    
    /// Cierra el editor y limpia estado.
    func dismissEditor() {
        isEditorPresented = false
        selectedWallet = nil
        editorMode = .create
    }
    
    /// Confirma y ejecuta el archivo pendiente.
    func confirmArchive() {
        guard let wallet = walletPendingAction else { return }
        archiveWallet(wallet)
        cleanupPendingAction()
        isArchiveAlertPresented = false
    }
    
    /// Confirma y ejecuta la eliminación pendiente.
    func confirmDelete() {
        guard let wallet = walletPendingAction else { return }
        deleteWallet(wallet)
        cleanupPendingAction()
        isDeleteAlertPresented = false
    }
    
    /// Cancela la acción pendiente.
    func cancelPendingAction() {
        cleanupPendingAction()
        isArchiveAlertPresented = false
        isDeleteAlertPresented = false
    }
    
    // MARK: - Private Helpers
    
    private func cleanupPendingAction() {
        walletPendingAction = nil
    }
    
    @discardableResult
    private func requireContext() -> ModelContext? {
        guard let context = modelContext else {
            print("❌ WalletsViewModel: ModelContext no configurado")
            return nil
        }
        return context
    }
    
    private func save() {
        do {
            try modelContext?.save()
        } catch {
            self.error = .saveFailed
            print("❌ WalletsViewModel: Error al guardar - \(error)")
        }
    }
    
    private func nextSortOrder() -> Int {
        (wallets.map(\.sortOrder).max() ?? -1) + 1
    }
    
    private func clearDefaultWallet() {
        for wallet in wallets where wallet.isDefault {
            wallet.isDefault = false
        }
    }
}

// MARK: - Wallet Error

/// Errores posibles en operaciones de billetera.
enum WalletError: Error, LocalizedError, Identifiable {
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
        case .notFound:
            return "Billetera no encontrada"
        case .duplicateName:
            return "Ya existe una billetera con ese nombre"
        case .saveFailed:
            return "Error al guardar los cambios"
        case .loadFailed:
            return "Error al cargar las billeteras"
        case .invalidData:
            return "Datos inválidos"
        case .limitReached:
            return "Has alcanzado el límite de \(AppConfig.Limits.maxWallets) billeteras"
        case .cannotArchiveDefault:
            return "No puedes archivar la billetera principal"
        case .hasTransactions:
            return "Esta billetera tiene transacciones asociadas"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .limitReached:
            return "Archiva algunas billeteras que no uses"
        case .cannotArchiveDefault:
            return "Primero establece otra billetera como principal"
        case .saveFailed, .loadFailed:
            return "Intenta de nuevo o reinicia la app"
        default:
            return nil
        }
    }
}

// MARK: - Wallet Editor Mode

/// Modo del editor de billeteras.
enum WalletEditorMode: Equatable {
    case create
    case edit(Wallet)
    
    var isEditing: Bool {
        if case .edit = self { return true }
        return false
    }
    
    var isCreating: Bool {
        self == .create
    }
    
    var wallet: Wallet? {
        if case .edit(let wallet) = self {
            return wallet
        }
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
        case (.create, .create):
            return true
        case (.edit(let lhsWallet), .edit(let rhsWallet)):
            return lhsWallet.id == rhsWallet.id
        default:
            return false
        }
    }
}
