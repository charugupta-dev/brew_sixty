import Foundation

enum ProfileExperienceLevel: String, CaseIterable, Identifiable {
    case justStarting
    case someExperience
    case enthusiast

    var id: String { rawValue }

    var title: String {
        switch self {
        case .justStarting:
            return "Just starting"
        case .someExperience:
            return "Some experience"
        case .enthusiast:
            return "Comfortable"
        }
    }

    var subtitle: String {
        switch self {
        case .justStarting:
            return "Beginner presets, simpler wording, and more help"
        case .someExperience:
            return "Cleaner setup with simpler wording"
        case .enthusiast:
            return "Technical labels and the leanest setup"
        }
    }
}

enum ProfilePreferences {
    enum Keys {
        static let hasCompletedProfile = "profile.hasCompleted"
        static let name = "profile.name"
        static let experienceLevel = "profile.experienceLevel"
        static let methodsUsed = "profile.methodsUsed"
    }

    static func encode(methods: Set<BrewMethod>) -> String {
        methods.map(\.rawValue)
            .sorted()
            .joined(separator: "|")
    }

    static func decode(methods rawValue: String) -> Set<BrewMethod> {
        Set(
            rawValue
                .split(separator: "|")
                .compactMap { BrewMethod(rawValue: String($0)) }
        )
    }
}
