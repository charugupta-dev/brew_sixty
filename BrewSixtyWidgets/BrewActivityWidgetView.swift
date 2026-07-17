import WidgetKit
import SwiftUI
import ActivityKit

struct BrewActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BrewActivityAttributes.self) { context in
            // Lock Screen Banner / Notification Center presentation
            LockScreenWidgetView(context: context)
        } dynamicIsland: { context in
            // Dynamic Island presentation
            DynamicIsland {
                // Expanded region
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.title2)
                            .foregroundStyle(Color.terracotta)
                    }
                    .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        let now = Date()
                        if context.state.isPaused {
                            Text(formatTime(context.state.pausedRemainingSeconds))
                                .font(.title3)
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .foregroundStyle(Color.terracotta)
                        } else if now < context.state.phaseEndDate {
                            Text(context.state.phaseEndDate, style: .timer)
                                .font(.title3)
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .foregroundStyle(Color.terracotta)
                        } else {
                            Text("Done!")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.terracotta)
                        }
                        Text("remaining")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.recipeName)
                            .font(.headline)
                            .fontWeight(.bold)
                        Text(context.state.phaseName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Water Target:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(context.state.targetWaterVolume.rounded()))g")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.terracotta)
                        }
                        
                        // Custom progress bar
                        if context.state.isPaused {
                            ProgressView(value: context.state.currentPhaseProgress)
                                .progressViewStyle(.linear)
                                .tint(Color.terracotta)
                                .frame(height: 6)
                        } else {
                            ProgressView(timerInterval: context.state.phaseStartDate...context.state.phaseEndDate, countsDown: false)
                                .progressViewStyle(.linear)
                                .tint(Color.terracotta)
                                .frame(height: 6)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
                }
            } compactLeading: {
                Image(systemName: "cup.and.saucer.fill")
                    .foregroundStyle(Color.terracotta)
                    .padding(.leading, 4)
            } compactTrailing: {
                let now = Date()
                if context.state.isPaused {
                    Text(formatTime(context.state.pausedRemainingSeconds))
                        .monospacedDigit()
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.terracotta)
                        .padding(.trailing, 4)
                } else if now < context.state.phaseEndDate {
                    Text(context.state.phaseEndDate, style: .timer)
                        .monospacedDigit()
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.terracotta)
                        .padding(.trailing, 4)
                } else {
                    Text("Done")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.terracotta)
                        .padding(.trailing, 4)
                }
            } minimal: {
                Image(systemName: "cup.and.saucer.fill")
                    .foregroundStyle(Color.terracotta)
            }
            .keylineTint(Color.terracotta)
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Lock Screen Banner View
struct LockScreenWidgetView: View {
    let context: ActivityViewContext<BrewActivityAttributes>
    
    var body: some View {
        HStack(spacing: 16) {
            // Left region: Large Timer
            VStack(alignment: .leading, spacing: 2) {
                let now = Date()
                if context.state.isPaused {
                    Text(formatTime(context.state.pausedRemainingSeconds))
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.terracotta)
                } else if now < context.state.phaseEndDate {
                    Text(context.state.phaseEndDate, style: .timer)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.terracotta)
                } else {
                    Text("Done!")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.terracotta)
                }
                
                Text(context.state.isPaused ? "PAUSED" : "ACTIVE BREW")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 110, alignment: .leading)
            
            // Vertical Divider
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 1)
                .frame(maxHeight: .infinity)
                .padding(.vertical, 4)
            
            // Right region: Brew Details
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(context.attributes.recipeName)
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Text(context.attributes.methodName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.terracotta.opacity(0.2))
                        .clipShape(Capsule())
                        .foregroundStyle(Color.terracotta)
                }
                
                Text(context.state.phaseName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // Progress and Target Weight
                HStack(spacing: 8) {
                    if context.state.isPaused {
                        ProgressView(value: context.state.currentPhaseProgress)
                            .progressViewStyle(.linear)
                            .tint(Color.terracotta)
                            .frame(height: 6)
                    } else {
                        ProgressView(timerInterval: context.state.phaseStartDate...context.state.phaseEndDate, countsDown: false)
                            .progressViewStyle(.linear)
                            .tint(Color.terracotta)
                            .frame(height: 6)
                    }
                    
                    if context.state.targetWaterVolume > 0 {
                        Text("\(Int(context.state.targetWaterVolume.rounded()))g")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.terracotta)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .containerBackground(for: .widget) {
            Color.darkRoast
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Color Theme Extension
extension Color {
    static let darkRoast = Color(red: 0.11, green: 0.08, blue: 0.07)
    static let terracotta = Color(red: 0.83, green: 0.44, blue: 0.33)
}
