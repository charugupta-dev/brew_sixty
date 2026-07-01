import Foundation

/// Represents the supported brewing methods in the app.
enum BrewMethod: String, CaseIterable, Codable {
    case v60 = "V60"
    case frenchPress = "FrenchPress"
    case aeropress = "Aeropress"
    case chemex = "Chemex"
}
