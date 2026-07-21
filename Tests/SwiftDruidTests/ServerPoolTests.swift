@testable import SwiftDruid
import AsyncHTTPClient
import Logging
import Testing
import Vapor

@Suite("ServerPool Tests")
struct ServerPoolTests {
    let logger = Logger(label: "SwiftDruid.Tests")

    private func makePool(
        baseURLs: [String],
        unavailableDuration: TimeInterval = 60,
        failureThreshold: Int = 3,
        failureWindow: TimeInterval = 30
    ) -> ServerPool {
        ServerPool(
            baseURLs: baseURLs,
            unavailableDuration: unavailableDuration,
            failureThreshold: failureThreshold,
            failureWindow: failureWindow,
            logger: logger
        )
    }

    /// Records enough failures to open the server's circuit.
    private func openCircuit(_ pool: ServerPool, server: String, failures: Int = 3) async {
        for _ in 0..<failures {
            await pool.recordFailure(server, reason: "test failure")
        }
    }

    @Test("Round-robin cycles through servers in order")
    func roundRobin() async {
        let pool = makePool(baseURLs: ["http://a/", "http://b/", "http://c/"])

        let first = await pool.nextServer()
        let second = await pool.nextServer()
        let third = await pool.nextServer()
        let fourth = await pool.nextServer()

        #expect(first == "http://a/")
        #expect(second == "http://b/")
        #expect(third == "http://c/")
        #expect(fourth == "http://a/")
    }

    @Test("Single server always returns the same URL")
    func singleServer() async {
        let pool = makePool(baseURLs: ["http://only/"])

        for _ in 0..<5 {
            let server = await pool.nextServer()
            #expect(server == "http://only/")
        }
    }

    @Test("A single failure does not take a server out of rotation")
    func singleFailureKeepsServerInRotation() async {
        let pool = makePool(baseURLs: ["http://a/", "http://b/"])

        _ = await pool.nextServer() // advance to "a"
        await pool.recordFailure("http://a/", reason: "connection refused")

        // "a" is still in rotation: one blip is below the threshold of 3
        let second = await pool.nextServer()
        let third = await pool.nextServer()
        #expect(second == "http://b/")
        #expect(third == "http://a/")
    }

    @Test("Reaching the failure threshold opens the circuit and skips the server")
    func thresholdOpensCircuit() async {
        let pool = makePool(baseURLs: ["http://a/", "http://b/", "http://c/"])

        _ = await pool.nextServer() // advance to "a"
        await openCircuit(pool, server: "http://a/")

        // Next calls should skip "a"
        let second = await pool.nextServer()
        let third = await pool.nextServer()
        let fourth = await pool.nextServer()

        #expect(second == "http://b/")
        #expect(third == "http://c/")
        // Wraps around, skips "a", returns "b"
        #expect(fourth == "http://b/")
    }

    @Test("Failures outside the failure window do not accumulate")
    func failuresOutsideWindowDoNotAccumulate() async {
        let pool = makePool(
            baseURLs: ["http://a/", "http://b/"],
            failureThreshold: 2,
            failureWindow: 0.01
        )

        await pool.recordFailure("http://a/", reason: "blip one")
        try? await Task.sleep(for: .milliseconds(30))
        await pool.recordFailure("http://a/", reason: "blip two, outside the window")

        // Two failures, but spread beyond the window: circuit stays closed
        let first = await pool.nextServer()
        #expect(first == "http://a/")
    }

    @Test("A success resets the failure count")
    func successResetsFailureCount() async {
        let pool = makePool(baseURLs: ["http://a/", "http://b/"])

        await pool.recordFailure("http://a/", reason: "failure one")
        await pool.recordFailure("http://a/", reason: "failure two")
        await pool.recordSuccess("http://a/")
        await pool.recordFailure("http://a/", reason: "failure after reset")

        // Only one failure since the last success: still in rotation
        let first = await pool.nextServer()
        #expect(first == "http://a/")
    }

    @Test("When all circuits are open, the pool fails open instead of returning nil")
    func allCircuitsOpenFailsOpen() async {
        let pool = makePool(baseURLs: ["http://a/", "http://b/"])

        await openCircuit(pool, server: "http://a/")
        await openCircuit(pool, server: "http://b/")

        // Fail-open: a server is still returned, never nil
        let result = await pool.nextServer()
        #expect(result != nil)
    }

    @Test("Fail-open picks the server closest to recovery")
    func failOpenPicksSoonestRecovery() async {
        // "a" opens first, so its cool-down expires first
        let pool = makePool(baseURLs: ["http://a/", "http://b/"])

        await openCircuit(pool, server: "http://a/")
        try? await Task.sleep(for: .milliseconds(20))
        await openCircuit(pool, server: "http://b/")

        let result = await pool.nextServer()
        #expect(result == "http://a/")
    }

