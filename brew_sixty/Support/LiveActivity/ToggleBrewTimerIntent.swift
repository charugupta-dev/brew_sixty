import AppIntents
import Foundation

struct ToggleBrewTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause or Resume Brew"
    static var isDiscoverable = false
    
    init() {}
    
    @MainActor
    func perform() async throws -> some IntentResult {
        if let activeVM = BrewSessionStore.shared.activeBrewViewModel {
            activeVM.toggleTimer()
        }
        return .result()
    }
}
