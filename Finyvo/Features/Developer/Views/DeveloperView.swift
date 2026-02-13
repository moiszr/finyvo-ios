//
//  DeveloperView.swift
//  Finyvo
//
//  Created by Moises Núñez on 02/12/26.
//  Pantalla de desarrollador para gestión de token, pruebas y diagnóstico FX.
//

#if DEBUG
import SwiftUI

// MARK: - Developer View

struct DeveloperView: View {
    @Environment(FXService.self) private var fxService
    @State private var viewModel = DeveloperViewModel()

    var body: some View {
        List {
            // MARK: Token API
            Section {
                tokenStatusRow

                SecureField("Token de API", text: $viewModel.tokenInput)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                HStack(spacing: FSpacing.sm) {
                    FButton("Guardar", variant: .brand, size: .small, isDisabled: viewModel.tokenInput.isEmpty) {
                        viewModel.saveToken(service: fxService)
                    }

                    if viewModel.isTokenSaved {
                        FButton("Eliminar", variant: .ghost, size: .small) {
                            viewModel.clearToken(service: fxService)
                        }
                    }
                }
            } header: {
                Text("Token API")
            } footer: {
                Text("El token se almacena de forma segura en el Keychain del dispositivo.")
            }

            // MARK: Estado FX
            Section("Estado FX") {
                HStack {
                    Text("Estado")
                    Spacer()
                    FXStatusBadge()
                }

                if let rates = fxService.currentRates {
                    LabeledContent("Base", value: rates.base)
                    LabeledContent("Fuente", value: rates.source)
                    LabeledContent("Estimado", value: rates.isEstimated ? "Sí" : "No")
                    LabeledContent("Monedas", value: "\(rates.rates.count)")
                    LabeledContent("Antigüedad", value: formatAge(rates.age))
                }

                if fxService.isCircuitOpen {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(FColors.danger)
                        Text("Circuit breaker abierto")
                            .foregroundStyle(FColors.danger)
                    }
                }

                if let error = fxService.lastError {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(FColors.danger)
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundStyle(FColors.danger)
                    }
                }
            }

            // MARK: Probador de Endpoints
            Section("Probador de Endpoints") {
                EndpointTesterView(viewModel: viewModel, fxService: fxService)
            }

            // MARK: Cache
            Section {
                LabeledContent("Entradas en memoria", value: "\(viewModel.memoryCacheCount)")
                LabeledContent("Entradas en disco", value: "\(viewModel.diskCacheCount)")

                FButton("Limpiar Cache", variant: .ghost, size: .small, icon: "trash") {
                    Task {
                        await viewModel.clearCache(service: fxService)
                    }
                }
            } header: {
                Text("Cache")
            }

            // MARK: Circuit Breaker
            Section {
                LabeledContent("Estado", value: fxService.isCircuitOpen ? "Abierto" : "Cerrado")
                LabeledContent("Fallos consecutivos", value: "\(fxService.consecutiveAuthFailures)")

                if fxService.isCircuitOpen {
                    FButton("Resetear Circuit Breaker", variant: .secondary, size: .small, icon: "arrow.counterclockwise") {
                        viewModel.resetCircuit(service: fxService)
                    }
                }
            } header: {
                Text("Circuit Breaker")
            }

            // MARK: Info
            Section("Info") {
                LabeledContent("Base URL", value: AppConfig.FinyvoRate.baseURL)
                LabeledContent("Cache TTL (latest)", value: "\(Int(AppConfig.FinyvoRate.latestCacheTTL / 3600))h")
                LabeledContent("Cache TTL (symbols)", value: "\(Int(AppConfig.FinyvoRate.symbolsCacheTTL / 86400))d")
                LabeledContent("Max reintentos", value: "\(AppConfig.FinyvoRate.maxRetryAttempts)")
            }
        }
        .navigationTitle("Desarrollador")
        .task {
            await viewModel.refreshCacheInfo(service: fxService)
        }
    }

    // MARK: - Token Status Row

    private var tokenStatusRow: some View {
        HStack {
            Image(systemName: viewModel.isTokenSaved ? "checkmark.shield.fill" : "xmark.shield.fill")
                .foregroundStyle(viewModel.isTokenSaved ? FColors.success : FColors.danger)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.isTokenSaved ? "Token configurado" : "Sin token")
                    .font(.subheadline.weight(.medium))

                if viewModel.isTokenSaved {
                    Text(viewModel.maskedToken)
                        .font(.caption)
                        .foregroundStyle(FColors.textSecondary)
                        .fontDesign(.monospaced)
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatAge(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return "< 1 min"
        } else if seconds < 3600 {
            return "\(Int(seconds / 60)) min"
        } else {
            return "\(Int(seconds / 3600))h \(Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60))m"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DeveloperView()
    }
    .environment(FXService())
}
#endif
