//
//  TransactionEditorSheet.swift
//  Finyvo
//
//  Created by Moises Núñez on 01/15/26.
//  Redesigned on 02/01/26 - Premium Liquid Glass editor
//  Refined on 02/03/26 - Premium action bar with liquid glass
//  Optimized on 02/04/26 - Performance, accessibility, bug fixes
//
//  Layout:
//    - Conditional Spacers: center content only when keyboard hidden
//    - When keyboard visible: content stacks at top, selected tags hidden
//    - Action section fixed at bottom, SwiftUI pushes it above keyboard
//    - Tags selector bleeds to screen edges for premium feel
//

import SwiftUI
import SwiftData
internal import Combine

// MARK: - Editor Constants

private enum EditorConstants {
    static let iconSizeSmall: CGFloat = 10
    static let iconSizeMedium: CGFloat = 14
    static let iconSizeLarge: CGFloat = 16
    static let focusDelay: UInt64 = 400_000_000 // 400ms in nanoseconds

    enum AnimationConfig {
        static let keyboard = Animation.interpolatingSpring(stiffness: 300, damping: 30)
        static let quick = TransactionUI.quickAnimation
        static let breathing = Animation.spring(response: 0.4, dampingFraction: 0.8)
    }
}

// MARK: - Keyboard Adaptive Modifier

private struct KeyboardAdaptive: ViewModifier {
    @Binding var keyboardHeight: CGFloat
    var onKeyboardHide: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .onReceive(
                NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
                    .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification))
            ) { notification in
                guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                withAnimation(EditorConstants.AnimationConfig.keyboard) {
                    keyboardHeight = frame.height
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(EditorConstants.AnimationConfig.keyboard) {
                    keyboardHeight = 0
                }
                onKeyboardHide?()
            }
    }
}

extension View {
    fileprivate func keyboardAdaptive(
        height: Binding<CGFloat>,
        onHide: (() -> Void)? = nil
    ) -> some View {
        modifier(KeyboardAdaptive(keyboardHeight: height, onKeyboardHide: onHide))
    }
}

// MARK: - Transaction Editor Sheet

struct TransactionEditorSheet: View {
    
    // MARK: - Properties
    
    @Bindable var viewModel: TransactionsViewModel
    let mode: TransactionEditorMode
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Data Queries
    
    @Query(filter: #Predicate<Wallet> { !$0.isArchived })
    private var wallets: [Wallet]
    
    @Query private var allTags: [Tag]
    
    // MARK: - Form State
    
    @State private var selectedType: TransactionType
    @State private var amountText: String = ""
    @State private var note: String = ""
    @State private var date: Date = .now
    @State private var selectedWallet: Wallet?
    @State private var selectedDestinationWallet: Wallet?
    @State private var selectedCategory: Category?
    @State private var selectedTags: [Tag] = []
    
    // MARK: - UI State
    
    @State private var showCategoryPicker = false
    @State private var showWalletPicker = false
    @State private var showDestinationWalletPicker = false
    @State private var showDatePicker = false
    @State private var showTagsInput = false
    @State private var newTagName: String = ""
    @State private var keyboardHeight: CGFloat = 0
    @State private var isSaving = false
    @State private var filteredTags: [Tag] = []
    
    @FocusState private var focusedField: EditorField?
    
    // MARK: - Animation

    @Namespace private var typePillNamespace
    
    private enum EditorField: Hashable {
        case note
        case amount
        case tag
    }
    
    // MARK: - Init
    
    init(viewModel: TransactionsViewModel, mode: TransactionEditorMode) {
        self.viewModel = viewModel
        self.mode = mode
        
        switch mode {
        case .create(let type):
            _selectedType = State(initialValue: type)
        case .edit(let transaction):
            _selectedType = State(initialValue: transaction.type)
            _amountText = State(initialValue: Self.formatInitialAmount(transaction.amount))
            _note = State(initialValue: transaction.note ?? "")
            _date = State(initialValue: transaction.date)
            _selectedWallet = State(initialValue: transaction.wallet)
            _selectedDestinationWallet = State(initialValue: transaction.destinationWallet)
            _selectedCategory = State(initialValue: transaction.category)
            _selectedTags = State(initialValue: transaction.tags ?? [])
        }
    }
    
    // MARK: - Computed Properties
    
    private var amount: Double {
        let cleanText = amountText
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
        return Double(cleanText) ?? 0
    }
    
    private var currencySymbol: String {
        if let wallet = selectedWallet {
            return CurrencyConfig.symbol(for: wallet.currencyCode)
        }
        return CurrencyConfig.defaultCurrency.symbol
    }
    
    private var currencyCode: String {
        selectedWallet?.currencyCode ?? CurrencyConfig.defaultCurrency.code
    }
    
    private var isValid: Bool {
        guard amount > 0 else { return false }
        guard selectedWallet != nil else { return false }
        
        if selectedType != .transfer {
            guard selectedCategory != nil else { return false }
        }
        
        if selectedType == .transfer {
            guard selectedDestinationWallet != nil else { return false }
            guard selectedWallet?.id != selectedDestinationWallet?.id else { return false }
        }
        
        return true
    }
    
    private var hasChanges: Bool {
        !amountText.isEmpty || !note.isEmpty || selectedWallet != nil || selectedCategory != nil
    }
    
    private var typeColor: Color {
        switch selectedType {
        case .income: return FColors.green
        case .expense: return FColors.red
        case .transfer: return FColors.blue
        }
    }
    
    private var hasAmountValue: Bool {
        !amountText.isEmpty
    }
    
    private var isTagInputEmpty: Bool {
        newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var isKeyboardVisible: Bool {
        keyboardHeight > 0
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                mainContentArea
                actionSection
                    .padding(.horizontal, FSpacing.lg)
                    .padding(.top, FSpacing.sm)
                    .padding(.bottom, FSpacing.sm)
            }
            .background(FColors.background.ignoresSafeArea())
            .toolbar { toolbarContent }
        }
        .sheet(isPresented: $showCategoryPicker) { categoryPickerSheet }
        .sheet(isPresented: $showWalletPicker) { walletPickerSheet }
        .sheet(isPresented: $showDestinationWalletPicker) { destinationWalletPickerSheet }
        .sheet(isPresented: $showDatePicker) { DatePickerSheet(selectedDate: $date) }
        .onChange(of: selectedType) { _, newType in handleTypeChange(to: newType) }
        .onChange(of: focusedField) { _, newField in handleFocusChange(to: newField) }
        .onChange(of: newTagName) { _, newValue in updateFilteredTags(searchText: newValue) }
        .onChange(of: allTags) { _, _ in updateFilteredTags(searchText: newTagName) }
        .onChange(of: selectedTags) { _, _ in updateFilteredTags(searchText: newTagName) }
        .keyboardAdaptive(height: $keyboardHeight) {
            handleKeyboardHide()
        }
        .interactiveDismissDisabled(hasChanges)
        .presentationDragIndicator(.hidden)
        .presentationBackground(FColors.background)
        .task { await initialSetup() }
    }
    
