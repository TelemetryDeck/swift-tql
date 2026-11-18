import AsyncHTTPClient
import NIOCore
import Vapor

extension Druid {
    /// Sends a query request and returns the response, with a body of at most `maximumResponseBytes`.
    ///
    /// With an `httpClient`, the response body is read as a stream and the read stops at the limit.
    /// A response that declares a larger `Content-Length` is rejected before any body byte is read.
    /// Without an `httpClient`, the Vapor `client` buffers the complete body first.
    ///
    /// - Throws: `Abort(.badRequest)` when the body is larger than the limit. An `Abort` tells
    ///   `Druid.execute` that the server is reachable, so the query is not sent to the next server.
    func sendQuery(_ request: ClientRequest, maximumResponseBytes: Int) async throws -> ClientResponse {
        guard let httpClient else {
            let response = try await client.send(request).get()
            let size = response.body?.readableBytes ?? 0
            if size > maximumResponseBytes {
                throw Self.responseTooLarge(maximumResponseBytes: maximumResponseBytes)
            }
            return response
        }

        var httpRequest = HTTPClientRequest(url: request.url.string)
        httpRequest.method = request.method
        httpRequest.headers = request.headers
        if let body = request.body {
            httpRequest.body = .bytes(body)
        }

        // No deadline for the complete request, the same as the Vapor client. The timeouts of the
        // `HTTPClient` configuration (connect, read) apply.
        let response = try await httpClient.execute(httpRequest, deadline: .distantFuture)

        let body: ByteBuffer
        do {
            body = try await response.body.collect(upTo: maximumResponseBytes)
        } catch is NIOTooManyBytesError {
            throw Self.responseTooLarge(maximumResponseBytes: maximumResponseBytes)
        }
        return ClientResponse(status: response.status, headers: response.headers, body: body)
    }

    static func responseTooLarge(maximumResponseBytes: Int) -> Abort {
        Abort(
            .badRequest,
            reason: "Query Result too large. The result of this query is larger than the maximum of \(maximumResponseBytes) bytes. Add a limit or use a shorter time interval."
        )
    }
}
