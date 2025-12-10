//
//  FinyvoApp.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/5/25.
//

import SwiftUI

@main
struct FinyvoApp: App {
    
    // Estado global de la app - se crea una sola vez
    @State private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            AppRouter()
                // Inyectamos el appState en el environment
                // Cualquier vista hija puede accederlo con @Environment(AppState.self)
                .environment(appState)
        }
    }
}
