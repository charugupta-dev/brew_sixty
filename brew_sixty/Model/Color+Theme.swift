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
    
    /// Copper color tokens
    static let primaryCopper = Color(red: 0.85, green: 0.45, blue: 0.25)
    static let brushedCopper = Color(red: 0.94, green: 0.67, blue: 0.48)
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
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.02),
                                Color.primaryCopper.opacity(0.12),
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
}

