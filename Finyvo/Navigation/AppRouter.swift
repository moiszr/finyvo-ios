//
//  AppRouter.swift
//  Finyvo
//
//  Created by Moises Núñez on 12/5/25.
//

import SwiftUI

// MARK: - App Router

struct AppRouter: View {
    
    @Environment(AppState.self) private var appState
    
    var body: some View {
        Group {
            if appState.isLoading {
                LoadingView()
            } else if !appState.hasCompletedOnboarding {
                OnboardingView()
            } else {
                // TODO: cuando tengas AuthView real, usarla aquí si !isAuthenticated
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isLoading)
        .animation(.easeInOut(duration: 0.3), value: appState.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
    }
}

// MARK: - Loading View

private struct LoadingView: View {
    var body: some View {
        ZStack {
            FColors.background
                .ignoresSafeArea()
            
            VStack(spacing: FSpacing.lg) {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(FColors.brand)
                
                ProgressView()
                    .tint(FColors.textSecondary)
            }
        }
    }
}

// MARK: - Tab Selection

private enum TabSelection: Hashable {
    case home
    case budget
    case reports
    case more
    case search
    
    var isPrimaryTab: Bool {
        switch self {
        case .home, .budget, .reports:
            return true
        case .more, .search:
            return false
        }
    }
    
    var title: String {
        switch self {
        case .home: "Inicio"
        case .budget: "Presupuesto"
        case .reports: "Reportes"
        case .more: "Más"
        case .search: "Buscar"
        }
    }
    
    var icon: String {
        switch self {
        case .home: "house.fill"
        case .budget: "target"
        case .reports: "chart.bar.fill"
        case .more: "chevron.up.chevron.down"
        case .search: "magnifyingglass"
        }
    }
}

// MARK: - Secondary Section

private enum SecondarySection: String, CaseIterable, Identifiable {
    case goals
    case categories
    case wallets
    case subscriptions
    case export
    case help
    case settings
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .goals: "Metas"
        case .categories: "Categorías"
        case .wallets: "Billeteras"
        case .subscriptions: "Suscripciones"
        case .export: "Exportar"
        case .help: "Ayuda"
        case .settings: "Ajustes"
        }
    }
    
    var icon: String {
        switch self {
        case .goals: "scope"
        case .categories: "square.grid.2x2.fill"
        case .wallets: "wallet.bifold.fill"
        case .subscriptions: "arrow.trianglehead.2.clockwise"
        case .export: "square.and.arrow.up"
        case .help: "questionmark.circle"
        case .settings: "gearshape.fill"
        }
    }
    
    /// Secciones principales (features)
    static var mainFeatures: [SecondarySection] {
        [.goals, .categories, .wallets, .subscriptions]
    }
    
    /// Secciones de utilidad
    static var utilities: [SecondarySection] {
        [.export, .help, .settings]
    }
}

// MARK: - Active Menu Item

private enum ActiveMenuItem: Equatable {
    case tab(TabSelection)
    case section(SecondarySection)
}

// MARK: - Main Tab View

private struct MainTabView: View {
    @State private var currentTab: TabSelection = .home
    @State private var isMoreMenuPresented: Bool = false
    @State private var activeSecondarySection: SecondarySection? = nil
    
    private var selectedTabBinding: Binding<TabSelection> {
        Binding(
            get: {
                if isMoreMenuPresented {
                    return .more
                }
                if currentTab == .search {
                    return .search
                }
                if activeSecondarySection != nil {
                    return .more
                }
                return currentTab
            },
            set: { newValue in
                handleTabSelection(newValue)
            }
        )
    }
    
    private var moreTabIcon: String {
        activeSecondarySection?.icon ?? "chevron.up.chevron.down"
    }
    
    private var currentActiveItem: ActiveMenuItem {
        if let section = activeSecondarySection {
            return .section(section)
        }
        return .tab(currentTab)
    }
    
