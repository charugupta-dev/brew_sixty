//
//  BrewFormView.swift
//  brew_sixty
//
//  Created by Charu Gupta on 11/05/26.
//

import SwiftUI

struct BrewFormView: View {
    @AppStorage(String.SettingsKeys.preferredRatio) private var brewRatio: Double = 12.0
    @AppStorage(String.SettingsKeys.preferredBeanWeight) private var preferredBeanWeight: Double = 8.0
    @Environment(\.dismiss) private var dismiss
    @State private var beanWeightString: String = ""
    @State private var timerViewModel: BrewViewModel? = nil
    
    private var beanWeight: Double {
        parseLocaleDouble(beanWeightString) ?? preferredBeanWeight
    }
    
    private var totalWater: Double {
        beanWeight * brewRatio
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                RadialGradient.coffeeBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Text("Beans (g)")
                            .font(.subheadline)
                            .foregroundStyle(Color.coffeeCream.opacity(0.8))
                        
                        HStack(spacing: 32) {
                            Button {
                                let currentVal = parseLocaleDouble(beanWeightString) ?? preferredBeanWeight
                                if currentVal > 1 {
                                    let val = currentVal - 0.5
                                    beanWeightString = String(format: "%.1f", val)
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundStyle(Color.coffeeCream)
                            }
                            TextField(String(format: "%.1f", preferredBeanWeight), text: $beanWeightString)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                                .frame(width: 140)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white)
                            Button {
                                let currentVal = parseLocaleDouble(beanWeightString) ?? preferredBeanWeight
                                let val = currentVal + 0.5
                                beanWeightString = String(format: "%.1f", val)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundStyle(Color.coffeeCream)
                            }
                        }
                    }
                    .padding(.top, 40)
                    
                    VStack(spacing: 8) {
                        Text("Target Water: \(String(format: "%.0f", totalWater)) g")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        
                        Text("Using 1:\(Int(brewRatio)) Ratio")
                            .font(.caption)
                            .foregroundStyle(Color.coffeeCream.opacity(0.8))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)
                    Spacer()
                    
                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        timerViewModel = BrewViewModel(beanWeight: beanWeight, ratio: brewRatio)
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
            }
            .navigationTitle("New Brew")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.footnote)
                        .foregroundStyle(Color.coffeeCream)
                }
                .tint(Color.coffeeCream)
            }
            .fullScreenCover(item: $timerViewModel) { vm in
                TimerView(viewModel: vm, onDismissAll: {
                    dismiss()
                })
            }
            .onAppear {
                beanWeightString = String(format: "%.1f", preferredBeanWeight)
            }
        }
    }
}

#Preview {
    BrewFormView()
}
