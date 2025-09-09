@testable import SwiftTQL
import Testing
import Foundation

struct IngestionDimensionSpecSpatialDimensionTests {
    let docsValueString = """
    {
      "dimName": "coordinates",
      "dims": [
        "x",
        "y"
      ]
    }
    """
    .filter { !$0.isWhitespace }

    let docsValue = IngestionDimensionSpecSpatialDimension(dimName: "coordinates", dims: ["x", "y"])

    let testedType = IngestionDimensionSpecSpatialDimension.self

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
}
