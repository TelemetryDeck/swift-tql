@testable import DataTransferObjects
import XCTest

final class DruidQueryTests: XCTestCase {

    let exampleDruidRegexJSON = """
    {
        "queryType": "groupBy",
        "dataSource": "telemetry-signals",
        "intervals": [
            "2021-11-15T19:18:43Z/2021-12-31T15:36:27Z"
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
                    "replaceMissingValue": true,
                    "replaceMissingValueWith": "foobar"
                }
            }
        ],
        "descending": false
    }
    """
    .data(using: .utf8)!
    
    func testRegeQueryDecoding() {
        XCTAssertNoThrow(try JSONDecoder.druidDecoder.decode(DruidCustomQuery.self, from: self.exampleDruidRegexJSON))
    }
    
    func testRegexQueryEncoding() {
        let regexQuery = DruidCustomQuery(
            queryType: .groupBy,
            dataSource: "telemetry-signals",
            descending: false,
            filter: nil,
            intervals: [.init(beginningDate: Date() - 3600*24*30, endDate: Date())],
            granularity: .all,
            aggregations: nil,
            limit: nil,
            context: nil)
        
        XCTFail("This test does not check against the output yet, and it does not include the regex extraction yet.")
    }
    
    func testDimensionSpecEncoding() throws {
        let dimensionSpec = DimensionSpec(type: .default, dimension: "test", outputName: "test", outputType: .string)
        
        let encodedJSON = try JSONEncoder.druidEncoder.encode(dimensionSpec)
        
        let expectedOutput = """
            {"outputName":"test","outputType":"STRING","type":"default","dimension":"test"}
            """
        
        XCTAssertEqual(expectedOutput, String(data: encodedJSON, encoding: .utf8)!)
    }
    
    func testDimensionSpecDecoding() throws {
        let expectedOutput = DimensionSpec(type: .default, dimension: "test", outputName: "test", outputType: .string)
        
        let input = """
            {"outputName":"test","outputType":"STRING","type":"default","dimension":"test"}
            """.data(using: .utf8)!
        
        let decodedOutput = try JSONDecoder.druidDecoder.decode(DimensionSpec.self, from: input)
        
        XCTAssertEqual(expectedOutput, decodedOutput)
    }
}
