//
//  Color+Theme.swift
//  brew_sixty
//
//  Created by Antigravity.
//

import SwiftUI

extension Color {
    /// Warm Coffee Accent Color
    static let coffeeAccent = Color(red: 0.65, green: 0.41, blue: 0.20)      // #A56933: Coffee Caramel
    
    /// Coffee Cream color for text and highlights (Warm ivory/cream #ECE5DD)
    static let coffeeCream = Color(red: 0.93, green: 0.90, blue: 0.87)
    
    /// Coffee Peach color token
    static let coffeePeach = Color(red: 0.94, green: 0.67, blue: 0.48)
    
    /// Custom palette from user upload
    static let appPrimary = Color(red: 0.65, green: 0.41, blue: 0.20)      // #A56933: Coffee Caramel
    static let appSecondary = Color(red: 0.43, green: 0.47, blue: 0.54)    // #6D788A: Slate Steel
    static let appTertiary = Color(red: 0.20, green: 0.48, blue: 0.75)     // #337ABE: Sky Blue
    static let appNeutral = Color(red: 0.54, green: 0.45, blue: 0.36)      // #89735C: Clay Brown
    
    /// Copper color tokens (Option 1 Warm Amber & Gold)
    static let primaryCopper = Color.appPrimary
    static let brushedCopper = Color.appNeutral
}

extension RadialGradient {
    static var coffeeBackground: RadialGradient {
        RadialGradient(
            colors: [Color(red: 0.33, green: 0.16, blue: 0.09), Color(red: 0.10, green: 0.08, blue: 0.09)],
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
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.02),
                                Color.primaryCopper.opacity(0.50),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
    }
}

extension View {
    func liquidGlassBorder(cornerRadius: CGFloat = 24) -> some View {
        self.modifier(LiquidGlassBorder(cornerRadius: cornerRadius))
    }
    
    func premiumCardBackground(cornerRadius: CGFloat = 24) -> some View {
        self.background(
            ZStack {
                Color(red: 0.11, green: 0.10, blue: 0.09).opacity(0.55)
                
                Image("timer_card_bg")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(0.16)
                    .blendMode(.plusLighter)
                    .clipped()
            }
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

