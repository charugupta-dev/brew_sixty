//
//  Item.swift
//  brew_sixty
//
//  Created by Charu Gupta on 11/05/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
