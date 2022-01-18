import Foundation

public struct DruidSQLQuery: Codable, Hashable {
    let query: String
    let context: DruidContext
    
    public init(query: String, context: DruidContext) {
        self.query = query
        self.context = context
    }
}
