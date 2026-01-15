//
//  WalletEditView.swift
//  Finyvo
//
//  Created by Moises Núñez on 01/14/26.
//  Production-ready wallet edit view with premium UX.
//
//  Updates (01/14/26):
//   - Fixed default wallet logic: uses setAsDefault() to clear others
//   - Toggle disabled when wallet is already default (can't unset)
//   - Dynamic subtitle shows current state
//   - StyleIconGrid height calculation fixed
//

import SwiftUI
import SwiftData

private enum SubtitleAnimationStyle {
    case none
    case interpolate
    case numeric
}

// MARK: - Wallet Edit View

struct WalletEditView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Dependencies

    @Bindable var viewModel: WalletsViewModel
    let wallet: Wallet

    // MARK: - State

    @State private var editor: WalletEditorViewModel
    @State private var showDiscardAlert = false
    @State private var isSaving = false

    // Expanded sections
    @State private var expandedSection: EditSection? = nil

    // Focus management
    @State private var isNameFocused = false
    @State private var isBalanceFocused = false
    @State private var isLastFourFocused = false

    // Focus tokens for re-triggering
    @State private var nameFocusToken: Int = 0
    @State private var balanceFocusToken: Int = 0
    @State private var lastFourFocusToken: Int = 0

    // Task management
    @State private var nameFocusTask: Task<Void, Never>?
    @State private var balanceFocusTask: Task<Void, Never>?
    @State private var lastFourFocusTask: Task<Void, Never>?
    @State private var scrollTask: Task<Void, Never>?

    // Sheet states
    @State private var showStylePicker = false

    // MARK: - Types

    private enum EditSection: String, CaseIterable {
        case name
        case balance
        case lastFour
    }

    // MARK: - Layout Constants

    private enum Layout {
        static let cardHorizontalPadding: CGFloat = 20
    }

    // MARK: - Computed Properties

    private var previewWallet: Wallet {
        Wallet(
            name: editor.name.isEmpty ? wallet.name : editor.name,
            type: editor.type,
            icon: editor.icon,
            color: editor.color,
            currencyCode: editor.currencyCode,
            initialBalance: editor.balanceEnabled ? editor.initialBalance : wallet.initialBalance,
            currentBalance: editor.balanceEnabled ? editor.initialBalance : wallet.currentBalance,
            isDefault: editor.isDefault,
            paymentReminderDay: editor.paymentReminderEnabled ? editor.paymentReminderDay : wallet.paymentReminderDay,
            notes: wallet.notes,
            lastFourDigits: editor.lastFourEnabled ? (editor.lastFourDigits.isEmpty ? nil : editor.lastFourDigits) : wallet.lastFourDigits
        )
    }

    private var hasActiveKeyboard: Bool {
        isNameFocused || isBalanceFocused || isLastFourFocused
    }

    private var isInputActive: Bool {
        hasActiveKeyboard && expandedSection != nil
    }

    private var currencySymbol: String {
        editor.selectedCurrency?.symbol ?? editor.currencyCode
    }

    private var canSave: Bool {
        editor.isValid && editor.hasChanges && !isSaving
    }
    
    /// Subtitle for the default toggle card
    private var defaultSubtitle: String {
        if wallet.isDefault {
            return "Billetera actual"
        }
        return editor.isDefault ? "Se marcará como principal" : "Usar por defecto"
    }

    // MARK: - Initialization

    init(viewModel: WalletsViewModel, wallet: Wallet) {
        self.viewModel = viewModel
        self.wallet = wallet
        _editor = State(initialValue: WalletEditorViewModel(mode: .edit(wallet)))
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
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Editar")
            .toolbar { toolbarContent }
            .interactiveDismissDisabled(editor.hasChanges)
            .alert("Descartar cambios", isPresented: $showDiscardAlert) {
                Button("Continuar editando", role: .cancel) {}
                Button("Descartar", role: .destructive) { dismiss() }
            } message: {
                Text("¿Seguro que quieres salir? Perderás los cambios.")
            }
            .onDisappear { cancelAllTasks() }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(FColors.background)
        .presentationCornerRadius(32)
        .sheet(isPresented: $showStylePicker) {
            StylePickerSheet(
                selectedIcon: $editor.icon,
                selectedColor: $editor.color,
                walletType: editor.type
            )
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    cardSection
                        .id("card")

                    cardsStack(proxy: proxy)
                        .padding(.top, FSpacing.lg)

                    immutableSection
                        .padding(.top, FSpacing.lg)
                }
                .padding(.horizontal, Layout.cardHorizontalPadding)
                .padding(.bottom, FSpacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: hasActiveKeyboard ? Constants.Layout.keyboardSafeAreaPadding : 0)
            }
            .onChange(of: isNameFocused) { _, newValue in
                handleFocusChange(for: .name, isFocused: newValue, proxy: proxy)
            }
            .onChange(of: isBalanceFocused) { _, newValue in
                handleFocusChange(for: .balance, isFocused: newValue, proxy: proxy)
            }
            .onChange(of: isLastFourFocused) { _, newValue in
                handleFocusChange(for: .lastFour, isFocused: newValue, proxy: proxy)
            }
        }
    }

    // MARK: - Card Section

    private var cardSection: some View {
        VStack(spacing: 0) {
            WalletCardView(wallet: previewWallet)
                .shadow(
                    color: editor.color.color.opacity(colorScheme == .dark ? 0.35 : 0.25),
                    radius: 20,
                    y: 12
                )
                .padding(.top, FSpacing.lg)
        }
    }

    private func cardsStack(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: FSpacing.md) {

            ActionSectionCard(
                icon: "paintpalette.fill",
                iconColor: FColors.purple,
                title: "Estilo",
                subtitle: "Icono y color",
                subtitleAnimation: .interpolate,
                onTap: {
                    Constants.Haptic.light()
                    showStylePicker = true
                }
            )

            // FIXED: Default toggle with proper logic
            ToggleSectionCard(
                icon: "star.fill",
                iconColor: FColors.yellow,
                title: "Billetera principal",
                subtitle: defaultSubtitle,
                subtitleAnimation: .interpolate,
                isOn: Binding(
                    get: { editor.isDefault },
                    set: { newValue in
                        // Only allow enabling if not already default
                        // Cannot disable - there must always be a default
                        if newValue && !wallet.isDefault {
                            editor.isDefault = true
                        }
                    }
                ),
                isDisabled: wallet.isDefault // Can't toggle off current default
            )

            EditSectionCard(
                icon: "textformat",
                iconColor: FColors.textPrimary,
                title: "Nombre",
                subtitle: editor.name.isEmpty ? wallet.name : editor.name,
                subtitleAnimation: .interpolate,
                isExpanded: expandedSection == .name,
                onToggle: { toggleSection(.name, proxy: proxy) }
            ) {
                nameContent
            }
            .id(EditSection.name.rawValue)

            EditSectionCard(
                icon: "banknote.fill",
                iconColor: FColors.green,
                title: "Balance inicial",
                subtitle: balanceSubtitle,
                subtitleAnimation: .numeric,
                isExpanded: expandedSection == .balance,
                onToggle: { toggleSection(.balance, proxy: proxy) }
            ) {
                balanceContent
            }
            .id(EditSection.balance.rawValue)

            if editor.type.supportsLastFourDigits {
                EditSectionCard(
                    icon: "number",
                    iconColor: FColors.blue,
                    title: "Últimos 4 dígitos",
                    subtitle: lastFourSubtitle,
                    subtitleAnimation: .interpolate,
                    isExpanded: expandedSection == .lastFour,
                    onToggle: { toggleSection(.lastFour, proxy: proxy) }
                ) {
                    lastFourContent
                }
                .id(EditSection.lastFour.rawValue)
            }

            if editor.type.supportsPaymentReminder {
                PaymentReminderCard(
                    isEnabled: $editor.paymentReminderEnabled,
                    selectedDay: $editor.paymentReminderDay,
                    subtitleAnimation: .numeric
                )
            }
        }
    }

    // MARK: - Immutable Section (read-only, bottom)

    private var immutableSection: some View {
        VStack(alignment: .leading, spacing: FSpacing.md) {

            Text("Información")
                .font(.caption.weight(.bold))
                .foregroundStyle(FColors.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, 4)

            VStack(spacing: FSpacing.md) {
                InfoSectionCard(
                    icon: editor.type.defaultIcon.systemName,
                    iconColor: FColors.pink,
                    title: "Tipo de cuenta",
                    value: editor.type.title
                )

                if let currency = editor.selectedCurrency {
                    InfoSectionCard(
                        icon: "dollarsign.circle.fill",
                        iconColor: FColors.teal,
                        title: "Moneda",
                        value: "\(currency.flag) \(currency.code)"
                    )
                }
            }
        }
    }

    // MARK: - Section Contents

    private var nameContent: some View {
        VStack(spacing: 0) {
            EditInputField(
                text: $editor.name,
                placeholder: wallet.name,
                isFocused: $isNameFocused,
                focusTask: $nameFocusTask,
                refocusToken: nameFocusToken,
                keyboardType: .default,
                autocapitalization: .words,
                maxLength: AppConfig.Limits.maxWalletNameLength,
                showBackground: true
            )

            Color.clear
                .frame(height: 1)
                .id("scrollTarget-name")
        }
    }

    private var balanceContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: FSpacing.sm) {
                Text(currencySymbol)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(FColors.textSecondary)

                EditInputField(
                    text: $editor.initialBalanceString,
                    placeholder: "0.00",
                    isFocused: $isBalanceFocused,
                    focusTask: $balanceFocusTask,
                    refocusToken: balanceFocusToken,
                    keyboardType: .decimalPad,
                    maxLength: 15,
                    showBackground: false
                )
                .onChange(of: editor.initialBalanceString) { _, newValue in
                    editor.balanceEnabled = !newValue.isEmpty && newValue != "0"
                }
            }
            .padding(.horizontal, FSpacing.md)
            .padding(.vertical, 14)
            .background(inputFieldBackground(isFocused: isBalanceFocused))

            Color.clear
                .frame(height: 1)
                .id("scrollTarget-balance")
        }
    }

    private var lastFourContent: some View {
        VStack(spacing: 0) {
            EditInputField(
                text: $editor.lastFourDigits,
                placeholder: "0000",
                isFocused: $isLastFourFocused,
                focusTask: $lastFourFocusTask,
                refocusToken: lastFourFocusToken,
                keyboardType: .numberPad,
                textAlignment: .center,
                textFont: .title3.weight(.medium).monospaced(),
                maxLength: 4,
                inputFilter: { $0.filter(\.isNumber) },
                showBackground: true
            )
            .onChange(of: editor.lastFourDigits) { _, newValue in
                editor.lastFourEnabled = !newValue.isEmpty
            }

            Color.clear
                .frame(height: 1)
                .id("scrollTarget-lastFour")
        }
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0)

            HStack(spacing: FSpacing.md) {
                EditSaveButton(
                    title: isSaving ? "Guardando..." : "Guardar cambios",
                    isEnabled: canSave,
                    icon: isSaving ? nil : "checkmark"
                ) {
                    save()
                }

                if isInputActive {
                    EditKeyboardDismissButton {
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
                handleClose()
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

    // MARK: - Subtitles

    private var balanceSubtitle: String {
        if editor.balanceEnabled, !editor.initialBalanceString.isEmpty, editor.initialBalanceString != "0" {
            return CurrencyConfig.format(editor.initialBalance, code: editor.currencyCode)
        }
        return CurrencyConfig.format(wallet.initialBalance, code: wallet.currencyCode)
    }

    private var lastFourSubtitle: String {
        let digits = editor.lastFourEnabled ? editor.lastFourDigits : (wallet.lastFourDigits ?? "")
        return digits.isEmpty ? "Opcional" : "•••• \(digits)"
    }

    // MARK: - Helpers

    private func inputFieldBackground(isFocused: Bool) -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isFocused ? FColors.brand.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
    }

    // MARK: - Section Management

    private func toggleSection(_ section: EditSection, proxy: ScrollViewProxy) {
        Constants.Haptic.light()
        cancelScrollTask()

        if expandedSection == section {
            collapseAndSave(section)
            scrollToCard(using: proxy)
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
        case .name:
            nameFocusToken += 1
            isNameFocused = true
        case .balance:
            balanceFocusToken += 1
            isBalanceFocused = true
        case .lastFour:
            lastFourFocusToken += 1
            isLastFourFocused = true
        }

        scrollToSection(section, using: proxy)
    }

    private func collapseAndSave(_ section: EditSection) {
        cancelAllFocusTasks()

        switch section {
        case .name:
            isNameFocused = false
        case .balance:
            editor.balanceEnabled = !editor.initialBalanceString.isEmpty && editor.initialBalanceString != "0"
            isBalanceFocused = false
        case .lastFour:
            editor.lastFourEnabled = !editor.lastFourDigits.isEmpty
            isLastFourFocused = false
        }

        hideKeyboard()

        withAnimation(Constants.Animation.cardSpring) {
            expandedSection = nil
        }
    }

    private func handleFocusChange(for section: EditSection, isFocused: Bool, proxy: ScrollViewProxy) {
        guard !isFocused, expandedSection == section else { return }
        collapseAndSave(section)
        scrollToCard(using: proxy)
    }

    private func scrollToSection(_ section: EditSection, using proxy: ScrollViewProxy) {
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

    private func scrollToCard(using proxy: ScrollViewProxy) {
        cancelScrollTask()

        scrollTask = Task { @MainActor in
            try? await Task.sleep(for: Constants.Timing.scrollNudgeDelay)
            guard !Task.isCancelled, expandedSection == nil else { return }

            withAnimation(Constants.Animation.smoothSpring) {
                proxy.scrollTo("card", anchor: .top)
            }
        }
    }

    private func dismissKeyboardAndCollapse() {
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
        isNameFocused = false
        isBalanceFocused = false
        isLastFourFocused = false
        hideKeyboard()
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }

    private func cancelAllFocusTasks() {
        nameFocusTask?.cancel()
        nameFocusTask = nil
        balanceFocusTask?.cancel()
        balanceFocusTask = nil
        lastFourFocusTask?.cancel()
        lastFourFocusTask = nil
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

    private func handleClose() {
        cancelAllTasks()
        dismissAllFocus()

        if editor.hasChanges {
            showDiscardAlert = true
        } else {
            dismiss()
        }
    }

    // FIXED: Save now properly handles default wallet changes
    private func save() {
        guard canSave else { return }

        cancelAllTasks()
        dismissAllFocus()
        isSaving = true

        Task { @MainActor in
            // Check if this wallet is being promoted to default
            let willBecomeDefault = editor.isDefault && !wallet.isDefault
            
            if editor.applyChanges(to: wallet) {
                if willBecomeDefault {
                    // Use setAsDefault which clears other defaults and moves to front
                    viewModel.setAsDefault(wallet)
                } else {
                    viewModel.updateWallet(wallet)
                }
                Constants.Haptic.success()
                dismiss()
            } else {
                Constants.Haptic.error()
                isSaving = false
            }
        }
    }
}

// MARK: - Action Section Card (tap)

private struct ActionSectionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var subtitleAnimation: SubtitleAnimationStyle = .none
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
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

                    subtitleView(subtitle)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(FColors.textTertiary)
            }
            .padding(FSpacing.md)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(cardBorder)
            .shadow(color: Color.black.opacity(0.02), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func subtitleView(_ value: String) -> some View {
        let base = Text(value)
            .font(.caption)
            .foregroundStyle(FColors.textSecondary)
            .lineLimit(1)

        switch subtitleAnimation {
        case .none:
            base
        case .interpolate:
            base
                .contentTransition(.interpolate)
                .animation(Constants.Animation.numericTransition, value: value)
        case .numeric:
            base
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(Constants.Animation.numericTransition, value: value)
        }
    }

    private var cardBackground: some View {
        (colorScheme == .dark ? FColors.backgroundSecondary : Color.white)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(
                colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04),
                lineWidth: 1
            )
    }
}

// MARK: - Toggle Section Card (FIXED: added isDisabled parameter)

private struct ToggleSectionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var subtitleAnimation: SubtitleAnimationStyle = .none
    @Binding var isOn: Bool
    var isDisabled: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
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

                subtitleView(subtitle)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(FColors.brand)
                .disabled(isDisabled)
        }
        .padding(FSpacing.md)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(cardBorder)
        .shadow(color: Color.black.opacity(0.02), radius: 6, y: 2)
    }

    @ViewBuilder
    private func subtitleView(_ value: String) -> some View {
        let base = Text(value)
            .font(.caption)
            .foregroundStyle(FColors.textSecondary)
            .lineLimit(1)

        switch subtitleAnimation {
        case .none:
            base
        case .interpolate:
            base
                .contentTransition(.interpolate)
                .animation(Constants.Animation.numericTransition, value: value)
        case .numeric:
            base
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(Constants.Animation.numericTransition, value: value)
        }
    }

    private var cardBackground: some View {
        colorScheme == .dark ? FColors.backgroundSecondary : .white
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(
                colorScheme == .dark
                ? Color.white.opacity(0.06)
                : Color.black.opacity(0.04),
                lineWidth: 1
            )
    }
}

