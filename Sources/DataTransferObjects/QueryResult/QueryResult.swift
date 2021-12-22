import Foundation

public enum QueryResult: Codable, Hashable, Equatable {
    case timeSeries(TimeSeriesQueryResult)
    case groupBy(GroupByQueryResult)

    enum CodingKeys: String, CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let type = try values.decode(String.self, forKey: .type)

        switch type {
        case "timeSeriesResult":
            self = .timeSeries(try TimeSeriesQueryResult(from: decoder))
        case "groupByResult":
            self = .groupBy(try GroupByQueryResult(from: decoder))
        default:
            throw EncodingError.invalidValue("Invalid type", .init(codingPath: [CodingKeys.type], debugDescription: "Invalid Type", underlyingError: nil))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .timeSeries(let timeSeries):
            try container.encode("timeSeriesResult", forKey: .type)
            try timeSeries.encode(to: encoder)
        case .groupBy(let columnComparison):
            try container.encode("groupByResult", forKey: .type)
            try columnComparison.encode(to: encoder)
        }
    }
}

public struct TimeSeriesQueryResult: Codable, Hashable, Equatable {
    public init(rows: [TimeSeriesQueryResultRow]) {
        self.rows = rows
    }
    
    public let rows: [TimeSeriesQueryResultRow]
}

/// Time series queries return an array of JSON objects, where each object represents a value as described in the time-series query.
/// For instance, the daily average of a dimension for the last one month.
public struct TimeSeriesQueryResultRow: Codable, Hashable, Equatable {
    public init(timestamp: Date, result: [String: Double]) {
        self.timestamp = timestamp
        self.result = result
    }

    public let timestamp: Date
    public let result: [String: Double]
}

/// GroupBy queries return an array of JSON objects, where each object represents a grouping as described in the group-by query.
/// For example, we can query for the daily average of a dimension for the past month grouped by another dimension.
public struct GroupByQueryResult: Codable, Hashable, Equatable {
    public init(timestamp: Date, result: [String: String]) {
        self.timestamp = timestamp
        self.result = result
    }

    public let timestamp: Date
    public let result: [String: String]
}

// MARK: - Legacy Structs

public enum LegacyDruidResultType: String, Codable {
    case timeSeries
}

public struct LegacyDruidResultWrapper: Codable {
    public let resultType: LegacyDruidResultType
    public let timeSeriesResults: [TimeSeriesQueryResultRow]

    public init(resultType: LegacyDruidResultType, timeSeriesResults: [TimeSeriesQueryResultRow]) {
        self.resultType = resultType
        self.timeSeriesResults = timeSeriesResults
    }
}
