//
//  LottieView.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/6/25.
//

import SwiftUI
import Lottie

/// Vista reusable para animaciones Lottie
/// Soporta loop, autoplay y respeta "Reduce Motion"
struct LottieView: View {
    
    // MARK: - Properties
    let name: String
    var loopMode: LottieLoopMode = .loop
    var contentMode: UIView.ContentMode = .scaleAspectFit
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    // MARK: - Body
    var body: some View {
        LottieViewRepresentable(
            name: name,
            loopMode: reduceMotion ? .playOnce : loopMode,
            contentMode: contentMode,
            animationSpeed: reduceMotion ? 0.5 : 1.0
        )
    }
}

// MARK: - UIViewRepresentable
private struct LottieViewRepresentable: UIViewRepresentable {
    let name: String
    let loopMode: LottieLoopMode
    let contentMode: UIView.ContentMode
    let animationSpeed: CGFloat
    
    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView(name: name)
        animationView.loopMode = loopMode
        animationView.contentMode = contentMode
        animationView.animationSpeed = animationSpeed
        animationView.backgroundBehavior = .pauseAndRestore
        
        // Configurar constraints
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        animationView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        return animationView
    }
    
    func updateUIView(_ animationView: LottieAnimationView, context: Context) {
        // Play cuando la vista se actualiza
        if !animationView.isAnimationPlaying {
            animationView.play()
        }
    }
}

// MARK: - Preview
#Preview {
    LottieView(name: "onboarding_transactions")
        .frame(width: 200, height: 200)
}
