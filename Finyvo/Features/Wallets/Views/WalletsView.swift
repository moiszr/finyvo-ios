//
//  WalletsView.swift
//  Finyvo
//
//  Created by Claude for Moises Núñez on 12/25/25.
//  Vista de billeteras con Hero Animation estilo Apple Wallet.
//
//  Production-Ready Improvements:
//  - Adaptive layout using GeometryReader (iPad/Split View compatible)
//  - Single source of truth for selection (selectedWalletID)
//  - Reactive to wallet ID changes with dictionary cleanup
//  - Centralized animation timing constants
//  - Cancellable animation tasks
//  - Enhanced accessibility labels
//

import SwiftUI
import SwiftData

// MARK: - Wallets View

struct WalletsView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    @State private var viewModel = WalletsViewModel()
    
    /// Single source of truth: solo guardamos el ID, derivamos el Wallet
    @State private var selectedWalletID: UUID? = nil
    @State private var isShowingDetail: Bool = false
    @State private var dragOffset: CGFloat = 0
    
    // Animation states para cada tarjeta
    @State private var cardAnimationOffsets: [UUID: CGFloat] = [:]
    @State private var cardAnimationOpacities: [UUID: Double] = [:]
    @State private var cardAnimationScales: [UUID: CGFloat] = [:]
    
    // Control de contenido
    @State private var showBalanceCard: Bool = true
    @State private var showDetailContent: Bool = false
    
    // Task de animación cancelable
    @State private var animationTask: Task<Void, Never>?
    
    // Task de acción post-cierre cancelable (evita acciones fantasma)
    @State private var actionTask: Task<Void, Never>?
    
    // MARK: - Query
    
    @Query(
        filter: #Predicate<Wallet> { !$0.isArchived },
        sort: [
            SortDescriptor(\Wallet.sortOrder, order: .forward),
            SortDescriptor(\Wallet.createdAt, order: .forward)
        ]
    )
    private var wallets: [Wallet]
    
    // MARK: - Derived State
    
    /// Wallet seleccionado derivado del ID (single source of truth)
    private var selectedWallet: Wallet? {
        guard let id = selectedWalletID else { return nil }
        return wallets.first { $0.id == id }
    }
    
    /// Índice del wallet seleccionado
    private var selectedIndex: Int? {
        guard let id = selectedWalletID else { return nil }
        return wallets.firstIndex { $0.id == id }
    }
    
    /// IDs actuales para detectar cambios
    private var walletIDs: [UUID] {
        wallets.map(\.id)
    }
    
    // MARK: - Animation Timing Constants (centralizados)
    
    private enum AnimationTiming {
        static let phaseDelay: Duration = .milliseconds(200)
        static let balanceCardDelay: Duration = .milliseconds(120)
        static let cleanupDelay: Duration = .milliseconds(350)
        static let actionDelay: Duration = .milliseconds(400)
    }
    
    // MARK: - Animation Constants
    
    private var heroSpring: Animation {
        .spring(response: 0.6, dampingFraction: 0.78, blendDuration: 0)
    }
    
    private var secondarySpring: Animation {
        .spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)
    }
    
    private var quickSpring: Animation {
        .spring(response: 0.35, dampingFraction: 0.75, blendDuration: 0)
    }
    
    private let staggerDelay: Double = 0.035
    
    // MARK: - Layout Constants
    
    private let visibleStackPortion: CGFloat = 55
    private let cardHorizontalPadding: CGFloat = 20
    private let cardAspectRatio: CGFloat = 1.586
    private let cardCornerRadius: CGFloat = 20
    
    // MARK: - Computed (usando geometry, no UIScreen)
    
    private func cardWidth(in geometry: GeometryProxy) -> CGFloat {
        geometry.size.width - (cardHorizontalPadding * 2)
    }
    
    private func cardHeight(in geometry: GeometryProxy) -> CGFloat {
        cardWidth(in: geometry) / cardAspectRatio
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                FColors.background.ignoresSafeArea()
                
                if wallets.isEmpty {
                    emptyState
                } else {
                    mainContent(geometry: geometry)
                }
            }
        }
        .navigationTitle(isShowingDetail ? "" : "Billeteras")
        .toolbarTitleDisplayMode(.inlineLarge)
        .toolbar { toolbarContent }
        .sheet(isPresented: $viewModel.isEditorPresented) {
            if viewModel.editorMode == .create {
                WalletCreationFlow(viewModel: viewModel)
            } else {
                WalletEditorSheet(viewModel: viewModel, mode: viewModel.editorMode)
            }
        }
        .sheet(isPresented: $viewModel.isBalanceAdjustmentPresented) {
            if let wallet = viewModel.selectedWallet {
                BalanceAdjustmentSheet(wallet: wallet, viewModel: viewModel)
            }
        }
        .alert("Archivar billetera", isPresented: $viewModel.isArchiveAlertPresented) {
            Button("Cancelar", role: .cancel) {}
            Button("Archivar", role: .destructive) { viewModel.confirmArchive() }
        } message: {
            Text("La billetera se ocultará pero sus transacciones se mantendrán.")
        }
        .task {
            // Guard: configure es idempotente en el viewModel,
            // pero syncAnimationStates puede correr múltiples veces sin problema
            viewModel.configure(with: modelContext)
            syncAnimationStates()
        }
        .onChange(of: walletIDs) { oldIDs, newIDs in
            // Reaccionar a cambios de IDs (no solo count)
            syncAnimationStates(oldIDs: oldIDs, newIDs: newIDs)
        }
        .onDisappear {
            // Cancelar todas las tareas pendientes al salir
            animationTask?.cancel()
            actionTask?.cancel()
        }
    }
    
    // MARK: - Sync Animation States
    
    /// Sincroniza los diccionarios de animación con los wallets actuales
    private func syncAnimationStates(oldIDs: [UUID]? = nil, newIDs: [UUID]? = nil) {
        let currentIDs = Set(walletIDs)
        
        // Agregar estados para nuevos wallets
        for id in currentIDs {
            if cardAnimationOffsets[id] == nil {
                cardAnimationOffsets[id] = 0
            }
            if cardAnimationOpacities[id] == nil {
                cardAnimationOpacities[id] = 1
            }
            if cardAnimationScales[id] == nil {
                cardAnimationScales[id] = 1
            }
        }
        
        // Limpiar estados de wallets eliminados (evita memory leak)
        if let oldIDs = oldIDs {
            let removedIDs = Set(oldIDs).subtracting(currentIDs)
            for id in removedIDs {
                cardAnimationOffsets.removeValue(forKey: id)
                cardAnimationOpacities.removeValue(forKey: id)
                cardAnimationScales.removeValue(forKey: id)
            }
        }
        
        // Si el wallet seleccionado fue eliminado, cerrar detalle
        if let selectedID = selectedWalletID, !currentIDs.contains(selectedID) {
            resetToListState()
        }
    }
    
    /// Resetea al estado de lista sin animación
    private func resetToListState() {
        selectedWalletID = nil
        isShowingDetail = false
        showDetailContent = false
        showBalanceCard = true
        dragOffset = 0
        viewModel.selectedWallet = nil
    }
    
    // MARK: - Toolbar Content
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        
        if isShowingDetail {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    closeDetail()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(FColors.textPrimary)
                }
                .accessibilityLabel("Cerrar detalle")
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                if let wallet = selectedWallet {
                    Menu {
                        Button {
                            closeDetailAndThen { viewModel.presentEdit(wallet) }
                        } label: {
                            Label("Editar Billetera", systemImage: "pencil")
                        }
                        
                        Button {
                            viewModel.selectedWallet = wallet
                            viewModel.isBalanceAdjustmentPresented = true
                        } label: {
                            Label("Ajustar Balance", systemImage: "plusminus.circle")
                        }
                        
                        Button {
                            // TODO: Transferencia
                        } label: {
                            Label("Agregar Transferencia", systemImage: "arrow.left.arrow.right")
                        }
                        
                        if !wallet.isDefault {
                            Divider()
                            Button(role: .destructive) {
                                closeDetailAndThen { viewModel.presentArchiveAlert(wallet) }
                            } label: {
                                Label("Archivar", systemImage: "archivebox")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(FColors.textPrimary)
                    }
                    .accessibilityLabel("Opciones de billetera")
                }
            }
            
        } else {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.presentCreate()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(FColors.textPrimary)
                }
                .disabled(viewModel.isLimitReached)
                .accessibilityLabel("Crear billetera")
            }
        }
    }
    
    // MARK: - Main Content
    
    private func mainContent(geometry: GeometryProxy) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                if showBalanceCard {
                    totalBalanceCard
                        .padding(.horizontal, cardHorizontalPadding)
                        .padding(.top, FSpacing.xs)
                        .padding(.bottom, FSpacing.md)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                if isShowingDetail {
                    Spacer()
                        .frame(height: FSpacing.xs)
                }
                
                walletStack(geometry: geometry)
                
                if showDetailContent, let wallet = selectedWallet {
                    detailContent(wallet: wallet, geometry: geometry)
                        .padding(.top, FSpacing.lg)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .scrollDisabled(isShowingDetail && dragOffset > 0)
    }
    
    // MARK: - Wallet Stack
    
    private func walletStack(geometry: GeometryProxy) -> some View {
        ZStack(alignment: .top) {
            ForEach(Array(wallets.enumerated()), id: \.element.id) { index, wallet in
                walletCardItem(wallet: wallet, index: index, geometry: geometry)
            }
        }
        .animation(heroSpring, value: cardAnimationOffsets)
        .animation(heroSpring, value: cardAnimationOpacities)
        .animation(secondarySpring, value: cardAnimationScales)
    }
    
    // MARK: - Wallet Card Item
    
    @ViewBuilder
    private func walletCardItem(wallet: Wallet, index: Int, geometry: GeometryProxy) -> some View {
        let baseOffset = CGFloat(index) * visibleStackPortion
        let animationOffset = cardAnimationOffsets[wallet.id] ?? 0
        let opacity = cardAnimationOpacities[wallet.id] ?? 1
        let scale = cardAnimationScales[wallet.id] ?? 1
        let isSelected = selectedWalletID == wallet.id
        
        let isLastCard = index == wallets.count - 1
        let height = cardHeight(in: geometry)
        let width = cardWidth(in: geometry)
        
        // Área de toque dinámica según estado
        let hitTestHeight: CGFloat = {
            if isShowingDetail && isSelected {
                return height
            } else {
                return isLastCard ? height : visibleStackPortion
            }
        }()
        
        WalletCardView(wallet: wallet, isExpanded: isShowingDetail && isSelected)
            .padding(.horizontal, cardHorizontalPadding)
            .contentShape(
                .interaction,
                Rectangle()
                    .size(width: width, height: hitTestHeight)
            )
            .contentShape(
                .contextMenuPreview,
                RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
            )
            .offset(y: baseOffset + animationOffset + (isSelected ? dragOffset : 0))
            .opacity(opacity)
            .scaleEffect(scale, anchor: .top)
            .zIndex(zIndexForCard(at: index))
            .onTapGesture {
                if !isShowingDetail {
                    selectWallet(wallet, at: index)
                }
            }
            .gesture(isSelected && isShowingDetail ? dragToDismissGesture : nil)
            .contextMenu {
                if !isShowingDetail {
                    contextMenuContent(for: wallet)
                }
            }
            .accessibilityLabel("\(wallet.name), balance \(wallet.formattedBalance)")
            .accessibilityHint(isShowingDetail ? "Desliza hacia abajo para cerrar" : "Toca para ver detalles")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    private func zIndexForCard(at index: Int) -> Double {
        if isShowingDetail {
            if let selectedIdx = selectedIndex {
                return index == selectedIdx ? 1000 : Double(index)
            }
        }
        return Double(index)
    }
    
    // MARK: - Select Wallet Animation
    
    private func selectWallet(_ wallet: Wallet, at index: Int) {
        // Cancelar animación anterior si existe
        animationTask?.cancel()
        
        Task { @MainActor in Constants.Haptic.medium() }
        
        // Single source of truth: solo guardamos el ID
        selectedWalletID = wallet.id
        viewModel.selectedWallet = wallet
        
        let selectedBaseOffset = CGFloat(index) * visibleStackPortion
        let targetOffset: CGFloat = -selectedBaseOffset
        
        // Fase 1: Ocultar balance card
        withAnimation(secondarySpring) {
            showBalanceCard = false
        }
        
        // Fase 2: Animar tarjetas con stagger
        for (i, w) in wallets.enumerated() {
            let distanceFromSelected = abs(i - index)
            let delay = Double(distanceFromSelected) * staggerDelay
            
            withAnimation(heroSpring.delay(delay)) {
                if i == index {
                    cardAnimationOffsets[w.id] = targetOffset
                    cardAnimationOpacities[w.id] = 1
                    cardAnimationScales[w.id] = 1
                } else if i < index {
                    let distanceUp = CGFloat(index - i)
                    cardAnimationOffsets[w.id] = targetOffset - (distanceUp * 20)
                    cardAnimationOpacities[w.id] = 0
                    cardAnimationScales[w.id] = 0.96
                } else {
                    let distanceDown = CGFloat(i - index)
                    cardAnimationOffsets[w.id] = 120 + (distanceDown * 60)
                    cardAnimationOpacities[w.id] = 0
                    cardAnimationScales[w.id] = 0.96
                }
            }
        }
        
        // Fase 3: Mostrar contenido de detalle (con Task cancelable)
        animationTask = Task { @MainActor in
            try? await Task.sleep(for: AnimationTiming.phaseDelay)
            guard !Task.isCancelled else { return }
            
            withAnimation(secondarySpring) {
                isShowingDetail = true
                showDetailContent = true
            }
        }
    }
    
    // MARK: - Close Detail Animation
    
    private func closeDetail(withHaptic: Bool = false) {
        // Cancelar animación anterior
        animationTask?.cancel()
        actionTask?.cancel()
        
        if withHaptic {
            Task { @MainActor in Constants.Haptic.light() }
        }
        
        // Fase 1: Ocultar contenido
        withAnimation(quickSpring) {
            showDetailContent = false
            dragOffset = 0
        }
        
        // Fase 2: Restaurar tarjetas con stagger
        let totalCards = wallets.count
        for (i, wallet) in wallets.enumerated() {
            let distanceFromSelected = selectedIndex.map { abs(i - $0) } ?? i
            let delay = Double(totalCards - 1 - distanceFromSelected) * staggerDelay
            
            withAnimation(heroSpring.delay(delay)) {
                cardAnimationOffsets[wallet.id] = 0
                cardAnimationOpacities[wallet.id] = 1
                cardAnimationScales[wallet.id] = 1
            }
        }
        
        // Fase 3 y 4: Balance card + cleanup (con Task cancelable)
        animationTask = Task { @MainActor in
            try? await Task.sleep(for: AnimationTiming.balanceCardDelay)
            guard !Task.isCancelled else { return }
            
            withAnimation(secondarySpring) {
                showBalanceCard = true
                isShowingDetail = false
            }
            
            try? await Task.sleep(for: AnimationTiming.cleanupDelay - AnimationTiming.balanceCardDelay)
            guard !Task.isCancelled else { return }
            
            selectedWalletID = nil
            viewModel.selectedWallet = nil
        }
    }
    
    private func closeDetailAndThen(_ action: @escaping () -> Void) {
        // Cancelar acción anterior pendiente
        actionTask?.cancel()
        
        closeDetail()
        
        actionTask = Task { @MainActor in
            try? await Task.sleep(for: AnimationTiming.actionDelay)
            guard !Task.isCancelled else { return }
            action()
        }
    }
    
    // MARK: - Drag Gesture
    
    private var dragToDismissGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                if value.translation.height > 0 {
                    let resistance = 1 - min(value.translation.height / 300, 0.6)
                    dragOffset = value.translation.height * resistance
                }
            }
            .onEnded { value in
                let velocity = value.predictedEndTranslation.height - value.translation.height
                
                if value.translation.height > 15 || velocity > 50 {
                    closeDetail(withHaptic: true)
                } else {
                    withAnimation(heroSpring) {
                        dragOffset = 0
                    }
                }
            }
    }
    
    // MARK: - Detail Content
    
    private func detailContent(wallet: Wallet, geometry: GeometryProxy) -> some View {
        VStack(spacing: FSpacing.lg) {
            statsSection(wallet: wallet)
            transactionsSection(wallet: wallet)
        }
        .padding(.horizontal, cardHorizontalPadding)
        .opacity(dragOffset > 30 ? max(0, 1 - (dragOffset / 100)) : 1)
    }
    
    // MARK: - Stats Section
    
    private func statsSection(wallet: Wallet) -> some View {
        HStack(spacing: FSpacing.md) {
            StatCard(
                title: "Balance",
                value: wallet.formattedBalance,
                icon: "creditcard.fill",
                color: FColors.blue
            )
            
            StatCard(
                title: "Transacciones",
                value: "0",
                icon: "arrow.left.arrow.right",
                color: FColors.purple
            )
        }
    }
    
    // MARK: - Transactions Section
    
    private func transactionsSection(wallet: Wallet) -> some View {
        VStack(alignment: .leading, spacing: FSpacing.md) {
            HStack {
                Text("Últimas Transacciones")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(FColors.textPrimary)
                
                Spacer()
                
                Button("Ver todas") {
                    // TODO: Navegar
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(FColors.brand)
            }
            
            transactionsPlaceholder
        }
    }
    
    private var transactionsPlaceholder: some View {
        VStack(spacing: 0) {
            ForEach(0..<5, id: \.self) { index in
                HStack(spacing: FSpacing.md) {
                    Circle()
                        .fill(FColors.backgroundTertiary)
                        .frame(width: 44, height: 44)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(FColors.backgroundTertiary)
                            .frame(width: 130, height: 14)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(FColors.backgroundTertiary)
                            .frame(width: 90, height: 11)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(FColors.backgroundTertiary)
                            .frame(width: 65, height: 14)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(FColors.textTertiary)
                    }
                }
                .padding(.vertical, 12)
                
                if index < 4 {
                    Divider()
                        .padding(.leading, 56)
                }
            }
        }
        .padding(FSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? FColors.backgroundSecondary : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04),
                    lineWidth: 1
                )
        )
    }
    
    // MARK: - Total Balance Card
    
    private var totalBalanceCard: some View {
        VStack(spacing: FSpacing.md) {
            VStack(spacing: FSpacing.xs) {
                Text("Balance Total")
                    .font(.subheadline)
                    .foregroundStyle(FColors.textSecondary)
                
                Text(viewModel.formattedTotalBalance)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(FColors.textPrimary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            
            HStack(spacing: FSpacing.xxl) {
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(FColors.green)
                        Text("Ingresos")
                            .foregroundStyle(FColors.textSecondary)
                    }
                    .font(.caption)
                    
                    Text(viewModel.monthlyIncome.asCurrency())
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FColors.textPrimary)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                }
                
                Rectangle()
                    .fill(FColors.separator)
                    .frame(width: 1, height: 32)
                
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(FColors.red)
                        Text("Gastos")
                            .foregroundStyle(FColors.textSecondary)
                    }
                    .font(.caption)
                    
                    Text(viewModel.monthlyExpenses.asCurrency())
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FColors.textPrimary)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, FSpacing.lg)
        .padding(.horizontal, FSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .dark ? FColors.backgroundSecondary : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04),
                    lineWidth: 1
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Balance total \(viewModel.formattedTotalBalance), ingresos \(viewModel.monthlyIncome.asCurrency()), gastos \(viewModel.monthlyExpenses.asCurrency())")
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func contextMenuContent(for wallet: Wallet) -> some View {
        Button {
            viewModel.presentEdit(wallet)
        } label: {
            Label("Editar", systemImage: "pencil")
        }
        
        if !wallet.isDefault {
            Button {
                viewModel.setAsDefault(wallet)
            } label: {
                Label("Establecer como principal", systemImage: "star")
            }
        }
        
        Button {
            viewModel.selectedWallet = wallet
            viewModel.isBalanceAdjustmentPresented = true
        } label: {
            Label("Ajustar balance", systemImage: "plusminus.circle")
        }
        
        Divider()
        
        if !wallet.isDefault {
            Button(role: .destructive) {
                viewModel.presentArchiveAlert(wallet)
            } label: {
                Label("Archivar", systemImage: "archivebox")
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: FSpacing.md) {
            Spacer(minLength: 40)
            
            Image(systemName: "wallet.pass.fill")
                .font(.system(size: 48))
                .foregroundStyle(FColors.textTertiary)
                .padding(.bottom, 8)
                .accessibilityHidden(true)
            
            Text("Sin billeteras")
                .font(.headline)
                .foregroundStyle(FColors.textPrimary)
            
            Text("Agrega tu primera billetera para comenzar a rastrear tus finanzas.")
                .font(.subheadline)
                .foregroundStyle(FColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, FSpacing.xxxl)
            
            Button {
                viewModel.presentCreate()
            } label: {
                Text("Crear ahora")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FColors.textPrimary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .stroke(FColors.border, lineWidth: 1)
                    )
            }
            .padding(.top, FSpacing.sm)
            .accessibilityHint("Crea tu primera billetera")
            
            Spacer()
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: FSpacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(FColors.textSecondary)
            }
            
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(FColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(colorScheme == .dark ? FColors.backgroundSecondary : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04),
                    lineWidth: 1
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WalletsView()
    }
    .modelContainer(for: Wallet.self, inMemory: true)
}

#Preview("Dark Mode") {
    NavigationStack {
        WalletsView()
    }
    .modelContainer(for: Wallet.self, inMemory: true)
    .preferredColorScheme(.dark)
}
