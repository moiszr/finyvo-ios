//
//  CategoryEditorSheet.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/11/25.
//

import SwiftUI

struct CategoryEditorSheet: View {

    // MARK: - Properties

    @Bindable var viewModel: CategoriesViewModel
    let mode: CategoryEditorMode

    @State private var editor: CategoryEditorViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @FocusState private var focusedField: Field?
    @State private var showIconColorPicker: Bool = false
    @State private var showAutoCategorizationInfo: Bool = false
    @State private var hasAppearedOnce: Bool = false
    
    @State private var isBudgetFocused: Bool = false
    @State private var isKeywordFocused: Bool = false
    
    @State private var showDiscardAlert: Bool = false

    private enum Field: Hashable {
        case name
        case budget
        case keyword
    }
    
    private var budgetFocus: Binding<Bool> {
        .init(
            get: { isBudgetFocused },
            set: { newValue in
                isBudgetFocused = newValue
                if !newValue, focusedField == .budget { focusedField = nil }
                if newValue { focusedField = .budget }
            }
        )
    }

    private var keywordFocus: Binding<Bool> {
        .init(
            get: { isKeywordFocused },
            set: { newValue in
                isKeywordFocused = newValue
                if !newValue, focusedField == .keyword { focusedField = nil }
                if newValue { focusedField = .keyword }
            }
        )
    }
    
    // Hero height
    private let heroHeight: CGFloat = 260

    // MARK: - Initialization

    init(viewModel: CategoriesViewModel, mode: CategoryEditorMode) {
        self.viewModel = viewModel
        self.mode = mode
        _editor = State(initialValue: CategoryEditorViewModel(mode: mode))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                FColors.background.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: FSpacing.lg) {
                        heroSection

                        VStack(spacing: FSpacing.lg) {
                            typePickerSection
                            budgetCard
                            autoCategorizationCard
                            saveButton
                                .padding(.top, FSpacing.md)
                        }
                        .padding(.horizontal, FSpacing.lg)
                        .padding(.bottom, FSpacing.xl)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            // ✅ 1 sola vez. Funciona tocando cards/textos/fondo,
            // pero NO mata el focus al tocar un TextField/Toggle/Button.
            .tapToDismissKeyboard {
                focusedField = nil
                isBudgetFocused = false
                isKeywordFocused = false
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
                keyboardToolbar
            }
        }
        .sheet(isPresented: $showIconColorPicker) {
            IconColorPickerSheet(
                selectedIcon: $editor.icon,
                selectedColor: $editor.color,
                onIconSelect: { editor.selectIcon($0) },
                onColorSelect: { editor.selectColor($0) }
            )
        }
        .sheet(isPresented: $showAutoCategorizationInfo) {
            AutoCategorizationInfoSheet { showAutoCategorizationInfo = false }
                .presentationDetents([.medium])                  // más espacio
                .presentationBackgroundInteraction(.automatic)           // se siente nativo
                .presentationBackground(.regularMaterial)                // mismo fondo “card”
                .presentationDragIndicator(.visible)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.regularMaterial)
        .presentationCornerRadius(32)
        .interactiveDismissDisabled(editor.hasChanges)
        .task { await handleInitialFocusIfNeeded() }
        .alert("Descartar cambios", isPresented: $showDiscardAlert) {
            Button("Seguir editando", role: .cancel) {}

            Button("Descartar", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Tienes cambios sin guardar. Si sales ahora, se perderán.")
        }
    }
    
