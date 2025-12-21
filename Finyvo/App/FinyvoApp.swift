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
    let sharedModelContainer: ModelContainer = {
        // Si luego agregas más modelos, los pones en el schema
        let schema = Schema([
            Category.self
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
        }
    }
}
