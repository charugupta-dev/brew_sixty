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
    var isCountingDown = false
    var isFinished = false
    var elapsed: TimeInterval = 0
    var countdownRemaining = AppConstants.BrewTimer.preBrewCountdownDuration

    private var timer: Timer? = nil
    private var countdownTimer: Timer? = nil
    private var startDate: Date? = nil
    private var activeWaitMessage: String? = nil
    private var activeWaitPhaseIdentifier: String? = nil
    private var lastWaitMessage: String? = nil

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

    var immersionPourDuration: TimeInterval {
        guard !isPourOverMethod else { return 0.0 }
        return min(steepPhaseDuration, AppConstants.BrewTimer.immersionPourDuration)
    }

    var immersionWaitDuration: TimeInterval {
        max(steepPhaseDuration - immersionPourDuration, 0.0)
    }

    var bloomDuration: TimeInterval {
        if isPourOverMethod {
            return customBloomDuration ?? AppConstants.BrewTimer.v60BloomDuration
        }
        return 0.0
    }

    var bloomPourDuration: TimeInterval {
        guard isPourOverMethod else { return 0.0 }
        return min(bloomDuration, AppConstants.BrewTimer.bloomPourDuration)
    }

    var bloomWaitDuration: TimeInterval {
        max(bloomDuration - bloomPourDuration, 0.0)
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

    var shouldShowPourStream: Bool {
        switch method {
        case .v60, .chemex:
            guard !isCountingDown, !isFinished, elapsed > 0 else { return false }

            if bloomDuration > 0 {
                return elapsed < bloomPourDuration || elapsed >= bloomDuration
            }

            return elapsed < totalDuration
        case .frenchPress, .aeropress:
            return isRunning || (elapsed > 0 && elapsed < totalDuration)
        }
    }

    var isPassiveWaitPhase: Bool {
        guard !isCountingDown, !isFinished else { return false }

        switch method {
        case .v60, .chemex:
            return bloomDuration > 0 && elapsed >= bloomPourDuration && elapsed < bloomDuration
        case .frenchPress, .aeropress:
            return elapsed >= immersionPourDuration && elapsed < steepPhaseDuration
        }
    }

    var waitingMessage: String? {
        guard isPassiveWaitPhase else { return nil }
        return activeWaitMessage
    }

    var currentPhaseRemainingTime: TimeInterval {
        let (_, phaseEnd) = currentPhaseBounds
        return max(phaseEnd - elapsed, 0)
    }

    var currentPhaseProgress: Double {
        let (phaseStart, phaseEnd) = currentPhaseBounds
        let phaseDuration = max(phaseEnd - phaseStart, 0.001)
        let phaseElapsed = min(max(elapsed - phaseStart, 0), phaseDuration)
        return phaseElapsed / phaseDuration
    }

    var currentPhaseMetricText: String? {
        if isFinished {
            return nil
        }

        switch method {
        case .v60, .chemex:
            if isCountingDown {
                return formattedGrams(bloomDuration > 0 ? bloomWater : targetWater)
            } else if elapsed == 0 {
                return formattedGrams(targetWater)
            } else if bloomDuration > 0 && elapsed < bloomDuration {
                return formattedGrams(bloomWater)
            } else {
                return formattedGrams(targetWater)
            }
        case .frenchPress, .aeropress:
            return activePhaseIndex < 2 ? formattedGrams(targetWater) : nil
        }
    }

    var currentPhaseSupportText: String {
        if isCountingDown {
            return method == .v60 || method == .chemex ? "Bloom target" : "Water target"
        }

        if isFinished {
            return AppConstants.BrewTimer.enjoyCoffeeMessage
        }

        switch method {
        case .v60, .chemex:
            if elapsed == 0 {
                return "Total water"
            } else if bloomDuration > 0 && elapsed < bloomPourDuration {
                return "Pour to"
            } else if bloomDuration > 0 && elapsed < bloomDuration {
                return "Let it bloom"
            } else if elapsed < (bloomDuration > 0 ? bloomDuration : 0.0) + AppConstants.BrewTimer.pourOverMainPourDuration {
                return "Pour to"
            } else {
                return "Final total"
            }
        case .frenchPress:
            switch activePhaseIndex {
            case 0:
                return "Pour to"
            case 1:
                return "Let it steep"
            default:
                return "Plunge gently"
            }
        case .aeropress:
            switch activePhaseIndex {
            case 0:
                return "Pour to"
            case 1:
                return "Let it steep"
            default:
                return "Press gently"
            }
        }
    }

    var activePhaseIndex: Int {
        if !isRunning && elapsed == 0 { return 0 }
        if isFinished { return -1 }

        switch method {
        case .v60, .chemex:
            if bloomDuration > 0 {
                if elapsed < bloomPourDuration {
                    return 0
                } else if elapsed < bloomDuration {
                    return 1
                } else if elapsed < bloomDuration + AppConstants.BrewTimer.pourOverMainPourDuration {
                    return 2
                } else {
                    return 3
                }
            } else if elapsed < AppConstants.BrewTimer.pourOverMainPourDuration {
                return 0
            } else {
                return 1
            }
        case .frenchPress, .aeropress:
            if elapsed < immersionPourDuration {
                return 0
            } else if elapsed < steepPhaseDuration {
                return 1
            } else {
                return 2
            }
        }
    }

    var currentPhaseTitle: String {
        if isCountingDown {
            return AppConstants.BrewTimer.readyPhaseTitle
        }

        if isFinished || elapsed >= totalDuration {
            return AppConstants.BrewTimer.donePhaseTitle
        }

        switch method {
        case .v60, .chemex:
            if bloomDuration > 0 {
                switch activePhaseIndex {
                case 0: return AppConstants.BrewTimer.bloomPourPhaseTitle
                case 1: return AppConstants.BrewTimer.bloomWaitPhaseTitle
                case 2: return AppConstants.BrewTimer.firstPourPhaseTitle
                default: return AppConstants.BrewTimer.finalDrawdownPhaseTitle
                }
            } else {
                return activePhaseIndex == 0 ? AppConstants.BrewTimer.firstPourPhaseTitle : AppConstants.BrewTimer.finalDrawdownPhaseTitle
            }
        case .frenchPress:
            switch activePhaseIndex {
            case 0:
                return AppConstants.BrewTimer.firstPourPhaseTitle
            case 1:
                return AppConstants.BrewTimer.steepPhaseTitle
            default:
                return AppConstants.BrewTimer.plungePhaseTitle
            }
        case .aeropress:
            switch activePhaseIndex {
            case 0:
                return AppConstants.BrewTimer.firstPourPhaseTitle
            case 1:
                return AppConstants.BrewTimer.steepPhaseTitle
            default:
                return AppConstants.BrewTimer.pressPhaseTitle
            }
        }
    }

    private var currentPhaseBounds: (start: TimeInterval, end: TimeInterval) {
        switch method {
        case .v60, .chemex:
            if bloomDuration > 0 {
                switch activePhaseIndex {
                case 0:
                    return (0, bloomPourDuration)
                case 1:
                    return (bloomPourDuration, bloomDuration)
                case 2:
                    return (bloomDuration, bloomDuration + AppConstants.BrewTimer.pourOverMainPourDuration)
                default:
                    return (bloomDuration + AppConstants.BrewTimer.pourOverMainPourDuration, totalDuration)
                }
            } else if activePhaseIndex == 0 {
                return (0, AppConstants.BrewTimer.pourOverMainPourDuration)
            } else {
                return (AppConstants.BrewTimer.pourOverMainPourDuration, totalDuration)
            }
        case .frenchPress, .aeropress:
            switch activePhaseIndex {
            case 0:
                return (0, immersionPourDuration)
            case 1:
                return (immersionPourDuration, steepPhaseDuration)
            default:
                return (steepPhaseDuration, totalDuration)
            }
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
            ratio: RecipeDraft.normalizedRatio(template.ratio),
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
            ratio: RecipeDraft.normalizedRatio(draft.ratio),
            waterVolume: draft.waterVolume,
            bloomDuration: draft.isPourOverMethod ? draft.preInfusionDuration : 0.0,
            steepDuration: draft.isPourOverMethod ? 0.0 : draft.steepDuration,
            pressDuration: draft.pressDuration
        )
    }

    // MARK: - Timer Controls
    func toggleTimer() {
        if isCountingDown {
            return
        }

        if isRunning {
            pause()
        } else {
            startOrResume()
        }
    }

    private func startOrResume() {
        if isFinished || elapsed >= totalDuration {
            prepareForRestart()
        }

        if elapsed == 0 {
            beginCountdown()
        } else {
            startTimer()
        }
    }

    private func beginCountdown() {
        countdownTimer?.invalidate()
        timer?.invalidate()
        timer = nil
        isRunning = false
        isFinished = false
        isCountingDown = true
        countdownRemaining = AppConstants.BrewTimer.preBrewCountdownDuration

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor [weak self] in
                guard let self = self else {
                    timer.invalidate()
                    return
                }

                guard self.isCountingDown else {
                    timer.invalidate()
                    return
                }

                if self.countdownRemaining <= 1 {
                    self.countdownTimer?.invalidate()
                    self.countdownTimer = nil
                    self.isCountingDown = false
                    self.countdownRemaining = 0
                    self.startTimer()
                } else {
                    self.countdownRemaining -= 1
                }
            }
        }
    }

    private func startTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        isFinished = false
        isCountingDown = false
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
                let previousWaitPhaseIdentifier = self.activeWaitPhaseIdentifier

                if nowElapsed >= self.totalDuration {
                    self.elapsed = self.totalDuration
                    self.isRunning = false
                    self.isFinished = true
                    self.timer?.invalidate()
                    self.timer = nil
                } else {
                    self.elapsed = nowElapsed
                }

                self.updateWaitMessageIfNeeded(previousPhaseIdentifier: previousWaitPhaseIdentifier)
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
        let previousWaitPhaseIdentifier = activeWaitPhaseIdentifier

        switch method {
        case .v60, .chemex:
            if bloomDuration > 0 {
                if elapsed < bloomPourDuration {
                    newElapsed = bloomPourDuration
                } else if elapsed < bloomDuration {
                    newElapsed = bloomDuration
                } else {
                    let firstPourEnd = bloomDuration + AppConstants.BrewTimer.pourOverMainPourDuration
                    if elapsed < firstPourEnd {
                        newElapsed = firstPourEnd
                    } else {
                        newElapsed = totalDuration
                    }
                }
            } else {
                let firstPourEnd = AppConstants.BrewTimer.pourOverMainPourDuration
                if elapsed < firstPourEnd {
                    newElapsed = firstPourEnd
                } else {
                    newElapsed = totalDuration
                }
            }
        case .frenchPress, .aeropress:
            if elapsed < immersionPourDuration {
                newElapsed = immersionPourDuration
            } else if elapsed < steepPhaseDuration {
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

        updateWaitMessageIfNeeded(previousPhaseIdentifier: previousWaitPhaseIdentifier)
    }

    func getProgress() -> Double {
        min(elapsed / totalDuration, 1.0)
    }

    func getPhaseText() -> String {
        if isCountingDown {
            switch method {
            case .v60, .chemex:
                return "\(AppConstants.BrewTimer.getReadyToBloomPrefix) \(formattedGrams(bloomWater))"
            case .frenchPress, .aeropress:
                return "\(AppConstants.BrewTimer.getReadyToBrewPrefix) \(formattedGrams(targetWater))"
            }
        }

        if isFinished || elapsed >= totalDuration {
            return AppConstants.BrewTimer.enjoyCoffeeMessage
        }

        switch method {
        case .v60, .chemex:
            if elapsed == 0 {
                return "\(AppConstants.BrewTimer.targetPrefix) \(formattedGrams(targetWater))"
            } else if bloomDuration > 0 && elapsed < bloomPourDuration {
                return "\(AppConstants.BrewTimer.bloomInstructionPrefix) \(formattedGrams(bloomWater))"
            } else if bloomDuration > 0 && elapsed < bloomDuration {
                return AppConstants.BrewTimer.bloomWaitInstruction
            } else if elapsed < (bloomDuration > 0 ? bloomDuration : 0.0) + AppConstants.BrewTimer.pourOverMainPourDuration {
                return "\(AppConstants.BrewTimer.firstPourInstructionPrefix) \(formattedGrams(firstPourWater))"
            } else {
                return "\(AppConstants.BrewTimer.drawdownInstructionPrefix) \(formattedGrams(targetWater))"
            }
        case .frenchPress, .aeropress:
            if elapsed == 0 {
                return "\(AppConstants.BrewTimer.targetPrefix) \(formattedGrams(targetWater))"
            } else if elapsed < immersionPourDuration {
                return "\(AppConstants.BrewTimer.immersionPourInstructionPrefix) \(formattedGrams(targetWater))"
            } else if elapsed < steepPhaseDuration {
                return AppConstants.BrewTimer.immersionWaitInstruction
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
        isCountingDown = false
        isFinished = false
        elapsed = 0
        countdownRemaining = AppConstants.BrewTimer.preBrewCountdownDuration
        startDate = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        timer?.invalidate()
        timer = nil
        beanWeight = initialBeanWeight
        activeWaitMessage = nil
        activeWaitPhaseIdentifier = nil
    }

    private var passiveWaitPhaseIdentifier: String? {
        guard isPassiveWaitPhase else { return nil }
        return "\(method.rawValue)-\(activePhaseIndex)"
    }

    private func updateWaitMessageIfNeeded(previousPhaseIdentifier: String?) {
        guard let currentPhaseIdentifier = passiveWaitPhaseIdentifier else {
            activeWaitPhaseIdentifier = nil
            activeWaitMessage = nil
            return
        }

        if currentPhaseIdentifier == previousPhaseIdentifier, activeWaitMessage != nil {
            activeWaitPhaseIdentifier = currentPhaseIdentifier
            return
        }

        let messages = isPourOverMethod
            ? AppConstants.BrewTimer.bloomWaitMessages
            : AppConstants.BrewTimer.immersionWaitMessages

        let candidateMessages = messages.filter { $0 != lastWaitMessage }
        let nextMessage = (candidateMessages.isEmpty ? messages : candidateMessages).randomElement()

        activeWaitPhaseIdentifier = currentPhaseIdentifier
        activeWaitMessage = nextMessage
        lastWaitMessage = nextMessage
    }
}
