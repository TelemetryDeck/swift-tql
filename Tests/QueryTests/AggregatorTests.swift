@testable import SwiftTQL
import Testing
import Foundation

struct AggregatorTests {
    let exampleDruidAggregatorsThetaSketch = """
    [
        {
          "fieldName": "clientUser",
          "name": "count",
          "type": "thetaSketch"
        }
      ]
    """
    .filter { !$0.isWhitespace }
    .data(using: .utf8)!

    let exampleDruidAggregatorsCountSum = """
    [
        {
          "fieldName": "count",
          "name": "count",
          "type": "longSum"
        }
      ]
    """
    .filter { !$0.isWhitespace }
    .data(using: .utf8)!

    let exampleDruidAggregatorsFiltered = """
    [
        {
          "type": "filtered",
          "name": "_namedFilteredAggregator",
          "filter": {
            "type": "selector",
            "dimension": "type",
            "value": "newSessionBegan"
          },
          "aggregator": {
            "type": "thetaSketch",
            "name": "newSessionBegan",
            "fieldName": "clientUser"
          }
        },
        {
          "type": "filtered",
          "filter": {
            "type": "and",
            "fields": [
              {
                "type": "selector",
                "dimension": "type",
                "value": "InsightShown"
              }
            ]
          },
          "aggregator": {
            "type": "thetaSketch",
            "name": "InsightShown",
            "fieldName": "clientUser"
          }
        }
      ]
    """
    .filter { !$0.isWhitespace }
    .data(using: .utf8)!

    @Test("ThetaSketch aggregator decoding") func thetaSketchAggregatorDecoding() throws {
        let decodedAggregators = try JSONDecoder.telemetryDecoder.decode([Aggregator].self, from: exampleDruidAggregatorsThetaSketch)

        #expect(decodedAggregators == [Aggregator.thetaSketch(.init(name: "count", fieldName: "clientUser"))])
    }

    @Test("QuantilesDoublesSketch aggregator") func quantilesDoublesSketchAggregator() throws {
        let stringRepresentation = """
        [
            {
              "fieldName": "clientUser",
              "k": 1024,
              "name": "count",
              "type": "quantilesDoublesSketch"
            }
          ]
        """
        .filter { !$0.isWhitespace }

        let swiftRepresentation = [Aggregator.quantilesDoublesSketch(.init(name: "count", fieldName: "clientUser", k: 1024))]

        let decodedAggregators = try JSONDecoder.telemetryDecoder.decode([Aggregator].self, from: stringRepresentation.data(using: .utf8)!)
        #expect(decodedAggregators == swiftRepresentation)

        let encodedAggregators = try JSONEncoder.telemetryEncoder.encode(swiftRepresentation)
        #expect(String(data: encodedAggregators, encoding: .utf8)! == stringRepresentation)
    }

    @Test("LongSum aggregator decoding") func longSumAggregatorDecoding() throws {
        let decodedAggregators = try JSONDecoder.telemetryDecoder.decode([Aggregator].self, from: exampleDruidAggregatorsCountSum)

        #expect(decodedAggregators == [Aggregator.longSum(.init(type: .longSum, name: "count", fieldName: "count"))])
    }

    @Test("Cardinality aggregator") func cardinalityAggregator() throws {
        let exampleAggregatorsString = """
        [
          {
            "byRow": false,
            "fields": ["clientUser"],
            "name": "a0",
            "round": true,
            "type": "cardinality"
          }
        ]
        """
        .filter { !$0.isWhitespace }

        let exampleAggregators = [Aggregator.cardinality(.init(name: "a0", fields: ["clientUser"], round: true))]

        #expect(try JSONDecoder.telemetryDecoder.decode([Aggregator].self, from: exampleAggregatorsString.data(using: .utf8)!) == exampleAggregators)

        #expect(try String(data: JSONEncoder.telemetryEncoder.encode(exampleAggregators), encoding: .utf8)! == exampleAggregatorsString)
    }