    var body: some View {
        ZStack {
            TabView(selection: selectedTabBinding) {
                Tab(value: TabSelection.home) {
                    PlaceholderView(title: TabSelection.home.title, icon: TabSelection.home.icon)
                } label: {
                    Image(systemName: TabSelection.home.icon)
                        .accessibilityLabel(TabSelection.home.title)
                }
                
                Tab(value: TabSelection.budget) {
                    PlaceholderView(title: TabSelection.budget.title, icon: TabSelection.budget.icon)
                } label: {
                    Image(systemName: TabSelection.budget.icon)
                        .accessibilityLabel(TabSelection.budget.title)
                }
                
                Tab(value: TabSelection.reports) {
                    PlaceholderView(title: TabSelection.reports.title, icon: TabSelection.reports.icon)
                } label: {
                    Image(systemName: TabSelection.reports.icon)
                        .accessibilityLabel(TabSelection.reports.title)
                }
                
                Tab(value: TabSelection.more) {
                    if let section = activeSecondarySection {
                        CategoriesView()
                    } else {
                        Color.clear
                    }
                } label: {
                    Image(systemName: moreTabIcon)
                        .accessibilityLabel(TabSelection.more.title)
                }
                
                Tab(value: TabSelection.search, role: .search) {
                    SearchTabView()
                } label: {
                    Label(TabSelection.search.title, systemImage: TabSelection.search.icon)
                }
            }
            .tint(FColors.brand)
            
            if isMoreMenuPresented {
                MoreMenuOverlay(
                    isPresented: $isMoreMenuPresented,
                    currentActiveItem: currentActiveItem,
                    onSelection: handleMenuSelection
                )
                .zIndex(100)
            }
        }
    }
    
    // MARK: - Navigation Handlers
    
    private func handleTabSelection(_ newValue: TabSelection) {
        switch newValue {
        case .more:
            // 1. Si venimos desde el buscador y HAY una sección secundaria activa
            //    → volvemos a esa sección sin abrir el menú.
            if currentTab == .search, activeSecondarySection != nil {
                isMoreMenuPresented = false
                currentTab = .more
                return
            }
            
            // 2. En cualquier otro caso, el tab "Más" actúa como disparador del overlay.
            isMoreMenuPresented = true

        case .search:
            // Vamos al tab de búsqueda, pero NO borramos la sección secundaria activa
            // para que el icono del tab "Más" siga reflejando de dónde venimos.
            currentTab = .search

        default:
            // Cualquier tab principal limpia la sección secundaria.
            activeSecondarySection = nil
            isMoreMenuPresented = false
            currentTab = newValue
        }
    }

    
    private func handleMenuSelection(_ item: ActiveMenuItem) {
        switch item {
        case .tab(let tab):
            activeSecondarySection = nil
            currentTab = tab
            
        case .section(let section):
            activeSecondarySection = section
            currentTab = .more
        }
    }
}

// MARK: - More Menu Overlay

private struct MoreMenuOverlay: View {
    @Binding var isPresented: Bool
    let currentActiveItem: ActiveMenuItem
    let onSelection: (ActiveMenuItem) -> Void
    
    @Environment(\.colorScheme) private var colorScheme

    @State private var overlayOpacity: Double = 0
    @State private var isBlurVisible: Bool = false
    @State private var itemStates: [ItemAnimationState]
    
    // MARK: - Types
    
    private struct ItemAnimationState {
        var opacity: Double = 0
        var offsetY: CGFloat = 24
        var scale: CGFloat = 0.96
    }
    
    private struct MenuItem: Identifiable {
        let id: String
        let title: String
        let systemImage: String
        let action: MenuAction

        init(title: String, systemImage: String, action: MenuAction) {
            self.title = title
            self.systemImage = systemImage
            self.action = action
            
            switch action {
            case .tab(let tab):
                self.id = "tab_\(tab)"
            case .section(let section):
                self.id = "section_\(section.rawValue)"
            case .quickAction(let quick):
                self.id = "quick_\(quick)"
            }
        }
    }
    
    private enum MenuAction: Equatable {
        case tab(TabSelection)
        case section(SecondarySection)
        case quickAction(QuickActionType)
        
        enum QuickActionType: Equatable {
            case quickInsights
            case upcoming
        }
    }
    
    // MARK: - Static menu definitions (NO dependen de self)
    
    private static let quickActionsStatic: [MenuItem] = [
        .init(title: "Resumen Rápido", systemImage: "bolt.fill", action: .quickAction(.quickInsights)),
        .init(title: "Próximamente", systemImage: "clock.fill", action: .quickAction(.upcoming))
    ]
    
    private static let mainNavigationStatic: [MenuItem] =
        TabSelection.allCases
            .filter { $0.isPrimaryTab }
            .map { MenuItem(title: $0.title, systemImage: $0.icon, action: .tab($0)) }
    
    private static var featureSectionsStatic: [MenuItem] {
        SecondarySection.mainFeatures.map {
            MenuItem(title: $0.title, systemImage: $0.icon, action: .section($0))
        }
    }
    
    private static var utilitySectionsStatic: [MenuItem] {
        SecondarySection.utilities.map {
            MenuItem(title: $0.title, systemImage: $0.icon, action: .section($0))
        }
    }
    
    // MARK: - Instance accessors (ya usan las estáticas)
    