    // MARK: - Main Content Area
    
    private var mainContentArea: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { dismissKeyboard() }
            
            VStack(spacing: FSpacing.md) {
                if !isKeyboardVisible {
                    Spacer(minLength: 0)
                }
                
                typePickerSection
                unifiedGlassCard
                
                if !selectedTags.isEmpty && !showTagsInput && !isKeyboardVisible {
                    selectedTagsRow
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                if !isKeyboardVisible {
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, FSpacing.lg)
            .padding(.top, isKeyboardVisible ? FSpacing.md : 0)
            .animation(EditorConstants.AnimationConfig.quick, value: isKeyboardVisible)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: EditorConstants.iconSizeMedium, weight: .semibold))
                    .foregroundStyle(FColors.textSecondary)
            }
            .accessibilityLabel("Cerrar editor")
            .accessibilityHint("Cierra el editor sin guardar")
        }
    }
    
    // MARK: - Sheet Builders
    
    private var categoryPickerSheet: some View {
        TransactionCategoryPickerSheet(
            selectedCategory: $selectedCategory,
            type: selectedType == .income ? CategoryType.income : CategoryType.expense
        )
    }
    
    private var walletPickerSheet: some View {
        TransactionWalletPickerSheet(
            selectedWallet: $selectedWallet,
            excludeWallet: nil
        )
    }
    
    private var destinationWalletPickerSheet: some View {
        TransactionWalletPickerSheet(
            selectedWallet: $selectedDestinationWallet,
            excludeWallet: selectedWallet
        )
    }
    
    // MARK: - Type Picker Section
    
    private var typePickerSection: some View {
        HStack(spacing: 10) {
            ForEach(TransactionTypePill.allCases) { pill in
                TransactionTypePillView(
                    pill: pill,
                    isSelected: selectedType == pill.type,
                    tint: pill.tint,
                    namespace: typePillNamespace
                ) {
                    withAnimation(EditorConstants.AnimationConfig.quick) {
                        selectedType = pill.type
                    }
                    Constants.Haptic.selection()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, FSpacing.xs)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tipo de transacción")
    }

    
    // MARK: - Unified Glass Card
    
    private var unifiedGlassCard: some View {
        VStack(alignment: .leading, spacing: FSpacing.md) {
            dateButton
                .padding(.bottom, FSpacing.xs)
            
            // Descripción y Monto con spacing reducido
            VStack(alignment: .leading, spacing: FSpacing.sm) { // 👈 Spacing más tight
                noteField
                amountField
            }
            
            selectorsRow
                .padding(.top, FSpacing.sm)
        }
        .padding(.vertical, FSpacing.lg)
        .padding(.horizontal, FSpacing.lg)
        .background(glassCardBackground)
        .scaleEffect(focusedField != nil ? 1.005 : 1.0)
        .animation(EditorConstants.AnimationConfig.breathing, value: focusedField != nil)
    }
    
    private var glassCardBackground: some View {
        GlassCardBackground()
    }
    
    // MARK: - Date Button (Capsule)
    
    private var dateButton: some View {
        Button {
            showDatePicker = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: EditorConstants.iconSizeMedium, weight: .semibold))
                    .foregroundStyle(FColors.blue)
                
                Text(dateDisplayText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FColors.textPrimary)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: EditorConstants.iconSizeSmall, weight: .bold))
                    .foregroundStyle(FColors.textTertiary)
            }
            .padding(.horizontal, TransactionUI.pillPaddingH)
            .padding(.vertical, TransactionUI.pillPaddingV)
            .background(
                Capsule()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Fecha de la transacción")
        .accessibilityValue(dateDisplayText)
        .accessibilityHint("Toca para cambiar la fecha")
    }
    
    private var dateDisplayText: String {
        if date.isToday {
            return "Hoy"
        } else if date.isYesterday {
            return "Ayer"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM yyyy"
            formatter.locale = Locale(identifier: "es")
            return formatter.string(from: date).capitalized
        }
    }
    
    // MARK: - Note Field
    
    private var noteField: some View {
        TextField("Descripción", text: $note)
            .font(.system(size: TransactionUI.mainFontSize, weight: .bold, design: .rounded))
            .foregroundStyle(FColors.textPrimary)
            .multilineTextAlignment(.leading)
            .focused($focusedField, equals: .note)
            .submitLabel(.next)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .onSubmit { focusedField = .amount }
            .accessibilityLabel("Descripción de la transacción")
            .accessibilityHint("Ingresa una descripción opcional")
    }
    
    // MARK: - Amount Field
    
    private var amountField: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            if hasAmountValue {
                Text(currencySymbol)
                    .font(.system(size: TransactionUI.mainFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(typeColor)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    .accessibilityHidden(true)
            }
            
            TextField("Monto", text: $amountText)
                .font(.system(size: TransactionUI.mainFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(hasAmountValue ? typeColor : FColors.textTertiary)
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .amount)
                .onChange(of: amountText) { _, newValue in
                    amountText = formatAmountInput(newValue)
                }
                .accessibilityLabel("Monto de la transacción")
                .accessibilityValue(hasAmountValue ? "\(currencySymbol)\(amountText)" : "Sin monto")
                .accessibilityHint("Ingresa el monto en \(currencyCode)")
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .animation(EditorConstants.AnimationConfig.quick, value: hasAmountValue)
    }
    
    // MARK: - Selectors Row
    
    private var selectorsRow: some View {
        HStack(spacing: FSpacing.sm) {
            TransactionCapsulePill(
                icon: selectedWallet?.icon.rawValue ?? "wallet.pass.fill",
                iconColor: selectedWallet?.color.color ?? FColors.textTertiary,
                title: selectedWallet?.name ?? "Billetera",
                isPlaceholder: selectedWallet == nil
            ) {
                showWalletPicker = true
            }
            .accessibilityLabel("Billetera")
            .accessibilityValue(selectedWallet?.name ?? "No seleccionada")
            .accessibilityHint("Toca para seleccionar una billetera")

            if selectedType != .transfer {
                TransactionCapsulePill(
                    icon: selectedCategory?.icon.rawValue ?? "square.grid.2x2.fill",
                    iconColor: selectedCategory?.color.color ?? FColors.textTertiary,
                    title: selectedCategory?.name ?? "Categoría",
                    isPlaceholder: selectedCategory == nil
                ) {
                    showCategoryPicker = true
                }
                .accessibilityLabel("Categoría")
                .accessibilityValue(selectedCategory?.name ?? "No seleccionada")
                .accessibilityHint("Toca para seleccionar una categoría")
            } else {
                TransactionCapsulePill(
                    icon: selectedDestinationWallet?.icon.rawValue ?? "wallet.pass.fill",
                    iconColor: selectedDestinationWallet?.color.color ?? FColors.textTertiary,
                    title: selectedDestinationWallet?.name ?? "Destino",
                    isPlaceholder: selectedDestinationWallet == nil
                ) {
                    showDestinationWalletPicker = true
                }
                .accessibilityLabel("Billetera destino")
                .accessibilityValue(selectedDestinationWallet?.name ?? "No seleccionada")
                .accessibilityHint("Toca para seleccionar la billetera destino")
            }
        }
    }
    
    // MARK: - Selected Tags Row
    
    private var selectedTagsRow: some View {
        FlowLayout(spacing: FSpacing.sm) {
            ForEach(selectedTags) { tag in
                TransactionTagChip(tag: tag) {
                    withAnimation(EditorConstants.AnimationConfig.quick) {
                        selectedTags.removeAll { $0.id == tag.id }
                    }
                    Constants.Haptic.light()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Etiquetas seleccionadas: \(selectedTags.count)")
    }
    
    // MARK: - Action Section
    
    private var actionSection: some View {
        VStack(spacing: 9) {
            if showTagsInput && !filteredTags.isEmpty {
                tagsScrollView
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity
                    ))
            }
            
            HStack(spacing: 12) {
                if showTagsInput {
                    tagsInputRow
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95, anchor: .leading).combined(with: .opacity),
                            removal: .scale(scale: 0.95, anchor: .leading).combined(with: .opacity)
                        ))
                } else {
                    normalActionButtons
                        .transition(.opacity)
                }
            }
            .animation(EditorConstants.AnimationConfig.quick, value: showTagsInput)
        }
        .animation(EditorConstants.AnimationConfig.quick, value: showTagsInput)
        .animation(EditorConstants.AnimationConfig.quick, value: newTagName)
    }
    
    private var tagsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filteredTags) { tag in
                    let isSelected = selectedTags.contains { $0.id == tag.id }
                    SelectableTagChip(tag: tag, isSelected: isSelected) {
                        Constants.Haptic.selection()
                        withAnimation(EditorConstants.AnimationConfig.quick) {
                            if isSelected {
                                selectedTags.removeAll { $0.id == tag.id }
                            } else {
                                selectedTags.append(tag)
                            }
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
                    ))
                }
            }
            .padding(.horizontal, FSpacing.lg)
            .animation(EditorConstants.AnimationConfig.quick, value: filteredTags.map { $0.id })
        }
        .scrollClipDisabled()
        .padding(.horizontal, -FSpacing.lg)
    }
    
    // MARK: - Update Filtered Tags
    
    private func updateFilteredTags(searchText: String) {
        let search = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filtered = search.isEmpty ? allTags : allTags.filter { $0.name.lowercased().contains(search) }
        
        let sorted = filtered.sorted { tag1, tag2 in
            let s1 = selectedTags.contains { $0.id == tag1.id }
            let s2 = selectedTags.contains { $0.id == tag2.id }
            if s1 != s2 { return s1 }
            return tag1.name.localizedCaseInsensitiveCompare(tag2.name) == .orderedAscending
        }
        
        // Animar el cambio de filteredTags
        withAnimation(EditorConstants.AnimationConfig.quick) {
            filteredTags = sorted
        }
    }
    
    // MARK: - Tags Input Row
    
    private var tagsInputRow: some View {
        HStack(spacing: 10) {
            tagsInputField
            tagsActionButton
        }
    }
    
    private var tagsInputField: some View {
        HStack(spacing: 0) {
            Image(systemName: "tag.fill")
                .font(.system(size: EditorConstants.iconSizeMedium, weight: .semibold))
                .foregroundStyle(FColors.textTertiary)
                .frame(width: 50)
            
            TextField("Nueva etiqueta...", text: $newTagName)
                .font(.subheadline)
                .focused($focusedField, equals: .tag)
                .submitLabel(.done)
                .onSubmit {
                    if !isTagInputEmpty {
                        addTagIfNeeded()
                    }
                }
                .padding(.trailing, 12)
                .accessibilityLabel("Nombre de la etiqueta")
                .accessibilityHint("Escribe el nombre de una nueva etiqueta o busca existentes")
        }
        .frame(height: TransactionUI.buttonHeight)
        .background(tagsInputBackground)
    }
    
    @ViewBuilder
    private var tagsInputBackground: some View {
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(.clear)
                .glassEffect(.regular.tint(FColors.textTertiary.opacity(0.1)))
        } else {
            Capsule()
                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                .overlay(
                    Capsule()
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.08), lineWidth: 1)
                )
        }
    }
    
    private var tagsActionButton: some View {
        Button {
            if isTagInputEmpty {
                closeTagsInput()
            } else {
                addTagIfNeeded()
            }
        } label: {
            Image(systemName: isTagInputEmpty ? "xmark" : "plus")
                .font(.system(size: EditorConstants.iconSizeLarge, weight: .bold))
                .foregroundStyle(isTagInputEmpty ? FColors.textSecondary : .white)
                .frame(width: TransactionUI.buttonHeight, height: TransactionUI.buttonHeight)
                .background(tagsActionButtonBackground)
                .contentShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle())
        .animation(EditorConstants.AnimationConfig.quick, value: isTagInputEmpty)
        .accessibilityLabel(isTagInputEmpty ? "Cerrar" : "Agregar etiqueta")
        .accessibilityHint(isTagInputEmpty ? "Cierra el campo de etiquetas" : "Agrega la etiqueta escrita")
    }
    
    @ViewBuilder
    private var tagsActionButtonBackground: some View {
        if #available(iOS 26.0, *) {
            Circle()
                .fill(isTagInputEmpty ? .clear : FColors.brand)
                .glassEffect(
                    isTagInputEmpty
                        ? .regular.tint(FColors.textTertiary.opacity(0.1))
                        : .regular.tint(FColors.brand.opacity(0.3))
                )
        } else {
            Circle()
                .fill(
                    isTagInputEmpty
                        ? (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                        : FColors.brand
                )
                .overlay(
                    Circle()
                        .stroke(
                            isTagInputEmpty
                                ? (colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.08))
                                : FColors.brand,
                            lineWidth: 1
                        )
                )
        }
    }
    
    private var normalActionButtons: some View {
        HStack(spacing: 12) {
            tagsToggleButton
            createButton
            
            if isKeyboardVisible {
                keyboardDismissButton
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(EditorConstants.AnimationConfig.quick, value: isKeyboardVisible)
    }
    
    private var tagsToggleButton: some View {
        Button {
            withAnimation(EditorConstants.AnimationConfig.quick) {
                showTagsInput = true
                focusedField = .tag
            }
        } label: {
            Image(systemName: "tag.fill")
                .font(.system(size: EditorConstants.iconSizeLarge, weight: .semibold))
                .foregroundStyle(!selectedTags.isEmpty ? FColors.brand : FColors.textSecondary)
                .frame(width: TransactionUI.buttonHeight, height: TransactionUI.buttonHeight)
                .background(tagsToggleBackground)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Agregar etiquetas")
        .accessibilityValue(selectedTags.isEmpty ? "Sin etiquetas" : "\(selectedTags.count) etiquetas")
        .accessibilityHint("Abre el selector de etiquetas")
    }
    
    @ViewBuilder
    private var tagsToggleBackground: some View {
        if #available(iOS 26.0, *) {
            Circle()
                .fill(.clear)
                .glassEffect(
                    !selectedTags.isEmpty
                        ? .regular.tint(FColors.brand.opacity(0.15))
                        : .regular.tint(FColors.textTertiary.opacity(0.1))
                )
        } else {
            Circle()
                .fill(
                    !selectedTags.isEmpty
                        ? FColors.brand.opacity(colorScheme == .dark ? 0.2 : 0.1)
                        : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                )
                .overlay(
                    Circle()
                        .stroke(
                            !selectedTags.isEmpty
                                ? FColors.brand.opacity(colorScheme == .dark ? 0.4 : 0.3)
                                : (colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.08)),
                            lineWidth: 1
                        )
                )
        }
    }
    
    private var createButton: some View {
        Button {
            save()
        } label: {
            HStack(spacing: 6) {
                Text(mode.isCreating ? "Crear" : "Guardar")
                    .font(.subheadline.weight(.semibold))

                Image(systemName: mode.isCreating ? "plus" : "checkmark")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(isValid ? (colorScheme == .dark ? .black : .white) : FColors.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: TransactionUI.buttonHeight)
            .background(
                Capsule().fill(
                    isValid
                        ? (colorScheme == .dark ? Color.white : Color.black)
                        : (colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.08))
                )
            )
            .shadow(
                color: isValid
                    ? Color.black.opacity(colorScheme == .dark ? 0.12 : 0.25)
                    : .clear,
                radius: 8,
                y: 4
            )
        }
        .disabled(!isValid || isSaving)
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(mode.isCreating ? "Crear transacción" : "Guardar cambios")
        .accessibilityHint(isValid ? "Guarda la transacción" : "Completa los campos requeridos primero")
    }
    
    private var keyboardDismissButton: some View {
        Button {
            dismissKeyboard()
        } label: {
            Image(systemName: "keyboard.chevron.compact.down")
                .font(.system(size: EditorConstants.iconSizeLarge, weight: .semibold))
                .foregroundStyle(FColors.textSecondary)
                .frame(width: TransactionUI.buttonHeight, height: TransactionUI.buttonHeight)
                .background(keyboardDismissBackground)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Ocultar teclado")
    }
    
    @ViewBuilder
    private var keyboardDismissBackground: some View {
        if #available(iOS 26.0, *) {
            Circle()
                .fill(.clear)
                .glassEffect(.regular.tint(FColors.textTertiary.opacity(0.1)))
        } else {
            Circle()
                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                .overlay(
                    Circle()
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.08), lineWidth: 1)
                )
        }
    }
    
    // MARK: - Actions
    
    private func addTagIfNeeded() {
        let name = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        
        if let existingTag = allTags.first(where: { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }) {
            if !selectedTags.contains(where: { $0.id == existingTag.id }) {
                selectedTags.append(existingTag)
            }
        } else {
            let randomColor = FCardColor.allCases.randomElement() ?? .blue
            let newTag = Tag(name: name, color: randomColor)
            
            modelContext.insert(newTag)
            
            do {
                try modelContext.save()
                selectedTags.append(newTag)
            } catch {
                modelContext.rollback()
                // Tag creation failed silently - the user will notice the tag wasn't added
            }
        }
        
        newTagName = ""
        Constants.Haptic.success()
        closeTagsInput()
    }
    
    private func closeTagsInput() {
        withAnimation(EditorConstants.AnimationConfig.quick) {
            showTagsInput = false
            newTagName = ""
            focusedField = nil
        }
    }
    
    private func dismissKeyboard() {
        focusedField = nil
    }
    
    private func handleTypeChange(to newType: TransactionType) {
        if newType == .transfer {
            selectedCategory = nil
        } else if selectedCategory != nil {
            let expectedType: CategoryType = newType == .income ? .income : .expense
            if selectedCategory?.type != expectedType {
                selectedCategory = nil
            }
        }
        
        if newType != .transfer {
            selectedDestinationWallet = nil
        }
    }
    
    private func handleFocusChange(to newField: EditorField?) {
        if newField == .note || newField == .amount {
            withAnimation(EditorConstants.AnimationConfig.quick) {
                showTagsInput = false
                newTagName = ""
            }
        }
    }
    
    private func handleKeyboardHide() {
        // Only close tags input if it's open and we're not in the middle of adding a tag
        if showTagsInput {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if keyboardHeight == 0 && showTagsInput {
                    withAnimation(EditorConstants.AnimationConfig.quick) {
                        showTagsInput = false
                        newTagName = ""
                    }
                }
            }
        }
    }
    
    private func formatAmountInput(_ input: String) -> String {
        var cleaned = input.filter { $0.isNumber || $0 == "." }
        
        let parts = cleaned.split(separator: ".", omittingEmptySubsequences: false)
        if parts.count > 2 {
            cleaned = String(parts[0]) + "." + String(parts[1])
        }
        
        if let dotIndex = cleaned.firstIndex(of: ".") {
            let decimals = cleaned[cleaned.index(after: dotIndex)...]
            if decimals.count > 2 {
                let endIndex = cleaned.index(dotIndex, offsetBy: 3)
                cleaned = String(cleaned[..<endIndex])
            }
        }
        
        if let number = Double(cleaned), number >= 1000 {
            let intPart = Int(number)
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.groupingSeparator = ","
            formatter.maximumFractionDigits = 0
            
            if let formatted = formatter.string(from: NSNumber(value: intPart)) {
                if let dotIndex = cleaned.firstIndex(of: ".") {
                    return formatted + String(cleaned[dotIndex...])
                }
                return formatted
            }
        }
        
        return cleaned
    }
    
    private static func formatInitialAmount(_ value: Double) -> String {
        if value == 0 { return "" }
        if value == floor(value) {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }
    
    private func initialSetup() async {
        // Set default wallet
        if selectedWallet == nil, let defaultWallet = wallets.first(where: { $0.isDefault }) ?? wallets.first {
            selectedWallet = defaultWallet
        }
        
        // Initialize filtered tags
        updateFilteredTags(searchText: "")
        
        // Focus after delay
        try? await Task.sleep(nanoseconds: EditorConstants.focusDelay)
        focusedField = .note
    }
    
    private func save() {
        // Defensive validation
        guard isValid else {
            Constants.Haptic.error()
            return
        }
        
        // Prevent double-tap
        guard !isSaving else { return }
        isSaving = true
        
        Constants.Haptic.success()
        focusedField = nil
        
        if mode.isCreating {
            viewModel.createTransaction(
                in: modelContext,
                amount: amount,
                type: selectedType,
                note: note.isEmpty ? nil : note,
                date: date,
                category: selectedType == .transfer ? nil : selectedCategory,
                wallet: selectedWallet,
                destinationWallet: selectedDestinationWallet,
                tags: selectedTags.isEmpty ? nil : selectedTags
            )
        } else if case .edit(let existing) = mode {
            existing.amount = abs(amount)
            existing.type = selectedType
            existing.note = note.isEmpty ? nil : note
            existing.date = date
            existing.wallet = selectedWallet
            existing.destinationWallet = selectedDestinationWallet
            existing.category = selectedType == .transfer ? nil : selectedCategory
            existing.tags = selectedTags.isEmpty ? nil : selectedTags
            existing.currencyCode = selectedWallet?.currencyCode
            existing.updatedAt = .now
            
            do {
                try modelContext.save()
            } catch {
                viewModel.error = .saveFailed
                isSaving = false
                return
            }
        }
        
        isSaving = false
        dismiss()
    }
}

