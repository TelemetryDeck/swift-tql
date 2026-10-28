import Foundation
@testable import SwiftDruid
import SwiftTQL
import Testing
import Vapor

/// A Vapor `Client` that records every request and answers each with a canned 200 response.
private final class CapturingClient: Client, @unchecked Sendable {
    let eventLoop: any EventLoop = EmbeddedEventLoop()
    let responseBody: String
    private let lock = NSLock()
    private var _requests: [ClientRequest] = []

    init(responseBody: String) {
        self.responseBody = responseBody
    }

    var requests: [ClientRequest] {
        lock.withLock { _requests }
    }

    func delegating(to eventLoop: any EventLoop) -> any Client { self }

    func send(_ request: ClientRequest) -> EventLoopFuture<ClientResponse> {
        lock.withLock { _requests.append(request) }
        var headers = HTTPHeaders()
        headers.contentType = .json
        let body = ByteBuffer(string: responseBody)
        return eventLoop.makeSucceededFuture(ClientResponse(status: .ok, headers: headers, body: body))
    }
}

@Suite("Query route tenant header tests")
struct QueryRouteHeaderTests {
    static let userID = UUID(uuidString: "6ba7b810-9dad-11d1-80b4-00c04fd430c8")!
    static let tenant = TenantContext(userID: userID, namespaces: ["com.example.app", "org.other.app"])
    static let invalidTenant = TenantContext(userID: userID, namespaces: ["Com.Example.App"])

    static let sqlQuery = SQLRoutes.DruidSQLQueryType(
        query: "SELECT 1",
        context: .init(engine: .native)
    )

    static let nativeQuery = CustomQuery(
        queryType: .timeseries,
        dataSource: "com.example.app",
        intervals: [.init(beginningDate: Date(timeIntervalSince1970: 0), endDate: Date(timeIntervalSince1970: 86400))],
        granularity: .day,
        aggregations: [.count(.init(name: "count"))]
    )

    static let nativeResult = #"[{"timestamp":"1970-01-01T00:00:00.000Z","result":{"count":1}}]"#

    private func assertTenantHeaders(_ request: ClientRequest) {
        #expect(request.headers[TenantContext.namespacesHeaderName] == ["com.example.app,org.other.app"])
        #expect(request.headers[TenantContext.userHeaderName] == [Self.userID.uuidString])
    }

    private func assertNoTenantHeaders(_ request: ClientRequest) {
        #expect(request.headers[TenantContext.namespacesHeaderName].isEmpty)
        #expect(request.headers[TenantContext.userHeaderName].isEmpty)
    }

    @Test("SQL route sends both headers with a tenant context")
    func sqlWithTenant() async throws {
        let client = CapturingClient(responseBody: "[]")
        let druid = Druid(baseURL: "http://druid/", client: client)

        let rows = try await druid.sql.execute(query: Self.sqlQuery, tenant: Self.tenant)

        #expect(rows.isEmpty)
        let request = try #require(client.requests.first)
        #expect(client.requests.count == 1)
        #expect(request.url.string == "http://druid/v2/sql")
        assertTenantHeaders(request)
    }

    @Test("SQL route sends neither header without a tenant context")
    func sqlWithoutTenant() async throws {
        let client = CapturingClient(responseBody: "[]")
        let druid = Druid(baseURL: "http://druid/", client: client)

        _ = try await druid.sql.execute(query: Self.sqlQuery)

        let request = try #require(client.requests.first)
        assertNoTenantHeaders(request)
    }

    @Test("Native route sends both headers plus the JSON content type with a tenant context")
    func nativeWithTenant() async throws {
        let client = CapturingClient(responseBody: Self.nativeResult)
        let druid = Druid(baseURL: "http://druid/", client: client)

        let result = try await druid.query.execute(query: Self.nativeQuery, tenant: Self.tenant)

        #expect(result.queryType == .timeseries)
        let request = try #require(client.requests.first)
        #expect(client.requests.count == 1)
        #expect(request.url.string == "http://druid/v2/")
        #expect(request.headers.contentType == .json)
        assertTenantHeaders(request)
    }

    @Test("Native route sends neither header without a tenant context")
    func nativeWithoutTenant() async throws {
        let client = CapturingClient(responseBody: Self.nativeResult)
        let druid = Druid(baseURL: "http://druid/", client: client)

        _ = try await druid.query.execute(query: Self.nativeQuery)

        let request = try #require(client.requests.first)
        #expect(request.headers.contentType == .json)
        assertNoTenantHeaders(request)
    }

    @Test("An invalid tenant context throws before any request is sent, on both routes")
    func invalidTenantThrowsBeforeRequest() async throws {
        let client = CapturingClient(responseBody: "[]")
        let druid = Druid(baseURLs: ["http://a/", "http://b/"], client: client)

        await #expect(throws: TenantContextError.invalidCharacter(namespace: "Com.Example.App")) {
            try await druid.sql.execute(query: Self.sqlQuery, tenant: Self.invalidTenant)
        }
        await #expect(throws: TenantContextError.invalidCharacter(namespace: "Com.Example.App")) {
            try await druid.query.execute(query: Self.nativeQuery, tenant: Self.invalidTenant)
        }

        #expect(client.requests.isEmpty)
        // Neither server was blamed for the client-side error.
        #expect(await druid.serverPool.nextServer(excluding: []) == "http://a/")
    }
}
