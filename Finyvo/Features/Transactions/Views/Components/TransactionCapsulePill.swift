//
//  TransactionCapsulePill.swift
//  Finyvo
//
//  Capsule pill unificado: read-only (detail) o tappable con chevron (editor).
//  Si `action` es nil, se muestra como label estática sin chevron.
//

import SwiftUI

struct TransactionCapsulePill: View {
    let icon: String
    let iconColor: Color
    let title: String
    var isPlaceholder: Bool = false
    var action: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if let action {
            Button {
                action()
            } label: {
                pillLabel(showChevron: true)
            }
            .buttonStyle(ScaleButtonStyle())
        } else {
            pillLabel(showChevron: false)
                .fixedSize(horizontal: true, vertical: false)
        }
    }

    private func pillLabel(showChevron: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)

            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isPlaceholder ? FColors.textTertiary : FColors.textPrimary)
                .lineLimit(1)

            if showChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(FColors.textTertiary)
            }
        }
        .padding(.horizontal, TransactionUI.pillPaddingH)
        .padding(.vertical, TransactionUI.pillPaddingV)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
        )
    }
}
