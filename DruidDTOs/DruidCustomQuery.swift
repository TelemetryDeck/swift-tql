//
//  DruidNativeQuery.swift
//  DruidNativeQuery
//
//  Created by Charlotte Böhm on 25.08.21.
//

import Foundation

// MARK: - druid query types

enum DruidQueryType: String, Codable {
    case timeseries
    case groupBy
}

/// Custom JSON based Druid query
///
/// @see https://druid.apache.org/docs/latest/querying/querying.html
struct DruidCustomQuery: Codable, Hashable {
    var queryType: DruidQueryType
    var dataSource: String = "telemetry-signals"
    var descending: Bool? = nil
    var filter: DruidFilter? = nil
    var intervals: [DruidInterval]
    let granularity: druidGranularity
    var aggregations: [DruidAggregator]? = nil
    var limit: Int? = nil
    var context: DruidContext? = nil

    func hash(into hasher: inout Hasher) {
        let jsonValue = try! JSONEncoder.druidEncoder.encode(self)
        hasher.combine(jsonValue)
    }

    static func == (lhs: DruidCustomQuery, rhs: DruidCustomQuery) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

// MARK: - objects used in druid queries

// query filters

/// The selector filter will match a specific dimension with a specific value.
/// Selector filters can be used as the base filters for more complex Boolean
/// expressions of filters.
struct DruidFilterSelector: Codable {
    let dimension: String
    let value: String
}

/// The column comparison filter is similar to the selector filter, but instead
/// compares dimensions to each other.
struct DruidFilterColumnComparison: Codable {
    let dimensions: [String]
}

/// The regular expression filter is similar to the selector filter, but using regular
/// expressions. It matches the specified dimension with the given pattern. The
/// pattern can be any standard Java regular expression.
///
/// @see http://docs.oracle.com/javase/6/docs/api/java/util/regex/Pattern.html
struct DruidFilterRegex: Codable {
    let dimension: String
    let pattern: String
}

// logical expression filters
struct DruidFilterExpression: Codable {
    let fields: [DruidFilter]
}

struct DruidFilterNot: Codable {
    let field: DruidFilter
}

/// A filter is a JSON object indicating which rows of data should be included in the computation
/// for a query. It’s essentially the equivalent of the WHERE clause in SQL.
indirect enum DruidFilter: Codable {
    
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

    #warning("TODO: This is untested and I just added it so it compiles. Needs some tests.")
    init(from decoder: Decoder) throws {
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
            #warning("This should throw an exception instead. Fatalerror will actually crash the whole server process, which is not very cool.")
            fatalError()
        }
    }

    func encode(to encoder: Encoder) throws {
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

struct DruidInterval: Codable, Hashable {
    let beginningDate: Date
    let endDate: Date

    static var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        let date1 = Self.dateFormatter.string(from: beginningDate)
        let date2 = Self.dateFormatter.string(from: endDate)

        try container.encode(date1 + "/" + date2)
    }

    init(from decoder: Decoder) throws {
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
    
    init(beginningDate: Date, endDate: Date) {
        self.beginningDate = beginningDate
        self.endDate = endDate
    }
}

struct DruidAggregator: Codable, Hashable {
    let type: druidAggregatorType
    let name: String
    var fieldName: String? = nil // should be nil for type count, maybe that should be enforced in code?
}

enum druidAggregatorType: String, Codable, Hashable {
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

enum druidGranularity: String, Codable, Hashable {
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

struct DruidContext: Codable, Hashable {
    var timeout: String? = nil
    var priority: Int? = nil
    var timestampResultField: String? = nil
    /// there are a lot of other possible entries? I don't know if we need all? maybe this should just be [String:String]

    // topN specific context
    var minTopNThreshold: Int? = nil
    // time series specific contexts
    var grandTotal: Bool? = nil
    var skipEmptyBuckets: Bool? = nil
}

struct DruidTimeSeriesResult: Codable {
    let timestamp: Date
    let result: [String: Double]
}

// MARK: - Vapor Extensions

#if canImport(Vapor)
import Vapor

extension DruidCustomQuery: Content {}
extension DruidInterval: Content {}
extension DruidAggregator: Content {}
extension druidAggregatorType: Content {}
extension DruidContext: Content {}
extension DruidTimeSeriesResult: Content {}
#endif
