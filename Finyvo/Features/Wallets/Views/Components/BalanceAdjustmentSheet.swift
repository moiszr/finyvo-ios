//
//  BalanceAdjustmentSheet.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/24/25.
//  Updated on 01/15/26 - Premium UX overhaul v2.2:
//    - Added subtle "helper" card under balance (same styling as Note card)
//    - Improved initial focus behavior to avoid "jump" bug (no auto-focus on appear)
//    - Cursor now shows reliably when tapping balance + uses dark color (like Note)
//    - Balance section has a touch more vertical breathing room
//

import SwiftUI

// MARK: - Balance Adjustment Sheet

struct BalanceAdjustmentSheet: View {
    
    // MARK: - Properties
    
    let wallet: Wallet
    @Bindable var viewModel: WalletsViewModel
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - State
    
    @State private var newBalanceString: String = ""
    @State private var reason: String = ""
    @State private var isSaving: Bool = false
    
    // Expanded sections
    @State private var expandedSection: AdjustmentSection? = nil
    
    // Focus management
    @State private var isBalanceFocused: Bool = false
    @State private var isReasonFocused: Bool = false
    
    // Focus tokens for re-triggering
    @State private var balanceFocusToken: Int = 0
    @State private var reasonFocusToken: Int = 0
    
    // Task management
    @State private var balanceFocusTask: Task<Void, Never>?
    @State private var reasonFocusTask: Task<Void, Never>?
    @State private var scrollTask: Task<Void, Never>?
    
    // Cursor animation
    @State private var cursorOpacity: Double = 1
    
    // ✅ Tap-driven cursor visibility (don’t rely on .onAppear only)
    @State private var cursorToken: Int = 0
    
    // ✅ Prevent “open → keyboard → jump” on first appearance
    @State private var didAppearOnce: Bool = false
    
    // MARK: - Types
    
    private enum AdjustmentSection: String {
        case reason
    }
    
    // MARK: - Computed Properties
    
    private var currentBalance: Double {
        wallet.currentBalance
    }
    
    private var newBalance: Double? {
        let currency = wallet.currency ?? CurrencyConfig.defaultCurrency
        return currency.parse(newBalanceString)
    }
    
    private var difference: Double {
        guard let new = newBalance else { return 0 }
        return new - currentBalance
    }
    
    private var hasDifference: Bool {
        guard let new = newBalance else { return false }
        return abs(new - currentBalance) > 0.001
    }
    
    private var isValid: Bool {
        newBalance != nil && hasDifference && !isSaving
    }
    
    private var currencySymbol: String {
        wallet.currency?.symbol ?? wallet.currencyCode
    }
    
    private var hasActiveKeyboard: Bool {
        isBalanceFocused || isReasonFocused
    }
    
    private var isInputActive: Bool {
        isBalanceFocused || (hasActiveKeyboard && expandedSection != nil)
    }
    
    /// Formatted display of the new balance for live preview
    private var formattedNewBalance: String {
        guard let balance = newBalance else {
            return "\(currencySymbol) 0.00"
        }
        return CurrencyConfig.format(balance, code: wallet.currencyCode)
    }
    
    /// Subtitle for reason card
    private var reasonSubtitle: String {
        reason.isEmpty ? "Opcional" : reason
    }
    
