import Foundation

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
        self.ratio = ratio
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
    }

    func makeTemplate() -> BrewTemplate {
        BrewTemplate(
            name: name,
            method: method,
            beanWeight: beanWeight,
            ratio: ratio,
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
        template.ratio = ratio
        template.waterVolume = waterVolume
        template.preInfusionActive = isPourOverMethod
        template.preInfusionDuration = isPourOverMethod ? preInfusionDuration : 0.0
        template.targetTemperature = targetTemperature
        template.hapticFeedbackEnabled = hapticFeedbackEnabled
        template.autoSyncEnabled = autoSyncEnabled
        template.steepDuration = isPourOverMethod ? 0.0 : steepDuration
        template.pressDuration = method == .aeropress ? pressDuration : (method == .frenchPress ? AppConstants.BrewTimer.frenchPressPlungeDuration : 0.0)
    }
}
