import SwiftUI

struct EmptyStateView: View {
  let icon: String
  let title: String
  let message: String

  var body: some View {
    VStack(spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 48))
        .foregroundColor(.gray.opacity(0.5))

      Text(title)
        .font(.system(size: 20, weight: .semibold))
        .foregroundColor(.primary)

      Text(message)
        .font(.system(size: 16))
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity)
    .frame(height: 200)
    .padding(.top, 60)
  }
}
