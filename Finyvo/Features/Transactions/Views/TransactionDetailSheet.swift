//
//  TransactionDetailSheet.swift
//  Finyvo
//
//  Created by Moises Núñez on 01/15/26.
//  Redesigned on 02/07/26 - v12
//  Alt Design on 02/07/26 - v13 (Editor-based detail layout)
//

import SwiftUI
import SwiftData

// MARK: - Constants

private enum DC {
    static let mainFont: CGFloat     = 28
    static let catFont: CGFloat      = 13
    static let catIconFont: CGFloat  = 12

    static let refFont: CGFloat      = 11
    static let actionH: CGFloat      = 48

    static let cardRadius: CGFloat   = 24
    static let pillPadH: CGFloat     = 14
    static let pillPadV: CGFloat     = 10

    static let hPad: CGFloat         = 22
    static let gap: CGFloat          = 14

    static let quick    = Animation.spring(response: 0.35, dampingFraction: 0.8)
    static let entrance = Animation.spring(response: 0.5, dampingFraction: 0.84)
}

// MARK: - Sheet

struct TransactionDetailSheet: View {

    let transaction: Transaction
    @Bindable var viewModel: TransactionsViewModel
    let modelContext: ModelContext

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var showDeleteAlert = false
    @State private var appeared = false

    // ✅ Detent dinámico por reglas (NO medir height)
    @State private var detentFraction: CGFloat = 0.75

    private var isDark: Bool { colorScheme == .dark }

    // MARK: - Derived

    private var typeColor: Color {
        switch transaction.type {
        case .income:   return FColors.green
        case .expense:  return FColors.red
        case .transfer: return FColors.blue
        }
    }

    private var categoryColor: Color {
        transaction.category?.color.color ?? typeColor
    }

    private var displayTitle: String {
        if let n = transaction.note, !n.isEmpty { return n }
        return transaction.category?.name ?? transaction.type.defaultTitle
    }

    private var shortDate: String {
        let d = transaction.date
        if d.isToday { return "Hoy" }
        if d.isYesterday { return "Ayer" }
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        f.locale = Locale(identifier: "es")
        return f.string(from: d).capitalized
    }

    private var currencyFlag: String {
        let code = transaction.wallet?.currencyCode ?? CurrencyConfig.defaultCurrency.code
        let base: UInt32 = 127397
        return String(code.prefix(2)).unicodeScalars
            .compactMap { UnicodeScalar(base + $0.value) }
            .map(String.init).joined()
    }

    private var currencyCode: String {
        transaction.wallet?.currencyCode ?? CurrencyConfig.defaultCurrency.code
    }

    private var walletTitle: String {
        transaction.wallet?.name ?? "Sin billetera"
    }

    private var walletIcon: String {
        transaction.wallet?.icon.rawValue ?? "wallet.pass.fill"
    }

    private var walletIconColor: Color {
        transaction.wallet?.color.color ?? FColors.textTertiary
    }

    private var categoryTitle: String {
        if transaction.type == .transfer {
            return transaction.destinationWallet?.name ?? "Destino"
        }
        return transaction.category?.name ?? "Categoría"
    }

    private var categoryIcon: String {
        if transaction.type == .transfer {
            return transaction.destinationWallet?.icon.rawValue ?? "wallet.pass.fill"
        }
        return transaction.category?.icon.rawValue ?? "square.grid.2x2.fill"
    }

    private var categoryIconColor: Color {
        if transaction.type == .transfer {
            return transaction.destinationWallet?.color.color ?? FColors.textTertiary
        }
        return transaction.category?.color.color ?? FColors.textTertiary
    }

    private var tags: [Tag] { transaction.tags ?? [] }

    // MARK: - Title sizing (como editor feel)

    private struct TitleStyle {
        let size: CGFloat
        let minScale: CGFloat
        let useLineLimit2: Bool
    }

    private var titleStyle: TitleStyle {
        let c = displayTitle.trimmingCharacters(in: .whitespacesAndNewlines).count

        if c <= 18 { return .init(size: 28, minScale: 0.85, useLineLimit2: false) }
        if c <= 28 { return .init(size: 24, minScale: 0.78, useLineLimit2: false) }
        if c <= 40 { return .init(size: 21, minScale: 0.72, useLineLimit2: false) }
        return .init(size: 19, minScale: 0.70, useLineLimit2: true) // “small” => lineLimit(2)
    }

    // MARK: - Detent rules (stable)

    private var computedDetentFraction: CGFloat {
        var f: CGFloat = 0.58  // antes 0.62

        if titleStyle.useLineLimit2 { f += 0.04 }

        if !tags.isEmpty {
            f += 0.06
            if tags.count >= 6 { f += 0.02 }
            if tags.count >= 10 { f += 0.02 }
        }

        if transaction.type == .transfer { f += 0.01 }

        return min(max(f, 0.54), 0.82)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DC.gap) {
                        // ✅ Pill de tipo arriba del card
                        selectedTypePill
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, FSpacing.sm)

