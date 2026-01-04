//
//  WalletCreationFlow.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/29/25.
//  Updated on 01/04/26 - Ultimate Premium Polish v6.
//

import SwiftUI
import SwiftData

// MARK: - Creation Steps

enum WalletCreationStep: Int, CaseIterable, Sendable {
    case name = 0
    case type = 1
    case style = 2
    case currency = 3
    case review = 4
    
    var title: String {
        switch self {
        case .name:     return "Nombre"
        case .type:     return "Tipo de Cuenta"
        case .style:    return "Personalización"
        case .currency: return "Moneda"
        case .review:   return "Revisión"
        }
    }
    
    func next() -> WalletCreationStep? {
        WalletCreationStep(rawValue: rawValue + 1)
    }
    
    func previous() -> WalletCreationStep? {
        guard rawValue > 0 else { return nil }
        return WalletCreationStep(rawValue: rawValue - 1)
    }
}

// MARK: - Main View

struct WalletCreationFlow: View {
    
    @Bindable var viewModel: WalletsViewModel
    @State private var editor: WalletEditorViewModel
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var currentStep: WalletCreationStep = .name
    @State private var showDiscardAlert = false
    @State private var direction: Int = 1
    
    private let smoothTransition: Animation = .spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2)
    
    init(viewModel: WalletsViewModel) {
        self.viewModel = viewModel
        _editor = State(initialValue: WalletEditorViewModel(mode: .create))
    }
    
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
    
    private var canProceedFromName: Bool {
        let trimmed = editor.name.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 2 && trimmed.count <= AppConfig.Limits.maxWalletNameLength
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { hideKeyboard() }
                
                VStack(spacing: 0) {
                    MonochromaticProgressIndicator(
                        currentStep: currentStep.rawValue,
                        totalSteps: WalletCreationStep.allCases.count
                    )
                    .padding(.top, FSpacing.md)
                    .padding(.bottom, FSpacing.sm)
                    
                    ZStack {
                        stepContent
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: direction > 0 ? .trailing : .leading).combined(with: .opacity).combined(with: .scale(scale: 0.99)),
                                    removal: .move(edge: direction > 0 ? .leading : .trailing).combined(with: .opacity)
                                )
                            )
                            .id(currentStep)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    bottomSection
                }
            }
            .background(FColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(currentStep.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { handleClose() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(FColors.textPrimary)
                    }
                    .accessibilityLabel("Cerrar")
                }
            }
            .alert("Descartar cambios", isPresented: $showDiscardAlert) {
                Button("Continuar editando", role: .cancel) {}
                Button("Descartar", role: .destructive) { dismiss() }
            } message: {
                Text("¿Seguro que quieres salir? Perderás los cambios.")
            }
        }
        .presentationDragIndicator(.visible)
        .presentationBackground(FColors.background)
        .interactiveDismissDisabled(editor.hasChanges)
    }
    
    private var bottomSection: some View {
        VStack(spacing: 0) {
            Divider().opacity(0)
            actionButtons
                .padding(.horizontal, FSpacing.lg)
                .padding(.top, FSpacing.xl)
                .padding(.bottom, FSpacing.md)
        }
        .background(FColors.background.ignoresSafeArea(edges: .bottom))
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        switch currentStep {
        case .name:
            FlowContinueButton(title: "Continuar", isEnabled: canProceedFromName, action: goToNextStep, icon: "arrow.right")
        case .review:
            HStack(spacing: FSpacing.md) {
                FlowBackButton(action: goToPreviousStep)
                FlowContinueButton(title: "Crear Billetera", isEnabled: true, action: createWallet, icon: "checkmark", variant: .brand)
            }
        default:
            HStack(spacing: FSpacing.md) {
                FlowBackButton(action: goToPreviousStep)
                FlowContinueButton(title: "Continuar", isEnabled: true, action: goToNextStep, icon: "arrow.right")
            }
        }
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .name:
            NameStepView(name: $editor.name, isValid: canProceedFromName, onContinue: goToNextStep)
        case .type:
            TypeStepView(selectedType: editor.type, onSelect: { editor.selectType($0) })
        case .style:
            StyleStepView(editor: editor, previewWallet: previewWallet)
        case .currency:
            CurrencyStepView(editor: editor)
        case .review:
            ReviewStepView(editor: editor)
        }
    }
    
    private func goToNextStep() {
        Constants.Haptic.light()
        hideKeyboard()
        guard let next = currentStep.next() else { return }
        direction = 1
        withAnimation(smoothTransition) { currentStep = next }
    }
    
    private func goToPreviousStep() {
        Constants.Haptic.light()
        hideKeyboard()
        guard let previous = currentStep.previous() else { return }
        direction = -1
        withAnimation(smoothTransition) { currentStep = previous }
    }
    
    private func handleClose() {
        hideKeyboard()
        if editor.hasChanges { showDiscardAlert = true } else { dismiss() }
    }
    
    private func createWallet() {
        Constants.Haptic.success()
        guard let data = editor.buildNewWalletData() else { return }
        viewModel.createWallet(
            name: data.name, type: data.type, icon: data.icon, color: data.color,
            currencyCode: data.currencyCode, initialBalance: data.initialBalance,
            isDefault: data.isDefault, paymentReminderDay: data.paymentReminderDay,
            notes: data.notes, lastFourDigits: data.lastFourDigits
        )
        dismiss()
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Progress Indicator

private struct MonochromaticProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(indicatorColor(isActive: index <= currentStep))
                    .frame(width: index == currentStep ? 32 : 6, height: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentStep)
            }
        }
        .frame(height: 10)
    }
    
    private func indicatorColor(isActive: Bool) -> Color {
        isActive
            ? (colorScheme == .light ? .black.opacity(0.8) : .white.opacity(0.9))
            : (colorScheme == .light ? .black.opacity(0.1) : .white.opacity(0.15))
    }
}

