//
//  Color+Theme.swift
//  brew_sixty
//
//  Created by Antigravity.
//

import SwiftUI

extension Color {
    /// Warm Coffee Accent Color
    static let coffeeAccent = Color(red: 0.62, green: 0.44, blue: 0.32)
    
    /// Coffee Cream color for text and highlights
    static let coffeeCream = Color(red: 0.92, green: 0.85, blue: 0.78)
    
    /// Coffee Peach color token
    static let coffeePeach = Color(red: 0.94, green: 0.67, blue: 0.48)
    
    /// Copper color tokens (warm latte-gold / honey-amber)
    static let primaryCopper = Color(red: 0.82, green: 0.62, blue: 0.34)
    static let brushedCopper = Color(red: 0.90, green: 0.75, blue: 0.48)
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