// MARK: - Edit Section Card

private struct EditSectionCard<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var subtitleAnimation: SubtitleAnimationStyle = .none
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

                        subtitleView(subtitle)
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

    @ViewBuilder
    private func subtitleView(_ value: String) -> some View {
        let base = Text(value)
            .font(.caption)
            .foregroundStyle(FColors.textSecondary)
            .lineLimit(1)

        switch subtitleAnimation {
        case .none:
            base
        case .interpolate:
            base
                .contentTransition(.interpolate)
                .animation(Constants.Animation.numericTransition, value: value)
        case .numeric:
            base
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(Constants.Animation.numericTransition, value: value)
        }
    }

    private var cardBackground: some View {
        colorScheme == .dark ? FColors.backgroundSecondary : .white
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(
                colorScheme == .dark
                ? Color.white.opacity(0.06)
                : Color.black.opacity(0.04),
                lineWidth: 1
            )
    }
}

// MARK: - Info Section Card

private struct InfoSectionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
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

                Text(value)
                    .font(.caption)
                    .foregroundStyle(FColors.textSecondary)
            }

            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(FColors.textTertiary)
        }
        .padding(FSpacing.md)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(cardBorder)
    }

    private var cardBackground: some View {
        (colorScheme == .dark ? FColors.backgroundSecondary : Color.white)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(
                colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04),
                lineWidth: 1
            )
    }
}

