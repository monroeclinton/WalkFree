import SwiftUI

struct TabPickerView: View {
  @Binding var selectedTab: Int

  var body: some View {
    Picker("View", selection: $selectedTab) {
      Text("Incomplete").tag(0)
      Text("Complete").tag(1)
    }
    .pickerStyle(.segmented)
    .padding(.horizontal, 20)
    .padding(.bottom, 16)
  }
}
