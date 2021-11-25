import Foundation

public struct DruidInterval: Codable, Hashable {
    public let beginningDate: Date
    public let endDate: Date

    static var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        let date1 = Self.dateFormatter.string(from: beginningDate)
        let date2 = Self.dateFormatter.string(from: endDate)

        try container.encode(date1 + "/" + date2)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let intervalString = try container.decode(String.self)

        let intervalArray = intervalString.split(separator: "/").map { String($0) }

        guard let beginningString = intervalArray.first,
              let endString = intervalArray.last,
              let beginningDate = Self.dateFormatter.date(from: beginningString),
              let endDate = Self.dateFormatter.date(from: endString)
        else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: [],
                debugDescription: "Could not find two dates!",
                underlyingError: nil
            ))
        }

        self.beginningDate = beginningDate
        self.endDate = endDate
    }

    public init(beginningDate: Date, endDate: Date) {
        self.beginningDate = beginningDate
        self.endDate = endDate
    }
}