// MARK: - Payment Reminder Card

private struct PaymentReminderCard: View {
    @Binding var isEnabled: Bool
    @Binding var selectedDay: Int
    var subtitleAnimation: SubtitleAnimationStyle = .none

    @State private var showDayPicker = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: FSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(FColors.orange.opacity(colorScheme == .dark ? 0.18 : 0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: "bell.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(FColors.orange)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Recordatorio Pago")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FColors.textPrimary)

                subtitleView(isEnabled ? "Día \(selectedDay) del mes" : "Desactivado")
            }

            Spacer()

            if isEnabled {
                Button {
                    Constants.Haptic.light()
                    showDayPicker = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(FColors.brand)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(FColors.brand.opacity(0.12)))
                }
            }

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .tint(FColors.brand)
        }
        .padding(FSpacing.md)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(cardBorder)
        .sheet(isPresented: $showDayPicker) {
            PaymentDayPicker(selectedDay: $selectedDay)
        }
    }

    @ViewBuilder
    private func subtitleView(_ value: String) -> some View {
        let base = Text(value)
            .font(.caption)
            .foregroundStyle(FColors.textSecondary)
            .lineLimit(1)

        switch subtitleAnimation {
        case .none:
            base
        case .interpolate:
            base
                .contentTransition(.interpolate)
                .animation(Constants.Animation.numericTransition, value: value)
        case .numeric:
            base
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(Constants.Animation.numericTransition, value: value)
        }
    }

    private var cardBackground: some View {
        (colorScheme == .dark ? FColors.backgroundSecondary : Color.white)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(
                colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04),
                lineWidth: 1
            )
    }
}

