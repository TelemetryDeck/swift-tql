@testable import SwiftTQL
import Testing
import Foundation

struct PostAggregatorTests {
    @Test("ThetaSketch aggregator decoding")
    func thetaSketchAggregatorDecoding() throws {
        let examplePostAggregatorThetaSketchEstimate = """
        [
          {
            "type": "thetaSketchEstimate",
            "name": "app_launched_and_data_entered_count",
            "field": {
              "type": "thetaSketchSetOp",
              "name": "app_launched_and_data_entered_count",
              "func": "INTERSECT",
              "fields": [
                {
                  "type": "fieldAccess",
                  "fieldName": "appLaunchedByNotification_count"
                },
                {
                  "type": "fieldAccess",
                  "fieldName": "dataEntered_count"
                }
              ]
            }
          }
        ]
        """
        .filter { !$0.isWhitespace }
        .data(using: .utf8)!

        let decodedAggregators = try JSONDecoder.telemetryDecoder.decode([PostAggregator].self, from: examplePostAggregatorThetaSketchEstimate)

        #expect(
            decodedAggregators ==
            [
                .thetaSketchEstimate(.init(
                    name: "app_launched_and_data_entered_count",
                    field: .thetaSketchSetOp(.init(
                        name: "app_launched_and_data_entered_count",
                        func: .intersect,
                        fields: [
                            .fieldAccess(.init(type: .fieldAccess, fieldName: "appLaunchedByNotification_count")),
                            .fieldAccess(.init(type: .fieldAccess, fieldName: "dataEntered_count")),
                        ]
                    ))
                )),
            ]
        )
    }

    @Test("Percentage arithmetic decoding")
    func percentageArithmeticDecoding() throws {
        let examplePostAggregatorPercentage = """
        [{
            "type"   : "arithmetic",
            "name"   : "part_percentage",
            "fn"     : "*",
            "fields" : [
               { "type"   : "arithmetic",
                 "name"   : "ratio",
                 "fn"     : "/",
                 "fields" : [
                   { "type" : "fieldAccess", "name" : "part", "fieldName" : "part" },
                   { "type" : "fieldAccess", "name" : "tot", "fieldName" : "tot" }
                 ]
               },
               { "type" : "constant", "name": "const", "value" : 100 }
            ]
          }]
        """
        .filter { !$0.isWhitespace }
        .data(using: .utf8)!

        let decodedAggregators = try JSONDecoder.telemetryDecoder.decode([PostAggregator].self, from: examplePostAggregatorPercentage)

        #expect(
            decodedAggregators ==
            [
                PostAggregator.arithmetic(.init(
                    name: "part_percentage",
                    function: .multiplication,
                    fields: [
                        .arithmetic(.init(
                            name: "ratio",
                            function: .division, fields: [
                                .fieldAccess(.init(type: .fieldAccess, name: "part", fieldName: "part")),
                                .fieldAccess(.init(type: .fieldAccess, name: "tot", fieldName: "tot")),
                            ]
                        )),
                        PostAggregator.constant(.init(name: "const", value: 100)),
                    ]
                )),
            ]
        )
    }

    @Test("PostAggregator expression decoding")
    func postAggregatorExpressionDecoding() throws {
        let examplePostAggregatorExpression = """
        [{
            "type"       : "expression",
            "name"       : "part_percentage",
            "expression" : "100 * (part / tot)"
          }]
        """
        .filter { !$0.isWhitespace }
        .data(using: .utf8)!

        let decodedAggregators = try JSONDecoder.telemetryDecoder.decode([PostAggregator].self, from: examplePostAggregatorExpression)

        #expect(
            decodedAggregators ==
            [
                .expression(.init(name: "part_percentage", expression: "100*(part/tot)")),
            ]
        )
    }

    @Test("PostAggregator arithmetic decoding")
    func postAggregatorArithmeticDecoding() throws {
        let examplePostAggregatorArithmetic = """
        [{
            "type"   : "arithmetic",
            "name"   : "average",
            "fn"     : "/",
            "fields" : [
                   { "type" : "fieldAccess", "name" : "tot", "fieldName" : "tot" },
                   { "type" : "fieldAccess", "name" : "rows", "fieldName" : "rows" }
                 ]
          }]
        """
        .filter { !$0.isWhitespace }
        .data(using: .utf8)!

        let decodedAggregators = try JSONDecoder.telemetryDecoder.decode([PostAggregator].self, from: examplePostAggregatorArithmetic)

        #expect(decodedAggregators == [
            PostAggregator.arithmetic(.init(
                name: "average",
                function: .division,
                fields: [
                    .fieldAccess(.init(type: .fieldAccess, name: "tot", fieldName: "tot")),
                    .fieldAccess(.init(type: .fieldAccess, name: "rows", fieldName: "rows")),
                ]
            )),
        ])
    }

    @Test("HyperUnique decoding")
    func hyperUniqueDecoding() throws {
        let exampleHyperUnique = """
        [{
            "type"   : "arithmetic",
            "name"   : "average_users_per_row",
            "fn"     : "/",
            "fields" : [
              { "type" : "hyperUniqueCardinality", "fieldName" : "unique_users" },
              { "type" : "fieldAccess", "name" : "rows", "fieldName" : "rows" }
            ]
          }]
        """
        .filter { !$0.isWhitespace }
        .data(using: .utf8)!

        let decodedAggregators = try JSONDecoder.telemetryDecoder.decode([PostAggregator].self, from: exampleHyperUnique)

        #expect(decodedAggregators == [
            PostAggregator.arithmetic(.init(
                name: "average_users_per_row",
                function: .division,
                fields: [
                    .hyperUniqueCardinality(.init(fieldName: "unique_users")),
                    .fieldAccess(.init(type: .fieldAccess, name: "rows", fieldName: "rows")),
                ]
            )),
        ])
    }

    @Test("ZScore 2 sample codable")
    func zScore2SampleCodable() throws {
        let example = """
        [{
            "name": "zscore",
            "sample1Size": {
              "fieldName": "_cohort_0",
              "type": "finalizingFieldAccess"
            },
            "sample2Size": {
              "fieldName": "_cohort_1",
              "type": "finalizingFieldAccess"
            },
            "successCount1": {
              "fieldName": "_cohort_0_success_0",
              "type": "finalizingFieldAccess"
            },
            "successCount2": {
              "fieldName": "_cohort_1_success_0",
              "type": "finalizingFieldAccess"
            },
            "type": "zscore2sample"
          }]
        """
        .filter { !$0.isWhitespace }

        let postAggregators = [
            PostAggregator.zscore2sample(.init(
                name: "zscore",
                sample1Size: .finalizingFieldAccess(.init(
                    type: .finalizingFieldAccess,
                    fieldName: "_cohort_0"
                )),
                successCount1: .finalizingFieldAccess(.init(
                    type: .finalizingFieldAccess,
                    fieldName: "_cohort_0_success_0"
                )),
                sample2Size: .finalizingFieldAccess(.init(
                    type: .finalizingFieldAccess,
                    fieldName: "_cohort_1"
                )),
                successCount2: .finalizingFieldAccess(.init(
                    type: .finalizingFieldAccess,
                    fieldName: "_cohort_1_success_0"
                ))
            )),
        ]

        let decodedAggregators = try JSONDecoder.telemetryDecoder.decode([PostAggregator].self, from: example.data(using: .utf8)!)
        #expect(decodedAggregators == postAggregators)

        let encodedAggregators = try JSONEncoder.telemetryEncoder.encode(postAggregators)
        #expect(String(data: encodedAggregators, encoding: .utf8) == example)
    }

    @Test("P-value codable")
    func pValueCodable() throws {
        let example = """
        [{
            "name": "pvalue",
            "type": "pvalue2tailedZtest",
            "zScore": {
              "fieldName": "zscore",
              "type": "fieldAccess"
            }
          }]
        """
        .filter { !$0.isWhitespace }

        let postAggregators = [
            PostAggregator.pvalue2tailedZtest(.init(
                name: "pvalue",
                zScore: .fieldAccess(.init(type: .fieldAccess, fieldName: "zscore"))
            )),
        ]

        let decodedAggregators = try JSONDecoder.telemetryDecoder.decode([PostAggregator].self, from: example.data(using: .utf8)!)
        #expect(decodedAggregators == postAggregators)

        let encodedAggregators = try JSONEncoder.telemetryEncoder.encode(postAggregators)
        #expect(String(data: encodedAggregators, encoding: .utf8) == example)
    }

    @Test("Quantiles doubles sketch to quantile post aggregator")
    func quantilesDoublesSketchToQuantilePostAggregator() throws {
        let stringRepresentation = """
        [{
            "field":  { "fieldName" : "someFieldName", "name" : "someField", "type" : "fieldAccess" },
            "fraction": 0.5,
            "name": "testtest",
            "type": "quantilesDoublesSketchToQuantile"
        }]
        """
        .filter { !$0.isWhitespace }

        let swiftRepresentation = [
            PostAggregator.quantilesDoublesSketchToQuantile(.init(
                name: "testtest",
                field: .fieldAccess(.init(type: .fieldAccess, name: "someField", fieldName: "someFieldName")),
                fraction: 0.5
            )),
        ]

        let decodedPostAggregators = try JSONDecoder.telemetryDecoder.decode([PostAggregator].self, from: stringRepresentation.data(using: .utf8)!)
        #expect(decodedPostAggregators == swiftRepresentation)

        let encodedPostAggregators = try JSONEncoder.telemetryEncoder.encode(swiftRepresentation)
        #expect(String(data: encodedPostAggregators, encoding: .utf8)! == stringRepresentation)
    }

    @Test("Quantiles doubles sketch to quantiles post aggregator")
    func quantilesDoublesSketchToQuantilesPostAggregator() throws {
        let stringRepresentation = """
        [{
            "field":  { "fieldName" : "someFieldName", "name" : "someField", "type" : "fieldAccess" },
            "fractions": [0.25, 0.5, 0.75],
            "name": "testtest",
            "type": "quantilesDoublesSketchToQuantiles"
        }]
        """
        .filter { !$0.isWhitespace }

        let swiftRepresentation = [
            PostAggregator.quantilesDoublesSketchToQuantiles(.init(
                name: "testtest",
                field: .fieldAccess(.init(type: .fieldAccess, name: "someField", fieldName: "someFieldName")),
                fractions: [0.25, 0.5, 0.75]
            )),
        ]

        let decodedPostAggregators = try JSONDecoder.telemetryDecoder.decode([PostAggregator].self, from: stringRepresentation.data(using: .utf8)!)
        #expect(decodedPostAggregators == swiftRepresentation)

        let encodedPostAggregators = try JSONEncoder.telemetryEncoder.encode(swiftRepresentation)
        #expect(String(data: encodedPostAggregators, encoding: .utf8)! == stringRepresentation)
    }

    @Test("Quantiles doubles sketch to histogram post aggregator")
    func quantilesDoublesSketchToHistogramPostAggregator() throws {
        let stringRepresentation = """
        [{
            "field":  { "fieldName" : "someFieldName", "name" : "someField", "type" : "fieldAccess" },
            "name": "testtest",
            "numBins": 25,
            "type": "quantilesDoublesSketchToHistogram"
        }]
        """
        .filter { !$0.isWhitespace }

        let swiftRepresentation = [
            PostAggregator.quantilesDoublesSketchToHistogram(.init(
                name: "testtest",
                field: .fieldAccess(.init(type: .fieldAccess, name: "someField", fieldName: "someFieldName")),
                numBins: 25
            )),
        ]

        let decodedPostAggregators = try JSONDecoder.telemetryDecoder.decode([PostAggregator].self, from: stringRepresentation.data(using: .utf8)!)
        #expect(decodedPostAggregators == swiftRepresentation)

        let encodedPostAggregators = try JSONEncoder.telemetryEncoder.encode(swiftRepresentation)
        #expect(String(data: encodedPostAggregators, encoding: .utf8)! == stringRepresentation)
    }

    @Test("Quantiles doubles sketch to rank post aggregator")
    func quantilesDoublesSketchToRankPostAggregator() throws {
        let stringRepresentation = """
        [{
            "field":  { "fieldName" : "someFieldName", "name" : "someField", "type" : "fieldAccess" },
            "name": "testtest",
            "type": "quantilesDoublesSketchToRank",
            "value": 1000
        }]
        """
        .filter { !$0.isWhitespace }

        let swiftRepresentation = [
            PostAggregator.quantilesDoublesSketchToRank(.init(
                name: "testtest",
                field: .fieldAccess(.init(type: .fieldAccess, name: "someField", fieldName: "someFieldName")),
                value: 1000
            )),
        ]

        let decodedPostAggregators = try JSONDecoder.telemetryDecoder.decode([PostAggregator].self, from: stringRepresentation.data(using: .utf8)!)
        #expect(decodedPostAggregators == swiftRepresentation)

        let encodedPostAggregators = try JSONEncoder.telemetryEncoder.encode(swiftRepresentation)
        #expect(String(data: encodedPostAggregators, encoding: .utf8)! == stringRepresentation)
    }

    @Test("Quantiles doubles sketch to CDF post aggregator")
    func quantilesDoublesSketchToCDFPostAggregator() throws {
        let stringRepresentation = """
        [{
            "field":  { "fieldName" : "someFieldName", "name" : "someField", "type" : "fieldAccess" },
            "name": "testtest",
            "splitPoints": [0.25, 0.5, 0.75],
            "type": "quantilesDoublesSketchToCDF"
        }]
        """
        .filter { !$0.isWhitespace }

        let swiftRepresentation = [
            PostAggregator.quantilesDoublesSketchToCDF(.init(
                name: "testtest",
                field: .fieldAccess(.init(type: .fieldAccess, name: "someField", fieldName: "someFieldName")),
                splitPoints: [0.25, 0.5, 0.75]
            )),
        ]

        let decodedPostAggregators = try JSONDecoder.telemetryDecoder.decode([PostAggregator].self, from: stringRepresentation.data(using: .utf8)!)
        #expect(decodedPostAggregators == swiftRepresentation)

        let encodedPostAggregators = try JSONEncoder.telemetryEncoder.encode(swiftRepresentation)
        #expect(String(data: encodedPostAggregators, encoding: .utf8)! == stringRepresentation)
    }

    @Test("Quantiles doubles sketch to string post aggregator")
    func quantilesDoublesSketchToStringPostAggregator() throws {
        let stringRepresentation = """
        [{
            "field":  { "fieldName" : "someFieldName", "name" : "someField", "type" : "fieldAccess" },
            "name": "testtest",
            "type": "quantilesDoublesSketchToString"
        }]
        """
        .filter { !$0.isWhitespace }

        let swiftRepresentation = [
            PostAggregator.quantilesDoublesSketchToString(.init(
                name: "testtest",
                field: .fieldAccess(.init(type: .fieldAccess, name: "someField", fieldName: "someFieldName"))
            )),
        ]

        let decodedPostAggregators = try JSONDecoder.telemetryDecoder.decode([PostAggregator].self, from: stringRepresentation.data(using: .utf8)!)
        #expect(decodedPostAggregators == swiftRepresentation)

        let encodedPostAggregators = try JSONEncoder.telemetryEncoder.encode(swiftRepresentation)
        #expect(String(data: encodedPostAggregators, encoding: .utf8)! == stringRepresentation)
    }
}