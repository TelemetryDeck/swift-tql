@testable import SwiftTQL
import Testing
import Foundation

struct IngestionDimensionSpecDimensionTests {
    let docsValueString = """
    { "name": "userId", "type": "long" }
    """
    .filter { !$0.isWhitespace }

    let docsValue = IngestionDimensionSpecDimension(type: .long, name: "userId", createBitmapIndex: nil, multiValueHandling: nil)

    let tdValueString = """
    {
        "createBitmapIndex": true,
        "multiValueHandling": "sorted_array",
        "name": "TelemetryDeck.Device.modelName",
        "type": "string"

    }
    """
    .filter { !$0.isWhitespace }

    let tdValue = IngestionDimensionSpecDimension(
        type: .string,
        name: "TelemetryDeck.Device.modelName",
        createBitmapIndex: true,
        multiValueHandling: .sorted_array
    )

    let testedType = IngestionDimensionSpecDimension.self

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
