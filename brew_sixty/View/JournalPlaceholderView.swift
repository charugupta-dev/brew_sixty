import SwiftUI

struct JournalPlaceholderView: View {
    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.08).ignoresSafeArea()
            Text("Journal View")
                .foregroundStyle(.white)
        }
    }
}
