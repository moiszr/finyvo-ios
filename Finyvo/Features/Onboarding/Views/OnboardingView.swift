//
//  OnboardingView.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/6/25.
//

import SwiftUI

struct OnboardingView: View {
    
    // MARK: - Properties
    @State private var viewModel = OnboardingViewModel()
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            
            pageContent
            
            pageIndicator
                .padding(.top, FSpacing.lg)
                .padding(.bottom, FSpacing.xxl)
            
            buttonSection
                .padding(.horizontal, FSpacing.xl)
                .padding(.bottom, FSpacing.xxxl)
        }
        .background(FColors.background)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: viewModel.currentIndex)
        .onAppear(perform: setupOnComplete)
    }
    
    // MARK: - Setup
    private func setupOnComplete() {
        viewModel.onComplete = {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            appState.completeOnboarding()
        }
    }
}

// MARK: - Subviews
private extension OnboardingView {
    
    // MARK: Header
    var headerSection: some View {
        HStack {
            Spacer()
            
            Button("Saltar") {
                viewModel.skip()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(FColors.textTertiary)
            .opacity(viewModel.isLastPage ? 0 : 1)
        }
        .frame(height: 44)
        .padding(.horizontal, FSpacing.xl)
    }
    
    // MARK: Page Content
    var pageContent: some View {
        TabView(selection: $viewModel.currentIndex) {
            ForEach(viewModel.pages) { page in
                OnboardingPageContent(page: page)
                    .tag(page.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
    
    // MARK: Page Indicator (Monocromático)
    var pageIndicator: some View {
        HStack(spacing: FSpacing.sm) {
            ForEach(viewModel.pages) { page in
                Capsule()
                    .fill(indicatorColor(isActive: page.id == viewModel.currentIndex))
                    .frame(
                        width: page.id == viewModel.currentIndex ? 28 : 8,
                        height: 8
                    )
                    .onTapGesture {
                        viewModel.goToPage(page.id)
                    }
            }
        }
    }
    
    func indicatorColor(isActive: Bool) -> Color {
        if isActive {
            return colorScheme == .light
                ? .black.opacity(0.85)
                : .white.opacity(0.9)
        }
        return colorScheme == .light
            ? .black.opacity(0.15)
            : .white.opacity(0.2)
    }
    
    // MARK: Button Section
    var buttonSection: some View {
        HStack(spacing: FSpacing.md) {
            if !viewModel.isFirstPage {
                FButton("Atrás", variant: .secondary) {
                    triggerLightHaptic()
                    viewModel.previousPage()
                }
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    )
                )
            }
            
            FButton(primaryButtonLabel, variant: .primary, isFullWidth: true) {
                triggerLightHaptic()
                viewModel.nextPage()
            }
        }
    }
    
    var primaryButtonLabel: String {
        if viewModel.isFirstPage { return "Comenzar" }
        if viewModel.isLastPage { return "Empezar" }
        return "Siguiente"
    }
    
    func triggerLightHaptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Page Content View
private struct OnboardingPageContent: View {
    let page: OnboardingPage
    
    @State private var isActive = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    // MARK: Computed
    
    /// Color del glow según el modo actual
    private var glowColor: Color {
        colorScheme == .light ? page.glowColorLight : page.glowColorDark
    }
    
    /// Opacidad del glow: más intenso que antes para ser visible
    private var glowOpacity: Double {
        colorScheme == .light ? 0.45 : 0.55
    }
    
    // MARK: Animation Values
    
    /// Valores de animación adaptados a Reduce Motion
    private var lottieOffset: CGFloat {
        reduceMotion ? 0 : (isActive ? 0 : 30)
    }
    
    private var lottieScale: CGFloat {
        reduceMotion ? 1 : (isActive ? 1 : 0.9)
    }
    
    private var titleOffset: CGFloat {
        reduceMotion ? 0 : (isActive ? 0 : 20)
    }
    
    private var subtitleOffset: CGFloat {
        reduceMotion ? 0 : (isActive ? 0 : 15)
    }
    
    private var contentOpacity: Double {
        isActive ? 1 : 0
    }
    
    // MARK: Body
    var body: some View {
        VStack(spacing: FSpacing.xxl) {
            Spacer()
            visualElement
            textContent
            Spacer()
        }
        .padding(.horizontal, FSpacing.xl)
        .onAppear(perform: animateIn)
        .onDisappear { isActive = false }
    }
    
    private func animateIn() {
        let duration = reduceMotion ? 0.2 : 0.55
        let delay = reduceMotion ? 0.0 : 0.1
        
        withAnimation(.easeOut(duration: duration).delay(delay)) {
            isActive = true
        }
    }
    
    // MARK: Visual Element
    private var visualElement: some View {
        ZStack {
            // Glow: RadialGradient con colores calibrados
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            glowColor.opacity(glowOpacity),
                            glowColor.opacity(glowOpacity * 0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 160
                    )
                )
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .opacity(contentOpacity)
            
            // Lottie
            LottieView(name: page.lottieName)
                .frame(width: 220, height: 220)
                .offset(y: lottieOffset)
                .scaleEffect(lottieScale)
                .opacity(contentOpacity)
        }
        .frame(height: 300)
    }
    
    // MARK: Text Content
    private var textContent: some View {
        VStack(spacing: FSpacing.md) {
            Text(page.title)
                .font(.system(size: 36, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(FColors.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .offset(y: titleOffset)
                .opacity(contentOpacity)
                .animation(
                    .easeOut(duration: reduceMotion ? 0.2 : 0.5).delay(reduceMotion ? 0 : 0.15),
                    value: isActive
                )
            
            Text(page.subtitle)
                .font(.system(size: 17, weight: .regular))
                .multilineTextAlignment(.center)
                .foregroundStyle(FColors.textSecondary)
                .lineSpacing(4)
                .lineLimit(2)
                .padding(.horizontal, FSpacing.sm)
                .offset(y: subtitleOffset)
                .opacity(contentOpacity)
                .animation(
                    .easeOut(duration: reduceMotion ? 0.2 : 0.45).delay(reduceMotion ? 0 : 0.22),
                    value: isActive
                )
        }
    }
}

// MARK: - Previews
#Preview("Light Mode") {
    OnboardingView()
        .environment(AppState())
}

#Preview("Dark Mode") {
    OnboardingView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
