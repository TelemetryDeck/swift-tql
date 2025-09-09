import SwiftTQL
import Testing
import Foundation

struct HavingTests {
    @Test("Custom query") func customQuery() throws {
        let customQuery = CustomQuery(
            queryType: .groupBy,
            dataSource: "sample_datasource",
            having: .equalTo(.init(aggregation: "test", value: 12))
        )

        let encodedCustomQuery = """
        {
            "dataSource": "sample_datasource",
            "having": {
                "aggregation": "test",
                "type": "equalTo",
                "value": 12
            },
            "queryType": "groupBy"
        }
        """
        .filter { !$0.isWhitespace }

        let encoded = try JSONEncoder.telemetryEncoder.encode(customQuery)
        #expect(String(data: encoded, encoding: .utf8)! == encodedCustomQuery)

        let decoded = try JSONDecoder.telemetryDecoder.decode(CustomQuery.self, from: encoded)
        #expect(customQuery == decoded)
    }

    @Test("Query filter") func queryFilter() throws {
        let havingSpec = HavingSpec.filter(.init(filter: .selector(.init(dimension: "test", value: "true"))))

        let encodedHavingSpec = """
        {
            "filter": {
                "dimension": "test",
                "type": "selector",
                "value": "true"
            },
            "type": "filter"
        }
        """
        .filter { !$0.isWhitespace }

        let encoded = try JSONEncoder.telemetryEncoder.encode(havingSpec)
        #expect(String(data: encoded, encoding: .utf8)! == encodedHavingSpec)

        let decoded = try JSONDecoder.telemetryDecoder.decode(HavingSpec.self, from: encoded)
        #expect(havingSpec == decoded)
    }

    @Test("Equal to") func equalTo() throws {
        let havingSpec = HavingSpec.equalTo(.init(aggregation: "test", value: 12))

        let encodedHavingSpec = """
        {
            "aggregation": "test",
            "type": "equalTo",
            "value": 12
        }
        """
        .filter { !$0.isWhitespace }

        let encoded = try JSONEncoder.telemetryEncoder.encode(havingSpec)
        #expect(String(data: encoded, encoding: .utf8)! == encodedHavingSpec)

        let decoded = try JSONDecoder.telemetryDecoder.decode(HavingSpec.self, from: encoded)
        #expect(havingSpec == decoded)
    }

    @Test("Greater than") func greaterThan() throws {
        let havingSpec = HavingSpec.greaterThan(.init(aggregation: "test", value: 12))

        let encodedHavingSpec = """
        {
            "aggregation": "test",
            "type": "greaterThan",
            "value": 12
        }
        """
        .filter { !$0.isWhitespace }

        let encoded = try JSONEncoder.telemetryEncoder.encode(havingSpec)
        #expect(String(data: encoded, encoding: .utf8)! == encodedHavingSpec)

        let decoded = try JSONDecoder.telemetryDecoder.decode(HavingSpec.self, from: encoded)
        #expect(havingSpec == decoded)
    }

    @Test("Less than") func lessThan() throws {
        let havingSpec = HavingSpec.lessThan(.init(aggregation: "test", value: 12))

        let encodedHavingSpec = """
        {
            "aggregation": "test",
            "type": "lessThan",
            "value": 12
        }
        """
        .filter { !$0.isWhitespace }

        let encoded = try JSONEncoder.telemetryEncoder.encode(havingSpec)
        #expect(String(data: encoded, encoding: .utf8)! == encodedHavingSpec)

        let decoded = try JSONDecoder.telemetryDecoder.decode(HavingSpec.self, from: encoded)
        #expect(havingSpec == decoded)
    }

    @Test("Dimension selector") func dimensionSelector() throws {
        let havingSpec = HavingSpec.dimensionSelector(.init(dimension: "test", value: "itsATest"))

        let encodedHavingSpec = """
        {
            "dimension": "test",
            "type": "dimSelector",
            "value": "itsATest"
        }
        """
        .filter { !$0.isWhitespace }

        let encoded = try JSONEncoder.telemetryEncoder.encode(havingSpec)
        #expect(String(data: encoded, encoding: .utf8)! == encodedHavingSpec)

        let decoded = try JSONDecoder.telemetryDecoder.decode(HavingSpec.self, from: encoded)
        #expect(havingSpec == decoded)
    }

    @Test("And") func and() throws {
        let havingSpec = HavingSpec.and(.init(havingSpecs: [
            .equalTo(.init(aggregation: "test", value: 12)),
            .dimensionSelector(.init(dimension: "test", value: "itsATest"))
        ]))

        let encodedHavingSpec = """
        {
            "havingSpecs": [
                {
                    "aggregation": "test",
                    "type": "equalTo",
                    "value": 12
                },
                {
                    "dimension": "test",
                    "type": "dimSelector",
                    "value": "itsATest"
                }
            ],
            "type": "and"
        }
        """
        .filter { !$0.isWhitespace }

        let encoded = try JSONEncoder.telemetryEncoder.encode(havingSpec)
        #expect(String(data: encoded, encoding: .utf8)! == encodedHavingSpec)

        let decoded = try JSONDecoder.telemetryDecoder.decode(HavingSpec.self, from: encoded)
        #expect(havingSpec == decoded)
    }

    @Test("Or") func or() throws {
        let havingSpec = HavingSpec.or(.init(havingSpecs: [
            .equalTo(.init(aggregation: "test", value: 12)),
            .dimensionSelector(.init(dimension: "test", value: "itsATest"))
        ]))

        let encodedHavingSpec = """
        {
            "havingSpecs": [
                {
                    "aggregation": "test",
                    "type": "equalTo",
                    "value": 12
                },
                {
                    "dimension": "test",
                    "type": "dimSelector",
                    "value": "itsATest"
                }
            ],
            "type": "or"
        }
        """
        .filter { !$0.isWhitespace }

        let encoded = try JSONEncoder.telemetryEncoder.encode(havingSpec)
        #expect(String(data: encoded, encoding: .utf8)! == encodedHavingSpec)

        let decoded = try JSONDecoder.telemetryDecoder.decode(HavingSpec.self, from: encoded)
        #expect(havingSpec == decoded)
    }

    @Test("Not") func not() throws {
        let havingSpec = HavingSpec.not(.init(havingSpec: .equalTo(.init(aggregation: "test", value: 12))))

        let encodedHavingSpec = """
        {
            "havingSpec": {
                "aggregation": "test",
                "type": "equalTo",
                "value": 12
            },
            "type": "not"
        }
        """
        .filter { !$0.isWhitespace }

        let encoded = try JSONEncoder.telemetryEncoder.encode(havingSpec)
        #expect(String(data: encoded, encoding: .utf8)! == encodedHavingSpec)

        let decoded = try JSONDecoder.telemetryDecoder.decode(HavingSpec.self, from: encoded)
        #expect(havingSpec == decoded)
    }
}
