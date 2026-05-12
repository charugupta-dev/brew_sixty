//
//  CoffeeThought.swift
//  brew_sixty
//
//  Created by Charu Gupta on 11/05/26.
//

import Foundation

struct CoffeeThought {
    static let thoughts = [
        "Ratio & Ritual.",
        "Precision in every pour.",
        "Water, bean, time."
    ]
    
    static var random: String {
        thoughts.randomElement() ?? thoughts[0]
    }
}
