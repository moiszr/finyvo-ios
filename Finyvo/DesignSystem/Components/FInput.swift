//
//  FInput.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/20/25.
//

import SwiftUI

// MARK: - FInput

/// Input premium de Finyvo - minimalista, fluido y elegante.
///
/// ## Características
/// - Diseño pill ultra-redondeado
/// - Animaciones suaves con spring
/// - Soporte para icono leading
/// - Soporte para botón trailing (ej: agregar, limpiar)
/// - Estados: normal, focused, disabled, error
/// - Haptic feedback sutil
/// - Accesibilidad completa
///
/// ## Uso básico
/// ```swift
/// FInput(
///     text: $amount,
///     placeholder: "0",
///     icon: "dollarsign.circle"
/// )
/// ```
///
/// ## Con acción trailing
/// ```swift
/// FInput(
///     text: $keyword,
///     placeholder: "uber eats, rappi",
///     icon: "magnifyingglass",
///     trailingIcon: "plus.circle.fill",
///     trailingAction: { addKeyword() }
/// )
/// ```

struct FInput: View {
    
    // MARK: - Properties
    
    @Binding var text: String
    let placeholder: String
    
    var icon: String? = nil
    var trailingIcon: String? = nil
    var trailingAction: (() -> Void)? = nil
    var showTrailingWhen: TrailingVisibility = .whenNotEmpty
    
    var prefix: String? = nil
    var suffix: String? = nil
    
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .sentences
    var autocorrection: Bool = true
    var submitLabel: SubmitLabel = .done
    
    var isDisabled: Bool = false
    var error: String? = nil
    
    var onSubmit: (() -> Void)? = nil
    var onFocusChange: ((Bool) -> Void)? = nil
    var externalFocus: Binding<Bool>? = nil
    
    var accessibilityTrailingLabel: String? = nil
    
    // MARK: - Trailing Visibility
    
    enum TrailingVisibility {
        case always
        case whenNotEmpty
        case never
    }
    
    // MARK: - Focus State
    
    @FocusState private var isFocusedInternal: Bool
    
    // MARK: - Environment
    
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Constants
    
    private let height: CGFloat = 52
    private let cornerRadius: CGFloat = 16
    
    // MARK: - Computed Properties
    
    private var hasError: Bool {
        error != nil && !error!.isEmpty
    }
    
    private var shouldShowTrailing: Bool {
        guard trailingIcon != nil else { return false }
        
        switch showTrailingWhen {
        case .always:
            return true
        case .whenNotEmpty:
            return !text.isEmpty
        case .never:
            return false
        }
    }
    
    // MARK: - Colors
    
    private var backgroundColor: Color {
        if isDisabled {
            return colorScheme == .dark
                ? Color.white.opacity(0.03)
                : Color.black.opacity(0.02)
        }
        
        return colorScheme == .dark
            ? Color.white.opacity(0.06)
            : Color.black.opacity(0.04)
    }
    
    private var borderColor: Color {
        if hasError {
            return FColors.danger.opacity(0.6)
        }
        
        if isFocusedInternal {
            return FColors.brand.opacity(0.5)
        }
        
        return .clear
    }
    
    private var iconColor: Color {
        if isDisabled {
            return FColors.textTertiary.opacity(0.5)
        }
        
        if isFocusedInternal {
            return FColors.brand
        }
        
        return FColors.textTertiary
    }
    
    private var textColor: Color {
        isDisabled ? FColors.textTertiary : FColors.textPrimary
    }
    
    init(
        text: Binding<String>,
        placeholder: String,
        icon: String? = nil,
        trailingIcon: String? = nil,
        trailingAction: (() -> Void)? = nil,
        showTrailingWhen: TrailingVisibility = .whenNotEmpty,
        accessibilityTrailingLabel: String? = nil,
        prefix: String? = nil,
        suffix: String? = nil,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        autocapitalization: TextInputAutocapitalization = .sentences,
        autocorrection: Bool = true,
        submitLabel: SubmitLabel = .done,
        isDisabled: Bool = false,
        error: String? = nil,
        onSubmit: (() -> Void)? = nil,
        onFocusChange: ((Bool) -> Void)? = nil,
        externalFocus: Binding<Bool>? = nil
    ) {
        self._text = text
        self.placeholder = placeholder

        self.icon = icon
        self.trailingIcon = trailingIcon
        self.trailingAction = trailingAction
        self.showTrailingWhen = showTrailingWhen
        self.accessibilityTrailingLabel = accessibilityTrailingLabel

        self.prefix = prefix
        self.suffix = suffix

        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.autocapitalization = autocapitalization
        self.autocorrection = autocorrection
        self.submitLabel = submitLabel

        self.isDisabled = isDisabled
        self.error = error

        self.onSubmit = onSubmit
        self.onFocusChange = onFocusChange
        self.externalFocus = externalFocus
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Input container
            HStack(spacing: 12) {
                // Leading icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(iconColor)
                        .frame(width: 20)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isFocusedInternal)
                }
                
