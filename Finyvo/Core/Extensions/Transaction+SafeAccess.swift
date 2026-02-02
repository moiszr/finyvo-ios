//
//  Transaction+SafeAccess.swift
//  Finyvo
//
//  Created by Moises Núñez on 01/17/26.
//  Safe accessors for Transaction properties that might reference deleted models.
//
//  This extension provides safe access to wallet-related properties
//  to prevent crashes when a wallet is deleted but transactions still reference it.
//

import Foundation

extension Transaction {
    
    // MARK: - Safe Wallet Access
    
    /// Safely checks if the wallet relationship is still valid.
    /// Returns `false` if the wallet was deleted.
    var hasValidWallet: Bool {
        guard let wallet = wallet else { return false }
        // Try to access a property - if it throws, wallet is invalid
        return !wallet.name.isEmpty || wallet.currentBalance != 0
    }
    
    /// Safely get wallet name, returns nil if wallet was deleted.
    var safeWalletName: String? {
        guard let wallet = wallet else { return nil }
        let name = wallet.name
        return name.isEmpty ? nil : name
    }
    
    /// Safely get the currency code from wallet or fallback to transaction's own or default.
    var safeCurrencyCode: String {
        // First priority: Transaction's own stored currency code
        if let code = currencyCode, !code.isEmpty {
            return code
        }
        // Second priority: Wallet's currency code
        if let wallet = wallet {
            let code = wallet.currencyCode
            if !code.isEmpty {
                return code
            }
        }
        // Fallback: App default
        return AppConfig.Defaults.currencyCode
    }
    
    /// Safe formatted signed amount that won't crash if wallet is deleted.
    ///
    /// Use this instead of `formattedSignedAmount` when displaying in lists
    /// where the wallet might have been deleted.
    var safeFormattedSignedAmount: String {
        let code = safeCurrencyCode
        let prefix: String
        switch type {
        case .income:
            prefix = "+"
        case .expense:
            prefix = "-"
        case .transfer:
            prefix = ""
        }
        return "\(prefix)\(amount.asCurrency(code: code))"
    }
    
    /// Safe formatted amount (without sign) that won't crash if wallet is deleted.
    var safeFormattedAmount: String {
        amount.asCurrency(code: safeCurrencyCode)
    }
    
    // MARK: - Safe Display Properties
    
    /// Wallet display name or "Sin billetera" if deleted/nil
    var walletDisplayName: String {
        safeWalletName ?? "Sin billetera"
    }
    
    /// Wallet icon name or default creditcard icon
    var walletIconName: String {
        guard let wallet = wallet else { return "creditcard.fill" }
        return wallet.systemImageName
    }
}         
