//
//  Constants.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/24/25.
//  Constantes globales de la aplicación.
//

import SwiftUI

// MARK: - Constants

enum Constants {
    
    // MARK: - Date Formats
    
    enum DateFormat {
        /// "24 Dic 2025"
        static let display = "d MMM yyyy"
        
        /// "Diciembre 2025"
        static let monthYear = "MMMM yyyy"
        
        /// "Dic 2025"
        static let shortMonthYear = "MMM yyyy"
        
        /// "24 Dic"
        static let dayMonth = "d MMM"
        
        /// "Lunes, 24 de diciembre"
        static let fullDay = "EEEE, d 'de' MMMM"
        
        /// "3:45 PM"
        static let time = "h:mm a"
        
        /// "24/12/2025"
        static let numeric = "dd/MM/yyyy"
        
        /// ISO 8601 para APIs
        static let iso8601 = "yyyy-MM-dd'T'HH:mm:ssZ"
    }
    
    // MARK: - Animations
    
    enum Animation {
        /// Spring estándar para la mayoría de animaciones
        static let defaultSpring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.8)
        
        /// Spring rápido para feedback inmediato
        static let quickSpring = SwiftUI.Animation.spring(response: 0.2, dampingFraction: 0.7)
        
        /// Spring suave para transiciones grandes
        static let smoothSpring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.85)
        
        /// Ease out para entradas
        static let easeOut = SwiftUI.Animation.easeOut(duration: 0.25)
        
        /// Ease in out para transiciones
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.3)
        
        /// Para charts y gráficos
        static let chartSpring = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.75)
    }
    
    // MARK: - Haptics
    
    enum Haptic {
        /// Feedback ligero (selección, toggle)
        @MainActor
        static func light() {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        
        /// Feedback medio (botones importantes)
        @MainActor
        static func medium() {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        
        /// Feedback de éxito
        @MainActor
        static func success() {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        
        /// Feedback de error
        @MainActor
        static func error() {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        
        /// Feedback de advertencia
        @MainActor
        static func warning() {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
        
        /// Feedback de selección
        @MainActor
        static func selection() {
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
    
    // MARK: - Accessibility
    
    enum Accessibility {
        /// Duración mínima para animaciones con Reduce Motion
        static let reducedMotionDuration: Double = 0.01
        
        /// Tamaño mínimo de touch target (44pt según Apple HIG)
        static let minTouchTarget: CGFloat = 44
    }
    
    // MARK: - Storage Keys
    
    enum StorageKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let preferredCurrencyCode = "preferredCurrencyCode"
        static let fiscalMonthStartDay = "fiscalMonthStartDay"
        static let lastSyncDate = "lastSyncDate"
        static let notificationsEnabled = "notificationsEnabled"
    }
    
    // MARK: - Regex Patterns
    
    enum Patterns {
        /// Email válido
        static let email = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        /// Solo números
        static let numbersOnly = "^[0-9]+$"
        
        /// Monto válido (con decimales opcionales)
        static let amount = "^[0-9]+(\\.[0-9]{1,2})?$"
    }
}
