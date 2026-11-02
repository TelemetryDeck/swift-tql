import Foundation
import NIOPosix
@testable import SwiftDruid
import SwiftTQL
import Testing
import Vapor

private struct SentSQLQuery: Decodable {
    struct Context: Decodable {
        let sqlQueryId: String?
    }

    let context: Context
    let query: String
}

private func sentSQLQuery(_ request: ClientRequest) throws -> SentSQLQuery {
    let body = try #require(request.body)
    return try JSONDecoder().decode(SentSQLQuery.self, from: Data(body.readableBytesView))
}

@Suite("SQL route cancellation tests")
struct SQLRouteCancellationTests {
    static let eventLoop = MultiThreadedEventLoopGroup.singleton.next()
    static let rows = #"[{"count":1}]"#

    static let query = SQLRoutes.DruidSQLQueryType(
        query: "SELECT COUNT(*) AS count FROM telemetry",
        context: .init(sqlTimeZone: "UTC")
    )

    @Test("Every SQL query is sent with an sqlQueryId")
    func assignsSQLQueryId() async throws {
        let client = HoldingClient(eventLoop: Self.eventLoop, holdPosts: false, responseBody: Self.rows)
        let druid = Druid(baseURL: "http://druid/", client: client)

        _ = try await druid.sql.execute(query: Self.query)

        let request = try #require(client.requests.first)
        let sent = try sentSQLQuery(request)
        #expect(sent.query == Self.query.query)
        let sqlQueryId = try #require(sent.context.sqlQueryId)
        #expect(UUID(uuidString: sqlQueryId) != nil)
        #expect(client.requests(.DELETE).isEmpty)
    }

    @Test("An sqlQueryId set by the caller is kept")
    func keepsCallerSQLQueryId() async throws {
        let client = HoldingClient(eventLoop: Self.eventLoop, holdPosts: false, responseBody: Self.rows)
        let druid = Druid(baseURL: "http://druid/", client: client)
        let query = SQLRoutes.DruidSQLQueryType(query: Self.query.query, context: .init(sqlQueryId: "caller-chosen-id"))

        _ = try await druid.sql.execute(query: query)

        let request = try #require(client.requests.first)
        #expect(try sentSQLQuery(request).context.sqlQueryId == "caller-chosen-id")
    }

    @Test("Cancelling the task stops waiting, cancels the SQL query on the same broker and throws CancellationError")
    func cancellationIssuesDelete() async throws {
        let client = HoldingClient(eventLoop: Self.eventLoop)
        let druid = Druid(baseURLs: ["http://a/", "http://b/"], client: client)

        let task = Task {
            try await druid.sql.execute(query: Self.query)
        }
        try await client.waitForRequests(count: 1)
        let post = try #require(client.requests(.POST).first)
        let sqlQueryId = try #require(try sentSQLQuery(post).context.sqlQueryId)

        task.cancel()
        let result = await task.result

        #expect(throws: CancellationError.self) { try result.get() }
        let deletes = client.requests(.DELETE)
        #expect(deletes.count == 1)
        #expect(deletes.first?.url.string == "\(post.url.string)/\(sqlQueryId)")
        #expect(deletes.first?.url.string.hasPrefix("http://a/") == true)

        // Cancellation is a local decision; it must not blame the server or fail over to another one.
        #expect(client.requests(.POST).count == 1)
        #expect(await druid.serverPool.nextServer(excluding: ["http://b/"]) == "http://a/")

        client.releaseHeldRequests()
    }

    @Test("Explicit cancellation by sqlQueryId reaches every configured broker")
    func cancelOnAllServers() async throws {
        let client = HoldingClient(eventLoop: Self.eventLoop)
        let druid = Druid(baseURLs: ["http://a/", "http://b/"], client: client)

        await druid.sql.cancel(sqlQueryId: "abc")

        let urls = client.requests(.DELETE).map(\.url.string).sorted()
        #expect(urls == ["http://a/v2/sql/abc", "http://b/v2/sql/abc"])
    }
}
