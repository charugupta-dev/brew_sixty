import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showLaunchScreen = true
    @State private var selectedTab: Tab = .brew
    
    enum Tab {
        case brew
        case methods
    }
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()
        
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
                    HomeView(selectedTab: $selectedTab)
                        .tag(Tab.brew)
                        .tabItem {
                            Label("BREW", systemImage: "cup.and.saucer.fill")
                        }
                    
                    MethodsView(selectedTab: $selectedTab)
                        .tag(Tab.methods)
                        .tabItem {
                            Label("METHODS", systemImage: "square.grid.2x2.fill")
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tint(Color.primaryCopper)
                .toolbarBackground(.hidden, for: .tabBar)
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: BrewLog.self, inMemory: true)
}
