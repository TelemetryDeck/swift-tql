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

/// Manages a pool of Druid servers with round-robin selection and health tracking.
public actor ServerPool {
    private struct ServerState {
        let baseURL: String
        var unavailableUntil: Date?

        var isAvailable: Bool {
            guard let until = unavailableUntil else { return true }
            return Date() >= until
        }
    }

    private var servers: [ServerState]
    private var nextIndex: Int = 0
    private let unavailableDuration: TimeInterval
    private let logger: Logger

    init(baseURLs: [String], unavailableDuration: TimeInterval, logger: Logger) {
        self.servers = baseURLs.map { ServerState(baseURL: $0) }
        self.unavailableDuration = unavailableDuration
        self.logger = logger
    }

    /// Returns the next available server using round-robin, or nil if all servers are unavailable.
    func nextServer() -> String? {
        let count = servers.count
        for _ in 0..<count {
            let index = nextIndex % count
            nextIndex += 1
            if servers[index].isAvailable {
                return servers[index].baseURL
            }
        }
        return nil
    }

    /// Marks a server as unavailable for the configured duration.
    func markUnavailable(_ baseURL: String) {
        if let index = servers.firstIndex(where: { $0.baseURL == baseURL }) {
            servers[index].unavailableUntil = Date().addingTimeInterval(unavailableDuration)
            logger.warning("Druid server marked unavailable", metadata: [
                "server": .string(baseURL),
                "unavailable_for_seconds": .stringConvertible(unavailableDuration),
            ])
        }
    }
}

public struct Druid {
    /// Initialize with a single Druid server URL.
    public init(baseURL: String, client: any Client, unavailableDuration: TimeInterval = 60) {
        self.baseURLs = [baseURL]
        self.client = client
        self.serverPool = ServerPool(
            baseURLs: [baseURL],
            unavailableDuration: unavailableDuration,
            logger: Logger(label: "SwiftDruid")
        )
    }

    /// Initialize with multiple Druid server URLs for load balancing.
    /// Requests are distributed across servers using round-robin.
    /// If a server fails with a connection error, it is marked as unavailable
    /// for `unavailableDuration` seconds and the request is retried on the next server.
    public init(baseURLs: [String], client: any Client, unavailableDuration: TimeInterval = 60) {
        precondition(!baseURLs.isEmpty, "At least one Druid server URL must be provided")
        self.baseURLs = baseURLs
        self.client = client
        self.serverPool = ServerPool(
            baseURLs: baseURLs,
            unavailableDuration: unavailableDuration,
            logger: Logger(label: "SwiftDruid")
        )
    }

    public let baseURLs: [String]

    /// The first configured server URL. Provided for backward compatibility.
    public var baseURL: String { baseURLs[0] }

    public let client: Client
    let serverPool: ServerPool

    private let logger = Logger(label: "SwiftDruid")

    /// Execute an operation against an available Druid server with automatic failover.
    ///
    /// The operation receives a base URL and should make its HTTP request using that URL.
    /// If the operation throws an `Abort` error (indicating a Druid-level error response),
    /// it is propagated immediately. Any other error is treated as a connection failure:
    /// the server is marked unavailable and the request is retried on the next server.
    ///
    /// - Parameter operation: A closure that performs the HTTP request given a server base URL.
    /// - Returns: The result of the operation.
    /// - Throws: The Druid error if the server responded with an error, or the last connection
    ///   error if all servers are unavailable.
    public func execute<T>(_ operation: (String) async throws -> T) async throws -> T {
        var lastError: Error?

        while let baseURL = await serverPool.nextServer() {
            do {
                return try await operation(baseURL)
            } catch let error as Abort {
                // Druid responded with an error — don't retry on other servers
                throw error
            } catch {
                // Connection failure — mark server unavailable and try the next one
                logger.error("Druid connection failed", metadata: [
                    "server": .string(baseURL),
                    "error": .string(String(describing: error)),
                ])
                await serverPool.markUnavailable(baseURL)
                lastError = error
            }
        }

        throw lastError ?? Abort(.serviceUnavailable, reason: "No Druid servers available")
    }

    public var sql: SQLRoutes { .init(druid: self) }
    public var supervisors: SupervisorRoutes { .init(druid: self) }
    public var dataSources: DataSourcesRoutes { .init(druid: self) }
    public var compaction: CompactionRoutes { .init(druid: self) }
    public var overlord: OverlordRoutes { .init(druid: self) }
}
