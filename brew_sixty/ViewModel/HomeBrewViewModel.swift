import Foundation
import SwiftUI

/// Represents the supported brewing methods in the app.
enum BrewMethod: String, CaseIterable, Codable {
    case v60 = "V60"
    case frenchPress = "FrenchPress"
}

@Observable
@MainActor
final class HomeBrewViewModel: Identifiable {
    let id = UUID()
    
    // MARK: - Properties
    var method: BrewMethod
    var beanWeight: Double
    var ratio: Double
    var waterVolume: Double
    
    var isRunning = false
    var isFinished = false
    var elapsed: TimeInterval = 0
    
    nonisolated(unsafe) private var timer: Timer? = nil
    private var startDate: Date? = nil
    
    // MARK: - Configuration Constants
    private struct Config {
        static let v60BloomDuration: TimeInterval = 45.0
        static let v60TotalDuration: TimeInterval = 150.0 // 2m 30s
        static let frenchPressSteepDuration: TimeInterval = 240.0 // 4m 00s
        static let frenchPressPlungeDuration: TimeInterval = 15.0 // 15s plunge
        static let bloomWaterMultiplier: Double = 3.0
        static let timerInterval: TimeInterval = 0.1
    }
    
    // MARK: - Computed Properties
    var bloomDuration: TimeInterval {
        switch method {
        case .v60: return Config.v60BloomDuration
        case .frenchPress: return 0.0
        }
    }
    
    var totalDuration: TimeInterval {
        switch method {
        case .v60: 
            return Config.v60TotalDuration
        case .frenchPress: 
            return Config.frenchPressSteepDuration + Config.frenchPressPlungeDuration
        }
    }
    
    var targetWater: Double {
        switch method {
        case .v60: return beanWeight * ratio
        case .frenchPress: return waterVolume
        }
    }
    
    var bloomWater: Double {
        beanWeight * Config.bloomWaterMultiplier
    }
    
    // MARK: - Initialization
    init(method: BrewMethod, beanWeight: Double, ratio: Double, waterVolume: Double) {
        self.method = method
        self.beanWeight = beanWeight
        self.ratio = ratio
        self.waterVolume = waterVolume
    }
    
    deinit {
        // Run invalidation on the main actor since timer is scheduled there
        let activeTimer = timer
        DispatchQueue.main.async {
            activeTimer?.invalidate()
        }
    }
    
    // MARK: - Timer Controls
    func toggleTimer() {
        if isRunning {
            pause()
        } else {
            start()
        }
    }
    
    private func start() {
        isRunning = true
        let currentStartDate = Date().addingTimeInterval(-elapsed)
        startDate = currentStartDate
        
        timer = Timer.scheduledTimer(withTimeInterval: Config.timerInterval, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            Task { @MainActor in
                guard self.isRunning, let startDate = self.startDate else { return }
                let nowElapsed = Date().timeIntervalSince(startDate)
                
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
    
    private func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    func resetTimer() {
        isRunning = false
        isFinished = false
        elapsed = 0
        startDate = nil
        timer?.invalidate()
        timer = nil
    }
    
    func skipPhase() {
        let newElapsed: TimeInterval
        switch method {
        case .v60:
            if elapsed < bloomDuration {
                newElapsed = bloomDuration
            } else {
                newElapsed = totalDuration
            }
        case .frenchPress:
            if elapsed < Config.frenchPressSteepDuration {
                newElapsed = Config.frenchPressSteepDuration
            } else {
                newElapsed = totalDuration
            }
        }
        
        elapsed = newElapsed
        
        // Fix: Update the start date dynamically so the timer calculates the skipped time correctly
        if isRunning {
            startDate = Date().addingTimeInterval(-newElapsed)
        }
    }
    
    func getProgress() -> Double {
        min(elapsed / totalDuration, 1.0)
    }
    
    func getPhaseText() -> String {
        switch method {
        case .v60:
            if elapsed == 0 {
                return "Target: \(Int(targetWater))g"
            } else if elapsed < bloomDuration {
                return "Bloom: Pour \(Int(bloomWater))g"
            } else {
                return "Drawdown: Pour to \(Int(targetWater))g"
            }
        case .frenchPress:
            if elapsed < Config.frenchPressSteepDuration {
                return "Steep: Let it sit"
            } else {
                return "Plunge: Press down slowly"
            }
        }
    }
}
