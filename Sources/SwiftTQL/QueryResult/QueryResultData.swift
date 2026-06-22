import Foundation
import Tracing

/// Carries the raw, undecoded response data returned from Druid for a query, along with the
/// metadata needed to decode it into a ``QueryResult`` on demand.
///
/// Decoding large Druid responses into ``QueryResult`` is expensive (see the hot-path
/// optimizations in `AdaptableQueryResultItem`). By passing `QueryResultData` around instead of an
/// eagerly-decoded ``QueryResult``, callers that only need to forward the raw bytes — for example
/// to a cache or another service — avoid the decode/re-encode round trip entirely, and only pay
/// the decoding cost when they actually need the structured result.
public struct QueryResultData: Sendable, Equatable, Hashable {
    /// The raw response body bytes returned by Druid.
    public let data: Data

    /// The type of query that produced this data. Determines how ``data`` is decoded.
    public let queryType: CustomQuery.QueryType

    /// Time restrictions carried over from the originating query, attached to the decoded result.
    public let restrictions: [QueryTimeInterval]?

    public init(data: Data, queryType: CustomQuery.QueryType, restrictions: [QueryTimeInterval]? = nil) {
        self.data = data
        self.queryType = queryType
        self.restrictions = restrictions
    }

    /// Decode the raw ``data`` into a structured ``QueryResult``.
    ///
    /// This performs the actual JSON decoding, which can be expensive for large result sets, so it
    /// is marked `async` to make the cost explicit and to leave room to offload the work later
    /// without an API change.
    public func decode() async throws -> QueryResult {
        try withSpan("QueryResultData.decode") { span in
            // Query/config payload + Druid request details available at this stage. Identity/context
            // (user/org/app) isn't carried on QueryResultData, so it can't be attached here.
            span.attributes["tql.query.type"] = queryType.rawValue
            span.attributes["tql.query.restriction_count"] = restrictions?.count ?? 0
            span.attributes["tql.result.payload_bytes"] = data.count

            let decoder = JSONDecoder.telemetryDecoder

            switch queryType {
            case .timeseries:
                let rows = try decoder.decode([TimeSeriesQueryResultRow].self, from: data)
                span.attributes["tql.result.row_count"] = rows.count
                return .timeSeries(TimeSeriesQueryResult(rows: rows, restrictions: restrictions))

            case .groupBy:
                let rows = try decoder.decode([GroupByQueryResultRow].self, from: data)
                span.attributes["tql.result.row_count"] = rows.count
                return .groupBy(GroupByQueryResult(rows: rows, restrictions: restrictions))

            case .topN:
                var rows = try decoder.decode([TopNQueryResultRow].self, from: data)
                // This fixes a druid bug where query results sometimes contain a row with a timestamp of 1970-01-01
                // Possible fix is https://github.com/apache/druid/pull/16915
                let minimumValidTimestamp = Date(iso8601String: "2020-01-01T00:00:00.000Z")!
                rows = rows.filter { ($0.timestamp > minimumValidTimestamp) || (!$0.result.isEmpty) }
                span.attributes["tql.result.row_count"] = rows.count
                return .topN(TopNQueryResult(rows: rows, restrictions: restrictions))

            case .scan:
                let rows = try decoder.decode([ScanQueryResultRow].self, from: data)
                span.attributes["tql.result.row_count"] = rows.count
                return .scan(ScanQueryResult(rows: rows))

            case .timeBoundary:
                let rows = try decoder.decode([TimeBoundaryResultRow].self, from: data)
                span.attributes["tql.result.row_count"] = rows.count
                return .timeBoundary(TimeBoundaryResult(rows: rows))

            default:
                throw QueryResultDataError.unsupportedQueryType(queryType)
            }
        }
    }
}

/// Errors thrown while decoding ``QueryResultData``.
public enum QueryResultDataError: Error, Equatable {
    /// The query type carried by the data has no associated result representation.
    case unsupportedQueryType(CustomQuery.QueryType)
}
