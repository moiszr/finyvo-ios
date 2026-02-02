//
//  TransactionDetailSheet.swift
//  Finyvo
//
//  Created by Moises Núñez on 01/15/26.
//  Refactored on 01/18/26 - Clean architecture
//
//  Premium transaction detail sheet.
//

import SwiftUI
import SwiftData

// MARK: - Transaction Detail Sheet

struct TransactionDetailSheet: View {
    
    // MARK: - Properties
    
    let transaction: Transaction
    @Bindable var viewModel: TransactionsViewModel
    let modelContext: ModelContext
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showDeleteAlert = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                    
                    mainInfoSection
                        .padding(.top, FSpacing.lg)
                    
                    if transaction.hasTags {
                        tagsSection
                            .padding(.top, FSpacing.lg)
                    }
                    
                    if let note = transaction.note, !note.isEmpty {
                        notesSection(note: note)
                            .padding(.top, FSpacing.lg)
                    }
                    
                    metadataSection
                        .padding(.top, FSpacing.lg)
                    
                    actionsSection
                        .padding(.top, FSpacing.xl)
                }
                .padding(.horizontal, FSpacing.lg)
                .padding(.bottom, FSpacing.xxxl)
            }
            .background(FColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .alert("Eliminar transacción", isPresented: $showDeleteAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Eliminar", role: .destructive) {
                    viewModel.deleteTransaction(transaction, in: modelContext)
                    dismiss()
                }
            } message: {
                Text("Esta acción no se puede deshacer.")
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(FColors.background)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: FSpacing.md) {
            ZStack {
                Circle()
                    .fill(typeColor.opacity(colorScheme == .dark ? 0.2 : 0.12))
                    .frame(width: 72, height: 72)
                
                Image(systemName: transaction.displayIcon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(typeColor)
            }
            
            VStack(spacing: 4) {
                Text(transaction.safeFormattedSignedAmount)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(FColors.textPrimary)
                    .monospacedDigit()
                
                HStack(spacing: 6) {
                    Image(systemName: typeIcon)
                        .font(.system(size: 12, weight: .semibold))
                    
                    Text(transaction.type.title)
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(typeColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FSpacing.xl)
    }
    
    // MARK: - Main Info Section
    
    private var mainInfoSection: some View {
        VStack(spacing: 0) {
            if let category = transaction.category {
                DetailInfoRow(
                    icon: category.icon.rawValue,
                    iconColor: category.color.color,
                    title: "Categoría",
                    value: category.name
                )
                
                Divider().padding(.leading, 52)
            }
            
            if let walletName = transaction.safeWalletName {
                DetailInfoRow(
                    icon: transaction.walletIconName,
                    iconColor: transaction.wallet?.color.color ?? FColors.textTertiary,
                    title: transaction.type == .transfer ? "Desde" : "Billetera",
                    value: walletName
                )
                
                if transaction.type == .transfer {
                    Divider().padding(.leading, 52)
                }
            }
            
            if transaction.type == .transfer, let destWallet = transaction.destinationWallet {
                DetailInfoRow(
                    icon: destWallet.systemImageName,
                    iconColor: destWallet.color.color,
                    title: "Hacia",
                    value: destWallet.name
                )
            }
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(cardBorder)
    }
    
    // MARK: - Tags Section
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: FSpacing.sm) {
            Text("Etiquetas")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FColors.textSecondary)
                .padding(.horizontal, 4)
            
            FlowLayout(spacing: 8) {
                ForEach(transaction.tags ?? [], id: \.id) { tag in
                    DetailTagChip(tag: tag)
                }
            }
        }
    }
    
    // MARK: - Notes Section
    
    private func notesSection(note: String) -> some View {
        VStack(alignment: .leading, spacing: FSpacing.sm) {
            Text("Notas")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FColors.textSecondary)
                .padding(.horizontal, 4)
            
            Text(note)
                .font(.body)
                .foregroundStyle(FColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(FSpacing.md)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(cardBorder)
        }
    }
    
    // MARK: - Metadata Section
    
    private var metadataSection: some View {
        VStack(spacing: 0) {
            DetailInfoRow(
                icon: "calendar",
                iconColor: FColors.textTertiary,
                title: "Fecha",
                value: transaction.date.formatted(date: .long, time: .shortened)
            )
            
            Divider().padding(.leading, 52)
            
            DetailInfoRow(
                icon: "number",
                iconColor: FColors.textTertiary,
                title: "Referencia",
                value: String(transaction.id.uuidString.prefix(8)).uppercased()
            )
            
            if transaction.isRecurring {
                Divider().padding(.leading, 52)
                
                DetailInfoRow(
                    icon: "repeat",
                    iconColor: FColors.purple,
                    title: "Recurrencia",
                    value: "Transacción recurrente"
                )
            }
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(cardBorder)
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: FSpacing.sm) {
            DetailActionButton(
                title: "Editar transacción",
                icon: "pencil",
                style: .primary
            ) {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    viewModel.presentEdit(transaction)
                }
            }
            
            HStack(spacing: FSpacing.sm) {
                DetailActionButton(
                    title: "Duplicar",
                    icon: "doc.on.doc",
                    style: .secondary
                ) {
                    _ = viewModel.duplicateTransactionAnimated(transaction, in: modelContext)
                    Constants.Haptic.success()
                    dismiss()
                }
                
                DetailActionButton(
                    title: "Eliminar",
                    icon: "trash",
                    style: .destructive
                ) {
                    showDeleteAlert = true
                }
            }
        }
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
                    .foregroundStyle(FColors.textPrimary)
            }
        }
        
        ToolbarItem(placement: .principal) {
            Text("Detalle")
                .font(.headline.weight(.semibold))
                .foregroundStyle(FColors.textPrimary)
        }
    }
    
    // MARK: - Helpers
    
    private var typeColor: Color {
        switch transaction.type {
        case .income: return FColors.green
        case .expense: return FColors.red
        case .transfer: return FColors.blue
        }
    }
    
    private var typeIcon: String {
        switch transaction.type {
        case .income: return "arrow.down.circle.fill"
        case .expense: return "arrow.up.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(colorScheme == .dark ? FColors.backgroundSecondary : Color.white)
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(
                colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04),
                lineWidth: 1
            )
    }
}

