//
//  LiquidCircleModifier.swift
//  Finyvo
//
//  Circle background con iOS 26+ glassEffect y fallback sólido.
//

import SwiftUI

struct LiquidCircleModifier: ViewModifier {
    var tint: Color? = nil

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.background {
                Circle().fill(.clear)
                    .glassEffect(.regular.tint(tint ?? .clear), in: .circle)
            }
        } else {
            let isDark = colorScheme == .dark
            let fill = tint ?? (isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
            let border: Color = isDark ? .white.opacity(0.12) : .black.opacity(0.06)
            content
                .background(Circle().fill(fill))
                .overlay(Circle().stroke(border, lineWidth: 0.5))
        }
    }
}

extension View {
    func liquidCircle(tint: Color? = nil) -> some View {
        modifier(LiquidCircleModifier(tint: tint))
    }
}
