import AppIntents
import Foundation

enum BrewMethodOption: String, CaseIterable, AppEnum, Sendable {
    case v60
    case frenchPress
    case aeropress
    case chemex

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Brewer"

    static var caseDisplayRepresentations: [BrewMethodOption: DisplayRepresentation] = [
        .v60: DisplayRepresentation(title: "V60"),
        .frenchPress: DisplayRepresentation(title: "French Press"),
        .aeropress: DisplayRepresentation(title: "Aeropress"),
        .chemex: DisplayRepresentation(title: "Chemex")
    ]

    var brewMethod: BrewMethod {
        switch self {
        case .v60:
            return .v60
        case .frenchPress:
            return .frenchPress
        case .aeropress:
            return .aeropress
        case .chemex:
            return .chemex
        }
    }
}

enum TasteStyleOption: String, CaseIterable, AppEnum, Sendable {
    case balanced
    case stronger
    case lighter

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Taste Style"

    static var caseDisplayRepresentations: [TasteStyleOption: DisplayRepresentation] = [
        .balanced: DisplayRepresentation(title: "Balanced"),
        .stronger: DisplayRepresentation(title: "Stronger"),
        .lighter: DisplayRepresentation(title: "Lighter")
    ]

    var firstCupProfile: FirstCupProfile {
        switch self {
        case .balanced:
            return .balanced
        case .stronger:
            return .stronger
        case .lighter:
            return .lighter
        }
    }
}

enum CupSizeOption: String, CaseIterable, AppEnum, Sendable {
    case oneCup
    case twoCups

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Cup Size"

    static var caseDisplayRepresentations: [CupSizeOption: DisplayRepresentation] = [
        .oneCup: DisplayRepresentation(title: "1 Cup"),
        .twoCups: DisplayRepresentation(title: "2 Cups")
    ]

    var servingSize: FirstCupServingSize {
        switch self {
        case .oneCup:
            return .oneCup
        case .twoCups:
            return .twoCups
        }
    }
}

enum RecipeAdjustmentOption: String, CaseIterable, AppEnum, Sendable {
    case stronger
    case lighter
    case oneCup
    case twoCups
    case increaseBloom
    case decreaseTemperature

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Recipe Tweak"

    static var caseDisplayRepresentations: [RecipeAdjustmentOption: DisplayRepresentation] = [
        .stronger: DisplayRepresentation(title: "Stronger"),
        .lighter: DisplayRepresentation(title: "Lighter"),
        .oneCup: DisplayRepresentation(title: "Single Cup (1 Cup)"),
        .twoCups: DisplayRepresentation(title: "Bigger Brew (2 Cups)"),
        .increaseBloom: DisplayRepresentation(title: "Increase Bloom Time"),
        .decreaseTemperature: DisplayRepresentation(title: "Decrease Temperature")
    ]

    var recipeAdjustmentType: RecipeAdjustmentType {
        switch self {
        case .stronger: return .stronger
        case .lighter: return .lighter
        case .oneCup: return .oneCup
        case .twoCups: return .twoCups
        case .increaseBloom: return .increaseBloom
        case .decreaseTemperature: return .decreaseTemperature
        }
    }
}

struct AdjustRecipeIntent: AppIntent {
    static var title: LocalizedStringResource = "Adjust Recipe"
    static var description = IntentDescription("Apply a tweak to your active draft or current recipe.")
    static var openAppWhenRun = true

    @Parameter(title: "Adjustment")
    var adjustment: RecipeAdjustmentOption

    func perform() async throws -> some IntentResult {
        let action = await Phase1IntentExecutionService.makeAdjustRecipeAction(adjustment: adjustment.recipeAdjustmentType)
        await Phase1IntentActionStore.save(action)
        return .result()
    }
}

struct BrewTemplateEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Recipe"
    static var defaultQuery = BrewTemplateQuery()

    let id: String
    let name: String
    let methodName: String

    var templateUUID: UUID? {
        UUID(uuidString: id)
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: LocalizedStringResource(stringLiteral: name),
            subtitle: LocalizedStringResource(stringLiteral: methodName)
        )
    }

    init(template: BrewTemplate) {
        id = template.id.uuidString
        name = template.name
        methodName = template.method.rawValue
    }
}

