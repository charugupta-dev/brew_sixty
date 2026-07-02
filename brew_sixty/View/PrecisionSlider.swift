import SwiftUI

struct PrecisionSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let rangeSpan = range.upperBound - range.lowerBound
            let progress = CGFloat((value - range.lowerBound) / rangeSpan)
            let clampedProgress = min(max(progress, 0), 1)
            let thumbSize: CGFloat = 20
            
            ZStack(alignment: .leading) {
                // Track Background with subtle tick marks
                ZStack {
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 6)
                    
                    // Subtle tick lines along the track to add technical precision
                    HStack(spacing: 0) {
                        let ticks = 7
                        ForEach(0..<ticks, id: \.self) { idx in
                            Rectangle()
                                .fill(Color.coffeeCream.opacity(0.14))
                                .frame(width: 1.5, height: 6)
                            if idx < ticks - 1 {
                                Spacer()
                            }
                        }
                    }
                }
                
                // Active Track Fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.primaryCopper, Color.brushedCopper],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: clampedProgress * width, height: 6)
                
                // Glowing Thumb Handle
                Circle()
                    .fill(Color.coffeeCream)
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(
                        Circle()
                            .stroke(Color.primaryCopper, lineWidth: 2)
                    )
                    .shadow(color: Color.primaryCopper.opacity(0.4), radius: 3)
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
