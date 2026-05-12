//
//  TimerView.swift
//  brew_sixty
//
//  Created by Charu Gupta on 11/05/26.
//

import SwiftUI

struct TimerView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Dependencies passed in from the BrewFormView
    let targetWater: Double
    let bloomWater: Double
    
    // Temporary State (Will be moved to ViewModel)
    @State private var startDate: Date? = nil
    @State private var isRunning = false
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            VStack(spacing: 60) {
                
                Text(isRunning ? "Brewing..." : "Ready to Brew")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                TimelineView(.animation) { context in
                    let elapsed = calculateElapsed(from: context.date)
                    let progress = min(elapsed / 150.0, 1.0)
                    
                    ZStack {
                        
                        Circle()
                            .stroke(.ultraThinMaterial, lineWidth: 16)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.primary, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 8) {
                            Text(formatTime(elapsed))
                                .font(.system(size: 72, weight: .light, design: .rounded))
                                .contentTransition(.numericText(value: elapsed))
                            
                            Text(currentPhase(elapsed: elapsed))
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 320, height: 320)
                }
                
                HStack(spacing: 40) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundStyle(.primary)
                            .frame(width: 80, height: 80)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    
                    Button {
                        if isRunning {
                            // Stop & Save logic goes here later
                            isRunning = false
                            dismiss()
                        } else {
                            startDate = Date()
                            isRunning = true
                        }
                    } label: {
                        Image(systemName: isRunning ? "stop.fill" : "play.fill")
                            .font(.title)
                            .foregroundStyle(.background)
                            .frame(width: 80, height: 80)
                            .background(Color.primary, in: Circle())
                            .shadow(color: .primary.opacity(0.3), radius: 10, y: 5)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func calculateElapsed(from contextDate: Date) -> TimeInterval {
        guard let start = startDate, isRunning else { return 0 }
        return contextDate.timeIntervalSince(start)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func currentPhase(elapsed: TimeInterval) -> String {
        if elapsed == 0 { return "Target: \(Int(targetWater))g" }
        if elapsed < 45 { return "Bloom: Pour \(Int(bloomWater))g" }
        if elapsed < 150 { return "Drawdown: Pour to \(Int(targetWater))g" }
        return "Enjoy your coffee"
    }
}
#Preview {
    TimerView(targetWater: 10.0, bloomWater: 5.0)
}