// MARK: - Flow Buttons

private struct FlowContinueButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void
    var icon: String? = nil
    var variant: FlowButtonVariant = .primary
    
    enum FlowButtonVariant { case primary, brand }
    @Environment(\.colorScheme) private var colorScheme
    
    private var backgroundColor: Color {
        if !isEnabled { return FColors.textTertiary.opacity(0.2) }
        return variant == .brand ? FColors.brand : (colorScheme == .dark ? .white : .black)
    }
    
    private var foregroundColor: Color {
        if !isEnabled { return FColors.textTertiary }
        return variant == .brand ? .white : (colorScheme == .dark ? .black : .white)
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title).font(.body.weight(.semibold))
                if let icon { Image(systemName: icon).font(.system(size: 14, weight: .bold)) }
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Capsule().fill(backgroundColor))
            .shadow(color: isEnabled ? backgroundColor.opacity(0.25) : .clear, radius: 8, y: 4)
        }
        .disabled(!isEnabled)
        .buttonStyle(FlowScaleButtonStyle())
    }
}

private struct FlowBackButton: View {
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(FColors.textPrimary)
                .frame(width: 56, height: 56)
                .background(Circle().fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05)))
        }
        .buttonStyle(FlowScaleButtonStyle())
    }
}

// MARK: - STEP 1: NAME

private struct NameStepView: View {
    @Binding var name: String
    let isValid: Bool
    let onContinue: () -> Void
    
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    private let maxLength = AppConfig.Limits.maxWalletNameLength
    
    private var isAtLimit: Bool {
        name.count >= maxLength
    }
    
