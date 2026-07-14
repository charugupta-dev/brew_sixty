import Foundation

enum FirstCupProfile: String, CaseIterable, Identifiable, Codable {
    case balanced
    case stronger
    case lighter

    var id: String { rawValue }

    var title: String {
        switch self {
        case .balanced:
            return "Balanced"
        case .stronger:
            return "Stronger"
        case .lighter:
            return "Lighter"
        }
    }

    var summary: String {
        switch self {
        case .balanced:
            return "Easy everyday starting point"
        case .stronger:
            return "More body and a richer-feeling cup"
        case .lighter:
            return "Cleaner, brighter, easier to sip"
        }
    }
}

enum FirstCupServingSize: String, CaseIterable, Identifiable, Codable {
    case oneCup
    case twoCups

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oneCup:
            return "1 Cup"
        case .twoCups:
            return "2 Cups"
        }
    }

    var summary: String {
        switch self {
        case .oneCup:
            return "Single cup"
        case .twoCups:
            return "Bigger brew"
        }
    }
}

enum RecipeAdjustmentType: String, Codable {
    case stronger
    case lighter
    case oneCup
    case twoCups
    case increaseBloom
    case decreaseTemperature
}

private struct FirstCupProfileSettings {
    let beanWeight: Double
    let ratio: Double
    let waterVolume: Double
    let preInfusionDuration: Double
    let steepDuration: Double
    let pressDuration: Double
    let targetTemperature: Double
}

struct RecipeDraft: Equatable, Codable {
    var name: String
    var method: BrewMethod
    var beanWeight: Double
    var ratio: Double
    var waterVolume: Double
    var preInfusionDuration: Double
    var steepDuration: Double
    var pressDuration: Double
    var targetTemperature: Double
    var hapticFeedbackEnabled: Bool
    var autoSyncEnabled: Bool

    init(
        name: String = AppConstants.Methods.Defaults.recipeName,
        method: BrewMethod = .v60,
        beanWeight: Double = AppConstants.Methods.Defaults.beanWeight,
        ratio: Double = AppConstants.Methods.Defaults.ratio,
        waterVolume: Double = AppConstants.Methods.Defaults.waterVolume,
        preInfusionDuration: Double = AppConstants.Methods.Defaults.bloomDuration,
        steepDuration: Double = AppConstants.Methods.Defaults.frenchPressSteepDuration,
        pressDuration: Double = AppConstants.Methods.Defaults.aeropressPressDuration,
        targetTemperature: Double = AppConstants.Methods.Defaults.targetTemperature,
        hapticFeedbackEnabled: Bool = true,
        autoSyncEnabled: Bool = true
    ) {
        self.name = name
        self.method = method
        self.beanWeight = beanWeight
        self.ratio = Self.normalizedRatio(ratio)
        self.waterVolume = waterVolume
        self.preInfusionDuration = preInfusionDuration
        self.steepDuration = steepDuration
        self.pressDuration = pressDuration
        self.targetTemperature = targetTemperature
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
        self.autoSyncEnabled = autoSyncEnabled
    }

    init(template: BrewTemplate) {
        self.init(
            name: template.name,
            method: template.method,
            beanWeight: template.beanWeight,
            ratio: template.ratio,
            waterVolume: template.waterVolume,
            preInfusionDuration: template.preInfusionDuration > 0 ? template.preInfusionDuration : AppConstants.Methods.Defaults.bloomDuration,
            steepDuration: template.steepDuration > 0 ? template.steepDuration : AppConstants.Methods.Defaults.frenchPressSteepDuration,
            pressDuration: template.pressDuration > 0 ? template.pressDuration : AppConstants.Methods.Defaults.aeropressPressDuration,
            targetTemperature: template.targetTemperature,
            hapticFeedbackEnabled: template.hapticFeedbackEnabled,
            autoSyncEnabled: template.autoSyncEnabled
        )
    }

    var isPourOverMethod: Bool {
        method == .v60 || method == .chemex
    }

