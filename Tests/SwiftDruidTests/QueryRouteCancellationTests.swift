import Foundation
import NIOConcurrencyHelpers
import NIOPosix
@testable import SwiftDruid
import SwiftTQL
import Testing
import Vapor

/// A Vapor `Client` that answers `DELETE` requests with `202 Accepted` right away but keeps
/// every `POST` pending until `releaseHeldRequests()` is called, so a test can cancel a task
/// while its query is "running on the broker".
private final class HoldingClient: Client, @unchecked Sendable {
    let eventLoop: any EventLoop
    private let lock = NIOLock()
    private var _requests: [ClientRequest] = []
    private var held: [EventLoopPromise<ClientResponse>] = []
    private let holdPosts: Bool

    init(eventLoop: any EventLoop, holdPosts: Bool = true) {
        self.eventLoop = eventLoop
        self.holdPosts = holdPosts
    }

    var requests: [ClientRequest] {
        lock.withLock { _requests }
    }

    func requests(_ method: HTTPMethod) -> [ClientRequest] {
        requests.filter { $0.method == method }
    }

    func delegating(to eventLoop: any EventLoop) -> any Client { self }

    func send(_ request: ClientRequest) -> EventLoopFuture<ClientResponse> {
        lock.withLock { _requests.append(request) }
        var headers = HTTPHeaders()
        headers.contentType = .json
        switch request.method {
        case .DELETE:
            return eventLoop.makeSucceededFuture(ClientResponse(status: .accepted, headers: headers))
        case .POST where holdPosts:
            let promise = eventLoop.makePromise(of: ClientResponse.self)
            lock.withLock { held.append(promise) }
            return promise.futureResult
        default:
            let body = ByteBuffer(string: #"[{"timestamp":"1970-01-01T00:00:00.000Z","result":{"count":1}}]"#)
            return eventLoop.makeSucceededFuture(ClientResponse(status: .ok, headers: headers, body: body))
        }
    }

    /// Completes every held request the way Druid does after a cancellation: with an error.
    func releaseHeldRequests() {
        let promises = lock.withLock { () -> [EventLoopPromise<ClientResponse>] in
            defer { held.removeAll() }
            return held
        }
        let body = ByteBuffer(string: #"{"error":"Query cancelled","errorMessage":"Query cancelled"}"#)
        for promise in promises {
            promise.succeed(ClientResponse(status: .internalServerError, body: body))
        }
    }

    /// Polls until `count` requests have been recorded, or fails the test after one second.
    func waitForRequests(count: Int) async throws {
        for _ in 0..<200 where requests.count < count {
            try await Task.sleep(for: .milliseconds(5))
        }
        #expect(requests.count >= count)
    }
}

private struct SentQuery: Decodable {
    struct Context: Decodable {
        let queryId: String?
    }

    let context: Context?
}

private func sentQueryId(_ request: ClientRequest) throws -> String? {
    let body = try #require(request.body)
    return try JSONDecoder().decode(SentQuery.self, from: Data(body.readableBytesView)).context?.queryId
}

@Suite("Query route cancellation tests")
struct QueryRouteCancellationTests {
    static let eventLoop = MultiThreadedEventLoopGroup.singleton.next()

    static let query = CustomQuery(
        queryType: .timeseries,
        dataSource: "com.example.app",
        intervals: [.init(beginningDate: Date(timeIntervalSince1970: 0), endDate: Date(timeIntervalSince1970: 86400))],
        granularity: .day,
        aggregations: [.count(.init(name: "count"))]
    )

    @Test("Every query is sent with a queryId")
    func assignsQueryId() async throws {
        let client = HoldingClient(eventLoop: Self.eventLoop, holdPosts: false)
        let druid = Druid(baseURL: "http://druid/", client: client)

        _ = try await druid.query.execute(query: Self.query)

        let request = try #require(client.requests.first)
        let queryId = try #require(try sentQueryId(request))
        #expect(UUID(uuidString: queryId) != nil)
        #expect(client.requests(.DELETE).isEmpty)
    }

    @Test("A queryId set by the caller is kept")
    func keepsCallerQueryId() async throws {
        let client = HoldingClient(eventLoop: Self.eventLoop, holdPosts: false)
        let druid = Druid(baseURL: "http://druid/", client: client)
        var query = Self.query
        query.context = QueryContext(queryId: "caller-chosen-id")

        _ = try await druid.query.execute(query: query)

        let request = try #require(client.requests.first)
        #expect(try sentQueryId(request) == "caller-chosen-id")
    }

    @Test("Cancelling the task stops waiting, cancels the query on the same broker and throws CancellationError")
    func cancellationIssuesDelete() async throws {
        let client = HoldingClient(eventLoop: Self.eventLoop)
        let druid = Druid(baseURLs: ["http://a/", "http://b/"], client: client)

        let task = Task {
            try await druid.query.execute(query: Self.query)
        }
        try await client.waitForRequests(count: 1)
        let post = try #require(client.requests(.POST).first)
        let queryId = try #require(try sentQueryId(post))

        task.cancel()
        let result = await task.result

        #expect(throws: CancellationError.self) { try result.get() }
        let deletes = client.requests(.DELETE)
        #expect(deletes.count == 1)
        #expect(deletes.first?.url.string == "\(post.url.string.replacingOccurrences(of: "v2/", with: ""))v2/\(queryId)")
        #expect(deletes.first?.url.string.hasPrefix("http://a/") == true)

        // Cancellation is a local decision; it must not blame the server or fail over to another one.
        #expect(client.requests(.POST).count == 1)
        #expect(await druid.serverPool.nextServer(excluding: ["http://b/"]) == "http://a/")

        client.releaseHeldRequests()
    }

    @Test("A task cancelled before the query is sent never reaches the broker")
    func cancelledBeforeSend() async throws {
        let client = HoldingClient(eventLoop: Self.eventLoop)
        let druid = Druid(baseURL: "http://druid/", client: client)

        let task = Task {
            try await Task.sleep(for: .seconds(10))
            return try await druid.query.execute(query: Self.query)
        }
        task.cancel()
        let result = await task.result

        #expect(throws: CancellationError.self) { try result.get() }
        #expect(client.requests.isEmpty)
    }

    @Test("Explicit cancellation by queryId reaches every configured broker")
    func cancelOnAllServers() async throws {
        let client = HoldingClient(eventLoop: Self.eventLoop)
        let druid = Druid(baseURLs: ["http://a/", "http://b/"], client: client)

        await druid.query.cancel(queryId: "abc")

        let urls = client.requests(.DELETE).map(\.url.string).sorted()
        #expect(urls == ["http://a/v2/abc", "http://b/v2/abc"])
    }
}
