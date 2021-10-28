//
//  DruidNativeQuery.swift
//  DruidNativeQuery
//
//  Created by Charlotte Böhm on 25.08.21.
//

import Foundation

// MARK: - druid query types

public enum DruidQueryType: String, Codable {
    case timeseries
    case groupBy
}

/// Custom JSON based Druid query
///
/// @see https://druid.apache.org/docs/latest/querying/querying.html
public struct DruidCustomQuery: Codable, Hashable {
    public init(queryType: DruidQueryType, dataSource: String = "telemetry-signals", descending: Bool? = nil, filter: DruidFilter? = nil, intervals: [DruidInterval], granularity: druidGranularity, aggregations: [DruidAggregator]? = nil, limit: Int? = nil, context: DruidContext? = nil) {
        self.queryType = queryType
        self.dataSource = dataSource
        self.descending = descending
        self.filter = filter
        self.intervals = intervals
        self.granularity = granularity
        self.aggregations = aggregations
        self.limit = limit
        self.context = context
    }
    
    public var queryType: DruidQueryType
    public var dataSource: String = "telemetry-signals"
    public var descending: Bool? = nil
    public var filter: DruidFilter? = nil
    public var intervals: [DruidInterval]
    public let granularity: druidGranularity
    public var aggregations: [DruidAggregator]? = nil
    public var limit: Int? = nil
    public var context: DruidContext? = nil

    public func hash(into hasher: inout Hasher) {
        let jsonValue = try! JSONEncoder.druidEncoder.encode(self)
        hasher.combine(jsonValue)
    }

    public static func == (lhs: DruidCustomQuery, rhs: DruidCustomQuery) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

// MARK: - objects used in druid queries

// query filters

/// The selector filter will match a specific dimension with a specific value.
/// Selector filters can be used as the base filters for more complex Boolean
/// expressions of filters.
public struct DruidFilterSelector: Codable {
    public init(dimension: String, value: String) {
        self.dimension = dimension
        self.value = value
    }
    
    public let dimension: String
    public let value: String
}

/// The column comparison filter is similar to the selector filter, but instead
/// compares dimensions to each other.
public struct DruidFilterColumnComparison: Codable {
    public init(dimensions: [String]) {
        self.dimensions = dimensions
    }
    
    public let dimensions: [String]
}

/// The regular expression filter is similar to the selector filter, but using regular
/// expressions. It matches the specified dimension with the given pattern. The
/// pattern can be any standard Java regular expression.
///
/// @see http://docs.oracle.com/javase/6/docs/api/java/util/regex/Pattern.html
public struct DruidFilterRegex: Codable {
    public init(dimension: String, pattern: String) {
        self.dimension = dimension
        self.pattern = pattern
    }
    
    public let dimension: String
    public let pattern: String
}

// logical expression filters
public struct DruidFilterExpression: Codable {
    public init(fields: [DruidFilter]) {
        self.fields = fields
    }
    
    public let fields: [DruidFilter]
}

public struct DruidFilterNot: Codable {
    public init(field: DruidFilter) {
        self.field = field
    }
    
