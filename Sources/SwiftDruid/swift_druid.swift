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

public struct Druid {
    public init(baseURL: String, client: any Client) {
        self.baseURL = baseURL
        self.client = client
    }

    public let baseURL: String
    public let client: Client

    public var sql: SQLRoutes { .init(druid: self) }
    public var supervisors: SupervisorRoutes { .init(druid: self) }
    public var dataSources: DataSourcesRoutes { .init(druid: self) }
    public var compaction: CompactionRoutes { .init(druid: self) }
    public var overlord: OverlordRoutes { .init(druid: self) }
}
