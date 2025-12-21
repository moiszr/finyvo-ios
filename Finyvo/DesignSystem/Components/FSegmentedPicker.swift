//
//  FSegmentedPicker.swift
//  Finyvo
//
//  Reusable native segmented picker with icon + text per segment.
//  Uses UIKit bridge for full control over rendering.
//
//  iOS 18: Standard segmented control styling
//  iOS 26+: Automatic liquid glass styling
//

import SwiftUI
import UIKit

// MARK: - Segment Item

/// Represents a single segment option
struct FSegmentItem<T: Hashable>: Identifiable {
    let id = UUID()
    let value: T
    let title: String
    let icon: String
}

// MARK: - FSegmentedPicker

/// Native segmented picker with icon + text per segment
///
/// Usage:
/// ```swift
/// FSegmentedPicker(
///     selection: $type,
///     items: [
///         FSegmentItem(value: .expense, title: "Gasto", icon: "arrow.down.circle.fill"),
///         FSegmentItem(value: .income, title: "Ingreso", icon: "arrow.up.circle.fill")
///     ]
/// )
/// ```
struct FSegmentedPicker<T: Hashable>: View {
    @Binding var selection: T
    let items: [FSegmentItem<T>]
    var isDisabled: Bool = false
    var height: CGFloat = 48
    
    var body: some View {
        FSegmentedControlBridge(
            selection: $selection,
            items: items,
            isDisabled: isDisabled,
            controlHeight: height
        )
        .frame(height: height)
        .disabled(isDisabled)
        .onChange(of: selection) { _, _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

// MARK: - UIKit Bridge

private struct FSegmentedControlBridge<T: Hashable>: UIViewRepresentable {
    @Binding var selection: T
    let items: [FSegmentItem<T>]
    var isDisabled: Bool
    var controlHeight: CGFloat
    
    func makeUIView(context: Context) -> UISegmentedControl {
        let control = UISegmentedControl(items: items.map { _ in "" })
        control.apportionsSegmentWidthsByContent = false
        control.isEnabled = !isDisabled
        
        control.addTarget(
            context.coordinator,
            action: #selector(Coordinator.changed(_:)),
            for: .valueChanged
        )
        
        // Set initial selection
        if let index = items.firstIndex(where: { $0.value == selection }) {
            control.selectedSegmentIndex = index
        }
        
        // Apply initial images
        context.coordinator.applyImages(to: control, selection: selection, style: control.traitCollection.userInterfaceStyle)
        
        return control
    }
    
    func updateUIView(_ uiView: UISegmentedControl, context: Context) {
        uiView.isEnabled = !isDisabled
        
        // Don't interfere during user interaction
        guard !uiView.isTracking else { return }
        
        if let index = items.firstIndex(where: { $0.value == selection }) {
            if uiView.selectedSegmentIndex != index {
                uiView.selectedSegmentIndex = index
            }
        }
        
        // Always update images when selection changes
        context.coordinator.applyImages(to: uiView, selection: selection, style: uiView.traitCollection.userInterfaceStyle)
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UISegmentedControl, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? uiView.intrinsicContentSize.width, height: controlHeight)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    final class Coordinator: NSObject {
        var parent: FSegmentedControlBridge
        
        init(parent: FSegmentedControlBridge) {
            self.parent = parent
        }
        
        @objc func changed(_ sender: UISegmentedControl) {
            let index = sender.selectedSegmentIndex
            guard index >= 0, index < parent.items.count else { return }
            parent.selection = parent.items[index].value
        }
        
        func applyImages(to control: UISegmentedControl, selection: T, style: UIUserInterfaceStyle) {
            for (index, item) in parent.items.enumerated() {
                let isSelected = item.value == selection
                control.setImage(
                    makeSegmentImage(
                        title: item.title,
                        symbol: item.icon,
                        isSelected: isSelected,
                        style: style
                    ),
                    forSegmentAt: index
                )
            }
        }
        
        private func makeSegmentImage(
            title: String,
            symbol: String,
            isSelected: Bool,
            style: UIUserInterfaceStyle
        ) -> UIImage {
            // Adaptive colors - selected is full opacity, unselected is dimmed
            let baseColor: UIColor = (style == .dark) ? .white : .label
            let alpha: CGFloat = isSelected ? 1.0 : 0.5
            
            // Scale based on height
            let fontSize: CGFloat = (parent.controlHeight >= 48) ? 16 : 15
            let symbolSize: CGFloat = (parent.controlHeight >= 48) ? 17 : 16
            let font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
            
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: symbolSize, weight: .semibold)
            let icon = UIImage(systemName: symbol, withConfiguration: symbolConfig)?
                .withTintColor(baseColor.withAlphaComponent(alpha), renderingMode: .alwaysOriginal)
            
            let text = NSAttributedString(
                string: title,
                attributes: [
                    .font: font,
                    .foregroundColor: baseColor.withAlphaComponent(alpha)
                ]
            )
            
            let paddingX: CGFloat = 12
            let spacing: CGFloat = 7
            let verticalPadding: CGFloat = (parent.controlHeight >= 48) ? 7 : 5
            
            let textSize = text.size()
            let iconSize = icon?.size ?? .zero
            let contentH = max(textSize.height, iconSize.height)
            
            let h = ceil(contentH + verticalPadding * 2)
            let w = ceil(paddingX + iconSize.width + spacing + textSize.width + paddingX)
            
            return UIGraphicsImageRenderer(size: CGSize(width: w, height: h)).image { _ in
                let yIcon = (h - iconSize.height) / 2
                icon?.draw(in: CGRect(x: paddingX, y: yIcon, width: iconSize.width, height: iconSize.height))
                
                let yText = (h - textSize.height) / 2
                text.draw(at: CGPoint(x: paddingX + iconSize.width + spacing, y: yText))
            }
        }
    }
}

// MARK: - Preview

#Preview("FSegmentedPicker") {
    struct PreviewWrapper: View {
        enum TransactionType: String, CaseIterable {
            case expense, income
        }
        
        @State private var type: TransactionType = .expense
        
        var body: some View {
            VStack(spacing: 20) {
                FSegmentedPicker(
                    selection: $type,
                    items: [
                        FSegmentItem(value: TransactionType.expense, title: "Gasto", icon: "arrow.down.circle.fill"),
                        FSegmentItem(value: TransactionType.income, title: "Ingreso", icon: "arrow.up.circle.fill")
                    ]
                )
                .padding()
                
                Text("Selected: \(type.rawValue)")
            }
            .padding()
        }
    }
    
    return PreviewWrapper()
}

#Preview("FSegmentedPicker - Dark") {
    struct PreviewWrapper: View {
        enum TransactionType: String, CaseIterable {
            case expense, income
        }
        
        @State private var type: TransactionType = .expense
        
        var body: some View {
            VStack(spacing: 20) {
                FSegmentedPicker(
                    selection: $type,
                    items: [
                        FSegmentItem(value: TransactionType.expense, title: "Gasto", icon: "arrow.down.circle.fill"),
                        FSegmentItem(value: TransactionType.income, title: "Ingreso", icon: "arrow.up.circle.fill")
                    ]
                )
                .padding()
                
                Text("Selected: \(type.rawValue)")
                    .foregroundStyle(.white)
            }
            .padding()
            .background(Color.black)
        }
    }
    
    return PreviewWrapper()
        .preferredColorScheme(.dark)
}
