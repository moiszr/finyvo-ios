//
//  FXStatusBadge.swift
//  Finyvo
//
//  Created by Moises Núñez on 02/12/26.
//  Pill de estado que muestra moneda base, frescura y estado del servicio FX.
//

import SwiftUI

// MARK: - FX Status Badge

struct FXStatusBadge: View {
    @Environment(FXService.self) private var fxService

    var body: some View {
        Button {
            Task {
                Constants.Haptic.light()
                await fxService.fetchLatestRates()
            }
        } label: {
            HStack(spacing: FSpacing.xs) {
                statusDot
                    .animation(Constants.Animation.quickSpring, value: statusColor)

                if let snapshot = fxService.currentRates {
                    Text(snapshot.base)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(FColors.textPrimary)

                    Text(relativeTime(from: snapshot.fetchedAt))
                        .font(.caption2)
                        .foregroundStyle(FColors.textSecondary)
                } else if fxService.isLoading {
                    ProgressView()
                        .controlSize(.mini)
                } else {
                    Text("FX")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(FColors.textSecondary)
                }
            }
            .padding(.horizontal, FSpacing.sm)
            .padding(.vertical, FSpacing.xs)
            .background(
                Capsule()
                    .fill(FColors.backgroundSecondary)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(accessibilityText)
    }

    // MARK: - Status Dot

    private var statusDot: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 6, height: 6)
    }

    private var statusColor: Color {
        if fxService.isCircuitOpen || !fxService.isConfigured {
            return FColors.danger
        }
        if let error = fxService.lastError {
            switch error {
            case .noToken, .circuitOpen:
                return FColors.danger
            default:
                return FColors.warning
            }
        }
        guard let snapshot = fxService.currentRates else {
            return FColors.danger
        }
        if snapshot.isExpired() || snapshot.isEstimated {
            return FColors.warning
        }
        return FColors.success
    }

    // MARK: - Relative Time

    private func relativeTime(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval < 60 {
            return "Ahora"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "Hace \(minutes)m"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "Hace \(hours)h"
        } else {
            let days = Int(interval / 86400)
            return "Hace \(days)d"
        }
    }

    // MARK: - Accessibility

    private var accessibilityText: String {
        if fxService.isCircuitOpen {
            return "Servicio de tasas deshabilitado"
        }
        if !fxService.isConfigured {
            return "Token de API no configurado"
        }
        if let snapshot = fxService.currentRates {
            return "Tasas de \(snapshot.base), \(relativeTime(from: snapshot.fetchedAt)). Toca para actualizar."
        }
        return "Sin datos de tasas. Toca para cargar."
    }
}

// MARK: - Preview

#Preview {
    FXStatusBadge()
        .environment(FXService())
        .padding()
}
