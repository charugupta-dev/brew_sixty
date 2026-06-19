//
//  TimerView.swift
//  brew_sixty
//
//  Created by Charu Gupta on 11/05/26.
//

import SwiftUI
import SwiftData

struct TimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let viewModel: BrewViewModel
    var onDismissAll: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            VStack(spacing: 60) {
                
                Text(viewModel.isRunning ? "Brewing..." : "Ready to Brew")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                TimelineView(.animation) { context in
                    let elapsed = viewModel.calculateElapsed(from: context.date)
                    let progress = viewModel.getProgress(for: elapsed)
                    
                    // We want a beautiful smooth transition from black to brown once drawdown starts.
                    // The bloom period ends at 45.0s. Let's make the transition duration 0.8 seconds.
                    let transitionDuration: TimeInterval = 0.8
                    let transitionProgress: Double = {
                        if elapsed < viewModel.bloomDuration {
                            return 0.0
                        } else {
                            return min((elapsed - viewModel.bloomDuration) / transitionDuration, 1.0)
                        }
                    }()
                    
                    let coffeeBrown = Color(red: 0.45, green: 0.31, blue: 0.22)
                    let currentColor = interpolateColor(from: .black, to: coffeeBrown, fraction: transitionProgress)
                    
                    ZStack {
                        
                        Circle()
                            .stroke(.ultraThinMaterial, lineWidth: 16)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(currentColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 8) {
                            Text(formatTime(elapsed))
                                .font(.system(size: 72, weight: .light, design: .rounded))
                                .contentTransition(.numericText(value: elapsed))
                            
                            Text(viewModel.getPhaseText(for: elapsed))
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 320, height: 320)
                }
                
                HStack(spacing: 40) {
                    Button {
                        if let onDismissAll = onDismissAll {
                            onDismissAll()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundStyle(.primary)
                            .frame(width: 80, height: 80)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    
                    Button {
                        if viewModel.isRunning {
                            viewModel.toggleTimer()
                            viewModel.saveLog(in: modelContext)
                            if let onDismissAll = onDismissAll {
                                onDismissAll()
                            } else {
                                dismiss()
                            }
                        } else {
                            viewModel.toggleTimer()
                        }
                    } label: {
                        Image(systemName: viewModel.isRunning ? "stop.fill" : "play.fill")
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
        .onAppear {
            if !viewModel.isRunning {
                viewModel.toggleTimer()
            }
        }
        .onChange(of: viewModel.isFinished) { oldValue, newValue in
            if newValue == true {
                viewModel.saveLog(in: modelContext)
                if let onDismissAll = onDismissAll {
                    onDismissAll()
                } else {
                    dismiss()
                }
            }
        }
    }
    
    private func interpolateColor(from start: Color, to end: Color, fraction: Double) -> Color {
        let f = min(max(fraction, 0), 1)
        #if canImport(UIKit)
        let uiStart = UIColor(start)
        let uiEnd = UIColor(end)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        uiStart.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        uiEnd.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return Color(red: Double(r1 + (r2 - r1) * CGFloat(f)),
                     green: Double(g1 + (g2 - g1) * CGFloat(f)),
                     blue: Double(b1 + (b2 - b1) * CGFloat(f)),
                     opacity: Double(a1 + (a2 - a1) * CGFloat(f)))
        #else
        return end
        #endif
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
#Preview {
    TimerView(viewModel: BrewViewModel(beanWeight: 8, ratio: 1.12))
}