// MARK: - Selectable Tag Chip

private struct SelectableTagChip: View {
    let tag: Tag
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(isSelected ? selectedTextColor : tag.color.color)
                    .frame(width: 8, height: 8)
                
                Text(tag.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isSelected ? selectedTextColor : FColors.textPrimary)
            }
            .padding(.horizontal, TransactionUI.pillPaddingH)
            .padding(.vertical, TransactionUI.pillPaddingV)
            .background(chipBackground)
        }
        .buttonStyle(.plain)
        .animation(EditorConstants.AnimationConfig.quick, value: isSelected)
        .accessibilityLabel(tag.displayName)
        .accessibilityValue(isSelected ? "Seleccionada" : "No seleccionada")
        .accessibilityHint("Toca para \(isSelected ? "deseleccionar" : "seleccionar")")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
    
    private var selectedTextColor: Color {
        if tag.color == .white {
            return colorScheme == .dark ? .black : .white
        }
        return .white
    }
    
    @ViewBuilder
    private var chipBackground: some View {
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(isSelected ? tag.color.color : .clear)
                .glassEffect(.regular.tint(tag.color.color.opacity(0.15)))
        } else {
            Capsule()
                .fill(isSelected ? tag.color.color : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04)))
        }
    }
}

// MARK: - Date Picker Sheet

private struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePicker(
                    "Fecha",
                    selection: $selectedDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .padding(.top, FSpacing.sm)
                .padding(.horizontal, FSpacing.md)
                .onChange(of: selectedDate) { oldValue, newValue in
                    handleDateChange(from: oldValue, to: newValue)
                }
                
                Spacer(minLength: 0)
            }
            .navigationTitle("Fecha")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Fecha")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(FColors.textPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: EditorConstants.iconSizeMedium, weight: .semibold))
                            .foregroundStyle(FColors.textSecondary)
                    }
                    .accessibilityLabel("Cerrar selector de fecha")
                }
            }
        }
        .presentationDetents([.height(500)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.clear)
        .presentationContentInteraction(.scrolls)
    }
    
    private func handleDateChange(from oldValue: Date, to newValue: Date) {
        let calendar = Calendar.current
        let oldDay = calendar.component(.day, from: oldValue)
        let newDay = calendar.component(.day, from: newValue)
        let oldMonth = calendar.component(.month, from: oldValue)
        let newMonth = calendar.component(.month, from: newValue)
        let oldYear = calendar.component(.year, from: oldValue)
        let newYear = calendar.component(.year, from: newValue)
        
        // If day changed within same month/year = day selection
        if oldDay != newDay && oldMonth == newMonth && oldYear == newYear {
            Constants.Haptic.selection()
            dismiss()
        }
    }
}

