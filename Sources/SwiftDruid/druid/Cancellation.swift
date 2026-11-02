import Vapor

extension Druid {
    /// Sends a best-effort cancellation (`DELETE`) to a broker.
    ///
    /// A failure to deliver the cancellation is logged, never thrown, because the caller is already
    /// on its way out. Druid answers `202 Accepted` whether or not it still knows the query. The
    /// request is sent with `Client.send(_:)`, whose `get()` does not check task cancellation, so
    /// it goes out even from an already cancelled task.
    ///
    /// - Parameters:
    ///   - uri: The cancel endpoint, `{baseURL}v2/{queryId}` for native queries and
    ///     `{baseURL}v2/sql/{sqlQueryId}` for SQL queries.
    ///   - baseURL: The broker the cancellation goes to, for logging.
    ///   - queryId: The query's id, for logging.
    func sendCancellation(to uri: URI, server baseURL: String, queryId: String) async {
        do {
            let response = try await client.send(ClientRequest(method: .DELETE, url: uri)).get()
            guard response.status == .accepted else {
                logger.warning("Druid did not accept the query cancellation", metadata: [
                    "server": .string(baseURL),
                    "query_id": .string(queryId),
                    "status": .stringConvertible(response.status.code),
                ])
                return
            }
        } catch {
            logger.warning("Failed to cancel Druid query", metadata: [
                "server": .string(baseURL),
                "query_id": .string(queryId),
                "error": .string(String(describing: error)),
            ])
        }
    }
}