    @MainActor
    private func handleInitialFocusIfNeeded() async {
        guard !hasAppearedOnce && !mode.isEditing else { return }
        hasAppearedOnce = true

        // Delay suave para que el sheet termine animación/presentación.
        try? await Task.sleep(nanoseconds: 300_500_000)
        focusedField = .name
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                handleCloseTapped()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
            }
            .accessibilityLabel("Cerrar")
        }
    }
    
    @ToolbarContentBuilder
    private var keyboardToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            if isBudgetFocused {
                Spacer()
                Button("Listo") {
                    isBudgetFocused = false
                    focusedField = nil
                    Task { @MainActor in hideKeyboard() }
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
            } else {
                EmptyView()
            }
        }
    }
    
    private func handleCloseTapped() {
        focusedField = nil
        isBudgetFocused = false
        isKeywordFocused = false

        if editor.hasChanges {
            showDiscardAlert = true
        } else {
            dismiss()
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack {
            // Background - extends to top edge of sheet
            editor.color.color
                .opacity(colorScheme == .dark ? 0.12 : 0.08)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 32,
                        bottomLeadingRadius: 32,
                        bottomTrailingRadius: 32,
                        topTrailingRadius: 32
                    )
                )
                .ignoresSafeArea(edges: .top)

            // Content - vertically centered
            VStack(spacing: 16) {
                
                // Icon button
                Button {
                    focusedField = nil
                    showIconColorPicker = true
                } label: {
                    ZStack(alignment: .bottomTrailing) {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .fill(editor.color.color.opacity(colorScheme == .dark ? 0.20 : 0.15))
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(colorScheme == .dark ? 0.25 : 0.60),
                                                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.15)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                            .frame(width: 72, height: 72)
                            .overlay(
                                Image(systemName: editor.icon.systemName)
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundStyle(editor.color.color)
                            )
                            .shadow(color: editor.color.color.opacity(0.25), radius: 12, y: 6)

                        Circle()
                            .fill(FColors.brand)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: "pencil")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                            .shadow(color: FColors.brand.opacity(0.4), radius: 4, y: 2)
                            .offset(x: 4, y: 4)
                    }
                }
                .buttonStyle(ScaleButtonStyle())

                // Name TextField - transparent, no cursor
                TextField("Nombre de categoría", text: $editor.name)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(editor.name.isEmpty ? FColors.textTertiary : FColors.textPrimary)
                    .focused($focusedField, equals: .name)
                    .submitLabel(.done)
                    .onSubmit { focusedField = nil }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: heroHeight)
    }

    // MARK: - Type Picker

    private var typePickerSection: some View {
        VStack(alignment: .leading, spacing: FSpacing.sm) {
            Text("Tipo de categoría")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FColors.textSecondary)

            FSegmentedPicker(
                selection: $editor.type,
                items: [
                    FSegmentItem(value: CategoryType.expense, title: "Gasto", icon: "arrow.down.circle.fill"),
                    FSegmentItem(value: CategoryType.income, title: "Ingreso", icon: "arrow.up.circle.fill")
                ],
                isDisabled: editor.isSystemCategory,
                height: 48
            )
            .opacity(editor.isSystemCategory ? 0.6 : 1)
            .onChange(of: editor.type) { _, newValue in
                editor.selectType(newValue)
            }
        }
    }

    // MARK: - Budget Card

    private var budgetCard: some View {
        NeutralCard {
            VStack(alignment: .leading, spacing: FSpacing.md) {

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Presupuesto mensual")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(FColors.textPrimary)

                        Text("Establece un límite de gasto")
                            .font(.caption)
                            .foregroundStyle(FColors.textTertiary)
                    }

                    Spacer()

                    Toggle("", isOn: $editor.budgetEnabled)
                        .labelsHidden()
                        .tint(FColors.brand)
                        .onChange(of: editor.budgetEnabled) { _, isOn in
                            if isOn {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    isBudgetFocused = true
                                }
                            } else {
                                isBudgetFocused = false
                            }
                        }
                }

                if editor.budgetEnabled {
                    FInput(
                        text: $editor.budgetAmount,
                        placeholder: "0",
                        icon: "dollarsign.circle",
                        prefix: "RD$",
                        suffix: "/ mes",
                        keyboardType: .decimalPad,
                        autocapitalization: .never,
                        autocorrection: false,
                        externalFocus: budgetFocus
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: editor.budgetEnabled)
        }
    }

    // MARK: - Auto-categorization Card

    private var autoCategorizationCard: some View {
        NeutralCard {
            VStack(alignment: .leading, spacing: FSpacing.md) {

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(FColors.brand)

                            Text("Autocategorización")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(FColors.textPrimary)
                        }

                        Text("Palabras clave para asignación automática")
                            .font(.caption)
                            .foregroundStyle(FColors.textTertiary)
                    }

                    Spacer()

                    Button {
                        focusedField = nil
                        showAutoCategorizationInfo = true
                    } label: {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(FColors.textTertiary)
                    }
                    .buttonStyle(.plain)
                }

                FInput(
                    text: $editor.newKeywordInput,
                    placeholder: "uber eats, rappi, mcdonald's",
                    icon: "magnifyingglass",
                    trailingIcon: "plus.circle.fill",
                    trailingAction: { addKeywordsFromInput() },
                    showTrailingWhen: .whenNotEmpty,
                    accessibilityTrailingLabel: "Agregar palabras clave",
                    autocapitalization: .never,
                    autocorrection: false,
                    submitLabel: .done,
                    onSubmit: { addKeywordsFromInput() },
                    externalFocus: keywordFocus
                )

                if !editor.keywords.isEmpty {
                    FlowLayout(spacing: FSpacing.sm) {
                        ForEach(editor.keywords, id: \.self) { keyword in
                            KeywordChip(keyword: keyword, color: editor.color.color) {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                    editor.removeKeyword(keyword)
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        FButton(
            mode.isEditing ? "Guardar cambios" : "Crear categoría",
            variant: .brand,
            size: .large,
            isFullWidth: true,
            icon: mode.isEditing ? "checkmark" : "plus",
            isDisabled: !editor.isValid
        ) {
            save()
        }
    }

    // MARK: - Helpers

    private func addKeywordsFromInput() {
        let input = editor.newKeywordInput

        let keywords = input
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty && !editor.keywords.contains($0) }

        guard !keywords.isEmpty else {
            editor.newKeywordInput = ""
            return
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            for keyword in keywords {
                editor.keywords.append(keyword)
            }
        }

        editor.newKeywordInput = ""
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func save() {
        focusedField = nil

        if mode.isEditing, let category = mode.category {
            if editor.applyChanges(to: category) {
                viewModel.updateCategory(category)
                dismiss()
            }
        } else {
            if let data = editor.buildNewCategoryData() {
                viewModel.createCategory(
                    name: data.name,
                    icon: data.icon,
                    color: data.color,
                    type: data.type,
                    budget: data.budget,
                    keywords: data.keywords
                )
                dismiss()
            }
        }
    }
}

// MARK: - Neutral Card

private struct NeutralCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(FSpacing.lg)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: FRadius.lg, style: .continuous))
            .overlay(border)
    }

    private var background: some View {
        ZStack {
            (colorScheme == .dark ? FColors.backgroundSecondary : Color(white: 0.97))

            LinearGradient(
                colors: [
                    colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.90),
                    colorScheme == .dark ? Color.white.opacity(0.01) : Color.white.opacity(0.30)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: FRadius.lg, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06),
                        colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}

// MARK: - Keyword Chip

private struct KeywordChip: View {
    let keyword: String
    let color: Color
    let onRemove: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 6) {
            Text(keyword)
                .font(.subheadline)
                .foregroundStyle(FColors.textPrimary)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(FColors.textTertiary)
                    .padding(4)
                    .background(Circle().fill(FColors.backgroundSecondary))
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, FSpacing.md)
        .padding(.trailing, FSpacing.xs)
        .padding(.vertical, FSpacing.sm)
        .background(
            Capsule(style: .continuous)
                .fill(color.opacity(colorScheme == .dark ? 0.16 : 0.12))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(color.opacity(0.20), lineWidth: 1)
                )
        )
    }
}

