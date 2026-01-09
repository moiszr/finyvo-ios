//
//  FInput.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/20/25.
//  Updated: strict maxLength, optional filters, internal counter, style variants.
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

    // Visual
    var textAlignment: TextAlignment = .leading
    var cornerRadius: CGFloat = 18
    var textFont: Font = .body

    // Strict input constraints
    var maxLength: Int? = nil
    var inputFilter: ((String) -> String)? = nil

    // Optional character counter inside the input (right side)
    var showsCharacterCount: Bool = false
    /// Shows counter only when close to limit (e.g., 10 shows from max-10 to max)
    var characterCountThreshold: Int = 10

    // Keyboard toolbar (for numeric pads)
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

    // MARK: - Style Variants

    enum Style {
        case standard          // current default look (height 52, rounded fill)
        case prominentCentered // matches your Step 1 "name" input look
        case bare              // no background/overlay/frame (parent draws the container)
    }

    var style: Style = .standard

    // MARK: - Focus

    @FocusState private var isFocusedInternal: Bool

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Constants

    private let height: CGFloat = 52

    // MARK: - Computed

    private var hasError: Bool {
        error != nil && !(error?.isEmpty ?? true)
    }

    private var shouldShowTrailing: Bool {
        guard trailingIcon != nil else { return false }
        switch showTrailingWhen {
        case .always: return true
        case .whenNotEmpty: return !text.isEmpty
        case .never: return false
        }
    }

    private var shouldShowCount: Bool {
        guard showsCharacterCount, let maxLength else { return false }
        // If trailingIcon exists, we avoid cramping UI (name step has no trailing anyway)
        if trailingIcon != nil { return false }

        let threshold = max(0, characterCountThreshold)
        let start = max(0, maxLength - threshold)
        return text.count >= start
    }

    private var isAtMaxLength: Bool {
        guard let maxLength else { return false }
        return text.count >= maxLength
    }

    // MARK: - Strict constrained binding (blocks extra input)

    private var constrainedText: Binding<String> {
        Binding(
            get: { text },
            set: { newValue in
                var value = newValue

                // 1) Optional filter first
                if let inputFilter {
                    value = inputFilter(value)
                }

                // 2) Strict maxLength
                if let maxLength, value.count > maxLength {
                    value = String(value.prefix(maxLength))
                }

                // 3) Avoid redundant sets (helps cursor stability)
                if value != text {
                    text = value
                }
            }
        )
    }

    // MARK: - Colors

    private var backgroundColor: Color {
        if isDisabled {
            return colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.02)
        }
        return colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04)
    }

    private var borderColor: Color {
        if hasError { return FColors.danger.opacity(0.6) }
        if isFocusedInternal { return FColors.brand.opacity(0.5) }
        return .clear
    }

    private var iconColor: Color {
        if isDisabled { return FColors.textTertiary.opacity(0.5) }
        if isFocusedInternal { return FColors.brand }
        return FColors.textTertiary
    }

    private var textColor: Color {
        isDisabled ? FColors.textTertiary : FColors.textPrimary
    }

    // MARK: - Init

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
        inputFilter: ((String) -> String)? = nil,
        showsCharacterCount: Bool = false,
        characterCountThreshold: Int = 10,
        showDoneButton: Bool = false,
        isDisabled: Bool = false,
        error: String? = nil,
        onSubmit: (() -> Void)? = nil,
        onFocusChange: ((Bool) -> Void)? = nil,
        externalFocus: Binding<Bool>? = nil,
        style: Style = .standard
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
        self.inputFilter = inputFilter

        self.showsCharacterCount = showsCharacterCount
        self.characterCountThreshold = characterCountThreshold

        self.showDoneButton = showDoneButton

        self.isDisabled = isDisabled
        self.error = error

        self.onSubmit = onSubmit
        self.onFocusChange = onFocusChange
        self.externalFocus = externalFocus

        self.style = style
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            Group {
                switch style {

                case .standard:
                    contentRow
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

                case .prominentCentered:
                    contentRow
                        .padding(.horizontal, FSpacing.lg)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(isFocusedInternal ? FColors.brand.opacity(0.5) : Color.clear, lineWidth: 1.5)
                        )

                case .bare:
                    contentRow
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isFocusedInternal)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hasError)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: shouldShowTrailing)

            if let error = error, !error.isEmpty {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(FColors.danger)
                    .padding(.horizontal, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .toolbar {
            if showDoneButton && isFocusedInternal {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") {
                        isFocusedInternal = false
                        onSubmit?()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(FColors.textPrimary)
                }
            }
        }
        .onChange(of: isFocusedInternal) { _, newValue in
            onFocusChange?(newValue)

            guard let externalFocus else { return }
            if externalFocus.wrappedValue != newValue {
                DispatchQueue.main.async { externalFocus.wrappedValue = newValue }
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

    // MARK: - Content Row

    private var contentRow: some View {
        HStack(spacing: 12) {

            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(iconColor)
                    .frame(width: 20)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isFocusedInternal)
            }

            if let prefix = prefix {
                Text(prefix)
                    .font(textFont.weight(.semibold))
                    .foregroundStyle(FColors.textSecondary)
            }

            TextField(placeholder, text: constrainedText)
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
                .layoutPriority(1)
                .onSubmit {
                    onSubmit?()
                    externalFocus?.wrappedValue = false
                }

            if shouldShowCount, let maxLength = maxLength {
                Text("\(text.count)/\(maxLength)")
                    .font(.caption2.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(isAtMaxLength ? FColors.orange : FColors.textTertiary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.25, dampingFraction: 0.85), value: text.count)
                    .padding(.leading, 6)
            }

            if let suffix = suffix {
                Text(suffix)
                    .font(.subheadline)
                    .foregroundStyle(FColors.textTertiary)
            }

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

    // Keeps your existing numeric behavior (toolbar enabled)
    func numeric() -> FInput {
        var copy = self
        copy.keyboardType = .decimalPad
        copy.autocapitalization = .never
        copy.autocorrection = false
        copy.showDoneButton = true
        return copy
    }

    // Numeric but NO toolbar (useful if you have your own "Listo" button inline)
    func numericNoToolbar() -> FInput {
        var copy = self
        copy.keyboardType = .decimalPad
        copy.autocapitalization = .never
        copy.autocorrection = false
        copy.showDoneButton = false
        return copy
    }

    func keywords() -> FInput {
        var copy = self
        copy.keyboardType = .default
        copy.autocapitalization = .never
        copy.autocorrection = false
        return copy
    }

    func digitsOnly(showToolbarDone: Bool = false) -> FInput {
        var copy = self
        copy.keyboardType = .numberPad
        copy.autocapitalization = .never
        copy.autocorrection = false
        copy.showDoneButton = showToolbarDone
        copy.inputFilter = { $0.filter(\.isNumber) }
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

    // Style helpers
    func prominentCentered() -> FInput {
        var copy = self
        copy.style = .prominentCentered
        copy.icon = nil
        copy.trailingIcon = nil
        return copy
    }

    func bare() -> FInput {
        var copy = self
        copy.style = .bare
        copy.icon = nil
        return copy
    }

    // Internal counter helper
    func withCharacterCount(nearLimit: Int = 10) -> FInput {
        var copy = self
        copy.showsCharacterCount = true
        copy.characterCountThreshold = nearLimit
        return copy
    }
}
