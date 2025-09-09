import SwiftTQL
import Testing
import Foundation

struct FilterTests {
    @Test("Encoding") func encoding() throws {
        let exampleFilter = Filter.not(FilterNot(field: Filter.selector(FilterSelector(dimension: "test", value: "abc"))))
        _ = try JSONEncoder.telemetryEncoder.encode(exampleFilter)
    }

    @Test("Filter interval") func filterInterval() throws {
        let exampleFilterIntervalString = """
        {
            "dimension" : "__time",
            "intervals" : [
              "2014-10-01T00:00:00.000Z/2014-10-07T00:00:00.000Z"
            ],
            "type" : "interval"
        }
        """
        .filter { !$0.isWhitespace }

        let beginDate: Date = Formatter.iso8601().date(from: "2014-10-01T00:00:00.000Z")!
        let endDate: Date = Formatter.iso8601().date(from: "2014-10-07T00:00:00.000Z")!

        let exampleFilterInterval = Filter.interval(FilterInterval(
            dimension: "__time",
            intervals: [.init(beginningDate: beginDate, endDate: endDate)]
        ))

        let decodedFilterInterval = try JSONDecoder.telemetryDecoder.decode(
            Filter.self,
            from: exampleFilterIntervalString.data(using: .utf8)!
        )

        let encodedFilterInterval = try JSONEncoder.telemetryEncoder.encode(exampleFilterInterval)

        #expect(exampleFilterInterval == decodedFilterInterval)
        #expect(exampleFilterIntervalString == String(data: encodedFilterInterval, encoding: .utf8))
    }

    @Test("Filter range string comparison") func filterRangeStringComparison() throws {
        // WHERE 'foo' <= name <= 'hoo'
        let filterJSON = """
        {
            "column": "name",
            "lower": "foo",
            "matchValueType": "STRING",
            "type": "range",
            "upper": "hoo"
        }
        """
        .filter { !$0.isWhitespace }

        let filterRange = Filter.range(
            FilterRange(
                column: "name",
                matchValueType: .String,
                lower: "foo",
                upper: "hoo"
            )
        )

        let decodedFilter = try JSONDecoder.telemetryDecoder.decode(
            Filter.self,
            from: filterJSON.data(using: .utf8)!
        )

        let encodedFilterInterval = try JSONEncoder.telemetryEncoder.encode(filterRange)

        #expect(filterRange == decodedFilter)
        #expect(filterJSON == String(data: encodedFilterInterval, encoding: .utf8))
    }

    @Test("Filter range number comparison") func filterRangeNumberComparison() throws {
        // WHERE 21 < age < 31
        let filterJSON = """
        {
            "column": "age",
            "lower": "21",
            "lowerOpen": true,
            "matchValueType": "DOUBLE",
            "type": "range",
            "upper": "31" ,
            "upperOpen": true
        }
        """
        .filter { !$0.isWhitespace }

        let filterRange = Filter.range(
            FilterRange(
                column: "age",
                matchValueType: .Double,
                lower: "21",
                upper: "31",
                lowerOpen: true,
                upperOpen: true
            )
        )

        let decodedFilter = try JSONDecoder.telemetryDecoder.decode(
            Filter.self,
            from: filterJSON.data(using: .utf8)!
        )

        let encodedFilterInterval = try JSONEncoder.telemetryEncoder.encode(filterRange)

        #expect(filterRange == decodedFilter)
        #expect(filterJSON == String(data: encodedFilterInterval, encoding: .utf8))
    }

    @Test("Filter range number comparison upper") func filterRangeNumberComparisonUpper() throws {
        // WHERE age < 31
        let filterJSON = """
        {
            "column": "age",
            "matchValueType": "DOUBLE",
            "type": "range",
            "upper": "31" ,
            "upperOpen": true
        }
        """
        .filter { !$0.isWhitespace }

        let filterRange = Filter.range(
            FilterRange(
                column: "age",
                matchValueType: .Double,
                upper: "31",
                upperOpen: true
            )
        )

        let decodedFilter = try JSONDecoder.telemetryDecoder.decode(
            Filter.self,
            from: filterJSON.data(using: .utf8)!
        )

        let encodedFilterInterval = try JSONEncoder.telemetryEncoder.encode(filterRange)

        #expect(filterRange == decodedFilter)
        #expect(filterJSON == String(data: encodedFilterInterval, encoding: .utf8))
    }

    @Test("Filter range number comparison lower") func filterRangeNumberComparisonLower() throws {
        // WHERE age >= 18
        let filterJSON = """
        {
            "column": "age",
            "lower": "18",
            "matchValueType": "DOUBLE",
            "type": "range"
        }
        """
        .filter { !$0.isWhitespace }

        let filterRange = Filter.range(
            FilterRange(
                column: "age",
                matchValueType: .Double,
                lower: "18"
            )
        )

        let decodedFilter = try JSONDecoder.telemetryDecoder.decode(
            Filter.self,
            from: filterJSON.data(using: .utf8)!
        )

        let encodedFilterInterval = try JSONEncoder.telemetryEncoder.encode(filterRange)

        #expect(filterRange == decodedFilter)
        #expect(filterJSON == String(data: encodedFilterInterval, encoding: .utf8))
    }

    @Test("Filter relative interval") func filterRelativeInterval() throws {
        let exampleFilterIntervalString = """
        {
          "dimension": "__time",
          "relativeIntervals": [
            {
              "beginningDate": {
                "component": "day",
                "offset": -30,
                "position": "beginning"
              },
              "endDate": {
                "component": "day",
                "offset": 0,
                "position": "end"
              }
            }
          ],
          "type": "interval"
        }
        """
        .filter { !$0.isWhitespace }

        let exampleFilterInterval = Filter.interval(
            FilterInterval(
                dimension: "__time",
                relativeIntervals: [
                    .init(
                        beginningDate: .init(.beginning, of: .day, adding: -30),
                        endDate: .init(.end, of: .day, adding: 0)
                    )
                ]
            )
        )

        let decodedFilterInterval = try JSONDecoder.telemetryDecoder.decode(
            Filter.self,
            from: exampleFilterIntervalString.data(using: .utf8)!
        )

        let encodedFilterInterval = try JSONEncoder.telemetryEncoder.encode(exampleFilterInterval)

        #expect(exampleFilterInterval == decodedFilterInterval)
        #expect(exampleFilterIntervalString == String(data: encodedFilterInterval, encoding: .utf8))
    }
}
