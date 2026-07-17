import Foundation

// Stub classes to satisfy compilation in the Widget Extension target.
// The actual execution runs in the main app process where the real classes are loaded.
final class BrewSessionStore {
    static let shared = BrewSessionStore()
    var activeBrewViewModel: HomeBrewViewModel? { nil }
}

final class HomeBrewViewModel {
    func toggleTimer() {}
}
