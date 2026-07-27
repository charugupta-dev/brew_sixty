import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var showLaunchScreen: Bool
    @State private var selectedTab: Tab
    @State private var brewSessionStore = BrewSessionStore.shared
    @AppStorage(ProfilePreferences.Keys.hasCompletedProfile) private var hasCompletedProfile = false
    @AppStorage(Phase1IntentActionStore.key) private var pendingActionData: Data?

    @Query(sort: \BrewTemplate.createdAt, order: .reverse) private var templates: [BrewTemplate]
    
    enum Tab {
        case brew
        case recipes
    }
    
    init() {
        _showLaunchScreen = State(
            initialValue: !ReadmeCaptureConfiguration.shouldSkipLaunchScreen && !Phase1IntentActionStore.hasPendingAction
        )
        _selectedTab = State(
            initialValue: ReadmeCaptureConfiguration.initialTab == .recipes ? .recipes : .brew
        )

        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground() // Restore translucent system glass
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        ZStack {
            if showLaunchScreen {
                LaunchView(showLaunch: $showLaunchScreen)
                    .transition(.opacity)
            } else {
                TabView(selection: $selectedTab) {
                    HomeView(selectedTab: $selectedTab, brewSessionStore: brewSessionStore)
                        .tag(Tab.brew)
                        .tabItem {
                            Label("Brew", systemImage: "cup.and.saucer.fill")
                        }
                    
                    MethodsView(selectedTab: $selectedTab, brewSessionStore: brewSessionStore)
                        .tag(Tab.recipes)
                        .tabItem {
                            Label("Recipes", systemImage: "square.grid.2x2.fill")
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tint(Color.primaryCopper)
                .transition(.opacity)
            }

            if let banner = brewSessionStore.intentHandoffBanner, !showLaunchScreen {
                VStack {
                    IntentHandoffBannerView(banner: banner)
                        .padding(.top, 10)
                        .padding(.horizontal, 16)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .allowsHitTesting(false)
            }
        }
        .preferredColorScheme(.light)
        .fullScreenCover(
            isPresented: Binding(
                get: { !showLaunchScreen && !hasCompletedProfile },
                set: { _ in }
            )
        ) {
            ProfileSetupView(mode: .onboarding)
        }
        .onAppear {
            applyPendingIntentDestinationIfNeeded()
            brewSessionStore.onInsertLog = { dose, ratio in
                let log = BrewLog(timestamp: Date(), beanWeightGram: dose, ratio: ratio)
                modelContext.insert(log)
                try? modelContext.save()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            applyPendingIntentDestinationIfNeeded()
        }
        .onChange(of: showLaunchScreen) { _, isShowing in
            guard !isShowing else { return }
            applyPendingIntentDestinationIfNeeded()
        }
        .onChange(of: pendingActionData) { _, _ in
            applyPendingIntentDestinationIfNeeded()
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: brewSessionStore.intentHandoffBanner)
    }

    private func applyPendingIntentDestinationIfNeeded() {
        guard !showLaunchScreen, let data = pendingActionData else { return }
        guard let action = try? JSONDecoder().decode(Phase1IntentAction.self, from: data) else {
            pendingActionData = nil
            return
        }

        switch action {
        case .adjustRecipe(let adjustment, let bannerTitle, let bannerSubtitle):
            if var activeDraft = brewSessionStore.activeEditingDraft {
                activeDraft.applyAdjustment(adjustment)
                brewSessionStore.activeEditingDraft = activeDraft
                brewSessionStore.presentIntentHandoff(title: bannerTitle, subtitle: bannerSubtitle)
                pendingActionData = nil
            } else {
                var draft = templates.first.map { RecipeDraft(template: $0) } ?? RecipeDraft()
                draft.applyAdjustment(adjustment)
                brewSessionStore.requestRecipeComposer(with: draft)
                selectedTab = .recipes
                brewSessionStore.presentIntentHandoff(title: bannerTitle, subtitle: bannerSubtitle)
                pendingActionData = nil
            }
        case .openRecipes(_, let bannerTitle, let bannerSubtitle):
            selectedTab = .recipes
        case .prepareSavedTemplate, .prepareTransientBrew:
            selectedTab = .brew
        case .openRecipeComposer:
            selectedTab = .recipes
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [BrewLog.self, BrewTemplate.self], inMemory: true)
}

struct IntentHandoffBannerView: View {
    let banner: IntentHandoffBanner

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "waveform.badge.mic")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.primaryCopper, Color.brushedCopper],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 38, height: 38)
                .background(
                    Circle()
                        .fill(Color.primaryCopper.opacity(0.12))
                )
                .overlay(
                    Circle()
                        .stroke(Color.primaryCopper.opacity(0.22), lineWidth: 1)
                )
                .shadow(color: Color.primaryCopper.opacity(0.28), radius: 6, y: 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(banner.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.coffeeCream)
                    .lineLimit(2)
                
                if let subtitle = banner.subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.coffeeCream.opacity(0.68))
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.08, green: 0.07, blue: 0.07).opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.9)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.primaryCopper.opacity(0.22), lineWidth: 0.9)
                )
        )
        .shadow(color: Color.black.opacity(0.35), radius: 16, y: 8)
    }
}
