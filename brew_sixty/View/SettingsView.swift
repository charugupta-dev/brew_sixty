//
//  SettingsView.swift
//  brew_sixty
//
//  Created by Charu Gupta on 11/05/26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage(String.SettingsKeys.preferredRatio) private var brewRatio: Double = 12.0
    @AppStorage(String.SettingsKeys.preferredBeanWeight) private var preferredBeanWeight: Double = 8.0
    
    @State private var beanWeightInput: String = ""
    @State private var localRatio: Double = 12.0
    
    var body: some View {
        NavigationStack {
            ZStack {
                RadialGradient.coffeeBackground
                    .ignoresSafeArea()
                
                Form {
                    Section(header: Text("Brew Recipe Defaults")) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Default Brew Ratio")
                                    .fontWeight(.medium)
                                Spacer()
                                Text("1 : \(String(format: "%.1f", localRatio))")
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.coffeeAccent)
                            }
                            
                            Slider(value: $localRatio, in: 8...22, step: 0.5) { editing in
                                if !editing {
                                    brewRatio = localRatio
                                }
                            }
                            .tint(Color.coffeeAccent)
                            
                            HStack {
                                Text("1:8 (Strong)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("1:15 (Standard)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("1:22 (Mild)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Default Bean Weight")
                                    .fontWeight(.medium)
                                Spacer()
                                HStack(spacing: 4) {
                                    TextField("8.0", text: $beanWeightInput)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 60)
                                        .textFieldStyle(.roundedBorder)
                                        .onChange(of: beanWeightInput) { _, newValue in
                                            if let doubleVal = parseLocaleDouble(newValue), doubleVal > 0 {
                                                preferredBeanWeight = doubleVal
                                            }
                                        }
                                    Text("g")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .scrollContentBackground(.hidden)
                .navigationTitle("Settings")
                .onAppear {
                    localRatio = brewRatio
                    beanWeightInput = String(format: "%.1f", preferredBeanWeight)
                }
                .onChange(of: brewRatio) { _, newValue in
                    localRatio = newValue
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
