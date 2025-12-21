import SwiftUI
import UIKit

extension View {

    /// Cierra el teclado forzosamente usando UIKit (seguro en Swift 6 con MainActor).
    @MainActor
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    /// Cierra el teclado al tocar fuera, SIN romper taps de controles.
    /// - Funciona tocando cards/textos/fondo.
    /// - NO se dispara si el tap cayó en Button/Toggle/TextField (UIControl / UITextField / UITextView).
    func tapToDismissKeyboard(
        isEnabled: Bool = true,
        onDismiss: @escaping () -> Void = {}
    ) -> some View {
        background(
            KeyboardDismissInstaller(isEnabled: isEnabled, onDismiss: onDismiss)
        )
    }
}

// MARK: - UIKit bridge (Window-level, ultra robust)

private struct KeyboardDismissInstaller: UIViewRepresentable {
    let isEnabled: Bool
    let onDismiss: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(isEnabled: isEnabled, onDismiss: onDismiss)
    }

    func makeUIView(context: Context) -> PassthroughView {
        let view = PassthroughView()
        view.onMoveToWindow = { window in
            context.coordinator.attachIfNeeded(to: window)
        }
        return view
    }

    func updateUIView(_ uiView: PassthroughView, context: Context) {
        context.coordinator.isEnabled = isEnabled
        context.coordinator.onDismiss = onDismiss

        uiView.onMoveToWindow = { window in
            context.coordinator.attachIfNeeded(to: window)
        }

        // Por si update llega cuando ya hay window
        if let window = uiView.window {
            context.coordinator.attachIfNeeded(to: window)
        }
    }

    static func dismantleUIView(_ uiView: PassthroughView, coordinator: Coordinator) {
        coordinator.detach()
    }

    /// View “fantasma” que NO intercepta touches (no hit-testing).
    final class PassthroughView: UIView {
        var onMoveToWindow: ((UIWindow) -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if let window {
                onMoveToWindow?(window)
            }
        }

        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool { false }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {

        var isEnabled: Bool
        var onDismiss: () -> Void

        private weak var installedOn: UIView?
        private var recognizer: UITapGestureRecognizer?

        init(isEnabled: Bool, onDismiss: @escaping () -> Void) {
            self.isEnabled = isEnabled
            self.onDismiss = onDismiss
        }

        func attachIfNeeded(to window: UIWindow) {
            guard installedOn !== window else { return }

            detach()

            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            tap.cancelsTouchesInView = false // no cancela touches de UI :contentReference[oaicite:2]{index=2}
            tap.delegate = self

            window.addGestureRecognizer(tap)
            recognizer = tap
            installedOn = window
        }

        func detach() {
            if let recognizer, let installedOn {
                installedOn.removeGestureRecognizer(recognizer)
            }
            recognizer = nil
            installedOn = nil
        }

        @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard isEnabled else { return }
            guard recognizer.state == .ended else { return }

            Task { @MainActor in
                onDismiss()
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            }
        }

        // Ignora taps dentro de controles / inputs.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard isEnabled else { return false }

            var v: UIView? = touch.view
            while let view = v {
                if view is UIControl || view is UITextField || view is UITextView {
                    return false
                }
                v = view.superview
            }
            return true
        }

        // No estorba a otros gestos (ej: scroll). :contentReference[oaicite:3]{index=3}
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }
}
