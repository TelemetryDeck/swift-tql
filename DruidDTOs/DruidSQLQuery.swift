import Foundation

struct DruidSQLQuery: Codable {
    let query: String
    let context: DruidContext
}

#if canImport(Vapor)
import Vapor
extension DruidSQLQuery: Content {}
#endif
