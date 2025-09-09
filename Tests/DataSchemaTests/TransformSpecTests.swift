@testable import SwiftTQL
import Testing
import Foundation

struct TransformSpecTests {
    let docsValueString = """
    {
      "filter": {
        "dimension": "country",
        "type": "selector",
        "value": "SanSeriffe"
      },
      "transforms": [
        {  "expression": "upper(country)", "name": "countryUpper", "type": "expression" }
      ]
    }
    """
    .filter { !$0.isWhitespace }

    let docsValue = TransformSpec(
        transforms: [
            .init(type: "expression", name: "countryUpper", expression: "upper(country)")
        ],
        filter: .selector(.init(dimension: "country", value: "SanSeriffe"))
    )

    let tdValueString = """
    {
        "transforms": []
    }
    """
    .filter { !$0.isWhitespace }

    let tdValue = TransformSpec(transforms: [], filter: nil)

    let testedType = TransformSpec.self

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
