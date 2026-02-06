import Vapor

public struct Druid {
    public init(baseURL: String, client: any Client) {
        self.baseURL = baseURL
        self.client = client
    }

    public let baseURL: String
    public let client: Client
}
