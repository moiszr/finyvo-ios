//
//  TagsSheet.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/24/25.
//  Sheet modal para gestión de etiquetas.
//  Integrated with Constants.Haptic and Constants.Animation.
//
//  Diseño:
//  - Detent: .medium, .large
//  - Background: .regularMaterial (glassmorphism)
//  - Pills apilados con FlowLayout
//  - Input con círculo de color
//  - Grid de colores 2x5
//

import SwiftUI
import SwiftData

// MARK: - Tags Sheet

struct TagsSheet: View {
    
    // MARK: - Properties
    
    @Bindable var viewModel: TagsViewModel
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    
    @State private var isAddingTag: Bool = false
    @State private var editingColorForTag: Tag? = nil
    @FocusState private var isInputFocused: Bool
    
    // Color grid: 5 columnas, 2 filas
    private let colorColumns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: FSpacing.lg) {
                        
                        // Header descriptivo
                        headerSection
                        
                        // Input para nuevo tag (siempre visible cuando está agregando)
                        if isAddingTag {
                            inputSection
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Tags existentes + botón agregar
                        tagsFlowSection
                        
                    }
                    .padding(.horizontal, FSpacing.lg)
                    .padding(.top, FSpacing.md)
                    .padding(.bottom, FSpacing.xxl)
                }
            }
            .navigationTitle("Etiquetas")
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
            }
            .animation(Constants.Animation.defaultSpring, value: isAddingTag)
            .animation(Constants.Animation.defaultSpring, value: editingColorForTag?.id)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.automatic)
        .presentationBackground(.clear)
        .presentationBackgroundInteraction(.automatic)
        .onAppear {
            viewModel.configure(with: modelContext)
            viewModel.loadTags()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Organiza tus gastos")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(FColors.textSecondary)
            
            Text("Agrega etiquetas para clasificar mejor tus transacciones. Máximo \(viewModel.maxTagsPerTransaction) por transacción.")
                .font(.caption)
                .foregroundStyle(FColors.textTertiary)
        }
    }
    
    // MARK: - Input Section (Card con Input + Color Picker)
    
    private var inputSection: some View {
        NeutralCard {
            VStack(alignment: .leading, spacing: FSpacing.md) {
                
                // Input row con círculo de color
                HStack(spacing: FSpacing.sm) {
                    // Círculo de color seleccionado
                    Circle()
                        .fill(viewModel.selectedColor.color)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: viewModel.selectedColor.color.opacity(0.3), radius: 4, y: 2)
                        .accessibilityLabel("Color seleccionado: \(viewModel.selectedColor.displayName(for: colorScheme))")
                    
                    // Input
                    TextField("nombre_etiqueta", text: $viewModel.newTagInput)
                        .font(.body)
                        .foregroundStyle(FColors.textPrimary)
                        .focused($isInputFocused)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit {
                            createTagIfValid()
                        }
                    
                    Spacer()
                    
                    // Botón crear (solo si válido)
                    if viewModel.isInputValid && !viewModel.inputAlreadyExists {
                        Button {
                            createTagIfValid()
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(FColors.brand)
                        }
                        .buttonStyle(TagsScaleButtonStyle())
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                // Validation hint
                HStack {
                    if viewModel.inputAlreadyExists {
                        Text("Esta etiqueta ya existe")
                            .font(.caption)
                            .foregroundStyle(FColors.danger)
                            .transition(.opacity)
                    } else if !viewModel.newTagInput.isEmpty && !viewModel.isInputValid {
                        Text(Tag.validationHint)
                            .font(.caption)
                            .foregroundStyle(FColors.textTertiary)
                            .transition(.opacity)
                    }
                    
                    Spacer()
                    
                    // Character counter
                    if !viewModel.newTagInput.isEmpty {
                        Text("\(viewModel.newTagInput.count)/\(AppConfig.Limits.maxTagNameLength)")
                            .font(.caption2)
                            .foregroundStyle(
                                viewModel.newTagInput.count > AppConfig.Limits.maxTagNameLength
                                ? FColors.danger
                                : FColors.textTertiary
                            )
                    }
                }
                
                // Divider
                Divider()
                    .opacity(0.5)
                
                // Color picker label
                Text("Color")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(FColors.textTertiary)
                
                // Color grid 2x5
                LazyVGrid(columns: colorColumns, spacing: 12) {
                    ForEach(FCardColor.allCases) { color in
                        colorButton(color, isSelected: viewModel.selectedColor == color) {
                            viewModel.selectedColor = color
                            Task { @MainActor in Constants.Haptic.light() }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Tags Flow Section
    
    private var tagsFlowSection: some View {
        VStack(alignment: .leading, spacing: FSpacing.sm) {
            
            // Label
            if !viewModel.tags.isEmpty {
                HStack {
                    Text("Tus etiquetas")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(FColors.textTertiary)
                    
                    Spacer()
                    
                    Text("\(viewModel.tags.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(FColors.textSecondary)
                }
                .padding(.top, FSpacing.sm)
            }
            
            FlowLayout(spacing: FSpacing.sm) {
                // Tags existentes
                ForEach(viewModel.tags) { tag in
                    TagPill(
                        tag: tag,
                        isEditingColor: editingColorForTag?.id == tag.id,
                        onDelete: {
                            withAnimation(Constants.Animation.quickSpring) {
                                viewModel.deleteTag(tag)
                            }
                        },
                        onColorTap: {
                            withAnimation(Constants.Animation.defaultSpring) {
                                if editingColorForTag?.id == tag.id {
                                    editingColorForTag = nil
                                } else {
                                    editingColorForTag = tag
                                    isAddingTag = false
                                }
                            }
                        }
                    )
                }
                
                // Botón agregar (siempre visible cuando no está agregando)
                if !isAddingTag {
                    AddTagPill {
                        withAnimation(Constants.Animation.defaultSpring) {
                            isAddingTag = true
                            editingColorForTag = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isInputFocused = true
                            }
                        }
                    }
                }
            }
            
            // Color picker para editar tag existente
            if let tag = editingColorForTag {
                editColorSection(for: tag)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    // MARK: - Edit Color Section (para tags existentes)
    
    private func editColorSection(for tag: Tag) -> some View {
        NeutralCard {
            VStack(alignment: .leading, spacing: FSpacing.sm) {
                HStack {
                    Text("Cambiar color de")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(FColors.textTertiary)
                    
                    Text(tag.displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tag.color.color)
                    
                    Spacer()
                    
                    Button {
                        withAnimation(Constants.Animation.quickSpring) {
                            editingColorForTag = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.body)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(FColors.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
                
                LazyVGrid(columns: colorColumns, spacing: 12) {
                    ForEach(FCardColor.allCases) { color in
                        colorButton(color, isSelected: tag.color == color) {
                            viewModel.updateColor(tag, to: color)
                        }
                    }
                }
            }
        }
        .padding(.top, FSpacing.sm)
    }
    
    // MARK: - Color Button
    
    private func colorButton(_ color: FCardColor, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color.color)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(colorScheme == .dark ? 0.15 : 0.4), lineWidth: 1)
                    )
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(color.contrastContentColor(for: colorScheme))
                }
            }
            .overlay(
                Group {
                    if isSelected {
                        Circle()
                            .stroke(FColors.textPrimary, lineWidth: 2)
                            .frame(width: 40, height: 40)
                    }
                }
            )
            .frame(width: 40, height: 40)
        }
        .buttonStyle(TagsScaleButtonStyle())
        .accessibilityLabel(color.displayName(for: colorScheme))
        .accessibilityValue(isSelected ? "Seleccionado" : "")
    }
    
    // MARK: - Actions
    
    private func createTagIfValid() {
        guard viewModel.isInputValid, !viewModel.inputAlreadyExists else { return }
        
        viewModel.createTagFromInput()
        // Mantener el modo agregar abierto para agregar más tags
        viewModel.newTagInput = ""
        // No cerrar isAddingTag para permitir agregar múltiples
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

// MARK: - Tag Pill

private struct TagPill: View {
    let tag: Tag
    var isEditingColor: Bool = false
    let onDelete: () -> Void
    let onColorTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 6) {
            // Color dot (tappable para cambiar color)
            Button(action: onColorTap) {
                Circle()
                    .fill(tag.color.color)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                    )
                    .overlay(
                        Group {
                            if isEditingColor {
                                Circle()
                                    .stroke(FColors.brand, lineWidth: 2)
                                    .frame(width: 16, height: 16)
                            }
                        }
                    )
            }
            .buttonStyle(.plain)
            
            // Nombre
            Text(tag.displayName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(FColors.textPrimary)
            
            // Botón eliminar
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(FColors.textTertiary)
                    .padding(4)
                    .background(
                        Circle()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, FSpacing.md)
        .padding(.trailing, FSpacing.xs)
        .padding(.vertical, FSpacing.sm)
        .background(pillBackground)
        .clipShape(Capsule(style: .continuous))
        .overlay(pillBorder)
    }
    
    private var pillBackground: some View {
        tag.color.color.opacity(colorScheme == .dark ? 0.16 : 0.12)
    }
    
    private var pillBorder: some View {
        Capsule(style: .continuous)
            .stroke(tag.color.color.opacity(0.25), lineWidth: 1)
    }
}

// MARK: - Add Tag Pill

private struct AddTagPill: View {
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(FColors.textSecondary)
                
                Text("Agregar")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FColors.textSecondary)
            }
            .padding(.horizontal, FSpacing.md)
            .padding(.vertical, FSpacing.sm)
            .background(
                Capsule(style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(
                        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                    )
            )
        }
        .buttonStyle(TagsScaleButtonStyle())
    }
}

// MARK: - Scale Button Style

private struct TagsScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(Constants.Animation.quickSpring, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Tags Sheet - Light") {
    Color.gray.opacity(0.2)
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            TagsSheet(viewModel: TagsViewModel())
        }
        .modelContainer(for: Tag.self, inMemory: true)
}

#Preview("Tags Sheet - Dark") {
    Color.black
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            TagsSheet(viewModel: TagsViewModel())
        }
        .modelContainer(for: Tag.self, inMemory: true)
        .preferredColorScheme(.dark)
}