    private var isNearLimit: Bool {
        name.count > maxLength - 10
    }
    
    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { isFocused = false }
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: FSpacing.xxl) {
                    ZStack {
                        Circle()
                            .fill(FColors.brand.opacity(colorScheme == .dark ? 0.08 : 0.05))
                            .frame(width: 120, height: 120)
                            .blur(radius: 20)
                        
                        Circle()
                            .fill(FColors.brand.opacity(colorScheme == .dark ? 0.15 : 0.1))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "wallet.bifold.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(FColors.brand)
                            .symbolEffect(.bounce, value: isFocused)
                    }
                    
                    VStack(spacing: FSpacing.sm) {
                        Text("¿Cómo se llama tu billetera?")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(FColors.textPrimary)
                        Text("Dale un nombre para identificarla")
                            .font(.subheadline)
                            .foregroundStyle(FColors.textSecondary)
                    }
                    .multilineTextAlignment(.center)
                    
                    // Input con límite estricto REAL
                    LimitedTextField(
                        text: $name,
                        placeholder: "Ej: Banco Principal",
                        maxLength: maxLength,
                        isFocused: $isFocused,
                        onSubmit: { if isValid { onContinue() } }
                    )
                    .padding(.horizontal, FSpacing.lg)
                    
                    // Counter solo cuando está cerca del límite
                    if isNearLimit {
                        Text("\(name.count)/\(maxLength)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(isAtLimit ? FColors.orange : FColors.textTertiary)
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }
                }
                .padding(.horizontal, FSpacing.lg)
                
                Spacer()
                Spacer()
            }
        }
        .onAppear {
            triggerFocus()
        }
        .onChange(of: isFocused) { old, new in
            // Cuando pierde foco y vuelve a la vista, re-focusear
        }
    }
    
    private func triggerFocus() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isFocused = true
        }
    }
}

// MARK: - Limited TextField (Previene escritura más allá del límite)

private struct LimitedTextField: View {
    @Binding var text: String
    let placeholder: String
    let maxLength: Int
    var isFocused: FocusState<Bool>.Binding
    var onSubmit: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        TextField(placeholder, text: $text)
            .font(.title3.weight(.medium))
            .multilineTextAlignment(.center)
            .padding(.horizontal, FSpacing.lg)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isFocused.wrappedValue ? FColors.brand.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
            .focused(isFocused)
            .submitLabel(.continue)
            .onSubmit(onSubmit)
            .onChange(of: text) { oldValue, newValue in
                // Prevenir escritura más allá del límite
                if newValue.count > maxLength {
                    text = String(newValue.prefix(maxLength))
                }
            }
    }
}

// MARK: - STEP 2: TYPE

private struct TypeStepView: View {
    let selectedType: WalletType
    let onSelect: (WalletType) -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    private let columns = [
        GridItem(.flexible(), spacing: FSpacing.md),
        GridItem(.flexible(), spacing: FSpacing.md)
    ]
    
    private var displayTypes: [WalletType] {
        [.cash, .checking, .savings, .creditCard, .digitalWallet, .investment, .crypto, .other]
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: FSpacing.lg) {
                    Text("Selecciona la categoría que mejor describa el propósito de esta cuenta.")
                        .font(.subheadline)
                        .foregroundStyle(FColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, FSpacing.xl)
                        .padding(.top, FSpacing.md)
                    
                    LazyVGrid(columns: columns, spacing: FSpacing.md) {
                        ForEach(displayTypes) { type in
                            TypeOptionCard(type: type, isSelected: selectedType == type) {
                                onSelect(type)
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    proxy.scrollTo(type.id, anchor: .center)
                                }
                            }
                            .id(type.id)
                        }
                    }
                    .padding(.horizontal, FSpacing.lg)
                }
                .padding(.bottom, 20)
            }
        }
    }
}

private struct TypeOptionCard: View {
    let type: WalletType
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: FSpacing.md) {
                ZStack {
                    Circle()
                        .fill(isSelected ? type.defaultColor.color : type.defaultColor.color.opacity(colorScheme == .dark ? 0.15 : 0.1))
                        .frame(width: 56, height: 56)
                    Image(systemName: type.defaultIcon.systemName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : type.defaultColor.color)
                }
                
                VStack(spacing: 2) {
                    Text(type.shortTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FColors.textPrimary)
                    
                    Text(type.helpDescription)
                        .font(.caption2)
                        .foregroundStyle(FColors.textTertiary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, FSpacing.sm)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(height: 32, alignment: .top)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FSpacing.lg)
            .padding(.horizontal, FSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(colorScheme == .dark ? FColors.backgroundSecondary : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? type.defaultColor.color : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? type.defaultColor.color.opacity(0.2) : .black.opacity(0.03), radius: isSelected ? 12 : 8, y: 4)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(FlowScaleButtonStyle())
    }
}

