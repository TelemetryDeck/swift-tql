import Vapor

public struct SupervisorRoutes {
    let druid: Druid

    public func list() async throws -> [String] {
        let uri = URI(string: "\(druid.baseURL)indexer/v1/supervisor")

        let response = try await druid.client.get(uri)
        guard response.status == .ok else {
            throw Abort(.internalServerError, reason: "Failed to get active supervisors")
        }

        return try response.content.decode([String].self)
    }

    public func terminate(supervisor: String) async throws {
        let uri = URI(string: "\(druid.baseURL)indexer/v1/supervisor/\(supervisor)/terminate")

        let response = try await druid.client.post(uri)
        guard response.status == .ok else {
            throw Abort(.internalServerError, reason: "Failed to terminate supervisor: \(supervisor)")
        }
    }
}