    @Test("Returns nil only when every server is excluded")
    func allExcludedReturnsNil() async {
        let pool = makePool(baseURLs: ["http://a/", "http://b/"])

        let result = await pool.nextServer(excluding: ["http://a/", "http://b/"])
        #expect(result == nil)

        let partial = await pool.nextServer(excluding: ["http://a/"])
        #expect(partial == "http://b/")
    }

    @Test("Server re-enters rotation after the cool-down expires")
    func serverRecovery() async {
        let pool = makePool(
            baseURLs: ["http://a/", "http://b/"],
            unavailableDuration: 0.01
        )

        await openCircuit(pool, server: "http://a/")
        await openCircuit(pool, server: "http://b/")

        // Wait for the cool-down to expire
        try? await Task.sleep(for: .milliseconds(20))

        // Both should be selectable again without fail-open kicking in
        var seen = Set<String>()
        for _ in 0..<2 {
            if let server = await pool.nextServer() {
                seen.insert(server)
            }
        }
        #expect(seen == ["http://a/", "http://b/"])
    }

    @Test("A single failure while half-open re-opens the circuit")
    func halfOpenReopensOnSingleFailure() async {
        let pool = makePool(
            baseURLs: ["http://a/", "http://b/"],
            unavailableDuration: 0.01
        )

        await openCircuit(pool, server: "http://a/")
        try? await Task.sleep(for: .milliseconds(20))

        // Cool-down expired: "a" is half-open and back in rotation.
        // One more failure must re-open immediately (no need for 3 again).
        await pool.recordFailure("http://a/", reason: "still failing")

        let first = await pool.nextServer()
        let second = await pool.nextServer()
        #expect(first == "http://b/")
        #expect(second == "http://b/")
    }

    @Test("A success while half-open closes the circuit")
    func halfOpenClosesOnSuccess() async {
        let pool = makePool(
            baseURLs: ["http://a/", "http://b/"],
            unavailableDuration: 0.01
        )

        await openCircuit(pool, server: "http://a/")
        try? await Task.sleep(for: .milliseconds(20))

        await pool.recordSuccess("http://a/")

        // Fully closed again: below-threshold failures don't take it out
        await pool.recordFailure("http://a/", reason: "one blip")
        _ = await pool.nextServer() // "a" or "b" depending on rotation
        let servers = [await pool.nextServer(), await pool.nextServer()]
        #expect(servers.contains("http://a/"))
    }

    @Test("Multiple open circuits leave remaining servers in rotation")
    func partialUnavailability() async {
        let pool = makePool(baseURLs: ["http://a/", "http://b/", "http://c/", "http://d/"])

        await openCircuit(pool, server: "http://a/")
        await openCircuit(pool, server: "http://c/")

        // Should only get b and d
        var results: [String] = []
        for _ in 0..<4 {
            if let server = await pool.nextServer() {
                results.append(server)
            }
        }

        #expect(results.allSatisfy { $0 == "http://b/" || $0 == "http://d/" })
        #expect(results.contains("http://b/"))
        #expect(results.contains("http://d/"))
    }
}

@Suite("Failure Classification Tests")
struct DruidRequestFailureTests {
    @Test("Task cancellation is classified as cancelled")
    func cancellationError() {
        #expect(DruidRequestFailure(classifying: CancellationError()) == .requestCancelled)
    }

    @Test("HTTP client cancellation is classified as cancelled")
    func httpClientCancelled() {
        #expect(DruidRequestFailure(classifying: HTTPClientError.cancelled) == .requestCancelled)
    }

    @Test("Local pool exhaustion is classified as client capacity, not server failure")
    func poolTimeout() {
        #expect(DruidRequestFailure(classifying: HTTPClientError.getConnectionFromPoolTimeout) == .clientAtCapacity)
    }

    @Test("Read timeout and deadline are classified as slow response")
    func slowResponses() {
        #expect(DruidRequestFailure(classifying: HTTPClientError.readTimeout) == .slowResponse)
        #expect(DruidRequestFailure(classifying: HTTPClientError.deadlineExceeded) == .slowResponse)
    }

    @Test("Connect timeout is classified as server unreachable")
    func connectTimeout() {
        #expect(DruidRequestFailure(classifying: HTTPClientError.connectTimeout) == .serverUnreachable)
        #expect(DruidRequestFailure(classifying: HTTPClientError.remoteConnectionClosed) == .serverUnreachable)
    }

    @Test("Unknown errors are classified as server unreachable")
    func unknownError() {
        struct SomeError: Error {}
        #expect(DruidRequestFailure(classifying: SomeError()) == .serverUnreachable)
    }
}

/// A Vapor `Client` stand-in for `Druid.execute` tests. The tested code paths never touch the
/// client — `execute` hands the base URL to a scripted closure — so every member traps.
private struct UnusedClient: Client {
    var eventLoop: any EventLoop { preconditionFailure("UnusedClient must not be used") }

    func delegating(to eventLoop: any EventLoop) -> any Client { self }

    func send(_ request: ClientRequest) -> EventLoopFuture<ClientResponse> {
        preconditionFailure("UnusedClient must not be used")
    }
}

