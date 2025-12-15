import Foundation

struct StreetData {
  let id: String
  let name: String
  let country: String?
  let state: String?
  let city: String?
  let county: String?
  let segments: [Segment]
}

struct JSONParser {
  static func parseStreets(from url: URL) -> [StreetData] {
    guard let data = try? Data(contentsOf: url) else {
      return []
    }

    guard let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
      return []
    }

    var streets: [StreetData] = []

    for street in json {
      if street["name"] == nil || street["id"] == nil {
        continue
      }

      var segments: [Segment] = []

      if let segmentsArray = street["segments"] as? [[String: Any]] {
        segments = segmentsArray.compactMap { segmentDict -> Segment? in
          guard let segmentId = segmentDict["id"] as? String else { return nil }

          var coordinates: [Coordinate] = []
          if let coordsArray = segmentDict["coordinates"] as? [[Double]] {
            coordinates = coordsArray.compactMap { coord -> Coordinate? in
              guard coord.count >= 2 else { return nil }
              return Coordinate(longitude: coord[0], latitude: coord[1])
            }
          }

          return Segment(id: segmentId, coordinates: coordinates)
        }
      }

      streets.append(
        StreetData(
          id: street["id"] as! String,
          name: street["name"] as! String,
          country: street["country"] as? String,
          state: street["state"] as? String,
          city: street["city"] as? String,
          county: street["county"] as? String,
          segments: segments
        ))
    }

    return streets
  }
}