// MARK: - Detail Info Row

private struct DetailInfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: FSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconColor.opacity(colorScheme == .dark ? 0.2 : 0.12))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(FColors.textTertiary)
                
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FColors.textPrimary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(FSpacing.md)
    }
}

// MARK: - Detail Tag Chip

private struct DetailTagChip: View {
    let tag: Tag
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(tag.color.color)
                .frame(width: 6, height: 6)
            
            Text(tag.displayName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(FColors.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(tag.color.color.opacity(colorScheme == .dark ? 0.15 : 0.1))
        )
    }
}

// MARK: - Detail Action Button

private struct DetailActionButton: View {
    
    enum Style { case primary, secondary, destructive }
    
    let title: String
    let icon: String
    let style: Style
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button {
            Constants.Haptic.light()
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(border)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return FColors.textPrimary
        case .destructive: return FColors.red
        }
    }
    
    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(FColors.brand)
        case .secondary:
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
        case .destructive:
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(FColors.red.opacity(colorScheme == .dark ? 0.15 : 0.08))
        }
    }
    
    @ViewBuilder
    private var border: some View {
        if style == .secondary {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(FColors.border, lineWidth: 1)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Transaction Detail") {
    TransactionDetailSheet(
        transaction: Transaction(
            amount: 1250.50,
            type: .expense,
            note: "Cena con amigos en el restaurante italiano."
        ),
        viewModel: TransactionsViewModel(),
        modelContext: try! ModelContext(ModelContainer(for: Transaction.self))
    )
}
#endif
