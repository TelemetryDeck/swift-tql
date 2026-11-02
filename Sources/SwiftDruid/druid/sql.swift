import Foundation
import SwiftTQL
import Tracing
import Vapor

public struct SQLRoutes {
    let druid: Druid

    public struct DruidSQLQueryType: Codable, Content, Sendable {
        /// Query context keys the client sends to Druid. Every key is optional and a nil key is
        /// left out of the body. For organization requests the backend sends only the keys that
        /// the tenant authorizer allowlists (`sqlTimeZone`, `useApproximateCountDistinct`,
        /// `useApproximateTopN`); `engine` is never allowlisted and stays nil on that path.
        public struct Context: Codable, Content, Sendable {
            public enum Engine: String, Codable, Content, Sendable {
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
    /// Every query is sent with an `sqlQueryId` in its context (a fresh UUID when the caller did
    /// not set one). When the calling task is cancelled while the broker is still working, the
    /// call stops waiting at once, asks that same broker to cancel the query
    /// (`DELETE /druid/v2/sql/{sqlQueryId}`) and throws `CancellationError`. Without this, a query
    /// whose caller has gone away keeps running on the broker until it finishes or hits the query
    /// timeout.
    ///
    /// - Parameters:
    ///   - query: The SQL request body.
    ///   - tenant: The organization user the query runs for. When set, the request carries the
    ///     `X-TD-Namespaces` and `X-TD-User` headers. When nil, the request is internal and
    ///     sends neither header.
    /// - Throws: `TenantContextError` before any request is made when `tenant` has an invalid
    ///   namespace list. `CancellationError` when the calling task is cancelled before Druid
    ///   answers.
    public func execute(query: DruidSQLQueryType, tenant: TenantContext? = nil) async throws -> [[String: ValueWrapper]] {
        // Validate outside `druid.execute`: an error thrown inside its closure would count as a
        // connection failure and fail over to every server.
        let tenantHeaders = try tenant?.headers() ?? HTTPHeaders()

        // Make sure the query can be cancelled on the broker: Druid only knows a SQL query by the
        // `sqlQueryId` the client sent along. Druid never requires authorization for this key.
        var queryToSend = query
        if (queryToSend.context.sqlQueryId ?? "").isEmpty {
            var context = queryToSend.context
            context.sqlQueryId = UUID().uuidString
            queryToSend = DruidSQLQueryType(query: queryToSend.query, context: context)
        }
        let sqlQueryId = queryToSend.context.sqlQueryId ?? ""

        return try await druid.execute { baseURL in
            try await withSpan("Druid.Druid.SQL.Query") { span in
                span.attributes["druid.sql_query_id"] = sqlQueryId

                let uri = URI(string: "\(baseURL)v2/sql")
                var request = ClientRequest(method: .POST, url: uri, headers: tenantHeaders)
                try request.content.encode(queryToSend)

                // `Client.post` awaits the response future with `get()`, which ignores task
                // cancellation. Await it in a way that returns the moment the task is cancelled, and
                // in that case tell the broker to stop the query. The broker then fails the pending
                // request promptly, which also frees the HTTP client's connection.
                let response: ClientResponse
                do {
                    response = try await druid.client.send(request).getUnlessCancelled()
                } catch is CancellationError {
                    druid.logger.notice("Druid SQL query abandoned by its caller, cancelling it on the broker", metadata: [
                        "server": .string(baseURL),
                        "sql_query_id": .string(sqlQueryId),
                    ])
                    await cancel(sqlQueryId: sqlQueryId, on: baseURL)
                    throw CancellationError()
                }

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

    /// Asks the broker at `baseURL` to cancel the SQL query with `sqlQueryId`
    /// (`DELETE /druid/v2/sql/{sqlQueryId}`).
    ///
    /// Best effort: a failure to deliver the cancellation is logged, never thrown, because the
    /// caller is already on its way out. Druid answers `202 Accepted` whether or not it still
    /// knows the query.
    public func cancel(sqlQueryId: String, on baseURL: String) async {
        guard !sqlQueryId.isEmpty else { return }
        await druid.sendCancellation(to: URI(string: "\(baseURL)v2/sql/\(sqlQueryId)"), server: baseURL, queryId: sqlQueryId)
    }

    /// Asks every configured broker to cancel the SQL query with `sqlQueryId`.
    ///
    /// Use this when the broker that runs the query is unknown, e.g. for an `sqlQueryId` the
    /// caller chose itself. Brokers that do not know the query answer `202 Accepted` as well.
    public func cancel(sqlQueryId: String) async {
        for baseURL in druid.baseURLs {
            await cancel(sqlQueryId: sqlQueryId, on: baseURL)
        }
    }
}
