import Foundation

struct BrewSuggestion: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let iconName: String
}

enum BrewRecommendationEngine {
    static func generateSuggestions(
        draft: RecipeDraft,
        experienceLevel: ProfileExperienceLevel,
        templates: [BrewTemplate],
        logs: [BrewLog]
    ) -> [BrewSuggestion] {
        var suggestions: [BrewSuggestion] = []
        
        switch experienceLevel {
        case .justStarting:
            // Rule 1: V60 Balanced Suggestion
            if draft.method == .v60 {
                suggestions.append(BrewSuggestion(
                    message: "You usually choose Balanced for V60.",
                    iconName: "sparkles"
                ))
            }
            
            // Rule 2: Large Brew Scaling Suggestion
            if draft.beanWeight >= 25.0 && draft.ratio != 16.0 {
                suggestions.append(BrewSuggestion(
                    message: "For 2 cups, try 30g with 1:16.",
                    iconName: "cup.and.saucer.fill"
                ))
            }
            
            // Rule 3: Last Brew Proximity Suggestion
            if let lastLog = logs.first {
                let doseDiff = abs(draft.beanWeight - lastLog.beanWeightGram)
                let ratioDiff = abs(draft.ratio - lastLog.ratio)
                if doseDiff <= 1.0 && ratioDiff <= 1.0 {
                    suggestions.append(BrewSuggestion(
                        message: "This looks close to your last brew.",
                        iconName: "clock.arrow.circlepath"
                    ))
                }
            }
            
        case .someExperience:
            // Rule 1: Lighter than usual Chemex comparison
            if draft.method == .chemex {
                let chemexTemplates = templates.filter { $0.method == .chemex }
                if !chemexTemplates.isEmpty {
                    let avgRatio = chemexTemplates.map(\.ratio).reduce(0, +) / Double(chemexTemplates.count)
                    if draft.ratio > avgRatio {
                        suggestions.append(BrewSuggestion(
                            message: "You made this lighter than your usual Chemex.",
                            iconName: "drop.fill"
                        ))
                    }
                }
            }
            
            // Rule 2: Saved preset bloom comparison
            let methodTemplates = templates.filter { $0.method == draft.method }
            if let longerBloomTemplate = methodTemplates.first(where: { $0.preInfusionDuration > draft.preInfusionDuration }) {
                suggestions.append(BrewSuggestion(
                    message: "Your bloom is shorter than your saved preset.",
                    iconName: "timer"
                ))
            }
            
            // Fallback: Last brew stats
            if suggestions.isEmpty {
                if let lastLog = logs.first {
                    suggestions.append(BrewSuggestion(
                        message: "Last brew: \(Int(lastLog.beanWeightGram))g at 1:\(Int(lastLog.ratio)).",
                        iconName: "clock.arrow.circlepath"
                    ))
                }
            }
            
        case .enthusiast:
            // Rule 1: Stronger/ratio pattern comparison
            let methodTemplates = templates.filter { $0.method == draft.method }
            if !methodTemplates.isEmpty {
                let avgRatio = methodTemplates.map(\.ratio).reduce(0, +) / Double(methodTemplates.count)
                if draft.ratio < avgRatio {
                    suggestions.append(BrewSuggestion(
                        message: "This is stronger than your usual ratio pattern.",
                        iconName: "chart.bar.fill"
                    ))
                }
            }
            
            // Rule 2: Morning Ritual reference suggestion
            if let morningRitual = templates.first(where: { $0.name.localizedCaseInsensitiveContains("Morning Ritual") }) {
                suggestions.append(BrewSuggestion(
                    message: "Your saved Morning Ritual is \(Int(morningRitual.beanWeight))g / 1:\(Int(morningRitual.ratio)) / \(Int(morningRitual.targetTemperature))°C.",
                    iconName: "bookmark.fill"
                ))
            } else if let firstTemplate = templates.first {
                suggestions.append(BrewSuggestion(
                    message: "Your saved \(firstTemplate.name) is \(Int(firstTemplate.beanWeight))g / 1:\(Int(firstTemplate.ratio)) / \(Int(firstTemplate.targetTemperature))°C.",
                    iconName: "bookmark.fill"
                ))
            }
        }
        
        // Base fallback suggestion
        if suggestions.isEmpty {
            suggestions.append(BrewSuggestion(
                message: "Fine-tune dose or ratio to adjust extraction style.",
                iconName: "sparkles"
            ))
        }
        
        return suggestions
    }
}
