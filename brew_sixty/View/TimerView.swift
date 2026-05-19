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
                            
                            Text(viewModel.getPhaseText(for: elapsed))
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
                        if viewModel.isRunning {
                            viewModel.toggleTimer()
                            viewModel.saveLog(in: modelContext)
                            dismiss()
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
        .onChange(of: viewModel.isFinished) { oldValue, newValue in
            if newValue == true {
                viewModel.saveLog(in: modelContext)
                dismiss()
            }
        }
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
