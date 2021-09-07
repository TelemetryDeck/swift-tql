//
//  DruidNativeQuery.swift
//  DruidNativeQuery
//
//  Created by Charlotte Böhm on 25.08.21.
//

import Foundation

// MARK: - druid query types

struct DruidNativeTimeseries: Encodable {
    let queryType: String = "timeseries"
    let dataSource: String = "telemetry-signals-tagged" // might change later if we have multiple datasources
    var descending: Bool? = nil
    var filter: druidFilter? = nil
    let intervals: [DruidInterval] // not really? or needs special encoding
    let granularity: druidGranularity
    var aggregations: [DruidAggregator]? = nil
    var limit: Int? = nil
    var context: DruidContext? = nil
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
struct DruidFilterExpression: Encodable {
    let fields: [druidFilter]
}

struct DruidFilterNot: Encodable {
    let field: druidFilter
}

indirect enum druidFilter: Encodable {
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

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        let date1 = dateFormatter.string(from: self.beginningDate)
        let date2 = dateFormatter.string(from: self.endDate)

        try container.encode(date1 + "/" + date2)
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

extension DruidNativeTimeseries: Content {}
extension DruidInterval: Content {}
extension DruidAggregator: Content {}
extension druidAggregatorType: Content {}
extension DruidContext: Content {}
#endif
