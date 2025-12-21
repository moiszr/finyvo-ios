//
//  IconPickerSheet.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/15/25.
//  Premium SF Symbol picker for category icons.
//

import SwiftUI

// MARK: - Icon Picker Sheet

/// Selector de iconos SF Symbols para categorías.
///
/// ## Características
/// - Grid de iconos organizados por categoría
/// - Preview del icono seleccionado con color
/// - Animaciones premium
///
/// ## Uso
/// ```swift
/// .sheet(isPresented: $showIconPicker) {
///     IconPickerSheet(selectedIcon: $icon, accentColor: color)
/// }
/// ```
struct IconPickerSheet: View {
    
    // MARK: - Properties
    
    @Binding var selectedIcon: FCategoryIcon
    var accentColor: FCardColor = .blue
    var onSelect: ((FCategoryIcon) -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Icon Groups
    
    private let expenseIcons: [(FCategoryIcon, String)] = [
        (.food, "Comida"),
        (.transport, "Transporte"),
        (.entertainment, "Entretenimiento"),
        (.shopping, "Compras"),
        (.services, "Servicios"),
        (.health, "Salud"),
        (.education, "Educación"),
        (.home, "Hogar"),
        (.clothing, "Ropa")
    ]
    
    private let incomeIcons: [(FCategoryIcon, String)] = [
        (.salary, "Salario"),
        (.freelance, "Freelance"),
        (.investments, "Inversiones"),
        (.gifts, "Regalos"),
        (.refund, "Reembolsos")
    ]
    
    private let otherIcons: [(FCategoryIcon, String)] = [
        (.other, "Otros")
    ]
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FSpacing.xl) {
                    // Preview
                    previewSection
                        .padding(.top, FSpacing.md)
                    
                    // Expense icons
                    iconSection(title: "Gastos", icons: expenseIcons)
                    
                    // Income icons
                    iconSection(title: "Ingresos", icons: incomeIcons)
                    
                    // Other
                    iconSection(title: "General", icons: otherIcons)
                }
                .padding(.horizontal, FSpacing.lg)
                .padding(.bottom, FSpacing.xxl)
            }
            .background(FColors.background)
            .navigationTitle("Icono")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") {
                        onSelect?(selectedIcon)
                        dismiss()
                    }
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
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        HStack(spacing: FSpacing.lg) {
            // Icon with glow
            ZStack {
                // Glow
                Circle()
                    .fill(accentColor.color.opacity(0.25))
                    .frame(width: 88, height: 88)
                    .blur(radius: 12)
                
                // Badge
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .fill(accentColor.color.opacity(0.2))
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.5),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                    
                    Image(systemName: selectedIcon.systemName)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(accentColor.color)
                }
                .frame(width: 72, height: 72)
                .shadow(color: accentColor.color.opacity(0.4), radius: 12, y: 6)
            }
            
            // Info
            VStack(alignment: .leading, spacing: FSpacing.xs) {
                Text("Seleccionado")
                    .font(.caption)
                    .foregroundStyle(FColors.textTertiary)
                
                Text(iconDisplayName(selectedIcon))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(FColors.textPrimary)
            }
            
            Spacer()
        }
        .padding(FSpacing.lg)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: FRadius.lg))
    }
    
    // MARK: - Icon Section
    
    private func iconSection(title: String, icons: [(FCategoryIcon, String)]) -> some View {
        VStack(alignment: .leading, spacing: FSpacing.md) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FColors.textSecondary)
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: FSpacing.md), count: 5),
                spacing: FSpacing.md
            ) {
                ForEach(icons, id: \.0) { icon, name in
                    iconButton(icon, name: name)
                }
            }
        }
    }
    
    // MARK: - Icon Button
    
    private func iconButton(_ icon: FCategoryIcon, name: String) -> some View {
        let isSelected = icon == selectedIcon
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedIcon = icon
            }
            hapticLight()
        } label: {
            VStack(spacing: FSpacing.xs) {
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: FRadius.md)
                        .fill(
                            isSelected
                                ? accentColor.color.opacity(colorScheme == .dark ? 0.25 : 0.15)
                                : (colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.03))
                        )
                        .frame(width: 56, height: 56)
                    
                    // Selection border
                    if isSelected {
                        RoundedRectangle(cornerRadius: FRadius.md)
                            .stroke(accentColor.color, lineWidth: 2)
                            .frame(width: 56, height: 56)
                    }
                    
                    // Icon
                    Image(systemName: icon.systemName)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(
                            isSelected ? accentColor.color : FColors.textSecondary
                        )
                }
                .shadow(
                    color: isSelected ? accentColor.color.opacity(0.3) : .clear,
                    radius: 6,
                    y: 3
                )
                
                Text(name)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(isSelected ? FColors.textPrimary : FColors.textTertiary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
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
    
    private func iconDisplayName(_ icon: FCategoryIcon) -> String {
        let allIcons = expenseIcons + incomeIcons + otherIcons
        return allIcons.first { $0.0 == icon }?.1 ?? "Icono"
    }
    
    private func hapticLight() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var icon: FCategoryIcon = .food
    
    Color.clear
        .sheet(isPresented: .constant(true)) {
            IconPickerSheet(selectedIcon: $icon, accentColor: .orange)
        }
}

#Preview("Dark Mode") {
    @Previewable @State var icon: FCategoryIcon = .salary
    
    Color.clear
        .sheet(isPresented: .constant(true)) {
            IconPickerSheet(selectedIcon: $icon, accentColor: .green)
        }
        .preferredColorScheme(.dark)
}
