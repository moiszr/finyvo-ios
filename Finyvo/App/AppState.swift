//
//  AppState.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/5/25.
//

import SwiftUI
import Observation

@Observable
final class AppState {
    
    // MARK: - Persisted Properties
    
    /// Si el usuario ya completó el onboarding (persiste entre sesiones)
    var hasCompletedOnboarding: Bool {
        get {
            access(keyPath: \.hasCompletedOnboarding)
            return UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        }
        set {
            withMutation(keyPath: \.hasCompletedOnboarding) {
                UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding")
            }
        }
    }
    
    // MARK: - State Properties
    
    /// Estado de carga inicial
    var isLoading: Bool = true
    
    /// Si el usuario está autenticado
    var isAuthenticated: Bool = false
    
    /// ID del usuario actual
    var currentUserId: String? = nil
    
    /// Moneda preferida (persiste entre sesiones)
    var preferredCurrencyCode: String {
        get {
            access(keyPath: \.preferredCurrencyCode)
            return UserDefaults.standard.string(forKey: Constants.StorageKeys.preferredCurrencyCode)
                ?? AppConfig.Defaults.currencyCode
        }
        set {
            withMutation(keyPath: \.preferredCurrencyCode) {
                UserDefaults.standard.set(newValue, forKey: Constants.StorageKeys.preferredCurrencyCode)
            }
        }
    }
    
    // MARK: - Init
    
    init() {
        // Simular carga inicial
        Task {
            try? await Task.sleep(for: .milliseconds(800))
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Actions
    
    /// Marcar onboarding como completado
    func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.3)) {
            hasCompletedOnboarding = true
        }
    }
    
    /// Resetear onboarding (para testing)
    func resetOnboarding() {
        hasCompletedOnboarding = false
    }
    
    /// Simular sign in
    func signIn(userId: String) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentUserId = userId
            isAuthenticated = true
        }
    }
    
    /// Sign out
    func signOut() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentUserId = nil
            isAuthenticated = false
        }
    }
}