                // Prefix
                if let prefix = prefix {
                    Text(prefix)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(FColors.textSecondary)
                }
                
                // TextField
                TextField(placeholder, text: $text)
                    .font(.body)
                    .foregroundStyle(textColor)
                    .tint(FColors.brand)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled(!autocorrection)
                    .submitLabel(submitLabel)
                    .focused($isFocusedInternal)
                    .disabled(isDisabled)
                    .onSubmit {
                        onSubmit?()
                        externalFocus?.wrappedValue = false
                    }
                
                // Suffix
                if let suffix = suffix {
                    Text(suffix)
                        .font(.subheadline)
                        .foregroundStyle(FColors.textTertiary)
                }
                
                // Trailing action button
                if shouldShowTrailing, let trailingIcon = trailingIcon {
                    Button {
                        hapticLight()
                        trailingAction?()
                    } label: {
                        Image(systemName: trailingIcon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(FColors.brand)
                            .frame(width: 44, height: 44)      // ✅ área tocable
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(TrailingButtonStyle())
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityLabel(accessibilityTrailingLabel ?? "Acción")
                }
            }
            .padding(.horizontal, 16)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: 1.5)
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isFocusedInternal)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hasError)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: shouldShowTrailing)
            
            // Error message
            if let error = error, !error.isEmpty {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(FColors.danger)
                    .padding(.horizontal, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onChange(of: isFocusedInternal) { _, newValue in
            onFocusChange?(newValue)

            guard let externalFocus else { return }
            if externalFocus.wrappedValue != newValue {
                DispatchQueue.main.async {
                    externalFocus.wrappedValue = newValue
                }
            }
        }
        .onChange(of: externalFocus?.wrappedValue) { _, newValue in
            guard let newValue else { return }
            if newValue != isFocusedInternal {
                isFocusedInternal = newValue
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(placeholder)
        .accessibilityValue(text.isEmpty ? "Vacío" : text)
        .accessibilityHint(error ?? "")
    }
    
    // MARK: - Haptics
    
    private func hapticLight() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Trailing Button Style

private struct TrailingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - FInput Modifiers

extension FInput {
    
    /// Configura el input para entrada numérica/moneda.
    func numeric() -> FInput {
        var copy = self
        copy.keyboardType = .decimalPad
        copy.autocapitalization = .never
        copy.autocorrection = false
        return copy
    }
    
    /// Configura el input para keywords/tags.
    func keywords() -> FInput {
        var copy = self
        copy.keyboardType = .default
        copy.autocapitalization = .never
        copy.autocorrection = false
        return copy
    }
}

// MARK: - FInputLabel

/// Label opcional para acompañar un FInput.
struct FInputLabel: View {
    let text: String
    var icon: String? = nil
    var iconColor: Color = FColors.brand
    
    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(iconColor)
            }
            
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FColors.textSecondary)
        }
    }
}

// MARK: - Previews

#Preview("Basic") {
    VStack(spacing: 24) {
        FInput(
            text: .constant(""),
            placeholder: "Buscar categorías...",
            icon: "magnifyingglass"
        )
        
        FInput(
            text: .constant("5000"),
            placeholder: "0",
            icon: "dollarsign.circle",
            prefix: "RD$",
            suffix: "/ mes"
        )
        .numeric()
        
        FInput(
            text: .constant("uber eats"),
            placeholder: "uber eats, rappi, mcdonald's",
            icon: "magnifyingglass",
            trailingIcon: "plus.circle.fill",
            trailingAction: {}
        )
        .keywords()
    }
    .padding()
}

#Preview("States") {
    VStack(spacing: 24) {
        VStack(alignment: .leading, spacing: 8) {
            FInputLabel(text: "Normal")
            FInput(
                text: .constant(""),
                placeholder: "Placeholder"
            )
        }
        
        VStack(alignment: .leading, spacing: 8) {
            FInputLabel(text: "Con texto")
            FInput(
                text: .constant("Contenido"),
                placeholder: "Placeholder"
            )
        }
        
        VStack(alignment: .leading, spacing: 8) {
            FInputLabel(text: "Disabled")
            FInput(
                text: .constant("Disabled"),
                placeholder: "Placeholder",
                isDisabled: true
            )
        }
        
        VStack(alignment: .leading, spacing: 8) {
            FInputLabel(text: "Con error")
            FInput(
                text: .constant(""),
                placeholder: "Placeholder",
                error: "Este campo es requerido"
            )
        }
    }
    .padding()
}

#Preview("Dark Mode") {
    VStack(spacing: 24) {
        FInput(
            text: .constant(""),
            placeholder: "Buscar...",
            icon: "magnifyingglass"
        )
        
        FInput(
            text: .constant("10000"),
            placeholder: "0",
            prefix: "RD$",
            suffix: "/ mes"
        )
        .numeric()
    }
    .padding()
    .background(FColors.background)
    .preferredColorScheme(.dark)
}
