//
//  FinyvoApp.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/5/25.
//

import SwiftUI
import SwiftData

@main
struct FinyvoApp: App {
    
    // Estado global de la app - se crea una sola vez
    @State private var appState = AppState()
    
    /// Contenedor compartido de SwiftData
    ///
    /// ⚠️ IMPORTANTE: Agregar aquí todos los modelos @Model que uses
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Category.self,
            Tag.self,          // ← AGREGADO: Modelo de etiquetas
            // Wallet.self,    // ← Agregar cuando crees el modelo
            // Transaction.self, // ← Agregar cuando crees el modelo
        ])
        
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Error al crear ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environment(appState)
                .modelContainer(sharedModelContainer)
                .environment(\.locale, Locale(identifier: AppConfig.Defaults.localeIdentifier))
        }
    }
}
