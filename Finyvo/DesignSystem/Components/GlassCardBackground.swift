//
//  GlassCardBackground.swift
//  Finyvo
//
//  Glass card background con iOS 26+ glassEffect y fallback ultraThinMaterial.
//

import SwiftUI

struct GlassCardBackground: View {
    var cornerRadius: CGFloat = TransactionUI.cardCornerRadius

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if #available(iOS 26.0, *) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.clear)
                .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            let isDark = colorScheme == .dark
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
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
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
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
}
