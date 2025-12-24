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
        static let currencyCode = "DOP"
        
        /// Día de inicio del mes fiscal (1-28)
        static let fiscalMonthStartDay = 1
        
        /// Días de anticipación para recordatorio de suscripción
        static let subscriptionReminderDays = 3
        
        /// Porcentaje de alerta de presupuesto
        static let budgetAlertPercentage = 0.8 // 80%
        
        /// Locale por defecto para formateo
        static let localeIdentifier = "es_DO"
    }
    
    // MARK: - Supabase
    
    enum Supabase {
        static let url = "https://your-project.supabase.co"
        static let anonKey = "your-anon-key-here"
    }
}

// MARK: - Currency Model

/// Representa una moneda con toda su información de formateo.
struct Currency: Identifiable, Hashable, Codable {
    let code: String           // ISO 4217: "USD", "EUR", "DOP"
    let symbol: String         // "$", "€", "RD$"
    let name: String           // "Dólar Estadounidense"
    let namePlural: String     // "Dólares Estadounidenses"
    let decimalDigits: Int     // 2 para mayoría, 0 para JPY, etc.
    let symbolPosition: SymbolPosition
    let groupingSeparator: String  // "," o "."
    let decimalSeparator: String   // "." o ","
    let flag: String           // Emoji de bandera "🇺🇸"
    
    var id: String { code }
    
    enum SymbolPosition: String, Codable {
        case before  // $100
        case after   // 100€
    }
    
