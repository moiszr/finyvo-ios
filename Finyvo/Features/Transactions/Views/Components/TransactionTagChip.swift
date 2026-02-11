//
//  TransactionTagChip.swift
//  Finyvo
//
//  Tag chip unificado: read-only (detail) o con botón de eliminar (editor).
//  Si `onRemove` es nil, se muestra sin botón X.
//

import SwiftUI

struct TransactionTagChip: View {
    let tag: Tag
    var onRemove: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tag.color.color)
                .frame(width: 8, height: 8)

            Text(tag.displayName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(FColors.textPrimary)

            if let onRemove {
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(FColors.textTertiary)
                }
                .accessibilityLabel("Eliminar etiqueta \(tag.displayName)")
            }
        }
        .padding(.horizontal, TransactionUI.pillPaddingH)
        .padding(.vertical, TransactionUI.pillPaddingV)
        .background(chipBackground)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Etiqueta: \(tag.displayName)")
    }

    @ViewBuilder
    private var chipBackground: some View {
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(.clear)
                .glassEffect(.regular.tint(tag.color.color.opacity(0.2)), in: .capsule)
        } else {
            Capsule()
                .fill(tag.color.color.opacity(colorScheme == .dark ? 0.15 : 0.1))
                .overlay(
                    Capsule()
                        .stroke(tag.color.color.opacity(0.2), lineWidth: 1)
                )
        }
    }
}
