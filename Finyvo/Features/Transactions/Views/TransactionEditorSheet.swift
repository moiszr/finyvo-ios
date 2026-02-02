//
//  TransactionEditorSheet.swift
//  Finyvo
//
//  Created by Moises Núñez on 01/15/26.
//  Redesigned on 02/01/26 - Premium Liquid Glass editor
//
//  Layout:
//    - Content centers when keyboard hidden (like WalletCreationFlow)
//    - Buttons at bottom, tight spacing (4px from keyboard)
//    - Same typography for description and amount
//    - Capsule style selectors
//

import SwiftUI
import SwiftData

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
    @State private var keyboardVisible = false
    
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
    
    private var isAmountFieldFocused: Bool {
        focusedField == .amount
    }
    
    private var hasAmountValue: Bool {
        !amountText.isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                FColors.background
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissKeyboard()
                    }
                
                VStack(spacing: 0) {
                    // Main content area - centers when keyboard hidden
                    GeometryReader { geometry in
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: FSpacing.lg) {
                                // Type picker
                                typePickerSection
                                    .padding(.top, FSpacing.sm)
                                
                                // Unified glass card
                                unifiedGlassCard
                                
                                // Selected tags (full width scroll)
                                if !selectedTags.isEmpty {
                                    selectedTagsRow
                                }
                            }
                            .padding(.horizontal, FSpacing.lg)
                            .frame(minHeight: geometry.size.height - (keyboardVisible ? 0 : 60))
                            .frame(maxWidth: .infinity)
                        }
                        .scrollDismissesKeyboard(.interactively)
                    }
                    
                    // Bottom action bar - tight spacing
                    bottomActionBar
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(FColors.textSecondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showCategoryPicker) {
            TransactionCategoryPickerSheet(
                selectedCategory: $selectedCategory,
                type: selectedType == .income ? CategoryType.income : CategoryType.expense
            )
        }
        .sheet(isPresented: $showWalletPicker) {
            TransactionWalletPickerSheet(
                selectedWallet: $selectedWallet,
                excludeWallet: nil
            )
        }
        .sheet(isPresented: $showDestinationWalletPicker) {
            TransactionWalletPickerSheet(
                selectedWallet: $selectedDestinationWallet,
                excludeWallet: selectedWallet
            )
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(selectedDate: $date)
        }
        .onChange(of: selectedType) { _, newType in
            handleTypeChange(to: newType)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(Constants.Animation.quickSpring) {
                keyboardVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(Constants.Animation.quickSpring) {
                keyboardVisible = false
            }
        }
        .interactiveDismissDisabled(hasChanges)
        .presentationDragIndicator(.hidden)
        .presentationBackground(FColors.background)
        .task {
            if selectedWallet == nil, let defaultWallet = wallets.first(where: { $0.isDefault }) ?? wallets.first {
                selectedWallet = defaultWallet
            }
            
            try? await Task.sleep(for: .milliseconds(400))
            focusedField = .note
        }
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
                    withAnimation(Constants.Animation.quickSpring) {
                        selectedType = pill.type
                    }
                    Constants.Haptic.selection()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading) // ancla al leading
        .padding(.top, FSpacing.xs)
    }

    
    // MARK: - Unified Glass Card
    
    private var unifiedGlassCard: some View {
        VStack(alignment: .leading, spacing: FSpacing.md) {
            // Calendar button at top
            dateButton
                .padding(.bottom, FSpacing.xs)
            
            // Description field
            noteField
            
            // Amount field (tight spacing)
            amountField
            
            // Selectors row (capsule style)
            selectorsRow
                .padding(.top, FSpacing.sm)
        }
        .padding(.vertical, FSpacing.lg)
        .padding(.horizontal, FSpacing.lg)
        .background(glassCardBackground)
    }
    
    @ViewBuilder
    private var glassCardBackground: some View {
        if #available(iOS 26.0, *) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.clear)
                .glassEffect(.regular, in: .rect(cornerRadius: 24))
        } else {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: colorScheme == .dark
                                    ? [Color.white.opacity(0.08), Color.white.opacity(0.02)]
                                    : [Color.white.opacity(0.7), Color.white.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: colorScheme == .dark
                                    ? [Color.white.opacity(0.15), Color.white.opacity(0.05)]
                                    : [Color.white.opacity(0.8), Color.black.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08),
                    radius: 20,
                    y: 8
                )
        }
    }
    
    // MARK: - Date Button (Capsule)
    
    private var dateButton: some View {
        Button {
            Constants.Haptic.light()
            showDatePicker = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FColors.blue)
                
                Text(dateDisplayText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FColors.textPrimary)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(FColors.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
            )
        }
        .buttonStyle(EditorScaleButtonStyle())
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
    
    // MARK: - Note Field (Same size as amount)
    
    private var noteField: some View {
        TextField("Descripción", text: $note)
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundStyle(FColors.textPrimary)
            .multilineTextAlignment(.leading)
            .focused($focusedField, equals: .note)
            .submitLabel(.next)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .onSubmit {
                focusedField = .amount
            }
    }
    
    // MARK: - Amount Field (Symbol only when value exists)
    
    private var amountField: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            // Currency symbol only shows when there's a value
            if hasAmountValue {
                Text(currencySymbol)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(typeColor)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
            
            TextField("Monto", text: $amountText)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(hasAmountValue ? typeColor : FColors.textTertiary)
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .amount)
                .onChange(of: amountText) { _, newValue in
                    amountText = formatAmountInput(newValue)
                }
            
            Spacer()
        }
        .animation(Constants.Animation.quickSpring, value: hasAmountValue)
    }
    
    // MARK: - Selectors Row (Capsule Style)
    
    private var selectorsRow: some View {
        HStack(spacing: FSpacing.sm) {
            // Wallet
            CapsuleSelectorButton(
                icon: selectedWallet?.icon.rawValue ?? "wallet.pass.fill",
                iconColor: selectedWallet?.color.color ?? FColors.textTertiary,
                title: selectedWallet?.name ?? "Billetera",
                isPlaceholder: selectedWallet == nil
            ) {
                showWalletPicker = true
            }
            
            // Category / Destination
            if selectedType != .transfer {
                CapsuleSelectorButton(
                    icon: selectedCategory?.icon.rawValue ?? "square.grid.2x2.fill",
                    iconColor: selectedCategory?.color.color ?? FColors.textTertiary,
                    title: selectedCategory?.name ?? "Categoría",
                    isPlaceholder: selectedCategory == nil
                ) {
                    showCategoryPicker = true
                }
            } else {
                CapsuleSelectorButton(
                    icon: selectedDestinationWallet?.icon.rawValue ?? "wallet.pass.fill",
                    iconColor: selectedDestinationWallet?.color.color ?? FColors.textTertiary,
                    title: selectedDestinationWallet?.name ?? "Destino",
                    isPlaceholder: selectedDestinationWallet == nil
                ) {
                    showDestinationWalletPicker = true
                }
            }
        }
    }
    
    // MARK: - Selected Tags Row
    
    private var selectedTagsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FSpacing.sm) {
                ForEach(selectedTags) { tag in
                    GlassTagChip(tag: tag) {
                        withAnimation(Constants.Animation.quickSpring) {
                            selectedTags.removeAll { $0.id == tag.id }
                        }
                    }
                }
            }
        }
        .scrollClipDisabled()
    }
    
    // MARK: - Bottom Action Bar (Tight Spacing)
    
    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            if showTagsInput {
                // Tags input mode
                tagsInputSection
                    .padding(.horizontal, FSpacing.lg)
                    .padding(.top, FSpacing.sm)
                    .padding(.bottom, FSpacing.sm)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity.combined(with: .move(edge: .bottom))
                    ))
            } else {
                // Normal mode
                normalActionButtons
                    .padding(.horizontal, FSpacing.lg)
                    .padding(.top, FSpacing.sm)
                    .padding(.bottom, 4)
                    .transition(.opacity)
            }
        }
        .background(FColors.background)
        .animation(Constants.Animation.quickSpring, value: showTagsInput)
    }
    
    private var normalActionButtons: some View {
        HStack(spacing: FSpacing.md) {
            // Tags button (no liquid glass, simple circle)
            Button {
                Constants.Haptic.light()
                withAnimation(Constants.Animation.quickSpring) {
                    showTagsInput = true
                    focusedField = .tag
                }
            } label: {
                Text("#")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(!selectedTags.isEmpty ? FColors.brand : FColors.textSecondary)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(
                                !selectedTags.isEmpty
                                    ? FColors.brand.opacity(colorScheme == .dark ? 0.2 : 0.1)
                                    : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                            )
                    )
            }
            .buttonStyle(EditorScaleButtonStyle())
            
            // Create button (FlowContinueButton style)
            createButton
            
            // Keyboard dismiss button (only when amount field is focused)
            if isAmountFieldFocused {
                keyboardDismissButton
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(Constants.Animation.quickSpring, value: isAmountFieldFocused)
    }
    
    private var createButton: some View {
        Button {
            save()
        } label: {
            HStack(spacing: 8) {
                Text(mode.isCreating ? "Crear" : "Guardar")
                    .font(.body.weight(.semibold))
                
                Image(systemName: mode.isCreating ? "plus" : "checkmark")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(isValid ? (colorScheme == .dark ? .black : .white) : FColors.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Capsule()
                    .fill(isValid ? typeColor : FColors.textTertiary.opacity(0.2))
            )
            .shadow(color: isValid ? typeColor.opacity(0.25) : .clear, radius: 8, y: 4)
        }
        .disabled(!isValid)
        .buttonStyle(EditorScaleButtonStyle())
    }
    
    private var keyboardDismissButton: some View {
        Button {
            Constants.Haptic.light()
            dismissKeyboard()
        } label: {
            Image(systemName: "keyboard.chevron.compact.down")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(FColors.textPrimary)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                )
        }
        .buttonStyle(EditorScaleButtonStyle())
    }
    
    // MARK: - Tags Input Section
    
    private var tagsInputSection: some View {
        VStack(spacing: FSpacing.sm) {
            // Existing tags to select
            if !allTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: FSpacing.sm) {
                        ForEach(allTags) { tag in
                            let isSelected = selectedTags.contains { $0.id == tag.id }
                            SelectableTagChip(tag: tag, isSelected: isSelected) {
                                Constants.Haptic.selection()
                                withAnimation(Constants.Animation.quickSpring) {
                                    if isSelected {
                                        selectedTags.removeAll { $0.id == tag.id }
                                    } else {
                                        selectedTags.append(tag)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Input row
            HStack(spacing: FSpacing.md) {
                TextField("Nueva etiqueta...", text: $newTagName)
                    .font(.subheadline)
                    .focused($focusedField, equals: .tag)
                    .submitLabel(.done)
                    .onSubmit {
                        createTagOrClose()
                    }
                    .padding(.horizontal, FSpacing.md)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                    )
                
                // Create/Close button (circular, same style)
                Button {
                    createTagOrClose()
                } label: {
                    Image(systemName: newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "xmark" : "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(colorScheme == .dark ? .black : .white)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(
                                    newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? (colorScheme == .dark ? .white : .black)
                                        : FColors.brand
                                )
                        )
                        .shadow(
                            color: newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? .clear
                                : FColors.brand.opacity(0.25),
                            radius: 8,
                            y: 4
                        )
                }
                .buttonStyle(EditorScaleButtonStyle())
            }
        }
    }
    
    // MARK: - Actions
    
    private func dismissKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
    
    private func createTagOrClose() {
        let name = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if name.isEmpty {
            withAnimation(Constants.Animation.quickSpring) {
                showTagsInput = false
                focusedField = nil
            }
            return
        }
        
        if let existingTag = allTags.first(where: { $0.name.lowercased() == name.lowercased() }) {
            if !selectedTags.contains(where: { $0.id == existingTag.id }) {
                selectedTags.append(existingTag)
            }
        } else {
            let randomColor = FCardColor.allCases.randomElement() ?? .blue
            let newTag = Tag(name: name, color: randomColor)
            modelContext.insert(newTag)
            selectedTags.append(newTag)
        }
        
        newTagName = ""
        Constants.Haptic.success()
    }
    
    private func save() {
        guard isValid else { return }
        
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
            }
        }
        
        dismiss()
    }
}

