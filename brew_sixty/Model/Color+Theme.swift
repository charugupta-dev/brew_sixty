//
//  Color+Theme.swift
//  brew_sixty
//
//  Created by Charu Gupta.
//

import SwiftUI

extension Color {
    /// Warm Coffee Accent Color (Deep Forest Pine Green)
    static let coffeeAccent = Color(red: 0.18, green: 0.32, blue: 0.20)
    
    /// Coffee Cream color for text and highlights (Charcoal brown)
    static let coffeeCream = Color(red: 0.36, green: 0.33, blue: 0.29)
    
    /// Coffee Peach color token (Secondary pine green)
    static let coffeePeach = Color(red: 0.25, green: 0.42, blue: 0.27)
    
    /// Custom palette from user upload
    static let appPrimary = Color(red: 0.18, green: 0.32, blue: 0.20)
    static let appSecondary = Color(red: 0.54, green: 0.55, blue: 0.49)
    static let appTertiary = Color(red: 0.25, green: 0.42, blue: 0.27)
    static let appNeutral = Color(red: 0.36, green: 0.33, blue: 0.29)
    
    /// Copper color tokens (Option 1 Warm Amber & Gold) -> Mapped to Nordic Light
    static let primaryCopper = Color(red: 0.18, green: 0.32, blue: 0.20)
    static let brushedCopper = Color(red: 0.54, green: 0.55, blue: 0.49)
    static let appPanel = Color(red: 0.98, green: 0.97, blue: 0.96)
    static let appSheetTop = Color(red: 0.96, green: 0.95, blue: 0.93)
    static let appSheetBottom = Color(red: 0.96, green: 0.95, blue: 0.93)
    static let deepRoastInk = Color.white // White text inside buttons
}

extension RadialGradient {
    static var coffeeBackground: RadialGradient {
        RadialGradient(
            colors: [Color(red: 0.98, green: 0.97, blue: 0.96), Color(red: 0.96, green: 0.95, blue: 0.93)],
            center: .center,
            startRadius: 10,
            endRadius: 500
        )
    }
}

struct LiquidGlassBorder: ViewModifier {
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color(red: 0.86, green: 0.84, blue: 0.81),
                                Color(red: 0.86, green: 0.84, blue: 0.81).opacity(0.5),
                                Color(red: 0.18, green: 0.32, blue: 0.20).opacity(0.2),
                                Color(red: 0.86, green: 0.84, blue: 0.81).opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func liquidGlassBorder(cornerRadius: CGFloat = 24) -> some View {
        self.modifier(LiquidGlassBorder(cornerRadius: cornerRadius))
    }
    
    func premiumCardBackground(cornerRadius: CGFloat = 24) -> some View {
        self.background(
            ZStack {
                Color(red: 0.98, green: 0.97, blue: 0.96) // Crisp white card background
                
                Image("timer_card_bg")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(0.04) // Very subtle texture
                    .blendMode(.multiply)
                    .clipped()
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color(red: 0.86, green: 0.84, blue: 0.81), lineWidth: 1.5) // Thin birch gray border
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

#Preview {
    ZStack {
        // Static background representing the slate-blue theme
        LinearGradient(
            colors: [Color(red: 0.05, green: 0.05, blue: 0.05), Color(red: 0.08, green: 0.09, blue: 0.12)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        VStack(spacing: 28) {
            Text("Custom Coffee Theme")
                .font(.system(.title2, design: .serif))
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            HStack(spacing: 12) {
                colorSwatch(name: "Primary", color: .appPrimary)
                colorSwatch(name: "Secondary", color: .appSecondary)
                colorSwatch(name: "Tertiary", color: .appTertiary)
                colorSwatch(name: "Neutral", color: .appNeutral)
            }
            
            VStack(spacing: 8) {
                Text("Liquid Glass Border")
                    .font(.system(.subheadline, design: .serif))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text("Translucent Overlay (15% Opacity)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding()
            .frame(width: 240, height: 110)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.10, green: 0.09, blue: 0.09).opacity(0.15))
            )
            .liquidGlassBorder(cornerRadius: 16)
        }
        .padding()
    }
}

@ViewBuilder
private func colorSwatch(name: String, color: Color) -> some View {
    VStack(spacing: 6) {
        RoundedRectangle(cornerRadius: 10)
            .fill(color)
            .frame(width: 65, height: 65)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
        
        Text(name)
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(.white.opacity(0.7))
            .multilineTextAlignment(.center)
    }
}