    mutating func applyAdjustment(_ type: RecipeAdjustmentType) {
        switch type {
        case .stronger:
            if isPourOverMethod {
                beanWeight = min((beanWeight + 1.5).rounded(), 40.0)
            } else {
                beanWeight = min((beanWeight + 2.0).rounded(), 40.0)
            }
            syncBrewingMath()
        case .lighter:
            beanWeight = max((beanWeight - 1.5).rounded(), 5.0)
            syncBrewingMath()
        case .oneCup:
            applyDefaults(for: method)
            beanWeight = 15.0
            if isPourOverMethod {
                ratio = 17.0
            } else {
                waterVolume = 250.0
            }
            syncBrewingMath()
        case .twoCups:
            applyDefaults(for: method)
            beanWeight = 30.0
            if isPourOverMethod {
                ratio = 17.0
            } else {
                waterVolume = 500.0
            }
            syncBrewingMath()
        case .increaseBloom:
            if method == .frenchPress {
                steepDuration = min(steepDuration + 15.0, 360.0)
            } else if method == .aeropress {
                steepDuration = min(steepDuration + 10.0, 180.0)
            } else {
                preInfusionDuration = min(preInfusionDuration + 5.0, 90.0)
            }
        case .decreaseTemperature:
            targetTemperature = max(targetTemperature - 2.0, 75.0)
        }
    }

    mutating func applyDefaults(for method: BrewMethod) {
        syncBrewingMath()
        self.method = method

        switch method {
        case .v60, .chemex:
            preInfusionDuration = AppConstants.Methods.Defaults.bloomDuration
        case .frenchPress:
            steepDuration = AppConstants.Methods.Defaults.frenchPressSteepDuration
        case .aeropress:
            steepDuration = AppConstants.Methods.Defaults.aeropressSteepDuration
            pressDuration = AppConstants.Methods.Defaults.aeropressPressDuration
        }

        syncBrewingMath()
    }

    mutating func applyStarterProfile(
        _ profile: FirstCupProfile,
        for method: BrewMethod? = nil,
        servingSize: FirstCupServingSize = .oneCup
    ) {
        let selectedMethod = method ?? self.method
        let settings = Self.starterSettings(for: selectedMethod, profile: profile, servingSize: servingSize)

        self.method = selectedMethod
        beanWeight = settings.beanWeight
        ratio = Self.normalizedRatio(settings.ratio)
        waterVolume = settings.waterVolume
        preInfusionDuration = settings.preInfusionDuration
        steepDuration = settings.steepDuration
        pressDuration = settings.pressDuration
        targetTemperature = settings.targetTemperature

        syncBrewingMath()
    }

    mutating func syncBrewingMath() {
        ratio = Self.normalizedRatio(ratio)

        if isPourOverMethod {
            waterVolume = (beanWeight * ratio).rounded()
        } else if beanWeight > 0 {
            ratio = Self.normalizedRatio(waterVolume / beanWeight)
        }
    }

    func matchesStarterProfile(_ profile: FirstCupProfile, servingSize: FirstCupServingSize) -> Bool {
        let settings = Self.starterSettings(for: method, profile: profile, servingSize: servingSize)

        return approximatelyEqual(beanWeight, settings.beanWeight, tolerance: 0.26)
            && approximatelyEqual(ratio, settings.ratio, tolerance: 0.1)
            && approximatelyEqual(waterVolume, settings.waterVolume, tolerance: 0.6)
            && approximatelyEqual(preInfusionDuration, settings.preInfusionDuration, tolerance: 0.6)
            && approximatelyEqual(steepDuration, settings.steepDuration, tolerance: 0.6)
            && approximatelyEqual(pressDuration, settings.pressDuration, tolerance: 0.6)
            && approximatelyEqual(targetTemperature, settings.targetTemperature, tolerance: 0.26)
    }

    func makeTemplate() -> BrewTemplate {
        BrewTemplate(
            name: name,
            method: method,
            beanWeight: beanWeight,
            ratio: Self.normalizedRatio(ratio),
            waterVolume: waterVolume,
            preInfusionActive: isPourOverMethod,
            preInfusionDuration: isPourOverMethod ? preInfusionDuration : 0.0,
            targetTemperature: targetTemperature,
            hapticFeedbackEnabled: hapticFeedbackEnabled,
            autoSyncEnabled: autoSyncEnabled,
            steepDuration: isPourOverMethod ? 0.0 : steepDuration,
            pressDuration: method == .aeropress ? pressDuration : (method == .frenchPress ? AppConstants.BrewTimer.frenchPressPlungeDuration : 0.0)
        )
    }

