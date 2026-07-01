import Foundation
import SwiftData

@Model
final class BrewTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var methodRaw: String
    var beanWeight: Double
    var ratio: Double
    var waterVolume: Double
    var preInfusionActive: Bool
    var preInfusionDuration: Double
    var targetTemperature: Double
    var hapticFeedbackEnabled: Bool
    var autoSyncEnabled: Bool
    var steepDuration: Double
    var pressDuration: Double
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        method: BrewMethod,
        beanWeight: Double,
        ratio: Double,
        waterVolume: Double,
        preInfusionActive: Bool,
        preInfusionDuration: Double,
        targetTemperature: Double,
        hapticFeedbackEnabled: Bool,
        autoSyncEnabled: Bool,
        steepDuration: Double,
        pressDuration: Double
    ) {
        self.id = id
        self.name = name
        self.methodRaw = method.rawValue
        self.beanWeight = beanWeight
        self.ratio = ratio
        self.waterVolume = waterVolume
        self.preInfusionActive = preInfusionActive
        self.preInfusionDuration = preInfusionDuration
        self.targetTemperature = targetTemperature
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
        self.autoSyncEnabled = autoSyncEnabled
        self.steepDuration = steepDuration
        self.pressDuration = pressDuration
        self.createdAt = Date()
    }

    var method: BrewMethod {
        get { BrewMethod(rawValue: methodRaw) ?? .v60 }
        set { methodRaw = newValue.rawValue }
    }
}
