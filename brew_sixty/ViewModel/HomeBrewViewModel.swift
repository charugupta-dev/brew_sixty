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
    
    private var timer: Timer? = nil
    private var startDate: Date? = nil
    
    // MARK: - Configuration Constants
    private struct Config {
        static let v60BloomDuration: TimeInterval = 45.0
        static let v60TotalDuration: TimeInterval = 150.0 // 2m 30s
        static let v60FirstPourMultiplier: Double = 0.6
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
        beanWeight * ratio
    }
    
    var bloomWater: Double {
        beanWeight * Config.bloomWaterMultiplier
    }

    var firstPourWater: Double {
        targetWater * Config.v60FirstPourMultiplier
    }
    
    var activePhaseIndex: Int {
        if !isRunning && elapsed == 0 { return 0 }
        if isFinished { return -1 }
        switch method {
        case .v60:
            if elapsed < Config.v60BloomDuration {
                return 0
            } else if elapsed < (Config.v60BloomDuration + 60.0) {
                return 1
            } else {
                return 2
            }
        case .frenchPress:
            if elapsed < Config.frenchPressSteepDuration {
                return 0
            } else {
                return 1
            }
        }
    }

    var currentPhaseTitle: String {
        if isFinished || elapsed >= totalDuration {
            return "Done"
        }

        switch method {
        case .v60:
            switch activePhaseIndex {
            case 0: return "Bloom"
            case 1: return "First Pour"
            default: return "Final Drawdown"
            }
        case .frenchPress:
            return activePhaseIndex == 0 ? "Steep" : "Plunge"
        }
    }
    
    // MARK: - Initialization
    init(method: BrewMethod, beanWeight: Double, ratio: Double, waterVolume: Double) {
        self.method = method
        self.beanWeight = beanWeight
        self.ratio = ratio
        self.waterVolume = waterVolume
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
            Task { @MainActor [weak self] in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
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
        beanWeight = 8.0
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
        
        if newElapsed >= totalDuration {
            elapsed = totalDuration
            isRunning = false
            isFinished = true
            timer?.invalidate()
            timer = nil
        } else {
            elapsed = newElapsed
            if isRunning {
                startDate = Date().addingTimeInterval(-newElapsed)
            }
        }
    }
    
    func getProgress() -> Double {
        min(elapsed / totalDuration, 1.0)
    }
    
    func getPhaseText() -> String {
        if isFinished || elapsed >= totalDuration {
            return "Enjoy your coffee!"
        }
        
        switch method {
        case .v60:
            if elapsed == 0 {
                return "Target: \(formattedGrams(targetWater))"
            } else if elapsed < bloomDuration {
                return "Bloom: Pour \(formattedGrams(bloomWater))"
            } else {
                return "Drawdown: Pour to \(formattedGrams(targetWater))"
            }
        case .frenchPress:
            if elapsed == 0 {
                return "Target: \(formattedGrams(targetWater))"
            } else if elapsed < Config.frenchPressSteepDuration {
                return "Steep: Pour \(formattedGrams(targetWater))"
            } else {
                return "Plunge: Press down slowly"
            }
        }
    }

    private func formattedGrams(_ value: Double) -> String {
        "\(Int(value.rounded()))g"
    }
}