    func apply(to template: BrewTemplate) {
        template.name = name
        template.method = method
        template.beanWeight = beanWeight
        template.ratio = Self.normalizedRatio(ratio)
        template.waterVolume = waterVolume
        template.preInfusionActive = isPourOverMethod
        template.preInfusionDuration = isPourOverMethod ? preInfusionDuration : 0.0
        template.targetTemperature = targetTemperature
        template.hapticFeedbackEnabled = hapticFeedbackEnabled
        template.autoSyncEnabled = autoSyncEnabled
        template.steepDuration = isPourOverMethod ? 0.0 : steepDuration
        template.pressDuration = method == .aeropress ? pressDuration : (method == .frenchPress ? AppConstants.BrewTimer.frenchPressPlungeDuration : 0.0)
    }

    static func normalizedRatio(_ value: Double) -> Double {
        value.rounded()
    }

    private static func starterSettings(
        for method: BrewMethod,
        profile: FirstCupProfile,
        servingSize: FirstCupServingSize
    ) -> FirstCupProfileSettings {
        let ratio: Double
        let targetTemperature: Double

        switch profile {
        case .stronger:
            ratio = method == .aeropress ? 13.0 : 15.0
            targetTemperature = method == .aeropress ? 89.5 : 93.0
        case .balanced:
            ratio = 15.0
            targetTemperature = method == .aeropress ? 90.5 : 93.5
        case .lighter:
            ratio = 17.0
            targetTemperature = method == .aeropress ? 91.0 : (method == .frenchPress ? 92.5 : 94.0)
        }

        switch method {
        case .v60:
            let beanWeight = servingSize == .oneCup ? 18.0 : 30.0
            let bloomDuration = profile == .stronger ? 40.0 : 45.0
            return FirstCupProfileSettings(
                beanWeight: beanWeight,
                ratio: ratio,
                waterVolume: (beanWeight * ratio).rounded(),
                preInfusionDuration: bloomDuration,
                steepDuration: AppConstants.Methods.Defaults.frenchPressSteepDuration,
                pressDuration: AppConstants.Methods.Defaults.aeropressPressDuration,
                targetTemperature: targetTemperature
            )
        case .chemex:
            let beanWeight = servingSize == .oneCup ? 20.0 : 30.0
            let bloomDuration = profile == .lighter ? 50.0 : 45.0
            return FirstCupProfileSettings(
                beanWeight: beanWeight,
                ratio: ratio,
                waterVolume: (beanWeight * ratio).rounded(),
                preInfusionDuration: bloomDuration,
                steepDuration: AppConstants.Methods.Defaults.frenchPressSteepDuration,
                pressDuration: AppConstants.Methods.Defaults.aeropressPressDuration,
                targetTemperature: targetTemperature
            )
        case .frenchPress:
            let beanWeight = servingSize == .oneCup ? 18.0 : 30.0
            let steepDuration: Double
            switch profile {
            case .stronger:
                steepDuration = 255.0
            case .balanced:
                steepDuration = 240.0
            case .lighter:
                steepDuration = 225.0
            }
            return FirstCupProfileSettings(
                beanWeight: beanWeight,
                ratio: ratio == 15.0 && profile == .stronger ? 14.0 : ratio,
                waterVolume: (beanWeight * (ratio == 15.0 && profile == .stronger ? 14.0 : ratio)).rounded(),
                preInfusionDuration: AppConstants.Methods.Defaults.bloomDuration,
                steepDuration: steepDuration,
                pressDuration: AppConstants.BrewTimer.frenchPressPlungeDuration,
                targetTemperature: targetTemperature
            )
        case .aeropress:
            let beanWeight = servingSize == .oneCup ? 16.0 : 22.0
            let steepDuration: Double
            let pressDuration: Double
            switch profile {
            case .stronger:
                steepDuration = 75.0
                pressDuration = 30.0
            case .balanced:
                steepDuration = 60.0
                pressDuration = 30.0
            case .lighter:
                steepDuration = 50.0
                pressDuration = 25.0
            }
            return FirstCupProfileSettings(
                beanWeight: beanWeight,
                ratio: ratio,
                waterVolume: (beanWeight * ratio).rounded(),
                preInfusionDuration: AppConstants.Methods.Defaults.bloomDuration,
                steepDuration: steepDuration,
                pressDuration: pressDuration,
                targetTemperature: targetTemperature
            )
        }
    }

    private func approximatelyEqual(_ lhs: Double, _ rhs: Double, tolerance: Double) -> Bool {
        abs(lhs - rhs) <= tolerance
    }
}
