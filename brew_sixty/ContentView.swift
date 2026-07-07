import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showLaunchScreen = true
    @State private var selectedTab: Tab = .brew
    @State private var brewSessionStore = BrewSessionStore()
    @AppStorage(ProfilePreferences.Keys.hasCompletedProfile) private var hasCompletedProfile = false
    
    enum Tab {
        case brew
        case recipes
    }
    
    init() {
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
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(
            isPresented: Binding(
                get: { !showLaunchScreen && !hasCompletedProfile },
                set: { _ in }
            )
        ) {
            ProfileSetupView(mode: .onboarding)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: BrewLog.self, inMemory: true)
}
