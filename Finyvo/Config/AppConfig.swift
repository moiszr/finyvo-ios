//
//  AppConfig.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/24/25.
//  Configuración global de la aplicación.
//

import Foundation

// MARK: - App Configuration

enum AppConfig {
    
    // MARK: - App Info
    
    static let appName = "Finyvo"
    
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // MARK: - Feature Flags
    
    /// Habilita el módulo de suscripciones recurrentes
    static let isSubscriptionsEnabled = true
    
    /// Habilita el módulo de metas de ahorro
    static let isGoalsEnabled = true
    
    /// Habilita analytics y reportes
    static let isAnalyticsEnabled = true
    
    /// Habilita sincronización con Supabase
    static let isSyncEnabled = false
    
    /// Habilita notificaciones push
    static let isNotificationsEnabled = true
    
    /// Habilita modo debug (logs extra, herramientas dev)
    static var isDebugMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Limits
    
    enum Limits {
        /// Máximo de categorías por tipo (income/expense)
        static let maxCategoriesPerType = 50
        
        /// Máximo de subcategorías por categoría
        static let maxSubcategoriesPerCategory = 10
        
        /// Máximo de tags por transacción
        static let maxTagsPerTransaction = 10
        
        /// Máximo de billeteras
        static let maxWallets = 20
        
        /// Máximo de metas activas
        static let maxActiveGoals = 10
        
        /// Máximo de keywords por categoría (auto-categorización)
        static let maxKeywordsPerCategory = 20
        
        /// Longitud máxima de nombre de categoría
        static let maxCategoryNameLength = 30
        
        /// Longitud máxima de nota en transacción
        static let maxTransactionNoteLength = 200
        
        /// Longitud máxima de nombre de tag
        static let maxTagNameLength = 30
        
        /// Longitud mínima de nombre de tag
        static let minTagNameLength = 2
    }
    
    // MARK: - Defaults
    
    enum Defaults {
        /// Código de moneda por defecto
        static let currencyCode = "USD"
        
        /// Día de inicio del mes fiscal (1-28)
        static let fiscalMonthStartDay = 1
        
        /// Días de anticipación para recordatorio de suscripción
        static let subscriptionReminderDays = 3
        
        /// Porcentaje de alerta de presupuesto
        static let budgetAlertPercentage = 0.8 // 80%
        
        /// Locale por defecto para formateo
        static let localeIdentifier = "es_US"
    }
    
    // MARK: - Supabase
    
    enum Supabase {
        static let url = "https://your-project.supabase.co"
        static let anonKey = "your-anon-key-here"
    }
}
