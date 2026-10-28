import Foundation
@testable import SwiftDruid
import Testing

@Suite("SQL request body tests")
struct SQLBodyTests {
    private func encodedKeys(_ context: SQLRoutes.DruidSQLQueryType.Context) throws -> [String: Any] {
        let body = SQLRoutes.DruidSQLQueryType(query: "SELECT 1", context: context)
        let data = try JSONEncoder().encode(body)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        return try #require(object["context"] as? [String: Any])
    }

    @Test("An empty context encodes as an empty object without an engine key")
    func emptyContext() throws {
        let context = try encodedKeys(.init())
        #expect(context.isEmpty)
    }

    @Test("Only the keys that are set appear in the body")
    func allowlistedKeys() throws {
        let context = try encodedKeys(.init(sqlTimeZone: "Europe/Berlin", useApproximateCountDistinct: false, useApproximateTopN: true))
        #expect(Set(context.keys) == ["sqlTimeZone", "useApproximateCountDistinct", "useApproximateTopN"])
        #expect(context["sqlTimeZone"] as? String == "Europe/Berlin")
        #expect(context["useApproximateCountDistinct"] as? Bool == false)
        #expect(context["useApproximateTopN"] as? Bool == true)
    }

    @Test("The engine and sqlQueryId keys still encode when set")
    func internalKeys() throws {
        let context = try encodedKeys(.init(engine: .native, sqlQueryId: "abc"))
        #expect(context["engine"] as? String == "native")
        #expect(context["sqlQueryId"] as? String == "abc")
    }

    @Test("A body with an empty context decodes")
    func decodeEmptyContext() throws {
        let data = Data(#"{"query":"SELECT 1","context":{}}"#.utf8)
        let body = try JSONDecoder().decode(SQLRoutes.DruidSQLQueryType.self, from: data)
        #expect(body.query == "SELECT 1")
        #expect(body.context.engine == nil)
    }
}
