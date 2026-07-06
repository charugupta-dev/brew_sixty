import SwiftUI

struct RulerPicker: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let majorStep: Double?
    let onInteraction: (() -> Void)?
    
    @State private var dragOffset: CGFloat = 0
    @State private var baseOffset: CGFloat = 0
    
    private var ticksCount: Int {
        Int(round((range.upperBound - range.lowerBound) / step)) + 1
    }
    
    private let itemWidth = AppConstants.Pickers.rulerItemWidth

    init(
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        majorStep: Double? = nil,
        onInteraction: (() -> Void)? = nil
    ) {
        _value = value
        self.range = range
        self.step = step
        self.majorStep = majorStep
        self.onInteraction = onInteraction
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let maxOffset: CGFloat = 0
            let minOffset: CGFloat = -CGFloat(ticksCount - 1) * itemWidth
            
            let currentOffset = min(max(baseOffset + dragOffset, minOffset), maxOffset)
            
            let alignmentOffset = CGFloat(ticksCount - 1) * itemWidth / 2.0
            
            ZStack(alignment: .bottom) {
                Color.white.opacity(0.01)
                
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(0..<ticksCount, id: \.self) { idx in
                        let tickValue = range.lowerBound + Double(idx) * step
                        let isMajor = isMajorTick(tickValue)
                        
                        let isActive = abs(value - tickValue) < 0.01
                        
                        VStack(spacing: 6) {
                            if isMajor {
                                Text(String(format: "%.0f", tickValue))
                                    .font(.system(size: isActive ? 15 : 12, weight: isActive ? .bold : .semibold, design: .monospaced))
                                    .foregroundStyle(isActive ? Color.primaryCopper : Color.coffeeCream.opacity(0.5))
                            } else {
                                Text(" ")
                                    .font(.system(size: 8))
                            }
                            
                            Rectangle()
                                .fill(isActive ? Color.primaryCopper : (isMajor ? Color.coffeeCream.opacity(0.7) : Color.coffeeCream.opacity(0.24)))
                                .frame(width: isMajor ? 1.5 : 1.0, height: isMajor ? (isActive ? 30 : 25) : 14)
                        }
                        .frame(width: itemWidth)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            let targetOffset = -CGFloat(idx) * itemWidth
                            withAnimation(.easeOut(duration: 0.2)) {
                                baseOffset = targetOffset
                                dragOffset = 0
                                onInteraction?()
                                value = tickValue
                            }
                        }
                    }
                }
                .offset(x: alignmentOffset + currentOffset)
                
                Rectangle()
                    .fill(Color.primaryCopper)
                    .frame(width: AppConstants.Pickers.rulerIndicatorWidth, height: AppConstants.Pickers.rulerIndicatorHeight)
                    .shadow(color: Color.primaryCopper.opacity(0.5), radius: 2)
                    .alignmentGuide(.bottom) { d in d[.bottom] - 8 }
                
                VStack(spacing: 0) {
                    Image(systemName: "triangle.fill")
                        .resizable()
                        .frame(width: AppConstants.Pickers.rulerTriangleWidth, height: AppConstants.Pickers.rulerTriangleHeight)
                        .foregroundStyle(Color.primaryCopper)
                        .rotationEffect(.degrees(180))
                        .shadow(color: Color.primaryCopper.opacity(0.5), radius: 2)
                    Spacer()
                }
                .frame(width: width, height: AppConstants.Pickers.rulerHeight)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        dragOffset = gesture.translation.width
                        
                        let liveOffset = min(max(baseOffset + gesture.translation.width, minOffset), maxOffset)
                        let activeIdx = Int(round(-liveOffset / itemWidth))
                        let activeVal = range.lowerBound + Double(activeIdx) * step
                        
                        if abs(value - activeVal) > 0.01 {
                            onInteraction?()
                            UISelectionFeedbackGenerator().selectionChanged()
                            value = activeVal
                        }
                    }
                    .onEnded { gesture in
                        baseOffset += gesture.translation.width
                        baseOffset = min(max(baseOffset, minOffset), maxOffset)
                        dragOffset = 0
                        
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
        .frame(height: AppConstants.Pickers.rulerHeight)
        .clipped()
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
