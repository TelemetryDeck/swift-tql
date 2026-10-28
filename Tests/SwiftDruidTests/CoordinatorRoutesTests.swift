@testable import SwiftDruid
import Foundation
import Testing

@Suite("CoordinatorRoutes Tests")
struct CoordinatorRoutesTests {
    @Test("Building the intervals URL")
    func intervalsURL() {
        let url = CoordinatorRoutes.intervalsURL(baseURL: "http://druid:8888/druid/", dataSource: "com.example")
        #expect(url == "http://druid:8888/druid/coordinator/v1/datasources/com.example/intervals?simple")
    }

    /// Shape returned by `GET /druid/coordinator/v1/datasources/{dataSource}/intervals?simple` (trimmed to two entries)
    @Test("Decoding the simple intervals response")
    func decodingIntervalsResponse() throws {
        let responseString = """
        {"2026-09-01T00:00:00.000Z/2026-10-01T00:00:00.000Z":{"size":734003200,"count":4},\
        "2026-10-03T00:00:00.000Z/2026-10-04T00:00:00.000Z":{"size":1234,"count":1}}
        """

        let intervals = try JSONDecoder().decode(
            [String: CoordinatorRoutes.IntervalStats].self,
            from: responseString.data(using: .utf8)!
        )

        #expect(intervals.count == 2)
        #expect(intervals["2026-09-01T00:00:00.000Z/2026-10-01T00:00:00.000Z"] == .init(size: 734_003_200, count: 4))
        #expect(intervals["2026-10-03T00:00:00.000Z/2026-10-04T00:00:00.000Z"] == .init(size: 1234, count: 1))
    }
}
