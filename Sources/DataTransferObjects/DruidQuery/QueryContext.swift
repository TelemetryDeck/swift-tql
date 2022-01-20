import Foundation

public struct QueryContext: Codable, Hashable {
    /// Query timeout in millis, beyond which unfinished queries will be cancelled. 0 timeout means no timeout.
    public var timeout: String? = nil

    /// Query Priority. Queries with higher priority get precedence for computational resources. Default: 0
    public var priority: Int? = nil

    public var timestampResultField: String? = "d0"

    // topN specific context
    public var minTopNThreshold: Int? = nil
    // time series specific contexts
    
    /// Druid can include an extra "grand totals" row as the last row of a timeseries result set. To enable this, add "grandTotal" : true to your query context. For example:
    public var grandTotal: Bool? = nil
    
    /// Timeseries queries normally fill empty interior time buckets with zeroes.
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