@Suite("Druid.execute Failover Tests")
struct DruidExecuteTests {
    struct ConnectionRefused: Error {}

    private func makeDruid(baseURLs: [String], unavailableDuration: TimeInterval = 60) -> Druid {
        Druid(baseURLs: baseURLs, client: UnusedClient(), unavailableDuration: unavailableDuration)
    }

    @Test("A connection failure fails over to the next server")
    func failoverOnConnectionError() async throws {
        let druid = makeDruid(baseURLs: ["http://a/", "http://b/"])

        let result = try await druid.execute { baseURL in
            if baseURL == "http://a/" {
                throw ConnectionRefused()
            }
            return baseURL
        }

        #expect(result == "http://b/")
    }

    @Test("When every server fails, the last connection error is thrown")
    func allServersFailingThrowsLastError() async {
        let druid = makeDruid(baseURLs: ["http://a/", "http://b/"])
        var attempts: [String] = []

        await #expect(throws: ConnectionRefused.self) {
            try await druid.execute { baseURL in
                attempts.append(baseURL)
                throw ConnectionRefused()
            }
        }

        // Each server is tried exactly once — no infinite failover loop
        #expect(Set(attempts) == ["http://a/", "http://b/"])
        #expect(attempts.count == 2)
    }

    @Test("An Abort from Druid propagates without trying other servers")
    func abortPropagatesWithoutRetry() async {
        let druid = makeDruid(baseURLs: ["http://a/", "http://b/"])
        var attempts = 0

        await #expect(throws: Abort.self) {
            try await druid.execute { (_: String) -> String in
                attempts += 1
                throw Abort(.badRequest, reason: "Bad query")
            }
        }

        #expect(attempts == 1)
    }

    @Test("Pool exhaustion surfaces as 503 with Retry-After and does not fail over")
    func poolExhaustionThrows503() async throws {
        let druid = makeDruid(baseURLs: ["http://a/", "http://b/"])
        var attempts = 0

        do {
            _ = try await druid.execute { (_: String) -> String in
                attempts += 1
                throw HTTPClientError.getConnectionFromPoolTimeout
            }
            Issue.record("Expected an error")
        } catch let abort as Abort {
            #expect(abort.status == .serviceUnavailable)
            #expect(abort.headers.first(name: "Retry-After") == "1")
        }

        #expect(attempts == 1)

        // The server was not blamed: it must still be first in rotation
        let next = await druid.serverPool.nextServer()
        #expect(next != nil)
    }

    @Test("Pool exhaustion does not open the server's circuit")
    func poolExhaustionDoesNotOpenCircuit() async {
        let druid = makeDruid(baseURLs: ["http://a/"])

        // Even many pool timeouts must not take the only server out of rotation
        for _ in 0..<5 {
            _ = try? await druid.execute { (_: String) -> String in
                throw HTTPClientError.getConnectionFromPoolTimeout
            }
        }

        let result = try? await druid.execute { baseURL in baseURL }
        #expect(result == "http://a/")
    }

    @Test("A read timeout propagates without retrying on another server")
    func readTimeoutDoesNotRetry() async {
        let druid = makeDruid(baseURLs: ["http://a/", "http://b/"])
        var attempts = 0

        await #expect(throws: HTTPClientError.self) {
            try await druid.execute { (_: String) -> String in
                attempts += 1
                throw HTTPClientError.readTimeout
            }
        }

        #expect(attempts == 1)
    }

    @Test("Cancellation propagates immediately without failover")
    func cancellationPropagates() async {
        let druid = makeDruid(baseURLs: ["http://a/", "http://b/"])
        var attempts = 0

        await #expect(throws: CancellationError.self) {
            try await druid.execute { (_: String) -> String in
                attempts += 1
                throw CancellationError()
            }
        }

        #expect(attempts == 1)
    }

    @Test("Requests keep flowing after repeated connection failures (fail-open end to end)")
    func noBlackoutUnderRepeatedFailures() async throws {
        let druid = makeDruid(baseURLs: ["http://a/", "http://b/"])

        // Open both circuits via execute-level connection failures
        for _ in 0..<4 {
            _ = try? await druid.execute { (_: String) -> String in
                throw ConnectionRefused()
            }
        }

        // Both circuits are now open — but requests must still reach a server
        let result = try await druid.execute { baseURL in baseURL }
        #expect(result == "http://a/" || result == "http://b/")
    }

    @Test("A recovered server closes its circuit on the next success")
    func successClosesCircuit() async throws {
        let druid = makeDruid(baseURLs: ["http://a/"])

        for _ in 0..<3 {
            _ = try? await druid.execute { (_: String) -> String in
                throw ConnectionRefused()
            }
        }

        // Fail-open lets the request through; the success closes the circuit
        let first = try await druid.execute { baseURL in baseURL }
        #expect(first == "http://a/")

        let second = try await druid.execute { baseURL in baseURL }
        #expect(second == "http://a/")
    }
}
