import SwiftUI

struct StreetRowView: View {
  let street: Street
  let isCompleted: Bool
  let action: () -> Void
  let onSelect: (() -> Void)?

  init(
    street: Street, isCompleted: Bool, action: @escaping () -> Void, onSelect: (() -> Void)? = nil
  ) {
    self.street = street
    self.isCompleted = isCompleted
    self.action = action
    self.onSelect = onSelect
  }

  var body: some View {
    HStack {
      Button(action: action) {
        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
          .foregroundColor(isCompleted ? .green : .gray)
          .font(.system(size: 16))
      }
      .buttonStyle(.plain)

      Button(action: {
        onSelect?()
      }) {
        VStack(alignment: .leading, spacing: 4) {
          Text(street.name)
            .font(.system(size: 17, weight: .medium))
            .foregroundColor(.primary)

          HStack(spacing: 8) {
            if let county = street.county {
              Text(county)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            }

            if street.segments.count > 1 {
              if street.county != nil {
                Text("•")
                  .font(.system(size: 14))
                  .foregroundColor(.secondary)
              }
              Text("\(street.segments.count) segments")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            }
          }

          if street.isPartiallyCompleted {
            ProgressView(value: street.completionProgress)
              .progressViewStyle(LinearProgressViewStyle(tint: .blue))
              .frame(height: 4)
              .padding(.top, 4)
          }

          if isCompleted, let completedDate = street.completedDate {
            Text(formatDate(completedDate))
              .font(.system(size: 14))
              .foregroundColor(.secondary)
          }
        }
      }
      .buttonStyle(.plain)

      Spacer()
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 20)
    .background(Color(.systemBackground))
  }

  private func formatDate(_ date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return "Completed \(formatter.localizedString(for: date, relativeTo: Date()))"
  }
}
