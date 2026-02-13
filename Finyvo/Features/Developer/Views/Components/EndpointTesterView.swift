//
//  EndpointTesterView.swift
//  Finyvo
//
//  Created by Moises Núñez on 02/12/26.
//  Componente para probar endpoints de FinyvoRate API.
//

#if DEBUG
import SwiftUI

// MARK: - Endpoint Tester View

struct EndpointTesterView: View {
    @Bindable var viewModel: DeveloperViewModel
    let fxService: FXService

    var body: some View {
        VStack(alignment: .leading, spacing: FSpacing.lg) {
            // Selector de endpoint
            Picker("Endpoint", selection: $viewModel.selectedEndpoint) {
                ForEach(TestableEndpoint.allCases) { endpoint in
                    Text(endpoint.displayName).tag(endpoint)
                }
            }
            .pickerStyle(.menu)

            // Campos dinámicos según endpoint
            parameterFields

            // Botón de prueba
            FButton(
                "Probar",
                variant: .brand,
                size: .medium,
                isFullWidth: true,
                icon: "play.fill",
                isLoading: viewModel.isTesting
            ) {
                Task {
                    await viewModel.testEndpoint(service: fxService)
                }
            }

            // Resultado
            if !viewModel.testResult.isEmpty {
                resultView
            }
        }
    }

    // MARK: - Parameter Fields

    @ViewBuilder
    private var parameterFields: some View {
        switch viewModel.selectedEndpoint {
        case .health:
            Text("Sin parámetros (endpoint público)")
                .font(.caption)
                .foregroundStyle(FColors.textSecondary)

        case .latest:
            FInput(
                text: $viewModel.testCurrencies,
                placeholder: "EUR,DOP (opcional)",
                icon: "dollarsign.circle"
            )

        case .date:
            FInput(
                text: $viewModel.testDate,
                placeholder: "2026-02-01",
                icon: "calendar"
            )
            FInput(
                text: $viewModel.testCurrencies,
                placeholder: "EUR,DOP (opcional)",
                icon: "dollarsign.circle"
            )

        case .timeframe:
            FInput(
                text: $viewModel.testStartDate,
                placeholder: "Inicio (2026-02-01)",
                icon: "calendar"
            )
            FInput(
                text: $viewModel.testEndDate,
                placeholder: "Fin (2026-02-10)",
                icon: "calendar"
            )
            FInput(
                text: $viewModel.testCurrencies,
                placeholder: "EUR,DOP (opcional)",
                icon: "dollarsign.circle"
            )

        case .convert:
            HStack(spacing: FSpacing.sm) {
                FInput(
                    text: $viewModel.testFromCurrency,
                    placeholder: "De (DOP)",
                    icon: "arrow.right"
                )
                FInput(
                    text: $viewModel.testToCurrency,
                    placeholder: "A (USD)",
                    icon: "arrow.left"
                )
            }
            FInput(
                text: $viewModel.testAmount,
                placeholder: "Monto (1000)",
                icon: "number"
            )
            .keyboardType(.decimalPad)
            FInput(
                text: $viewModel.testDate,
                placeholder: "Fecha (opcional)",
                icon: "calendar"
            )

        case .symbols:
            Text("Sin parámetros")
                .font(.caption)
                .foregroundStyle(FColors.textSecondary)
        }
    }

    // MARK: - Result View

    private var resultView: some View {
        VStack(alignment: .leading, spacing: FSpacing.sm) {
            HStack {
                Text("Resultado")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(FColors.textSecondary)

                Spacer()

                if let requestId = viewModel.lastRequestId {
                    Button {
                        viewModel.copyRequestId()
                    } label: {
                        HStack(spacing: 4) {
                            Text("ID: \(String(requestId.prefix(8)))…")
                                .font(.caption2)
                            Image(systemName: "doc.on.doc")
                                .font(.caption2)
                        }
                        .foregroundStyle(FColors.textTertiary)
                    }
                }
            }

            ScrollView {
                Text(viewModel.testResult)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(FColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 300)
            .padding(FSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: FRadius.sm)
                    .fill(FColors.backgroundSecondary)
            )
        }
    }
}
#endif
