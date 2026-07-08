import Foundation

struct MethodGuideContent {
    let title: String
    let summary: String
    let startingPoint: String
    let note: String
}

extension BrewMethod {
    var guideContent: MethodGuideContent {
        switch self {
        case .v60:
            return MethodGuideContent(
                title: "V60",
                summary: "V60 usually gives you a cleaner, brighter cup where the flavors feel a little more separated and vivid.",
                startingPoint: "If you want a calm everyday pour-over, this is a lovely place to begin.",
                note: "It rewards a steady pour more than force, so small adjustments show up clearly in the cup."
            )
        case .chemex:
            return MethodGuideContent(
                title: "Chemex",
                summary: "Chemex leans elegant and tea-like, with more space, clarity, and softness in the finish.",
                startingPoint: "It is a great pick when you want a larger cup that still feels light on its feet.",
                note: "A slightly looser ratio usually keeps it open and polished instead of heavy."
            )
        case .frenchPress:
            return MethodGuideContent(
                title: "French Press",
                summary: "French Press brings more body and texture, so the cup feels deeper, warmer, and a little more comforting.",
                startingPoint: "Choose this when you want brewing to feel simple and the cup to feel fuller.",
                note: "Steep time matters, but this brewer is usually more forgiving than it first looks."
            )
        case .aeropress:
            return MethodGuideContent(
                title: "Aeropress",
                summary: "Aeropress is flexible and forgiving, so it can land anywhere from punchy and short to smooth and easy-going.",
                startingPoint: "It is a great choice when you want a brewer that adapts quickly to your mood.",
                note: "Steep time and press time work together here, so gentle changes go a long way."
            )
        }
    }
}
