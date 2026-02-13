//
//  Constants.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/24/25.
//  Updated on 01/09/26 - Centralized timing constants
//  Updated on 01/17/26 - Added shortMonthYear format
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
        
        /// Spring para cards expandibles
        static let cardSpring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        
        /// Spring para selección de items
        static let selectionSpring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        
        /// Ease out para entradas
        static let easeOut = SwiftUI.Animation.easeOut(duration: 0.25)
        
        /// Ease in out para transiciones
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.3)
        
        /// Para charts y gráficos
        static let chartSpring = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.75)
        
        /// Para transiciones de pasos en flujos
        static let stepTransition = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2)
        
        /// Para botones y controles interactivos
        static let buttonSpring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.8)
        
        /// Para contenido numérico que cambia (balances, contadores)
        static let numericTransition = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.15)
    }
    
    // MARK: - Timing (for Task.sleep delays)
    
    enum Timing {
        /// Delay para auto-focus en inputs después de transición
        static let focusDelay: Duration = .milliseconds(150)
        
        /// Delay para focus en inputs con keyboard (más largo para sheet/modal)
        static let keyboardFocusDelay: Duration = .milliseconds(300)
        
        /// Delay para scroll después de expandir contenido
        static let scrollDelay: Duration = .milliseconds(150)
        
        /// Delay para scroll cuando se expande un card (más largo para esperar animación)
        static let expandedCardScrollDelay: Duration = .milliseconds(250)
        
        /// Delay para el segundo scroll (nudge) que compensa el teclado
        static let scrollNudgeDelay: Duration = .milliseconds(90)
        
        /// Delay para limpiar estado después de animación de dismiss
        static let dismissCleanupDelay: Double = 0.4
        
        /// Delay mínimo para mostrar loading states (evita flash)
        static let minLoadingDisplay: Duration = .milliseconds(300)
        
        /// Debounce para búsqueda en tiempo real
        static let searchDebounce: Duration = .milliseconds(300)
        
        /// Debounce para validación de inputs
        static let inputValidationDebounce: Duration = .milliseconds(200)

        /// Debounce para conversión de moneda en tiempo real
        static let fxConversionDebounce: Duration = .milliseconds(500)
    }
    
    // MARK: - Layout
    
    enum Layout {
        /// Padding extra en safe area cuando el teclado está activo
        static let keyboardSafeAreaPadding: CGFloat = 12
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
        static let fxAPIToken = "fxAPIToken"
        static let fxLastFetchDate = "fxLastFetchDate"
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

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(Constants.Animation.quickSpring, value: configuration.isPressed)
    }
}
