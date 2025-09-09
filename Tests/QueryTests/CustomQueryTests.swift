@testable import SwiftTQL
import XCTest

final class CustomQueryTests: XCTestCase {
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

    func testRegexQueryDecoding() throws {
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

        XCTAssertEqual(regexQuery.intervals, decodedQuery.intervals)
        XCTAssertEqual(regexQuery.queryType, decodedQuery.queryType)
        XCTAssertEqual(regexQuery.dataSource, decodedQuery.dataSource)
        XCTAssertEqual(regexQuery.descending, decodedQuery.descending)
        XCTAssertEqual(regexQuery.filter, decodedQuery.filter)
        XCTAssertEqual(regexQuery.granularity, decodedQuery.granularity)
        XCTAssertEqual(regexQuery.limit, decodedQuery.limit)
        XCTAssertEqual(regexQuery.dimensions, decodedQuery.dimensions)
        XCTAssertEqual(regexQuery, decodedQuery)
    }

    func testDimensionSpecEncoding() throws {
        let dimensionSpec = DimensionSpec.default(.init(dimension: "test", outputName: "test", outputType: .string))

        let encodedJSON = try JSONEncoder.telemetryEncoder.encode(dimensionSpec)

        let expectedOutput = """
        {"dimension":"test","outputName":"test","outputType":"STRING","type":"default"}
        """

        XCTAssertEqual(expectedOutput, String(data: encodedJSON, encoding: .utf8)!)
    }

    func testDimensionSpecDecoding() throws {
        let expectedOutput = DimensionSpec.default(.init(dimension: "test", outputName: "test", outputType: .string))

        let input = """
        {"outputName":"test","outputType":"STRING","type":"default","dimension":"test"}
        """.data(using: .utf8)!

        let decodedOutput = try JSONDecoder.telemetryDecoder.decode(DimensionSpec.self, from: input)

        XCTAssertEqual(expectedOutput, decodedOutput)
    }

    func testRegularExpressionExtractionFunctionEncoding() throws {
        let input = ExtractionFunction.regex(.init(expr: "abc", replaceMissingValue: false, replaceMissingValueWith: nil))

        let expectedOutput = """
        {"expr":"abc","index":1,"replaceMissingValue":false,"type":"regex"}
        """

        let encodedOutput = try JSONEncoder.telemetryEncoder.encode(input)

        XCTAssertEqual(expectedOutput, String(data: encodedOutput, encoding: .utf8)!)
    }

    func testRegularExpressionExtractionFunctionDecoding() throws {
        let input = """
        {"type":"regex","expr":"abc","index":1,"replaceMissingValue":true,"replaceMissingValueWith":"foobar"}
        """
        .data(using: .utf8)!

        let expectedOutput = ExtractionFunction.regex(.init(expr: "abc", index: 1, replaceMissingValue: true, replaceMissingValueWith: "foobar"))

        let decodedOutput = try JSONDecoder.telemetryDecoder.decode(ExtractionFunction.self, from: input)

        XCTAssertEqual(expectedOutput, decodedOutput)
    }

    func testRegularExpressionExtractionFunctionRawDecoding() throws {
        let input = """
        {"type":"regex","expr":"abc","index":1,"replaceMissingValue":true,"replaceMissingValueWith":"foobar"}
        """
        .data(using: .utf8)!

        let expectedOutput = RegularExpressionExtractionFunction(expr: "abc", index: 1, replaceMissingValue: true, replaceMissingValueWith: "foobar")

        let decodedOutput = try JSONDecoder.telemetryDecoder.decode(RegularExpressionExtractionFunction.self, from: input)

        XCTAssertTrue(decodedOutput.replaceMissingValue)
        XCTAssertEqual(expectedOutput, decodedOutput)
    }

    func testRegisteredLookupExtractionFunctionEncodingDefault() throws {
        let input = ExtractionFunction.registeredLookup(.init(lookup: "apps", retainMissingValue: true))

        let expectedOutput = """
        {"lookup":"apps","retainMissingValue":true,"type":"registeredLookup"}
        """

        let encodedOutput = try JSONEncoder.telemetryEncoder.encode(input)

        XCTAssertEqual(expectedOutput, String(data: encodedOutput, encoding: .utf8)!)
    }

    func testRegisteredLookupExtractionFunctionDecodingDefault() throws {
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

        XCTAssertEqual(expectedOutput, decodedOutput)
    }

