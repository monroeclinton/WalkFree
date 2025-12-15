import SwiftUI

struct StreetListView: View {
  let streets: [Street]
  let isCompletedTab: Bool
  let searchText: String
  let onToggleCompletion: (Street) -> Void
  let onSelectStreet: ((Street) -> Void)?

  init(
    streets: [Street], isCompletedTab: Bool, searchText: String,
    onToggleCompletion: @escaping (Street) -> Void, onSelectStreet: ((Street) -> Void)? = nil
  ) {
    self.streets = streets
    self.isCompletedTab = isCompletedTab
    self.searchText = searchText
    self.onToggleCompletion = onToggleCompletion
    self.onSelectStreet = onSelectStreet
  }

  var body: some View {
    Group {
      if streets.isEmpty {
        EmptyStateView(
          icon: isCompletedTab ? "checkmark.circle" : "map",
          title: "No streets",
          message: isCompletedTab
            ? (searchText.isEmpty
              ? "No streets completed yet" : "No completed streets match your search")
            : (searchText.isEmpty ? "All streets are completed" : "No streets match your search")
        )
      } else {
        LazyVStack(spacing: 0) {
          ForEach(sortedStreets) { street in
            StreetRowView(
              street: street,
              isCompleted: street.isCompleted,
              action: {
                onToggleCompletion(street)
              },
              onSelect: {
                onSelectStreet?(street)
              }
            )

            Divider()
              .padding(.leading, 60)
          }
        }
      }
    }
  }

  private var sortedStreets: [Street] {
    if isCompletedTab {
      return streets.sorted(by: {
        ($0.completedDate ?? Date.distantPast) > ($1.completedDate ?? Date.distantPast)
      })
    } else {
      return streets
    }
  }
}
