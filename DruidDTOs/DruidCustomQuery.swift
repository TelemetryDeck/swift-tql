//
//  DruidNativeQuery.swift
//  DruidNativeQuery
//
//  Created by Charlotte Böhm on 25.08.21.
//

import Foundation

// MARK: - druid query types

struct DruidCustomQuery: Codable, Hashable {
    var queryType: String = "timeseries"
    var dataSource: String = "telemetry-signals"
    var descending: Bool? = nil
    var filter: druidFilter? = nil
    var intervals: [DruidInterval]
    let granularity: druidGranularity
    var aggregations: [DruidAggregator]? = nil
    var limit: Int? = nil
    var context: DruidContext? = nil

    func hash(into hasher: inout Hasher) {
        hasher.combine(queryType)
        hasher.combine(dataSource)
        hasher.combine(descending)

        // TODO: add filters, intervals, etc to hasher
    }

    static func == (lhs: DruidCustomQuery, rhs: DruidCustomQuery) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

// MARK: - objects used in druid queries

// query filters

struct DruidFilterSelector: Codable {
    let dimension: String
    let value: String
}

struct DruidFilterColumnComparison: Codable {
    let dimensions: [String]
}

struct DruidFilterRegex: Codable {
    let dimension: String
    let pattern: String
}

// logical expression filters
struct DruidFilterExpression: Codable {
    let fields: [druidFilter]
}

struct DruidFilterNot: Codable {
    let field: druidFilter
}

indirect enum druidFilter: Codable {
    case selector(DruidFilterSelector)
    case columnComparison(DruidFilterColumnComparison)
    case regex(DruidFilterRegex)
    // logical expression filters
    case and(DruidFilterExpression)
    case or(DruidFilterExpression)
    case not(DruidFilterNot)

    enum CodingKeys: String, CodingKey {
        case type
    }

    // TODO: This is untested and I just added it so it compiles. Needs some tests.
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
    // timeseries specific contexts
    var grandTotal: Bool? = nil
    var skipEmptyBuckets: Bool? = nil
}

// MARK: - Vapor Extensions

#if canImport(Vapor)
import Vapor

extension DruidCustomQuery: Content {}
extension DruidInterval: Content {}
extension DruidAggregator: Content {}
extension druidAggregatorType: Content {}
extension DruidContext: Content {}
#endif