    func testInlineLookupExtractionFunctionEncodingDefault() throws {
        let input = ExtractionFunction.inlineLookup(InlineLookupExtractionFunction(lookupMap: ["foo": "bar", "baz": "bat"]))

        let expectedOutput = """
        {"injective":true,"lookup":{"map":{"baz":"bat","foo":"bar"},"type":"map"},"retainMissingValue":true,"type":"lookup"}
        """

        let encodedOutput = try JSONEncoder.telemetryEncoder.encode(input)

        XCTAssertEqual(expectedOutput, String(data: encodedOutput, encoding: .utf8)!)
    }

    func testInlineLookupExtractionFunctionDecodingDefault() throws {
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

        XCTAssertEqual(expectedOutput, decodedOutput)
    }

    func testInlineLookupExtractionFunctionEncodingNonInjective() throws {
        let input = ExtractionFunction.inlineLookup(.init(lookupMap: ["foo": "bar", "baz": "bat"], retainMissingValue: false, injective: false, replaceMissingValueWith: "MISSING"))

        let expectedOutput = """
        {"injective":false,"lookup":{"map":{"baz":"bat","foo":"bar"},"type":"map"},"replaceMissingValueWith":"MISSING","retainMissingValue":false,"type":"lookup"}
        """

        let encodedOutput = try JSONEncoder.telemetryEncoder.encode(input)

        XCTAssertEqual(expectedOutput, String(data: encodedOutput, encoding: .utf8)!)
    }

    func testInlineLookupExtractionFunctionDecodingNonInjective() throws {
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

        XCTAssertEqual(expectedOutput, decodedOutput)
    }

    func testRegisteredLookupDimensionDecoding() throws {
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

        XCTAssertEqual(expectedOutput, decodedOutput)
    }

    func testExpandedGranularityDefinition() throws {
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

        XCTAssertEqual(regexQuery.granularity, decodedQuery.granularity)
    }

    func testExpandedDataSourceDefinition() throws {
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

        XCTAssertEqual(regexQuery.dataSource, decodedQuery.dataSource)
    }

    func testMinimalCustomQueryForFunnels() throws {
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

    func testScanQueryDecoding() throws {
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

        XCTAssertEqual(expectedOutput, decodedOutput)
    }

    func testScanQueryEncoding() throws {
        let input = CustomQuery(queryType: .scan, dataSource: "wikipedia", limit: 3, columns: [])

        let expectedOutput = """
        {"columns":[],"dataSource":"wikipedia","limit":3,"queryType":"scan"}
        """

        let encodedOutput = try JSONEncoder.telemetryEncoder.encode(input)

        XCTAssertEqual(expectedOutput, String(data: encodedOutput, encoding: .utf8)!)
    }

    func testTimeBoundaryQueryDecoding() throws {
        let input = """
         {
           "queryType": "timeBoundary",
           "dataSource": "wikipedia"
         }
        """.data(using: .utf8)!

        let expectedOutput = CustomQuery(queryType: .timeBoundary, dataSource: "wikipedia")

        let decodedOutput = try JSONDecoder.telemetryDecoder.decode(CustomQuery.self, from: input)

        XCTAssertEqual(expectedOutput, decodedOutput)
    }

    func testTimeBoundaryQueryEncoding() throws {
        let input = CustomQuery(queryType: .timeBoundary, dataSource: "wikipedia")

        let expectedOutput = """
        {"dataSource":"wikipedia","queryType":"timeBoundary"}
        """

        let encodedOutput = try JSONEncoder.telemetryEncoder.encode(input)

        XCTAssertEqual(expectedOutput, String(data: encodedOutput, encoding: .utf8)!)
    }

    func testChartConfiguration() throws {
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
        XCTAssertEqual(String(data: encoded, encoding: .utf8)!, encodedCustomQuery)

        let decoded = try JSONDecoder.telemetryDecoder.decode(CustomQuery.self, from: encoded)
        XCTAssertEqual(customQuery, decoded)
    }

    func testChartConfigurationDisabledAxis() throws {
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
        XCTAssertEqual(String(data: encoded, encoding: .utf8)!, encodedCustomQuery)

        let decoded = try JSONDecoder.telemetryDecoder.decode(CustomQuery.self, from: encoded)
        XCTAssertEqual(customQuery, decoded)
    }
}
