//
//  IconColorPickerSheet.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/22/25.
//  Premium unified Icon + Color picker (Expandable Card).
//

import SwiftUI

struct IconColorPickerSheet: View {

    // MARK: - Bindings

    @Binding var selectedIcon: FCategoryIcon
    @Binding var selectedColor: FCardColor

    var onIconSelect: ((FCategoryIcon) -> Void)? = nil
    var onColorSelect: ((FCardColor) -> Void)? = nil

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var searchText: String = ""
    @State private var isColorExpanded: Bool = false

    // MARK: - Layout Configurations

    private let iconColumns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: FSpacing.md), count: 6)
    private let colorColumns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: FSpacing.md), count: 5)

    // MARK: - Data Source

    private var filteredIcons: [FCategoryIcon] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let icons = FCategoryIcon.allOrdered // Usando la extensión
        
        guard !q.isEmpty else { return icons }
        
        return icons.filter { icon in
            icon.displayName.lowercased().contains(q) ||
            icon.systemName.lowercased().contains(q)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: FSpacing.lg) {

                    // Card Premium Expandible
                    previewAndColorCard
                        .padding(.top, FSpacing.sm)
                        .zIndex(1)

                    // Grid de Iconos
                    iconGridSection
                }
                .padding(.horizontal, FSpacing.lg)
                .padding(.bottom, FSpacing.xxl)
                // Anima el layout al expandir
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isColorExpanded)
            }
            .background(FColors.background)
            .navigationTitle("Personalizar")
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
                    .accessibilityHint("Cierra el selector")
                    .accessibilityIdentifier("iconColorPicker.close")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(FColors.textPrimary)
                        .accessibilityLabel("Listo")
                        .accessibilityHint("Cierra el selector")
                        .accessibilityIdentifier("iconColorPicker.done")
                }
            }
        }
        .searchable(text: $searchText, prompt: "Buscar iconos")
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.regularMaterial)
        .presentationCornerRadius(24)
        .accessibilityLabel("Buscar iconos")
        .accessibilityHint("Escribe para filtrar los iconos")
    }

    // MARK: - Premium Preview & Color Card

    private var previewAndColorCard: some View {
        VStack(spacing: 0) {
            
            // Fila Superior: Icono + Info + Botón Selector
            HStack(spacing: FSpacing.md) {
                
                // 1. Icono Preview
                iconPreviewCircle
                
                // 2. Información
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vista previa")
                        .font(.caption)
                        .foregroundStyle(FColors.textTertiary)
                    
                    // Nombre del Icono
                    Text(selectedIcon.displayName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(FColors.textPrimary)
                        .contentTransition(.numericText())
                }
                
                Spacer()
                
                // 3. Botón Selector de Color (Píldora)
                colorSelectorButton
            }
            .padding(FSpacing.lg)
            
            // Fila Inferior: Grid de Colores (Solo visible si expandido)
            if isColorExpanded {
                Divider()
                    .opacity(0.3)
                    .padding(.horizontal, FSpacing.lg)
                
                colorGridArea
                    .transition(.opacity)
            }
        }
        .background(neutralCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: FRadius.lg, style: .continuous))
        .overlay(neutralCardBorder)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Vista previa")
        .accessibilityValue("\(selectedIcon.displayName), color \(selectedColor.displayName(for: colorScheme))")
    }
    
    // MARK: - Componentes del Card

    private var iconPreviewCircle: some View {
        ZStack {
            // Glow sutil
            Circle()
                .fill(selectedColor.color.opacity(colorScheme == .dark ? 0.25 : 0.15))
                .frame(width: 64, height: 64)
                .blur(radius: 8)
            
            // Círculo sólido
            Circle()
                .fill(selectedColor.color)
                .frame(width: 52, height: 52)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: selectedColor.color.opacity(0.3), radius: 6, y: 3)
            
            // Icono
            Image(systemName: selectedIcon.systemName)
                .font(.system(size: 22, weight: .semibold))
                // ✅ ARREGLO: Pasamos 'colorScheme' para que calcule el contraste correcto
                .foregroundStyle(selectedColor.contrastContentColor(for: colorScheme))
        }.accessibilityHidden(true)
    }
    
    private var colorSelectorButton: some View {
        Button {
            hapticLight()
            isColorExpanded.toggle()
        } label: {
            HStack(spacing: 8) {
                // Dot indicador
                Circle()
                    .fill(selectedColor.color)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                
                // Texto: Nombre del color O "Cerrar"
                Text(isColorExpanded ? "Cerrar" : selectedColor.displayName(for: colorScheme))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FColors.textPrimary)
                    .lineLimit(1)
                    .layoutPriority(1)
                
                // Chevron
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(FColors.textTertiary)
                    .rotationEffect(.degrees(isColorExpanded ? 180 : 0))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
            )
            .overlay(
                Capsule()
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Selector de color")
        .accessibilityValue(selectedColor.displayName(for: colorScheme))
        .accessibilityHint(isColorExpanded ? "Doble toque para cerrar la paleta de colores" : "Doble toque para abrir la paleta de colores")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("iconColorPicker.colorSelector")
    }
    
    private var colorGridArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: colorColumns, spacing: 12) {
                ForEach(FCardColor.allCases) { color in
                    colorButton(color)
                }
            }
        }
        .padding(FSpacing.lg)
    }
    
    private func colorButton(_ color: FCardColor) -> some View {
        let isSelected = color == selectedColor
        
        return Button {
            selectColor(color)
        } label: {
            ZStack {
                Circle()
                    .fill(color.color)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(colorScheme == .dark ? 0.15 : 0.4), lineWidth: 1)
                    )
                
                if isSelected {
                    // El checkmark también necesita respetar el contraste del color de fondo
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(color.contrastContentColor(for: colorScheme))
                        .shadow(radius: 1)
                        .accessibilityHidden(true)
                }
            }
            .overlay(
                Group {
                    if isSelected {
                        Circle()
                            .stroke(FColors.textPrimary, lineWidth: 2)
                            .frame(width: 44, height: 44)
                    }
                }
            )
            .frame(width: 44, height: 44)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(color.displayName(for: colorScheme))
        .accessibilityValue(isSelected ? "Seleccionado" : "")
        .accessibilityHint("Doble toque para seleccionar este color")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("iconColorPicker.color.\(color.rawValue)")
    }

    // MARK: - Actions

    private func selectColor(_ color: FCardColor) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedColor = color
            onColorSelect?(color)
        }
        hapticLight()
    }

    // MARK: - Icon Grid Section

    private var iconGridSection: some View {
        LazyVGrid(columns: iconColumns, spacing: FSpacing.md) {
            ForEach(filteredIcons, id: \.rawValue) { icon in
                iconCell(icon)
            }
        }
    }

    private func iconCell(_ icon: FCategoryIcon) -> some View {
        let isSelected = icon == selectedIcon

        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                selectedIcon = icon
                onIconSelect?(icon)
            }
            hapticLight()
        } label: {
            ZStack {
                // Fondo consistente
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        isSelected
                        ? selectedColor.color.opacity(colorScheme == .dark ? 0.22 : 0.14)
                        : (colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.03))
                    )
                
                // Borde consistente (siempre presente si no está seleccionado para mantener tamaño visual)
                if !isSelected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.05),
                            lineWidth: 1
                        )
                }

                // Borde de selección
                if isSelected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(selectedColor.color, lineWidth: 2)
                }

                Image(systemName: icon.systemName)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(isSelected ? selectedColor.color : FColors.textSecondary)
                    .accessibilityHidden(true)
            }
            .frame(height: 50)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Icono \(icon.displayName)")
        .accessibilityValue(isSelected ? "Seleccionado" : "")
        .accessibilityHint("Doble toque para seleccionar este icono")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("iconColorPicker.icon.\(icon.rawValue)")
    }

    // MARK: - Styles & Helpers

    private var neutralCardBackground: some View {
        ZStack {
            (colorScheme == .dark ? FColors.backgroundSecondary : Color(white: 0.97))
            
            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.05 : 0.7),
                    Color.white.opacity(0.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottom
            )
        }
    }

    private var neutralCardBorder: some View {
        RoundedRectangle(cornerRadius: FRadius.lg, style: .continuous)
            .stroke(
                Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.05),
                lineWidth: 1
            )
    }

    private func hapticLight() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// Helper para animación de botones al pulsar
private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Color Picker") {
    @Previewable @State var icon: FCategoryIcon = .food
    @Previewable @State var color: FCardColor = .white // Prueba con .white

    Color.gray.opacity(0.1)
        .sheet(isPresented: .constant(true)) {
            IconColorPickerSheet(selectedIcon: $icon, selectedColor: $color)
        }
}