// MARK: - Category Picker Sheet

struct TransactionCategoryPickerSheet: View {
    @Binding var selectedCategory: Category?
    let type: CategoryType
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedDetent: PresentationDetent = .medium
    
    @Query private var categories: [Category]
    
    init(selectedCategory: Binding<Category?>, type: CategoryType) {
        _selectedCategory = selectedCategory
        self.type = type
        
        let typeRaw = type.rawValue
        _categories = Query(
            filter: #Predicate<Category> { category in
                !category.isArchived && category.typeRaw == typeRaw
            },
            sort: [SortDescriptor(\Category.sortOrder)]
        )
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if categories.isEmpty {
                    emptyCategoryState
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: FSpacing.sm) {
                        ForEach(categories) { category in
                            CategoryPickerCard(
                                category: category,
                                isSelected: selectedCategory?.id == category.id,
                                isCompact: selectedDetent == .medium
                            ) {
                                selectedCategory = category
                                Constants.Haptic.selection()
                                dismiss()
                            }
                        }
                    }
                    .padding(FSpacing.lg)
                }
            }
            .navigationTitle("Categoría")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Categoría")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(FColors.textPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: EditorConstants.iconSizeMedium, weight: .semibold))
                            .foregroundStyle(FColors.textSecondary)
                    }
                    .accessibilityLabel("Cerrar selector de categoría")
                }
            }
        }
        .presentationDetents([.medium, .large], selection: $selectedDetent)
        .presentationDragIndicator(.hidden)
        .presentationBackground(selectedDetent == .large ? FColors.background : Color.clear)
    }
    
    private var emptyCategoryState: some View {
        VStack(spacing: FSpacing.md) {
            Spacer()
            
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 48))
                .foregroundStyle(FColors.textTertiary)
            
            Text("Sin categorías")
                .font(.headline)
                .foregroundStyle(FColors.textPrimary)
            
            Text("Crea categorías desde el menú.")
                .font(.subheadline)
                .foregroundStyle(FColors.textSecondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(FSpacing.xxxl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sin categorías disponibles. Crea categorías desde el menú.")
    }
}

