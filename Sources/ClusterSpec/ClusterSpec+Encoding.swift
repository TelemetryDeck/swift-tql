import Foundation

public extension ClusterSpec {
    /// Names the source query and connects its columns to the roles of the gauge.
    ///
    /// Each field is optional and has its own default. Set a field only when the default is not correct.
    /// A column name that the query result does not have gives the error `columnNotFound`.
    /// A field that the gauge does not use gives the warning `unusedField`. The gauge still shows.
    ///
    /// This example shows the events for each day, with one series for each of the five largest app versions:
    ///
    /// ```json
    /// "encoding": { "x": "day", "y": ["events"], "breakdown": { "column": "appVersion", "top": 5, "other": "sum" } }
    /// ```
    struct Encoding: Codable, Hashable, Sendable {
        /// The name of the query that the gauge reads. Without it, the gauge reads the first query.
        public var source: String?

        /// The column for the x axis or for the category.
        ///
        /// Without it, the gauge uses the first time column with more than one value, then the first text column.
        /// A time column gives a time axis. A text column gives one category for each value, in the sequence of the rows.
        /// Sort the rows in the query (`ORDER BY`).
        /// On a time axis, the gauge does not show a row with a null x value. It reports the number of these rows.
        /// A null or empty category has the label "(no value)".
        /// A pie shows a time value as date text.
        public var x: String?

        /// One or more number columns. With a breakdown, exactly one column.
        ///
        /// Without it, the gauge uses each number column that is not x. Each column is one series.
        /// The gauges `pie` and `bigNumber` read only the first column.
        /// A column that does not hold numbers gives the error `frameDoesNotFit`. In SQL, a number as text is not a number: use `CAST`.
        public var y: [String]?

        /// The maximum number of categories when x is a text column. Without it, the gauge shows each category.
        ///
        /// The gauge keeps the categories with the highest values of the first y column. They keep the sequence of the rows.
        /// The gauge reports the number of categories that it does not show.
        /// `"top": 5` with the gauge `pie` shows the five largest slices. It has no slice for the remaining rows.
        public var top: Limit?

        /// `true` puts zero where a value is missing. Without it, a missing value is a gap.
        ///
        /// A SQL query returns no row for a time step without events. The gauge adds these time steps.
        /// With `true`, such a time step shows as zero. Use `true` for counts. Do not use it for an average or a share.
        public var fillZero: Bool?

        /// How the series stack. Without it, bars with a breakdown are stacked and all other series are not.
        /// Series of an extra query do not stack with the generated series.
        public var stack: Stack?

        /// A column whose values become separate series.
        ///
        /// Without it, the gauge makes a breakdown when x is a time column and the result has exactly
        /// one text column and exactly one number column.
        public var breakdown: Breakdown?
    }

    /// Changes rows into series: one series for each value of a column.
    ///
    /// The query returns one row for each pair of x value and breakdown value:
    /// `SELECT ... AS "day", "appVersion", COUNT(*) AS "events" ... GROUP BY 1, 2`.
    /// The tooltip shows the ten series with the highest values and one line for the sum of the others.
    struct Breakdown: Codable, Hashable, Sendable {
        /// The column whose values become separate series. It must not be the x column.
        /// A null or empty value is in the series "(no value)".
        public var column: String

        /// The maximum number of series. The web app uses 10 without it.
        /// The gauge keeps the values with the highest sums. `"all"` shows a maximum of 1000 series.
        /// A chart with more than 20 series is difficult to read. The colours repeat.
        public var top: Limit?

        /// What occurs with the values after the limit. The web app drops them without it.
        /// With `drop`, a stack does not show the total. Use `sum` when the user must see the total.
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
        /// The total includes the values that the breakdown limit removed. The value axis and the tooltip show percentages.
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
