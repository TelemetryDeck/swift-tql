// swiftlint:disable line_length

import SwiftTQL
import Testing
import Foundation

struct SQLQueryConversionTests {
    let sqlQuery = """
    SELECT majorSystemVersion, SUM("count") "Count" FROM "telemetry-signals" GROUP BY 1 ORDER BY 2 ASC
    """

    let planJSON = """
    [
      {
        "PLAN": "[{\\\"query\\\":{\\\"queryType\\\":\\\"groupBy\\\",\\\"dataSource\\\":{\\\"type\\\":\\\"table\\\",\\\"name\\\":\\\"telemetry-signals\\\"},\\\"intervals\\\":{\\\"type\\\":\\\"intervals\\\",\\\"intervals\\\":[\\\"-146136543-09-08T08:23:32.096Z/146140482-04-24T15:36:27.903Z\\\"]},\\\"granularity\\\":{\\\"type\\\":\\\"all\\\"},\\\"dimensions\\\":[{\\\"type\\\":\\\"default\\\",\\\"dimension\\\":\\\"majorSystemVersion\\\",\\\"outputName\\\":\\\"d0\\\",\\\"outputType\\\":\\\"STRING\\\"}],\\\"aggregations\\\":[{\\\"type\\\":\\\"longSum\\\",\\\"name\\\":\\\"a0\\\",\\\"fieldName\\\":\\\"count\\\"}],\\\"limitSpec\\\":{\\\"type\\\":\\\"default\\\",\\\"columns\\\":[{\\\"dimension\\\":\\\"a0\\\",\\\"direction\\\":\\\"ascending\\\",\\\"dimensionOrder\\\":{\\\"type\\\":\\\"numeric\\\"}}]},\\\"context\\\":{\\\"sqlQueryId\\\":\\\"5c233022-b521-4e6b-b390-ca161188f17e\\\"}},\\\"signature\\\":[{\\\"name\\\":\\\"d0\\\",\\\"type\\\":\\\"STRING\\\"},{\\\"name\\\":\\\"a0\\\",\\\"type\\\":\\\"LONG\\\"}]}]",
        "RESOURCES": "[{\\\"name\\\":\\\"telemetry-signals\\\",\\\"type\\\":\\\"DATASOURCE\\\"}]"
      }
    ]
    """
    .data(using: .utf8)!

    @Test("SQL query conversion request encoding produces correct JSON")
    func encodingConversionRequest() throws {
        let input = SQLQueryConversionRequest(query: sqlQuery)
        let expectedOutput = "{\"query\":\"SELECT majorSystemVersion, SUM(\\\"count\\\") \\\"Count\\\" FROM \\\"telemetry-signals\\\" GROUP BY 1 ORDER BY 2 ASC\"}"
        let output = try JSONEncoder.telemetryEncoder.encode(input)
        let outputString = String(data: output, encoding: .utf8)

        #expect(expectedOutput == outputString)
    }

    @Test("SQL query conversion response decoding parses JSON correctly")
    func decodingConversionResponse() throws {
        let expectedOutput = [SQLQueryConversionResponseItem(plan: "[{\"query\":{\"queryType\":\"groupBy\",\"dataSource\":{\"type\":\"table\",\"name\":\"telemetry-signals\"},\"intervals\":{\"type\":\"intervals\",\"intervals\":[\"-146136543-09-08T08:23:32.096Z/146140482-04-24T15:36:27.903Z\"]},\"granularity\":{\"type\":\"all\"},\"dimensions\":[{\"type\":\"default\",\"dimension\":\"majorSystemVersion\",\"outputName\":\"d0\",\"outputType\":\"STRING\"}],\"aggregations\":[{\"type\":\"longSum\",\"name\":\"a0\",\"fieldName\":\"count\"}],\"limitSpec\":{\"type\":\"default\",\"columns\":[{\"dimension\":\"a0\",\"direction\":\"ascending\",\"dimensionOrder\":{\"type\":\"numeric\"}}]},\"context\":{\"sqlQueryId\":\"5c233022-b521-4e6b-b390-ca161188f17e\"}},\"signature\":[{\"name\":\"d0\",\"type\":\"STRING\"},{\"name\":\"a0\",\"type\":\"LONG\"}]}]")]

        let output = try JSONDecoder.telemetryDecoder.decode([SQLQueryConversionResponseItem].self, from: planJSON)

        #expect(expectedOutput == output)
        #expect(output.count == 1)
    }

    @Test("SQL query conversion response item can extract plan successfully")
    func sqlQueryConversionResponseItemGetPlan() throws {
        let responseItems = try JSONDecoder.telemetryDecoder.decode([SQLQueryConversionResponseItem].self, from: planJSON)
        let responseItem = responseItems.first!

        _ = try responseItem.getQuery()
    }
}
