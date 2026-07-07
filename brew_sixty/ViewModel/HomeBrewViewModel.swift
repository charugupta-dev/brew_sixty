import Foundation
import SwiftUI
import SwiftData

@Observable
@MainActor
final class HomeBrewViewModel: Identifiable {
    let id = UUID()
    
    // MARK: - Properties
    var method: BrewMethod
    var beanWeight: Double
    let initialBeanWeight: Double
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
    var onReset: (() -> Void)?
    
    // MARK: - Computed Properties
    private var isPourOverMethod: Bool {
        method == .v60 || method == .chemex
    }

    private var steepPhaseDuration: TimeInterval {
        switch method {
        case .frenchPress:
            return customSteepDuration ?? AppConstants.BrewTimer.frenchPressSteepDuration
        case .aeropress:
            return customSteepDuration ?? AppConstants.BrewTimer.aeropressSteepDuration
        case .v60, .chemex:
            return 0.0
        }
    }

    var bloomDuration: TimeInterval {
        if isPourOverMethod {
            return customBloomDuration ?? AppConstants.BrewTimer.v60BloomDuration
        }
        return 0.0
    }
    
    var totalDuration: TimeInterval {
        switch method {
        case .v60:
            return bloomDuration + AppConstants.BrewTimer.v60DrawdownDuration
        case .chemex:
            return bloomDuration + (customSteepDuration ?? AppConstants.BrewTimer.chemexDrawdownDuration)
        case .frenchPress:
            return steepPhaseDuration + (customPressDuration ?? AppConstants.BrewTimer.frenchPressPlungeDuration)
        case .aeropress:
            return steepPhaseDuration + (customPressDuration ?? AppConstants.BrewTimer.aeropressPressDuration)
        }
    }
    
    var targetWater: Double {
        if isPourOverMethod {
            return beanWeight * ratio
        } else {
            return waterVolume
        }
    }
    
    var bloomWater: Double {
        beanWeight * AppConstants.BrewTimer.bloomWaterMultiplier
    }

    var firstPourWater: Double {
        targetWater * AppConstants.BrewTimer.firstPourMultiplier
    }
    
    var activePhaseIndex: Int {
        if !isRunning && elapsed == 0 { return 0 }
        if isFinished { return -1 }
        switch method {
        case .v60, .chemex:
            let bloom = bloomDuration
            if bloom > 0 && elapsed < bloom {
                return 0
            } else if elapsed < (bloom + AppConstants.BrewTimer.pourOverMainPourDuration) {
                return bloom > 0 ? 1 : 0
            } else {
                return bloom > 0 ? 2 : 1
            }
        case .frenchPress, .aeropress:
            if elapsed < steepPhaseDuration {
                return 0
            } else {
                return 1
            }
        }
    }

    var currentPhaseTitle: String {
        if isFinished || elapsed >= totalDuration {
            return AppConstants.BrewTimer.donePhaseTitle
        }

        switch method {
        case .v60, .chemex:
            let bloom = bloomDuration
            if bloom > 0 {
                switch activePhaseIndex {
                case 0: return AppConstants.BrewTimer.bloomPhaseTitle
                case 1: return AppConstants.BrewTimer.firstPourPhaseTitle
                default: return AppConstants.BrewTimer.finalDrawdownPhaseTitle
                }
            } else {
                return activePhaseIndex == 0 ? AppConstants.BrewTimer.firstPourPhaseTitle : AppConstants.BrewTimer.finalDrawdownPhaseTitle
            }
        case .frenchPress:
            return activePhaseIndex == 0 ? AppConstants.BrewTimer.steepPhaseTitle : AppConstants.BrewTimer.plungePhaseTitle
        case .aeropress:
            return activePhaseIndex == 0 ? AppConstants.BrewTimer.steepPhaseTitle : AppConstants.BrewTimer.pressPhaseTitle
        }
    }
    
    // MARK: - Initialization
    init(method: BrewMethod, beanWeight: Double, ratio: Double, waterVolume: Double) {
        self.method = method
        self.beanWeight = beanWeight
        self.initialBeanWeight = beanWeight
        self.ratio = ratio
        self.waterVolume = waterVolume
    }
    