    @Test("Filtered aggregator decoding") func filteredAggregatorDecoding() throws {
        let decodedAggregators = try JSONDecoder.telemetryDecoder.decode([Aggregator].self, from: exampleDruidAggregatorsFiltered)

        #expect(decodedAggregators == [
            .filtered(
                .init(
                    filter: .selector(
                        .init(
                            dimension: "type",
                            value: "newSessionBegan"
                        )
                    ),
                    aggregator: .thetaSketch(
                        .init(
                            name: "newSessionBegan",
                            fieldName: "clientUser"
                        )
                    ),
                    name: "_namedFilteredAggregator"
                )
            ),
            .filtered(
                .init(
                    filter: .and(
                        .init(
                            fields: [
                                .selector(
                                    .init(
                                        dimension: "type",
                                        value: "InsightShown"
                                    )
                                ),
                            ]
                        )
                    ),
                    aggregator: .thetaSketch(
                        .init(
                            name: "InsightShown",
                            fieldName: "clientUser"
                        )
                    )
                )
            ),
        ])
    }

    @Test("Filtered aggregator encoding") func filteredAggregatorEncoding() throws {
        let aggregators: [Aggregator] = [
            .filtered(
                .init(
                    filter: .selector(
                        .init(
                            dimension: "type",
                            value: "newSessionBegan"
                        )
                    ),
                    aggregator: .thetaSketch(
                        .init(
                            name: "newSessionBegan",
                            fieldName: "clientUser"
                        )
                    ),
                    name: "_namedFilteredAggregator"
                )
            ),
            .filtered(
                .init(
                    filter: .and(
                        .init(
                            fields: [
                                .selector(
                                    .init(
                                        dimension: "type",
                                        value: "InsightShown"
                                    )
                                ),
                            ]
                        )
                    ),
                    aggregator: .thetaSketch(
                        .init(
                            name: "InsightShown",
                            fieldName: "clientUser"
                        )
                    )
                )
            ),
        ]

        let encodedAggregators = try JSONEncoder.telemetryEncoder.encode(aggregators)

        let expectedEncodedAggregators = """
        [
            {
              "aggregator": {
                "fieldName": "clientUser",
                "name": "newSessionBegan",
                "type": "thetaSketch"
              },
              "filter": {
                "dimension": "type",
                "type": "selector",
                "value": "newSessionBegan"
              },
              "name": "_namedFilteredAggregator",
              "type": "filtered"
            },
            {
              "aggregator": {
                "fieldName": "clientUser",
                "name": "InsightShown",
                "type": "thetaSketch"
              },
              "filter": {
                "fields": [
                  {
                    "dimension": "type",
                    "type": "selector",
                    "value": "InsightShown"
                  }
                ],
                "type": "and"
              },
              "type": "filtered"
            }
          ]
        """
        .filter { !$0.isWhitespace }

        #expect(String(data: encodedAggregators, encoding: .utf8)! == expectedEncodedAggregators)
    }

    @Test("UserCount aggregator") func userCountAggregator() throws {
        let stringRepresentation = """
        [
            {
              "type": "userCount"
            }
          ]
        """
        .filter { !$0.isWhitespace }

        let swiftRepresentation = [Aggregator.userCount(.init())]

        let decodedAggregators = try JSONDecoder.telemetryDecoder.decode([Aggregator].self, from: stringRepresentation.data(using: .utf8)!)
        #expect(decodedAggregators == swiftRepresentation)

        let encodedAggregators = try JSONEncoder.telemetryEncoder.encode(swiftRepresentation)
        #expect(String(data: encodedAggregators, encoding: .utf8)! == stringRepresentation)
    }

    @Test("EventCount aggregator") func eventCountAggregator() throws {
        let stringRepresentation = """
        [
            {
              "type": "eventCount"
            }
          ]
        """
        .filter { !$0.isWhitespace }

        let swiftRepresentation = [Aggregator.eventCount(.init())]

        let decodedAggregators = try JSONDecoder.telemetryDecoder.decode([Aggregator].self, from: stringRepresentation.data(using: .utf8)!)
        #expect(decodedAggregators == swiftRepresentation)

        let encodedAggregators = try JSONEncoder.telemetryEncoder.encode(swiftRepresentation)
        #expect(String(data: encodedAggregators, encoding: .utf8)! == stringRepresentation)
    }

    @Test("Histogram aggregator with defaults") func histogramAggregatorWithDefaults() throws {
        let stringRepresentation = """
        [
            {
              "type": "histogram"
            }
          ]
        """
        .filter { !$0.isWhitespace }

        let swiftRepresentation = [Aggregator.histogram(.init())]

        let decodedAggregators = try JSONDecoder.telemetryDecoder.decode([Aggregator].self, from: stringRepresentation.data(using: .utf8)!)
        #expect(decodedAggregators == swiftRepresentation)

        let encodedAggregators = try JSONEncoder.telemetryEncoder.encode(swiftRepresentation)
        #expect(String(data: encodedAggregators, encoding: .utf8)! == stringRepresentation)
    }

    @Test("Histogram aggregator with parameters") func histogramAggregatorWithParameters() throws {
        let stringRepresentation = """
        [
            {
              "fieldName": "anotherNumericalField",
              "k": 512,
              "name": "MyVeryCoolHistogram",
              "numBins": 25,
              "type": "histogram"
            }
          ]
        """
        .filter { !$0.isWhitespace }

        let swiftRepresentation = [Aggregator.histogram(.init(name: "MyVeryCoolHistogram", fieldName: "anotherNumericalField", splitPoints: nil, numBins: 25, k: 512))]

        let decodedAggregators = try JSONDecoder.telemetryDecoder.decode([Aggregator].self, from: stringRepresentation.data(using: .utf8)!)
        #expect(decodedAggregators == swiftRepresentation)

        let encodedAggregators = try JSONEncoder.telemetryEncoder.encode(swiftRepresentation)
        #expect(String(data: encodedAggregators, encoding: .utf8)! == stringRepresentation)
    }
}