    /// Formatea un valor Double a String con el formato de esta moneda.
    ///
    /// - Parameters:
    ///   - value: Valor a formatear
    ///   - showSymbol: Si debe incluir el símbolo (default: true)
    ///   - compact: Si debe usar formato compacto K/M (default: false)
    /// - Returns: String formateado
    func format(_ value: Double, showSymbol: Bool = true, compact: Bool = false) -> String {
        if compact {
            return formatCompact(value, showSymbol: showSymbol)
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimalDigits
        formatter.maximumFractionDigits = decimalDigits
        formatter.groupingSeparator = groupingSeparator
        formatter.decimalSeparator = decimalSeparator
        
        let formattedNumber = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.\(decimalDigits)f", value)
        
        guard showSymbol else { return formattedNumber }
        
        switch symbolPosition {
        case .before:
            return "\(symbol)\(formattedNumber)"
        case .after:
            return "\(formattedNumber) \(symbol)"
        }
    }
    
    /// Formatea en formato compacto (1.5K, 2.3M)
    private func formatCompact(_ value: Double, showSymbol: Bool) -> String {
        let absValue = abs(value)
        let sign = value < 0 ? "-" : ""
        
        let (number, suffix): (Double, String) = {
            if absValue >= 1_000_000_000 {
                return (absValue / 1_000_000_000, "B")
            } else if absValue >= 1_000_000 {
                return (absValue / 1_000_000, "M")
            } else if absValue >= 1_000 {
                return (absValue / 1_000, "K")
            } else {
                return (absValue, "")
            }
        }()
        
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = number >= 10 ? 0 : 1
        formatter.minimumFractionDigits = 0
        
        let formattedNumber = formatter.string(from: NSNumber(value: number)) ?? String(format: "%.1f", number)
        
        guard showSymbol else { return "\(sign)\(formattedNumber)\(suffix)" }
        
        switch symbolPosition {
        case .before:
            return "\(sign)\(symbol)\(formattedNumber)\(suffix)"
        case .after:
            return "\(sign)\(formattedNumber)\(suffix) \(symbol)"
        }
    }
    
    /// Parsea un string de input a Double.
    ///
    /// - Parameter input: String del usuario (puede tener separadores locales)
    /// - Returns: Double o nil si no es válido
    func parse(_ input: String) -> Double? {
        var normalized = input
            .replacingOccurrences(of: symbol, with: "")
            .replacingOccurrences(of: groupingSeparator, with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        // Normalizar separador decimal a "."
        if decimalSeparator != "." {
            normalized = normalized.replacingOccurrences(of: decimalSeparator, with: ".")
        }
        
        return Double(normalized)
    }
}

// MARK: - Currency Catalog

/// Catálogo completo de monedas mundiales.
enum CurrencyConfig {
    
    // MARK: - All Currencies
    
    /// Catálogo completo de monedas soportadas.
    static let all: [Currency] = [
        // 🌎 América
        Currency(code: "DOP", symbol: "RD$", name: "Peso Dominicano", namePlural: "Pesos Dominicanos", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇩🇴"),
        Currency(code: "USD", symbol: "$", name: "Dólar Estadounidense", namePlural: "Dólares Estadounidenses", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇺🇸"),
        Currency(code: "MXN", symbol: "$", name: "Peso Mexicano", namePlural: "Pesos Mexicanos", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇲🇽"),
        Currency(code: "COP", symbol: "$", name: "Peso Colombiano", namePlural: "Pesos Colombianos", decimalDigits: 0, symbolPosition: .before, groupingSeparator: ".", decimalSeparator: ",", flag: "🇨🇴"),
        Currency(code: "ARS", symbol: "$", name: "Peso Argentino", namePlural: "Pesos Argentinos", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ".", decimalSeparator: ",", flag: "🇦🇷"),
        Currency(code: "CLP", symbol: "$", name: "Peso Chileno", namePlural: "Pesos Chilenos", decimalDigits: 0, symbolPosition: .before, groupingSeparator: ".", decimalSeparator: ",", flag: "🇨🇱"),
        Currency(code: "PEN", symbol: "S/", name: "Sol Peruano", namePlural: "Soles Peruanos", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇵🇪"),
        Currency(code: "BRL", symbol: "R$", name: "Real Brasileño", namePlural: "Reales Brasileños", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ".", decimalSeparator: ",", flag: "🇧🇷"),
        Currency(code: "VES", symbol: "Bs", name: "Bolívar Venezolano", namePlural: "Bolívares Venezolanos", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ".", decimalSeparator: ",", flag: "🇻🇪"),
        Currency(code: "UYU", symbol: "$U", name: "Peso Uruguayo", namePlural: "Pesos Uruguayos", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ".", decimalSeparator: ",", flag: "🇺🇾"),
        Currency(code: "BOB", symbol: "Bs", name: "Boliviano", namePlural: "Bolivianos", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇧🇴"),
        Currency(code: "PYG", symbol: "₲", name: "Guaraní Paraguayo", namePlural: "Guaraníes Paraguayos", decimalDigits: 0, symbolPosition: .before, groupingSeparator: ".", decimalSeparator: ",", flag: "🇵🇾"),
        Currency(code: "GTQ", symbol: "Q", name: "Quetzal Guatemalteco", namePlural: "Quetzales Guatemaltecos", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇬🇹"),
        Currency(code: "HNL", symbol: "L", name: "Lempira Hondureño", namePlural: "Lempiras Hondureños", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇭🇳"),
        Currency(code: "NIO", symbol: "C$", name: "Córdoba Nicaragüense", namePlural: "Córdobas Nicaragüenses", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇳🇮"),
        Currency(code: "CRC", symbol: "₡", name: "Colón Costarricense", namePlural: "Colones Costarricenses", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ".", decimalSeparator: ",", flag: "🇨🇷"),
        Currency(code: "PAB", symbol: "B/.", name: "Balboa Panameño", namePlural: "Balboas Panameños", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇵🇦"),
        Currency(code: "CAD", symbol: "CA$", name: "Dólar Canadiense", namePlural: "Dólares Canadienses", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇨🇦"),
        Currency(code: "CUP", symbol: "$", name: "Peso Cubano", namePlural: "Pesos Cubanos", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇨🇺"),
        Currency(code: "JMD", symbol: "J$", name: "Dólar Jamaiquino", namePlural: "Dólares Jamaiquinos", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇯🇲"),
        Currency(code: "HTG", symbol: "G", name: "Gourde Haitiano", namePlural: "Gourdes Haitianos", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇭🇹"),
        
        // 🌍 Europa
        Currency(code: "EUR", symbol: "€", name: "Euro", namePlural: "Euros", decimalDigits: 2, symbolPosition: .after, groupingSeparator: ".", decimalSeparator: ",", flag: "🇪🇺"),
        Currency(code: "GBP", symbol: "£", name: "Libra Esterlina", namePlural: "Libras Esterlinas", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇬🇧"),
        Currency(code: "CHF", symbol: "CHF", name: "Franco Suizo", namePlural: "Francos Suizos", decimalDigits: 2, symbolPosition: .before, groupingSeparator: "'", decimalSeparator: ".", flag: "🇨🇭"),
        Currency(code: "SEK", symbol: "kr", name: "Corona Sueca", namePlural: "Coronas Suecas", decimalDigits: 2, symbolPosition: .after, groupingSeparator: " ", decimalSeparator: ",", flag: "🇸🇪"),
        Currency(code: "NOK", symbol: "kr", name: "Corona Noruega", namePlural: "Coronas Noruegas", decimalDigits: 2, symbolPosition: .after, groupingSeparator: " ", decimalSeparator: ",", flag: "🇳🇴"),
        Currency(code: "DKK", symbol: "kr", name: "Corona Danesa", namePlural: "Coronas Danesas", decimalDigits: 2, symbolPosition: .after, groupingSeparator: ".", decimalSeparator: ",", flag: "🇩🇰"),
        Currency(code: "PLN", symbol: "zł", name: "Zloty Polaco", namePlural: "Zlotys Polacos", decimalDigits: 2, symbolPosition: .after, groupingSeparator: " ", decimalSeparator: ",", flag: "🇵🇱"),
        Currency(code: "CZK", symbol: "Kč", name: "Corona Checa", namePlural: "Coronas Checas", decimalDigits: 2, symbolPosition: .after, groupingSeparator: " ", decimalSeparator: ",", flag: "🇨🇿"),
        Currency(code: "HUF", symbol: "Ft", name: "Florín Húngaro", namePlural: "Florines Húngaros", decimalDigits: 0, symbolPosition: .after, groupingSeparator: " ", decimalSeparator: ",", flag: "🇭🇺"),
        Currency(code: "RON", symbol: "lei", name: "Leu Rumano", namePlural: "Lei Rumanos", decimalDigits: 2, symbolPosition: .after, groupingSeparator: ".", decimalSeparator: ",", flag: "🇷🇴"),
        Currency(code: "BGN", symbol: "лв", name: "Lev Búlgaro", namePlural: "Leva Búlgaros", decimalDigits: 2, symbolPosition: .after, groupingSeparator: " ", decimalSeparator: ",", flag: "🇧🇬"),
        Currency(code: "RUB", symbol: "₽", name: "Rublo Ruso", namePlural: "Rublos Rusos", decimalDigits: 2, symbolPosition: .after, groupingSeparator: " ", decimalSeparator: ",", flag: "🇷🇺"),
        Currency(code: "UAH", symbol: "₴", name: "Grivna Ucraniana", namePlural: "Grivnas Ucranianas", decimalDigits: 2, symbolPosition: .after, groupingSeparator: " ", decimalSeparator: ",", flag: "🇺🇦"),
        Currency(code: "TRY", symbol: "₺", name: "Lira Turca", namePlural: "Liras Turcas", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ".", decimalSeparator: ",", flag: "🇹🇷"),
        
        // 🌏 Asia
        Currency(code: "JPY", symbol: "¥", name: "Yen Japonés", namePlural: "Yenes Japoneses", decimalDigits: 0, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇯🇵"),
        Currency(code: "CNY", symbol: "¥", name: "Yuan Chino", namePlural: "Yuanes Chinos", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇨🇳"),
        Currency(code: "KRW", symbol: "₩", name: "Won Surcoreano", namePlural: "Wones Surcoreanos", decimalDigits: 0, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇰🇷"),
        Currency(code: "INR", symbol: "₹", name: "Rupia India", namePlural: "Rupias Indias", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇮🇳"),
        Currency(code: "IDR", symbol: "Rp", name: "Rupia Indonesia", namePlural: "Rupias Indonesias", decimalDigits: 0, symbolPosition: .before, groupingSeparator: ".", decimalSeparator: ",", flag: "🇮🇩"),
        Currency(code: "THB", symbol: "฿", name: "Baht Tailandés", namePlural: "Bahts Tailandeses", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇹🇭"),
        Currency(code: "VND", symbol: "₫", name: "Dong Vietnamita", namePlural: "Dongs Vietnamitas", decimalDigits: 0, symbolPosition: .after, groupingSeparator: ".", decimalSeparator: ",", flag: "🇻🇳"),
        Currency(code: "PHP", symbol: "₱", name: "Peso Filipino", namePlural: "Pesos Filipinos", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇵🇭"),
        Currency(code: "MYR", symbol: "RM", name: "Ringgit Malayo", namePlural: "Ringgits Malayos", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇲🇾"),
        Currency(code: "SGD", symbol: "S$", name: "Dólar Singapurense", namePlural: "Dólares Singapurenses", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇸🇬"),
        Currency(code: "HKD", symbol: "HK$", name: "Dólar de Hong Kong", namePlural: "Dólares de Hong Kong", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇭🇰"),
        Currency(code: "TWD", symbol: "NT$", name: "Dólar Taiwanés", namePlural: "Dólares Taiwaneses", decimalDigits: 0, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇹🇼"),
        Currency(code: "PKR", symbol: "₨", name: "Rupia Pakistaní", namePlural: "Rupias Pakistaníes", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇵🇰"),
        Currency(code: "BDT", symbol: "৳", name: "Taka de Bangladés", namePlural: "Takas de Bangladés", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇧🇩"),
        
        // 🌍 Medio Oriente
        Currency(code: "AED", symbol: "د.إ", name: "Dírham de EAU", namePlural: "Dírhams de EAU", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇦🇪"),
        Currency(code: "SAR", symbol: "﷼", name: "Riyal Saudí", namePlural: "Riyales Saudíes", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇸🇦"),
        Currency(code: "ILS", symbol: "₪", name: "Nuevo Séquel Israelí", namePlural: "Nuevos Séqueles Israelíes", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇮🇱"),
        Currency(code: "QAR", symbol: "﷼", name: "Riyal Catarí", namePlural: "Riyales Cataríes", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇶🇦"),
        Currency(code: "KWD", symbol: "د.ك", name: "Dinar Kuwaití", namePlural: "Dinares Kuwaitíes", decimalDigits: 3, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇰🇼"),
        Currency(code: "BHD", symbol: "BD", name: "Dinar Bareiní", namePlural: "Dinares Bareiníes", decimalDigits: 3, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇧🇭"),
        Currency(code: "OMR", symbol: "﷼", name: "Rial Omaní", namePlural: "Riales Omaníes", decimalDigits: 3, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇴🇲"),
        Currency(code: "JOD", symbol: "د.أ", name: "Dinar Jordano", namePlural: "Dinares Jordanos", decimalDigits: 3, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇯🇴"),
        Currency(code: "EGP", symbol: "£", name: "Libra Egipcia", namePlural: "Libras Egipcias", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇪🇬"),
        
        // 🌍 África
        Currency(code: "ZAR", symbol: "R", name: "Rand Sudafricano", namePlural: "Rands Sudafricanos", decimalDigits: 2, symbolPosition: .before, groupingSeparator: " ", decimalSeparator: ",", flag: "🇿🇦"),
        Currency(code: "NGN", symbol: "₦", name: "Naira Nigeriano", namePlural: "Nairas Nigerianos", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇳🇬"),
        Currency(code: "KES", symbol: "KSh", name: "Chelín Keniano", namePlural: "Chelines Kenianos", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇰🇪"),
        Currency(code: "MAD", symbol: "د.م.", name: "Dírham Marroquí", namePlural: "Dírhams Marroquíes", decimalDigits: 2, symbolPosition: .after, groupingSeparator: " ", decimalSeparator: ",", flag: "🇲🇦"),
        Currency(code: "GHS", symbol: "₵", name: "Cedi Ghanés", namePlural: "Cedis Ghaneses", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇬🇭"),
        Currency(code: "TZS", symbol: "TSh", name: "Chelín Tanzano", namePlural: "Chelines Tanzanos", decimalDigits: 0, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇹🇿"),
        Currency(code: "UGX", symbol: "USh", name: "Chelín Ugandés", namePlural: "Chelines Ugandeses", decimalDigits: 0, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇺🇬"),
        
        // 🌏 Oceanía
        Currency(code: "AUD", symbol: "A$", name: "Dólar Australiano", namePlural: "Dólares Australianos", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇦🇺"),
        Currency(code: "NZD", symbol: "NZ$", name: "Dólar Neozelandés", namePlural: "Dólares Neozelandeses", decimalDigits: 2, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🇳🇿"),
        
        // 🪙 Crypto (opcional, para futuro)
        // Currency(code: "BTC", symbol: "₿", name: "Bitcoin", namePlural: "Bitcoins", decimalDigits: 8, symbolPosition: .before, groupingSeparator: ",", decimalSeparator: ".", flag: "🪙"),
    ]
    
    // MARK: - Quick Access
    
    /// Monedas más populares (para mostrar primero en pickers)
    static let popular: [Currency] = [
        currency(for: "DOP")!,
        currency(for: "USD")!,
        currency(for: "EUR")!,
        currency(for: "MXN")!,
        currency(for: "COP")!,
        currency(for: "ARS")!,
        currency(for: "BRL")!,
        currency(for: "GBP")!,
    ]
    
    /// Monedas latinoamericanas
    static let latinAmerica: [Currency] = all.filter { currency in
        ["DOP", "USD", "MXN", "COP", "ARS", "CLP", "PEN", "BRL", "VES", "UYU", "BOB", "PYG", "GTQ", "HNL", "NIO", "CRC", "PAB", "CUP"].contains(currency.code)
    }
    
    // MARK: - Lookup Functions
    
    /// Obtiene una moneda por su código ISO.
    ///
    /// - Parameter code: Código ISO 4217 (ej: "USD", "EUR")
    /// - Returns: Currency o nil si no existe
    static func currency(for code: String) -> Currency? {
        all.first { $0.code.uppercased() == code.uppercased() }
    }
    
    /// Obtiene la moneda por defecto configurada en AppConfig.
    static var defaultCurrency: Currency {
        currency(for: AppConfig.Defaults.currencyCode) ?? all.first!
    }
    
    /// Obtiene el símbolo para un código de moneda.
    ///
    /// - Parameter code: Código ISO de la moneda
    /// - Returns: Símbolo o el código si no existe
    static func symbol(for code: String) -> String {
        currency(for: code)?.symbol ?? code
    }
    
    /// Obtiene el nombre para un código de moneda.
    ///
    /// - Parameter code: Código ISO de la moneda
    /// - Returns: Nombre o el código si no existe
    static func name(for code: String) -> String {
        currency(for: code)?.name ?? code
    }
    
    /// Formatea un valor con la moneda especificada.
    ///
    /// - Parameters:
    ///   - value: Valor a formatear
    ///   - code: Código de moneda (default: moneda por defecto)
    ///   - compact: Usar formato compacto K/M
    /// - Returns: String formateado
    static func format(_ value: Double, code: String? = nil, compact: Bool = false) -> String {
        let curr = currency(for: code ?? AppConfig.Defaults.currencyCode) ?? defaultCurrency
        return curr.format(value, compact: compact)
    }
    
    // MARK: - Grouping by Region
    
    /// Agrupa las monedas por región para UI.
    static var groupedByRegion: [(region: String, currencies: [Currency])] {
        [
            ("América Latina", latinAmerica),
            ("Norteamérica", all.filter { ["USD", "CAD"].contains($0.code) }),
            ("Europa", all.filter { ["EUR", "GBP", "CHF", "SEK", "NOK", "DKK", "PLN", "CZK", "HUF", "RON", "BGN", "RUB", "UAH", "TRY"].contains($0.code) }),
            ("Asia", all.filter { ["JPY", "CNY", "KRW", "INR", "IDR", "THB", "VND", "PHP", "MYR", "SGD", "HKD", "TWD", "PKR", "BDT"].contains($0.code) }),
            ("Medio Oriente", all.filter { ["AED", "SAR", "ILS", "QAR", "KWD", "BHD", "OMR", "JOD", "EGP"].contains($0.code) }),
            ("África", all.filter { ["ZAR", "NGN", "KES", "MAD", "GHS", "TZS", "UGX"].contains($0.code) }),
            ("Oceanía", all.filter { ["AUD", "NZD"].contains($0.code) }),
        ]
    }
}

// MARK: - Double Extension for Currency Formatting

extension Double {
    
    /// Formatea como moneda usando la configuración por defecto.
    ///
    /// - Parameter code: Código de moneda opcional (usa default si nil)
    /// - Returns: String formateado (ej: "RD$1,500.00")
    func asCurrency(code: String? = nil) -> String {
        CurrencyConfig.format(self, code: code)
    }
    
    /// Formatea como moneda compacta.
    ///
    /// - Parameter code: Código de moneda opcional
    /// - Returns: String compacto (ej: "RD$1.5K")
    func asCompactCurrency(code: String? = nil) -> String {
        CurrencyConfig.format(self, code: code, compact: true)
    }
    
    /// Formatea como porcentaje.
    ///
    /// - Returns: String (ej: "75%")
    func asPercentage() -> String {
        "\(Int(self * 100))%"
    }
}
