import Foundation
@testable import SwiftDruid
import Testing

@Suite("TenantContext header tests")
struct TenantContextTests {
    /// One row of `Fixtures/headers.json`, a copy of `druid-tenant-auth/fixtures/headers.json`.
    /// The Java `HeaderParser` tests run the same rows, so both sides agree on every value.
    struct FixtureRow: Decodable {
        let id: String
        let note: String
        let namespaces: String?
        let user: String?
        let state: String
        let namespaceList: [String]?
    }

    static func loadFixtureRows() throws -> [FixtureRow] {
        let url = try #require(Bundle.module.url(forResource: "headers", withExtension: "json", subdirectory: "Fixtures"))
        return try JSONDecoder().decode([FixtureRow].self, from: Data(contentsOf: url))
    }

    /// Rows the Swift type can express: a namespaces value and a user that parses as a UUID.
    /// Absent headers (H1, H4, H5) and non-UUID users (H11, H16, H17) are prevented by the type.
    static func expressibleRows() throws -> [FixtureRow] {
        try loadFixtureRows().filter { row in
            row.namespaces != nil && row.user.flatMap(UUID.init(uuidString:)) != nil
        }
    }

    @Test("The fixture file loads and has the expressible rows")
    func fixtureCoverage() throws {
        let ids = try Self.expressibleRows().map(\.id)
        #expect(ids == ["H2", "H3", "H6", "H7", "H8", "H9", "H10", "H12", "H12a", "H18", "H19", "H20", "H21", "H22", "H23"])
    }

    @Test("Every expressible fixture row is accepted exactly when the extension accepts it", arguments: try expressibleRows())
    func fixtureRow(row: FixtureRow) throws {
        let userString = try #require(row.user)
        let userID = try #require(UUID(uuidString: userString))
        let namespacesValue = try #require(row.namespaces)
        let namespaces = namespacesValue.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
        let context = TenantContext(userID: userID, namespaces: namespaces)

        if row.state == "VALID" {
            let headers = try context.headers()
            #expect(headers[TenantContext.namespacesHeaderName] == [namespacesValue], "\(row.id): \(row.note)")
            #expect(headers[TenantContext.userHeaderName] == [userID.uuidString], "\(row.id): \(row.note)")
            #expect(namespaces == row.namespaceList, "\(row.id): \(row.note)")
            #expect(headers.count == 2)
        } else {
            #expect(row.state == "INVALID", "\(row.id): unexpected state \(row.state)")
            #expect(throws: TenantContextError.self, "\(row.id): \(row.note)") {
                try context.headers()
            }
        }
    }

    @Test("The user header is the UUID string Foundation produces")
    func userHeaderIsUUIDString() throws {
        let userID = try #require(UUID(uuidString: "6ba7b810-9dad-11d1-80b4-00c04fd430c8"))
        let headers = try TenantContext(userID: userID, namespaces: ["com.example.app"]).headers()
        #expect(headers.first(name: "X-TD-User") == "6BA7B810-9DAD-11D1-80B4-00C04FD430C8")
        #expect(headers.first(name: "X-TD-Namespaces") == "com.example.app")
    }

    @Test("An empty list is rejected")
    func emptyList() {
        let context = TenantContext(userID: UUID(), namespaces: [])
        #expect(throws: TenantContextError.emptyNamespaces) {
            try context.headers()
        }
    }

    @Test("An empty entry is rejected with its index")
    func emptyEntry() {
        let context = TenantContext(userID: UUID(), namespaces: ["com.example.app", ""])
        #expect(throws: TenantContextError.emptyNamespace(index: 1)) {
            try context.headers()
        }
    }

    @Test("A comma inside an entry is rejected because it is the separator")
    func commaInsideEntry() {
        let context = TenantContext(userID: UUID(), namespaces: ["com.example.app,org.other.app"])
        #expect(throws: TenantContextError.invalidCharacter(namespace: "com.example.app,org.other.app")) {
            try context.headers()
        }
    }

    @Test("A joined value of exactly 4 KiB is accepted")
    func maxSizeAccepted() throws {
        // 63 chars + "," = 64 bytes per entry; 64 entries = 4096 bytes, minus the last comma, plus 1.
        let entry = String(repeating: "a", count: 63)
        var namespaces = Array(repeating: entry, count: 64)
        namespaces[63] = String(repeating: "a", count: 64)
        let joined = namespaces.joined(separator: ",")
        #expect(joined.utf8.count == 4096)

        let headers = try TenantContext(userID: UUID(), namespaces: namespaces).headers()
        #expect(headers.first(name: "X-TD-Namespaces")?.utf8.count == 4096)
    }

    @Test("A joined value of 4 KiB plus one byte is rejected")
    func oversizeRejected() {
        let entry = String(repeating: "a", count: 63)
        var namespaces = Array(repeating: entry, count: 64)
        namespaces[63] = String(repeating: "a", count: 65)
        #expect(namespaces.joined(separator: ",").utf8.count == 4097)

        #expect(throws: TenantContextError.headerTooLarge(bytes: 4097)) {
            try TenantContext(userID: UUID(), namespaces: namespaces).headers()
        }
    }

    @Test("Errors have a description")
    func errorDescriptions() {
        let errors: [TenantContextError] = [
            .emptyNamespaces,
            .emptyNamespace(index: 0),
            .invalidCharacter(namespace: "X"),
            .headerTooLarge(bytes: 5000),
        ]
        for error in errors {
            #expect(error.errorDescription?.isEmpty == false)
        }
    }
}