// MARK: - STEP 3: STYLE

private struct StyleStepView: View {
    @Bindable var editor: WalletEditorViewModel
    let previewWallet: Wallet
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: FSpacing.xl) {
                WalletCardView(wallet: previewWallet)
                    .shadow(color: editor.color.color.opacity(0.35), radius: 15, y: 12)
                    .padding(.horizontal, FSpacing.lg)
                    .padding(.top, FSpacing.xl)
                
                VStack(alignment: .leading, spacing: FSpacing.xl) {
                    VStack(alignment: .leading, spacing: FSpacing.md) {
                        Text("Color")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(FColors.textTertiary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .padding(.horizontal, FSpacing.lg)
                            .padding(.top, FSpacing.md)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: FSpacing.md) {
                                ForEach(FCardColor.allCases) { color in
                                    ColorOptionButton(color: color, isSelected: editor.color == color) {
                                        editor.selectColor(color)
                                    }
                                }
                            }
                            .padding(.horizontal, FSpacing.lg)
                            .padding(.vertical, 10)
                        }
                        .padding(.vertical, -10)
                    }
                    
                    VStack(alignment: .leading, spacing: FSpacing.md) {
                        Text("Icono")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(FColors.textTertiary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .padding(.horizontal, FSpacing.lg)
                        
                        AdaptiveIconGrid(
                            icons: FWalletIcon.allOrdered,
                            selectedIcon: editor.icon,
                            selectedColor: editor.color,
                            onSelect: { editor.selectIcon($0) }
                        )
                        .padding(.horizontal, FSpacing.lg)
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
}

private struct AdaptiveIconGrid: View {
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
                    IconOptionButton(icon: icon, color: selectedColor, isSelected: selectedIcon == icon, size: itemSize) {
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

private struct ColorOptionButton: View {
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
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(color.contrastContentColor(for: colorScheme))
                        .shadow(radius: 1)
                }
            }
            .frame(width: 44, height: 44)
            .background(Circle().stroke(isSelected ? color.color : Color.clear, lineWidth: 2))
            .scaleEffect(isSelected ? 1.15 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

private struct IconOptionButton: View {
    let icon: FWalletIcon
    let color: FCardColor
    let isSelected: Bool
    let size: CGFloat
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected
                        ? color.color.opacity(colorScheme == .dark ? 0.22 : 0.14)
                        : (colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.03)))
                
                if !isSelected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.05), lineWidth: 1)
                }
                
                if isSelected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(color.color, lineWidth: 2)
                }
                
                Image(systemName: icon.systemName)
                    .font(.system(size: 19, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? color.color : FColors.textSecondary)
                    .symbolEffect(.bounce, value: isSelected)
            }
            .frame(width: size, height: size)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(FlowScaleButtonStyle())
    }
}

// MARK: - STEP 4: CURRENCY (Headers con ancho completo)

private struct CurrencyStepView: View {
    @Bindable var editor: WalletEditorViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    private var popularCurrencies: [Currency] { CurrencyConfig.popularCurrencies }
    private var allCurrenciesSorted: [Currency] {
        CurrencyConfig.allCurrencies.sorted { $0.code < $1.code }
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section {
                    currencyList(currencies: popularCurrencies)
                        .padding(.top, FSpacing.sm)
                } header: {
                    CurrencyStickyHeader(title: "Populares")
                }
                
                Section {
                    currencyList(currencies: allCurrenciesSorted.filter { !popularCurrencies.contains($0) })
                        .padding(.top, FSpacing.sm)
                } header: {
                    CurrencyStickyHeader(title: "Todas las monedas")
                }
            }
            .padding(.horizontal, FSpacing.lg)
            .padding(.bottom, 20)
        }
    }
    
    @ViewBuilder
    private func currencyList(currencies: [Currency]) -> some View {
        VStack(spacing: 12) {
            ForEach(currencies, id: \.code) { currency in
                CurrencyRow(currency: currency, isSelected: editor.currencyCode == currency.code) {
                    editor.selectCurrency(currency.code)
                }
            }
        }
        .padding(.bottom, 8)
    }
}