    private var cursorColor: Color {
        // “like Note”: dark, subtle (not brand colored)
        colorScheme == .dark ? Color.white.opacity(0.85) : Color.black.opacity(0.85)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                FColors.background
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { dismissKeyboardAndCollapse() }
                
                VStack(spacing: 0) {
                    mainContent
                    bottomToolbar
                }
            }
            .navigationTitle("Ajustar Balance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .animation(Constants.Animation.cardSpring, value: hasDifference)
            .animation(Constants.Animation.cardSpring, value: expandedSection)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(FColors.background)
        .onAppear { setupInitialStateIfNeeded() }
        .onDisappear { cancelAllTasks() }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: FSpacing.lg) {
                    
                    balanceInputSection
                    
                    // ✅ New helper card under balance (same vibe as Note card)
                    balanceHelperCard
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    
                    if hasDifference {
                        differenceIndicator
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .move(edge: .top)),
                                removal: .opacity.combined(with: .scale(scale: 0.95))
                            ))
                    }
                    
                    reasonCard(proxy: proxy)
                        .id(AdjustmentSection.reason.rawValue)
                }
                .padding(.horizontal, FSpacing.lg)
                .padding(.bottom, FSpacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: hasActiveKeyboard ? Constants.Layout.keyboardSafeAreaPadding : 0)
            }
            .onChange(of: isReasonFocused) { _, newValue in
                handleFocusChange(for: .reason, isFocused: newValue, proxy: proxy)
            }
        }
    }
    
    // MARK: - Balance Input Section
    
    private var balanceInputSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text(formattedNewBalance)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(FColors.textPrimary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(Constants.Animation.numericTransition, value: newBalance)
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)
                
                // ✅ Cursor always re-starts blinking on tap
                if isBalanceFocused {
                    Rectangle()
                        .fill(cursorColor)
                        .frame(width: 2, height: 38)
                        .opacity(cursorOpacity)
                        .padding(.leading, 2)
                        .onAppear { startCursorBlink() }
                        .onChange(of: cursorToken) { _, _ in startCursorBlink() }
                }
            }
            
            Text("Nuevo balance")
                .font(.caption)
                .foregroundStyle(FColors.textTertiary)
            
            HiddenBalanceInput(
                text: $newBalanceString,
                isFocused: $isBalanceFocused,
                focusTask: $balanceFocusTask,
                refocusToken: balanceFocusToken
            )
            .frame(width: 0, height: 0)
            .opacity(0)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FSpacing.xl)
        .contentShape(Rectangle())
        .onTapGesture {
            Constants.Haptic.light()
            
            // ✅ Don’t fight the sheet on first appear; focus only on user tap.
            isBalanceFocused = true
            
            // ✅ Ensure cursor starts blinking immediately every time
            cursorToken += 1
        }
    }
    
    // MARK: - NEW: Helper Card under Balance
    
    private var balanceHelperCard: some View {
        // Same styling as the Note card (blue icon / same radius & background)
        HStack(spacing: FSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(FColors.blue.opacity(colorScheme == .dark ? 0.18 : 0.12))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(FColors.blue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Escribe el balance real de tu cuenta. Calcularemos la diferencia automáticamente.")
                    .font(.caption)
                    .foregroundStyle(FColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding(FSpacing.md)
        .padding(.vertical, 4) // ✅ a bit more height, subtle
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(cardBorder)
        .shadow(color: Color.black.opacity(0.02), radius: 6, y: 2)
    }
    
    // MARK: - Difference Indicator
    
    private var differenceIndicator: some View {
        HStack(spacing: FSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(differenceColor.opacity(colorScheme == .dark ? 0.18 : 0.12))
                    .frame(width: 40, height: 40)
                
                Image(systemName: difference >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(differenceColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(difference >= 0 ? "Incremento" : "Reducción")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FColors.textPrimary)
                
                Text("Diferencia")
                    .font(.caption)
                    .foregroundStyle(FColors.textSecondary)
            }
            
            Spacer()
            
            Text("\(difference >= 0 ? "+" : "")\(CurrencyConfig.format(difference, code: wallet.currencyCode))")
                .font(.body.weight(.bold))
                .foregroundStyle(differenceColor)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(Constants.Animation.numericTransition, value: difference)
        }
        .padding(FSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(differenceColor.opacity(colorScheme == .dark ? 0.1 : 0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(differenceColor.opacity(0.15), lineWidth: 1)
        )
    }
    
    private var differenceColor: Color {
        difference >= 0 ? FColors.green : FColors.red
    }
    
    // MARK: - Reason Card (Expandable)
    
    private func reasonCard(proxy: ScrollViewProxy) -> some View {
        AdjustmentExpandableCard(
            icon: "text.alignleft",
            iconColor: FColors.blue,
            title: "Nota",
            subtitle: reasonSubtitle,
            isExpanded: expandedSection == .reason,
            onToggle: { toggleSection(.reason, proxy: proxy) }
        ) {
            VStack(spacing: 0) {
                ReasonInputField(
                    text: $reason,
                    placeholder: "Ej: Corrección de cargo no registrado",
                    isFocused: $isReasonFocused,
                    focusTask: $reasonFocusTask,
                    refocusToken: reasonFocusToken
                )
                
                Color.clear
                    .frame(height: 1)
                    .id("scrollTarget-reason")
            }
        }
    }
    
    // MARK: - Bottom Toolbar
    
    private var bottomToolbar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0)
            
            HStack(spacing: FSpacing.md) {
                AdjustmentSaveButton(
                    title: isSaving ? "Ajustando..." : "Ajustar Balance",
                    isEnabled: isValid,
                    icon: isSaving ? nil : "checkmark"
                ) {
                    save()
                }
                
                if isInputActive {
                    AdjustmentKeyboardDismissButton {
                        Constants.Haptic.light()
                        dismissKeyboardAndCollapse()
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, FSpacing.lg)
            .padding(.top, FSpacing.lg)
            .padding(.bottom, FSpacing.md)
            .animation(Constants.Animation.buttonSpring, value: isInputActive)
        }
        .background(FColors.background.ignoresSafeArea(edges: .bottom))
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                Constants.Haptic.light()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(FColors.textPrimary)
            }
            .disabled(isSaving)
            .accessibilityLabel("Cerrar")
        }
    }
    
    // MARK: - Card Styling Helpers
    
    private var cardBackground: some View {
        colorScheme == .dark ? FColors.backgroundSecondary : Color.white
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(
                colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04),
                lineWidth: 1
            )
    }
    
    // MARK: - Cursor
    
    private func startCursorBlink() {
        // Reset + start a smooth blink every time we tap
        cursorOpacity = 1
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            cursorOpacity = 0
        }
    }
    
    // MARK: - Section Management
    
    private func toggleSection(_ section: AdjustmentSection, proxy: ScrollViewProxy) {
        Constants.Haptic.light()
        cancelScrollTask()
        
        // Dismiss balance focus if active
        if isBalanceFocused {
            isBalanceFocused = false
            hideKeyboard()
        }
        
        if expandedSection == section {
            collapseAndSave(section)
            scrollToTop(using: proxy)
            return
        }
        
        if expandedSection != nil {
            cancelAllFocusTasks()
            dismissAllFocus()
        }
        
        withAnimation(Constants.Animation.cardSpring) {
            expandedSection = section
        }
        
        switch section {
        case .reason:
            reasonFocusToken += 1
            isReasonFocused = true
        }
        
        scrollToSection(section, using: proxy)
    }
    
    private func collapseAndSave(_ section: AdjustmentSection) {
        cancelAllFocusTasks()
        
        switch section {
        case .reason:
            isReasonFocused = false
        }
        
        hideKeyboard()
        
        withAnimation(Constants.Animation.cardSpring) {
            expandedSection = nil
        }
    }
    
    private func handleFocusChange(for section: AdjustmentSection, isFocused: Bool, proxy: ScrollViewProxy) {
        guard !isFocused, expandedSection == section else { return }
        collapseAndSave(section)
        scrollToTop(using: proxy)
    }
    
    private func scrollToSection(_ section: AdjustmentSection, using proxy: ScrollViewProxy) {
        cancelScrollTask()
        
        let targetID = "scrollTarget-\(section.rawValue)"
        
        scrollTask = Task { @MainActor in
            try? await Task.sleep(for: Constants.Timing.expandedCardScrollDelay)
            guard !Task.isCancelled, expandedSection == section else { return }
            
            withAnimation(Constants.Animation.smoothSpring) {
                proxy.scrollTo(targetID, anchor: .bottom)
            }
            
            try? await Task.sleep(for: Constants.Timing.scrollNudgeDelay)
            guard !Task.isCancelled, expandedSection == section else { return }
            
            withAnimation(Constants.Animation.smoothSpring) {
                proxy.scrollTo(targetID, anchor: .bottom)
            }
        }
    }
    
    private func scrollToTop(using proxy: ScrollViewProxy) {
        cancelScrollTask()
        
        scrollTask = Task { @MainActor in
            try? await Task.sleep(for: Constants.Timing.scrollNudgeDelay)
            guard !Task.isCancelled, expandedSection == nil else { return }
            
            withAnimation(Constants.Animation.smoothSpring) {
                proxy.scrollTo("top", anchor: .top)
            }
        }
    }
    
    private func dismissKeyboardAndCollapse() {
        if isBalanceFocused {
            isBalanceFocused = false
            hideKeyboard()
            return
        }
        
        guard expandedSection != nil else {
            hideKeyboard()
            return
        }
        
        cancelAllFocusTasks()
        cancelScrollTask()
        
        if let section = expandedSection {
            collapseAndSave(section)
        }
    }
    
    // MARK: - Focus Management
    
    private func dismissAllFocus() {
        isBalanceFocused = false
        isReasonFocused = false
        hideKeyboard()
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
    
    private func cancelAllFocusTasks() {
        balanceFocusTask?.cancel()
        balanceFocusTask = nil
        reasonFocusTask?.cancel()
        reasonFocusTask = nil
    }
    
    private func cancelScrollTask() {
        scrollTask?.cancel()
        scrollTask = nil
    }
    
    private func cancelAllTasks() {
        cancelAllFocusTasks()
        cancelScrollTask()
    }
    
    // MARK: - Actions
    
    private func setupInitialStateIfNeeded() {
        guard !didAppearOnce else { return }
        didAppearOnce = true
        
        newBalanceString = formatForInput(currentBalance)
    }
    
    private func save() {
        guard let newBalance = newBalance, isValid else { return }
        
        cancelAllTasks()
        dismissAllFocus()
        isSaving = true
        
        Task { @MainActor in
            viewModel.adjustBalance(
                wallet,
                newBalance: newBalance,
                reason: reason.isEmpty ? nil : reason
            )
            Constants.Haptic.success()
            dismiss()
        }
    }
    
    // MARK: - Helpers
    
    private func formatForInput(_ value: Double) -> String {
        if value == 0 { return "" }
        if value == floor(value) {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }
}

// MARK: - Hidden Balance Input

private struct HiddenBalanceInput: View {
    @Binding var text: String
    @Binding var isFocused: Bool
    @Binding var focusTask: Task<Void, Never>?
    let refocusToken: Int
    
    @FocusState private var fieldFocus: Bool
    
    var body: some View {
        TextField("", text: $text)
            .keyboardType(.decimalPad)
            .focused($fieldFocus)
            .onChange(of: fieldFocus) { _, newValue in
                isFocused = newValue
            }
            .onChange(of: isFocused) { _, newValue in
                if newValue != fieldFocus {
                    fieldFocus = newValue
                }
            }
            .onAppear { syncFocus() }
            .onChange(of: refocusToken) { _, _ in syncFocus() }
            .onDisappear {
                focusTask?.cancel()
                focusTask = nil
            }
    }
    
    private func syncFocus() {
        // Only mirror external focus; do not force focus on appear.
        if fieldFocus != isFocused {
            fieldFocus = isFocused
        }
    }
}

// MARK: - Adjustment Expandable Card

private struct AdjustmentExpandableCard<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let isExpanded: Bool
    let onToggle: () -> Void
    @ViewBuilder let expandedContent: Content
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: FSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(iconColor.opacity(colorScheme == .dark ? 0.18 : 0.12))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(iconColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(FColors.textPrimary)
                        
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(FColors.textSecondary)
                            .lineLimit(1)
                            .contentTransition(.interpolate)
                            .animation(Constants.Animation.numericTransition, value: subtitle)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(FColors.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                expandedContent
                    .padding(.top, FSpacing.md)
            }
        }
        .padding(FSpacing.md)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(cardBorder)
        .shadow(color: Color.black.opacity(0.02), radius: 6, y: 2)
        .animation(Constants.Animation.cardSpring, value: isExpanded)
    }
    
    private var cardBackground: some View {
        colorScheme == .dark ? FColors.backgroundSecondary : Color.white
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(
                colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04),
                lineWidth: 1
            )
    }
}

