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
                HomeView()
                    .transition(.opacity)
            }
        }
    }
}

#Preview {
    ContentView()
}
