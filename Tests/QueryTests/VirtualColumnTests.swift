@testable import SwiftTQL
import Testing
import Foundation

struct VirtualColumnTests {
    let tdValueString = """
    {
      "aggregations": [
        { "fieldName": "clientUser", "name": "count", "type": "thetaSketch" }
      ],
      "dimension": {
        "dimension": "calculatedSystemVersion",
        "outputName": "fooPage",
        "type": "default"
      },
      "granularity": "all",
      "metric": { "metric": "count", "type": "numeric" },
      "queryType": "topN",
      "threshold": 10,
       "virtualColumns": [
        {
          "expression": "nvl(majorMinorSystemVersion,concat('TelemetryDeck.Device.operatingSystem+'-'+nvl(OSVersion,'unknown')))",
          "name": "calculatedSystemVersion",
          "outputType": "STRING",
          "type": "expression"
        }
      ]
    }
    """
    .filter { !$0.isWhitespace }

    let tdValue = CustomQuery(
        queryType: .topN,
        virtualColumns: [
            .expression(
                .init(
                    name: "calculatedSystemVersion",
                    expression: "nvl(majorMinorSystemVersion,concat('TelemetryDeck.Device.operatingSystem+'-'+nvl(OSVersion,'unknown')))",
                    outputType: "STRING"
                )
            )
        ],
        granularity: .all,
        aggregations: [
            .thetaSketch(.init(name: "count", fieldName: "clientUser"))
        ],
        threshold: 10,
        metric: .numeric(.init(metric: "count")),
        dimension: .default(.init(dimension: "calculatedSystemVersion", outputName: "fooPage"))
    )

    let testedType = CustomQuery.self

    @Test("Decoding docs example")
    func decodingDocsExample() throws {
        let decodedValue = try JSONDecoder.telemetryDecoder.decode(testedType, from: tdValueString.data(using: .utf8)!)
        #expect(tdValue == decodedValue)
    }

    @Test("Encoding docs example")
    func encodingDocsExample() throws {
        let encodedValue = try JSONEncoder.telemetryEncoder.encode(tdValue)
        #expect(tdValueString == String(data: encodedValue, encoding: .utf8)!)
    }
}

struct ExpressionVirtualColumnTests {
    let docsValueString = """
    {
      "expression": "<rowexpression>",
      "name": "<nameofthevirtualcolumn>",
      "outputType": "FLOAT",
      "type": "expression"
    }
    """
    .filter { !$0.isWhitespace }

    let docsValue = VirtualColumn.expression(
        ExpressionVirtualColumn(name: "<nameofthevirtualcolumn>", expression: "<rowexpression>", outputType: "FLOAT")
    )

    let testedType = VirtualColumn.self

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

struct ListFilteredVirtualColumnTests {
    let docsValueString = """
    {
      "delegate": "dim3",
      "isAllowList": true,
      "name": "filteredDim3",
      "type": "mv-filtered",
      "values": ["hello", "world"]
    }
    """
    .filter { !$0.isWhitespace }

    let docsValue = VirtualColumn.listFiltered(
        .init(
            name: "filteredDim3",
            delegate: "dim3",
            values: ["hello", "world"],
            isAllowList: true
        )
    )

    let testedType = VirtualColumn.self

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
