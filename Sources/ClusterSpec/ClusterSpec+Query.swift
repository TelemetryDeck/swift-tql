import Foundation
import SwiftTQL

public extension ClusterSpec {
    /// One query of a spec.
    ///
    /// Rules for a SQL query that a chart reads:
    ///
    /// - Give each column a name: `COUNT(*) AS "events"`.
    /// - For a time axis, return a time value, not text: `TIME_FLOOR(__time, 'P1D') AS "day"`.
    /// - For categories, return text. `TIME_FORMAT(__time, 'EEE')` gives the weekday as text.
    /// - Return numbers for the y columns. Use `CAST` for a number that is text.
    /// - Return few rows. A gauge reads a maximum of 10,000 rows. Group in the query, not in the gauge.
    /// - `LIMIT` without `ORDER BY` returns rows that the database selects. For a chart of the largest values, sort first.
    ///
    /// ```json
    /// { "name": "main", "language": "sql", "query": "SELECT TIME_FLOOR(__time, 'P1D') AS \"day\", COUNT(*) AS \"events\" FROM ... GROUP BY 1" }
    /// ```
    struct Query: Codable, Hashable, Sendable {
        /// The name of the query in this spec. `encoding.source` and `datasetId` refer to it.
        /// Use a name that tells what the query returns, for example `users`. The name `main` is usual for the first query.
        public var name: String

        /// The TQL query or the SQL text.
        public var query: Content

        /// The time between two runs of the query, in seconds. The minimum is 60. The web app uses 3600 without it.
        public var refreshSeconds: Int?

        public enum Content: Hashable, Sendable {
            case tql(CustomQuery)

            /// SQL text. `{{events}}` is the placeholder for the events of the app.
            case sql(String)
        }

        private enum Language: String, Codable {
            case tql
            case sql
        }

        private enum CodingKeys: String, CodingKey {
            case name
            case language
            case query
            case refreshSeconds
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            name = try container.decode(String.self, forKey: .name)
            guard !name.isEmpty else {
                throw DecodingError.dataCorruptedError(forKey: .name, in: container, debugDescription: "A query needs a name")
            }

            switch try container.decode(Language.self, forKey: .language) {
            case .tql:
                query = try .tql(container.decode(CustomQuery.self, forKey: .query))
            case .sql:
                let text = try container.decode(String.self, forKey: .query)
                guard !text.isEmpty else {
                    throw DecodingError.dataCorruptedError(forKey: .query, in: container, debugDescription: "A SQL query needs text")
                }
                query = .sql(text)
            }

            refreshSeconds = try container.decodeIfPresent(Int.self, forKey: .refreshSeconds)
            if let refreshSeconds, refreshSeconds < 60 {
                throw DecodingError.dataCorruptedError(forKey: .refreshSeconds, in: container, debugDescription: "The minimum is 60 seconds")
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encode(name, forKey: .name)

            switch query {
            case let .tql(query):
                try container.encode(Language.tql, forKey: .language)
                try container.encode(query, forKey: .query)
            case let .sql(text):
                try container.encode(Language.sql, forKey: .language)
                try container.encode(text, forKey: .query)
            }

            try container.encodeIfPresent(refreshSeconds, forKey: .refreshSeconds)
        }
    }
}