                        // ✅ Card estilo editor
                        unifiedDetailCard

                        // ✅ Tags debajo (FlowLayout, no scroll)
                        if !tags.isEmpty {
                            tagsSection
                                .padding(.top, 2)
                        }

                        referenceLabel
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, DC.hPad)
                    .padding(.bottom, DC.gap)
                }
                .scrollClipDisabled()

                // ✅ Actions bar pinned bottom (igual al primer diseño)
                actionsBar
                    .padding(.horizontal, DC.hPad)
                    .padding(.vertical, FSpacing.sm)
            }
            .background(FColors.background.ignoresSafeArea())
            .toolbar { toolbarItems }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 8)
        }
        .alert("Eliminar transacción", isPresented: $showDeleteAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Eliminar", role: .destructive) {
                Constants.Haptic.warning()
                viewModel.deleteTransaction(transaction, in: modelContext)
                dismiss()
            }
        } message: {
            Text("Esta acción no se puede deshacer.")
        }
        .presentationDetents([.fraction(detentFraction)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(FColors.background)
        .onAppear {
            detentFraction = computedDetentFraction
            withAnimation(DC.entrance) { appeared = true }
        }
        .onChange(of: tags.count) { _, _ in detentFraction = computedDetentFraction }
        .onChange(of: transaction.type) { _, _ in detentFraction = computedDetentFraction }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FColors.textSecondary)
            }
        }
    }

    // MARK: - Type Pill (selected only)

    private var selectedTypePill: some View {
        HStack(spacing: 6) {
            Image(systemName: transaction.type.systemImageName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(typeColor)

            Text(transaction.type.title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? .white : .primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(typePillBackground)
        .contentShape(Capsule())
    }

    @ViewBuilder
    private var typePillBackground: some View {
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(.clear)
                .glassEffect(.regular.tint(typeColor.opacity(0.22)).interactive(), in: .capsule)
        } else {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().fill(typeColor.opacity(isDark ? 0.18 : 0.14)))
                .overlay(Capsule().stroke(typeColor.opacity(isDark ? 0.25 : 0.18), lineWidth: 1))
        }
    }

    // MARK: - Unified Detail Card (Editor-based)

    private var unifiedDetailCard: some View {
        VStack(alignment: .leading, spacing: FSpacing.md) {

            // Fecha dentro del card arriba del título
            datePill
                .padding(.bottom, 2)

            // Descripción + Monto (tight, como editor)
            VStack(alignment: .leading, spacing: FSpacing.xs) {
                Text(displayTitle)
                    .font(.system(size: titleStyle.size, weight: .bold, design: .rounded))
                    .foregroundStyle(FColors.textPrimary)
                    .lineLimit(titleStyle.useLineLimit2 ? 2 : 1)
                    .minimumScaleFactor(titleStyle.minScale)

                Text(transaction.formattedAmount)
                    .font(.system(size: DC.mainFont, weight: .bold, design: .rounded))
                    .foregroundStyle(typeColor)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }

            // Pills abajo: wallet + category/destino
            HStack(spacing: FSpacing.sm) {
                DetailCapsulePill(
                    icon: walletIcon,
                    iconColor: walletIconColor,
                    title: walletTitle,
                    isPlaceholder: transaction.wallet == nil
                )

                DetailCapsulePill(
                    icon: categoryIcon,
                    iconColor: categoryIconColor,
                    title: categoryTitle,
                    isPlaceholder: (transaction.type == .transfer
                                    ? transaction.destinationWallet == nil
                                    : transaction.category == nil)
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, FSpacing.lg)
        .padding(.horizontal, FSpacing.lg)
        .background(glassCardBackground)
    }

    private var datePill: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(FColors.blue)

            Text(shortDate)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(FColors.textPrimary)
        }
        .padding(.horizontal, DC.pillPadH)
        .padding(.vertical, DC.pillPadV)
        .background(
            Capsule().fill(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
        )
    }

    @ViewBuilder
    private var glassCardBackground: some View {
        if #available(iOS 26.0, *) {
            RoundedRectangle(cornerRadius: DC.cardRadius, style: .continuous)
                .fill(.clear)
                .glassEffect(.regular, in: .rect(cornerRadius: DC.cardRadius))
        } else {
            RoundedRectangle(cornerRadius: DC.cardRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DC.cardRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: isDark
                                    ? [Color.white.opacity(0.08), Color.white.opacity(0.02)]
                                    : [Color.white.opacity(0.7), Color.white.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DC.cardRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: isDark
                                    ? [Color.white.opacity(0.15), Color.white.opacity(0.05)]
                                    : [Color.white.opacity(0.8), Color.black.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.08), radius: 20, y: 8)
        }
    }

    // MARK: - Tags (FlowLayout, no scroll)

    private var tagsSection: some View {
        FlowLayout(spacing: 8) {
            ForEach(tags, id: \.id) { tag in
                DetailTagChip(tag: tag)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Reference

    private var referenceLabel: some View {
        Text(String(transaction.id.uuidString.prefix(8)).uppercased())
            .font(.system(size: DC.refFont, weight: .medium, design: .monospaced))
            .foregroundStyle(FColors.textTertiary.opacity(0.5))
            .frame(maxWidth: .infinity)
    }

    // MARK: - Actions Bar (igual al diseño 1)

    private var actionsBar: some View {
        HStack(spacing: 10) {
            Button {
                Constants.Haptic.light()
                showDeleteAlert = true
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(FColors.red)
                    .frame(width: DC.actionH, height: DC.actionH)
                    .modifier(LiquidCircleMod(tint: FColors.red.opacity(0.08)))
            }
            .buttonStyle(ScaleButtonStyle())

            Button {
                Constants.Haptic.light()
                _ = viewModel.duplicateTransactionAnimated(transaction, in: modelContext)
                Constants.Haptic.success()
                dismiss()
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(FColors.textSecondary)
                    .frame(width: DC.actionH, height: DC.actionH)
                    .modifier(LiquidCircleMod())
            }
            .buttonStyle(ScaleButtonStyle())

            Button {
                Constants.Haptic.light()
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    viewModel.presentEdit(transaction)
                }
            } label: {
                HStack(spacing: 6) {
                    Text("Editar")
                        .font(.subheadline.weight(.semibold))
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(isDark ? .black : .white)
                .frame(maxWidth: .infinity)
                .frame(height: DC.actionH)
                .background(Capsule().fill(isDark ? Color.white : Color.black))
                .shadow(color: Color.black.opacity(isDark ? 0.12 : 0.25), radius: 8, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
}

// MARK: - Detail Capsule Pill (Read-only CapsuleSelectorButton style)

private struct DetailCapsulePill: View {
    let icon: String
    let iconColor: Color
    let title: String
    var isPlaceholder: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)

            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isPlaceholder ? FColors.textTertiary : FColors.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule().fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
        )
        .fixedSize(horizontal: true, vertical: false) // ✅ ancho intrínseco del contenido
    }
}

// MARK: - Liquid Circle Modifier

private struct LiquidCircleMod: ViewModifier {
    var tint: Color? = nil
    @Environment(\.colorScheme) private var cs

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.background {
                Circle().fill(.clear)
                    .glassEffect(.regular.tint(tint ?? .clear), in: .circle)
            }
        } else {
            let dark = cs == .dark
            let fill = tint ?? (dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
            let border: Color = dark ? .white.opacity(0.12) : .black.opacity(0.06)
            content
                .background(Circle().fill(fill))
                .overlay(Circle().stroke(border, lineWidth: 0.5))
        }
    }
}

// MARK: - Detail Tag Chip

private struct DetailTagChip: View {
    let tag: Tag
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tag.color.color)
                .frame(width: 8, height: 8)
            Text(tag.displayName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(FColors.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(chipBg)
    }

    @ViewBuilder
    private var chipBg: some View {
        if #available(iOS 26.0, *) {
            Capsule().fill(.clear)
                .glassEffect(.regular.tint(tag.color.color.opacity(0.2)), in: .capsule)
        } else {
            let dark = colorScheme == .dark
            Capsule()
                .fill(tag.color.color.opacity(dark ? 0.15 : 0.1))
                .overlay(Capsule().stroke(tag.color.color.opacity(0.2), lineWidth: 1))
        }
    }
}

#if DEBUG
#Preview("Detail ALT - Dark") {
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            TransactionDetailSheet(
                transaction: Transaction(amount: 1250.50, type: .expense, note: "Cena con amigos en un lugar larguísimo para forzar shrink"),
                viewModel: TransactionsViewModel(),
                modelContext: try! ModelContext(ModelContainer(for: Transaction.self))
            )
        }
        .preferredColorScheme(.dark)
}

#Preview("Detail ALT - Tags") {
    Color.white.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            let t = Transaction(amount: 350, type: .expense, note: "Supermercado semanal")
            // Nota: en tu app real, tags vienen de SwiftData. Aquí preview simple.
            TransactionDetailSheet(
                transaction: t,
                viewModel: TransactionsViewModel(),
                modelContext: try! ModelContext(ModelContainer(for: Transaction.self))
            )
        }
        .preferredColorScheme(.light)
}
#endif