// MARK: - Payment Day Picker

private struct PaymentDayPicker: View {
    @Binding var selectedDay: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Día del mes", selection: $selectedDay) {
                    ForEach(1...28, id: \.self) { day in
                        Text("Día \(day)").tag(day)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 200)

                Spacer()
            }
            .padding(.top, FSpacing.md)
            .navigationTitle("Día de pago")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") {
                        Constants.Haptic.light()
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(FColors.textPrimary)
                }
            }
        }
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Edit Input Field

private struct EditInputField: View {
    @Binding var text: String
    let placeholder: String
    @Binding var isFocused: Bool
    @Binding var focusTask: Task<Void, Never>?
    let refocusToken: Int
    var keyboardType: UIKeyboardType = .default
    var textAlignment: TextAlignment = .leading
    var textFont: Font = .body
    var autocapitalization: TextInputAutocapitalization = .never
    var maxLength: Int = 100
    var inputFilter: ((String) -> String)? = nil
    var showBackground: Bool = true

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        FInput(
            text: $text,
            placeholder: placeholder,
            keyboardType: keyboardType,
            autocapitalization: autocapitalization,
            autocorrection: false,
            submitLabel: .done,
            textAlignment: textAlignment,
            textFont: textFont,
            maxLength: maxLength,
            inputFilter: inputFilter,
            showDoneButton: false,
            externalFocus: $isFocused,
            style: .bare
        )
        .padding(.horizontal, showBackground ? FSpacing.md : 0)
        .padding(.vertical, showBackground ? 14 : 0)
        .background(
            Group {
                if showBackground {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(isFocused ? FColors.brand.opacity(0.5) : Color.clear, lineWidth: 1.5)
                        )
                }
            }
        )
        .onAppear { triggerFocusIfNeeded() }
        .onChange(of: refocusToken) { _, _ in triggerFocusIfNeeded() }
        .onDisappear {
            focusTask?.cancel()
            focusTask = nil
        }
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

