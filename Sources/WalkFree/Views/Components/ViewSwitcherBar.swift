import SwiftUI

enum ViewType: String, CaseIterable {
  case list = "List"
  case map = "Map"
}

struct ViewSwitcherBar: View {
  @Binding var selectedView: ViewType

  var body: some View {
    VStack {
      Spacer()
      HStack {
        Spacer()
        HStack(spacing: 0) {
          ForEach(ViewType.allCases, id: \.self) { viewType in
            Button(action: {
              selectedView = viewType
            }) {
              Text(viewType.rawValue)
                .font(.system(size: 16, weight: selectedView == viewType ? .semibold : .regular))
                .foregroundColor(selectedView == viewType ? .white : .primary)
                .frame(width: 70, height: 36)
                .background(selectedView == viewType ? Color.blue : Color.clear)
                .cornerRadius(8)
            }
          }
        }
        .padding(4)
        .background(Color(.systemGray5))
        .cornerRadius(10)
        Spacer()
      }
      .padding(.bottom, 20)
    }
  }
}
