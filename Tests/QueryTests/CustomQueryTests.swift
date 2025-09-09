@testable import SwiftTQL
import Testing
import Foundation

struct CustomQueryTests {
    let randomDate = Date(timeIntervalSinceReferenceDate: 656_510_400) // Thursday, October 21, 2021 2:00:00 PM GMT+02:00

    let exampleDruidRegexJSON = """
    {
        "queryType": "groupBy",
        "dataSource": "telemetry-signals",
        "intervals": [
            "2021-10-21T12:00:00Z/2021-10-21T12:00:00Z"
        ],
        "granularity": "all",
        "dimensions": [
            {
                "type": "default",
                "dimension": "appID",
                "outputName": "appID",
                "outputType": "STRING"
            },
            {
                "type": "extraction",
                "dimension": "payload",
                "outputName": "payload",
                "outputType": "STRING",
                "extractionFn": {
                    "type": "regex",
                    "expr": "(.*:).*",
                    "index": 1,
                    "replaceMissingValue": true,
                    "replaceMissingValueWith": "foobar"
                }
            }
        ],
        "descending": false
    }
    """
    .filter { !$0.isWhitespace }
    .data(using: .utf8)!

    @Test("Regex query decoding") func regexQueryDecoding() throws {
        let regexQuery = CustomQuery(
            queryType: .groupBy,
            dataSource: "telemetry-signals",
            descending: false,
            filter: nil,
            intervals: [.init(beginningDate: randomDate, endDate: randomDate)],
            granularity: .all,
            aggregations: nil,
            limit: nil,
            context: nil,
            dimensions: [
                .default(.init(
                    dimension: "appID",
                    outputName: "appID",
                    outputType: .string
                )),
                .extraction(.init(
                    dimension: "payload",
                    outputName: "payload",
                    outputType: .string,
                    extractionFn: .regex(.init(
                        expr: "(.*:).*",
                        replaceMissingValue: true,
                        replaceMissingValueWith: "foobar"
                    ))
                )),
            ]
        )

        let decodedQuery = try JSONDecoder.telemetryDecoder.decode(CustomQuery.self, from: exampleDruidRegexJSON)

        #expect(regexQuery.intervals == decodedQuery.intervals)
        #expect(regexQuery.queryType == decodedQuery.queryType)
        #expect(regexQuery.dataSource == decodedQuery.dataSource)
        #expect(regexQuery.descending == decodedQuery.descending)
        #expect(regexQuery.filter == decodedQuery.filter)
        #expect(regexQuery.granularity == decodedQuery.granularity)
        #expect(regexQuery.limit == decodedQuery.limit)
        #expect(regexQuery.dimensions == decodedQuery.dimensions)
        #expect(regexQuery == decodedQuery)
    }

    @Test("Dimension spec encoding") func dimensionSpecEncoding() throws {
        let dimensionSpec = DimensionSpec.default(.init(dimension: "test", outputName: "test", outputType: .string))

        let encodedJSON = try JSONEncoder.telemetryEncoder.encode(dimensionSpec)

        let expectedOutput = """
        {"dimension":"test","outputName":"test","outputType":"STRING","type":"default"}
        """

        #expect(expectedOutput == String(data: encodedJSON, encoding: .utf8)!)
    }

    @Test("Dimension spec decoding") func dimensionSpecDecoding() throws {
        let expectedOutput = DimensionSpec.default(.init(dimension: "test", outputName: "test", outputType: .string))

        let input = """
        {"outputName":"test","outputType":"STRING","type":"default","dimension":"test"}
        """.data(using: .utf8)!

        let decodedOutput = try JSONDecoder.telemetryDecoder.decode(DimensionSpec.self, from: input)

        #expect(expectedOutput == decodedOutput)
    }

    @Test("Regular expression extraction function encoding") func regularExpressionExtractionFunctionEncoding() throws {
        let input = ExtractionFunction.regex(.init(expr: "abc", replaceMissingValue: false, replaceMissingValueWith: nil))

        let expectedOutput = """
        {"expr":"abc","index":1,"replaceMissingValue":false,"type":"regex"}
        """

        let encodedOutput = try JSONEncoder.telemetryEncoder.encode(input)

        #expect(expectedOutput == String(data: encodedOutput, encoding: .utf8)!)
    }

