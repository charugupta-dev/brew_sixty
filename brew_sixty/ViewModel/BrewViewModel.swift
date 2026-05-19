//
//  BrewViewModel.swift
//  brew_sixty
//
//  Created by Charu Gupta on 11/05/26.
//

import Foundation
import SwiftData

@Observable
final class BrewViewModel {
    
    let beanWeight: Double
    let ratio: Double
    
    var startDate: Date? = nil
    var isRunning: Bool = false
    
    //(Standard V60 timings)
    private let bloomDuration: TimeInterval = 45.0
    private let totalDuration: TimeInterval = 150.0
    var finalElapsed: TimeInterval = 0
    var isFinished: Bool = false
    
    init(beanWeight: Double, ratio: Double) {
        self.beanWeight = beanWeight
        self.ratio = ratio
    }
    
    // MARK: - Computed Properties
    
    var targetWater: Double {
        beanWeight * ratio
    }
    
    var bloomWater: Double {
        beanWeight * 3.0
    }
    
    // MARK: - Intents / Actions
    
    func toggleTimer() {
        if isRunning {
            finalElapsed = abs(Date().timeIntervalSince(startDate ?? Date()))
            isRunning = false
        } else {
            startDate = Date()
            finalElapsed = 0
            isRunning = true
        }
    }
    
    func calculateElapsed(from contextDate: Date) -> TimeInterval {
        // If we aren't running, just return the frozen time
        guard let start = startDate, isRunning else { return finalElapsed }
        
        let elapsed = contextDate.timeIntervalSince(start)
        
        // Auto-stop logic
        if elapsed >= totalDuration {
            // Push the state change to the next run loop to avoid SwiftUI warnings
            DispatchQueue.main.async {
                if self.isRunning {
                    self.finalElapsed = self.totalDuration
                    self.isRunning = false
                    self.isFinished = true
                }
            }
            return totalDuration
        }
        
        return elapsed
    }
    
    func getProgress(for elapsed: TimeInterval) -> Double {
        return min(elapsed / totalDuration, 1.0)
    }
    
    func getPhaseText(for elapsed: TimeInterval) -> String {
        if elapsed == 0 {
            return "Target: \(Int(targetWater)) g"
        } else if elapsed < bloomDuration {
            return "Bloom: Pour \(Int(bloomWater)) g"
        } else if elapsed < totalDuration {
            return "Drawdown: Pour to \(Int(targetWater)) g"
        } else {
            return "Enjoy your coffee"
        }
    }
    
    // Injects the context so the VM remains decoupled from the UI Environment
    func saveLog(in context: ModelContext) {
        let log = BrewLog(
            timestamp: .now,
            beanWeightGram: beanWeight,
            ratio: ratio
        )
        context.insert(log)
        print("log -- \(log.timestamp)")
        try? context.save()
    }
}
