//
//  CategoryDetailSheet.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/11/25.
//  Refactored for FCategoryIcon and FCardColor with premium design.
//

import SwiftUI

// MARK: - Category Detail Sheet

/// Sheet de detalle de categoría con estadísticas y acciones.
///
/// ## Características
/// - Hero section con icono SF Symbol
/// - Estadísticas del mes actual
/// - Progreso de presupuesto
/// - Acciones rápidas
struct CategoryDetailSheet: View {
    
    // MARK: - Properties
    
    let category: Category
    @Bindable var viewModel: CategoriesViewModel
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FSpacing.xl) {
                    // Hero section
                    heroSection
                    
                    // Stats section
                    statsSection
                    
                    // Budget section
                    if category.hasBudget {
                        budgetSection
                    }
                    
                    // Keywords section
                    if !category.keywords.isEmpty {
                        keywordsSection
                    }
                    
                    // Subcategories section
                    if category.hasChildren {
                        subcategoriesSection
                    }
                    
                    // Actions section
                    actionsSection
                }
                .padding(.horizontal, FSpacing.lg)
                .padding(.vertical, FSpacing.lg)
            }
            .background(FColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.regularMaterial)
        .presentationCornerRadius(24)
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FColors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(FColors.backgroundSecondary)
                    .clipShape(Circle())
            }
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    viewModel.presentEdit(category)
                }
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FColors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(FColors.backgroundSecondary)
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: FSpacing.lg) {
            // Icon with glow
            ZStack {
                // Glow
                Circle()
                    .fill(category.color.color.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                
                // Icon badge
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .fill(category.color.color.opacity(0.15))
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(colorScheme == .dark ? 0.3 : 0.8),
                                            Color.white.opacity(colorScheme == .dark ? 0.05 : 0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                    
                    Image(systemName: category.systemImageName)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(category.color.color)
                }
                .frame(width: 100, height: 100)
                .shadow(color: category.color.color.opacity(0.4), radius: 20, y: 10)
            }
            
            // Name & badges
            HStack(spacing: FSpacing.sm) {
                Text(category.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(FColors.textPrimary)
                
                if category.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.subheadline)
                        .foregroundStyle(.yellow)
                }
                
                if category.isSystem {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(FColors.textTertiary)
                }
                
                if category.isArchived {
                    Image(systemName: "archivebox.fill")
                        .font(.caption)
                        .foregroundStyle(FColors.textTertiary)
                }
            }
            
            // Type badge
            HStack(spacing: FSpacing.xs) {
                Image(systemName: category.type.systemImageName)
                    .font(.caption)
                Text(category.type.title)
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(category.type.defaultColor.color)
            .padding(.horizontal, FSpacing.md)
            .padding(.vertical, FSpacing.xs)
            .background(category.type.defaultColor.color.opacity(0.12))
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FSpacing.xl)
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: FSpacing.md) {
            sectionHeader(icon: "chart.bar", title: "Este mes")
            
            HStack(spacing: FSpacing.md) {
                // Total spent/received
                StatCard(
                    title: category.type == .expense ? "Gastado" : "Recibido",
                    value: "RD$0", // TODO: conectar con transacciones
                    subtitle: "0 transacciones",
                    accentColor: category.color.color
                )
                
                // Average
                StatCard(
                    title: "Promedio",
                    value: "RD$0",
                    subtitle: "últimos 3 meses",
                    accentColor: nil
                )
            }
        }
        .padding(FSpacing.lg)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: FRadius.lg))
    }
    
    // MARK: - Budget Section
    
    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: FSpacing.md) {
            sectionHeader(icon: "target", title: "Presupuesto")
            
            VStack(spacing: FSpacing.sm) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        Capsule()
                            .fill(FColors.backgroundSecondary)
                        
                        // Progress
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [category.color.color, category.color.color.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 0) // TODO: calcular progreso real
                            .shadow(color: category.color.color.opacity(0.4), radius: 4, y: 2)
                    }
                }
                .frame(height: 8)
                
                // Labels
                HStack {
                    Text("RD$0 de RD$\(Int(category.budget ?? 0))")
                        .font(.subheadline)
                        .foregroundStyle(FColors.textPrimary)
                    
                    Spacer()
                    
                    Text("0%")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FColors.green)
                }
            }
        }
        .padding(FSpacing.lg)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: FRadius.lg))
    }
    
    // MARK: - Keywords Section
    
    private var keywordsSection: some View {
        VStack(alignment: .leading, spacing: FSpacing.md) {
            sectionHeader(icon: "sparkles", title: "Palabras clave")
            
            FlowLayout(spacing: FSpacing.sm) {
                ForEach(category.keywords, id: \.self) { keyword in
                    Text(keyword)
                        .font(.caption)
                        .foregroundStyle(FColors.textSecondary)
                        .padding(.horizontal, FSpacing.sm)
                        .padding(.vertical, 6)
                        .background(FColors.backgroundSecondary)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(FSpacing.lg)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: FRadius.lg))
    }
    
    // MARK: - Subcategories Section
    
    private var subcategoriesSection: some View {
        VStack(alignment: .leading, spacing: FSpacing.md) {
            sectionHeader(icon: "folder", title: "Subcategorías")
            
            VStack(spacing: 0) {
                ForEach(Array(category.activeChildren.enumerated()), id: \.element.id) { index, child in
                    if index > 0 {
                        Divider()
                            .padding(.leading, 48)
                    }
                    
                    HStack(spacing: FSpacing.md) {
                        // Icon
                        Image(systemName: child.systemImageName)
                            .font(.body)
                            .foregroundStyle(child.color.color)
                            .frame(width: 32, height: 32)
                            .background(child.color.color.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Text(child.name)
                            .font(.body)
                            .foregroundStyle(FColors.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(FColors.textTertiary)
                    }
                    .padding(.vertical, FSpacing.sm)
                }
            }
        }
        .padding(FSpacing.lg)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: FRadius.lg))
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 0) {
            // Add transaction
            ActionRow(
                icon: "plus.circle",
                title: "Agregar transacción",
                color: FColors.brand
            ) {
                // TODO: Navigate to add transaction
            }
            
            Divider().padding(.leading, 48)
            
            // Toggle favorite
            ActionRow(
                icon: category.isFavorite ? "star.slash" : "star",
                title: category.isFavorite ? "Quitar de favoritos" : "Agregar a favoritos",
                color: .yellow
            ) {
                viewModel.toggleFavorite(category)
            }
            
            Divider().padding(.leading, 48)
            
            // Duplicate
            ActionRow(
                icon: "doc.on.doc",
                title: "Duplicar categoría",
                color: FColors.textSecondary
            ) {
                viewModel.duplicateCategory(category)
                dismiss()
            }
            
            // Restore (if archived)
            if category.isArchived {
                Divider().padding(.leading, 48)
                
                ActionRow(
                    icon: "arrow.uturn.backward",
                    title: "Restaurar categoría",
                    color: FColors.green
                ) {
                    viewModel.restoreCategory(category)
                    dismiss()
                }
            }
            
            // Archive or Delete (if not system)
            if !category.isSystem {
                Divider().padding(.leading, 48)
                
                if category.isArchived {
                    ActionRow(
                        icon: "trash",
                        title: "Eliminar permanentemente",
                        color: FColors.red,
                        isDestructive: true
                    ) {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            viewModel.presentDeleteAlert(category)
                        }
                    }
                } else {
                    ActionRow(
                        icon: "archivebox",
                        title: "Archivar categoría",
                        color: FColors.red,
                        isDestructive: true
                    ) {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            viewModel.presentArchiveAlert(category)
                        }
                    }
                }
            }
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: FRadius.lg))
    }
    
    // MARK: - Helpers
    
    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: FSpacing.sm) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(FColors.textTertiary)
            
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FColors.textSecondary)
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: FRadius.lg)
            .fill(
                colorScheme == .dark
                    ? Color.white.opacity(0.06)
                    : Color.black.opacity(0.03)
            )
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let accentColor: Color?
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: FSpacing.xs) {
            Text(title)
                .font(.caption)
                .foregroundStyle(FColors.textTertiary)
            
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(FColors.textPrimary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(FColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FRadius.md)
                .fill(
                    accentColor != nil
                        ? accentColor!.opacity(colorScheme == .dark ? 0.15 : 0.1)
                        : (colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.02))
                )
        )
    }
}

// MARK: - Action Row

private struct ActionRow: View {
    let icon: String
    let title: String
    let color: Color
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: FSpacing.md) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundStyle(isDestructive ? color : FColors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(FColors.textTertiary)
            }
            .padding(.horizontal, FSpacing.lg)
            .padding(.vertical, FSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    let category = Category(
        name: "Comida",
        icon: .food,
        color: .orange,
        type: .expense,
        budget: 5000,
        keywords: ["uber eats", "rappi", "restaurante"]
    )
    
    return Color.clear
        .sheet(isPresented: .constant(true)) {
            CategoryDetailSheet(
                category: category,
                viewModel: CategoriesViewModel()
            )
        }
}

#Preview("Dark Mode") {
    let category = Category(
        name: "Transporte",
        icon: .transport,
        color: .blue,
        type: .expense,
        budget: 3000,
        keywords: ["uber", "didi", "gasolina"]
    )
    
    return Color.clear
        .sheet(isPresented: .constant(true)) {
            CategoryDetailSheet(
                category: category,
                viewModel: CategoriesViewModel()
            )
        }
        .preferredColorScheme(.dark)
}
