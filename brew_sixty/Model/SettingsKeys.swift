//
//  SettingsKeys.swift
//  brew_sixty
//
//  Created by Antigravity.
//

import Foundation

extension String {
    enum SettingsKeys {
        static let preferredRatio = "preferredRatio"
        static let preferredBeanWeight = "preferredBeanWeight"
    }
}

/// Helper to parse decimal numbers in a locale-aware manner
func parseLocaleDouble(_ string: String) -> Double? {
    if let val = Double(string) { return val }
    
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.locale = .current
    return formatter.number(from: string)?.doubleValue
}