// MARK: - Scale Button Style

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

// MARK: - Icon Color Picker Sheet

struct IconColorPickerSheet: View {
    @Binding var selectedIcon: FCategoryIcon
    @Binding var selectedColor: FCardColor
    var onIconSelect: (FCategoryIcon) -> Void
    var onColorSelect: (FCardColor) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedTab: Int = 0

    private let expenseIcons: [(FCategoryIcon, String)] = [
        (.food, "Comida"), (.transport, "Transporte"), (.entertainment, "Ocio"),
        (.shopping, "Compras"), (.services, "Servicios"), (.health, "Salud"),
        (.education, "Educación"), (.home, "Hogar"), (.clothing, "Ropa")
    ]
    
    private let incomeIcons: [(FCategoryIcon, String)] = [
        (.salary, "Salario"), (.freelance, "Freelance"), (.investments, "Inversiones"),
        (.gifts, "Regalos"), (.refund, "Reembolsos")
    ]
    
    private let otherIcons: [(FCategoryIcon, String)] = [
        (.other, "Otros")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: FSpacing.lg) {
                previewSection
                    .padding(.horizontal, FSpacing.lg)
                    .padding(.top, FSpacing.md)

                Picker("", selection: $selectedTab) {
                    Text("Icono").tag(0)
                    Text("Color").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, FSpacing.lg)

                ScrollView {
                    if selectedTab == 0 {
                        iconGrid
                    } else {
                        colorGrid
                    }
                }
            }
            .background(FColors.background)
            .navigationTitle("Personalizar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(FColors.brand)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.regularMaterial)
        .presentationCornerRadius(24)
    }

