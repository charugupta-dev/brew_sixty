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
            return "More guidance and safer defaults"
        case .someExperience:
            return "A balanced mix of help and control"
        case .enthusiast:
            return "Fast, streamlined setup"
        }
    }
}

enum GuidanceMode: String, CaseIterable, Identifiable {
    case guided
    case manual

    var id: String { rawValue }

    var title: String {
        switch self {
        case .guided:
            return "Guided"
        case .manual:
            return "Manual"
        }
    }

    var subtitle: String {
        switch self {
        case .guided:
            return "Explain methods and parameters as you go"
        case .manual:
            return "Keep things lean and get to brewing faster"
        }
    }
}

enum ProfilePreferences {
    enum Keys {
        static let hasCompletedProfile = "profile.hasCompleted"
        static let name = "profile.name"
        static let experienceLevel = "profile.experienceLevel"
        static let methodsUsed = "profile.methodsUsed"
        static let guidanceMode = "profile.guidanceMode"
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
