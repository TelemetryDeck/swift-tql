import Foundation

public extension ClusterSpec {
    /// Names the source query and connects its columns to the roles of the gauge.
    struct Encoding: Codable, Hashable, Sendable {
        /// The name of the query that the gauge reads. Without it, the gauge reads the first query.
        public var source: String?

        /// The column for the x axis or for the category.
        public var x: String?

        /// One or more number columns. With a breakdown, exactly one column.
        public var y: [String]?

        /// The maximum number of categories when x is a text column. Without it, the gauge shows each category.
        public var top: Limit?

        /// `true` puts zero where a value is missing. Without it, a missing value is a gap.
        public var fillZero: Bool?

        /// How the series stack. Without it, bars with a breakdown are stacked and all other series are not.
        public var stack: Stack?

        /// A column whose values become separate series.
        public var breakdown: Breakdown?
    }

    struct Breakdown: Codable, Hashable, Sendable {
        /// The column whose values become separate series.
        public var column: String

        /// The maximum number of series. The web app uses 10 without it.
        public var top: Limit?

        /// What occurs with the values after the limit. The web app drops them without it.
        public var other: Other?

        /// The sequence of the series. The web app sorts by value without it.
        public var sort: Sort?

        public enum Other: String, Codable, Hashable, Sendable {
            /// The gauge does not show the remaining values.
            case drop

            /// One series "Other" holds the sum of the remaining values.
            case sum
        }

        public enum Sort: String, Codable, Hashable, Sendable {
            /// The series with the highest sum is first.
            case value

            /// The series are in the sequence of their names.
            case name
        }
    }

    enum Stack: String, Codable, Hashable, Sendable {
        case none
        case stacked

        /// Each value becomes its fraction of the total for the same x value.
        case percent
    }

    /// A maximum number, or `"all"` for no limit.
    enum Limit: Codable, Hashable, Sendable {
        case count(Int)
        case all

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let count = try? container.decode(Int.self), count >= 1 {
                self = .count(count)
            } else if try container.decode(String.self) == "all" {
                self = .all
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "A limit is a number from 1, or the text \"all\"")
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()

            switch self {
            case let .count(count): try container.encode(count)
            case .all: try container.encode("all")
            }
        }
    }
}
