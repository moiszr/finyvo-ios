//
//  FTextField.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/6/25.
//

import SwiftUI

// MARK: - FTextField
/// Campo de texto premium con floating label animado
/// El label comienza como placeholder y se anima hacia arriba al enfocar

struct FTextField: View {
    
    // MARK: - Properties
    let label: String
    @Binding var text: String
    var helperText: String? = nil
    var errorText: String? = nil
    var isSecure: Bool = false
    var isDisabled: Bool = false
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .sentences
    var submitLabel: SubmitLabel = .done
    var onSubmit: (() -> Void)? = nil
    
    // MARK: - State
    @FocusState private var isFocused: Bool
    @State private var isPasswordVisible: Bool = false
    
    // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Constants
    private let inputHeight: CGFloat = 56
    
    // MARK: - Computed Properties
    
    /// Determina si el label debe estar arriba (floating)
    private var isLabelFloating: Bool {
        isFocused || !text.isEmpty
    }
    
    /// Hay error
    private var hasError: Bool {
        errorText != nil && !errorText!.isEmpty
    }
    
    // MARK: - Colors
    
    private var borderColor: Color {
        if hasError {
            return FColors.danger
        }
        if isFocused {
            return colorScheme == .light ? .black : .white
        }
        return colorScheme == .light
            ? .black.opacity(0.12)
            : .white.opacity(0.12)
    }
    
    private var borderWidth: CGFloat {
        isFocused || hasError ? 1.5 : 1
    }
    
    private var backgroundColor: Color {
        colorScheme == .light
            ? .black.opacity(0.02)
            : .white.opacity(0.04)
    }
    
    private var labelColor: Color {
        if hasError {
            return FColors.danger
        }
        if isLabelFloating {
            return FColors.textSecondary
        }
        return FColors.textTertiary
    }
    
    private var textColor: Color {
        isDisabled
            ? FColors.textTertiary
            : FColors.textPrimary
    }
    
    private var iconColor: Color {
        if isFocused {
            return colorScheme == .light ? .black : .white
        }
        return FColors.textTertiary
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: FSpacing.xs) {
            // Input container
            ZStack(alignment: .leading) {
                // Background + Border (pill style) con animación
                RoundedRectangle(cornerRadius: FRadius.xl)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: FRadius.xl)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                    .frame(height: inputHeight)
                    .animation(.easeOut(duration: 0.2), value: isFocused)
                    .animation(.easeOut(duration: 0.2), value: hasError)
                
                // Content
                HStack(spacing: FSpacing.sm) {
                    // Leading icon
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(iconColor)
                            .frame(width: 24)
                            .animation(.easeOut(duration: 0.2), value: isFocused)
                    }
                    
                    // Label + TextField stack
                    ZStack(alignment: .leading) {
                        // Floating Label
                        Text(label)
                            .font(.system(size: isLabelFloating ? 12 : 16, weight: .regular))
                            .foregroundStyle(labelColor)
                            .offset(y: isLabelFloating ? -10 : 0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isLabelFloating)
                        
                        // TextField
                        Group {
                                if isSecure && !isPasswordVisible {
                                    SecureField("", text: $text)
                                } else {
                                    TextField("", text: $text)
                                }
                            }
                            .keyboardType(keyboardType)
                            .textContentType(textContentType)
                            .textInputAutocapitalization(autocapitalization)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(textColor)
                            .focused($isFocused)
                            .offset(y: isLabelFloating ? 8 : 0)
                            .opacity(isLabelFloating ? 1 : 0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isLabelFloating)
                            .submitLabel(submitLabel)
                            .onSubmit {
                                onSubmit?()
                            }
                            .disabled(isDisabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Trailing: Password toggle
                    if isSecure {
                        Button {
                            isPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundStyle(FColors.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, FSpacing.xl)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isFocused = true
            }
            
            // Helper / Error text
            if let error = errorText, !error.isEmpty {
                Text(error)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(FColors.danger)
                    .padding(.horizontal, FSpacing.lg)
            } else if let helper = helperText, !helper.isEmpty {
                Text(helper)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(FColors.textTertiary)
                    .padding(.horizontal, FSpacing.lg)
            }
        }
    }
}

// MARK: - Previews

#Preview("Login Form") {
    VStack(spacing: FSpacing.lg) {
        PreviewTextField(label: "Email", text: "fdsfsd")
        PreviewTextField(label: "Contraseña", text: "password", isSecure: true)
        
        HStack {
            Spacer()
            Text("¿Olvidaste tu contraseña?")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(FColors.brand)
        }
        .padding(.top, FSpacing.xs)
        
        FButton("Iniciar Sesión", variant: .brand) {
            // action
        }
        .padding(.top, FSpacing.sm)
    }
    .padding(.horizontal, FSpacing.xl)
    .padding(.vertical, FSpacing.xxl)
}

#Preview("All States") {
    ScrollView {
        VStack(spacing: FSpacing.lg) {
            PreviewTextField(label: "Vacío")
            PreviewTextField(label: "Con texto", text: "Moises Núñez")
            PreviewTextField(label: "Contraseña", text: "secreto", isSecure: true)
            PreviewTextField(label: "Con error", errorText: "Este campo es requerido")
            PreviewTextField(label: "Con helper", helperText: "Mínimo 8 caracteres")
            PreviewTextField(label: "Con icono", icon: "envelope")
        }
        .padding()
    }
}

#Preview("Dark Mode") {
    VStack(spacing: FSpacing.lg) {
        PreviewTextField(label: "Email", text: "test@email.com")
        PreviewTextField(label: "Contraseña", isSecure: true)
    }
    .padding()
    .preferredColorScheme(.dark)
}

// MARK: - Preview Helper
private struct PreviewTextField: View {
    let label: String
    var text: String = ""
    var helperText: String? = nil
    var errorText: String? = nil
    var isSecure: Bool = false
    var icon: String? = nil
    
    @State private var inputText: String = ""
    
    init(
        label: String,
        text: String = "",
        helperText: String? = nil,
        errorText: String? = nil,
        isSecure: Bool = false,
        icon: String? = nil
    ) {
        self.label = label
        self.text = text
        self.helperText = helperText
        self.errorText = errorText
        self.isSecure = isSecure
        self.icon = icon
        self._inputText = State(initialValue: text)
    }
    
    var body: some View {
        FTextField(
            label: label,
            text: $inputText,
            helperText: helperText,
            errorText: errorText,
            isSecure: isSecure,
            icon: icon
        )
    }
}