    public let field: DruidFilter
}

/// A filter is a JSON object indicating which rows of data should be included in the computation
/// for a query. It’s essentially the equivalent of the WHERE clause in SQL.
public indirect enum DruidFilter: Codable {
    /// The selector filter will match a specific dimension with a specific value.
    /// Selector filters can be used as the base filters for more complex Boolean
    /// expressions of filters.
    case selector(DruidFilterSelector)

    /// The column comparison filter is similar to the selector filter, but instead
    /// compares dimensions to each other.
    case columnComparison(DruidFilterColumnComparison)

    /// The regular expression filter is similar to the selector filter, but using regular
    /// expressions. It matches the specified dimension with the given pattern. The
    /// pattern can be any standard Java regular expression.
    case regex(DruidFilterRegex)

    // logical expression filters
    case and(DruidFilterExpression)
    case or(DruidFilterExpression)
    case not(DruidFilterNot)

    enum CodingKeys: String, CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let type = try values.decode(String.self, forKey: .type)

        switch type {
        case "selector":
            self = .selector(try DruidFilterSelector(from: decoder))
        case "columnComparison":
            self = .columnComparison(try DruidFilterColumnComparison(from: decoder))
        case "regex":
            self = .regex(try DruidFilterRegex(from: decoder))
        case "and":
            self = .and(try DruidFilterExpression(from: decoder))
        case "or":
            self = .or(try DruidFilterExpression(from: decoder))
        case "not":
            self = .not(try DruidFilterNot(from: decoder))
        default:
            throw EncodingError.invalidValue("Invalid type", .init(codingPath: [CodingKeys.type], debugDescription: "Invalid Type", underlyingError: nil))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .selector(let selector):
            try container.encode("selector", forKey: .type)
            try selector.encode(to: encoder)
        case .columnComparison(let columnComparison):
            try container.encode("columnComparison", forKey: .type)
            try columnComparison.encode(to: encoder)
        case .regex(let regex):
            try container.encode("regex", forKey: .type)
            try regex.encode(to: encoder)
        case .and(let and):
            try container.encode("and", forKey: .type)
            try and.encode(to: encoder)
        case .or(let or):
            try container.encode("or", forKey: .type)
            try or.encode(to: encoder)
        case .not(let not):
            try container.encode("not", forKey: .type)
            try not.encode(to: encoder)
        }
    }
}

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

public struct DruidAggregator: Codable, Hashable {
    public init(type: DruidAggregatorType, name: String, fieldName: String? = nil) {
        self.type = type
        self.name = name
        self.fieldName = fieldName
    }
    
    public let type: DruidAggregatorType
    public let name: String
    public var fieldName: String? = nil // should be nil for type count, maybe that should be enforced in code?
}

public enum DruidAggregatorType: String, Codable, Hashable {
    case count

    case longSum
    case doubleSum
    case floatSum

    case doubleMin
    case doubleMax
    case floatMin
    case floatMax
    case longMin
    case longMax

    case doubleMean

    case doubleFirst
    case doubleLast
    case floatFirst
    case floatLast
    case longFirst
    case longLast
    case stringFirst
    case stringLast

    case doubleAny
    case floatAny
    case longAny
    case stringAny

    case thetaSketch

    // JavaScript aggregator missing
}

public enum druidGranularity: String, Codable, Hashable {
    case all
    case none
    case second
    case minute
    case fifteen_minute
    case thirty_minute
    case hour
    case day
    case week
    case month
    case quarter
    case year
}

public struct DruidContext: Codable, Hashable {
    /// Query timeout in millis, beyond which unfinished queries will be cancelled. 0 timeout means no timeout.
    public var timeout: String? = nil

    /// Query Priority. Queries with higher priority get precedence for computational resources. Default: 0
    public var priority: Int? = nil

    public var timestampResultField: String? = nil

    // topN specific context
    public var minTopNThreshold: Int? = nil
    // time series specific contexts
    public var grandTotal: Bool? = nil
    public var skipEmptyBuckets: Bool? = nil

    public init(timeout: String? = nil, priority: Int? = nil, timestampResultField: String? = nil, minTopNThreshold: Int? = nil, grandTotal: Bool? = nil, skipEmptyBuckets: Bool? = nil) {
        self.timeout = timeout
        self.priority = priority
        self.timestampResultField = timestampResultField
        self.minTopNThreshold = minTopNThreshold
        self.grandTotal = grandTotal
        self.skipEmptyBuckets = skipEmptyBuckets
    }
}

public struct DruidTimeSeriesResult: Codable {
    public init(timestamp: Date, result: [String : Double]) {
        self.timestamp = timestamp
        self.result = result
    }
    
    public let timestamp: Date
    public let result: [String: Double]
}

public enum DruidResultType: String, Codable {
    case timeSeries
}

public struct DruidResultWrapper: Codable {
    public let resultType: DruidResultType
    public let timeSeriesResults: [DruidTimeSeriesResult]

    public init(resultType: DruidResultType, timeSeriesResults: [DruidTimeSeriesResult]) {
        self.resultType = resultType
        self.timeSeriesResults = timeSeriesResults
    }
}
