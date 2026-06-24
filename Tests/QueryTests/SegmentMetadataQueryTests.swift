import Foundation
import SwiftTQL
import Testing

struct SegmentMetadataQueryTests {
    /// The example query from https://druid.apache.org/docs/latest/querying/segmentmetadataquery
    @Test("Decoding the documentation's example segmentMetadata query")
    func decodingExampleQuery() throws {
        let input = """
        {
          "queryType": "segmentMetadata",
          "dataSource": "sample_datasource",
          "intervals": ["2013-01-01/2014-01-01"]
        }
        """.data(using: .utf8)!

        let expectedOutput = CustomQuery(
            queryType: .segmentMetadata,
            dataSource: "sample_datasource",
            intervals: [.init(
                beginningDate: Formatter.iso8601dateOnly().date(from: "2013-01-01")!,
                endDate: Formatter.iso8601dateOnly().date(from: "2014-01-01")!
            )]
        )

        let decodedOutput = try JSONDecoder.telemetryDecoder.decode(CustomQuery.self, from: input)

        #expect(decodedOutput == expectedOutput)
    }

    @Test("Encoding a segmentMetadata query with toInclude, analysisTypes, merge and aggregatorMergeStrategy")
    func encodingFullQuery() throws {
        let query = CustomQuery(
            queryType: .segmentMetadata,
            dataSource: "sample_datasource",
            toInclude: .list(["dim1", "dim2"]),
            merge: true,
            analysisTypes: [.cardinality, .minmax],
            aggregatorMergeStrategy: .strict
        )

        let expectedOutput = """
        {"aggregatorMergeStrategy":"strict","analysisTypes":["cardinality","minmax"],"dataSource":"sample_datasource","merge":true,"queryType":"segmentMetadata","toInclude":{"columns":["dim1","dim2"],"type":"list"}}
        """

        let encodedOutput = try JSONEncoder.telemetryEncoder.encode(query)

        #expect(String(data: encodedOutput, encoding: .utf8)! == expectedOutput)
    }

    @Test("Round-tripping a segmentMetadata query preserves all segmentMetadata fields")
    func roundTrip() throws {
        let query = CustomQuery(
            queryType: .segmentMetadata,
            dataSource: "sample_datasource",
            toInclude: .all,
            merge: false,
            analysisTypes: [.cardinality, .interval, .minmax, .size, .timestampSpec, .queryGranularity, .aggregators, .rollup, .projections],
            aggregatorMergeStrategy: .lenient
        )

        let encoded = try JSONEncoder.telemetryEncoder.encode(query)
        let decoded = try JSONDecoder.telemetryDecoder.decode(CustomQuery.self, from: encoded)

        #expect(decoded == query)
    }

    @Test("toInclude encodes its three variants as documented")
    func toIncludeVariants() throws {
        let all = try JSONEncoder.telemetryEncoder.encode(CustomQuery.SegmentMetadataToInclude.all)
        #expect(String(data: all, encoding: .utf8)! == #"{"type":"all"}"#)

        let none = try JSONEncoder.telemetryEncoder.encode(CustomQuery.SegmentMetadataToInclude.none)
        #expect(String(data: none, encoding: .utf8)! == #"{"type":"none"}"#)

        let list = try JSONEncoder.telemetryEncoder.encode(CustomQuery.SegmentMetadataToInclude.list(["dim1", "dim2"]))
        #expect(String(data: list, encoding: .utf8)! == #"{"columns":["dim1","dim2"],"type":"list"}"#)
    }
}
