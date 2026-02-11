//
//  TransactionTypePillBackground.swift
//  Finyvo
//
//  Glass capsule background tintado para type pills.
//  Soporta `isSelected` y `matchedGeometryEffect` opcional via namespace.
//

import SwiftUI

struct TransactionTypePillBackground: View {
    let tint: Color
    var isSelected: Bool = true
    var namespace: Namespace.ID? = nil
    var matchedId: String = "selectedTypePill"

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if isSelected {
            selectedBackground
        }
    }

    @ViewBuilder
    private var selectedBackground: some View {
        if #available(iOS 26.0, *) {
            capsuleGlass
                .applyMatchedGeometry(id: matchedId, namespace: namespace)
        } else {
            capsuleFallback
                .applyMatchedGeometry(id: matchedId, namespace: namespace)
        }
    }

    @available(iOS 26.0, *)
    private var capsuleGlass: some View {
        Capsule()
            .fill(.clear)
            .glassEffect(.regular.tint(tint.opacity(0.22)).interactive(), in: .capsule)
    }

    private var capsuleFallback: some View {
        let isDark = colorScheme == .dark
        return Capsule()
            .fill(.ultraThinMaterial)
            .overlay(Capsule().fill(tint.opacity(isDark ? 0.18 : 0.14)))
            .overlay(Capsule().stroke(tint.opacity(isDark ? 0.25 : 0.18), lineWidth: 1))
    }
}

// MARK: - Matched Geometry Helper

private extension View {
    @ViewBuilder
    func applyMatchedGeometry(id: String, namespace: Namespace.ID?) -> some View {
        if let ns = namespace {
            self.matchedGeometryEffect(id: id, in: ns)
        } else {
            self
        }
    }
}
