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

    public func list() async throws -> [String] {
        return try await withSpan("Druid.Supervisor.list") { _ in
            let uri = URI(string: "\(druid.baseURL)indexer/v1/supervisor")

            let response = try await druid.client.get(uri)
            guard response.status == .ok else {
                throw Abort(.internalServerError, reason: "Failed to get active supervisors")
            }

            return try response.content.decode([String].self)
        }
    }

    public func get(supervisor: String) async throws -> SupervisorReturnType? {
        return try await withSpan("Druid.Supervisor.get") { _ in
            let uri = URI(string: "\(druid.baseURL)indexer/v1/supervisor/\(supervisor)")

            let response = try await druid.client.get(uri)

            if response.status == .notFound { return nil }
            guard response.status == .ok else {
                throw Abort(.internalServerError, reason: "Failed to get supervisor: \(supervisor)")
            }

            return try response.content.decode(SupervisorReturnType.self)
        }
    }

    public func create(spec: Supervisor) async throws {
        try await withSpan("Druid.Supervisor.create") { _ in
            let uri = URI(string: "\(druid.baseURL)indexer/v1/supervisor")

            let response = try await druid.client.post(uri, content: spec)
            guard response.status == .ok else {
                throw Abort(.internalServerError, reason: "Failed to get active supervisors")
            }

            return try response.content.decode([String].self)
        }
    }

    public func terminate(supervisor: String) async throws {
        try await withSpan("Druid.Supervisor.terminate") { _ in
            let uri = URI(string: "\(druid.baseURL)indexer/v1/supervisor/\(supervisor)/terminate")

            let response = try await druid.client.post(uri)
            guard response.status == .ok else {
                throw Abort(.internalServerError, reason: "Failed to terminate supervisor: \(supervisor)")
            }
        }
    }
}

extension Supervisor: Vapor.Content {}