// MARK: - Edit Save Button

private struct EditSaveButton: View {
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
        .buttonStyle(EditScaleButtonStyle())
    }
}

// MARK: - Edit Keyboard Dismiss Button

private struct EditKeyboardDismissButton: View {
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
        .buttonStyle(EditScaleButtonStyle())
        .accessibilityLabel("Cerrar teclado")
    }
}

// MARK: - Edit Scale Button Style

private struct EditScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(Constants.Animation.quickSpring, value: configuration.isPressed)
    }
}

// MARK: - Style Picker Sheet

private struct StylePickerSheet: View {
    @Binding var selectedIcon: FWalletIcon
    @Binding var selectedColor: FCardColor
    let walletType: WalletType

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var localIcon: FWalletIcon
    @State private var localColor: FCardColor

    init(selectedIcon: Binding<FWalletIcon>, selectedColor: Binding<FCardColor>, walletType: WalletType) {
        self._selectedIcon = selectedIcon
        self._selectedColor = selectedColor
        self.walletType = walletType
        self._localIcon = State(initialValue: selectedIcon.wrappedValue)
        self._localColor = State(initialValue: selectedColor.wrappedValue)
    }

    private var previewWallet: Wallet {
        Wallet(
            name: walletType.title,
            type: walletType,
            icon: localIcon,
            color: localColor,
            currencyCode: "USD",
            initialBalance: 0
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: FSpacing.xl) {
                    WalletCardView(wallet: previewWallet)
                        .shadow(color: localColor.color.opacity(0.35), radius: 15, y: 12)
                        .padding(.horizontal, FSpacing.lg)
                        .padding(.top, FSpacing.lg)

                    VStack(alignment: .leading, spacing: FSpacing.md) {
                        Text("Color")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(FColors.textTertiary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .padding(.horizontal, FSpacing.lg)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: FSpacing.md) {
                                ForEach(FCardColor.allCases) { color in
                                    StyleColorButton(color: color, isSelected: localColor == color) {
                                        Constants.Haptic.light()
                                        withAnimation(Constants.Animation.selectionSpring) {
                                            localColor = color
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, FSpacing.lg)
                            .padding(.vertical, FSpacing.sm)
                        }
                    }

                    VStack(alignment: .leading, spacing: FSpacing.md) {
                        Text("Icono")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(FColors.textTertiary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .padding(.horizontal, FSpacing.lg)

                        StyleIconGrid(
                            icons: FWalletIcon.allOrdered,
                            selectedIcon: localIcon,
                            selectedColor: localColor
                        ) { icon in
                            Constants.Haptic.light()
                            withAnimation(Constants.Animation.selectionSpring) {
                                localIcon = icon
                            }
                        }
                        .padding(.horizontal, FSpacing.lg)
                    }
                }
                .padding(.bottom, FSpacing.xxxl)
            }
            .background(FColors.background)
            .navigationTitle("Personalizar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(FColors.textPrimary)
                    }
                    .accessibilityLabel("Cerrar")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Aplicar") {
                        Constants.Haptic.success()
                        selectedIcon = localIcon
                        selectedColor = localColor
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(FColors.brand)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(FColors.background)
    }
}

// MARK: - Style Color Button

private struct StyleColorButton: View {
    let color: FCardColor
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(color.color)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(color.contrastContentColor(for: colorScheme))
                        .shadow(radius: 1)
                }
            }
            .frame(width: 44, height: 44)
            .background(
                Circle().stroke(isSelected ? color.color : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.15 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(Constants.Animation.selectionSpring, value: isSelected)
    }
}

// MARK: - Style Icon Grid (FIXED: added calculatedHeight)

private struct StyleIconGrid: View {
    let icons: [FWalletIcon]
    let selectedIcon: FWalletIcon
    let selectedColor: FCardColor
    let onSelect: (FWalletIcon) -> Void