struct BrewTemplateQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [BrewTemplateEntity] {
        let allTemplates = try await Phase1IntentExecutionService.fetchAllTemplateEntities()
        let idSet = Set(identifiers)
        return allTemplates.filter { idSet.contains($0.id) }
    }

    func suggestedEntities() async throws -> [BrewTemplateEntity] {
        try await Phase1IntentExecutionService.fetchAllTemplateEntities()
    }

    func entities(matching string: String) async throws -> [BrewTemplateEntity] {
        let query = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return try await suggestedEntities() }

        return try await Phase1IntentExecutionService.fetchAllTemplateEntities().filter {
            $0.name.localizedCaseInsensitiveContains(query) || $0.methodName.localizedCaseInsensitiveContains(query)
        }
    }
}

struct StartBrewIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Brew"
    static var description = IntentDescription("Prepare a brew in Brew Sixty from a saved recipe or a quick voice setup.")
    static var openAppWhenRun = true

    @Parameter(title: "Recipe")
    var recipe: BrewTemplateEntity?

    @Parameter(title: "Brewer")
    var method: BrewMethodOption?

    @Parameter(title: "Cup Size")
    var servingSize: CupSizeOption?

    @Parameter(title: "Taste Style")
    var tasteStyle: TasteStyleOption?

    func perform() async throws -> some IntentResult {
        let action = await Phase1IntentExecutionService.makeStartBrewAction(
            template: recipe,
            method: method?.brewMethod,
            servingSize: servingSize?.servingSize,
            tasteStyle: tasteStyle?.firstCupProfile
        )

        await Phase1IntentActionStore.save(action)
        return .result()
    }
}

struct CreateRecipeIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Recipe"
    static var description = IntentDescription("Open the Brew Sixty recipe builder with a ready-to-tune draft.")
    static var openAppWhenRun = true

    @Parameter(title: "Brewer")
    var method: BrewMethodOption?

    @Parameter(title: "Cup Size")
    var servingSize: CupSizeOption?

    @Parameter(title: "Taste Style")
    var tasteStyle: TasteStyleOption?

    func perform() async throws -> some IntentResult {
        let action = await Phase1IntentExecutionService.makeCreateRecipeAction(
            method: method?.brewMethod,
            servingSize: servingSize?.servingSize,
            tasteStyle: tasteStyle?.firstCupProfile
        )

        await Phase1IntentActionStore.save(action)
        return .result()
    }
}

struct ShowRecipesIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Recipes"
    static var description = IntentDescription("Open the Brew Sixty recipes library.")
    static var openAppWhenRun = true

    @Parameter(title: "Brewer")
    var method: BrewMethodOption?

    func perform() async throws -> some IntentResult {
        let action = await Phase1IntentExecutionService.makeShowRecipesAction(method: method?.brewMethod)
        await Phase1IntentActionStore.save(action)
        return .result()
    }
}

struct BrewSixtyShortcutsProvider: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .orange

    static var appShortcuts: [AppShortcut] {
        let startBrew = AppShortcut(
            intent: StartBrewIntent(),
            phrases: [
                "Start brew in \(.applicationName)",
                "Start my brew in \(.applicationName)",
                "Start a V60 brew in \(.applicationName)"
            ],
            shortTitle: "Start Brew",
            systemImageName: "cup.and.saucer.fill"
        )

        let createRecipe = AppShortcut(
            intent: CreateRecipeIntent(),
            phrases: [
                "Create a recipe in \(.applicationName)",
                "Make a coffee recipe in \(.applicationName)",
                "Create a 2 cup Chemex in \(.applicationName)"
            ],
            shortTitle: "Create Recipe",
            systemImageName: "slider.horizontal.3"
        )

        let adjustRecipe = AppShortcut(
            intent: AdjustRecipeIntent(),
            phrases: [
                "Make this \(\.$adjustment) in \(.applicationName)",
                "Change recipe to \(\.$adjustment) in \(.applicationName)",
                "Adjust my V60 to \(\.$adjustment) in \(.applicationName)"
            ],
            shortTitle: "Adjust Recipe",
            systemImageName: "slider.horizontal.3"
        )

        let showRecipes = AppShortcut(
            intent: ShowRecipesIntent(),
            phrases: [
                "Show my recipes in \(.applicationName)",
                "Open recipes in \(.applicationName)",
                "Show my saved brews in \(.applicationName)",
                "Show my \(\.$method) recipes in \(.applicationName)",
                "Open \(\.$method) setup in \(.applicationName)"
            ],
            shortTitle: "Show Recipes",
            systemImageName: "square.grid.2x2.fill"
        )

        return [startBrew, createRecipe, adjustRecipe, showRecipes]
    }
}
