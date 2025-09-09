@testable import SwiftTQL
import Testing
import Foundation

struct SupervisorTests {
    let tdValueString = """
    {
      "type": "kinesis",
      "context": null,
      "suspended": false
    }
    """
    .filter { !$0.isWhitespace }

    let testedType = Supervisor.self

    @Test("Decoding TelemetryDeck example should match expected suspended value")
    func decodingTelemetryDeckExample() throws {
        let decodedValue = try JSONDecoder.telemetryDecoder.decode(testedType, from: tdValueString.data(using: .utf8)!)
        #expect(decodedValue.suspended == false)
    }
}