    @Test("Regular expression extraction function decoding") func regularExpressionExtractionFunctionDecoding() throws {
        let input = """
        {"type":"regex","expr":"abc","index":1,"replaceMissingValue":true,"replaceMissingValueWith":"foobar"}
        """
        .data(using: .utf8)!

        let expectedOutput = ExtractionFunction.regex(.init(expr: "abc", index: 1, replaceMissingValue: true, replaceMissingValueWith: "foobar"))

        let decodedOutput = try JSONDecoder.telemetryDecoder.decode(ExtractionFunction.self, from: input)

        #expect(expectedOutput == decodedOutput)
    }

    @Test("Regular expression extraction function raw decoding") func regularExpressionExtractionFunctionRawDecoding() throws {
        let input = """
        {"type":"regex","expr":"abc","index":1,"replaceMissingValue":true,"replaceMissingValueWith":"foobar"}
        """
        .data(using: .utf8)!

        let expectedOutput = RegularExpressionExtractionFunction(expr: "abc", index: 1, replaceMissingValue: true, replaceMissingValueWith: "foobar")

        let decodedOutput = try JSONDecoder.telemetryDecoder.decode(RegularExpressionExtractionFunction.self, from: input)

        #expect(decodedOutput.replaceMissingValue)
        #expect(expectedOutput == decodedOutput)
    }

    @Test("Registered lookup extraction function encoding default") func registeredLookupExtractionFunctionEncodingDefault() throws {
        let input = ExtractionFunction.registeredLookup(.init(lookup: "apps", retainMissingValue: true))

        let expectedOutput = """
        {"lookup":"apps","retainMissingValue":true,"type":"registeredLookup"}
        """

        let encodedOutput = try JSONEncoder.telemetryEncoder.encode(input)

        #expect(expectedOutput == String(data: encodedOutput, encoding: .utf8)!)
    }

    @Test("Registered lookup extraction function decoding default") func registeredLookupExtractionFunctionDecodingDefault() throws {
        let input = """
        {
          "type": "registeredLookup",
          "lookup": "apps",
          "retainMissingValue": true
        }
        """
        .data(using: .utf8)!

        let expectedOutput = ExtractionFunction.registeredLookup(.init(lookup: "apps", retainMissingValue: true))

        let decodedOutput = try JSONDecoder.telemetryDecoder.decode(ExtractionFunction.self, from: input)

        #expect(expectedOutput == decodedOutput)
    }

    @Test("Inline lookup extraction function encoding default") func inlineLookupExtractionFunctionEncodingDefault() throws {
        let input = ExtractionFunction.inlineLookup(InlineLookupExtractionFunction(lookupMap: ["foo": "bar", "baz": "bat"]))

        let expectedOutput = """
        {"injective":true,"lookup":{"map":{"baz":"bat","foo":"bar"},"type":"map"},"retainMissingValue":true,"type":"lookup"}
        """

        let encodedOutput = try JSONEncoder.telemetryEncoder.encode(input)

        #expect(expectedOutput == String(data: encodedOutput, encoding: .utf8)!)
    }

    @Test("Inline lookup extraction function decoding default") func inlineLookupExtractionFunctionDecodingDefault() throws {
        let input = """
        {
          "type":"lookup",
          "lookup":{
            "type":"map",
            "map":{"foo":"bar", "baz":"bat"}
          },
          "retainMissingValue":true,
          "injective":true
        }
        """
        .data(using: .utf8)!

        let expectedOutput = ExtractionFunction.inlineLookup(.init(lookupMap: ["foo": "bar", "baz": "bat"]))

        let decodedOutput = try JSONDecoder.telemetryDecoder.decode(ExtractionFunction.self, from: input)

        #expect(expectedOutput == decodedOutput)
    }

    @Test("Inline lookup extraction function encoding non-injective") func inlineLookupExtractionFunctionEncodingNonInjective() throws {
        let input = ExtractionFunction.inlineLookup(.init(lookupMap: ["foo": "bar", "baz": "bat"], retainMissingValue: false, injective: false, replaceMissingValueWith: "MISSING"))

        let expectedOutput = """
        {"injective":false,"lookup":{"map":{"baz":"bat","foo":"bar"},"type":"map"},"replaceMissingValueWith":"MISSING","retainMissingValue":false,"type":"lookup"}
        """

        let encodedOutput = try JSONEncoder.telemetryEncoder.encode(input)

        #expect(expectedOutput == String(data: encodedOutput, encoding: .utf8)!)
    }

