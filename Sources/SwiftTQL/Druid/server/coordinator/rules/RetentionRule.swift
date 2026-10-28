import Foundation

/// A Druid retention rule (load or drop rule).
///
/// The Coordinator evaluates a datasource's rules top to bottom and applies the first rule that matches a segment.
/// Segments that match a drop rule are marked unused; a kill task can then delete them from deep storage. When no
/// datasource rule matches, the cluster default rules (`_default`) apply.
///
/// `period` values are ISO 8601 periods such as `"P3M"`.
///
/// https://druid.apache.org/docs/latest/operations/rule-configuration
public enum RetentionRule: Codable, Hashable, Equatable, Sendable {
    /// Keep all segments loaded.
    case loadForever(tieredReplicants: [String: Int]? = nil, useDefaultTierForNull: Bool? = nil)

    /// Keep segments that overlap `interval` loaded.
    case loadByInterval(interval: QueryTimeInterval, tieredReplicants: [String: Int]? = nil, useDefaultTierForNull: Bool? = nil)

    /// Keep segments from the last `period` loaded. With `includeFuture` (Druid's default), segments that start after
    /// now match as well.
    case loadByPeriod(
        period: String,
        includeFuture: Bool? = nil,
        tieredReplicants: [String: Int]? = nil,
        useDefaultTierForNull: Bool? = nil
    )

    /// Drop all segments.
    case dropForever

    /// Drop segments contained in `interval`.
    case dropByInterval(interval: QueryTimeInterval)

    /// Drop segments from the last `period`. With `includeFuture` (Druid's default), segments that start after now
    /// match as well.
    case dropByPeriod(period: String, includeFuture: Bool? = nil)

    /// Drop segments that end before now minus `period`. Pair it with a load rule above, e.g.
    /// `[.loadByPeriod(period: "P1Y"), .dropBeforeByPeriod(period: "P1Y")]` to retain one year of data.
    case dropBeforeByPeriod(period: String)

    enum RuleType: String, Codable {
        case loadForever
        case loadByInterval
        case loadByPeriod
        case dropForever
        case dropByInterval
        case dropByPeriod
        case dropBeforeByPeriod
    }

    enum CodingKeys: String, CodingKey {
        case type
        case interval
        case period
        case includeFuture
        case tieredReplicants
        case useDefaultTierForNull
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(RuleType.self, forKey: .type)

        switch type {
        case .loadForever:
            self = try .loadForever(
                tieredReplicants: container.decodeIfPresent([String: Int].self, forKey: .tieredReplicants),
                useDefaultTierForNull: container.decodeIfPresent(Bool.self, forKey: .useDefaultTierForNull)
            )
        case .loadByInterval:
            self = try .loadByInterval(
                interval: container.decode(QueryTimeInterval.self, forKey: .interval),
                tieredReplicants: container.decodeIfPresent([String: Int].self, forKey: .tieredReplicants),
                useDefaultTierForNull: container.decodeIfPresent(Bool.self, forKey: .useDefaultTierForNull)
            )
        case .loadByPeriod:
            self = try .loadByPeriod(
                period: container.decode(String.self, forKey: .period),
                includeFuture: container.decodeIfPresent(Bool.self, forKey: .includeFuture),
                tieredReplicants: container.decodeIfPresent([String: Int].self, forKey: .tieredReplicants),
                useDefaultTierForNull: container.decodeIfPresent(Bool.self, forKey: .useDefaultTierForNull)
            )
        case .dropForever:
            self = .dropForever
        case .dropByInterval:
            self = try .dropByInterval(interval: container.decode(QueryTimeInterval.self, forKey: .interval))
        case .dropByPeriod:
            self = try .dropByPeriod(
                period: container.decode(String.self, forKey: .period),
                includeFuture: container.decodeIfPresent(Bool.self, forKey: .includeFuture)
            )
        case .dropBeforeByPeriod:
            self = try .dropBeforeByPeriod(period: container.decode(String.self, forKey: .period))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .loadForever(tieredReplicants, useDefaultTierForNull):
            try container.encode(RuleType.loadForever, forKey: .type)
            try container.encodeIfPresent(tieredReplicants, forKey: .tieredReplicants)
            try container.encodeIfPresent(useDefaultTierForNull, forKey: .useDefaultTierForNull)
        case let .loadByInterval(interval, tieredReplicants, useDefaultTierForNull):
            try container.encode(RuleType.loadByInterval, forKey: .type)
            try container.encode(interval, forKey: .interval)
            try container.encodeIfPresent(tieredReplicants, forKey: .tieredReplicants)
            try container.encodeIfPresent(useDefaultTierForNull, forKey: .useDefaultTierForNull)
        case let .loadByPeriod(period, includeFuture, tieredReplicants, useDefaultTierForNull):
            try container.encode(RuleType.loadByPeriod, forKey: .type)
            try container.encode(period, forKey: .period)
            try container.encodeIfPresent(includeFuture, forKey: .includeFuture)
            try container.encodeIfPresent(tieredReplicants, forKey: .tieredReplicants)
            try container.encodeIfPresent(useDefaultTierForNull, forKey: .useDefaultTierForNull)
        case .dropForever:
            try container.encode(RuleType.dropForever, forKey: .type)
        case let .dropByInterval(interval):
            try container.encode(RuleType.dropByInterval, forKey: .type)
            try container.encode(interval, forKey: .interval)
        case let .dropByPeriod(period, includeFuture):
            try container.encode(RuleType.dropByPeriod, forKey: .type)
            try container.encode(period, forKey: .period)
            try container.encodeIfPresent(includeFuture, forKey: .includeFuture)
        case let .dropBeforeByPeriod(period):
            try container.encode(RuleType.dropBeforeByPeriod, forKey: .type)
            try container.encode(period, forKey: .period)
        }
    }
}
