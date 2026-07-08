import Foundation

enum FirstCupProfile: String, CaseIterable, Identifiable {
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

private struct FirstCupProfileSettings {
    let beanWeight: Double
    let ratio: Double
    let waterVolume: Double
    let preInfusionDuration: Double
    let steepDuration: Double
    let pressDuration: Double
    let targetTemperature: Double
}

struct RecipeDraft: Equatable {
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

    mutating func applyStarterProfile(_ profile: FirstCupProfile, for method: BrewMethod? = nil) {
        let selectedMethod = method ?? self.method
        let settings = Self.starterSettings(for: selectedMethod, profile: profile)

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

    func matchesStarterProfile(_ profile: FirstCupProfile) -> Bool {
        let settings = Self.starterSettings(for: method, profile: profile)

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

    private static func starterSettings(for method: BrewMethod, profile: FirstCupProfile) -> FirstCupProfileSettings {
        switch (method, profile) {
        case (.v60, .balanced):
            return FirstCupProfileSettings(
                beanWeight: 18.0,
                ratio: 16.0,
                waterVolume: 288.0,
                preInfusionDuration: 45.0,
                steepDuration: AppConstants.Methods.Defaults.frenchPressSteepDuration,
                pressDuration: AppConstants.Methods.Defaults.aeropressPressDuration,
                targetTemperature: 93.5
            )
        case (.v60, .stronger):
            return FirstCupProfileSettings(
                beanWeight: 18.0,
                ratio: 15.0,
                waterVolume: 270.0,
                preInfusionDuration: 40.0,
                steepDuration: AppConstants.Methods.Defaults.frenchPressSteepDuration,
                pressDuration: AppConstants.Methods.Defaults.aeropressPressDuration,
                targetTemperature: 93.0
            )
        case (.v60, .lighter):
            return FirstCupProfileSettings(
                beanWeight: 18.0,
                ratio: 17.0,
                waterVolume: 306.0,
                preInfusionDuration: 45.0,
                steepDuration: AppConstants.Methods.Defaults.frenchPressSteepDuration,
                pressDuration: AppConstants.Methods.Defaults.aeropressPressDuration,
                targetTemperature: 94.0
            )
        case (.chemex, .balanced):
            return FirstCupProfileSettings(
                beanWeight: 20.0,
                ratio: 16.0,
                waterVolume: 320.0,
                preInfusionDuration: 45.0,
                steepDuration: AppConstants.Methods.Defaults.frenchPressSteepDuration,
                pressDuration: AppConstants.Methods.Defaults.aeropressPressDuration,
                targetTemperature: 93.5
            )
        case (.chemex, .stronger):
            return FirstCupProfileSettings(
                beanWeight: 20.0,
                ratio: 15.0,
                waterVolume: 300.0,
                preInfusionDuration: 45.0,
                steepDuration: AppConstants.Methods.Defaults.frenchPressSteepDuration,
                pressDuration: AppConstants.Methods.Defaults.aeropressPressDuration,
                targetTemperature: 93.0
            )
        case (.chemex, .lighter):
            return FirstCupProfileSettings(
                beanWeight: 20.0,
                ratio: 17.0,
                waterVolume: 340.0,
                preInfusionDuration: 50.0,
                steepDuration: AppConstants.Methods.Defaults.frenchPressSteepDuration,
                pressDuration: AppConstants.Methods.Defaults.aeropressPressDuration,
                targetTemperature: 94.0
            )
        case (.frenchPress, .balanced):
            return FirstCupProfileSettings(
                beanWeight: 18.0,
                ratio: 15.0,
                waterVolume: 270.0,
                preInfusionDuration: AppConstants.Methods.Defaults.bloomDuration,
                steepDuration: 240.0,
                pressDuration: AppConstants.BrewTimer.frenchPressPlungeDuration,
                targetTemperature: 93.5
            )
        case (.frenchPress, .stronger):
            return FirstCupProfileSettings(
                beanWeight: 18.0,
                ratio: 14.0,
                waterVolume: 250.0,
                preInfusionDuration: AppConstants.Methods.Defaults.bloomDuration,
                steepDuration: 255.0,
                pressDuration: AppConstants.BrewTimer.frenchPressPlungeDuration,
                targetTemperature: 93.0
            )
        case (.frenchPress, .lighter):
            return FirstCupProfileSettings(
                beanWeight: 18.0,
                ratio: 17.0,
                waterVolume: 300.0,
                preInfusionDuration: AppConstants.Methods.Defaults.bloomDuration,
                steepDuration: 225.0,
                pressDuration: AppConstants.BrewTimer.frenchPressPlungeDuration,
                targetTemperature: 92.5
            )
        case (.aeropress, .balanced):
            return FirstCupProfileSettings(
                beanWeight: 16.0,
                ratio: 15.0,
                waterVolume: 240.0,
                preInfusionDuration: AppConstants.Methods.Defaults.bloomDuration,
                steepDuration: 60.0,
                pressDuration: 30.0,
                targetTemperature: 90.5
            )
        case (.aeropress, .stronger):
            return FirstCupProfileSettings(
                beanWeight: 16.0,
                ratio: 13.0,
                waterVolume: 210.0,
                preInfusionDuration: AppConstants.Methods.Defaults.bloomDuration,
                steepDuration: 75.0,
                pressDuration: 30.0,
                targetTemperature: 89.5
            )
        case (.aeropress, .lighter):
            return FirstCupProfileSettings(
                beanWeight: 16.0,
                ratio: 17.0,
                waterVolume: 270.0,
                preInfusionDuration: AppConstants.Methods.Defaults.bloomDuration,
                steepDuration: 50.0,
                pressDuration: 25.0,
                targetTemperature: 91.0
            )
        }
    }

    private func approximatelyEqual(_ lhs: Double, _ rhs: Double, tolerance: Double) -> Bool {
        abs(lhs - rhs) <= tolerance
    }
}