    @State private var calculatedHeight: CGFloat = 250
    
    private let columns = 6
    private let spacing: CGFloat = 12

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let totalSpacing = spacing * CGFloat(columns - 1)
            let itemSize = floor((availableWidth - totalSpacing) / CGFloat(columns))
            let rows = ceil(Double(icons.count) / Double(columns))
            let gridHeight = CGFloat(rows) * itemSize + CGFloat(rows - 1) * spacing

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(itemSize), spacing: spacing), count: columns),
                spacing: spacing
            ) {
                ForEach(icons, id: \.rawValue) { icon in
                    StyleIconButton(
                        icon: icon,
                        color: selectedColor,
                        isSelected: selectedIcon == icon,
                        size: itemSize
                    ) {
                        onSelect(icon)
                    }
                }
            }
            .onAppear { calculatedHeight = gridHeight }
            .onChange(of: geometry.size.width) { _, _ in calculatedHeight = gridHeight }
        }
        .frame(height: calculatedHeight)
    }
}

// MARK: - Style Icon Button

private struct StyleIconButton: View {
    let icon: FWalletIcon
    let color: FCardColor
    let isSelected: Bool
    let size: CGFloat
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var bounceToken = 0

    private var cardFill: Color { colorScheme == .dark ? FColors.backgroundSecondary : .white }
    private var cardStroke: Color { colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04) }
    private var selectedFill: Color { color.color.opacity(colorScheme == .dark ? 0.22 : 0.14) }

    var body: some View {
        Button {
            bounceToken += 1
            onTap()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? selectedFill : cardFill)

                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? color.color : cardStroke, lineWidth: isSelected ? 2 : 1)

                Image(systemName: icon.systemName)
                    .font(.system(size: 19, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? color.color : FColors.textSecondary)
                    .symbolEffect(.bounce, value: bounceToken)
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(EditScaleButtonStyle())
        .animation(Constants.Animation.selectionSpring, value: isSelected)
    }
}
