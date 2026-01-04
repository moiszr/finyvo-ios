//
//  FInput.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/20/25.
//  Updated for maxLength support and keyboard toolbar.
//

import SwiftUI

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
    
    // Personalización Visual
    var textAlignment: TextAlignment = .leading
    var cornerRadius: CGFloat = 18 // Aumentado ligeramente
    var textFont: Font = .body
    
    // NUEVO: Límite de caracteres
    var maxLength: Int? = nil
    
    // NUEVO: Mostrar toolbar con botón Listo (para teclados numéricos)
    var showDoneButton: Bool = false
    
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
    
    // Init actualizado
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
        textAlignment: TextAlignment = .leading,
        cornerRadius: CGFloat = 18,
        textFont: Font = .body,
        maxLength: Int? = nil,
        showDoneButton: Bool = false,
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
        
        self.textAlignment = textAlignment
        self.cornerRadius = cornerRadius
        self.textFont = textFont
        self.maxLength = maxLength
        self.showDoneButton = showDoneButton

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
                        .font(textFont.weight(.semibold))
                        .foregroundStyle(FColors.textSecondary)
                }
                
                // TextField
                TextField(placeholder, text: $text)
                    .font(textFont)
                    .foregroundStyle(textColor)
                    .tint(FColors.brand)
                    .multilineTextAlignment(textAlignment)
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
                    .onChange(of: text) { oldValue, newValue in
                        // Aplicar límite de caracteres si está definido
                        if let maxLength = maxLength, newValue.count > maxLength {
                            text = String(newValue.prefix(maxLength))
                        }
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
                            .frame(width: 44, height: 44)
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
        .toolbar {
            // Toolbar para teclados numéricos (solo si showDoneButton es true)
            if showDoneButton && isFocusedInternal {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") {
                        isFocusedInternal = false
                        onSubmit?()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(FColors.brand)
                }
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

// MARK: - Modifiers Extension
extension FInput {
    func numeric() -> FInput {
        var copy = self
        copy.keyboardType = .decimalPad
        copy.autocapitalization = .never
        copy.autocorrection = false
        copy.showDoneButton = true
        return copy
    }
    
    func keywords() -> FInput {
        var copy = self
        copy.keyboardType = .default
        copy.autocapitalization = .never
        copy.autocorrection = false
        return copy
    }
    
    func textAlignment(_ alignment: TextAlignment) -> FInput {
        var copy = self
        copy.textAlignment = alignment
        return copy
    }
    
    func pill() -> FInput {
        var copy = self
        copy.cornerRadius = 26
        return copy
    }
    
    func font(_ font: Font) -> FInput {
        var copy = self
        copy.textFont = font
        return copy
    }
    
    func maxLength(_ length: Int) -> FInput {
        var copy = self
        copy.maxLength = length
        return copy
    }
    
    func withDoneButton(_ show: Bool = true) -> FInput {
        var copy = self
        copy.showDoneButton = show
        return copy
    }
}
