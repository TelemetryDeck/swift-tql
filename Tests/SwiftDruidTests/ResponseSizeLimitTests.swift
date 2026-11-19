import AsyncHTTPClient
import Foundation
@testable import SwiftDruid
import SwiftTQL
import Testing
import Vapor

/// A Vapor `Client` that answers each request with a 200 response of a fixed body size.
private final class FixedSizeClient: Client, @unchecked Sendable {
    let eventLoop: any EventLoop = EmbeddedEventLoop()
    let bodySize: Int
    private let lock = NSLock()
    private var _requestCount = 0

    init(bodySize: Int) {
        self.bodySize = bodySize
    }

    var requestCount: Int {
        lock.withLock { _requestCount }
    }

    func delegating(to eventLoop: any EventLoop) -> any Client { self }

    func send(_ request: ClientRequest) -> EventLoopFuture<ClientResponse> {
        lock.withLock { _requestCount += 1 }
        let body = ByteBuffer(repeating: UInt8(ascii: " "), count: bodySize)
        return eventLoop.makeSucceededFuture(ClientResponse(status: .ok, headers: HTTPHeaders(), body: body))
    }
}

@Suite("Query response size limit tests", .serialized)
struct ResponseSizeLimitTests {
    static let sqlQuery = SQLRoutes.DruidSQLQueryType(query: "SELECT 1", context: .init(engine: .native))

    static let nativeQuery = CustomQuery(
        queryType: .scan,
        dataSource: "com.example.app",
        intervals: [.init(beginningDate: Date(timeIntervalSince1970: 0), endDate: Date(timeIntervalSince1970: 86400))],
        limit: 10
    )

    private func expectTooLarge(_ operation: () async throws -> Void) async {
        do {
            try await operation()
            Issue.record("Expected a 'Query Result too large' error")
        } catch let error as Abort {
            #expect(error.status == .badRequest)
            #expect(error.reason.contains("Query Result too large"))
        } catch {
            Issue.record("Expected an Abort, got \(error)")
        }
    }

    // MARK: Vapor client (complete body is buffered, then checked)

    @Test("Native query: a body larger than the limit is rejected and not sent to the next server")
    func nativeTooLargeWithVaporClient() async throws {
        let client = FixedSizeClient(bodySize: 2000)
        let druid = Druid(baseURLs: ["http://druid-1/", "http://druid-2/"], client: client, maximumQueryResponseBytes: 1000)

        await expectTooLarge { _ = try await druid.query.execute(query: Self.nativeQuery) }
        #expect(client.requestCount == 1)
    }

    @Test("SQL query: a body larger than the limit is rejected and not sent to the next server")
    func sqlTooLargeWithVaporClient() async throws {
        let client = FixedSizeClient(bodySize: 2000)
        let druid = Druid(baseURLs: ["http://druid-1/", "http://druid-2/"], client: client, maximumSQLResponseBytes: 1000)

        await expectTooLarge { _ = try await druid.sql.execute(query: Self.sqlQuery) }
        #expect(client.requestCount == 1)
    }

    @Test("A body at the limit is accepted")
    func bodyAtLimitIsAccepted() async throws {
        let client = FixedSizeClient(bodySize: 1000)
        let druid = Druid(baseURL: "http://druid/", client: client, maximumSQLResponseBytes: 1000)

        let data = try await druid.sql.execute(query: Self.sqlQuery)
        #expect(data.count == 1000)
    }

    @Test("The default limits are 32 MiB for native queries and 256 MiB for SQL")
    func defaultLimits() {
        let druid = Druid(baseURL: "http://druid/", client: FixedSizeClient(bodySize: 0))
        #expect(druid.maximumQueryResponseBytes == 32 * 1024 * 1024)
        #expect(druid.maximumSQLResponseBytes == 256 * 1024 * 1024)
    }

    // MARK: HTTPClient (the read stops at the limit)

    /// Starts a local server that answers `POST /druid/v2/` and `POST /druid/v2/sql` with a body
    /// of `bodySize` bytes, runs `body` with a `Druid` that uses an `HTTPClient`, then stops it.
    private func withLocalDruid(
        bodySize: Int,
        chunked: Bool,
        limit: Int,
        _ body: (Druid) async throws -> Void
    ) async throws {
        let app = try await Application.make(.testing)
        let respond: @Sendable (Request) -> Response = { _ in
            let buffer = ByteBuffer(repeating: UInt8(ascii: " "), count: bodySize)
            if chunked {
                // A stream body has no Content-Length, so the client must count the bytes it reads.
                return Response(status: .ok, body: .init(stream: { writer in
                    writer.write(.buffer(buffer)).whenComplete { _ in _ = writer.write(.end) }
                }))
            }
            return Response(status: .ok, body: .init(buffer: buffer))
        }
        app.on(.POST, "druid", "v2", body: .collect(maxSize: "1mb"), use: respond)
        app.on(.POST, "druid", "v2", "sql", body: .collect(maxSize: "1mb"), use: respond)
        let httpClient = HTTPClient(eventLoopGroupProvider: .singleton)

        let result: Result<Void, any Error>
        do {
            try await app.server.start(address: .hostname("127.0.0.1", port: 0))
            let port = try #require(app.http.server.shared.localAddress?.port)
            let druid = Druid(
                baseURL: "http://127.0.0.1:\(port)/druid/",
                client: app.client,
                httpClient: httpClient,
                maximumQueryResponseBytes: limit,
                maximumSQLResponseBytes: limit
            )
            try await body(druid)
            result = .success(())
        } catch {
            result = .failure(error)
        }
        try await httpClient.shutdown()
        await app.server.shutdown()
        try await app.asyncShutdown()
        try result.get()
    }

    @Test("HTTPClient: a body above the limit is rejected, with and without Content-Length", arguments: [false, true])
    func tooLargeWithHTTPClient(chunked: Bool) async throws {
        try await withLocalDruid(bodySize: 512 * 1024, chunked: chunked, limit: 1000) { druid in
            await expectTooLarge { _ = try await druid.query.execute(query: Self.nativeQuery) }
            await expectTooLarge { _ = try await druid.sql.execute(query: Self.sqlQuery) }
        }
    }

    @Test("HTTPClient: a body below the limit is returned complete")
    func belowLimitWithHTTPClient() async throws {
        try await withLocalDruid(bodySize: 5000, chunked: false, limit: 10000) { druid in
            let data = try await druid.sql.execute(query: Self.sqlQuery)
            #expect(data.count == 5000)
        }
    }
}
