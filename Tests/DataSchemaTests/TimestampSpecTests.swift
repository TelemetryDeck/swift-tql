@testable import SwiftTQL
import Testing
import Foundation

struct TimestampSpecTests {
    let docsValueString = """
    {
      "column": "timestamp",
      "format": "auto"
    }
    """
    .filter { !$0.isWhitespace }

    let docsValue = TimestampSpec(column: "timestamp", format: .auto, missingValue: nil)

    let tdValueString = """
    {
        "column": "receivedAt",
        "format": "iso",
        "missingValue": "blob"
      }
    """
    .filter { !$0.isWhitespace }

    let tdValue = TimestampSpec(column: "receivedAt", format: .iso, missingValue: "blob")

    let testedType = TimestampSpec.self

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
