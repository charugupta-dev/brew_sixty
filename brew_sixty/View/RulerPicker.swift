import SwiftUI

struct RulerPicker: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    
    private var ticksCount: Int {
        Int(round((range.upperBound - range.lowerBound) / step)) + 1
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let itemWidth: CGFloat = 22 // 14 frame width + 8 spacing
            
            ScrollViewReader { proxy in
                ZStack(alignment: .bottom) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .bottom, spacing: 8) {
                            // Leading padding to center the first tick
                            Spacer(minLength: width / 2 - 7)
                            
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
                                .frame(width: 14)
                                .id(idx)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        proxy.scrollTo(idx, anchor: .center)
                                        value = tickValue
                                    }
                                }
                            }
                            
                            // Trailing padding to center the last tick
                            Spacer(minLength: width / 2 - 7)
                        }
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: geo.frame(in: .named("ruler_scroll")).minX
                                )
                            }
                        )
                    }
                    .coordinateSpace(name: "ruler_scroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                        // Calculate middle element offset
                        let centerOffset = -offset + (width / 2) - 7
                        let estimatedIdx = Int(round(centerOffset / itemWidth))
                        let clampedIdx = min(max(estimatedIdx, 0), ticksCount - 1)
                        let computedVal = range.lowerBound + Double(clampedIdx) * step
                        
                        // Only update value binding if it's different to avoid scroll loop fighting
                        if abs(value - computedVal) > 0.01 {
                            DispatchQueue.main.async {
                                value = computedVal
                            }
                        }
                    }
                    .onChange(of: value) { oldValue, newValue in
                        let idx = Int(round((newValue - range.lowerBound) / step))
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(idx, anchor: .center)
                        }
                    }
                    .onAppear {
                        let idx = Int(round((value - range.lowerBound) / step))
                        DispatchQueue.main.async {
                            proxy.scrollTo(idx, anchor: .center)
                        }
                    }
                    
                    // Central indicator needle in Gold theme
                    Rectangle()
                        .fill(Color.primaryCopper)
                        .frame(width: 2, height: 40)
                        .shadow(color: Color.primaryCopper.opacity(0.5), radius: 2)
                        .alignmentGuide(.bottom) { d in d[.bottom] - 8 }
                }
            }
        }
        .frame(height: 60)
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
