import SwiftUI

struct SteppedWeightPicker: View {
    @Binding var value: Double
    let range: ClosedRange<Double> = AppConstants.Pickers.steppedWeightRange
    let step: Double = AppConstants.Pickers.steppedWeightStep
    let presets: [Double] = AppConstants.Pickers.steppedWeightPresets
    let onInteraction: (() -> Void)?

    init(value: Binding<Double>, onInteraction: (() -> Void)? = nil) {
        _value = value
        self.onInteraction = onInteraction
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button {
                    if value > range.lowerBound {
                        onInteraction?()
                        value = max(range.lowerBound, value - step)
                        UISelectionFeedbackGenerator().selectionChanged()
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: AppConstants.Pickers.steppedWeightButtonSize, height: AppConstants.Pickers.steppedWeightButtonSize)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", value))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    Text("GRAMS")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color.primaryCopper)
                        .tracking(AppConstants.UI.eyebrowTracking)
                }
                
                Spacer()
                
                Button {
                    if value < range.upperBound {
                        onInteraction?()
                        value = min(range.upperBound, value + step)
                        UISelectionFeedbackGenerator().selectionChanged()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: AppConstants.Pickers.steppedWeightButtonSize, height: AppConstants.Pickers.steppedWeightButtonSize)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                }
            }
            .padding(.vertical, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(presets, id: \.self) { preset in
                        let isSelected = abs(value - preset) < 0.01
                        Button {
                            withAnimation(.easeOut(duration: 0.15)) {
                                onInteraction?()
                                value = preset
                                UISelectionFeedbackGenerator().selectionChanged()
                            }
                        } label: {
                            Text(String(format: "%.0fg", preset))
                                .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .monospaced))
                                .foregroundStyle(isSelected ? .black : .white.opacity(0.65))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? Color.primaryCopper : Color.white.opacity(0.04))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.08), lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
    }
}
