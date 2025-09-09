@testable import SwiftTQL
import Testing
import Foundation

struct GranularitySpecTests {
    let docsValueString = """
    {
      "intervals": [
        "2013-08-31/2013-09-01"
      ],
      "queryGranularity": "none",
      "rollup": true,
      "segmentGranularity": "day"
    }
    """
    .filter { !$0.isWhitespace }

    let docsValue = GranularitySpec(
        type: nil,
        segmentGranularity: .day,
        queryGranularity: QueryGranularity.none,
        rollup: true,
        intervals: ["2013-08-31/2013-09-01"]
    )

    let tdValueString = """
    {
        "intervals": [],
        "queryGranularity": "hour",
        "rollup": true,
        "segmentGranularity": "day",
        "type": "uniform"
    }
    """
    .filter { !$0.isWhitespace }

    let tdValue = GranularitySpec(type: .uniform, segmentGranularity: .day, queryGranularity: .hour, rollup: true, intervals: [])

    let testedType = GranularitySpec.self

    @Test("Decoding docs example")
    func decodingDocsExample() throws {
        let decodedValue = try JSONDecoder.telemetryDecoder.decode(testedType, from: docsValueString.data(using: .utf8)!)
        #expect(docsValue == decodedValue)
    }

    @Test("Encoding docs example")
    func encodingDocsExample() throws {
        let encodedValue = try JSONEncoder.telemetryEncoder.encode(docsValue)
        #expect(docsValueString == String(data: encodedValue, encoding: .utf8)!)
    }

    @Test("Decoding TelemetryDeck example")
    func decodingTelemetryDeckExample() throws {
        let decodedValue = try JSONDecoder.telemetryDecoder.decode(testedType, from: tdValueString.data(using: .utf8)!)
        #expect(tdValue == decodedValue)
    }

    @Test("Encoding TelemetryDeck example")
    func encodingTelemetryDeckExample() throws {
        let encodedValue = try JSONEncoder.telemetryEncoder.encode(tdValue)
        #expect(tdValueString == String(data: encodedValue, encoding: .utf8)!)
    }
}