    @Test("Inline lookup extraction function decoding non-injective") func inlineLookupExtractionFunctionDecodingNonInjective() throws {
        let input = """
        {
          "type":"lookup",
          "lookup":{
            "type":"map",
            "map":{"foo":"bar", "baz":"bat"}
          },
          "retainMissingValue":false,
          "injective":false,
          "replaceMissingValueWith":"MISSING"
        }
        """
        .data(using: .utf8)!

        let expectedOutput = ExtractionFunction.inlineLookup(.init(lookupMap: ["foo": "bar", "baz": "bat"], retainMissingValue: false, injective: false, replaceMissingValueWith: "MISSING"))

        let decodedOutput = try JSONDecoder.telemetryDecoder.decode(ExtractionFunction.self, from: input)

        #expect(expectedOutput == decodedOutput)
    }

    @Test("Registered lookup dimension decoding") func registeredLookupDimensionDecoding() throws {
        let input = """
        {
            "dimension": "appID",
            "extractionFn": {
              "type": "registeredLookup",
              "lookup": "apps",
              "retainMissingValue": true
            },
            "outputName": "App",
            "type": "extraction"
          }
        """
        .data(using: .utf8)!

        let expectedOutput = DimensionSpec.extraction(.init(dimension: "appID", outputName: "App", extractionFn: .registeredLookup(.init(lookup: "apps", retainMissingValue: true))))

        let decodedOutput = try JSONDecoder.telemetryDecoder.decode(DimensionSpec.self, from: input)

        #expect(expectedOutput == decodedOutput)
    }

    @Test("Expanded granularity definition") func expandedGranularityDefinition() throws {
        let exampleJSON = """
        {
            "queryType": "groupBy",
            "dataSource": "telemetry-signals",
            "intervals": [
                "2021-10-21T12:00:00Z/2021-10-21T12:00:00Z"
            ],
            "granularity": {"type": "all"},
            "dimensions": [
                {
                    "type": "default",
                    "dimension": "appID",
                    "outputName": "appID",
                    "outputType": "STRING"
                },
                {
                    "type": "extraction",
                    "dimension": "payload",
                    "outputName": "payload",
                    "outputType": "STRING",
                    "extractionFn": {
                        "type": "regex",
                        "expr": "(.*:).*",
                        "index": 1,
                        "replaceMissingValue": true,
                        "replaceMissingValueWith": "foobar"
                    }
                }
            ],
            "descending": false
        }
        """
        .filter { !$0.isWhitespace }
        .data(using: .utf8)!

        let regexQuery = CustomQuery(
            queryType: .groupBy,
            dataSource: "telemetry-signals",
            descending: false,
            filter: nil,
            intervals: [],
            granularity: .all,
            aggregations: nil,
            limit: nil,
            context: nil,
            dimensions: []
        )

        let decodedQuery = try JSONDecoder.telemetryDecoder.decode(CustomQuery.self, from: exampleJSON)

        #expect(regexQuery.granularity == decodedQuery.granularity)
    }

    @Test("Expanded data source definition") func expandedDataSourceDefinition() throws {
        let exampleJSON = """
        {
            "queryType": "groupBy",
            "dataSource":{"type":"table","name":"telemetry-signals"},
            "intervals": [
                "2021-10-21T12:00:00Z/2021-10-21T12:00:00Z"
            ],
            "granularity": {"type": "all"},
            "dimensions": [
                {
                    "type": "default",
                    "dimension": "appID",
                    "outputName": "appID",
                    "outputType": "STRING"
                },
                {
                    "type": "extraction",
                    "dimension": "payload",
                    "outputName": "payload",
                    "outputType": "STRING",
                    "extractionFn": {
                        "type": "regex",
                        "expr": "(.*:).*",
                        "index": 1,
                        "replaceMissingValue": true,
                        "replaceMissingValueWith": "foobar"
                    }
                }
            ],
            "descending": false
        }
        """
        .filter { !$0.isWhitespace }
        .data(using: .utf8)!

        let regexQuery = CustomQuery(
            queryType: .groupBy,
            dataSource: "telemetry-signals",
            descending: false,
            filter: nil,
            intervals: [],
            granularity: .all,
            aggregations: nil,
            limit: nil,
            context: nil,
            dimensions: []
        )

        let decodedQuery = try JSONDecoder.telemetryDecoder.decode(CustomQuery.self, from: exampleJSON)

        #expect(regexQuery.dataSource == decodedQuery.dataSource)
    }