// Header con ancho completo para cubrir contenido al hacer scroll
private struct CurrencyStickyHeader: View {
    let title: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(FColors.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)
            Spacer()
        }
        .padding(.vertical, FSpacing.sm)
        .padding(.horizontal, 4)
        // Fondo extendido para cubrir el contenido que pasa por debajo
        .frame(maxWidth: .infinity)
        .background(
            FColors.background
                .padding(.horizontal, -FSpacing.lg) // Extiende más allá del padding del padre
        )
    }
}

private struct CurrencyRow: View {
    let currency: Currency
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: FSpacing.md) {
                Text(currency.flag)
                    .font(.title2)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(currency.code)
                        .font(.body.weight(.bold))
                        .foregroundStyle(FColors.textPrimary)
                        .monospaced()
                    Text(currency.name)
                        .font(.caption)
                        .foregroundStyle(FColors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Text(currency.symbol)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FColors.textTertiary)
                    .padding(.trailing, 4)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(FColors.brand)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, FSpacing.md)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected
                        ? FColors.brand.opacity(colorScheme == .dark ? 0.15 : 0.08)
                        : (colorScheme == .dark ? FColors.backgroundSecondary : Color.white))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? FColors.brand : Color.clear, lineWidth: 1.4)
            )
            .shadow(color: isSelected ? FColors.brand.opacity(0.15) : Color.black.opacity(colorScheme == .dark ? 0 : 0.04), radius: isSelected ? 8 : 6, y: 3)
            .scaleEffect(isSelected ? 1.01 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(FlowScaleButtonStyle())
    }
}

// MARK: - Review Field Enum

private enum ReviewField: Hashable {
    case balance
    case lastFour
}

// MARK: - STEP 5: REVIEW

private struct ReviewStepView: View {
    @Bindable var editor: WalletEditorViewModel
    
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var expandedCard: ReviewField? = nil
    @State private var showReminderPicker = false
    @State private var isKeyboardVisible = false
    
