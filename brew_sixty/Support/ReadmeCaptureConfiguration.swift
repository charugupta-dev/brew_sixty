import Foundation
import SwiftData

enum ReadmeCaptureConfiguration {
    enum InitialTab {
        case brew
        case recipes
    }

    enum Scenario: String {
        case brew
        case recipes
        case editor
    }

    private static let captureArgument = "-readme-capture"

    static var scenario: Scenario? {
        let arguments = ProcessInfo.processInfo.arguments

        guard let captureIndex = arguments.firstIndex(of: captureArgument),
              arguments.indices.contains(captureIndex + 1) else {
            return nil
        }

        return Scenario(rawValue: arguments[captureIndex + 1].lowercased())
    }

    static var isEnabled: Bool {
        scenario != nil
    }

    static var shouldSkipLaunchScreen: Bool {
        isEnabled
    }

    static var initialTab: InitialTab {
        switch scenario {
        case .recipes, .editor:
            return .recipes
        case .brew, .none:
            return .brew
        }
    }

    static var shouldStartDemoBrew: Bool {
        scenario == .brew
    }

    static var shouldPresentRecipeEditor: Bool {
        scenario == .editor
    }

    static func prepareUserDefaults() {
        guard isEnabled else { return }

        let defaults = UserDefaults.standard
        defaults.set(true, forKey: ProfilePreferences.Keys.hasCompletedProfile)
        defaults.set("Charu", forKey: ProfilePreferences.Keys.name)
        defaults.set(ProfileExperienceLevel.someExperience.rawValue, forKey: ProfilePreferences.Keys.experienceLevel)
        defaults.set(
            ProfilePreferences.encode(methods: [.v60, .chemex, .frenchPress, .aeropress]),
            forKey: ProfilePreferences.Keys.methodsUsed
        )
    }

    static func seedDemoDataIfNeeded(in context: ModelContext) throws {
        guard isEnabled else { return }

        let existingTemplates = try context.fetch(FetchDescriptor<BrewTemplate>())
        guard existingTemplates.isEmpty else { return }

        sampleTemplates.forEach(context.insert)
        try context.save()
    }

    private static var sampleTemplates: [BrewTemplate] {
        [
            BrewTemplate(
                name: "Morning Ritual",
                method: .v60,
                beanWeight: 18.0,
                ratio: 15.5,
                waterVolume: 279.0,
                preInfusionActive: true,
                preInfusionDuration: 45.0,
                targetTemperature: 93.5,
                hapticFeedbackEnabled: true,
                autoSyncEnabled: true,
                steepDuration: 0.0,
                pressDuration: 0.0
            ),
            BrewTemplate(
                name: "Weekend Press",
                method: .frenchPress,
                beanWeight: 30.0,
                ratio: 14.0,
                waterVolume: 420.0,
                preInfusionActive: false,
                preInfusionDuration: 0.0,
                targetTemperature: 94.0,
                hapticFeedbackEnabled: true,
                autoSyncEnabled: true,
                steepDuration: 240.0,
                pressDuration: AppConstants.BrewTimer.frenchPressPlungeDuration
            ),
            BrewTemplate(
                name: "Travel Aero",
                method: .aeropress,
                beanWeight: 15.0,
                ratio: 13.0,
                waterVolume: 220.0,
                preInfusionActive: false,
                preInfusionDuration: 0.0,
                targetTemperature: 92.0,
                hapticFeedbackEnabled: true,
                autoSyncEnabled: true,
                steepDuration: 60.0,
                pressDuration: 30.0
            )
        ]
    }
}