    @Test("Minimal custom query for funnels") func minimalCustomQueryForFunnels() throws {
        // just ensuring this compiles
        _ = CustomQuery(
            queryType: .funnel,
            granularity: .all,
            steps: [
                .init(filter: .selector(.init(dimension: "something", value: "one")), name: "Step One"),
                .init(filter: .selector(.init(dimension: "other", value: "two")), name: "Step Twp"),
            ]
        )
    }

    @Test("Scan query decoding") func scanQueryDecoding() throws {
        let input = """
         {
           "queryType": "scan",
           "dataSource": "wikipedia",
           "columns":[],
           "limit":3,
            "order": "ascending"
         }
        """.data(using: .utf8)!

        let expectedOutput = CustomQuery(queryType: .scan, dataSource: "wikipedia", limit: 3, columns: [], order: .ascending)

        let decodedOutput = try JSONDecoder.telemetryDecoder.decode(CustomQuery.self, from: input)

        #expect(expectedOutput == decodedOutput)
    }

    @Test("Scan query encoding") func scanQueryEncoding() throws {
        let input = CustomQuery(queryType: .scan, dataSource: "wikipedia", limit: 3, columns: [])

        let expectedOutput = """
        {"columns":[],"dataSource":"wikipedia","limit":3,"queryType":"scan"}
        """

        let encodedOutput = try JSONEncoder.telemetryEncoder.encode(input)

        #expect(expectedOutput == String(data: encodedOutput, encoding: .utf8)!)
    }

    @Test("Time boundary query decoding") func timeBoundaryQueryDecoding() throws {
        let input = """
         {
           "queryType": "timeBoundary",
           "dataSource": "wikipedia"
         }
        """.data(using: .utf8)!

        let expectedOutput = CustomQuery(queryType: .timeBoundary, dataSource: "wikipedia")

        let decodedOutput = try JSONDecoder.telemetryDecoder.decode(CustomQuery.self, from: input)

        #expect(expectedOutput == decodedOutput)
    }

    @Test("Time boundary query encoding") func timeBoundaryQueryEncoding() throws {
        let input = CustomQuery(queryType: .timeBoundary, dataSource: "wikipedia")

        let expectedOutput = """
        {"dataSource":"wikipedia","queryType":"timeBoundary"}
        """

        let encodedOutput = try JSONEncoder.telemetryEncoder.encode(input)

        #expect(expectedOutput == String(data: encodedOutput, encoding: .utf8)!)
    }

    @Test("Chart configuration") func chartConfiguration() throws {
        let customQuery = CustomQuery(
            queryType: .timeseries,
            dataSource: "telemetry-signals",
            granularity: .all,
            chartConfiguration: .init(displayMode: .barChart, darkMode: false)
        )

        let encodedCustomQuery = """
        {
            "chartConfiguration": {
                "darkMode": false,
                "displayMode": "barChart"
            },
            "dataSource": "telemetry-signals",
            "granularity": "all",
            "queryType": "timeseries"
        }
        """
        .filter { !$0.isWhitespace }

        let encoded = try JSONEncoder.telemetryEncoder.encode(customQuery)
        #expect(String(data: encoded, encoding: .utf8)! == encodedCustomQuery)

        let decoded = try JSONDecoder.telemetryDecoder.decode(CustomQuery.self, from: encoded)
        #expect(customQuery == decoded)
    }

    @Test("Chart configuration disabled axis") func chartConfigurationDisabledAxis() throws {
        let customQuery = CustomQuery(
            queryType: .timeseries,
            dataSource: "telemetry-signals",
            granularity: .all,
            chartConfiguration: ChartConfiguration(options: ChartConfigurationOptions(xAxis: .init(show: false)))
        )

        let encodedCustomQuery = """
        {
            "chartConfiguration": {
                "options": {
                    "xAxis": {
                        "show": false
                    }
                }
            },
            "dataSource": "telemetry-signals",
            "granularity": "all",
            "queryType": "timeseries"
        }
        """
        .filter { !$0.isWhitespace }

        let encoded = try JSONEncoder.telemetryEncoder.encode(customQuery)
        #expect(String(data: encoded, encoding: .utf8)! == encodedCustomQuery)

        let decoded = try JSONDecoder.telemetryDecoder.decode(CustomQuery.self, from: encoded)
        #expect(customQuery == decoded)
    }
}
