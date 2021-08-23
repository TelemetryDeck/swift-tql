import Foundation

struct DruidSQLQueryContext: Codable {
    let skipEmptyBuckets: Bool
}

struct DruidSQLQuery: Codable {
    let query: String
    let context: DruidSQLQueryContext
}

#if canImport(Vapor)
import Vapor
extension DruidSQLQuery: Content {}
extension DruidSQLQueryContext: Content {}
#endif
