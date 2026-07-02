import SwiftUI

struct RulerPicker: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let majorStep: Double?
    
    @State private var dragOffset: CGFloat = 0
    @State private var baseOffset: CGFloat = 0
    
    private var ticksCount: Int {
        Int(round((range.upperBound - range.lowerBound) / step)) + 1
    }
    
    private let itemWidth: CGFloat = 16 // tick width + spacing

    init(
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        majorStep: Double? = nil
    ) {
        _value = value
        self.range = range
        self.step = step
        self.majorStep = majorStep
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let maxOffset: CGFloat = 0
            let minOffset: CGFloat = -CGFloat(ticksCount - 1) * itemWidth
            
            // Clamp offset during dragging to prevent sliding beyond boundaries
            let currentOffset = min(max(baseOffset + dragOffset, minOffset), maxOffset)
            
            // Align the first tick (index 0) of the centered HStack directly under the pointer
            let alignmentOffset = CGFloat(ticksCount - 1) * itemWidth / 2.0
            
            ZStack(alignment: .bottom) {
                // Background Track for capturing gestures
                Color.white.opacity(0.01)
                
                // Ticks track
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(0..<ticksCount, id: \.self) { idx in
                        let tickValue = range.lowerBound + Double(idx) * step
                        let isMajor = isMajorTick(tickValue)
                        
                        let isActive = abs(value - tickValue) < 0.01
                        
                        VStack(spacing: 4) {
                            if isMajor {
                                Text(String(format: "%.0f", tickValue))
                                    .font(.system(size: isActive ? 11 : 9, weight: isActive ? .bold : .medium, design: .monospaced))
                                    .foregroundStyle(isActive ? Color.primaryCopper : Color.coffeeCream.opacity(0.45))
                            } else {
                                Text(" ")
                                    .font(.system(size: 8))
                            }
                            
                            Rectangle()
                                .fill(isActive ? Color.primaryCopper : (isMajor ? Color.coffeeCream.opacity(0.7) : Color.coffeeCream.opacity(0.24)))
                                .frame(width: isMajor ? 1.5 : 1.0, height: isMajor ? (isActive ? 28 : 24) : 12)
                        }
                        .frame(width: itemWidth)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            let targetOffset = -CGFloat(idx) * itemWidth
                            withAnimation(.easeOut(duration: 0.2)) {
                                baseOffset = targetOffset
                                dragOffset = 0
                                value = tickValue
                            }
                        }
                    }
                }
                .offset(x: alignmentOffset + currentOffset) // Center the active tick
                
                // Central gold indicator needle (bottom-aligned)
                Rectangle()
                    .fill(Color.primaryCopper)
                    .frame(width: 2, height: 40)
                    .shadow(color: Color.primaryCopper.opacity(0.5), radius: 2)
                    .alignmentGuide(.bottom) { d in d[.bottom] - 8 }
                
                // Top indicator needle / triangle pointing down
                VStack(spacing: 0) {
                    Image(systemName: "triangle.fill")
                        .resizable()
                        .frame(width: 8, height: 6)
                        .foregroundStyle(Color.primaryCopper)
                        .rotationEffect(.degrees(180))
                        .shadow(color: Color.primaryCopper.opacity(0.5), radius: 2)
                    Spacer()
                }
                .frame(width: width, height: 60)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        dragOffset = gesture.translation.width
                        
                        // Calculate active value while dragging using live offset
                        let liveOffset = min(max(baseOffset + gesture.translation.width, minOffset), maxOffset)
                        let activeIdx = Int(round(-liveOffset / itemWidth))
                        let activeVal = range.lowerBound + Double(activeIdx) * step
                        
                        // Haptic feedback when crossing a tick
                        if abs(value - activeVal) > 0.01 {
                            UISelectionFeedbackGenerator().selectionChanged()
                            value = activeVal
                        }
                    }
                    .onEnded { gesture in
                        baseOffset += gesture.translation.width
                        baseOffset = min(max(baseOffset, minOffset), maxOffset)
                        dragOffset = 0
                        
                        // Snap to nearest tick
                        let activeIdx = Int(round(-baseOffset / itemWidth))
                        let snappedOffset = -CGFloat(activeIdx) * itemWidth
                        
                        withAnimation(.easeOut(duration: 0.15)) {
                            baseOffset = snappedOffset
                            value = range.lowerBound + Double(activeIdx) * step
                        }
                    }
            )
            .onAppear {
                syncOffsetFromValue()
            }
            .onChange(of: value) { _, newValue in
                // Only sync if not actively dragging
                if dragOffset == 0 {
                    let targetIdx = Int(round((newValue - range.lowerBound) / step))
                    let targetOffset = -CGFloat(targetIdx) * itemWidth
                    if abs(baseOffset - targetOffset) > 0.01 {
                        withAnimation(.easeOut(duration: 0.2)) {
                            baseOffset = targetOffset
                        }
                    }
                }
            }
        }
        .frame(height: 60)
        .clipped() // Restrict the scale rendering to the card boundaries
    }
    
    private func syncOffsetFromValue() {
        let idx = Int(round((value - range.lowerBound) / step))
        baseOffset = -CGFloat(idx) * itemWidth
    }

    private func isMajorTick(_ tickValue: Double) -> Bool {
        let spacing = majorStep ?? (step * 5)
        guard spacing > 0 else { return false }

        let normalized = (tickValue - range.lowerBound) / spacing
        return abs(normalized.rounded() - normalized) < 0.0001
    }
}
