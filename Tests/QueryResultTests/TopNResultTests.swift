import SwiftTQL
import Testing
import Foundation

struct TopNResultTests {
    static let firstMonthDate: Date = Formatter.iso8601().date(from: "2021-12-01T00:00:00.000Z")!
    static let secondMonthDate: Date = Formatter.iso8601().date(from: "2022-01-01T00:00:00.000Z")!

    let emptyResult = """
    [
      {
        "result": [],
        "timestamp": "2021-12-01T00:00:00+0000"
      },
      {
        "result": [],
        "timestamp": "2022-01-01T00:00:00+0000"
      }
    ]
    """
    .filter { !$0.isWhitespace }

    let decodedEmptyExampleResult = [
        TopNQueryResultRow(timestamp: firstMonthDate, result: []),
        TopNQueryResultRow(timestamp: secondMonthDate, result: []),
    ]

    let exampleResult = """
    [
      {
        "result": [
          {
            "appVersion": "276",
            "count": 1
          },
          {
            "appVersion": "324",
            "count": 1
          },
          {
            "appVersion": "408",
            "count": 35
          }
        ],
        "timestamp": "2021-12-01T00:00:00+0000"
      },
      {
        "result": [
          {
            "appVersion": null,
            "count": 2
          },
          {
            "appVersion": "411",
            "count": 6
          },
          {
            "appVersion": "448",
            "count": 9
          }
        ],
        "timestamp": "2022-01-01T00:00:00+0000"
      }
    ]
    """
    .filter { !$0.isWhitespace }

    let decodedExampleResult = [
        TopNQueryResultRow(timestamp: firstMonthDate, result: [
            .init(metrics: ["count": .init(1)], dimensions: ["appVersion": .init("276")]),
            .init(metrics: ["count": .init(1)], dimensions: ["appVersion": .init("324")]),
            .init(metrics: ["count": .init(35)], dimensions: ["appVersion": .init("408")]),
        ]),
        TopNQueryResultRow(timestamp: secondMonthDate, result: [
            .init(metrics: ["count": .init(2)], dimensions: [:], nullValues: ["appVersion"]),
            .init(metrics: ["count": .init(6)], dimensions: ["appVersion": .init("411")]),
            .init(metrics: ["count": .init(9)], dimensions: ["appVersion": .init("448")]),
        ]),
    ]

    let resultRowItemNull = """
      {
        "appVersion": null,
        "count": 2
      }
    """
    .filter { !$0.isWhitespace }

    let resultRowItemNullExample = AdaptableQueryResultItem(metrics: ["count": .init(2)], dimensions: [:], nullValues: ["appVersion"])

    let resultRowItemOneEntry = """
      {
        "appVersion": "335",
        "count": 2
      }
    """
    .filter { !$0.isWhitespace }

    let resultRowItemOneItemExample = AdaptableQueryResultItem(metrics: ["count": .init(2)], dimensions: ["appVersion": .init("335")])

    let resultRowItemManyEntries = """
      {
          "average": 1.25,
          "count": 88,
          "dim1": "another_dim1_val",
          "some_metrics": 28344
       }
    """
    .filter { !$0.isWhitespace }

    let resultRowItemManyEntriesExample = AdaptableQueryResultItem(
        metrics: [
            "count": .init(88),
            "some_metrics": .init(28344),
            "average": .init(1.25),
        ],
        dimensions: ["dim1": .init("another_dim1_val")]
    )

    @Test("Decoding empty TopN result")
    func decodingEmptyResult() throws {
        let decodedRows = try JSONDecoder.telemetryDecoder.decode([TopNQueryResultRow].self, from: emptyResult.data(using: .utf8)!)
        #expect(decodedRows == decodedEmptyExampleResult)
    }

    @Test("Encoding empty TopN result")
    func encodingEmptyResult() throws {
        let encoded = try JSONEncoder.telemetryEncoder.encode(decodedEmptyExampleResult)
        #expect(String(data: encoded, encoding: .utf8)! == emptyResult)
    }

    @Test("Decoding TopN query result")
    func decoding() throws {
        let decodedRows = try JSONDecoder.telemetryDecoder.decode([TopNQueryResultRow].self, from: exampleResult.data(using: .utf8)!)
        #expect(decodedRows == decodedExampleResult)
    }

    @Test("Encoding TopN query result")
    func encoding() throws {
        let encoded = try JSONEncoder.telemetryEncoder.encode(decodedExampleResult)
        #expect(String(data: encoded, encoding: .utf8)! == exampleResult)
    }

    @Test("Decoding TopN query result row item with null entry")
    func decodingTopNQueryResultRowItemNullEntry() throws {
        let decoded = try JSONDecoder.telemetryDecoder.decode(AdaptableQueryResultItem.self, from: resultRowItemNull.data(using: .utf8)!)
        #expect(decoded == resultRowItemNullExample)
    }

    @Test("Decoding TopN query result row item with one entry")
    func decodingTopNQueryResultRowItemOneEntry() throws {
        let decoded = try JSONDecoder.telemetryDecoder.decode(AdaptableQueryResultItem.self, from: resultRowItemOneEntry.data(using: .utf8)!)
        #expect(decoded == resultRowItemOneItemExample)
    }

    @Test("Decoding TopN query result row item with many entries")
    func decodingTopNQueryResultRowItemManyEntries() throws {
        let decoded = try JSONDecoder.telemetryDecoder.decode(AdaptableQueryResultItem.self, from: resultRowItemManyEntries.data(using: .utf8)!)
        #expect(decoded == resultRowItemManyEntriesExample)
    }

    @Test("Encoding TopN query result row item with null entry")
    func encodingTopNQueryResultRowItemNullEntry() throws {
        let encoded = try JSONEncoder.telemetryEncoder.encode(resultRowItemNullExample)
        #expect(String(data: encoded, encoding: .utf8)! == resultRowItemNull)
    }

    @Test("Encoding TopN query result row item with one entry")
    func encodingTopNQueryResultRowItemOneEntry() throws {
        let encoded = try JSONEncoder.telemetryEncoder.encode(resultRowItemOneItemExample)
        #expect(String(data: encoded, encoding: .utf8)! == resultRowItemOneEntry)
    }

    @Test("Encoding TopN query result row item with many entries")
    func encodingTopNQueryResultRowItemManyEntries() throws {
        let encoded = try JSONEncoder.telemetryEncoder.encode(resultRowItemManyEntriesExample)
        #expect(String(data: encoded, encoding: .utf8)! == resultRowItemManyEntries)
    }
}