    private var previewSection: some View {
        HStack(spacing: FSpacing.lg) {
            ZStack {
                Circle()
                    .fill(selectedColor.color.opacity(0.15))
                    .frame(width: 80, height: 80)

                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(Circle().fill(selectedColor.color.opacity(0.2)))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: selectedIcon.systemName)
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(selectedColor.color)
                    )
                    .shadow(color: selectedColor.color.opacity(0.3), radius: 8, y: 4)
            }

            VStack(alignment: .leading, spacing: FSpacing.xs) {
                Text("Vista previa")
                    .font(.caption)
                    .foregroundStyle(FColors.textTertiary)

                Text(iconName(selectedIcon))
                    .font(.headline)
                    .foregroundStyle(FColors.textPrimary)

                Text(selectedColor.displayName)
                    .font(.subheadline)
                    .foregroundStyle(selectedColor.color)
            }

            Spacer()
        }
        .padding(FSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: FRadius.lg)
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.03))
        )
    }

    private var iconGrid: some View {
        VStack(alignment: .leading, spacing: FSpacing.lg) {
            iconSection(title: "Gastos", icons: expenseIcons)
            iconSection(title: "Ingresos", icons: incomeIcons)
            iconSection(title: "General", icons: otherIcons)
        }
        .padding(.horizontal, FSpacing.lg)
        .padding(.bottom, FSpacing.xxl)
    }

    private func iconSection(title: String, icons: [(FCategoryIcon, String)]) -> some View {
        VStack(alignment: .leading, spacing: FSpacing.sm) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FColors.textSecondary)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: FSpacing.md), count: 5),
                spacing: FSpacing.md
            ) {
                ForEach(icons, id: \.0) { icon, _ in
                    iconButton(icon)
                }
            }
        }
    }

    private func iconButton(_ icon: FCategoryIcon) -> some View {
        let isSelected = icon == selectedIcon

        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                selectedIcon = icon
                onIconSelect(icon)
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: FRadius.md)
                    .fill(
                        isSelected
                            ? selectedColor.color.opacity(0.2)
                            : (colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.03))
                    )

                if isSelected {
                    RoundedRectangle(cornerRadius: FRadius.md)
                        .stroke(selectedColor.color, lineWidth: 2)
                }

                Image(systemName: icon.systemName)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(isSelected ? selectedColor.color : FColors.textSecondary)
            }
            .frame(height: 56)
        }
        .buttonStyle(.plain)
    }

    private var colorGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: FSpacing.md), count: 4),
            spacing: FSpacing.lg
        ) {
            ForEach(FCardColor.allCases) { color in
                colorButton(color)
            }
        }
        .padding(.horizontal, FSpacing.lg)
        .padding(.bottom, FSpacing.xxl)
    }

    private func colorButton(_ color: FCardColor) -> some View {
        let isSelected = color == selectedColor

        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                selectedColor = color
                onColorSelect(color)
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: FSpacing.xs) {
                ZStack {
                    if isSelected {
                        Circle()
                            .stroke(FColors.brand, lineWidth: 3)
                            .frame(width: 56, height: 56)
                    }

                    Circle()
                        .fill(color.color)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                    }
                }
                .shadow(color: isSelected ? color.color.opacity(0.4) : .clear, radius: 8, y: 4)

                Text(color.displayName)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? FColors.textPrimary : FColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    private func iconName(_ icon: FCategoryIcon) -> String {
        let all = expenseIcons + incomeIcons + otherIcons
        return all.first { $0.0 == icon }?.1 ?? "Icono"
    }
}