    convenience init(method: BrewMethod, beanWeight: Double, ratio: Double, waterVolume: Double, bloomDuration: TimeInterval? = nil, steepDuration: TimeInterval? = nil, pressDuration: TimeInterval? = nil) {
        self.init(method: method, beanWeight: beanWeight, ratio: ratio, waterVolume: waterVolume)
        self.customBloomDuration = bloomDuration
        self.customSteepDuration = steepDuration
        self.customPressDuration = pressDuration
    }

    convenience init(template: BrewTemplate) {
        self.init(
            method: template.method,
            beanWeight: template.beanWeight,
            ratio: template.ratio,
            waterVolume: template.waterVolume,
            bloomDuration: template.method == .v60 || template.method == .chemex
                ? (template.preInfusionDuration > 0 ? template.preInfusionDuration : AppConstants.BrewTimer.v60BloomDuration)
                : 0.0,
            steepDuration: template.steepDuration,
            pressDuration: template.pressDuration
        )
    }

    convenience init(draft: RecipeDraft) {
        self.init(
            method: draft.method,
            beanWeight: draft.beanWeight,
            ratio: draft.ratio,
            waterVolume: draft.waterVolume,
            bloomDuration: draft.isPourOverMethod ? draft.preInfusionDuration : 0.0,
            steepDuration: draft.isPourOverMethod ? 0.0 : draft.steepDuration,
            pressDuration: draft.pressDuration
        )
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
        if isFinished || elapsed >= totalDuration {
            prepareForRestart()
        }

        isFinished = false
        isRunning = true
        let currentStartDate = Date().addingTimeInterval(-elapsed)
        startDate = currentStartDate
        
        timer = Timer.scheduledTimer(withTimeInterval: AppConstants.BrewTimer.timerInterval, repeats: true) { [weak self] timer in
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
    
    func resetTimer(notifyObservers: Bool = true) {
        prepareForRestart()

        if notifyObservers {
            onReset?()
        }
    }
    
    func skipPhase() {
        let newElapsed: TimeInterval
        switch method {
        case .v60, .chemex:
            let bloom = bloomDuration
            if bloom > 0 && elapsed < bloom {
                newElapsed = bloom
            } else {
                let firstPourEnd = (bloom > 0 ? bloom : 0.0) + AppConstants.BrewTimer.pourOverMainPourDuration
                if elapsed < firstPourEnd {
                    newElapsed = firstPourEnd
                } else {
                    newElapsed = totalDuration
                }
            }
        case .frenchPress, .aeropress:
            if elapsed < steepPhaseDuration {
                newElapsed = steepPhaseDuration
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
            return AppConstants.BrewTimer.enjoyCoffeeMessage
        }
        
        switch method {
        case .v60, .chemex:
            let bloom = bloomDuration
            if elapsed == 0 {
                return "\(AppConstants.BrewTimer.targetPrefix) \(formattedGrams(targetWater))"
            } else if bloom > 0 && elapsed < bloom {
                return "\(AppConstants.BrewTimer.bloomInstructionPrefix) \(formattedGrams(bloomWater))"
            } else if elapsed < (bloom > 0 ? bloom : 0.0) + AppConstants.BrewTimer.pourOverMainPourDuration {
                return "\(AppConstants.BrewTimer.firstPourInstructionPrefix) \(formattedGrams(firstPourWater))"
            } else {
                return "\(AppConstants.BrewTimer.drawdownInstructionPrefix) \(formattedGrams(targetWater))"
            }
        case .frenchPress, .aeropress:
            if elapsed == 0 {
                return "\(AppConstants.BrewTimer.targetPrefix) \(formattedGrams(targetWater))"
            } else if elapsed < steepPhaseDuration {
                return "\(AppConstants.BrewTimer.steepInstructionPrefix) \(formattedGrams(targetWater))"
            } else {
                return method == .frenchPress ? AppConstants.BrewTimer.plungeInstruction : AppConstants.BrewTimer.pressInstruction
            }
        }
    }

    private func formattedGrams(_ value: Double) -> String {
        "\(Int(value.rounded()))\(AppConstants.Text.gramsUnit)"
    }

    private func prepareForRestart() {
        isRunning = false
        isFinished = false
        elapsed = 0
        startDate = nil
        timer?.invalidate()
        timer = nil
        beanWeight = initialBeanWeight
    }
}
