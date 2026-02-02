//
//  TransactionGroupHeader.swift
//  Finyvo
//
//  Created by Moises Núñez on 01/15/26.
//  Updated on 01/30/26 - Simplified: only date and transaction count
//
//  Header para grupos de transacciones por fecha.
//

import SwiftUI

// MARK: - Transaction Group Header

struct TransactionGroupHeader: View {
    
    // MARK: - Properties
    
    let group: TransactionGroup
    
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Computed
    
    private var transactionCountLabel: String {
        group.count == 1 ? "1 transacción" : "\(group.count) transacciones"
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .center) {
            // Fecha
            VStack(alignment: .leading, spacing: 2) {
                Text(group.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FColors.textPrimary)
                
                if let subtitle = group.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(FColors.textTertiary)
                }
            }
            
            Spacer()
            
            // Cantidad de transacciones
            Text(transactionCountLabel)
                .font(.caption)
                .foregroundStyle(FColors.textTertiary)
        }
        .padding(.horizontal, FSpacing.lg)
        .padding(.vertical, FSpacing.sm)
    }

}

// MARK: - Minimal Group Header

struct TransactionGroupHeaderMinimal: View {
    
    let title: String
    var subtitle: String? = nil
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(FColors.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            if let subtitle {
                Text("•")
                    .font(.caption)
                    .foregroundStyle(FColors.textTertiary.opacity(0.5))
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(FColors.textTertiary)
            }
            
            Spacer()
        }
        .padding(.horizontal, FSpacing.lg)
        .padding(.vertical, FSpacing.xs)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Group Headers") {
    VStack(spacing: 0) {
        TransactionGroupHeader(
            group: TransactionGroup(
                id: "today",
                date: .now,
                title: "Hoy",
                subtitle: nil,
                transactions: []
            )
        )
        
        Divider()
        
        TransactionGroupHeader(
            group: TransactionGroup(
                id: "yesterday",
                date: Calendar.current.date(byAdding: .day, value: -1, to: .now)!,
                title: "Ayer",
                subtitle: "14 de enero",
                transactions: []
            )
        )
        
        Divider()
        
        TransactionGroupHeaderMinimal(title: "Diciembre 2025", subtitle: "15 transacciones")
    }
    .background(FColors.background)
}
#endif