    private var livePreviewWallet: Wallet {
        let balance = editor.initialBalance
        let lastFour = editor.lastFourDigits.isEmpty ? nil : editor.lastFourDigits
        
        return Wallet(
            name: editor.name.isEmpty ? "Mi Billetera" : editor.name,
            type: editor.type,
            icon: editor.icon,
            color: editor.color,
            currencyCode: editor.currencyCode,
            initialBalance: balance,
            currentBalance: balance,
            lastFourDigits: lastFour
        )
    }
    
    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { dismissKeyboardAndCollapse() }
            
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: FSpacing.xl) {
                        WalletCardView(wallet: livePreviewWallet)
                            .shadow(color: editor.color.color.opacity(0.25), radius: 15, y: 12)
                            .padding(.horizontal, FSpacing.lg)
                            .padding(.top, FSpacing.xl)
                            .id("preview")
                        
                        VStack(spacing: FSpacing.md) {
                            // Balance
                            ReviewExpandableCard(
                                icon: "banknote.fill",
                                iconColor: FColors.green,
                                title: "Balance inicial",
                                subtitle: balanceSubtitle,
                                isExpanded: expandedCard == .balance,
                                onToggle: { toggleCard(.balance, proxy: proxy) }
                            ) {
                                BalanceInputContent(
                                    editor: editor,
                                    onDone: { dismissAndScrollToTop(proxy: proxy) }
                                )
                                .id(ReviewField.balance)
                            }
                            
                            // Default
                            ReviewCard {
                                HStack {
                                    ReviewIconLabel(icon: "star.fill", color: FColors.yellow, title: "Billetera principal", subtitle: "Usar por defecto")
                                    Spacer()
                                    Toggle("", isOn: $editor.isDefault)
                                        .labelsHidden()
                                        .tint(FColors.brand)
                                }
                            }
                            
                            // Last 4
                            if editor.type == .creditCard || editor.type == .debitCard {
                                ReviewExpandableCard(
                                    icon: "number",
                                    iconColor: FColors.blue,
                                    title: "Últimos 4 dígitos",
                                    subtitle: lastFourSubtitle,
                                    isExpanded: expandedCard == .lastFour,
                                    onToggle: { toggleCard(.lastFour, proxy: proxy) }
                                ) {
                                    LastFourInputContent(
                                        editor: editor,
                                        onDone: { dismissAndScrollToTop(proxy: proxy) }
                                    )
                                    .id(ReviewField.lastFour)
                                }
                            }
                            
                            // Payment Reminder - Sin redundancia
                            if editor.type.supportsPaymentReminder {
                                ReviewCard {
                                    HStack {
                                        // Solo mostrar el día en el subtítulo, no en el pill
                                        ReviewIconLabel(
                                            icon: "bell.fill",
                                            color: FColors.orange,
                                            title: "Recordatorio pago",
                                            subtitle: editor.paymentReminderEnabled
                                                ? "Día \(editor.paymentReminderDay) del mes"
                                                : "Desactivado"
                                        )
                                        Spacer()
                                        
                                        // Solo mostrar el botón de editar si está habilitado
                                        if editor.paymentReminderEnabled {
                                            Button {
                                                Constants.Haptic.light()
                                                showReminderPicker = true
                                            } label: {
                                                Image(systemName: "pencil")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundStyle(FColors.brand)
                                                    .frame(width: 32, height: 32)
                                                    .background(Circle().fill(FColors.brand.opacity(0.12)))
                                            }
                                        }
                                        
                                        Toggle("", isOn: $editor.paymentReminderEnabled)
                                            .labelsHidden()
                                            .tint(FColors.brand)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, FSpacing.lg)
                    }
                    .padding(.bottom, 20)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .sheet(isPresented: $showReminderPicker) {
            DayPickerSheet(selectedDay: $editor.paymentReminderDay)
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
        }
    }
    
    private var balanceSubtitle: String {
        if !editor.initialBalanceString.isEmpty && editor.initialBalanceString != "0" {
            return CurrencyConfig.format(editor.initialBalance, code: editor.currencyCode)
        }
        return "Opcional"
    }
    
    private var lastFourSubtitle: String {
        if !editor.lastFourDigits.isEmpty {
            return "•••• \(editor.lastFourDigits)"
        }
        return "Opcional"
    }
    
    private func toggleCard(_ card: ReviewField, proxy: ScrollViewProxy) {
        Constants.Haptic.light()
        
        if expandedCard == card {
            dismissAndScrollToTop(proxy: proxy)
            return
        }
        
        if expandedCard != nil {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            expandedCard = card
        }
        
        // Scroll suave al card expandido
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                proxy.scrollTo(card, anchor: .center)
            }
        }
    }
    
    private func dismissAndScrollToTop(proxy: ScrollViewProxy) {
        // Guardar estados
        if expandedCard == .balance {
            editor.balanceEnabled = !editor.initialBalanceString.isEmpty && editor.initialBalanceString != "0"
        }
        if expandedCard == .lastFour {
            editor.lastFourEnabled = !editor.lastFourDigits.isEmpty
        }
        
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            expandedCard = nil
        }
        
        // Scroll suave hacia arriba para mostrar la vista completa
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                proxy.scrollTo("preview", anchor: .top)
            }
        }
    }
    
    private func dismissKeyboardAndCollapse() {
        if expandedCard == .balance {
            editor.balanceEnabled = !editor.initialBalanceString.isEmpty && editor.initialBalanceString != "0"
        }
        if expandedCard == .lastFour {
            editor.lastFourEnabled = !editor.lastFourDigits.isEmpty
        }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            expandedCard = nil
        }
        
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Day Picker Sheet

