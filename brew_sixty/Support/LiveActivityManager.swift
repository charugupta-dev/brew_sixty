import ActivityKit
import Foundation
import OSLog

#if canImport(ActivityKit)
@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private let logger = Logger(subsystem: "practice.brew-sixty", category: "LiveActivity")
    
    private init() {
        #if !targetEnvironment(macCatalyst)
        // Recovery of active Live Activities on startup
        self.currentActivity = Activity<BrewActivityAttributes>.activities.first
        if let currentActivity {
            logger.info("Recovered active Live Activity: \(currentActivity.id, privacy: .public)")
        }
        #endif
    }

    private var currentActivity: Activity<BrewActivityAttributes>? = nil
    private var startTask: Task<Void, Never>? = nil

    func startActivity(
        recipeName: String,
        methodName: String,
        totalWaterVolume: Double,
        initialPhaseName: String,
        phaseRemainingSeconds: TimeInterval,
        targetWaterVolume: Double,
        currentPhaseProgress: Double
    ) {
        #if !targetEnvironment(macCatalyst)
        logger.info("Requesting Live Activity... areActivitiesEnabled: \(ActivityAuthorizationInfo().areActivitiesEnabled, privacy: .public)")
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            logger.error("Live Activities are disabled for this app in Settings!")
            return
        }
        
        // Serialize operations to prevent overlap / race conditions
        let previousTask = startTask
        startTask = Task {
            if let previousTask {
                _ = await previousTask.result
            }
            
            endActivity()

            let attributes = BrewActivityAttributes(
                recipeName: recipeName,
                methodName: methodName,
                totalWaterVolume: totalWaterVolume
            )

            let initialContentState = BrewActivityAttributes.ContentState(
                phaseName: initialPhaseName,
                targetWaterVolume: targetWaterVolume,
                currentPhaseProgress: currentPhaseProgress,
                phaseEndDate: Date().addingTimeInterval(phaseRemainingSeconds),
                isPaused: false,
                pausedRemainingSeconds: phaseRemainingSeconds
            )

            do {
                currentActivity = try Activity<BrewActivityAttributes>.request(
                    attributes: attributes,
                    content: .init(state: initialContentState, staleDate: nil)
                )
                logger.info("Started Live Activity: \(self.currentActivity?.id ?? "", privacy: .public)")
            } catch {
                logger.error("Error starting Live Activity: \(error.localizedDescription, privacy: .public)")
            }
        }
        #endif
    }

    func updateActivity(
        phaseName: String,
        phaseRemainingSeconds: TimeInterval,
        targetWaterVolume: Double,
        currentPhaseProgress: Double,
        isPaused: Bool = false
    ) {
        #if !targetEnvironment(macCatalyst)
        guard let activity = currentActivity else { return }

        let previousTask = startTask
        startTask = Task {
            if let previousTask {
                _ = await previousTask.result
            }

            let updatedContentState = BrewActivityAttributes.ContentState(
                phaseName: phaseName,
                targetWaterVolume: targetWaterVolume,
                currentPhaseProgress: currentPhaseProgress,
                phaseEndDate: Date().addingTimeInterval(phaseRemainingSeconds),
                isPaused: isPaused,
                pausedRemainingSeconds: phaseRemainingSeconds
            )

            let content = ActivityContent<BrewActivityAttributes.ContentState>(
                state: updatedContentState,
                staleDate: nil
            )

            await activity.update(content)
            logger.info("Updated Live Activity: \(activity.id, privacy: .public)")
        }
        #endif
    }

    func endActivity(finalState: BrewActivityAttributes.ContentState? = nil, delayedDismissal: Bool = false) {
        #if !targetEnvironment(macCatalyst)
        guard let activity = currentActivity else { return }

        let previousTask = startTask
        startTask = Task {
            if let previousTask {
                _ = await previousTask.result
            }

            let dismissalPolicy: ActivityUIDismissalPolicy
            if delayedDismissal {
                dismissalPolicy = .after(Date().addingTimeInterval(300)) // Keep on lockscreen for 5 minutes
            } else {
                dismissalPolicy = .immediate
            }

            if let finalState {
                let content = ActivityContent<BrewActivityAttributes.ContentState>(
                    state: finalState,
                    staleDate: nil
                )
                await activity.end(content, dismissalPolicy: dismissalPolicy)
            } else {
                await activity.end(nil, dismissalPolicy: dismissalPolicy)
            }
            
            logger.info("Ended Live Activity: \(activity.id, privacy: .public)")
            if self.currentActivity?.id == activity.id {
                self.currentActivity = nil
            }
        }
        #endif
    }
}
#endif
