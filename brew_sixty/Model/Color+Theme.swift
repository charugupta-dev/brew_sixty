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

