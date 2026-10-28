import AsyncHTTPClient
import Logging
import Vapor

public struct DruidError: Codable, Equatable, LocalizedError {
    let error: String?
    let errorClass: String?
    let host: String?
    let errorCode: String?
    let persona: String?
    let category: String?
    let errorMessage: String?

    public var errorDescription: String? {
        let parts: [(String, String?)] = [
            ("Error", error),
            ("Message", errorMessage),
            ("Code", errorCode),
            ("Class", errorClass),
            ("Category", category),
            ("Host", host),
            ("Persona", persona),
        ]
        let description = parts
            .compactMap { label, value in value.map { "\(label): \($0)" } }
            .joined(separator: ", ")
        return description.isEmpty ? "Unknown Druid error" : description
    }
}

/// Classifies a failed request so the failover layer reacts appropriately.
///
/// Only genuine connection-level failures are evidence that a server might be down. Errors that
/// originate on our side of the wire (an exhausted local connection pool, a cancelled task) or that
/// merely mean "the query is slow" must never take a server out of rotation — misclassifying them
/// is how a burst of queries can black out the whole pool.
enum DruidRequestFailure: Equatable {
    /// The server could not be reached (connect timeout, connection refused, DNS, TLS, reset).
    /// Counts toward opening the server's circuit; the request is retried on the next server.
    case serverUnreachable
    /// The local HTTP client has no free connection for this host. Says nothing about the server's
    /// health; surfaces as a 503 so callers back off, without retrying or marking anything.
    case clientAtCapacity
    /// The request was cancelled on our side. Propagated immediately.
    case requestCancelled
    /// The server accepted the request but did not answer before the client's read timeout or
    /// deadline. The query already ran once, so it is not retried on another server — re-running a
    /// multi-minute query elsewhere doubles cluster load exactly when the cluster is slowest.
    case slowResponse

    init(classifying error: any Error) {
        if error is CancellationError {
            self = .requestCancelled
        } else if let clientError = error as? HTTPClientError {
            switch clientError {
            case .getConnectionFromPoolTimeout:
                self = .clientAtCapacity
            case .cancelled:
                self = .requestCancelled
            case .readTimeout, .deadlineExceeded:
                self = .slowResponse
            default:
                self = .serverUnreachable
            }
        } else {
            self = .serverUnreachable
        }
    }
}