    private var quickActions: [MenuItem] { Self.quickActionsStatic }
    private var mainNavigation: [MenuItem] { Self.mainNavigationStatic }
    private var featureSections: [MenuItem] { Self.featureSectionsStatic }
    private var utilitySections: [MenuItem] { Self.utilitySectionsStatic }
    
    private var allItems: [MenuItem] {
        quickActions + mainNavigation + featureSections + utilitySections
    }
    
    private var totalItemCount: Int { allItems.count }
    
    // MARK: - Colors
    
    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var dividerColor: Color {
        colorScheme == .dark ? .white.opacity(0.12) : .black.opacity(0.1)
    }
    
    // MARK: - Init (usa SOLO las propiedades estáticas)
    
    init(
        isPresented: Binding<Bool>,
        currentActiveItem: ActiveMenuItem,
        onSelection: @escaping (ActiveMenuItem) -> Void
    ) {
        self._isPresented = isPresented
        self.currentActiveItem = currentActiveItem
        self.onSelection = onSelection
        
        let count =
            Self.quickActionsStatic.count +
            Self.mainNavigationStatic.count +
            Self.featureSectionsStatic.count +
            Self.utilitySectionsStatic.count
        
        self._itemStates = State(initialValue: Array(repeating: ItemAnimationState(), count: count))
    }
    
    // MARK: - Body

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                // Fondo (blur + tint + gradiente) — también cierra al tocar fuera
                backgroundLayers
                    .contentShape(Rectangle())
                    .onTapGesture(perform: dismissMenu)

                // Contenedor centrado verticalmente
                VStack {
                    Spacer() // espacio superior
                    menuContent
                        .padding(.horizontal, 36)
                    Spacer() // espacio inferior
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .ignoresSafeArea()
        }
        .onAppear(perform: showWithAnimation)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, dismissMenu)   // gesto de “Z” para cerrar
    }

    // MARK: - Menu Content

    @ViewBuilder
    private var menuContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Quick Actions
            menuSection(items: quickActions, startIndex: 0)
            
            sectionSpacer(height: 18)
            animatedDivider(afterIndex: quickActions.count - 1)
            sectionSpacer(height: 18)
            
            // Main Navigation
            menuSection(items: mainNavigation, startIndex: quickActions.count)
            
            animatedDivider(afterIndex: quickActions.count + mainNavigation.count - 1)
                .padding(.vertical, 14)
            
            // Feature Sections
            menuSection(
                items: featureSections,
                startIndex: quickActions.count + mainNavigation.count
            )
            
            animatedDivider(
                afterIndex: quickActions.count + mainNavigation.count + featureSections.count - 1
            )
            .padding(.vertical, 14)
            
            // Utility Sections
            menuSection(
                items: utilitySections,
                startIndex: quickActions.count + mainNavigation.count + featureSections.count
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Background
    
    @ViewBuilder
    private var backgroundLayers: some View {
        GaussianBlurView(isVisible: isBlurVisible)
            .ignoresSafeArea()
        
        Rectangle()
            .fill(
                colorScheme == .dark
                    ? Color.black.opacity(0.35 * overlayOpacity)
                    : Color.white.opacity(0.25 * overlayOpacity)
            )
            .ignoresSafeArea()
        
        LinearGradient(
            colors: [
                colorScheme == .dark
                    ? Color.white.opacity(0.04)
                    : Color.white.opacity(0.35),
                .clear
            ],
            startPoint: .top,
            endPoint: .center
        )
        .opacity(overlayOpacity)
    }
    
    // MARK: - View Builders
    
    @ViewBuilder
    private func sectionSpacer(height: CGFloat) -> some View {
        Spacer().frame(height: height)
    }
    
    @ViewBuilder
    private func menuSection(items: [MenuItem], startIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                menuItemView(item, index: startIndex + index)
            }
        }
    }
    
    @ViewBuilder
    private func menuItemView(_ item: MenuItem, index: Int) -> some View {
        let state = itemStates[safe: index] ?? ItemAnimationState()
        let isActive = isItemActive(item.action)
        
        Button {
            handleSelection(item)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: item.systemImage)
                    .imageScale(.medium)          // tamaño consistente para todos
                    .frame(width: 24, alignment: .center)
                
                Text(item.title)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .tracking(-0.3)
            }
            .foregroundStyle(isActive ? FColors.brand : textColor)
        }
        // 🔑 Aquí definimos la fuente UNA sola vez para TODO el item
        .font(.title3.weight(.semibold))        // Dynamic Type friendly y consistente
        .buttonStyle(MenuButtonStyle())
        .opacity(state.opacity)
        .offset(y: state.offsetY)
        .scaleEffect(state.scale, anchor: .leading)
        .accessibilityLabel(Text(item.title))
        .accessibilityHint(Text("Ir a \(item.title)"))
    }
    
    @ViewBuilder
    private func animatedDivider(afterIndex: Int) -> some View {
        let state = itemStates[safe: afterIndex] ?? ItemAnimationState()
        
        Rectangle()
            .fill(dividerColor)
            .frame(height: 1)
            .frame(maxWidth: 180)
            .opacity(state.opacity * 0.7)
    }
    
    // MARK: - State Helpers
    
    private func isItemActive(_ action: MenuAction) -> Bool {
        switch action {
        case .tab(let tab):
            if case .tab(let activeTab) = currentActiveItem {
                return tab == activeTab
            }
        case .section(let section):
            if case .section(let activeSection) = currentActiveItem {
                return section == activeSection
            }
        case .quickAction:
            return false
        }
        return false
    }
    
    // MARK: - Animations
    
    private func showWithAnimation() {
        withAnimation(.easeOut(duration: 0.5)) {
            overlayOpacity = 1
            isBlurVisible = true
        }
        
        for index in 0..<totalItemCount {
            let delay = Double(index) * 0.04 + 0.05
            
            withAnimation(
                .spring(response: 0.6, dampingFraction: 0.85, blendDuration: 0.1)
                    .delay(delay)
            ) {
                itemStates[index].opacity = 1
                itemStates[index].offsetY = 0
                itemStates[index].scale = 1
            }
        }
    }
    
    private func dismissWithAnimation(completion: @escaping () -> Void) {
        for index in (0..<totalItemCount).reversed() {
            let reverseIndex = totalItemCount - 1 - index
            let delay = Double(reverseIndex) * 0.02
            
            withAnimation(.easeOut(duration: 0.22).delay(delay)) {
                itemStates[index].opacity = 0
                itemStates[index].offsetY = -12
                itemStates[index].scale = 0.97
            }
        }
        
        withAnimation(.easeOut(duration: 0.38).delay(0.08)) {
            overlayOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) {
            isBlurVisible = false
            isPresented = false
            completion()
        }
    }
    
    // MARK: - Actions
    
    private func dismissMenu() {
        dismissWithAnimation {}
    }
    
    private func handleSelection(_ item: MenuItem) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        switch item.action {
        case .tab(let tab):
            onSelection(.tab(tab))
        case .section(let section):
            onSelection(.section(section))
        case .quickAction:
            // TODO: acciones rápidas
            break
        }
        
        dismissWithAnimation {}
    }
}


