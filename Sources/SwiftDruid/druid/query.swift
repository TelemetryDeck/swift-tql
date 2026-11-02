import Foundation
import SwiftTQL
import Tracing
import Vapor

extension CustomQuery: Content {}

public struct QueryRoutes {
    let druid: Druid

    /// Run a native Druid query.
    ///
    /// Every query is sent with a `queryId` in its context (a fresh UUID when the caller did not
    /// set one). When the calling task is cancelled while the broker is still working, the call
    /// stops waiting at once, asks that same broker to cancel the query
    /// (`DELETE /druid/v2/{queryId}`) and throws `CancellationError`. Without this, a query whose
    /// caller has gone away (a client that disconnected, a request that timed out) keeps running
    /// on the broker until it finishes or hits the query timeout.
    ///
    /// - Parameters:
    ///   - compiledQuery: The compiled native query.
    ///   - tenant: The organization user the query runs for. When set, the request carries the
    ///     `X-TD-Namespaces` and `X-TD-User` headers. When nil, the request is internal and
    ///     sends neither header.
    /// - Throws: `TenantContextError` before any request is made when `tenant` has an invalid
    ///   namespace list. `CancellationError` when the calling task is cancelled before Druid
    ///   answers.
    public func execute(query compiledQuery: CustomQuery, tenant: TenantContext? = nil) async throws -> QueryResultData {
        // Validate outside `druid.execute`: an error thrown inside its closure would count as a
        // connection failure and fail over to every server.
        let tenantHeaders = try tenant?.headers() ?? HTTPHeaders()

        // Make sure the query can be cancelled on the broker: Druid only knows a query by the
        // `queryId` the client sent along.
        var queryToSend = compiledQuery
        if (queryToSend.context?.queryId ?? "").isEmpty {
            if queryToSend.context == nil {
                queryToSend.context = QueryContext()
            }
            queryToSend.context?.queryId = UUID().uuidString
        }
        let queryId = queryToSend.context?.queryId ?? ""

        return try await druid.execute { baseURL in
            try await withSpan("Druid.Druid.TQL.Query") { span in
                span.attributes["druid.query_id"] = queryId

                let compiledQueryData: Data
                do {
                    compiledQueryData = try JSONEncoder.telemetryEncoder.encode(queryToSend)
                } catch {
                    throw Abort(.internalServerError, reason: "Error encoding query: \(error)")
                }

                // Materialize the query string lazily: the logger methods take an autoclosure, so this
                // only runs when the log statement is actually emitted (e.g. on error).
                let queryAsString = { String(data: compiledQueryData, encoding: .utf8) ?? "encoding error" }

                druid.logger.info("Running Druid Query: \(queryAsString()) on server \(baseURL)")

                // Send to Druid, reusing the bytes we already encoded above instead of re-encoding the query.
                let uri = URI(string: "\(baseURL)v2/")
                var requestBody = ByteBufferAllocator().buffer(capacity: compiledQueryData.count)
                requestBody.writeBytes(compiledQueryData)
                var headers = HTTPHeaders()
                headers.contentType = .json
                headers.add(contentsOf: tenantHeaders)
                let request = ClientRequest(method: .POST, url: uri, headers: headers, body: requestBody)

                // `Client.post` awaits the response future with `get()`, which ignores task
                // cancellation. Await it in a way that returns the moment the task is cancelled, and
                // in that case tell the broker to stop the query. The broker then fails the pending
                // request promptly, which also frees the HTTP client's connection.
                let response: ClientResponse
                do {
                    response = try await druid.client.send(request).getUnlessCancelled()
                } catch is CancellationError {
                    druid.logger.notice("Druid query abandoned by its caller, cancelling it on the broker", metadata: [
                        "server": .string(baseURL),
                        "query_id": .string(queryId),
                    ])
                    await cancel(queryId: queryId, on: baseURL)
                    throw CancellationError()
                }

                let maxResponseSize = 32 * 1024 * 1024
                if response.body?.readableBytes ?? 0 > maxResponseSize {
                    druid.logger.warning("Query Result too large: \(response.body?.readableBytes ?? 0) bytes. Query was \n\(queryAsString())")
                    throw Abort(
                        .badRequest,
                        reason: "Query Result too large. The result of this query is \(response.body?.readableBytes ?? 0) bytes, which is larger than the maximum of \(maxResponseSize) bytes."
                    )
                }

                // Check for errors
                guard response.status == .ok else {
                    if let error = try? response.content.decode(DruidError.self) {
                        throw Abort(response.status, reason: error.localizedDescription)
                    } else {
                        throw Abort(.internalServerError, reason: "Failed to run query")
                    }
                }

                // Capture the raw response bytes without decoding. Turning these into a structured
                // QueryResult is deferred to QueryResultData.decode(), so callers that only forward
                // the bytes don't pay for a decode/re-encode round trip.
                guard let buffer = response.body else {
                    throw Abort(.internalServerError, reason: "Druid query returned an empty response body")
                }

                return QueryResultData(
                    data: Data(buffer.readableBytesView),
                    queryType: compiledQuery.queryType,
                    restrictions: compiledQuery.restrictions
                )
            }
        }
    }

    /// Asks the broker at `baseURL` to cancel the query with `queryId` (`DELETE /druid/v2/{queryId}`).
    ///
    /// Best effort: a failure to deliver the cancellation is logged, never thrown, because the
    /// caller is already on its way out. Druid answers `202 Accepted` whether or not it still
    /// knows the query.
    public func cancel(queryId: String, on baseURL: String) async {
        guard !queryId.isEmpty else { return }
        await druid.sendCancellation(to: URI(string: "\(baseURL)v2/\(queryId)"), server: baseURL, queryId: queryId)
    }

    /// Asks every configured broker to cancel the query with `queryId`.
    ///
    /// Use this when the broker that runs the query is unknown, e.g. for a `queryId` the caller
    /// chose itself. Brokers that do not know the query answer `202 Accepted` as well.
    public func cancel(queryId: String) async {
        for baseURL in druid.baseURLs {
            await cancel(queryId: queryId, on: baseURL)
        }
    }
}
