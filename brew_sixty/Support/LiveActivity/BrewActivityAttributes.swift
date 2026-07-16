import ActivityKit
import Foundation

struct BrewActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var phaseName: String
        var targetWaterVolume: Double
        var currentPhaseProgress: Double
        var phaseEndDate: Date
        var isPaused: Bool
        var pausedRemainingSeconds: TimeInterval
    }

    var recipeName: String
    var methodName: String
    var totalWaterVolume: Double
}
