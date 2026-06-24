import Foundation
import SwiftTQL
import Testing

struct SegmentMetadataResultTests {
    /// The example result from https://druid.apache.org/docs/latest/querying/segmentmetadataquery
    let exampleResultJSON = """
    [
      {
        "id": "some_id",
        "intervals": ["2013-05-13T00:00:00.000Z/2013-05-14T00:00:00.000Z"],
        "columns": {
          "__time": { "type": "LONG", "hasMultipleValues": false, "hasNulls": false, "size": 407240380, "cardinality": null, "errorMessage": null },
          "dim1": { "type": "STRING", "hasMultipleValues": false, "hasNulls": false, "size": 100000, "cardinality": 1944, "errorMessage": null },
          "dim2": { "type": "STRING", "hasMultipleValues": true, "hasNulls": true, "size": 100000, "cardinality": 1504, "errorMessage": null },
          "metric1": { "type": "FLOAT", "hasMultipleValues": false, "hasNulls": false, "size": 100000, "cardinality": null, "errorMessage": null }
        },
        "aggregators": {
          "metric1": { "type": "longSum", "name": "metric1", "fieldName": "metric1" }
        },
        "queryGranularity": { "type": "none" },
        "size": 300000,
        "numRows": 5000000
      }
    ]
    """

    @Test("Decoding the documentation's example segmentMetadata result")
    func decodingExampleResult() throws {
        let decoded = try JSONDecoder.telemetryDecoder.decode([SegmentAnalysis].self, from: Data(exampleResultJSON.utf8))

        #expect(decoded.count == 1)
        let row = try #require(decoded.first)

        #expect(row.id == "some_id")
        #expect(row.size == 300000)
        #expect(row.numRows == 5000000)
        #expect(row.intervals?.count == 1)
        #expect(row.queryGranularity == QueryGranularity.none)

        #expect(row.columns.count == 4)
        #expect(row.columns["__time"]?.type == "LONG")
        #expect(row.columns["__time"]?.cardinality == nil)
        #expect(row.columns["dim1"]?.cardinality == 1944)
        #expect(row.columns["dim2"]?.hasMultipleValues == true)
        #expect(row.columns["dim2"]?.hasNulls == true)
        #expect(row.columns["dim2"]?.cardinality == 1504)
        #expect(row.columns["metric1"]?.type == "FLOAT")

        #expect(row.aggregators?["metric1"] == .longSum(.init(type: .longSum, name: "metric1", fieldName: "metric1")))
    }

    @Test("Decoding segmentMetadata QueryResultData")
    func decodingViaQueryResultData() async throws {
        let data = QueryResultData(data: Data(exampleResultJSON.utf8), queryType: .segmentMetadata)

        let expected = QueryResult.segmentMetadata(SegmentMetadataQueryResult(rows: [
            SegmentAnalysis(
                id: "some_id",
                intervals: [.init(
                    beginningDate: Date(iso8601String: "2013-05-13T00:00:00.000Z")!,
                    endDate: Date(iso8601String: "2013-05-14T00:00:00.000Z")!
                )],
                columns: [
                    "__time": .init(type: "LONG", hasMultipleValues: false, hasNulls: false, size: 407240380, cardinality: nil),
                    "dim1": .init(type: "STRING", hasMultipleValues: false, hasNulls: false, size: 100000, cardinality: 1944),
                    "dim2": .init(type: "STRING", hasMultipleValues: true, hasNulls: true, size: 100000, cardinality: 1504),
                    "metric1": .init(type: "FLOAT", hasMultipleValues: false, hasNulls: false, size: 100000, cardinality: nil),
                ],
                size: 300000,
                numRows: 5000000,
                aggregators: ["metric1": .longSum(.init(type: .longSum, name: "metric1", fieldName: "metric1"))],
                queryGranularity: QueryGranularity.none
            ),
        ]))

        #expect(try await data.decode() == expected)
    }
}
