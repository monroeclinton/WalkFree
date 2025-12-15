import SwiftUI

struct ProgressHeaderView: View {
  let completedCount: Int
  let totalStreets: Int
  @Binding var showPercentageTooltip: Bool

  private var completionPercentage: Double {
    guard totalStreets > 0 else { return 0 }
    return (Double(completedCount) / Double(totalStreets)) * 100
  }

  var body: some View {
    VStack(spacing: 12) {
      ZStack(alignment: .top) {
        Button(action: {
          showPercentageTooltip.toggle()
        }) {
          Text("\(completedCount)/\(totalStreets) streets")
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundColor(.primary)
        }
        .buttonStyle(.plain)

        if showPercentageTooltip {
          VStack(spacing: 4) {
            Text("\(String(format: "%.1f", completionPercentage))%")
              .font(.system(size: 16, weight: .semibold))
              .foregroundColor(.white)
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(Color.black.opacity(0.8))
          .cornerRadius(8)
          .offset(y: -50)
          .transition(.opacity.combined(with: .scale))
          .allowsHitTesting(false)
        }
      }

      // Progress bar
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.2))

          RoundedRectangle(cornerRadius: 8)
            .fill(
              LinearGradient(
                colors: [Color.blue, Color.blue.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .frame(
              width: geometry.size.width * CGFloat(completedCount) / CGFloat(max(totalStreets, 1)))
        }
      }
      .frame(height: 8)
      .padding(.horizontal, 20)
    }
    .padding(.top, 20)
    .padding(.bottom, 24)
    .background(Color(.systemBackground))
  }
}
