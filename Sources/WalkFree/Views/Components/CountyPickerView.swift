import SwiftUI

struct CountyPickerView: View {
  let uniqueCounties: [String]
  @Binding var selectedCounty: String?

  var body: some View {
    HStack {
      Text("County:")
        .font(.system(size: 16))
        .foregroundColor(.secondary)

      Picker("County", selection: $selectedCounty) {
        Text("All").tag(String?.none)
        ForEach(uniqueCounties, id: \.self) { county in
          Text(county).tag(String?.some(county))
        }
      }
      .pickerStyle(.menu)
    }
    .padding(.horizontal, 20)
    .padding(.bottom, 16)
  }
}