// MARK: - Capsule Selector Button

private struct CapsuleSelectorButton: View {
    let icon: String
    let iconColor: Color
    let title: String
    var isPlaceholder: Bool = false
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button {
            Constants.Haptic.light()
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
                
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isPlaceholder ? FColors.textTertiary : FColors.textPrimary)
                    .lineLimit(1)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(FColors.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
            )
        }
        .buttonStyle(EditorScaleButtonStyle())
    }
}

// MARK: - Glass Tag Chip

private struct GlassTagChip: View {
    let tag: Tag
    let onRemove: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tag.color.color)
                .frame(width: 8, height: 8)
            
            Text(tag.displayName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(FColors.textPrimary)
            
            Button {
                Constants.Haptic.light()
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(FColors.textTertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(chipBackground)
    }
    
    @ViewBuilder
    private var chipBackground: some View {
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(.clear)
                .glassEffect(.regular.tint(tag.color.color.opacity(0.2)), in: .capsule)
        } else {
            Capsule()
                .fill(tag.color.color.opacity(colorScheme == .dark ? 0.15 : 0.1))
                .overlay(
                    Capsule()
                        .stroke(tag.color.color.opacity(0.2), lineWidth: 1)
                )
        }
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
                    .fill(isSelected ? .white : tag.color.color)
                    .frame(width: 8, height: 8)
                
                Text(tag.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isSelected ? .white : FColors.textPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? tag.color.color : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04)))
            )
        }
        .buttonStyle(.plain)
        .animation(Constants.Animation.quickSpring, value: isSelected)
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
                .onChange(of: selectedDate) { _, _ in
                    Constants.Haptic.selection()
                    Task {
                        try? await Task.sleep(for: .milliseconds(200))
                        dismiss()
                    }
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
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(FColors.textSecondary)
                    }
                }
            }
        }
        .presentationDetents([.height(500)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.clear)
        .presentationContentInteraction(.scrolls)
    }
}

