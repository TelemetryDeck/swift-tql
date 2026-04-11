import SwiftTQL
import Tracing
import Vapor

public struct SupervisorRoutes {
    let druid: Druid

    public struct SupervisorReturnType: Codable, Content {
        public let type: Supervisor.SupervisorType
        public let id: String
        public let spec: SpecReturnType

        public struct SpecReturnType: Codable, Content {
            public let ioConfig: IoConfigReturnType
        }

        public struct IoConfigReturnType: Codable, Content {
            public let topic: String?
        }
    }

    public struct SupervisorStatus: Codable, Content {
        public let id: String
        public let generationTime: String?
        public let payload: Payload

        public struct Payload: Content {
            public let dataSource: String
            public let stream: String?
            public let partitions: Int?
            public let replicas: Int?
            public let aggregateLag: Int?
            public let suspended: Bool
            public let healthy: Bool
            public let state: String
            public let detailedState: String?
        }
    }

    public func list() async throws -> [String] {
        return try await druid.execute { baseURL in
            try await withSpan("Druid.Supervisor.list") { _ in
                let uri = URI(string: "\(baseURL)indexer/v1/supervisor")

                let response = try await druid.client.get(uri)
                guard response.status == .ok else {
                    if let error = try? response.content.decode(DruidError.self) {
                        throw Abort(response.status, reason: error.localizedDescription)
                    } else {
                        throw Abort(.internalServerError, reason: "Failed to list supervisors")
                    }
                }

                return try response.content.decode([String].self)
            }
        }
    }

    public func get(supervisor: String) async throws -> SupervisorReturnType? {
        return try await druid.execute { baseURL in
            try await withSpan("Druid.Supervisor.get") { _ in
                let uri = URI(string: "\(baseURL)indexer/v1/supervisor/\(supervisor)")

                let response = try await druid.client.get(uri)

                if response.status == .notFound { return nil }
                guard response.status == .ok else {
                    if let error = try? response.content.decode(DruidError.self) {
                        throw Abort(response.status, reason: error.localizedDescription)
                    } else {
                        throw Abort(.internalServerError, reason: "Failed to get supervisor \(supervisor)")
                    }
                }

                return try response.content.decode(SupervisorReturnType.self)
            }
        }
    }

    public func status(supervisor: String) async throws -> SupervisorStatus? {
        return try await druid.execute { baseURL in
            try await withSpan("Druid.Supervisor.status") { _ in
                let uri = URI(string: "\(baseURL)indexer/v1/supervisor/\(supervisor)/status")

                let response = try await druid.client.get(uri)

                if response.status == .notFound { return nil }
                guard response.status == .ok else {
                    if let error = try? response.content.decode(DruidError.self) {
                        throw Abort(response.status, reason: error.localizedDescription)
                    } else {
                        throw Abort(.internalServerError, reason: "Failed to get supervisor status for \(supervisor)")
                    }
                }
                return try response.content.decode(SupervisorStatus.self)
            }
        }
    }

    public func create(spec: Supervisor) async throws {
        try await druid.execute { baseURL in
            try await withSpan("Druid.Supervisor.create") { _ in
                let uri = URI(string: "\(baseURL)indexer/v1/supervisor")

                let response = try await druid.client.post(uri, content: spec)
                guard response.status == .ok else {
                    if let error = try? response.content.decode(DruidError.self) {
                        throw Abort(response.status, reason: error.localizedDescription)
                    } else {
                        throw Abort(.internalServerError, reason: "Failed to create supervisor")
                    }
                }
            }
        }
    }

    public func suspend(supervisor: String) async throws {
        try await druid.execute { baseURL in
            try await withSpan("Druid.Supervisor.suspend") { _ in
                let uri = URI(string: "\(baseURL)indexer/v1/supervisor/\(supervisor)/suspend")

                let response = try await druid.client.post(uri)
                guard response.status == .ok else {
                    if let error = try? response.content.decode(DruidError.self) {
                        throw Abort(response.status, reason: error.localizedDescription)
                    } else {
                        throw Abort(.internalServerError, reason: "Failed to suspend supervisor \(supervisor)")
                    }
                }
            }
        }
    }

    public func resume(supervisor: String) async throws {
        try await druid.execute { baseURL in
            try await withSpan("Druid.Supervisor.resume") { _ in
                let uri = URI(string: "\(baseURL)indexer/v1/supervisor/\(supervisor)/resume")

                let response = try await druid.client.post(uri)
                guard response.status == .ok else {
                    if let error = try? response.content.decode(DruidError.self) {
                        throw Abort(response.status, reason: error.localizedDescription)
                    } else {
                        throw Abort(.internalServerError, reason: "Failed to resume supervisor \(supervisor)")
                    }
                }
            }
        }
    }

    public func terminate(supervisor: String) async throws {
        try await druid.execute { baseURL in
            try await withSpan("Druid.Supervisor.terminate") { _ in
                let uri = URI(string: "\(baseURL)indexer/v1/supervisor/\(supervisor)/terminate")

                let response = try await druid.client.post(uri)
                guard response.status == .ok else {
                    if let error = try? response.content.decode(DruidError.self) {
                        throw Abort(response.status, reason: error.localizedDescription)
                    } else {
                        throw Abort(.internalServerError, reason: "Failed to terminate supervisor \(supervisor)")
                    }
                }
            }
        }
    }
}

extension Supervisor: Vapor.Content {}
