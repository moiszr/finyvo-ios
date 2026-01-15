//
//  WalletsView.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/25/25.
//  Updated on 01/14/26 - Simplified default wallet handling:
//    - Removed ensureFrontWalletIsDefault (handled by ViewModel)
//    - Simplified animation states
//    - Clean drag & drop that respects ViewModel's default logic
//

import SwiftUI
import SwiftData

// MARK: - Wallets View

struct WalletsView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - State
    
    @State private var viewModel = WalletsViewModel()
    @State private var selectedWalletID: UUID? = nil
    @State private var isShowingDetail: Bool = false
    @State private var dragOffset: CGFloat = 0
    
    // Animation states
    @State private var cardAnimationOffsets: [UUID: CGFloat] = [:]
    @State private var cardAnimationOpacities: [UUID: Double] = [:]
    @State private var cardAnimationScales: [UUID: CGFloat] = [:]
    
    // Content visibility
    @State private var showBalanceCard: Bool = true
    @State private var showDetailContent: Bool = false
    
    // Cancelable tasks
    @State private var animationTask: Task<Void, Never>?
    @State private var actionTask: Task<Void, Never>?
    
    // Drag & Drop
    @State private var draggingWalletID: UUID? = nil
    @State private var dragTranslation: CGFloat = 0
    @State private var initialDragIndex: Int? = nil
    @State private var currentDropIndex: Int? = nil
    
    // Sheets
    @State private var isArchivedPresented: Bool = false
    
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
    
    private var selectedWallet: Wallet? {
        guard let id = selectedWalletID else { return nil }
        return wallets.first { $0.id == id }
    }
    
    private var selectedIndex: Int? {
        guard let id = selectedWalletID else { return nil }
        return wallets.firstIndex { $0.id == id }
    }
    
    private var walletIDs: [UUID] { wallets.map(\.id) }
    
    private var frontWallet: Wallet? { wallets.last }
    
    // MARK: - Animation Constants
    
    private enum Timing {
        static let phaseDelay: Duration = .milliseconds(200)
        static let balanceCardDelay: Duration = .milliseconds(120)
        static let cleanupDelay: Duration = .milliseconds(350)
        static let actionDelay: Duration = .milliseconds(400)
    }
    
    private var heroSpring: Animation {
        .spring(response: 0.6, dampingFraction: 0.78)
    }
    
    private var secondarySpring: Animation {
        .spring(response: 0.5, dampingFraction: 0.8)
    }
    
    private var quickSpring: Animation {
        .spring(response: 0.35, dampingFraction: 0.75)
    }
    
    private var dragSpring: Animation {
        .spring(response: 0.4, dampingFraction: 0.7)
    }
    
    private let staggerDelay: Double = 0.035
    
    // MARK: - Layout Constants
    
    private let visibleStackPortion: CGFloat = 55
    private let cardHorizontalPadding: CGFloat = 20
    private let cardAspectRatio: CGFloat = 1.586
    
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
            editorSheet
        }
        .sheet(isPresented: $viewModel.isBalanceAdjustmentPresented) {
            if let wallet = viewModel.selectedWallet {
                BalanceAdjustmentSheet(wallet: wallet, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $isArchivedPresented) {
            ArchivedWalletsSheet(viewModel: viewModel)
        }
        .alert("Archivar billetera", isPresented: $viewModel.isArchiveAlertPresented) {
            Button("Cancelar", role: .cancel) {}
            Button("Archivar", role: .destructive) { viewModel.confirmArchive() }
        } message: {
            Text("La billetera se ocultará pero sus transacciones se mantendrán.")
        }
        .task {
            viewModel.configure(with: modelContext)
            syncAnimationStates()
        }
        .onChange(of: walletIDs) { oldIDs, newIDs in
            syncAnimationStates(oldIDs: oldIDs, newIDs: newIDs)
        }
        .onDisappear {
            animationTask?.cancel()
            actionTask?.cancel()
        }
    }
    
    // MARK: - Editor Sheet
    
    @ViewBuilder
    private var editorSheet: some View {
        if viewModel.editorMode == .create {
            WalletCreationFlow(viewModel: viewModel)
        } else if let wallet = viewModel.editorMode.wallet {
            WalletEditView(viewModel: viewModel, wallet: wallet)
        }
    }
    
    // MARK: - Sync Animation States
    
    private func syncAnimationStates(oldIDs: [UUID]? = nil, newIDs: [UUID]? = nil) {
        let currentIDs = Set(walletIDs)
        
        for id in currentIDs {
            cardAnimationOffsets[id] = cardAnimationOffsets[id] ?? 0
            cardAnimationOpacities[id] = cardAnimationOpacities[id] ?? 1
            cardAnimationScales[id] = cardAnimationScales[id] ?? 1
        }
        
        if let oldIDs = oldIDs {
            for id in Set(oldIDs).subtracting(currentIDs) {
                cardAnimationOffsets.removeValue(forKey: id)
                cardAnimationOpacities.removeValue(forKey: id)
                cardAnimationScales.removeValue(forKey: id)
            }
        }
        
        if let selectedID = selectedWalletID, !currentIDs.contains(selectedID) {
            resetToListState()
        }
    }
    
    private func resetToListState() {
        selectedWalletID = nil
        isShowingDetail = false
        showDetailContent = false
        showBalanceCard = true
        dragOffset = 0
        viewModel.selectedWallet = nil
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if isShowingDetail {
            ToolbarItem(placement: .topBarLeading) {
                Button { closeDetail() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(FColors.textPrimary)
                }
                .accessibilityLabel("Cerrar")
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                if let wallet = selectedWallet {
                    detailMenu(for: wallet)
                }
            }
        } else {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isArchivedPresented = true } label: {
                    Image(systemName: "archivebox")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(FColors.textPrimary)
                }
                .accessibilityLabel("Archivadas")
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button { viewModel.presentCreate() } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(FColors.textPrimary)
                }
                .disabled(viewModel.isLimitReached)
                .accessibilityLabel("Crear")
            }
        }
    }
    
    // MARK: - Detail Menu
    
    @ViewBuilder
    private func detailMenu(for wallet: Wallet) -> some View {
        Menu {
            Button {
                closeDetailAndThen { viewModel.presentEdit(wallet) }
            } label: {
                Label("Editar", systemImage: "pencil")
            }
            
            Button {
                viewModel.selectedWallet = wallet
                viewModel.isBalanceAdjustmentPresented = true
            } label: {
                Label("Ajustar balance", systemImage: "plusminus.circle")
            }
            
            if !wallet.isDefault {
                Button {
                    viewModel.setAsDefault(wallet)
                    closeDetail()
                } label: {
                    Label("Hacer principal", systemImage: "star")
                }
            }
            
            Button {
                // TODO: Transfer
            } label: {
                Label("Transferir", systemImage: "arrow.left.arrow.right")
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
        .accessibilityLabel("Opciones")
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
                    Spacer().frame(height: FSpacing.xs)
                }
                
                walletStack(geometry: geometry)
                
                if showDetailContent, let wallet = selectedWallet {
                    detailContent(wallet: wallet)
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
        let animOffset = cardAnimationOffsets[wallet.id] ?? 0
        let opacity = cardAnimationOpacities[wallet.id] ?? 1
        let scale = cardAnimationScales[wallet.id] ?? 1
        let isSelected = selectedWalletID == wallet.id
        let isDragging = draggingWalletID == wallet.id
        let isLastCard = index == wallets.count - 1
        let height = cardHeight(in: geometry)
        let width = cardWidth(in: geometry)
        
        let dragAdjustedOffset = calculateDragOffset(for: index, baseOffset: baseOffset)
        let hitTestHeight: CGFloat = (isShowingDetail && isSelected) ? height : (isLastCard ? height : visibleStackPortion)
        
        WalletCardView(wallet: wallet, isExpanded: isShowingDetail && isSelected)
            .padding(.horizontal, cardHorizontalPadding)
            .contentShape(.interaction, Rectangle().size(width: width, height: hitTestHeight))
            .offset(y: dragAdjustedOffset + animOffset + (isSelected && !isDragging ? dragOffset : 0))
            .opacity(opacity)
            .scaleEffect(isDragging ? 1.03 : scale, anchor: .top)
            .shadow(color: isDragging ? .black.opacity(0.2) : .clear, radius: isDragging ? 15 : 0, y: isDragging ? 8 : 0)
            .zIndex(zIndex(for: index, isDragging: isDragging))
            .onTapGesture {
                guard !isShowingDetail, draggingWalletID == nil else { return }
                selectWallet(wallet, at: index)
            }
            .gesture(isSelected && isShowingDetail ? dragToDismissGesture : nil)
            .gesture(!isShowingDetail ? reorderGesture(for: wallet, at: index, cardHeight: height) : nil)
            .accessibilityLabel("\(wallet.name), \(wallet.formattedBalance)\(wallet.isDefault ? ", principal" : "")")
            .accessibilityHint(isShowingDetail ? "Desliza abajo para cerrar" : "Toca para detalles")
    }
    
    // MARK: - Drag Offset Calculation
    
    private func calculateDragOffset(for index: Int, baseOffset: CGFloat) -> CGFloat {
        guard let dragIndex = initialDragIndex, draggingWalletID != nil else {
            return baseOffset
        }
        
        if wallets[index].id == draggingWalletID {
            return baseOffset + dragTranslation
        }
        
        let draggedOffset = CGFloat(dragIndex) * visibleStackPortion + dragTranslation
        
        if dragIndex < index && draggedOffset > baseOffset - visibleStackPortion / 2 {
            return baseOffset - visibleStackPortion
        }
        
        if dragIndex > index && draggedOffset < baseOffset + visibleStackPortion / 2 {
            return baseOffset + visibleStackPortion
        }
        
        return baseOffset
    }
    
    private func zIndex(for index: Int, isDragging: Bool) -> Double {
        if isDragging { return 1000 }
        if isShowingDetail, let selectedIdx = selectedIndex {
            return index == selectedIdx ? 1000 : Double(index)
        }
        return Double(index)
    }
    
    // MARK: - Reorder Gesture
    
    private func reorderGesture(for wallet: Wallet, at index: Int, cardHeight: CGFloat) -> some Gesture {
        LongPressGesture(minimumDuration: 0.3)
            .sequenced(before: DragGesture())
            .onChanged { value in
                if case .second(true, let drag) = value, let drag = drag {
                    if draggingWalletID == nil {
                        draggingWalletID = wallet.id
                        initialDragIndex = index
                        Constants.Haptic.medium()
                    }
                    
                    withAnimation(dragSpring) {
                        dragTranslation = drag.translation.height
                    }
                    
                    let newIndex = calculateNewIndex(from: index, translation: drag.translation.height)
                    if newIndex != currentDropIndex {
                        currentDropIndex = newIndex
                        Constants.Haptic.selection()
                    }
                }
            }
            .onEnded { _ in
                guard draggingWalletID != nil else { return }
                
                if let fromIndex = initialDragIndex,
                   let toIndex = currentDropIndex,
                   fromIndex != toIndex {
                    viewModel.moveWallet(from: IndexSet(integer: fromIndex), to: toIndex > fromIndex ? toIndex + 1 : toIndex)
                    Constants.Haptic.success()
                } else {
                    Constants.Haptic.light()
                }
                
                withAnimation(dragSpring) {
                    draggingWalletID = nil
                    dragTranslation = 0
                    initialDragIndex = nil
                    currentDropIndex = nil
                }
            }
    }
    
    private func calculateNewIndex(from index: Int, translation: CGFloat) -> Int {
        let movement = Int(round(translation / visibleStackPortion))
        return max(0, min(wallets.count - 1, index + movement))
    }
    
    // MARK: - Select Wallet
    
    private func selectWallet(_ wallet: Wallet, at index: Int) {
        animationTask?.cancel()
        Constants.Haptic.medium()
        
        selectedWalletID = wallet.id
        viewModel.selectedWallet = wallet
        
        let targetOffset: CGFloat = -CGFloat(index) * visibleStackPortion
        
        withAnimation(secondarySpring) {
            showBalanceCard = false
        }
        
        for (i, w) in wallets.enumerated() {
            let delay = Double(abs(i - index)) * staggerDelay
            
            withAnimation(heroSpring.delay(delay)) {
                if i == index {
                    cardAnimationOffsets[w.id] = targetOffset
                    cardAnimationOpacities[w.id] = 1
                    cardAnimationScales[w.id] = 1
                } else if i < index {
                    cardAnimationOffsets[w.id] = targetOffset - CGFloat(index - i) * 20
                    cardAnimationOpacities[w.id] = 0
                    cardAnimationScales[w.id] = 0.96
                } else {
                    cardAnimationOffsets[w.id] = 120 + CGFloat(i - index) * 60
                    cardAnimationOpacities[w.id] = 0
                    cardAnimationScales[w.id] = 0.96
                }
            }
        }
        
        animationTask = Task { @MainActor in
            try? await Task.sleep(for: Timing.phaseDelay)
            guard !Task.isCancelled else { return }
            
            withAnimation(secondarySpring) {
                isShowingDetail = true
                showDetailContent = true
            }
        }
    }
    
    // MARK: - Close Detail
    
    private func closeDetail(withHaptic: Bool = false) {
        animationTask?.cancel()
        actionTask?.cancel()
        
        if withHaptic { Constants.Haptic.light() }
        
        withAnimation(quickSpring) {
            showDetailContent = false
            dragOffset = 0
        }
        
        let totalCards = wallets.count
        for (i, wallet) in wallets.enumerated() {
            let delay = Double(totalCards - 1 - (selectedIndex.map { abs(i - $0) } ?? i)) * staggerDelay
            
            withAnimation(heroSpring.delay(delay)) {
                cardAnimationOffsets[wallet.id] = 0
                cardAnimationOpacities[wallet.id] = 1
                cardAnimationScales[wallet.id] = 1
            }
        }
        
        animationTask = Task { @MainActor in
            try? await Task.sleep(for: Timing.balanceCardDelay)
            guard !Task.isCancelled else { return }
            
            withAnimation(secondarySpring) {
                showBalanceCard = true
                isShowingDetail = false
            }
            
            try? await Task.sleep(for: Timing.cleanupDelay - Timing.balanceCardDelay)
            guard !Task.isCancelled else { return }
            
            selectedWalletID = nil
            viewModel.selectedWallet = nil
        }
    }
    
    private func closeDetailAndThen(_ action: @escaping () -> Void) {
        actionTask?.cancel()
        closeDetail()
        
        actionTask = Task { @MainActor in
            try? await Task.sleep(for: Timing.actionDelay)
            guard !Task.isCancelled else { return }
            action()
        }
    }
    
    // MARK: - Drag to Dismiss
    
    private var dragToDismissGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                guard value.translation.height > 0 else { return }
                let resistance = 1 - min(value.translation.height / 300, 0.6)
                dragOffset = value.translation.height * resistance
            }
            .onEnded { value in
                let velocity = value.predictedEndTranslation.height - value.translation.height
                
                if value.translation.height > 15 || velocity > 50 {
                    closeDetail(withHaptic: true)
                } else {
                    withAnimation(heroSpring) { dragOffset = 0 }
                }
            }
    }
    
    // MARK: - Detail Content
    
    private func detailContent(wallet: Wallet) -> some View {
        VStack(spacing: FSpacing.lg) {
            statsSection(wallet: wallet)
            transactionsSection(wallet: wallet)
        }
        .padding(.horizontal, cardHorizontalPadding)
        .opacity(dragOffset > 30 ? max(0, 1 - dragOffset / 100) : 1)
    }
    
    private func statsSection(wallet: Wallet) -> some View {
        HStack(spacing: FSpacing.md) {
            StatCard(title: "Balance", value: wallet.formattedBalance, icon: "creditcard.fill", color: FColors.blue)
            StatCard(title: "Transacciones", value: "0", icon: "arrow.left.arrow.right", color: FColors.purple)
        }
    }
    
    private func transactionsSection(wallet: Wallet) -> some View {
        VStack(alignment: .leading, spacing: FSpacing.md) {
            HStack {
                Text("Últimas Transacciones")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(FColors.textPrimary)
                Spacer()
                Button("Ver todas") {}
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
                    Divider().padding(.leading, 56)
                }
            }
        }
        .padding(FSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? FColors.backgroundSecondary : .white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04), lineWidth: 1)
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
                balanceMetric(icon: "arrow.down.circle.fill", color: FColors.green, label: "Ingresos", value: viewModel.monthlyIncome)
                Rectangle().fill(FColors.separator).frame(width: 1, height: 32)
                balanceMetric(icon: "arrow.up.circle.fill", color: FColors.red, label: "Gastos", value: viewModel.monthlyExpenses)
            }
        }
        .padding(.vertical, FSpacing.lg)
        .padding(.horizontal, FSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .dark ? FColors.backgroundSecondary : .white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04), lineWidth: 1)
        )
    }
    
    private func balanceMetric(icon: String, color: Color, label: String, value: Double) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon).foregroundStyle(color)
                Text(label).foregroundStyle(FColors.textSecondary)
            }
            .font(.caption)
            
            Text(value.asCurrency())
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FColors.textPrimary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
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
            
            Text("Sin billeteras")
                .font(.headline)
                .foregroundStyle(FColors.textPrimary)
            
            Text("Agrega tu primera billetera para comenzar a rastrear tus finanzas.")
                .font(.subheadline)
                .foregroundStyle(FColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, FSpacing.xxxl)
            
            Button { viewModel.presentCreate() } label: {
                Text("Crear ahora")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FColors.textPrimary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().stroke(FColors.border, lineWidth: 1))
            }
            .padding(.top, FSpacing.sm)
            
            Spacer()
        }
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
                .fill(colorScheme == .dark ? FColors.backgroundSecondary : .white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04), lineWidth: 1)
        )
    }
}

