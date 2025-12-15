import SwiftUI

struct SearchBarView: View {
  @Binding var searchText: String

  var body: some View {
    HStack {
      Image(systemName: "magnifyingglass")
        .foregroundColor(.gray)
        .font(.system(size: 16))

      TextField("Search streets", text: $searchText)
        .textFieldStyle(.roundedBorder)
        .font(.system(size: 16))
        .submitLabel(.search)

      if !searchText.isEmpty {
        Button(action: {
          searchText = ""
        }) {
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(.gray)
            .font(.system(size: 16))
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 20)
    .padding(.bottom, 16)
  }
}
