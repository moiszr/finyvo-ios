//
//  ColorPickerSheet.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/11/25.
//  Refactored for FCardColor palette with premium design.
//

import SwiftUI

// MARK: - Color Picker Sheet

/// Selector de colores premium con la paleta FCardColor.
///
/// ## Uso
/// ```swift
/// .sheet(isPresented: $showColorPicker) {
///     ColorPickerSheet(selectedColor: $color)
/// }
/// ```
struct ColorPickerSheet: View {
    
    // MARK: - Properties
    
    @Binding var selectedColor: FCardColor
    var onSelect: ((FCardColor) -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: FSpacing.xl) {
                // Preview
                previewSection
                    .padding(.top, FSpacing.md)
                
                // Color grid
                colorGrid
                
                Spacer()
            }
            .padding(.horizontal, FSpacing.lg)
            .background(FColors.background)
            .navigationTitle("Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") {
                        onSelect?(selectedColor)
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(FColors.brand)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(.regularMaterial)
        .presentationCornerRadius(24)
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        HStack(spacing: FSpacing.lg) {
            // Color circle with glow
            ZStack {
                // Glow effect
                Circle()
                    .fill(selectedColor.color.opacity(0.3))
                    .frame(width: 88, height: 88)
                    .blur(radius: 12)
                
                // Main circle
                Circle()
                    .fill(selectedColor.color)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: selectedColor.color.opacity(0.4), radius: 12, y: 6)
            }
            
            // Color info
            VStack(alignment: .leading, spacing: FSpacing.xs) {
                Text("Seleccionado")
                    .font(.caption)
                    .foregroundStyle(FColors.textTertiary)
                
                Text(selectedColor.displayName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(FColors.textPrimary)
            }
            
            Spacer()
        }
        .padding(FSpacing.lg)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: FRadius.lg))
    }
    
    // MARK: - Color Grid
    
    private var colorGrid: some View {
        VStack(alignment: .leading, spacing: FSpacing.md) {
            Text("Paleta Finyvo")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FColors.textSecondary)
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: FSpacing.md), count: 4),
                spacing: FSpacing.md
            ) {
                ForEach(FCardColor.allCases) { color in
                    colorButton(color)
                }
            }
        }
    }
    
    // MARK: - Color Button
    
    private func colorButton(_ color: FCardColor) -> some View {
        let isSelected = color == selectedColor
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedColor = color
            }
            hapticLight()
        } label: {
            VStack(spacing: FSpacing.xs) {
                ZStack {
                    // Selection ring
                    if isSelected {
                        Circle()
                            .stroke(FColors.brand, lineWidth: 3)
                            .frame(width: 56, height: 56)
                    }
                    
                    // Color circle
                    Circle()
                        .fill(color.color)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(
                                    Color.white.opacity(colorScheme == .dark ? 0.2 : 0.5),
                                    lineWidth: 1
                                )
                        )
                    
                    // Checkmark
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                    }
                }
                .shadow(
                    color: isSelected ? color.color.opacity(0.4) : .clear,
                    radius: 8,
                    y: 4
                )
                
                Text(color.displayName)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? FColors.textPrimary : FColors.textSecondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(color.displayName)
    }
    
    // MARK: - Helpers
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: FRadius.lg)
            .fill(
                colorScheme == .dark
                    ? Color.white.opacity(0.06)
                    : Color.black.opacity(0.03)
            )
    }
    
    private func hapticLight() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var color: FCardColor = .blue
    
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ColorPickerSheet(selectedColor: $color)
        }
}

#Preview("Dark Mode") {
    @Previewable @State var color: FCardColor = .orange
    
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ColorPickerSheet(selectedColor: $color)
        }
        .preferredColorScheme(.dark)
}