private struct DayPickerSheet: View {
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
                    .foregroundStyle(FColors.brand)
                }
            }
        }
    }
}

// MARK: - Review Components

private struct ReviewExpandableCard<Content: View>: View {
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
                HStack {
                    ReviewIconLabel(icon: icon, color: iconColor, title: title, subtitle: subtitle)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(FColors.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                expandedContent
                    .padding(.top, FSpacing.md)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.98, anchor: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.98, anchor: .top))
                    ))
            }
        }
        .padding(FSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .dark ? FColors.backgroundSecondary : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 6, y: 2)
    }
}

// MARK: - Input con límite estricto y toolbar propio

private struct BalanceInputContent: View {
    @Bindable var editor: WalletEditorViewModel
    let onDone: () -> Void
    
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    private let maxLength = 15
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text(editor.selectedCurrency?.symbol ?? "$")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(FColors.textSecondary)
                
                TextField("0.00", text: $editor.initialBalanceString)
                    .font(.body)
                    .keyboardType(.decimalPad)
                    .focused($isFocused)
                    .onChange(of: editor.initialBalanceString) { oldValue, newValue in
                        // Límite estricto - prevenir escritura
                        if newValue.count > maxLength {
                            editor.initialBalanceString = String(newValue.prefix(maxLength))
                            return
                        }
                        editor.balanceEnabled = !editor.initialBalanceString.isEmpty && editor.initialBalanceString != "0"
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isFocused ? FColors.brand.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
            
            // Botón Listo inline - siempre visible cuando está expandido
            Button {
                isFocused = false
                onDone()
            } label: {
                Text("Listo")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FColors.brand)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .padding(.top, FSpacing.sm)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isFocused = true
            }
        }
    }
}

private struct LastFourInputContent: View {
    @Bindable var editor: WalletEditorViewModel
    let onDone: () -> Void
    
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            TextField("0000", text: $editor.lastFourDigits)
                .font(.title3.weight(.medium).monospaced())
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .onChange(of: editor.lastFourDigits) { oldValue, newValue in
                    // Solo números
                    let filtered = newValue.filter { $0.isNumber }
                    
                    // Límite estricto de 4 - prevenir escritura
                    if filtered.count > 4 {
                        editor.lastFourDigits = String(filtered.prefix(4))
                        return
                    }
                    
                    // Aplicar filtro si había caracteres no numéricos
                    if filtered != newValue {
                        editor.lastFourDigits = filtered
                        return
                    }
                    
                    editor.lastFourEnabled = !editor.lastFourDigits.isEmpty
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isFocused ? FColors.brand.opacity(0.5) : Color.clear, lineWidth: 1.5)
                )
            
            // Botón Listo inline
            Button {
                isFocused = false
                onDone()
            } label: {
                Text("Listo")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FColors.brand)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .padding(.top, FSpacing.sm)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isFocused = true
            }
        }
    }
}

private struct ReviewCard<Content: View>: View {
    @ViewBuilder let content: Content
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        content
            .padding(FSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(colorScheme == .dark ? FColors.backgroundSecondary : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04), lineWidth: 1)
            )
    }
}

private struct ReviewIconLabel: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: FSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.15))
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(color)
            }
            .frame(width: 44, height: 44)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(FColors.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(FColors.textSecondary)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: subtitle)
            }
        }
    }
}

// MARK: - Preview

#Preview("Wallet Creation") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Wallet.self, configurations: config)
    let viewModel = WalletsViewModel()
    return Color.gray.ignoresSafeArea().sheet(isPresented: .constant(true)) {
        WalletCreationFlow(viewModel: viewModel)
    }.modelContainer(container)
}
