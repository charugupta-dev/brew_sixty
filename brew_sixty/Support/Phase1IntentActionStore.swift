import Foundation

enum Phase1IntentDestination: String, Codable {
    case brew
    case recipes
}

enum Phase1IntentAction: Codable {
    case prepareSavedTemplate(templateID: UUID, bannerTitle: String, bannerSubtitle: String?)
    case prepareTransientBrew(draft: RecipeDraft, bannerTitle: String, bannerSubtitle: String?)
    case openRecipeComposer(draft: RecipeDraft, bannerTitle: String, bannerSubtitle: String?)
    case openRecipes(methodFilter: BrewMethod?, bannerTitle: String, bannerSubtitle: String?)
    case adjustRecipe(adjustment: RecipeAdjustmentType, bannerTitle: String, bannerSubtitle: String?)

    var destination: Phase1IntentDestination {
        switch self {
        case .prepareSavedTemplate, .prepareTransientBrew:
            return .brew
        case .openRecipeComposer, .openRecipes, .adjustRecipe:
            return .recipes
        }
    }

    var bannerTitle: String {
        switch self {
        case .prepareSavedTemplate(_, let bannerTitle, _),
             .prepareTransientBrew(_, let bannerTitle, _),
             .openRecipeComposer(_, let bannerTitle, _),
             .openRecipes(_, let bannerTitle, _),
             .adjustRecipe(_, let bannerTitle, _):
            return bannerTitle
        }
    }

    var bannerSubtitle: String? {
        switch self {
        case .prepareSavedTemplate(_, _, let bannerSubtitle),
             .prepareTransientBrew(_, _, let bannerSubtitle),
             .openRecipeComposer(_, _, let bannerSubtitle),
             .openRecipes(_, _, let bannerSubtitle),
             .adjustRecipe(_, _, let bannerSubtitle):
            return bannerSubtitle
        }
    }
}

enum Phase1IntentActionStore {
    static let key = "phase1.intent.action"

    static var hasPendingAction: Bool {
        UserDefaults.standard.data(forKey: key) != nil
    }

    static func save(_ action: Phase1IntentAction) {
        let defaults = UserDefaults.standard

        guard let data = try? JSONEncoder().encode(action) else {
            defaults.removeObject(forKey: key)
            return
        }

        defaults.set(data, forKey: key)
    }

    static func peek() -> Phase1IntentAction? {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: key) else { return nil }

        guard let action = try? JSONDecoder().decode(Phase1IntentAction.self, from: data) else {
            defaults.removeObject(forKey: key)
            return nil
        }

        return action
    }

    static func consume(destination: Phase1IntentDestination) -> Phase1IntentAction? {
        guard let action = peek(), action.destination == destination else { return nil }
        UserDefaults.standard.removeObject(forKey: key)
        return action
    }
}
