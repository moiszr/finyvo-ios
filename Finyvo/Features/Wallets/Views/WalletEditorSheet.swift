//
//  WalletEditorSheet.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/24/25.
//  Refactored: Sheet para EDITAR billeteras únicamente.
//  La creación ahora usa WalletCreationFlow.
//

import SwiftUI

struct WalletEditorSheet: View {
    
    // MARK: - Properties
    
    @Bindable var viewModel: WalletsViewModel
    let mode: WalletEditorMode
    
    @State private var editor: WalletEditorViewModel
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @FocusState private var focusedField: Field?
    @State private var showDiscardAlert = false
    
    private enum Field: Hashable {
        case name, balance, lastFour
    }
    
    // MARK: - Computed
    
    private var previewWallet: Wallet {
        Wallet(
            name: editor.name.isEmpty ? "Mi Billetera" : editor.name,
            type: editor.type,
            icon: editor.icon,
            color: editor.color,
            currencyCode: editor.currencyCode,
            initialBalance: editor.balanceEnabled ? editor.initialBalance : 0,
            lastFourDigits: editor.lastFourEnabled ? (editor.lastFourDigits.isEmpty ? nil : editor.lastFourDigits) : nil
        )
    }
    
    private var currencySymbol: String {
        editor.selectedCurrency?.symbol ?? editor.currencyCode
    }
    
    // MARK: - Initialization
    
