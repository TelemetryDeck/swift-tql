import Vapor

public extension Druid {
    func listSupervisors() async throws -> [String] {
        let uri = URI(string: "\(baseURL)indexer/v1/supervisor")

        let response = try await client.get(uri)
        guard response.status == .ok else {
            throw Abort(.internalServerError, reason: "Failed to get active supervisors")
        }

        return try response.content.decode([String].self)
    }
}