// MARK: - Gaussian Blur View (seguro y compatible)

private struct GaussianBlurView: UIViewRepresentable {
    let isVisible: Bool

    func makeUIView(context: Context) -> UIVisualEffectView {
        // El estilo systemUltraThinMaterial Dark/Light se adapta solo
        let effect = UIBlurEffect(style: .systemChromeMaterial)
        let view = UIVisualEffectView(effect: effect)
        view.alpha = isVisible ? 1 : 0
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            uiView.alpha = isVisible ? 1 : 0
        }
    }
}

// MARK: - Menu Button Style

private struct MenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.5 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1, anchor: .leading)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

// MARK: - Array Extension

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - TabSelection Extension

extension TabSelection: CaseIterable {
    static var allCases: [TabSelection] {
        [.home, .budget, .reports, .more, .search]
    }
}

// MARK: - Placeholder View

private struct PlaceholderView: View {
    let title: String
    let icon: String
    
    var body: some View {
        NavigationStack {
            VStack(spacing: FSpacing.lg) {
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundStyle(FColors.textTertiary)
                
                Text("Próximamente")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FColors.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FColors.background)
            .navigationTitle(title)
        }
    }
}

// MARK: - Search Tab View

private struct SearchTabView: View {
    @State private var query = ""
    
    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Buscar en Finyvo")
                                .font(.title3.weight(.semibold))
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                                .foregroundStyle(FColors.textPrimary)

                            Text("Encuentra transacciones, categorías, presupuestos y más.")
                                .font(.subheadline)
                                .foregroundStyle(FColors.textSecondary)

                        }
                        .padding(.vertical, FSpacing.md)
                    }
                } else {
                    Section("Resultados") {
                        Text("Sin resultados para \"\(query)\"")
                            .foregroundStyle(FColors.textSecondary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(FColors.background)
            .searchable(text: $query, placement: .automatic, prompt: "Buscar en Finyvo…")
            .navigationTitle("Buscar")
        }
    }
}

// MARK: - Previews

#Preview("Light Mode") {
    AppRouter()
        .environment(AppState())
}

#Preview("Dark Mode") {
    AppRouter()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
