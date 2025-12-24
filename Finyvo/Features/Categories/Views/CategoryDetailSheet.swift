//
//  CategoryDetailSheet.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/11/25.
//  Premium "Silent Canvas" detail view with Interactive Chart.
//  Integrated with CurrencyConfig and Constants.
//

import SwiftUI

struct CategoryDetailSheet: View {
    
    // MARK: - Properties
    
    let category: Category
    @Bindable var viewModel: CategoriesViewModel
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - State
    
    @State private var selectedMonth: Date = Date()
    
    // MARK: - Layout Constants
    
    private let heroHeight: CGFloat = 260
    
    // MARK: - Mock Data (TODO: Replace with real data)
    
    private var thisMonthSpent: Double { 12500 }
    private var thisMonthTransactions: Int { 23 }
    private var averageSpent: Double { 10200 }
    private var budgetProgress: Double { 0.45 }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                FColors.background.ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: FSpacing.lg) {
                        heroSection
                        
                        VStack(spacing: FSpacing.lg) {
                            statsSection
                            
                            // Interactive Chart
                            chartSection
                            
                            if category.hasBudget {
                                budgetSection
                            }
                            
                            if category.hasChildren {
                                subcategoriesSection
                            }
                            
                            if !category.keywords.isEmpty {
                                keywordsSection
                            }
                            
                            actionsSection
                                .padding(.top, FSpacing.sm)
                        }
                        .padding(.horizontal, FSpacing.lg)
                        .padding(.bottom, FSpacing.xl)
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.regularMaterial)
        .presentationCornerRadius(32)
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
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(FColors.textPrimary)
            }
            .accessibilityLabel("Cerrar")
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    viewModel.presentEdit(category)
                }
            } label: {
                Text("Editar")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(FColors.textPrimary)
            }
            .accessibilityLabel("Editar categoría")
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        ZStack {
            category.color.color
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
            
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(category.color.color.opacity(colorScheme == .dark ? 0.25 : 0.15))
                        .frame(width: 88, height: 88)
                        .blur(radius: 12)
                    
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .fill(category.color.color.opacity(colorScheme == .dark ? 0.20 : 0.15))
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
                            Image(systemName: category.systemImageName)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(category.color.color)
                        )
                        .shadow(color: category.color.color.opacity(0.25), radius: 12, y: 6)
                }
                
                VStack(spacing: 8) {
                    Text(category.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(FColors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 6) {
                        Image(systemName: category.type.systemImageName)
                            .font(.caption.weight(.semibold))
                        
                        Text(category.type.title)
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(FColors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: heroHeight)
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        HStack(spacing: FSpacing.md) {
            StatCard(
                title: "Este mes",
                value: thisMonthSpent.asCompactCurrency(),
                subtitle: "\(thisMonthTransactions) transacciones",
                icon: "chart.bar.fill",
                accentColor: category.color.color
            )
            
            StatCard(
                title: "Promedio",
                value: averageSpent.asCompactCurrency(),
                subtitle: "últimos 3 meses",
                icon: "arrow.triangle.2.circlepath",
                accentColor: FColors.textSecondary
            )
        }
    }
    
    // MARK: - Chart Section
    
    private var chartSection: some View {
        DetailCard {
            CategoryDetailChart(
                accentColor: category.color.color,
                selectedMonth: $selectedMonth
            )
        }
    }
    
    // MARK: - Budget Section
    
    private var budgetSection: some View {
        DetailCard {
            VStack(alignment: .leading, spacing: FSpacing.md) {
                HStack {
                    Label {
                        Text("Presupuesto")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(FColors.textPrimary)
                    } icon: {
                        Image(systemName: "target")
                            .foregroundStyle(category.color.color)
                    }
                    
                    Spacer()
                    
                    Text("\(category.formattedBudget()) / mes")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(FColors.textSecondary)
                }
                
                VStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [category.color.color, category.color.color.opacity(0.85)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * budgetProgress)
                                .shadow(color: category.color.color.opacity(0.3), radius: 2, y: 1)
                        }
                    }
                    .frame(height: 8)
                    
                    HStack {
                        Text("\(Int(budgetProgress * 100))% usado")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(category.color.color)
                        
                        Spacer()
                        
                        let remaining = (category.budget ?? 0) * (1 - budgetProgress)
                        Text("Quedan \(remaining.asCompactCurrency())")
                            .font(.caption)
                            .foregroundStyle(FColors.textTertiary)
                    }
                }
            }
        }
    }
    
    // MARK: - Subcategories Section
    
    private var subcategoriesSection: some View {
        DetailCard {
            VStack(alignment: .leading, spacing: FSpacing.md) {
                Label {
                    Text("Subcategorías")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FColors.textPrimary)
                } icon: {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(FColors.textSecondary)
                }
                
                Divider()
                    .opacity(0.5)
                
                VStack(spacing: 0) {
                    ForEach(Array(category.activeChildren.enumerated()), id: \.element.id) { index, child in
                        if index > 0 {
                            Divider()
                                .padding(.leading, 48)
                                .opacity(0.3)
                        }
                        
                        SubcategoryRow(child: child, colorScheme: colorScheme)
                    }
                }
            }
        }
    }
    
    // MARK: - Keywords Section
    
    private var keywordsSection: some View {
        DetailCard {
            VStack(alignment: .leading, spacing: FSpacing.md) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FColors.textSecondary)
                    
                    Text("Palabras clave")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FColors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(category.keywords.count)/\(AppConfig.Limits.maxKeywordsPerCategory)")
                        .font(.caption)
                        .foregroundStyle(FColors.textTertiary)
                }
                
                FlowLayout(spacing: FSpacing.sm) {
                    ForEach(category.keywords, id: \.self) { keyword in
                        DetailKeywordChip(keyword: keyword, color: category.color.color)
                    }
                }
            }
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        DetailCard {
            VStack(spacing: 0) {
                DetailActionRow(
                    title: category.isFavorite ? "Quitar de favoritos" : "Marcar como favorito",
                    icon: category.isFavorite ? "star.slash.fill" : "star.fill",
                    iconColor: FColors.yellow
                ) {
                    viewModel.toggleFavorite(category)
                    Task { @MainActor in Constants.Haptic.light() }
                }
                
                DetailActionDivider()
                
                DetailActionRow(
                    title: "Duplicar categoría",
                    icon: "doc.on.doc.fill",
                    iconColor: FColors.textSecondary
                ) {
                    viewModel.duplicateCategory(category)
                    dismiss()
                }
                
                if !category.isSystem {
                    DetailActionDivider()
                    
                    DetailActionRow(
                        title: category.isArchived ? "Eliminar permanentemente" : "Archivar categoría",
                        icon: category.isArchived ? "trash.fill" : "archivebox.fill",
                        iconColor: FColors.red,
                        isDestructive: true
                    ) {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            if category.isArchived {
                                viewModel.presentDeleteAlert(category)
                            } else {
                                viewModel.presentArchiveAlert(category)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Detail Card

private struct DetailCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(FSpacing.lg)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: FRadius.lg, style: .continuous))
            .overlay(cardBorder)
    }
    
    private var cardBackground: some View {
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
    
    private var cardBorder: some View {
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

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accentColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(FColors.textPrimary)
                
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(FColors.textSecondary)
            }
            
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(FColors.textTertiary)
        }
        .padding(FSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(cardBorder)
    }
    
    private var cardBackground: some View {
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
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
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

// MARK: - Subcategory Row

private struct SubcategoryRow: View {
    let child: Category
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: FSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(child.color.color.opacity(colorScheme == .dark ? 0.15 : 0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: child.systemImageName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(child.color.color)
            }
            
            Text(child.name)
                .font(.body)
                .foregroundStyle(FColors.textPrimary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(FColors.textTertiary)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Detail Keyword Chip

private struct DetailKeywordChip: View {
    let keyword: String
    let color: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Text(keyword)
            .font(.subheadline)
            .foregroundStyle(FColors.textPrimary)
            .padding(.horizontal, FSpacing.md)
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

// MARK: - Detail Action Row

private struct DetailActionRow: View {
    let title: String
    let icon: String
    let iconColor: Color
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: FSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(iconColor)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundStyle(isDestructive ? FColors.red : FColors.textPrimary)
                
                Spacer()
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(DetailActionButtonStyle())
    }
}

// MARK: - Detail Action Divider

private struct DetailActionDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 40)
            .opacity(0.5)
    }
}

// MARK: - Detail Action Button Style

private struct DetailActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(Constants.Animation.easeOut, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Detail - Light") {
    let category = Category(
        name: "Comida",
        icon: .food,
        color: .orange,
        type: .expense,
        budget: 5000,
        keywords: ["uber eats", "rappi", "restaurante", "supermercado"]
    )
    
    return Color.clear
        .sheet(isPresented: .constant(true)) {
            CategoryDetailSheet(
                category: category,
                viewModel: CategoriesViewModel()
            )
        }
}

#Preview("Detail - Dark") {
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
