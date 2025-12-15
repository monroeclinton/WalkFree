import SwiftUI

struct LoadingOverlay: View {
  let isLoading: Bool

  var body: some View {
    Group {
      if isLoading {
        VStack(spacing: 16) {
          ProgressView()
          Text("Loading streets...")
            .font(.system(size: 16))
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
      }
    }
  }
}
