import SwiftUI

struct LaunchView: View {
    @Binding var showLaunch: Bool
    @State private var animateText = false
    
    var body: some View {
        ZStack {
            VideoWallpaperBackground(style: .hero, isMasked: false)

            VStack(spacing: 16) {
                
                Text("Brew Sixty")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(Color.coffeeCream)
                    .scaleEffect(animateText ? 1.0 : 0.9)
                    .opacity(animateText ? 1.0 : 0.0)
                
                Text("Slow coffee, Beautifully timed")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.primaryCopper)
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
