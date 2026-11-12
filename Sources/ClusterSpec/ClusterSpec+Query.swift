import Foundation
import SwiftTQL

public extension ClusterSpec {
    /// One query of a spec.
    struct Query: Codable, Hashable, Sendable {
        /// The name of the query in this spec. `encoding.source` and `datasetId` refer to it.
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
