import Foundation
import NIOConcurrencyHelpers
import NIOPosix
@testable import SwiftDruid
import Testing
import Vapor

/// A Vapor `Client` that answers `DELETE` requests with `202 Accepted` right away but keeps
/// every `POST` pending until `releaseHeldRequests()` is called, so a test can cancel a task
/// while its query is "running on the broker".
final class HoldingClient: Client, @unchecked Sendable {
    let eventLoop: any EventLoop
    private let lock = NIOLock()
    private var _requests: [ClientRequest] = []
    private var held: [EventLoopPromise<ClientResponse>] = []
    private let holdPosts: Bool
    private let responseBody: String

    /// - Parameters:
    ///   - holdPosts: Keep `POST` requests pending until `releaseHeldRequests()`.
    ///   - responseBody: The body a `POST` is answered with when it is not held; a native
    ///     timeseries result by default.
    init(
        eventLoop: any EventLoop,
        holdPosts: Bool = true,
        responseBody: String = #"[{"timestamp":"1970-01-01T00:00:00.000Z","result":{"count":1}}]"#
    ) {
        self.eventLoop = eventLoop
        self.holdPosts = holdPosts
        self.responseBody = responseBody
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
            let body = ByteBuffer(string: responseBody)
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
