import SwiftUI

struct CitySelectorButton: View {
  let cityName: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack {
        Image(systemName: "mappin.circle.fill")
          .foregroundColor(.blue)
          .font(.system(size: 20))

        Text(cityName)
          .font(.system(size: 18, weight: .semibold))
          .foregroundColor(.primary)

        Spacer()

        Image(systemName: "chevron.down")
          .foregroundColor(.gray)
          .font(.system(size: 14, weight: .medium))
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 12)
      .background(Color(.systemGray6))
      .cornerRadius(10)
    }
    .padding(.horizontal, 20)
    .padding(.top, 16)
    .padding(.bottom, 16)
  }
}
