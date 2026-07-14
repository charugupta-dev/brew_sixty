import Foundation
import SwiftData

enum Phase1IntentExecutionService {
    struct UserProfile {
        let experienceLevel: ProfileExperienceLevel
        let preferredMethods: [BrewMethod]
    }

    static func makeStartBrewAction(
        template: BrewTemplateEntity?,
        method: BrewMethod?,
        servingSize: FirstCupServingSize?,
        tasteStyle: FirstCupProfile?
    ) -> Phase1IntentAction {
        if let template {
            let title = startBannerTitle(for: template)
            let subtitle = template.methodName
            let templateID = template.templateUUID ?? UUID()
            return Phase1IntentAction.prepareSavedTemplate(
                templateID: templateID,
                bannerTitle: title,
                bannerSubtitle: subtitle
            )
        }

        let profile = loadUserProfile()
        let draft = makeDraft(
            profile: profile,
            method: method,
            servingSize: servingSize,
            tasteStyle: tasteStyle
        )

        let title = draftBannerTitle(for: draft, experienceLevel: profile.experienceLevel, prefix: "Prepared")
        let subtitle = draftBannerSubtitle(for: draft, experienceLevel: profile.experienceLevel)
        return Phase1IntentAction.prepareTransientBrew(
            draft: draft,
            bannerTitle: title,
            bannerSubtitle: subtitle
        )
    }

    static func makeCreateRecipeAction(
        method: BrewMethod?,
        servingSize: FirstCupServingSize?,
        tasteStyle: FirstCupProfile?
    ) -> Phase1IntentAction {
        let profile = loadUserProfile()
        let draft = makeDraft(
            profile: profile,
            method: method,
            servingSize: servingSize,
            tasteStyle: tasteStyle
        )

        return Phase1IntentAction.openRecipeComposer(
            draft: draft,
            bannerTitle: "Recipe builder ready",
            bannerSubtitle: draftBannerSubtitle(for: draft, experienceLevel: profile.experienceLevel)
        )
    }

    static func makeShowRecipesAction(method: BrewMethod?) -> Phase1IntentAction {
        let bannerText = method.map { "Show my \($0.rawValue) recipes" } ?? "Opened your recipes"
        return .openRecipes(
            methodFilter: method,
            bannerTitle: bannerText,
            bannerSubtitle: "Browse, edit, or start a brew"
        )
    }

    static func makeAdjustRecipeAction(adjustment: RecipeAdjustmentType) -> Phase1IntentAction {
        let title: String
        switch adjustment {
        case .stronger: title = "Made recipe stronger"
        case .lighter: title = "Made recipe lighter"
        case .oneCup: title = "Scaled to 1 cup"
        case .twoCups: title = "Scaled to 2 cups"
        case .increaseBloom: title = "Increased bloom time"
        case .decreaseTemperature: title = "Lowered temperature"
        }
        return .adjustRecipe(
            adjustment: adjustment,
            bannerTitle: title,
            bannerSubtitle: "Applied adjustment to active draft"
        )
    }