private struct CategoryPickerCard: View {
    let category: Category
    let isSelected: Bool
    var isCompact: Bool = false
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: FSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(category.color.color.opacity(colorScheme == .dark ? 0.2 : 0.12))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: category.icon.rawValue)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(category.color.color)
                }
                
                Text(category.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FColors.textPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FSpacing.md)
            .background(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? category.color.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(category.name)
        .accessibilityValue(isSelected ? "Seleccionada" : "")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        if isCompact {
            // Semi-transparente cuando está en .medium
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .dark
                    ? Color.white.opacity(0.06)
                    : Color.black.opacity(0.03)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            colorScheme == .dark
                                ? Color.white.opacity(0.08)
                                : Color.black.opacity(0.05),
                            lineWidth: 1
                        )
                )
        } else {
            // Sólido cuando está en .large
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .dark ? FColors.backgroundSecondary : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.04),
                    radius: 8,
                    y: 4
                )
        }
    }
}

// MARK: - Wallet Picker Sheet

struct TransactionWalletPickerSheet: View {
    @Binding var selectedWallet: Wallet?
    let excludeWallet: Wallet?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedDetent: PresentationDetent = .medium
    
    @Query(filter: #Predicate<Wallet> { !$0.isArchived })
    private var wallets: [Wallet]
    
    private var filteredWallets: [Wallet] {
        if let exclude = excludeWallet {
            return wallets.filter { $0.id != exclude.id }
        }
        return wallets
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FSpacing.md) {
                    ForEach(filteredWallets) { wallet in
                        WalletPickerRow(
                            wallet: wallet,
                            isSelected: selectedWallet?.id == wallet.id,
                            isCompact: selectedDetent == .medium
                        ) {
                            selectedWallet = wallet
                            Constants.Haptic.selection()
                            dismiss()
                        }
                    }
                }
                .padding(FSpacing.lg)
            }
            .navigationTitle("Billetera")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Billetera")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(FColors.textPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: EditorConstants.iconSizeMedium, weight: .semibold))
                            .foregroundStyle(FColors.textSecondary)
                    }
                    .accessibilityLabel("Cerrar selector de billetera")
                }
            }
        }
        .presentationDetents([.medium, .large], selection: $selectedDetent)
        .presentationDragIndicator(.hidden)
        .presentationBackground(selectedDetent == .large ? FColors.background : Color.clear)
    }
}

