import SwiftTQL
import Tracing
import Vapor

extension CustomQuery: Content {}

public struct QueryRoutes {
    let druid: Druid

    public func execute(query compiledQuery: CustomQuery) async throws -> QueryResultData {
        return try await druid.execute { baseURL in
            try await withSpan("Druid.Druid.TQL.Query") { _ in
                let compiledQueryData: Data
                do {
                    compiledQueryData = try JSONEncoder.telemetryEncoder.encode(compiledQuery)
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
                let response = try await druid.client.post(uri) { clientRequest in
                    clientRequest.headers.contentType = .json
                    clientRequest.body = requestBody
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
}
