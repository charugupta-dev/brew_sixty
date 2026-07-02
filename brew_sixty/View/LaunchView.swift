import SwiftUI

struct LaunchView: View {
    @State private var thought = CoffeeThought.random
    @Binding var showLaunch: Bool
    @State private var animateText = false
    
    var body: some View {
        ZStack {
            VideoWallpaperBackground()

            VStack(spacing: 16) {
                Text("☕️")
                    .font(.system(size: 64))
                    .scaleEffect(animateText ? 1.0 : 0.8)
                    .opacity(animateText ? 1.0 : 0.0)
                
                Text("Brew Sixty")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(Color.coffeeCream)
                    .scaleEffect(animateText ? 1.0 : 0.9)
                    .opacity(animateText ? 1.0 : 0.0)
                
                Text(thought)
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.coffeeAccent)
                    .scaleEffect(animateText ? 1.0 : 0.9)
                    .opacity(animateText ? 0.7 : 0.0)
            }
        }
        .task {
            withAnimation(.easeOut(duration: 1.2)) {
                animateText = true
            }
            do {
                try await Task.sleep(for: .seconds(2.5))
                withAnimation(.easeInOut(duration: 0.8)) {
                    showLaunch = false
                }
            } catch {
                // Task was cancelled, safely ignore
            }
        }
    }
}

#Preview {
    @Previewable @State var showLaunch = true
    LaunchView(showLaunch: $showLaunch)
}