// MARK: - Reason Input Field

private struct ReasonInputField: View {
    @Binding var text: String
    let placeholder: String
    @Binding var isFocused: Bool
    @Binding var focusTask: Task<Void, Never>?
    let refocusToken: Int
    
    @FocusState private var fieldFocus: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        TextField(placeholder, text: $text)
            .font(.body)
            .foregroundStyle(FColors.textPrimary)
            .focused($fieldFocus)
            .padding(.horizontal, FSpacing.md)
            .padding(.vertical, 14)
            .background(inputBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(inputBorder)
            .onChange(of: fieldFocus) { _, newValue in
                isFocused = newValue
            }
            .onChange(of: isFocused) { _, newValue in
                if newValue != fieldFocus {
                    fieldFocus = newValue
                }
            }
            .onAppear { triggerFocusIfNeeded() }
            .onChange(of: refocusToken) { _, _ in triggerFocusIfNeeded() }
            .onDisappear {
                focusTask?.cancel()
                focusTask = nil
            }
    }
    
    private var inputBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
    }
    
    private var inputBorder: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(isFocused ? FColors.brand.opacity(0.5) : Color.clear, lineWidth: 1.5)
    }
    
    private func triggerFocusIfNeeded() {
        guard !isFocused else { return }
        focusTask?.cancel()
        focusTask = Task { @MainActor in
            try? await Task.sleep(for: Constants.Timing.focusDelay)
            guard !Task.isCancelled else { return }
            isFocused = true
        }
    }
}

