//
//  BrewFormView.swift
//  brew_sixty
//
//  Created by Charu Gupta on 11/05/26.
//

import SwiftUI

struct BrewFormView: View {
    @AppStorage("preferredRatio") private var brewRatio: Double = 12.0
    @Environment(\.dismiss) private var dismiss
    @State private var beanWeight: Double = 8.0
    private var totalWater: Double {
        beanWeight * brewRatio
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Text("Beans (g)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 32) {
                        Button {
                            if beanWeight > 1 { beanWeight -= 0.5 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.primary)
                        }
                        Text(String(format: "%.1f", beanWeight))
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .frame(width: 140)
                            .multilineTextAlignment(.center)
                        Button {
                            beanWeight += 0.5
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .padding(.top, 40)
                
                VStack(spacing: 8) {
                    Text("Target Water: \(String(format: "%.0f", totalWater)) g")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Using 1:\(Int(brewRatio)) Ratio")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)
                Spacer()
                
                
                NavigationLink {
                    TimerView(viewModel: BrewViewModel(beanWeight: beanWeight, ratio: brewRatio))
                } label: {
                    Text("Start Timer")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.primary)
                        .foregroundStyle(.background)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .navigationTitle("New Brew")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.footnote)
                        .foregroundStyle(.primary)
                }
                .tint(.primary)
            }
        }
    }
}

#Preview {
    BrewFormView()
}
