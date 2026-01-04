//
//  View+Extensions.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/24/25.
//  Extensiones útiles para Views.
//

import SwiftUI

// MARK: - Keyboard Dismissal

extension View {
    
    /// Oculta el teclado programáticamente.
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    /// Agrega un gesto de tap que cierra el teclado.
    func tapToDismissKeyboard(_ action: (() -> Void)? = nil) -> some View {
        self.onTapGesture {
            hideKeyboard()
            action?()
        }
    }
    
    /// Agrega un fondo que cierra el teclado al tocar.
    func dismissKeyboardOnTap() -> some View {
        self.background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
        )
    }
}

// MARK: - Conditional Modifiers

extension View {
    
    /// Aplica un modificador condicionalmente.
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Aplica un modificador si el valor opcional no es nil.
    @ViewBuilder
    func ifLet<T, Content: View>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}

// MARK: - Corner Radius

extension View {
    
    /// Aplica corner radius solo a esquinas específicas.
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Safe Area

extension View {
    
    /// Lee los safe area insets.
    func readSafeArea(_ safeArea: Binding<EdgeInsets>) -> some View {
        self.background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        safeArea.wrappedValue = geo.safeAreaInsets
                    }
                    .onChange(of: geo.safeAreaInsets) { _, newValue in
                        safeArea.wrappedValue = newValue
                    }
            }
        )
    }
}

// MARK: - Debugging

extension View {
    
    /// Imprime el tamaño de la vista en consola (solo debug).
    func debugSize(_ label: String = "") -> some View {
        #if DEBUG
        self.background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        print("📐 \(label.isEmpty ? "View" : label): \(geo.size)")
                    }
            }
        )
        #else
        self
        #endif
    }
    
    /// Agrega un borde de debug a la vista.
    func debugBorder(_ color: Color = .red) -> some View {
        #if DEBUG
        self.border(color, width: 1)
        #else
        self
        #endif
    }
}

// MARK: - Shimmer Effect

extension View {
    
    /// Aplica un efecto shimmer de carga.
    /// - Parameter isActive: Si el efecto está activo (default: true)
    func shimmer(isActive: Bool = true) -> some View {
        self.modifier(ShimmerModifier(isActive: isActive))
    }
}

private struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        if isActive {
            content
                .overlay(
                    GeometryReader { geo in
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.3),
                                Color.white.opacity(0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 2)
                        .offset(x: -geo.size.width + (geo.size.width * 2 * phase))
                    }
                )
                .mask(content)
                .onAppear {
                    withAnimation(
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                    ) {
                        phase = 1
                    }
                }
                .onChange(of: isActive) { _, newValue in
                    if newValue {
                        phase = 0
                        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            phase = 1
                        }
                    } else {
                        phase = 0
                    }
                }
        } else {
            content
        }
    }
}
