//
//  DruidNativeQuery.swift
//  DruidNativeQuery
//
//  Created by Charlotte Böhm on 25.08.21.
//

import Foundation

/// Custom JSON based Druid query
///
/// @see https://druid.apache.org/docs/latest/querying/querying.html
public struct DruidCustomQuery: Codable, Hashable, Equatable {
    public init(queryType: DruidCustomQuery.QueryType, dataSource: String = "telemetry-signals", descending: Bool? = nil, filter: DruidFilter? = nil, intervals: [DruidInterval], granularity: DruidCustomQuery.Granularity, aggregations: [DruidAggregator]? = nil, limit: Int? = nil, context: DruidContext? = nil, threshold: Int? = nil, metric: TopNMetricSpec? = nil, dimension: DimensionSpec? = nil, dimensions: [DimensionSpec]? = nil) {
        self.queryType = queryType
        self.dataSource = dataSource
        self.descending = descending
        self.filter = filter
        self.intervals = intervals
        self.granularity = granularity
        self.aggregations = aggregations
        self.limit = limit
        self.context = context
        self.threshold = threshold
        self.metric = metric
        self.dimension = dimension
        self.dimensions = dimensions
    }

    public enum QueryType: String, Codable {
        case timeseries
        case groupBy
        case topN
    }

    public enum Granularity: String, Codable, Hashable {
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

    public var queryType: QueryType
    public var dataSource: String = "telemetry-signals"
    public var descending: Bool? = nil
    public var filter: DruidFilter? = nil
    public var intervals: [DruidInterval]
    public let granularity: Granularity
    public var aggregations: [DruidAggregator]? = nil
    public var limit: Int? = nil
    public var context: DruidContext? = nil
    
    /// Only for topN Queries: An integer defining the N in the topN (i.e. how many results you want in the top list)
    public var threshold: Int? = nil
    
    /// Only for topN Queries: A DimensionSpec defining the dimension that you want the top taken for
    public var dimension: DimensionSpec?
    
    /// Only for topN Queries: Specifying the metric to sort by for the top list
    public var metric: TopNMetricSpec?

    /// Only for groupBy Queries: A list of dimensions to do the groupBy over, if queryType is groupBy
    public var dimensions: [DimensionSpec]?

    public func hash(into hasher: inout Hasher) {
        hasher.combine(queryType)
        hasher.combine(dataSource)
        hasher.combine(descending)
        hasher.combine(filter)
        hasher.combine(intervals)
        hasher.combine(granularity)
        hasher.combine(aggregations)
        hasher.combine(limit)
        hasher.combine(context)
        hasher.combine(threshold)
        hasher.combine(metric)
        hasher.combine(dimensions)
        hasher.combine(dimension)
    }

    public static func == (lhs: DruidCustomQuery, rhs: DruidCustomQuery) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
