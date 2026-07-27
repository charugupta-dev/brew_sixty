import SwiftUI

struct SteppedWeightPicker: View {
    @Binding var value: Double
    let range: ClosedRange<Double> = AppConstants.Pickers.steppedWeightRange
    let step: Double = AppConstants.Pickers.steppedWeightStep
    let presets: [Double] = AppConstants.Pickers.steppedWeightPresets
    let onInteraction: (() -> Void)?
    
    @State private var showPresets = false // Collapsible disclosure state

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
                        .foregroundStyle(Color.coffeeCream)
                        .frame(width: AppConstants.Pickers.steppedWeightButtonSize, height: AppConstants.Pickers.steppedWeightButtonSize)
                        .background(Color(red: 0.94, green: 0.92, blue: 0.89))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(red: 0.86, green: 0.84, blue: 0.81), lineWidth: 1))
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text("\(Int(value.rounded()))")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.coffeeCream)
                    Text("GRAMS")
                        .font(.system(size: 10, weight: .bold))
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
                        .foregroundStyle(Color.coffeeCream)
                        .frame(width: AppConstants.Pickers.steppedWeightButtonSize, height: AppConstants.Pickers.steppedWeightButtonSize)
                        .background(Color(red: 0.94, green: 0.92, blue: 0.89))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(red: 0.86, green: 0.84, blue: 0.81), lineWidth: 1))
                }
            }
            .padding(.vertical, 4)
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showPresets.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Text(showPresets ? "Hide Presets" : "Quick Presets")
                    Image(systemName: showPresets ? "chevron.up" : "chevron.down")
                }
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.primaryCopper)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(Color(red: 0.94, green: 0.92, blue: 0.89))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            if showPresets {
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
                                    .foregroundStyle(isSelected ? .white : Color.coffeeCream.opacity(0.65))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(isSelected ? Color.primaryCopper : Color(red: 0.94, green: 0.92, blue: 0.89))
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(isSelected ? Color.clear : Color(red: 0.86, green: 0.84, blue: 0.81), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