// MARK: - Archived Wallets Sheet

struct ArchivedWalletsSheet: View {
    @Bindable var viewModel: WalletsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @Query(
        filter: #Predicate<Wallet> { $0.isArchived },
        sort: [SortDescriptor(\Wallet.updatedAt, order: .reverse)]
    )
    private var archivedWallets: [Wallet]
    
    @State private var walletToDelete: Wallet? = nil
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            Group {
                if archivedWallets.isEmpty {
                    emptyState
                } else {
                    walletsList
                }
            }
            .navigationTitle("Archivadas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(FColors.textPrimary)
                        }
                        .accessibilityLabel("Cerrar")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.automatic)
        .presentationBackground(.clear)
        .presentationBackgroundInteraction(.automatic)
        .confirmationDialog(
            "Eliminar permanentemente",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive) {
                if let wallet = walletToDelete {
                    Constants.Haptic.warning()
                    viewModel.deleteWallet(wallet)
                    walletToDelete = nil
                }
            }
            Button("Cancelar", role: .cancel) {
                walletToDelete = nil
            }
        } message: {
            Text("Esta acción no se puede deshacer.")
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: FSpacing.md) {
            Spacer()
            
            Image(systemName: "archivebox")
                .font(.system(size: 48))
                .foregroundStyle(FColors.textTertiary)
            
            Text("Nada archivado")
                .font(.headline)
                .foregroundStyle(FColors.textPrimary)
            
            Text("Las billeteras que archives aparecerán aquí.")
                .font(.subheadline)
                .foregroundStyle(FColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, FSpacing.xxxl)
            
            Spacer()
        }
    }
    
    private var walletsList: some View {
        List {
            ForEach(archivedWallets) { wallet in
                WalletCardCompact(wallet: wallet)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: FSpacing.lg, bottom: 6, trailing: FSpacing.lg))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            walletToDelete = wallet
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                        }
                        .tint(Color.red)
                        
                        Button {
                            Constants.Haptic.success()
                            viewModel.restoreWallet(wallet)
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                        }
                        .tint(FColors.brand)
                    }
                    .contextMenu {
                        Button {
                            Constants.Haptic.success()
                            viewModel.restoreWallet(wallet)
                        } label: {
                            Label("Restaurar", systemImage: "arrow.uturn.backward")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            walletToDelete = wallet
                            showDeleteConfirmation = true
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
            }
            .onDelete { indexSet in
                if let index = indexSet.first {
                    walletToDelete = archivedWallets[index]
                    showDeleteConfirmation = true
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WalletsView()
    }
    .modelContainer(for: Wallet.self, inMemory: true)
}
