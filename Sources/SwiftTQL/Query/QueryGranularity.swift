import Foundation

// MARK: - Simple Granularity

/// Named granularities supported by Apache Druid.
public enum SimpleGranularity: String, Codable, Hashable, CaseIterable, Sendable {
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

// MARK: - Duration Granularity

/// A fixed-duration granularity specified in milliseconds.
///
/// Duration granularities are useful for fixed-length intervals that don't align to calendar boundaries.
/// For example, a duration of `3600000` represents exactly one hour (regardless of DST changes).
public struct DurationGranularity: Codable, Hashable, Sendable {
    /// The duration in milliseconds.
    public let duration: Int64

    /// An optional origin date that offsets the granularity boundaries.
    public let origin: Date?

    public init(duration: Int64, origin: Date? = nil) {
        self.duration = duration
        self.origin = origin
    }

    enum CodingKeys: String, CodingKey {
        case duration
        case origin
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        duration = try container.decode(Int64.self, forKey: .duration)
        if let originString = try container.decodeIfPresent(String.self, forKey: .origin) {
            origin = try Self.parseISO8601(originString)
        } else {
            origin = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(duration, forKey: .duration)
        if let origin {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            try container.encode(formatter.string(from: origin), forKey: .origin)
        }
    }

    private static func parseISO8601(_ string: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: string) { return date }
        throw DecodingError.dataCorrupted(.init(
            codingPath: [],
            debugDescription: "Unable to parse ISO 8601 date: \(string)"
        ))
    }
}

// MARK: - Period Granularity

/// An ISO 8601 period-based granularity with optional timezone and origin.
///
/// Period granularities align to calendar boundaries and respect timezone rules (including DST).
/// For example, `"P1D"` with `timeZone: "America/Los_Angeles"` produces day-aligned buckets in Pacific time.
public struct PeriodGranularity: Codable, Hashable, Sendable {
    /// An ISO 8601 period string (e.g. `"P1D"`, `"PT6H"`, `"P1M"`).
    public let period: String

    /// An optional IANA timezone (e.g. `"America/Los_Angeles"`). Defaults to UTC when nil.
    public let timeZone: String?

    /// An optional origin date that offsets the granularity boundaries.
    public let origin: Date?

    public init(period: String, timeZone: String? = nil, origin: Date? = nil) {
        self.period = period
        self.timeZone = timeZone
        self.origin = origin
    }

    enum CodingKeys: String, CodingKey {
        case period
        case timeZone
        case origin
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        period = try container.decode(String.self, forKey: .period)
        timeZone = try container.decodeIfPresent(String.self, forKey: .timeZone)
        if let originString = try container.decodeIfPresent(String.self, forKey: .origin) {
            origin = try Self.parseISO8601(originString)
        } else {
            origin = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(period, forKey: .period)
        try container.encodeIfPresent(timeZone, forKey: .timeZone)
        if let origin {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            try container.encode(formatter.string(from: origin), forKey: .origin)
        }
    }

    private static func parseISO8601(_ string: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: string) { return date }
        throw DecodingError.dataCorrupted(.init(
            codingPath: [],
            debugDescription: "Unable to parse ISO 8601 date: \(string)"
        ))
    }
}

// MARK: - QueryGranularity

/// Represents an Apache Druid query granularity.
///
/// Supports three forms:
/// - **Simple**: Named granularities like `"day"`, `"hour"`, `"all"` — encoded as bare strings.
/// - **Duration**: Fixed millisecond intervals — encoded as `{"type":"duration","duration":...}`.
/// - **Period**: ISO 8601 periods with timezone support — encoded as `{"type":"period","period":...}`.
public enum QueryGranularity: Codable, Hashable, Sendable {
    case simple(SimpleGranularity)
    case duration(DurationGranularity)
    case period(PeriodGranularity)

    // MARK: - Static convenience properties

    public static let all: QueryGranularity = .simple(.all)
    public static let none: QueryGranularity = .simple(.none)
    public static let second: QueryGranularity = .simple(.second)
    public static let minute: QueryGranularity = .simple(.minute)
    public static let fifteen_minute: QueryGranularity = .simple(.fifteen_minute)
    public static let thirty_minute: QueryGranularity = .simple(.thirty_minute)
    public static let hour: QueryGranularity = .simple(.hour)
    public static let day: QueryGranularity = .simple(.day)
    public static let week: QueryGranularity = .simple(.week)
    public static let month: QueryGranularity = .simple(.month)
    public static let quarter: QueryGranularity = .simple(.quarter)
    public static let year: QueryGranularity = .simple(.year)

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case type
    }

    // MARK: - Decoding

    public init(from decoder: Decoder) throws {
        // Try bare string first (simple granularity)
        if let singleValueContainer = try? decoder.singleValueContainer(),
           let rawValue = try? singleValueContainer.decode(String.self) {
            // Check if it matches a known simple granularity (case-insensitive)
            for simpleCase in SimpleGranularity.allCases where rawValue.lowercased() == simpleCase.rawValue {
                self = .simple(simpleCase)
                return
            }
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Unknown granularity string: \(rawValue)"
            ))
        }

        // Try keyed container with "type" discriminator
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type.lowercased() {
        case "duration":
            self = try .duration(DurationGranularity(from: decoder))
        case "period":
            self = try .period(PeriodGranularity(from: decoder))
        default:
            // Try as simple granularity in object form: {"type": "day"}
            for simpleCase in SimpleGranularity.allCases where type.lowercased() == simpleCase.rawValue {
                self = .simple(simpleCase)
                return
            }
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Unknown granularity type: \(type)"
            ))
        }
    }

    // MARK: - Encoding

    public func encode(to encoder: Encoder) throws {
        switch self {
        case let .simple(granularity):
            // Simple granularities encode as bare strings
            var container = encoder.singleValueContainer()
            try container.encode(granularity.rawValue)
        case let .duration(durationGranularity):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("duration", forKey: .type)
            try durationGranularity.encode(to: encoder)
        case let .period(periodGranularity):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("period", forKey: .type)
            try periodGranularity.encode(to: encoder)
        }
    }
}