/// Manages a pool of Druid servers with round-robin selection and a per-server circuit breaker.
///
/// A server's circuit opens after `failureThreshold` connection failures within `failureWindow`
/// seconds, taking it out of rotation for `unavailableDuration` seconds. Once that cool-down
/// expires the server re-enters rotation in a half-open state: a successful response closes the
/// circuit, while a single further connection failure re-opens it immediately.
///
/// The pool never fails fast to zero: when every server's circuit is open, `nextServer(excluding:)`
/// falls back to the server closest to recovery instead of returning nil, so the worst case is a
/// slow error rather than a guaranteed blackout.
public actor ServerPool {
    private struct ServerState {
        let baseURL: String
        var consecutiveFailures: Int = 0
        var lastFailureAt: Date?
        var unavailableUntil: Date?

        /// `unavailableUntil` deliberately stays set after it expires (half-open) until a success
        /// clears it, so `recordFailure` can tell half-open from closed.
        func isInRotation(at now: Date) -> Bool {
            guard let until = unavailableUntil else { return true }
            return now >= until
        }
    }

    private var servers: [ServerState]
    private var nextIndex: Int = 0
    private let unavailableDuration: TimeInterval
    private let failureThreshold: Int
    private let failureWindow: TimeInterval
    private let logger: Logger

    init(
        baseURLs: [String],
        unavailableDuration: TimeInterval,
        failureThreshold: Int = 3,
        failureWindow: TimeInterval = 30,
        logger: Logger
    ) {
        self.servers = baseURLs.map { ServerState(baseURL: $0) }
        self.unavailableDuration = unavailableDuration
        self.failureThreshold = max(1, failureThreshold)
        self.failureWindow = failureWindow
        self.logger = logger
    }

    /// Returns the next server to try: round-robin over servers in rotation, skipping those in
    /// `excluding` (already tried by the current request). When every non-excluded server's circuit
    /// is open, fails open and returns the server closest to recovery. Returns nil only when every
    /// server has been excluded.
    func nextServer(excluding: Set<String> = []) -> String? {
        let now = Date()
        let count = servers.count
        var fallback: (baseURL: String, until: Date)?

        for _ in 0..<count {
            let index = nextIndex % count
            nextIndex += 1
            let server = servers[index]
            guard !excluding.contains(server.baseURL) else { continue }

            if server.isInRotation(at: now) {
                return server.baseURL
            }

            if let until = server.unavailableUntil, until < (fallback?.until ?? .distantFuture) {
                fallback = (server.baseURL, until)
            }
        }

        guard let fallback else { return nil }
        logger.warning("All Druid servers have open circuits — failing open", metadata: [
            "server": .string(fallback.baseURL),
        ])
        return fallback.baseURL
    }

    /// Records a connection-level failure. Opens the circuit once `failureThreshold` failures
    /// accumulate within `failureWindow`; while half-open, a single failure re-opens it.
    func recordFailure(_ baseURL: String, reason: String) {
        guard let index = servers.firstIndex(where: { $0.baseURL == baseURL }) else { return }
        let now = Date()
        var server = servers[index]

        // Outside an open/half-open circuit, forget stale failures so occasional blips spread over
        // a long period never open the circuit.
        if server.unavailableUntil == nil,
           let lastFailureAt = server.lastFailureAt,
           now.timeIntervalSince(lastFailureAt) > failureWindow {
            server.consecutiveFailures = 0
        }

        server.consecutiveFailures += 1
        server.lastFailureAt = now

        if server.consecutiveFailures >= failureThreshold {
            server.unavailableUntil = now.addingTimeInterval(unavailableDuration)
            logger.warning("Druid server circuit opened", metadata: [
                "server": .string(baseURL),
                "consecutive_failures": .stringConvertible(server.consecutiveFailures),
                "unavailable_for_seconds": .stringConvertible(unavailableDuration),
                "error": .string(reason),
            ])
        } else {
            logger.notice("Druid server connection failure", metadata: [
                "server": .string(baseURL),
                "consecutive_failures": .stringConvertible(server.consecutiveFailures),
                "failure_threshold": .stringConvertible(failureThreshold),
                "error": .string(reason),
            ])
        }

        servers[index] = server
    }

    /// Records a successful response — including a Druid-level error response, which still proves
    /// the server is reachable — closing the circuit and resetting the failure count.
    func recordSuccess(_ baseURL: String) {
        guard let index = servers.firstIndex(where: { $0.baseURL == baseURL }) else { return }
        if servers[index].unavailableUntil != nil {
            logger.info("Druid server circuit closed", metadata: [
                "server": .string(baseURL),
            ])
        }
        servers[index].consecutiveFailures = 0
        servers[index].lastFailureAt = nil
        servers[index].unavailableUntil = nil
    }
}

public struct Druid: Sendable {
    /// Initialize with a single Druid server URL.
    public init(
        baseURL: String,
        client: any Client,
        unavailableDuration: TimeInterval = 60,
        failureThreshold: Int = 3,
        failureWindow: TimeInterval = 30
    ) {
        self.init(
            baseURLs: [baseURL],
            client: client,
            unavailableDuration: unavailableDuration,
            failureThreshold: failureThreshold,
            failureWindow: failureWindow
        )
    }

