import Foundation
import SwiftUI

@Observable
final class HomeBrewViewModel: Identifiable {
    let id = UUID()
    var method: String // "V60" or "FrenchPress"
    var beanWeight: Double
    var ratio: Double
    var waterVolume: Double
    
    var isRunning = false
    var isFinished = false
    var elapsed: TimeInterval = 0
    private var timer: Timer? = nil
    
    var bloomDuration: TimeInterval {
        method == "V60" ? 45.0 : 0.0
    }
    
    var totalDuration: TimeInterval {
        method == "V60" ? 150.0 : 255.0 // V60: 2:30; FrenchPress: 4:00 steep + 15s plunge
    }
    
    var targetWater: Double {
        method == "V60" ? (beanWeight * ratio) : waterVolume
    }
    
    var bloomWater: Double {
        beanWeight * 3.0
    }
    
    init(method: String, beanWeight: Double, ratio: Double, waterVolume: Double) {
        self.method = method
        self.beanWeight = beanWeight
        self.ratio = ratio
        self.waterVolume = waterVolume
    }
    
    func toggleTimer() {
        if isRunning {
            isRunning = false
            timer?.invalidate()
            timer = nil
        } else {
            isRunning = true
            let start = Date().addingTimeInterval(-elapsed)
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                let nowElapsed = Date().timeIntervalSince(start)
                if nowElapsed >= self.totalDuration {
                    self.elapsed = self.totalDuration
                    self.isRunning = false
                    self.isFinished = true
                    self.timer?.invalidate()
                    self.timer = nil
                } else {
                    self.elapsed = nowElapsed
                }
            }
        }
    }
    
    func resetTimer() {
        isRunning = false
        isFinished = false
        elapsed = 0
        timer?.invalidate()
        timer = nil
    }
    
    func skipPhase() {
        if method == "V60" {
            if elapsed < bloomDuration {
                elapsed = bloomDuration
            } else {
                elapsed = totalDuration
            }
        } else {
            if elapsed < 240.0 {
                elapsed = 240.0
            } else {
                elapsed = totalDuration
            }
        }
    }
    
    func getProgress() -> Double {
        return min(elapsed / totalDuration, 1.0)
    }
    
    func getPhaseText() -> String {
        if method == "V60" {
            if elapsed == 0 {
                return "Target: \(Int(targetWater))g"
            } else if elapsed < bloomDuration {
                return "Bloom: Pour \(Int(bloomWater))g"
            } else {
                return "Drawdown: Pour to \(Int(targetWater))g"
            }
        } else {
            if elapsed < 240.0 {
                return "Steep: Let it sit"
            } else {
                return "Plunge: Press down slowly"
            }
        }
    }
}
