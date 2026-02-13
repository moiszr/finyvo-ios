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
    static let catFont: CGFloat      = 13
    static let catIconFont: CGFloat  = 12
    static let refFont: CGFloat      = 11
    static let hPad: CGFloat         = 22
    static let gap: CGFloat          = 14
    static let entrance = Animation.spring(response: 0.5, dampingFraction: 0.84)
}

// MARK: - Sheet

struct TransactionDetailSheet: View {

    let transaction: Transaction
    @Bindable var viewModel: TransactionsViewModel
    let modelContext: ModelContext

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppState.self) private var appState
    @Environment(FXService.self) private var fxService

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

    /// Texto de conversión FX para la moneda preferida
    private var fxConvertedCaption: String? {
        let preferred = appState.preferredCurrencyCode
        let txCurrency = transaction.safeCurrencyCode
        guard txCurrency != preferred else { return nil }

        // Intentar primero el snapshot guardado
        if let formatted = transaction.formattedFXAmount,
           transaction.fxPreferredCurrencyCode == preferred {
            return formatted
        }

        // Intentar conversión local
        let engine = FXEngine(service: fxService)
        if let result = engine.convertLocallyIfPossible(amount: transaction.amount, from: txCurrency, to: preferred) {
            return result.convertedAmount.asCurrency(code: preferred)
        }

        return nil
    }

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

        if titleStyle.useLineLimit2 { f += 0.06 }

        if !tags.isEmpty {
            f += 0.06
            if tags.count >= 4 { f += 0.06 }
            if tags.count >= 7 { f += 0.06 }
            if tags.count >= 10 { f += 0.06 }
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
        .background(TransactionTypePillBackground(tint: typeColor))
        .contentShape(Capsule())
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
                    .font(.system(size: TransactionUI.mainFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(typeColor)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                // Monto convertido a moneda preferida
                if let convertedText = fxConvertedCaption {
                    Text("≈ \(convertedText)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(FColors.textSecondary)
                        .monospacedDigit()
                }
            }

            // Pills abajo: wallet + category/destino
            HStack(spacing: FSpacing.sm) {
                TransactionCapsulePill(
                    icon: walletIcon,
                    iconColor: walletIconColor,
                    title: walletTitle,
                    isPlaceholder: transaction.wallet == nil
                )

                TransactionCapsulePill(
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
        .padding(.horizontal, TransactionUI.pillPaddingH)
        .padding(.vertical, TransactionUI.pillPaddingV)
        .background(
            Capsule().fill(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
        )
    }

    private var glassCardBackground: some View {
        GlassCardBackground()
    }

    // MARK: - Tags (FlowLayout, no scroll)

    private var tagsSection: some View {
        FlowLayout(spacing: FSpacing.sm) {
            ForEach(tags, id: \.id) { tag in
                TransactionTagChip(tag: tag)
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
                    .frame(width: TransactionUI.buttonHeight, height: TransactionUI.buttonHeight)
                    .liquidCircle(tint: FColors.red.opacity(0.08))
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
                    .frame(width: TransactionUI.buttonHeight, height: TransactionUI.buttonHeight)
                    .liquidCircle()
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
                .frame(height: TransactionUI.buttonHeight)
                .background(Capsule().fill(isDark ? Color.white : Color.black))
                .shadow(color: Color.black.opacity(isDark ? 0.12 : 0.25), radius: 8, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
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
            .environment(AppState())
            .environment(FXService())
        }
        .preferredColorScheme(.dark)
}

#Preview("Detail ALT - Tags") {
    Color.white.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            let t = Transaction(amount: 350, type: .expense, note: "Supermercado semanal")
            TransactionDetailSheet(
                transaction: t,
                viewModel: TransactionsViewModel(),
                modelContext: try! ModelContext(ModelContainer(for: Transaction.self))
            )
            .environment(AppState())
            .environment(FXService())
        }
        .preferredColorScheme(.light)
}
#endif