    /// Initialize with multiple Druid server URLs for load balancing.
    /// Requests are distributed across servers using round-robin.
    /// If a server accumulates `failureThreshold` connection failures within `failureWindow`
    /// seconds, it is taken out of rotation for `unavailableDuration` seconds and requests are
    /// retried on the remaining servers.
    public init(
        baseURLs: [String],
        client: any Client,
        unavailableDuration: TimeInterval = 60,
        failureThreshold: Int = 3,
        failureWindow: TimeInterval = 30
    ) {
        precondition(!baseURLs.isEmpty, "At least one Druid server URL must be provided")
        self.baseURLs = baseURLs
        self.client = client
        self.serverPool = ServerPool(
            baseURLs: baseURLs,
            unavailableDuration: unavailableDuration,
            failureThreshold: failureThreshold,
            failureWindow: failureWindow,
            logger: Logger(label: "SwiftDruid")
        )
    }

    public let baseURLs: [String]

    /// The first configured server URL. Provided for backward compatibility.
    public var baseURL: String { baseURLs[0] }

    public let client: Client
    let serverPool: ServerPool

    let logger = Logger(label: "SwiftDruid")

    /// Execute an operation against an available Druid server with automatic failover.
    ///
    /// The operation receives a base URL and should make its HTTP request using that URL.
    /// Failures are classified before the server pool reacts:
    /// - An `Abort` means Druid itself responded (with an error). It is propagated immediately and
    ///   counts as proof that the server is reachable.
    /// - Connection-level failures (connect timeout/refused, DNS, TLS, resets) count toward opening
    ///   the server's circuit, and the request is retried on the next server.
    /// - Local conditions are never blamed on the server: an exhausted local connection pool
    ///   surfaces as a 503 with `Retry-After`, cancellation propagates immediately, and a read
    ///   timeout propagates without a retry (the query already ran once).
    ///
    /// Each server is tried at most once per request. If every server fails with a connection
    /// error, the last connection error is thrown.
    ///
    /// - Parameter operation: A closure that performs the HTTP request given a server base URL.
    /// - Returns: The result of the operation.
    public func execute<T>(_ operation: (String) async throws -> T) async throws -> T {
        var lastError: Error?
        var tried = Set<String>()

        while let baseURL = await serverPool.nextServer(excluding: tried) {
            tried.insert(baseURL)

            do {
                let result = try await operation(baseURL)
                await serverPool.recordSuccess(baseURL)
                return result
            } catch let error as Abort {
                // Druid responded with an error — the server is reachable; don't retry elsewhere.
                await serverPool.recordSuccess(baseURL)
                throw error
            } catch {
                switch DruidRequestFailure(classifying: error) {
                case .serverUnreachable:
                    logger.error("Druid connection failed", metadata: [
                        "server": .string(baseURL),
                        "error": .string(String(describing: error)),
                    ])
                    await serverPool.recordFailure(baseURL, reason: String(describing: error))
                    lastError = error
                case .clientAtCapacity:
                    logger.warning("Local connection pool for Druid server exhausted", metadata: [
                        "server": .string(baseURL),
                    ])
                    throw Abort(
                        .serviceUnavailable,
                        headers: ["Retry-After": "1"],
                        reason: "The query engine is at capacity right now. Please retry in a moment."
                    )
                case .requestCancelled:
                    throw error
                case .slowResponse:
                    logger.warning("Druid server did not answer before the client timeout", metadata: [
                        "server": .string(baseURL),
                        "error": .string(String(describing: error)),
                    ])
                    throw error
                }
            }
        }

        throw lastError ?? Abort(.serviceUnavailable, reason: "No Druid servers available")
    }

    public var sql: SQLRoutes { .init(druid: self) }
    public var query: QueryRoutes { .init(druid: self) }
    public var supervisors: SupervisorRoutes { .init(druid: self) }
    public var dataSources: DataSourcesRoutes { .init(druid: self) }
    public var compaction: CompactionRoutes { .init(druid: self) }
    public var overlord: OverlordRoutes { .init(druid: self) }
    /// Read-only Coordinator metadata routes (segment intervals, sizes, counts).
    public var coordinator: CoordinatorRoutes { .init(druid: self) }
    /// Per-datasource retention (load/drop) rules on the Coordinator.
    public var retentionRules: RetentionRuleRoutes { .init(druid: self) }
}