private struct WalletPickerRow: View {
    let wallet: Wallet
    let isSelected: Bool
    var isCompact: Bool = false
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: FSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(wallet.color.color.opacity(colorScheme == .dark ? 0.2 : 0.12))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: wallet.icon.rawValue)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(wallet.color.color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(wallet.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FColors.textPrimary)
                    
                    Text(wallet.formattedBalance)
                        .font(.caption)
                        .foregroundStyle(FColors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(FColors.brand)
                }
            }
            .padding(FSpacing.md)
            .background(rowBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? FColors.brand : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("\(wallet.name), balance: \(wallet.formattedBalance)")
        .accessibilityValue(isSelected ? "Seleccionada" : "")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
    
    @ViewBuilder
    private var rowBackground: some View {
        if isCompact {
            // Semi-transparente cuando está en .medium
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .dark
                    ? Color.white.opacity(0.06)
                    : Color.black.opacity(0.03)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            colorScheme == .dark
                                ? Color.white.opacity(0.08)
                                : Color.black.opacity(0.05),
                            lineWidth: 1
                        )
                )
        } else {
            // Sólido cuando está en .large
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .dark ? FColors.backgroundSecondary : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.04),
                    radius: 8,
                    y: 4
                )
        }
    }
}

// MARK: - Transaction Type Pills (Editor)

