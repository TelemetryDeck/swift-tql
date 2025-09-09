@testable import SwiftTQL
import Testing
import Foundation

struct InputFormatTests {
    let docsValueString = """
    {
        "type": "json"
    }
    """
    .filter { !$0.isWhitespace }

    let docsValue = InputFormat(type: .json, keepNullColumns: nil)

    let tdValueString = """
    {
        "keepNullColumns": false,
        "type": "json"
    }
    """
    .filter { !$0.isWhitespace }

    let tdValue = InputFormat(type: .json, keepNullColumns: false)

    let testedType = InputFormat.self

    @Test("Decoding docs example should match expected value")
    func decodingDocsExample() throws {
        let decodedValue = try JSONDecoder.telemetryDecoder.decode(testedType, from: docsValueString.data(using: .utf8)!)
        #expect(docsValue == decodedValue)
    }

    @Test("Encoding docs example should match expected JSON string")
    func encodingDocsExample() throws {
        let encodedValue = try JSONEncoder.telemetryEncoder.encode(docsValue)
        #expect(docsValueString == String(data: encodedValue, encoding: .utf8)!)
    }

    @Test("Decoding TelemetryDeck example should match expected value")
    func decodingTelemetryDeckExample() throws {
        let decodedValue = try JSONDecoder.telemetryDecoder.decode(testedType, from: tdValueString.data(using: .utf8)!)
        #expect(tdValue == decodedValue)
    }

    @Test("Encoding TelemetryDeck example should match expected JSON string")
    func encodingTelemetryDeckExample() throws {
        let encodedValue = try JSONEncoder.telemetryEncoder.encode(tdValue)
        #expect(tdValueString == String(data: encodedValue, encoding: .utf8)!)
    }
}
