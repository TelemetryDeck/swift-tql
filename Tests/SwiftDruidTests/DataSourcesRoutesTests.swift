@testable import SwiftDruid
import Foundation
import SwiftTQL
import Testing

@Suite("DataSourcesRoutes Tests")
struct DataSourcesRoutesTests {
    let interval = QueryTimeInterval(
        beginningDate: Date(timeIntervalSince1970: 1_704_067_200),
        endDate: Date(timeIntervalSince1970: 1_735_689_600)
    )

    func encode(_ filter: DataSourcesRoutes.SegmentsFilter) throws -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return try String(data: encoder.encode(filter), encoding: .utf8)
    }

    @Test("Building the datasource URL")
    func dataSourceURL() {
        let url = DataSourcesRoutes.dataSourceURL(baseURL: "http://druid:8888/druid/", dataSource: "com.example")
        #expect(url == "http://druid:8888/druid/indexer/v1/datasources/com.example")
    }

    @Test("Encoding an interval filter")
    func encodingIntervalFilter() throws {
        #expect(try encode(.init(interval: interval)) == """
        {"interval":"2024-01-01T00:00:00.000Z\\/2025-01-01T00:00:00.000Z"}
        """)
        #expect(try encode(.init(interval: interval, versions: ["2024-02-01T00:00:00.000Z"])) == """
        {"interval":"2024-01-01T00:00:00.000Z\\/2025-01-01T00:00:00.000Z","versions":["2024-02-01T00:00:00.000Z"]}
        """)
    }

    @Test("Encoding a segment ID filter")
    func encodingSegmentIdFilter() throws {
        let segmentId = "com.example_2024-01-01T00:00:00.000Z_2024-02-01T00:00:00.000Z_2024-02-02T10:00:00.000Z"
        #expect(try encode(.init(segmentIds: [segmentId])) == """
        {"segmentIds":["\(segmentId)"]}
        """)
    }

    @Test("Decoding the segment change response")
    func decodingResponse() throws {
        let response = try JSONDecoder().decode(
            DataSourcesRoutes.SegmentChangeMetadata.self,
            from: #"{"numChangedSegments":12}"#.data(using: .utf8)!
        )
        #expect(response.numChangedSegments == 12)
        #expect(response.segmentStateChanged == nil)
    }
}
