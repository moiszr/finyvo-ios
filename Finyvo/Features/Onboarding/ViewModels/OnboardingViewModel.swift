//
//  OnboardingViewModel.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/6/25.
//

import SwiftUI

// MARK: - Onboarding Page Model
struct OnboardingPage: Identifiable, Equatable {
    let id: Int
    let title: String
    let subtitle: String
    let lottieName: String
    let glowColorLight: Color  // Color del glow en Light Mode
    let glowColorDark: Color   // Color del glow en Dark Mode
    
    static func == (lhs: OnboardingPage, rhs: OnboardingPage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - OnboardingViewModel
@Observable
final class OnboardingViewModel {
    
    // MARK: - Properties
    
    var currentIndex: Int = 0
    var onComplete: (() -> Void)?
    
    /// Páginas del onboarding con paleta de glow calibrada para Light y Dark
    let pages: [OnboardingPage] = [
        // Página 1: Moneda amarilla/naranja
        // En light: dorado intenso que destaque sobre blanco
        // En dark: dorado cálido más luminoso
        OnboardingPage(
            id: 0,
            title: "Cada peso\ncuenta",
            subtitle: "Registra ingresos y gastos al instante. Cero fricción.",
            lottieName: "onboarding_transactions",
            glowColorLight: Color(red: 1.0, green: 0.65, blue: 0.0),  // Naranja dorado
            glowColorDark: Color(red: 1.0, green: 0.75, blue: 0.2)    // Dorado luminoso
        ),
        
        // Página 2: Hoja con gráficos (morado/rosa)
        // En light: violeta más saturado
        // En dark: violeta brillante
        OnboardingPage(
            id: 1,
            title: "Tu dinero,\nordenado",
            subtitle: "Finyvo clasifica todo. Tú solo observa los patrones.",
            lottieName: "onboarding_categories",
            glowColorLight: Color(red: 0.6, green: 0.3, blue: 0.9),   // Violeta saturado
            glowColorDark: Color(red: 0.7, green: 0.4, blue: 1.0)     // Violeta brillante
        ),
        
        // Página 3: Flecha azul (suscripciones)
        // En light: azul cielo visible
        // En dark: azul eléctrico
        OnboardingPage(
            id: 2,
            title: "Adiós\nsorpresas",
            subtitle: "Detecta cobros recurrentes antes de que te golpeen.",
            lottieName: "onboarding_subscriptions",
            glowColorLight: Color(red: 0.2, green: 0.6, blue: 1.0),   // Azul cielo
            glowColorDark: Color(red: 0.3, green: 0.7, blue: 1.0)     // Azul eléctrico
        ),
        
        // Página 4: Cerdito rosa (metas)
        // En light: rosa coral
        // En dark: rosa vibrante
        OnboardingPage(
            id: 3,
            title: "Metas\nreales",
            subtitle: "Presupuestos que se sienten alcanzables, día a día.",
            lottieName: "onboarding_goals",
            glowColorLight: Color(red: 1.0, green: 0.45, blue: 0.55), // Rosa coral
            glowColorDark: Color(red: 1.0, green: 0.55, blue: 0.65)   // Rosa vibrante
        )
    ]
    
    // MARK: - Computed Properties
    
    var currentPage: OnboardingPage {
        pages[currentIndex]
    }
    
    var isFirstPage: Bool {
        currentIndex == 0
    }
    
    var isLastPage: Bool {
        currentIndex == pages.count - 1
    }
    
    // MARK: - Actions
    
    func nextPage() {
        guard !isLastPage else {
            completeOnboarding()
            return
        }
        currentIndex += 1
    }
    
    func previousPage() {
        guard !isFirstPage else { return }
        currentIndex -= 1
    }
    
    func goToPage(_ index: Int) {
        guard index >= 0 && index < pages.count else { return }
        currentIndex = index
    }
    
    func skip() {
        completeOnboarding()
    }
    
    func completeOnboarding() {
        onComplete?()
    }
}
