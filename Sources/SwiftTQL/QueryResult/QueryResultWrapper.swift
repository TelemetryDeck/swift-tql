import Foundation

public struct QueryResultWrapper: Codable, Hashable, Equatable, Sendable {
    /// The raw, undecoded Druid response carried through without being serialized into this wrapper.
    ///
    /// `result` is deliberately excluded from this type's `Codable` conformance (see ``CodingKeys``
    /// and the custom `init(from:)`/`encode(to:)` below): the whole point of ``QueryResultData`` is
    /// to avoid the decode/re-encode round trip, so routing its bytes through `JSONEncoder` here
    /// would defeat the optimization. The raw bytes are instead spliced into the HTTP response at the
    /// Vapor `AsyncResponseEncodable` seam. Consequently, a wrapper decoded from JSON always has a
    /// `nil` `result`.
    public let result: QueryResultData?
    public let error: String?

    public let calculationDuration: TimeInterval
    public let calculationFinishedAt: Date

    public init(result: QueryResultData?, calculationDuration: TimeInterval, finishedAt: Date, error: String?) {
        self.result = result
        self.calculationDuration = calculationDuration
        self.error = error
        calculationFinishedAt = finishedAt
    }

    /// Coding keys deliberately omit `result` so it is never serialized or deserialized.
    private enum CodingKeys: String, CodingKey {
        case error
        case calculationDuration
        case calculationFinishedAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // `result` is never encoded, so there is nothing to decode — always nil on the way back in.
        result = nil
        error = try container.decodeIfPresent(String.self, forKey: .error)
        calculationDuration = try container.decode(TimeInterval.self, forKey: .calculationDuration)
        calculationFinishedAt = try container.decode(Date.self, forKey: .calculationFinishedAt)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // `result` is intentionally not encoded; see the note on the property.
        try container.encodeIfPresent(error, forKey: .error)
        try container.encode(calculationDuration, forKey: .calculationDuration)
        try container.encode(calculationFinishedAt, forKey: .calculationFinishedAt)
    }
}
