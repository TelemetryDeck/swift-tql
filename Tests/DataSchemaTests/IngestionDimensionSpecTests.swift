@testable import SwiftTQL
import Testing
import Foundation

struct IngestionDimensionSpecTests {
    let docsValueString = """
    {
      "dimensionExclusions" : [],
      "dimensions": [
        { "name": "page", "type": "long" },
        { "name": "userId", "type": "long" }
      ],
      "spatialDimensions" : [],
      "useSchemaDiscovery": true
    }
    """
    .filter { !$0.isWhitespace }

    let docsValue = DimensionsSpec(
        dimensions: [
            .init(type: .long, name: "page", createBitmapIndex: nil, multiValueHandling: nil),
            .init(type: .long, name: "userId", createBitmapIndex: nil, multiValueHandling: nil),
        ],
        dimensionExclusions: [],
        spatialDimensions: [],
        includeAllDimensions: nil,
        useSchemaDiscovery: true,
        forceSegmentSortByTime: nil
    )

    let tdValueString = """
    {
        "dimensionExclusions": [
          "__time",
          "count",
          "receivedAt"
        ],
        "dimensions": [
          {
            "createBitmapIndex": true,
            "multiValueHandling": "SORTED_ARRAY",
            "name": "appID",
            "type": "string"
          },
          {
            "createBitmapIndex": true,
            "multiValueHandling": "sorted_array",
            "name": "type",
            "type": "string"
          },
          {
            "createBitmapIndex": true,
            "multiValueHandling": "SORTED_ARRAY",
            "name": "clientUser",
            "type": "string"
          },
          {
            "createBitmapIndex": false,
            "multiValueHandling": "SORTED_ARRAY",
            "name": "TelemetryDeck.Metrics.Swift.memoryMetrics.averageSuspendedMemory.standardDeviation",
            "type": "float"
          }
        ],
        "includeAllDimensions": false,
        "useSchemaDiscovery": false
    }
    """
    .filter { !$0.isWhitespace }

    let tdValue = DimensionsSpec(
        dimensions: [
            .init(type: .string, name: "appID", createBitmapIndex: true, multiValueHandling: .sorted_array),
            .init(type: .string, name: "type", createBitmapIndex: true, multiValueHandling: .sorted_array),
            .init(type: .string, name: "clientUser", createBitmapIndex: true, multiValueHandling: .sorted_array),
            .init(type: .float, name: "TelemetryDeck.Metrics.Swift.memoryMetrics.averageSuspendedMemory.standardDeviation",
                  createBitmapIndex: false, multiValueHandling: .sorted_array),
        ],
        dimensionExclusions: [
            "__time",
            "count",
            "receivedAt",
        ],
        spatialDimensions: nil,
        includeAllDimensions: false,
        useSchemaDiscovery: false,
        forceSegmentSortByTime: nil
    )

    let testedType = DimensionsSpec.self

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
        #expect(
            tdValueString.replacingOccurrences(of: "SORTED_ARRAY", with: "sorted_array") ==
            String(
                data: encodedValue,
                encoding: .utf8
            )!
        )
    }
}