    init(viewModel: WalletsViewModel, mode: WalletEditorMode) {
        self.viewModel = viewModel
        self.mode = mode
        _editor = State(initialValue: WalletEditorViewModel(mode: mode))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                FColors.background.ignoresSafeArea()
                
                if !mode.isEditing {
                    // Guard: solo modo EDIT
                    ContentUnavailableView(
                        "Usar WalletCreationFlow",
                        systemImage: "exclamationmark.triangle",
                        description: Text("Este sheet es solo para edición")
                    )
                } else {
                    editContent
                }
            }
            .navigationTitle("Editar Billetera")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.regularMaterial)
        .presentationCornerRadius(32)
        .interactiveDismissDisabled(editor.hasChanges)
        .alert("Descartar cambios", isPresented: $showDiscardAlert) {
            Button("Seguir editando", role: .cancel) {}
            Button("Descartar", role: .destructive) { dismiss() }
        } message: {
            Text("Tienes cambios sin guardar. ¿Deseas descartarlos?")
        }
    }
    
    // MARK: - Edit Content
    
    private var editContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Card preview spacer
                Color.clear
                    .frame(height: cardPreviewHeight)
                
                // Form content
                VStack(spacing: FSpacing.lg) {
                    nameSection
                    typeSection
                    styleSection
                    currencySection
                    balanceSection
                    lastFourSection
                    defaultSection
                    
                    if editor.supportsPaymentReminder {
                        reminderSection
                    }
                }
                .padding(.horizontal, FSpacing.lg)
                .padding(.top, FSpacing.md)
                .padding(.bottom, FSpacing.xxxl)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .overlay(alignment: .top) {
            cardPreviewOverlay
        }
    }
    
    // MARK: - Card Preview
    
    private var cardPreviewHeight: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let cardWidth = screenWidth - (FSpacing.lg * 2)
        return (cardWidth / 1.586) + FSpacing.lg
    }
    
    private var cardPreviewOverlay: some View {
        VStack(spacing: 0) {
            WalletCardView(wallet: previewWallet)
                .padding(.horizontal, FSpacing.lg)
                .padding(.top, FSpacing.md)
                .shadow(
                    color: editor.color.color.opacity(colorScheme == .dark ? 0.3 : 0.2),
                    radius: 16,
                    y: 8
                )
            
            // Fade gradient
            LinearGradient(
                colors: [FColors.background, FColors.background.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)
        }
        .background(FColors.background)
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
                    .foregroundStyle(FColors.textPrimary)
            }
        }
        
        ToolbarItem(placement: .confirmationAction) {
            Button("Guardar") {
                save()
            }
            .font(.body.weight(.semibold))
            .foregroundStyle(editor.isValid ? FColors.brand : FColors.textTertiary)
            .disabled(!editor.isValid)
        }
    }
    
    // MARK: - Sections
    
    private var nameSection: some View {
        EditorSection(title: "Nombre") {
            FInput(
                text: $editor.name,
                placeholder: "Mi billetera",
                icon: "pencil",
                autocapitalization: .words,
                autocorrection: false,
                submitLabel: .done,
                onSubmit: { focusedField = nil }
            )
            .focused($focusedField, equals: .name)
            
            if editor.name.count > AppConfig.Limits.maxWalletNameLength - 5 {
                HStack {
                    Spacer()
                    Text("\(editor.name.count)/\(AppConfig.Limits.maxWalletNameLength)")
                        .font(.caption2)
                        .foregroundStyle(
                            editor.name.count >= AppConfig.Limits.maxWalletNameLength
                            ? FColors.danger : FColors.textTertiary
                        )
                }
            }
        }
    }
    
    private var typeSection: some View {
        EditorSection(title: "Tipo de cuenta") {
            Menu {
                ForEach(WalletType.allCases) { type in
                    Button {
                        editor.selectType(type)
                    } label: {
                        HStack {
                            Image(systemName: type.defaultIcon.systemName)
                            Text(type.title)
                            if editor.type == type {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: FSpacing.sm) {
                    Image(systemName: editor.type.defaultIcon.systemName)
                        .font(.body.weight(.medium))
                        .foregroundStyle(editor.type.defaultColor.color)
                        .frame(width: 24)
                    
                    Text(editor.type.title)
                        .font(.body)
                        .foregroundStyle(FColors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(FColors.textTertiary)
                }
                .padding(FSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: FRadius.md, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                )
            }
        }
    }
    
    private var styleSection: some View {
        EditorSection(title: "Apariencia") {
            HStack(spacing: FSpacing.xl) {
                // Icon preview
                VStack(spacing: FSpacing.xs) {
                    Image(systemName: editor.icon.systemName)
                        .font(.title2)
                        .foregroundStyle(editor.color.color)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(editor.color.color.opacity(0.15))
                        )
                    
                    Text("Icono")
                        .font(.caption2)
                        .foregroundStyle(FColors.textTertiary)
                }
                
                Spacer()
                
                // Color preview
                VStack(spacing: FSpacing.xs) {
                    Circle()
                        .fill(editor.color.color)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        )
                    
                    Text(editor.color.displayName(for: colorScheme))
                        .font(.caption2)
                        .foregroundStyle(FColors.textTertiary)
                }
            }
            .frame(maxWidth: .infinity)
            
            Text("Los cambios de estilo se realizan desde la vista de creación")
                .font(.caption)
                .foregroundStyle(FColors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, FSpacing.xs)
        }
    }
    
    private var currencySection: some View {
        EditorSection(title: "Moneda") {
            if let currency = editor.selectedCurrency {
                HStack(spacing: FSpacing.md) {
                    Text(currency.flag)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currency.code)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(FColors.textPrimary)
                        
                        Text(currency.name)
                            .font(.caption)
                            .foregroundStyle(FColors.textSecondary)
                    }
                    
                    Spacer()
                }
                .padding(FSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: FRadius.md, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                )
            }
            
            Text("La moneda no puede cambiarse después de crear la billetera")
                .font(.caption)
                .foregroundStyle(FColors.textTertiary)
        }
    }
    
    private var balanceSection: some View {
        EditorSection {
            ToggleRow(
                title: "Balance inicial",
                subtitle: "El monto con que inició esta cuenta",
                isOn: $editor.balanceEnabled
            ) {
                if editor.balanceEnabled {
                    FInput(
                        text: $editor.initialBalanceString,
                        placeholder: "0.00",
                        icon: "banknote",
                        prefix: currencySymbol,
                        keyboardType: .decimalPad,
                        autocapitalization: .never
                    )
                    .focused($focusedField, equals: .balance)
                }
            }
        }
    }
    
    private var lastFourSection: some View {
        EditorSection {
            ToggleRow(
                title: "Últimos 4 dígitos",
                subtitle: "Para identificación visual en la tarjeta",
                isOn: $editor.lastFourEnabled
            ) {
                if editor.lastFourEnabled {
                    FInput(
                        text: $editor.lastFourDigits,
                        placeholder: "1234",
                        icon: "number",
                        keyboardType: .numberPad,
                        autocapitalization: .never
                    )
                    .focused($focusedField, equals: .lastFour)
                    
                    if !editor.lastFourDigits.isEmpty && editor.lastFourDigits.count != 4 {
                        Text("Debe tener exactamente 4 dígitos")
                            .font(.caption)
                            .foregroundStyle(FColors.danger)
                    }
                }
            }
        }
    }
    
    private var defaultSection: some View {
        EditorSection {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Billetera principal")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(FColors.textPrimary)
                    
                    Text("Se usará por defecto en transacciones")
                        .font(.caption)
                        .foregroundStyle(FColors.textTertiary)
                }
                
                Spacer()
                
                Toggle("", isOn: $editor.isDefault)
                    .labelsHidden()
                    .tint(FColors.brand)
            }
        }
    }
    
    private var reminderSection: some View {
        EditorSection {
            ToggleRow(
                title: "Recordatorio de pago",
                subtitle: "Recibe una notificación mensual",
                isOn: $editor.paymentReminderEnabled
            ) {
                if editor.paymentReminderEnabled {
                    HStack {
                        Text("Día del mes")
                            .font(.subheadline)
                            .foregroundStyle(FColors.textSecondary)
                        
                        Spacer()
                        
                        Menu {
                            ForEach(editor.availableReminderDays, id: \.self) { day in
                                Button {
                                    editor.paymentReminderDay = day
                                } label: {
                                    HStack {
                                        Text("\(day)")
                                        if editor.paymentReminderDay == day {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text("\(editor.paymentReminderDay)")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(FColors.textPrimary)
                                
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(FColors.textTertiary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleClose() {
        focusedField = nil
        
        if editor.hasChanges {
            showDiscardAlert = true
        } else {
            dismiss()
        }
    }
    
    private func save() {
        focusedField = nil
        
        guard let wallet = mode.wallet else { return }
        
        if editor.applyChanges(to: wallet) {
            viewModel.updateWallet(wallet)
            Task { @MainActor in Constants.Haptic.success() }
            dismiss()
        }
    }
}

// MARK: - Editor Section

private struct EditorSection<Content: View>: View {
    var title: String?
    @ViewBuilder let content: Content
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: FSpacing.sm) {
            if let title {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FColors.textSecondary)
            }
            
            content
        }
        .padding(FSpacing.lg)
        .background(sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: FRadius.lg, style: .continuous))
        .overlay(sectionBorder)
    }
    
    private var sectionBackground: some View {
        colorScheme == .dark
            ? FColors.backgroundSecondary
            : Color.white
    }
    
    private var sectionBorder: some View {
        RoundedRectangle(cornerRadius: FRadius.lg, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? Color.white.opacity(0.06)
                    : Color.black.opacity(0.04),
                lineWidth: 1
            )
    }
}

// MARK: - Toggle Row

private struct ToggleRow<Content: View>: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    @ViewBuilder let expandedContent: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: FSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(FColors.textPrimary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(FColors.textTertiary)
                }
                
                Spacer()
                
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(FColors.brand)
            }
            
            if isOn {
                expandedContent
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isOn)
    }
}

// MARK: - Preview

#Preview {
    let wallet = Wallet(
        name: "Banco Popular",
        type: .checking,
        color: .blue,
        currencyCode: "DOP",
        initialBalance: 45000
    )
    
    Color.clear
        .sheet(isPresented: .constant(true)) {
            WalletEditorSheet(
                viewModel: WalletsViewModel(),
                mode: .edit(wallet)
            )
        }
}
