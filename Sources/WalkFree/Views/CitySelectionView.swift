import SwiftUI

struct CitySelectionView: View {
  @Binding var selectedCityIndex: Int
  @Binding var isPresented: Bool
  let cities: [City]
  @State private var searchText = ""

  private var filteredCities: [City] {
    if searchText.isEmpty {
      return cities
    }
    return cities.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
  }

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Search field
        HStack {
          Image(systemName: "magnifyingglass")
            .foregroundColor(.gray)
            .font(.system(size: 16))

          TextField("Search cities", text: $searchText)
            .textFieldStyle(.roundedBorder)
            .font(.system(size: 16))
            .autocapitalization(.none)
            .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))

        // City list
        List {
          ForEach(Array(filteredCities.enumerated()), id: \.element.id) { index, city in
            let originalIndex = cities.firstIndex(where: { $0.id == city.id }) ?? 0

            Button(action: {
              selectedCityIndex = originalIndex
              isPresented = false
            }) {
              HStack {
                VStack(alignment: .leading, spacing: 4) {
                  Text(city.name)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.primary)

                  Text("\(city.completedCount)/\(city.totalStreets) streets")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                }

                Spacer()

                if originalIndex == selectedCityIndex {
                  Image(systemName: "checkmark")
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .semibold))
                }
              }
              .padding(.vertical, 4)
            }
          }
        }
        .listStyle(.plain)
      }
      .navigationTitle("Select City")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Cancel") {
            isPresented = false
          }
        }
      }
    }
  }
}
