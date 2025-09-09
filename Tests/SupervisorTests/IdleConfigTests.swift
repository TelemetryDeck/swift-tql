@testable import SwiftTQL
import Testing
import Foundation

struct IdleConfigTests {
    let tdValueString = """
    {
        "enabled": true,
        "inactiveAfterMillis": 10000
    }
    """
    .filter { !$0.isWhitespace }

    let tdValue = IdleConfig(enabled: true, inactiveAfterMillis: 10000)

    let testedType = IdleConfig.self

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
