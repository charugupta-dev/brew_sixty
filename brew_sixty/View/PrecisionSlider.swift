import SwiftUI

struct PrecisionSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let onInteraction: (() -> Void)?

    init(
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        onInteraction: (() -> Void)? = nil
    ) {
        _value = value
        self.range = range
        self.step = step
        self.onInteraction = onInteraction
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let rangeSpan = range.upperBound - range.lowerBound
            let progress = CGFloat((value - range.lowerBound) / rangeSpan)
            let clampedProgress = min(max(progress, 0), 1)
            let thumbSize = AppConstants.Pickers.precisionThumbSize
            
            ZStack(alignment: .leading) {
                ZStack {
                    Capsule()
                        .fill(Color.black.opacity(0.35))
                        .frame(height: AppConstants.Pickers.precisionTrackHeight)
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(AppConstants.UI.subtleBorderOpacity), lineWidth: 1)
                        )
                    
                    HStack(spacing: 0) {
                        let ticks = AppConstants.Pickers.precisionTickCount
                        ForEach(0..<ticks, id: \.self) { idx in
                            Rectangle()
                                .fill(Color.coffeeCream.opacity(0.18))
                                .frame(width: AppConstants.Pickers.precisionTickWidth, height: AppConstants.Pickers.precisionTrackHeight)
                            if idx < ticks - 1 {
                                Spacer()
                            }
                        }
                    }
                }
                
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.primaryCopper, Color.brushedCopper],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: clampedProgress * width, height: AppConstants.Pickers.precisionTrackHeight)
                
                Circle()
                    .fill(Color.coffeeCream)
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(
                        Circle()
                            .stroke(Color.primaryCopper, lineWidth: 2)
                    )
                    .overlay(
                        Circle()
                            .fill(Color.primaryCopper)
                            .frame(width: AppConstants.Pickers.precisionCenterDotSize, height: AppConstants.Pickers.precisionCenterDotSize)
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 3, x: 0, y: 2)
                    .offset(x: clampedProgress * (width - thumbSize))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                let dragX = gesture.location.x - (thumbSize / 2)
                                let percent = dragX / (width - thumbSize)
                                let newVal = range.lowerBound + Double(percent) * rangeSpan
                                let steppedVal = round(newVal / step) * step
                                let clampedVal = min(max(steppedVal, range.lowerBound), range.upperBound)
                                
                                if abs(value - clampedVal) > 0.01 {
                                    onInteraction?()
                                    UISelectionFeedbackGenerator().selectionChanged()
                                    value = clampedVal
                                }
                            }
                    )
            }
            .contentShape(Rectangle())
        }
        .frame(height: 20)
    }
}