    static func fetchAllTemplateEntities() throws -> [BrewTemplateEntity] {
        let context = try makeModelContext()
        let templates = try context.fetch(FetchDescriptor<BrewTemplate>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
        return templates.map(BrewTemplateEntity.init(template:))
    }

    private static func makeModelContext() throws -> ModelContext {
        let container = try ModelContainer(for: BrewLog.self, BrewTemplate.self)
        return ModelContext(container)
    }

    private static func loadUserProfile() -> UserProfile {
        let defaults = UserDefaults.standard
        let level = ProfileExperienceLevel(rawValue: defaults.string(forKey: ProfilePreferences.Keys.experienceLevel) ?? "") ?? .justStarting
        let methodsRaw = defaults.string(forKey: ProfilePreferences.Keys.methodsUsed) ?? ""
        let preferredMethods = BrewMethod.allCases.filter { ProfilePreferences.decode(methods: methodsRaw).contains($0) }

        return UserProfile(
            experienceLevel: level,
            preferredMethods: preferredMethods
        )
    }

    private static func makeDraft(
        profile: UserProfile,
        method: BrewMethod?,
        servingSize: FirstCupServingSize?,
        tasteStyle: FirstCupProfile?
    ) -> RecipeDraft {
        let resolvedMethod = method ?? profile.preferredMethods.first ?? .v60
        var draft = RecipeDraft()

        switch profile.experienceLevel {
        case .justStarting:
            draft.applyStarterProfile(
                tasteStyle ?? .balanced,
                for: resolvedMethod,
                servingSize: servingSize ?? .oneCup
            )
        case .someExperience:
            if tasteStyle != nil || servingSize != nil {
                draft.applyStarterProfile(
                    tasteStyle ?? .balanced,
                    for: resolvedMethod,
                    servingSize: servingSize ?? .oneCup
                )
            } else {
                draft.applyDefaults(for: resolvedMethod)
            }
        case .enthusiast:
            if let tasteStyle {
                draft.applyStarterProfile(
                    tasteStyle,
                    for: resolvedMethod,
                    servingSize: servingSize ?? .oneCup
                )
            } else {
                draft.applyDefaults(for: resolvedMethod)

                if let servingSize, servingSize == .twoCups {
                    draft.beanWeight = max((draft.beanWeight * 1.7).rounded(), draft.beanWeight)
                    draft.syncBrewingMath()
                }
            }
        }

        return draft
    }

    private static func draftBannerTitle(for draft: RecipeDraft, experienceLevel: ProfileExperienceLevel, prefix: String) -> String {
        switch experienceLevel {
        case .justStarting, .someExperience:
            var parts: [String] = [prefix]
            if let servingText = beginnerServingDescription(for: draft) {
                parts.append(servingText)
            }
            if let tasteText = beginnerTasteDescription(for: draft) {
                parts.append(tasteText)
            }
            parts.append(draft.method.rawValue)
            return parts.joined(separator: " ")
        case .enthusiast:
            return "\(prefix) \(draft.method.rawValue)"
        }
    }

    private static func draftBannerSubtitle(for draft: RecipeDraft, experienceLevel: ProfileExperienceLevel) -> String {
        switch experienceLevel {
        case .justStarting:
            return "Simple setup, ready when you are"
        case .someExperience:
            let ratioText = draft.isPourOverMethod ? "1:\(Int(draft.ratio.rounded()))" : "\(Int(draft.waterVolume.rounded()))g water"
            return "\(Int(draft.beanWeight.rounded()))g coffee • \(ratioText)"
        case .enthusiast:
            if draft.isPourOverMethod {
                return "\(Int(draft.beanWeight.rounded()))g • 1:\(Int(draft.ratio.rounded())) • \(Int(draft.targetTemperature.rounded()))°C"
            }

            return "\(Int(draft.beanWeight.rounded()))g • \(Int(draft.waterVolume.rounded()))g • \(Int(draft.targetTemperature.rounded()))°C"
        }
    }

    private static func startBannerTitle(for template: BrewTemplateEntity) -> String {
        "Prepared \(template.name)"
    }

    private static func beginnerServingDescription(for draft: RecipeDraft) -> String? {
        if FirstCupProfile.allCases.contains(where: { draft.matchesStarterProfile($0, servingSize: .twoCups) }) {
            return FirstCupServingSize.twoCups.title
        }

        if FirstCupProfile.allCases.contains(where: { draft.matchesStarterProfile($0, servingSize: .oneCup) }) {
            return FirstCupServingSize.oneCup.title
        }

        return nil
    }

    private static func beginnerTasteDescription(for draft: RecipeDraft) -> String? {
        if let match = FirstCupProfile.allCases.first(where: { draft.matchesStarterProfile($0, servingSize: .twoCups) }) {
            return match.title
        }

        if let match = FirstCupProfile.allCases.first(where: { draft.matchesStarterProfile($0, servingSize: .oneCup) }) {
            return match.title
        }

        return nil
    }
}