private enum TransactionTypePill: String, CaseIterable, Identifiable {
    case expense, income, transfer

    var id: String { rawValue }

    var type: TransactionType {
        switch self {
        case .expense: return .expense
        case .income: return .income
        case .transfer: return .transfer
        }
    }

    var title: String {
        switch self {
        case .expense: return "Gasto"
        case .income: return "Ingreso"
        case .transfer: return "Transferencia"
        }
    }

    var icon: String {
        switch self {
        case .expense: return "arrow.up.circle.fill"
        case .income: return "arrow.down.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .expense: return FColors.red
        case .income: return FColors.green
        case .transfer: return FColors.blue
        }
    }
}

private struct TransactionTypePillView: View {

    let pill: TransactionTypePill
    let isSelected: Bool
    let tint: Color
    let namespace: Namespace.ID
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            Constants.Haptic.light()
            onTap()
        } label: {
            label
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(pill.title)
        .accessibilityValue(isSelected ? "Seleccionado" : "")
        .accessibilityHint("Toca para seleccionar tipo \(pill.title)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var label: some View {
        HStack(spacing: 6) {
            if isSelected {
                Image(systemName: pill.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .transition(.scale.combined(with: .opacity))
            }

            Text(pill.title)
                .font(.system(size: EditorConstants.iconSizeMedium, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, isSelected ? 16 : TransactionUI.pillPaddingH)
        .padding(.vertical, TransactionUI.pillPaddingV)
        .background(background)
        .contentShape(Capsule())
        .animation(EditorConstants.AnimationConfig.quick, value: isSelected)
    }

    private var foreground: Color {
        guard isSelected else { return .secondary }
        return colorScheme == .dark ? .white : .primary
    }

    private var background: some View {
        TransactionTypePillBackground(
            tint: tint,
            isSelected: isSelected,
            namespace: namespace
        )
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Transaction Editor") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            TransactionEditorSheet(
                viewModel: TransactionsViewModel(),
                mode: .create(type: .expense)
            )
        }
        .modelContainer(for: [Transaction.self, Category.self, Wallet.self, Tag.self])
}

#Preview("Transaction Editor - Dark") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            TransactionEditorSheet(
                viewModel: TransactionsViewModel(),
                mode: .create(type: .income)
            )
        }
        .modelContainer(for: [Transaction.self, Category.self, Wallet.self, Tag.self])
        .preferredColorScheme(.dark)
}
#endif
