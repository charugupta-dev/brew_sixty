//
//  ContentView.swift
//  brew_sixty
//
//  Created by Charu Gupta on 11/05/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showLaunchScreen = true
    
    var body: some View {
        ZStack {
            if showLaunchScreen {
                LaunchView(showLaunch: $showLaunchScreen)
                    .transition(.opacity)
            } else {
                TabView {
                    HomeView()
                        .tabItem {
                            Label("Brews", systemImage: "cup.and.saucer.fill")
                        }
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                }
                .tint(.coffeeAccent)
                .transition(.opacity)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: BrewLog.self, inMemory: true)
}
