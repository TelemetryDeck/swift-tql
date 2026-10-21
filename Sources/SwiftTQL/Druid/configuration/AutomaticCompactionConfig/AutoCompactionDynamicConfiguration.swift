/// Defines Automatic Compaction settings for a data source
public struct AutoCompactionDynamicConfig: Codable, Hashable, Equatable, Sendable {
    public init(
        dataSource: String,
        taskPriority: Int?,
        inputSegmentSizeBytes: Int?,
        skipOffsetFromLatest: String?,
        tuningConfig: TuningConfig?,
        granularitySpec: GranularitySpec?,
        maxRowsPerSegment: Int?,
        ioConfig: CompactionIOConfig? = nil
    ) {
        self.dataSource = dataSource
        self.taskPriority = taskPriority
        self.inputSegmentSizeBytes = inputSegmentSizeBytes
        self.skipOffsetFromLatest = skipOffsetFromLatest
        self.tuningConfig = tuningConfig
        self.granularitySpec = granularitySpec
        self.maxRowsPerSegment = maxRowsPerSegment
        self.ioConfig = ioConfig
    }

    /// The datasource name to be compacted.
    public let dataSource: String

    /// Priority of compaction task (Defaults to 25)
    public let taskPriority: Int?

    /// Maximum number of total segment bytes processed per compaction task.
    ///
    /// Since a time chunk must be processed in its entirety, if the segments for a particular time chunk have a total size in bytes greater than this parameter, compaction will not run for that time chunk. (default = 100,000,000,000,000 i.e. 100TB)
    public let inputSegmentSizeBytes: Int?

    /// The offset for searching segments to be compacted in ISO 8601 duration format. Strongly recommended to set for realtime datasources. See Data handling with compaction. (default = "P1D")
    public let skipOffsetFromLatest: String?

    /// Tuning config for compaction tasks.
    public let tuningConfig: TuningConfig?

    // not implemented:
    // public let taskContext: TaskContext?

    /// Custom granularitySpec.
    public let granularitySpec: GranularitySpec?

    // not implemented:
    // public let dimensionsSpec: DimensionsSpec?

    // not implemented:
    // public let transformSpec: TransformSpec?

    // not implemented:
    // public let metricsSpec: MetricsSpec?

    /// IO config for compaction tasks.
    public let ioConfig: CompactionIOConfig?

    // undocumented
    public let maxRowsPerSegment: Int?
}

/// IO config for automatic compaction tasks
///
/// https://druid.apache.org/docs/latest/data-management/automatic-compaction/#compaction-io-configuration
public struct CompactionIOConfig: Codable, Hashable, Equatable, Sendable {
    public init(dropExisting: Bool? = nil) {
        self.dropExisting = dropExisting
    }

    /// Always "compact".
    public var type: String { "compact" }

    /// If true, compaction tasks mark all existing segments fully contained by the compacted interval as unused, even
    /// if the compacted segments don't cover them (e.g. a YEAR segment being recompacted into MONTH segments).
    /// (default = false)
    public let dropExisting: Bool?

    enum CodingKeys: String, CodingKey {
        case type
        case dropExisting
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dropExisting = try container.decodeIfPresent(Bool.self, forKey: .dropExisting)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(dropExisting, forKey: .dropExisting)
    }
}
