import Foundation

/// Segment metadata queries return per-segment information about the queried data source.
///
/// Each row is a ``SegmentAnalysis`` describing one segment (or, when `merge` is enabled, a single merged result),
/// including the number of rows, the interval covered, the estimated byte size, the segment id, the rollup status,
/// and detailed per-column information.
///
/// https://druid.apache.org/docs/latest/querying/segmentmetadataquery
public struct SegmentMetadataQueryResult: Codable, Hashable, Equatable, Sendable {
    public init(rows: [SegmentAnalysis], restrictions: [QueryTimeInterval]? = nil) {
        self.restrictions = restrictions
        self.rows = rows
    }

    public let restrictions: [QueryTimeInterval]?
    public let rows: [SegmentAnalysis]
}

/// Per-segment information returned by a segmentMetadata query.
///
/// https://druid.apache.org/docs/latest/querying/segmentmetadataquery
public struct SegmentAnalysis: Codable, Hashable, Equatable, Sendable {
    public init(
        id: String,
        intervals: [QueryTimeInterval]? = nil,
        columns: [String: ColumnAnalysis],
        size: Int? = nil,
        numRows: Int? = nil,
        aggregators: [String: Aggregator]? = nil,
        timestampSpec: TimestampSpec? = nil,
        queryGranularity: QueryGranularity? = nil,
        rollup: Bool? = nil
    ) {
        self.id = id
        self.intervals = intervals
        self.columns = columns
        self.size = size
        self.numRows = numRows
        self.aggregators = aggregators
        self.timestampSpec = timestampSpec
        self.queryGranularity = queryGranularity
        self.rollup = rollup
    }

    /// The segment identifier.
    public let id: String

    /// The list of intervals associated with the queried segments. Present when the `interval` analysis type is enabled.
    public let intervals: [QueryTimeInterval]?

    /// Detailed per-column information, keyed by column name.
    public let columns: [String: ColumnAnalysis]

    /// The estimated total byte size as if the data were stored in a flat format. Present when the `size` analysis type is enabled.
    public let size: Int?

    /// The number of rows stored inside the segment.
    public let numRows: Int?

    /// The list of aggregators usable for querying metric columns, keyed by column name. Present when the `aggregators`
    /// analysis type is enabled. May be null if aggregators are unknown or unmergeable.
    public let aggregators: [String: Aggregator]?

    /// The timestampSpec of data stored in segments. Present when the `timestampSpec` analysis type is enabled. Can be
    /// null if the timestampSpec of segments was unknown or unmergeable.
    public let timestampSpec: TimestampSpec?

    /// The query granularity of data stored in segments. Present when the `queryGranularity` analysis type is enabled.
    /// Can be null if the query granularity of segments was unknown or unmergeable.
    public let queryGranularity: QueryGranularity?

    /// Whether the segment is rolled up. Present when the `rollup` analysis type is enabled. When merging is enabled,
    /// if some segments are rolled up and others are not, this is null.
    public let rollup: Bool?
}

/// Detailed information about a single column returned by a segmentMetadata query.
///
/// https://druid.apache.org/docs/latest/querying/segmentmetadataquery
public struct ColumnAnalysis: Codable, Hashable, Equatable, Sendable {
    public init(
        type: String,
        typeSignature: String? = nil,
        hasMultipleValues: Bool? = nil,
        hasNulls: Bool? = nil,
        size: Int,
        cardinality: Int? = nil,
        minValue: String? = nil,
        maxValue: String? = nil,
        errorMessage: String? = nil
    ) {
        self.type = type
        self.typeSignature = typeSignature
        self.hasMultipleValues = hasMultipleValues
        self.hasNulls = hasNulls
        self.size = size
        self.cardinality = cardinality
        self.minValue = minValue
        self.maxValue = maxValue
        self.errorMessage = errorMessage
    }

    /// The column type. One of `STRING`, `FLOAT`, `DOUBLE`, `LONG`, or `COMPLEX<typeName>`.
    public let type: String

    /// The internal type signature Druid uses to represent the column type.
    public let typeSignature: String?

    /// Whether the column contains multiple values in any row.
    public let hasMultipleValues: Bool?

    /// Whether the column contains any null values.
    public let hasNulls: Bool?

    /// The estimated byte size of the column as if it were stored in a flat format.
    public let size: Int

    /// The number of unique values in the column. Only dictionary-encoded (i.e. `STRING`) columns have a cardinality;
    /// for all other column types this is null.
    public let cardinality: Int?

    /// The estimated minimum value of the column. Only reported for string columns when the `minmax` analysis type is enabled.
    public let minValue: String?

    /// The estimated maximum value of the column. Only reported for string columns when the `minmax` analysis type is enabled.
    public let maxValue: String?

    /// If non-null, you should not trust the other fields in this column analysis.
    public let errorMessage: String?
}
