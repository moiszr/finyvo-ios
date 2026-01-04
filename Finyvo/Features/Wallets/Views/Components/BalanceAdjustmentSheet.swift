//
//  BalanceAdjustmentSheet.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/24/25.
//  Sheet para ajustar el balance de una billetera manualmente.
//

import SwiftUI

struct BalanceAdjustmentSheet: View {
    
    // MARK: - Properties
    
    let wallet: Wallet
    @Bindable var viewModel: WalletsViewModel
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var newBalanceString: String = ""
    @State private var reason: String = ""
    @FocusState private var isBalanceFocused: Bool
    
    // MARK: - Computed
    
    private var currentBalance: Double {
        wallet.currentBalance
    }
    
    private var newBalance: Double? {
        let currency = wallet.currency ?? CurrencyConfig.defaultCurrency
        return currency.parse(newBalanceString)
    }
    
    private var difference: Double {
        guard let new = newBalance else { return 0 }
        return new - currentBalance
    }
    
    private var isValid: Bool {
        newBalance != nil && newBalance != currentBalance
    }
    
    private var currencySymbol: String {
        wallet.currency?.symbol ?? wallet.currencyCode
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: FSpacing.xl) {
                // Header con info actual
                currentBalanceHeader
                
                // Input de nuevo balance
                newBalanceSection
                
                // Diferencia
                if isValid {
                    differenceSection
                }
                
                // Razón opcional
                reasonSection
                
                Spacer()
                
                // Botón guardar
                saveButton
            }
            .padding(.horizontal, FSpacing.lg)
            .padding(.top, FSpacing.lg)
            .padding(.bottom, FSpacing.xl)
            .background(FColors.background)
            .navigationTitle("Ajustar Balance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(FColors.textPrimary)
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(.regularMaterial)
        .presentationCornerRadius(32)
        .onAppear {
            newBalanceString = formatForInput(currentBalance)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isBalanceFocused = true
            }
        }
    }
    
    // MARK: - Current Balance Header
    
    private var currentBalanceHeader: some View {
        VStack(spacing: FSpacing.sm) {
            // Mini card visual
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(wallet.color.color)
                        .frame(width: 40, height: 28)
                    
                    Image(systemName: wallet.systemImageName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(wallet.color.contrastContentColor(for: colorScheme))
                }
                
                Text(wallet.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FColors.textPrimary)
                
                Spacer()
            }
            
            // Balance actual
            HStack {
                Text("Balance actual")
                    .font(.caption)
                    .foregroundStyle(FColors.textSecondary)
                
                Spacer()
                
                Text(wallet.formattedBalance)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(FColors.textPrimary)
            }
        }
        .padding(FSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? FColors.backgroundSecondary : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05), lineWidth: 1)
        )
    }
    
    // MARK: - New Balance Section
    
    private var newBalanceSection: some View {
        VStack(alignment: .leading, spacing: FSpacing.sm) {
            Text("Nuevo balance")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FColors.textSecondary)
            
            HStack(spacing: 12) {
                Text(currencySymbol)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(FColors.textSecondary)
                
                TextField("0", text: $newBalanceString)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(FColors.textPrimary)
                    .keyboardType(.decimalPad)
                    .focused($isBalanceFocused)
                    .multilineTextAlignment(.leading)
            }
            .padding(FSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ? FColors.backgroundSecondary : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isBalanceFocused ? FColors.brand.opacity(0.5) : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05)),
                        lineWidth: isBalanceFocused ? 2 : 1
                    )
            )
            
            Text("Ingresa el balance real de tu cuenta.")
                .font(.caption)
                .foregroundStyle(FColors.textTertiary)
        }
    }
    
    // MARK: - Difference Section
    
    private var differenceSection: some View {
        HStack {
            Image(systemName: difference >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundStyle(difference >= 0 ? FColors.green : FColors.red)
            
            Text("Diferencia")
                .font(.subheadline)
                .foregroundStyle(FColors.textSecondary)
            
            Spacer()
            
            Text("\(difference >= 0 ? "+" : "")\(difference.asCurrency(code: wallet.currencyCode))")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(difference >= 0 ? FColors.green : FColors.red)
        }
        .padding(FSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill((difference >= 0 ? FColors.green : FColors.red).opacity(0.1))
        )
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .animation(Constants.Animation.defaultSpring, value: difference)
    }
    
    // MARK: - Reason Section
    
    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: FSpacing.sm) {
            HStack {
                Text("Razón del ajuste")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FColors.textSecondary)
                
                Text("(opcional)")
                    .font(.caption)
                    .foregroundStyle(FColors.textTertiary)
            }
            
            TextField("Ej: Corrección de cargo no registrado", text: $reason)
                .font(.body)
                .padding(FSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(colorScheme == .dark ? FColors.backgroundSecondary : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05), lineWidth: 1)
                )
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        FButton(
            "Ajustar Balance",
            variant: .primary,
            size: .large,
            isFullWidth: true,
            icon: "checkmark",
            isDisabled: !isValid
        ) {
            save()
        }
    }
    
    // MARK: - Actions
    
    private func save() {
        guard let newBalance = newBalance else { return }
        viewModel.adjustBalance(wallet, newBalance: newBalance, reason: reason.isEmpty ? nil : reason)
        dismiss()
    }
    
    // MARK: - Helpers
    
    private func formatForInput(_ value: Double) -> String {
        if value == 0 { return "" }
        if value == floor(value) {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }
}

// MARK: - Preview

#Preview {
    let wallet = Wallet(
        name: "Banco Popular",
        type: .checking,
        color: .blue,
        currencyCode: "DOP",
        initialBalance: 45000
    )
    
    Color.clear
        .sheet(isPresented: .constant(true)) {
            BalanceAdjustmentSheet(wallet: wallet, viewModel: WalletsViewModel())
        }
}
