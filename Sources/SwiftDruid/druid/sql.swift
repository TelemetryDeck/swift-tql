import SwiftTQL
import Tracing
import Vapor

public struct SQLRoutes {
    let druid: Druid

    public struct DruidSQLQueryType: Codable, Content {
        /// Query context keys the client sends to Druid. Every key is optional and a nil key is
        /// left out of the body. For organization requests the backend sends only the keys that
        /// the tenant authorizer allowlists (`sqlTimeZone`, `useApproximateCountDistinct`,
        /// `useApproximateTopN`); `engine` is never allowlisted and stays nil on that path.
        public struct Context: Codable, Content {
            public enum Engine: String, Codable, Content {
                case native
            }

            public var engine: Engine?
            public var sqlTimeZone: String?
            public var useApproximateCountDistinct: Bool?
            public var useApproximateTopN: Bool?
            public var sqlQueryId: String?

            public init(
                engine: Engine? = nil,
                sqlTimeZone: String? = nil,
                useApproximateCountDistinct: Bool? = nil,
                useApproximateTopN: Bool? = nil,
                sqlQueryId: String? = nil
            ) {
                self.engine = engine
                self.sqlTimeZone = sqlTimeZone
                self.useApproximateCountDistinct = useApproximateCountDistinct
                self.useApproximateTopN = useApproximateTopN
                self.sqlQueryId = sqlQueryId
            }
        }

        public let context: Context
        public let query: String

        public init(query: String, context: Context) {
            self.query = query
            self.context = context
        }
    }

    /// Run a SQL query.
    ///
    /// - Parameters:
    ///   - query: The SQL request body.
    ///   - tenant: The organization user the query runs for. When set, the request carries the
    ///     `X-TD-Namespaces` and `X-TD-User` headers. When nil, the request is internal and
    ///     sends neither header.
    /// - Throws: `TenantContextError` before any request is made when `tenant` has an invalid
    ///   namespace list.
    public func execute(query: DruidSQLQueryType, tenant: TenantContext? = nil) async throws -> [[String: ValueWrapper]] {
        // Validate outside `druid.execute`: an error thrown inside its closure would count as a
        // connection failure and fail over to every server.
        let headers = try tenant?.headers() ?? HTTPHeaders()

        return try await druid.execute { baseURL in
            try await withSpan("Druid.Druid.SQL.Query") { _ in
                let uri = URI(string: "\(baseURL)v2/sql")

                let response = try await druid.client.post(uri, headers: headers, content: query)
                guard response.status == .ok else {
                    if let error = try? response.content.decode(DruidError.self) {
                        throw Abort(response.status, reason: error.localizedDescription)
                    } else {
                        throw Abort(.internalServerError, reason: "Failed to run query")
                    }
                }

                return try response.content.decode([[String: ValueWrapper]].self)
            }
        }
    }
}
