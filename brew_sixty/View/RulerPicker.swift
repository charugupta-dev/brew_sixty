import SwiftUI

struct RulerPicker: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    
    @State private var dragOffset: CGFloat = 0
    @State private var baseOffset: CGFloat = 0
    
    private var ticksCount: Int {
        Int(round((range.upperBound - range.lowerBound) / step)) + 1
    }
    
    private let itemWidth: CGFloat = 16 // tick width + spacing
    
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
                        let isMajor = idx % 5 == 0
                        
                        VStack(spacing: 4) {
                            if isMajor {
                                Text(String(format: "%.1f", tickValue))
                                    .font(.system(size: 8))
                                    .foregroundStyle(Color.white.opacity(0.4))
                            } else {
                                Text(" ")
                                    .font(.system(size: 8))
                            }
                            
                            Rectangle()
                                .fill(isMajor ? Color.white.opacity(0.8) : Color.white.opacity(0.3))
                                .frame(width: isMajor ? 1.5 : 1.0, height: isMajor ? 24 : 12)
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
                
                // Central gold indicator needle
                Rectangle()
                    .fill(Color.primaryCopper)
                    .frame(width: 2, height: 40)
                    .shadow(color: Color.primaryCopper.opacity(0.5), radius: 2)
                    .alignmentGuide(.bottom) { d in d[.bottom] - 8 }
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
    }
    
    private func syncOffsetFromValue() {
        let idx = Int(round((value - range.lowerBound) / step))
        baseOffset = -CGFloat(idx) * itemWidth
    }
}
