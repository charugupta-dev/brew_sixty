//  BrewLog.swift
//  brew_sixty
//
//  Created by Charu Gupta on 11/05/26.
//

import Foundation
import SwiftData

@Model
final class BrewLog {
    var timestamp: Date
    var beanWeightGram: Double
    var ratio: Double
    var thought: String?
    
    var totalWaterWeight: Double {
        beanWeightGram * ratio
    }
    
    var bloomWaterWeight: Double {
        beanWeightGram * 3
    }
    
    init(timestamp: Date = .now, beanWeightGram: Double = 8.0, ratio: Double = 12.0, thought: String? = nil) {
        self.timestamp = timestamp
        self.beanWeightGram = beanWeightGram
        self.ratio = ratio
        self.thought = thought
    }
}
