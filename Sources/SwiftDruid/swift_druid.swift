import Vapor

public struct DruidError: Codable, Equatable {
    let error: String?
    let errorClass: String?
    let host: String?
    let errorCode: String?
    let persona: String?
    let category: String?
    let errorMessage: String?
}

public struct Druid {
    public init(baseURL: String, client: any Client) {
        self.baseURL = baseURL
        self.client = client
    }

    public let baseURL: String
    public let client: Client

    public var sql: SQLRoutes { .init(druid: self) }
    public var supervisors: SupervisorRoutes { .init(druid: self) }
    public var compaction: CompactionRoutes { .init(druid: self) }
}
