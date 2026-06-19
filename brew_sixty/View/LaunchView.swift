import SwiftUI

struct LaunchView: View {
    @State private var thought = CoffeeThought.random
    @Binding var showLaunch: Bool
    @State private var animateText = false
    
    var body: some View {
        ZStack {
            // Espresso Radial Gradient Background
            RadialGradient(
                colors: [Color(red: 0.23, green: 0.16, blue: 0.12), Color(red: 0.08, green: 0.06, blue: 0.05)],
                center: .center,
                startRadius: 10,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("☕️")
                    .font(.system(size: 64))
                    .scaleEffect(animateText ? 1.0 : 0.8)
                    .opacity(animateText ? 1.0 : 0.0)
                
                Text("Brew Sixty")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(Color(red: 0.92, green: 0.85, blue: 0.78))
                    .scaleEffect(animateText ? 1.0 : 0.9)
                    .opacity(animateText ? 1.0 : 0.0)
                
                Text(thought)
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(red: 0.62, green: 0.44, blue: 0.32))
                    .opacity(animateText ? 0.7 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animateText = true
            }
            Task {
                try? await Task.sleep(for: .seconds(2.5))
                withAnimation(.easeInOut(duration: 0.8)) {
                    showLaunch = false
                }
            }
        }
    }
}
