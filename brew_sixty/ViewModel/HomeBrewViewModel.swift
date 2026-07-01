import Foundation
import SwiftUI

/// Represents the supported brewing methods in the app.
enum BrewMethod: String, CaseIterable, Codable {
    case v60 = "V60"
    case frenchPress = "FrenchPress"
    case aeropress = "Aeropress"
    case chemex = "Chemex"
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
    
    // Custom recipe properties
    var customBloomDuration: TimeInterval? = nil
    var customSteepDuration: TimeInterval? = nil
    var customPressDuration: TimeInterval? = nil
    var customPreInfusionActive: Bool? = nil
    
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
        if method == .v60 || method == .chemex {
            if let active = customPreInfusionActive, !active { return 0.0 }
            return customBloomDuration ?? Config.v60BloomDuration
        }
        return 0.0
    }
    
    var totalDuration: TimeInterval {
        switch method {
        case .v60:
            return (customBloomDuration ?? Config.v60BloomDuration) + 105.0 // default remaining
        case .chemex:
            return 240.0
        case .frenchPress:
            let steep = customSteepDuration ?? Config.frenchPressSteepDuration
            let plunge = customPressDuration ?? Config.frenchPressPlungeDuration
            return steep + plunge
        case .aeropress:
            let steep = customSteepDuration ?? 60.0
            let press = customPressDuration ?? 30.0
            return steep + press
        }
    }
    
    var targetWater: Double {
        if method == .v60 || method == .chemex {
            return beanWeight * ratio
        } else {
            return waterVolume
        }
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
        case .v60, .chemex:
            let bloom = bloomDuration
            if bloom > 0 && elapsed < bloom {
                return 0
            } else if elapsed < (bloom + 60.0) {
                return bloom > 0 ? 1 : 0
            } else {
                return bloom > 0 ? 2 : 1
            }
        case .frenchPress, .aeropress:
            let steep = customSteepDuration ?? (method == .frenchPress ? Config.frenchPressSteepDuration : 60.0)
            if elapsed < steep {
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
        case .v60, .chemex:
            let bloom = bloomDuration
            if bloom > 0 {
                switch activePhaseIndex {
                case 0: return "Bloom"
                case 1: return "First Pour"
                default: return "Final Drawdown"
                }
            } else {
                return activePhaseIndex == 0 ? "First Pour" : "Final Drawdown"
            }
        case .frenchPress:
            return activePhaseIndex == 0 ? "Steep" : "Plunge"
        case .aeropress:
            return activePhaseIndex == 0 ? "Steep" : "Press"
        }
    }
    
    // MARK: - Initialization
    init(method: BrewMethod, beanWeight: Double, ratio: Double, waterVolume: Double) {
        self.method = method
        self.beanWeight = beanWeight
        self.ratio = ratio
        self.waterVolume = waterVolume
    }
    
    convenience init(method: BrewMethod, beanWeight: Double, ratio: Double, waterVolume: Double, bloomDuration: TimeInterval? = nil, steepDuration: TimeInterval? = nil, pressDuration: TimeInterval? = nil, preInfusionActive: Bool? = nil) {
        self.init(method: method, beanWeight: beanWeight, ratio: ratio, waterVolume: waterVolume)
        self.customBloomDuration = bloomDuration
        self.customSteepDuration = steepDuration
        self.customPressDuration = pressDuration
        self.customPreInfusionActive = preInfusionActive
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
        case .v60, .chemex:
            let bloom = bloomDuration
            if bloom > 0 && elapsed < bloom {
                newElapsed = bloom
            } else {
                let firstPourEnd = (bloom > 0 ? bloom : 0.0) + 60.0
                if elapsed < firstPourEnd {
                    newElapsed = firstPourEnd
                } else {
                    newElapsed = totalDuration
                }
            }
        case .frenchPress, .aeropress:
            let steep = customSteepDuration ?? (method == .frenchPress ? Config.frenchPressSteepDuration : 60.0)
            if elapsed < steep {
                newElapsed = steep
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
        case .v60, .chemex:
            let bloom = bloomDuration
            if elapsed == 0 {
                return "Target: \(formattedGrams(targetWater))"
            } else if bloom > 0 && elapsed < bloom {
                return "Bloom: Pour \(formattedGrams(bloomWater))"
            } else {
                return "Drawdown: Pour to \(formattedGrams(targetWater))"
            }
        case .frenchPress, .aeropress:
            let steep = customSteepDuration ?? (method == .frenchPress ? Config.frenchPressSteepDuration : 60.0)
            if elapsed == 0 {
                return "Target: \(formattedGrams(targetWater))"
            } else if elapsed < steep {
                return "Steep: Pour \(formattedGrams(targetWater))"
            } else {
                return method == .frenchPress ? "Plunge: Press down slowly" : "Press: Press down slowly"
            }
        }
    }

    private func formattedGrams(_ value: Double) -> String {
        "\(Int(value.rounded()))g"
    }
}
