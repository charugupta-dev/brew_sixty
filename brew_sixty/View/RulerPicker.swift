import SwiftUI

struct RulerPicker: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    
    private var ticksCount: Int {
        Int((range.upperBound - range.lowerBound) / step) + 1
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Spacer(minLength: UIScreen.main.bounds.width / 2 - 16)
                        
                        ForEach(0..<ticksCount, id: \.self) { idx in
                            let tickValue = range.lowerBound + Double(idx) * step
                            let isMajor = idx % 5 == 0
                            
                            VStack(spacing: 4) {
                                Rectangle()
                                    .fill(isMajor ? Color.white.opacity(0.8) : Color.white.opacity(0.3))
                                    .frame(width: isMajor ? 1.5 : 1.0, height: isMajor ? 24 : 12)
                                
                                if isMajor {
                                    Text(String(format: "%.1f", tickValue))
                                        .font(.system(size: 8))
                                        .foregroundStyle(Color.white.opacity(0.4))
                                }
                            }
                            .frame(width: 14)
                            .id(idx)
                            .onTapGesture {
                                withAnimation {
                                    value = tickValue
                                }
                            }
                        }
                        
                        Spacer(minLength: UIScreen.main.bounds.width / 2 - 16)
                    }
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .global).minX)
                        }
                    )
                }
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                    let centerOffset = -offset + UIScreen.main.bounds.width / 2 - 16
                    let itemWidth: CGFloat = 22 // 14 frame width + 8 spacing
                    let estimatedIdx = Int(round(centerOffset / itemWidth))
                    let clampedIdx = min(max(estimatedIdx, 0), ticksCount - 1)
                    let computedVal = range.lowerBound + Double(clampedIdx) * step
                    if abs(value - computedVal) > 0.01 {
                        value = computedVal
                    }
                }
                .onAppear {
                    let idx = Int((value - range.lowerBound) / step)
                    proxy.scrollTo(idx, anchor: .center)
                }
            }
            .frame(height: 50)
            .overlay(
                // Center Needle indicator in Gold theme
                Rectangle()
                    .fill(Color.primaryCopper)
                    .frame(width: 2, height: 40)
                    .shadow(color: Color.primaryCopper.opacity(0.5), radius: 2)
                , alignment: .center
            )
        }
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
