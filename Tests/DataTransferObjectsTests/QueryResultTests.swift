//
//  DruidQueryResultTests.swift
//
//
//  Created by Daniel Jilg on 22.12.21.
//

import DataTransferObjects
import XCTest

class QueryResultTests: XCTestCase {
    let randomDate = Date(timeIntervalSinceReferenceDate: 656510400) // Thursday, October 21, 2021 2:00:00 PM GMT+02:00

    func testEncodingTimeSeries() throws {
        let exampleQueryResult = QueryResult.timeSeries(
            TimeSeriesQueryResult(rows:
                [
                    TimeSeriesQueryResultRow(timestamp: randomDate - 3600, result: ["test": 11]),
                    TimeSeriesQueryResultRow(timestamp: randomDate, result: ["test": 12]),
                ]
            )
        )

        let encodedQueryResult = try JSONEncoder.druidEncoder.encode(exampleQueryResult)
        
        let expectedResult = """
        {
            "rows": [
                {"result":{"test":11},"timestamp":"2021-10-21T11:00:00+0000"},
                {"result":{"test":12},"timestamp":"2021-10-21T12:00:00+0000"}
            ],
            "type":"timeSeriesResult"
        }
        """
        .filter { !$0.isWhitespace }
        
        XCTAssertEqual(String(data: encodedQueryResult, encoding: .utf8)!, expectedResult)
        
    }

    func testEncodingGroupBy() throws {
        let exampleQueryResult = QueryResult.groupBy(GroupByQueryResult(timestamp: randomDate, event: .init(metrics: [:], dimensions: ["abc":"def","uno":"due"])))
        let encodedQueryResult = try JSONEncoder.druidEncoder.encode(exampleQueryResult)
        let expectedResult = """
          {
            "event": {"abc":"def","uno":"due"},
            "timestamp": "2021-10-21T12:00:00+0000",
            "type":"groupByResult",
            "version": "v1"
          }
        """
        .filter { !$0.isWhitespace }
            
        XCTAssertEqual(String(data: encodedQueryResult, encoding: .utf8)!, expectedResult)
    }
    
    func testDecodingGroupBy() throws {
        let expectedResult = GroupByQueryResult(timestamp: randomDate, event: .init(metrics: ["count":12], dimensions: ["abc":"def","uno":"due"]))
        let groupByResult = """
          {
            "event": {"abc":"def","uno":"due", "count": 12},
            "timestamp": "2021-10-21T12:00:00+0000",
            "version": "v1"
          }
        """
        
        let decodedResult = try JSONDecoder.druidDecoder.decode(GroupByQueryResult.self, from: groupByResult.data(using: .utf8)!)
        XCTAssertEqual(expectedResult, decodedResult)
    }
    
    func testDecodingTimeSeriesResult() throws {
        let exampleResult = """
        {"timestamp":"2021-01-01T00:00:00.000Z","result":{"d0":1609459200000}}
        """
        .filter { !$0.isWhitespace }
        
        let decodedResult = try JSONDecoder.druidDecoder.decode(TimeSeriesQueryResultRow.self, from: exampleResult.data(using: .utf8)!)
        
        XCTAssertEqual(decodedResult.result, ["d0": 1609459200000])
    }
}
