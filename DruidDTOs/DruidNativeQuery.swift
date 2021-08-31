//
//  DruidNativeQuery.swift
//  DruidNativeQuery
//
//  Created by Charlotte Böhm on 25.08.21.
//

import Foundation

// MARK: - druid query types

struct DruidNativeTimeseries: Encodable, Hashable {
    let queryType: String = "timeseries"
    let dataSource: String = "telemetry-signals-tagged" // might change later if we have multiple datasources
    var descending: Bool? = nil
    let intervals: [DruidInterval] // not really? or needs special encoding
    let granularity: druidGranularity
    var aggregations: [DruidAggregator]? = nil
    var limit: Int? = nil
    var context: DruidContext? = nil
}

// MARK: - objects used in druid queries

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
    case count = "count"
    
    case longSum = "longSum"
    case doubleSum = "doubleSum"
    case floatSum = "floatSum"
    
    case doubleMin = "doubleMin"
    case doubleMax = "doubleMax"
    case floatMin = "floatMin"
    case floatMax = "floatMax"
    case longMin = "longMin"
    case longMax = "longMax"
    
    case doubleMean = "doubleMean"
    
    case doubleFirst = "doubleFirst"
    case doubleLast = "doubleLast"
    case floatFirst = "floatFirst"
    case floatLast = "floatLast"
    case longFirst = "longFirst"
    case longLast = "longLast"
    case stringFirst = "stringFirst"
    case stringLast = "stringLast"
    
    case doubleAny = "doubleAny"
    case floatAny = "floatAny"
    case longAny = "longAny"
    case stringAny = "stringAny"
    
    // JavaScript aggregator missing
}

enum druidGranularity: String, Codable, Hashable {
    case all = "all"
    case none = "none"
    case second = "second"
    case minute = "minute"
    case fifteen_minute = "fifteen_minute"
    case thirty_minute = "thirty_minute"
    case hour = "hour"
    case day = "day"
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    case year = "year"
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
