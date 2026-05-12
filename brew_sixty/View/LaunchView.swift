//
//  LaunchView.swift
//  brew_sixty
//
//  Created by Charu Gupta on 11/05/26.
//

import SwiftUI

struct LaunchView: View {
    @State private var thought = CoffeeThought.random
    @Binding var showLaunch: Bool
    
    var body: some View {
        ZStack {
            // Base layer structure
            Color.clear.ignoresSafeArea()
            
            // Content structure
            VStack {
                Text(thought)
            }
        }
        .onAppear {
            Task {
                try? await Task.sleep(for: .seconds(2))
                withAnimation(.easeInOut(duration: 0.8)) {
                    showLaunch = false
                }
            }
        }
    }
}