// MARK: - Editor Scale Button Style

private struct EditorScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(Constants.Animation.quickSpring, value: configuration.isPressed)
    }
}

// MARK: - Category Picker Sheet

struct TransactionCategoryPickerSheet: View {
    @Binding var selectedCategory: Category?
    let type: CategoryType
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
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
                                isSelected: selectedCategory?.id == category.id
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
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(FColors.textSecondary)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.clear)
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
    }
}

private struct CategoryPickerCard: View {
    let category: Category
    let isSelected: Bool
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
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isSelected ? category.color.color : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(EditorScaleButtonStyle())
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        if #available(iOS 26.0, *) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.clear)
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? FColors.backgroundSecondary : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04), lineWidth: 1)
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
                VStack(spacing: FSpacing.sm) {
                    ForEach(filteredWallets) { wallet in
                        WalletPickerRow(
                            wallet: wallet,
                            isSelected: selectedWallet?.id == wallet.id
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
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(FColors.textSecondary)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.clear)
    }
}

private struct WalletPickerRow: View {
    let wallet: Wallet
    let isSelected: Bool
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
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isSelected ? FColors.brand : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(EditorScaleButtonStyle())
    }
    
    @ViewBuilder
    private var rowBackground: some View {
        if #available(iOS 26.0, *) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.clear)
                .glassEffect(.regular, in: .rect(cornerRadius: 14))
        } else {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(colorScheme == .dark ? FColors.backgroundSecondary : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04), lineWidth: 1)
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
                .font(.system(size: 14, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, isSelected ? 16 : 14)
        .padding(.vertical, 10)
        .background(background)
        .animation(Constants.Animation.quickSpring, value: isSelected)
    }

    private var foreground: Color {
        guard isSelected else { return .secondary }
        // cuando está seleccionado, se lee bien sobre el glass tintado
        return colorScheme == .dark ? .white : .primary
    }

    @ViewBuilder
    private var background: some View {
        if isSelected {
            if #available(iOS 26.0, *) {
                Capsule()
                    .fill(.clear)
                    // Tint dinámico tipo “premium glass”
                    .glassEffect(.regular.tint(tint.opacity(0.22)).interactive(), in: .capsule)
                    .matchedGeometryEffect(id: "selectedTypePill", in: namespace)
            } else {
                Capsule()
                    .fill(.ultraThinMaterial)
                    // overlay tint para que “se sienta” glass tintado también en < iOS 26
                    .overlay(
                        Capsule()
                            .fill(tint.opacity(colorScheme == .dark ? 0.18 : 0.14))
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                tint.opacity(colorScheme == .dark ? 0.25 : 0.18),
                                lineWidth: 1
                            )
                    )
                    .matchedGeometryEffect(id: "selectedTypePill", in: namespace)
            }
        }
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
