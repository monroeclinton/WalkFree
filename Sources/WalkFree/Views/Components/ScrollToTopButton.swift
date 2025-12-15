import SwiftUI

struct ScrollOffsetPreferenceKey: PreferenceKey {
  static let defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}

struct ScrollToTopButton: View {
  @Binding var scrollOffset: CGFloat
  let scrollToTop: () -> Void

  private var isVisible: Bool {
    scrollOffset > 30
  }

  var body: some View {
    Button(action: scrollToTop) {
      Image(systemName: "arrow.up.circle.fill")
        .font(.system(size: 44))
        .foregroundColor(.white)
        .background(
          Circle()
            .fill(Color.blue)
            .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
        )
    }
    .buttonStyle(.plain)
    .opacity(isVisible ? 1 : 0)
    .scaleEffect(isVisible ? 1 : 0.8)
    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: scrollOffset)
    .allowsHitTesting(isVisible)
  }
}