// MARK: - Auto Categorization Info Sheet

private struct AutoCategorizationInfoSheet: View {
    let onClose: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()
                .overlay(
                    (colorScheme == .dark ? Color.white : Color.black)
                        .opacity(0.08)
                )
                .padding(.top, FSpacing.xs)

            ScrollView {
                VStack(alignment: .leading, spacing: FSpacing.lg) {
                    infoItem(
                        icon: "tag.fill",
                        title: "Palabras clave",
                        description: "Agrega términos separados por comas. Ejemplo: \"uber eats, rappi, mcdonald's\"."
                    )
                    
                    infoItem(
                        icon: "arrow.right.circle.fill",
                        title: "Asignación automática",
                        description: "Cuando una transacción contenga alguna de estas palabras, Finyvo sugerirá o asignará automáticamente esta categoría."
                    )
                    
                    infoItem(
                        icon: "lightbulb.fill",
                        title: "Mejores resultados",
                        description: "Usa nombres específicos de comercios o servicios (ej. \"uber\", \"spotify\", \"claro\") para lograr una autocategorización más precisa."
                    )
                }
                .padding(.horizontal, FSpacing.lg)
                .padding(.vertical, FSpacing.lg)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)

            FButton("Entendido", variant: .brand, size: .large, isFullWidth: true) {
                onClose()
            }
            .padding(.horizontal, FSpacing.lg)
            .padding(.bottom, FSpacing.lg)
            .padding(.top, FSpacing.sm)
        }
        // Fondo del sheet: más limpio y consistente en light/dark
        .background(
            LinearGradient(
                colors: [
                    FColors.background,
                    FColors.backgroundSecondary.opacity(colorScheme == .dark ? 0.9 : 0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Header

    private var header: some View {
        HStack(spacing: FSpacing.md) {
            // 🔵 Icono redondo
            ZStack {
                Circle()
                    .fill(FColors.brand.opacity(colorScheme == .dark ? 0.20 : 0.14))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Circle()
                            .stroke(
                                Color.white.opacity(colorScheme == .dark ? 0.20 : 0.35),
                                lineWidth: 0.5
                            )
                    )

                Image(systemName: "sparkles")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(FColors.brand)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Autocategorización")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(FColors.textPrimary)
                    .tracking(-0.2)

                // 🔠 Subtítulo corto y un poco más pequeño
                Text("Haz que Finyvo aprenda de tus movimientos.")
                    .font(.footnote) // antes .subheadline
                    .foregroundStyle(FColors.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.horizontal, FSpacing.lg)
        .padding(.top, FSpacing.lg)
        .padding(.bottom, FSpacing.sm)
    }
    
    // MARK: - Info Item

    private func infoItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: FSpacing.md) {
            ZStack {
                Circle()
                    .fill(FColors.backgroundSecondary.opacity(colorScheme == .dark ? 0.9 : 1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FColors.brand)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FColors.textPrimary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(FColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Previews

#Preview("Create - Dark") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            CategoryEditorSheet(viewModel: CategoriesViewModel(), mode: .create)
        }
        .preferredColorScheme(.dark)
}

#Preview("Create - Light") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            CategoryEditorSheet(viewModel: CategoriesViewModel(), mode: .create)
        }
        .preferredColorScheme(.light)
}