// MARK: - Adjustment Save Button

private struct AdjustmentSaveButton: View {
    let title: String
    let isEnabled: Bool
    let icon: String?
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var backgroundColor: Color {
        if !isEnabled { return FColors.textTertiary.opacity(0.2) }
        return colorScheme == .dark ? .white : .black
    }
    
    private var foregroundColor: Color {
        if !isEnabled { return FColors.textTertiary }
        return colorScheme == .dark ? .black : .white
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.body.weight(.semibold))
                
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Capsule().fill(backgroundColor))
            .shadow(color: isEnabled ? backgroundColor.opacity(0.25) : .clear, radius: 8, y: 4)
        }
        .disabled(!isEnabled)
        .buttonStyle(AdjustmentScaleButtonStyle())
    }
}

// MARK: - Adjustment Keyboard Dismiss Button

private struct AdjustmentKeyboardDismissButton: View {
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "keyboard.chevron.compact.down")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(FColors.textPrimary)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                )
        }
        .buttonStyle(AdjustmentScaleButtonStyle())
        .accessibilityLabel("Cerrar teclado")
    }
}

// MARK: - Adjustment Scale Button Style

private struct AdjustmentScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(Constants.Animation.quickSpring, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Balance Adjustment") {
    let wallet = Wallet(
        name: "Banco Popular",
        type: .checking,
        icon: .bank,
        color: .blue,
        currencyCode: "DOP",
        initialBalance: 45000,
        lastFourDigits: "4532"
    )
    
    Color.gray.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            BalanceAdjustmentSheet(wallet: wallet, viewModel: WalletsViewModel())
        }
}

#Preview("Dark Mode") {
    let wallet = Wallet(
        name: "Efectivo",
        type: .cash,
        icon: .cash,
        color: .green,
        currencyCode: "USD",
        initialBalance: 250
    )
    
    Color.gray.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            BalanceAdjustmentSheet(wallet: wallet, viewModel: WalletsViewModel())
        }
        .preferredColorScheme(.dark)
}
