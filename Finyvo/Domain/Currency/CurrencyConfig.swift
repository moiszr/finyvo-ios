//
//  CurrencyConfig.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/24/25.
//

import Foundation

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
