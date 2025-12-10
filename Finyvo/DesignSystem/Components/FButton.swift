//
//  FButton.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/6/25.
//

import SwiftUI

// MARK: - FButton
/// Botón premium de Finyvo con soporte para múltiples variantes
/// Diseñado para ser sobrio, elegante y adaptarse a light/dark mode

struct FButton: View {
    
    // MARK: - Button Variants
    enum Variant {
        case primary    // Fondo sólido (negro en light, blanco en dark)
        case secondary  // Borde, sin fondo
        case ghost      // Sin fondo ni borde, solo texto
        case brand      // Color de marca (#0EA5E9)
    }
    
    // MARK: - Button Sizes
    enum Size {
        case small
        case medium
        case large
        
        var verticalPadding: CGFloat {
            switch self {
            case .small: return FSpacing.sm
            case .medium: return FSpacing.md
            case .large: return FSpacing.lg
            }
        }
        
        var horizontalPadding: CGFloat {
            switch self {
            case .small: return FSpacing.md
            case .medium: return FSpacing.lg
            case .large: return FSpacing.xl
            }
        }
        
        var font: Font {
            switch self {
            case .small: return .subheadline.weight(.semibold)
            case .medium: return .body.weight(.semibold)
            case .large: return .headline.weight(.semibold)
            }
        }
        
        /// Radio de esquina según el tamaño del botón
        var cornerRadius: CGFloat {
            switch self {
            case .small: return FRadius.md   // 16pt
            case .medium: return FRadius.lg  // 22pt
            case .large: return FRadius.xl   // 28pt
            }
        }
    }
    
    // MARK: - Properties
    let title: String
    let variant: Variant
    let size: Size
    let isFullWidth: Bool
    let icon: String?
    let iconPosition: IconPosition
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    enum IconPosition {
        case leading
        case trailing
    }
    
    // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Initializer
    init(
        _ title: String,
        variant: Variant = .primary,
        size: Size = .medium,
        isFullWidth: Bool = false,
        icon: String? = nil,
        iconPosition: IconPosition = .leading,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.variant = variant
        self.size = size
        self.isFullWidth = isFullWidth
        self.icon = icon
        self.iconPosition = iconPosition
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    // MARK: - Body
    var body: some View {
        Button(action: {
            if !isLoading && !isDisabled {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                action()
            }
        }) {
            HStack(spacing: FSpacing.sm) {
                // Leading icon
                if let icon = icon, iconPosition == .leading, !isLoading {
                    Image(systemName: icon)
                        .font(size.font)
                }
                
                // Loading or Title
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .font(size.font)
                }
                
                // Trailing icon
                if let icon = icon, iconPosition == .trailing, !isLoading {
                    Image(systemName: icon)
                        .font(size.font)
                }
            }
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, size.horizontalPadding)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
            .overlay {
                if variant == .secondary {
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .stroke(borderColor, lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(FButtonStyle())
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1)
    }
    
    // MARK: - Computed Colors
    
    private var foregroundColor: Color {
        switch variant {
        case .primary:
            return colorScheme == .light ? .white : .black
        case .secondary:
            return colorScheme == .light ? .black : .white
        case .ghost:
            return colorScheme == .light ? .black : .white
        case .brand:
            return .white
        }
    }
    
    private var backgroundColor: Color {
        switch variant {
        case .primary:
            return colorScheme == .light ? .black : .white
        case .secondary:
            return .clear
        case .ghost:
            return .clear
        case .brand:
            return FColors.brand
        }
    }
    
    private var borderColor: Color {
        colorScheme == .light ? .black.opacity(0.2) : .white.opacity(0.2)
    }
}

// MARK: - Custom Button Style (Press Animation)
struct FButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("All Variants") {
    ScrollView {
        VStack(spacing: FSpacing.xl) {
            
            Group {
                Text("Primary").font(.headline)
                FButton("Continuar", variant: .primary) {
                    print("Primary tapped")
                }
                FButton("Continuar", variant: .primary, isFullWidth: true) {
                    print("Primary full width")
                }
            }
            
            Divider()
            
            Group {
                Text("Secondary").font(.headline)
                FButton("Cancelar", variant: .secondary) {
                    print("Secondary tapped")
                }
                FButton("Cancelar", variant: .secondary, isFullWidth: true) {
                    print("Secondary full width")
                }
            }
            
            Divider()
            
            Group {
                Text("Ghost").font(.headline)
                FButton("Saltar", variant: .ghost) {
                    print("Ghost tapped")
                }
            }
            
            Divider()
            
            Group {
                Text("Brand").font(.headline)
                FButton("Comenzar", variant: .brand, isFullWidth: true) {
                    print("Brand tapped")
                }
            }
            
            Divider()
            
            Group {
                Text("With Icons").font(.headline)
                FButton("Añadir", variant: .primary, icon: "plus") {
                    print("Add tapped")
                }
                FButton("Siguiente", variant: .brand, icon: "arrow.right", iconPosition: .trailing) {
                    print("Next tapped")
                }
            }
            
            Divider()
            
            Group {
                Text("Sizes").font(.headline)
                HStack {
                    FButton("Small", variant: .primary, size: .small) {}
                    FButton("Medium", variant: .primary, size: .medium) {}
                    FButton("Large", variant: .primary, size: .large) {}
                }
            }
            
            Divider()
            
            Group {
                Text("States").font(.headline)
                FButton("Loading...", variant: .brand, isLoading: true) {}
                FButton("Disabled", variant: .primary, isDisabled: true) {}
            }
        }
        .padding()
    }
}

#Preview("Light Mode") {
    VStack(spacing: FSpacing.lg) {
        FButton("Primary Button", variant: .primary, isFullWidth: true) {}
        FButton("Secondary Button", variant: .secondary, isFullWidth: true) {}
        FButton("Brand Button", variant: .brand, isFullWidth: true) {}
    }
    .padding()
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    VStack(spacing: FSpacing.lg) {
        FButton("Primary Button", variant: .primary, isFullWidth: true) {}
        FButton("Secondary Button", variant: .secondary, isFullWidth: true) {}
        FButton("Brand Button", variant: .brand, isFullWidth: true) {}
    }
    .padding()
    .preferredColorScheme(.dark)
}
