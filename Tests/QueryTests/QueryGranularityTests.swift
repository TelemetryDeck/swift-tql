@testable import SwiftTQL
import XCTest

final class QueryGranularityTests: XCTestCase {
    let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    let decoder = JSONDecoder()

    // MARK: - Simple Granularity Encoding

    func testSimpleGranularityEncodesAsBareString() throws {
        let granularity = QueryGranularity.day
        let data = try encoder.encode(granularity)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertEqual(json, "\"day\"")
    }

    func testAllSimpleGranularitiesRoundTrip() throws {
        let allSimple: [QueryGranularity] = [
            .all, .none, .second, .minute, .fifteen_minute, .thirty_minute,
            .hour, .day, .week, .month, .quarter, .year,
        ]

        for granularity in allSimple {
            let data = try encoder.encode(granularity)
            let decoded = try decoder.decode(QueryGranularity.self, from: data)
            XCTAssertEqual(decoded, granularity, "Round-trip failed for \(granularity)")
        }
    }

    // MARK: - Simple Granularity Decoding

    func testDecodeSimpleFromBareString() throws {
        let json = Data("\"hour\"".utf8)
        let granularity = try decoder.decode(QueryGranularity.self, from: json)
        XCTAssertEqual(granularity, .hour)
    }

    func testDecodeSimpleFromObjectForm() throws {
        let json = Data("""
        {"type": "day"}
        """.utf8)
        let granularity = try decoder.decode(QueryGranularity.self, from: json)
        XCTAssertEqual(granularity, .day)
    }

    func testDecodeSimpleCaseInsensitive() throws {
        let json = Data("\"DAY\"".utf8)
        let granularity = try decoder.decode(QueryGranularity.self, from: json)
        XCTAssertEqual(granularity, .day)
    }

    func testDecodeSimpleCaseInsensitiveObjectForm() throws {
        let json = Data("""
        {"type": "Month"}
        """.utf8)
        let granularity = try decoder.decode(QueryGranularity.self, from: json)
        XCTAssertEqual(granularity, .month)
    }

    // MARK: - Static Property Equality

    func testStaticPropertyEqualsSimpleCase() {
        XCTAssertEqual(QueryGranularity.day, .simple(.day))
        XCTAssertEqual(QueryGranularity.all, .simple(.all))
        XCTAssertEqual(QueryGranularity.none, .simple(.none))
        XCTAssertEqual(QueryGranularity.hour, .simple(.hour))
    }

    // MARK: - Duration Granularity

    func testDurationGranularityEncodeDecode() throws {
        let granularity = QueryGranularity.duration(DurationGranularity(duration: 3600000))
        let data = try encoder.encode(granularity)
        let json = String(data: data, encoding: .utf8)!

        XCTAssertTrue(json.contains("\"type\":\"duration\""))
        XCTAssertTrue(json.contains("\"duration\":3600000"))

        let decoded = try decoder.decode(QueryGranularity.self, from: data)
        XCTAssertEqual(decoded, granularity)
    }

    func testDurationGranularityWithOrigin() throws {
        let json = Data("""
        {"type":"duration","duration":7200000,"origin":"2012-01-01T00:30:00Z"}
        """.utf8)

        let granularity = try decoder.decode(QueryGranularity.self, from: json)

        guard case let .duration(durationGranularity) = granularity else {
            XCTFail("Expected duration granularity")
            return
        }

        XCTAssertEqual(durationGranularity.duration, 7200000)
        XCTAssertNotNil(durationGranularity.origin)

        // Round-trip
        let encoded = try encoder.encode(granularity)
        let redecoded = try decoder.decode(QueryGranularity.self, from: encoded)
        XCTAssertEqual(redecoded, granularity)
    }

    func testDurationGranularityWithoutOrigin() throws {
        let json = Data("""
        {"type":"duration","duration":86400000}
        """.utf8)

        let granularity = try decoder.decode(QueryGranularity.self, from: json)

        guard case let .duration(durationGranularity) = granularity else {
            XCTFail("Expected duration granularity")
            return
        }

        XCTAssertEqual(durationGranularity.duration, 86400000)
        XCTAssertNil(durationGranularity.origin)
    }

    // MARK: - Period Granularity

    func testPeriodGranularityEncodeDecode() throws {
        let granularity = QueryGranularity.period(PeriodGranularity(period: "P1D"))
        let data = try encoder.encode(granularity)
        let json = String(data: data, encoding: .utf8)!

        XCTAssertTrue(json.contains("\"type\":\"period\""))
        XCTAssertTrue(json.contains("\"period\":\"P1D\""))

        let decoded = try decoder.decode(QueryGranularity.self, from: data)
        XCTAssertEqual(decoded, granularity)
    }

    func testPeriodGranularityWithTimezone() throws {
        let json = Data("""
        {"type":"period","period":"P1D","timeZone":"America/Los_Angeles"}
        """.utf8)

        let granularity = try decoder.decode(QueryGranularity.self, from: json)

        guard case let .period(periodGranularity) = granularity else {
            XCTFail("Expected period granularity")
            return
        }

        XCTAssertEqual(periodGranularity.period, "P1D")
        XCTAssertEqual(periodGranularity.timeZone, "America/Los_Angeles")
        XCTAssertNil(periodGranularity.origin)

        // Round-trip
        let encoded = try encoder.encode(granularity)
        let redecoded = try decoder.decode(QueryGranularity.self, from: encoded)
        XCTAssertEqual(redecoded, granularity)
    }

    func testPeriodGranularityWithTimezoneAndOrigin() throws {
        let json = Data("""
        {"type":"period","period":"PT6H","timeZone":"America/Los_Angeles","origin":"2012-01-01T00:30:00Z"}
        """.utf8)

        let granularity = try decoder.decode(QueryGranularity.self, from: json)

        guard case let .period(periodGranularity) = granularity else {
            XCTFail("Expected period granularity")
            return
        }

        XCTAssertEqual(periodGranularity.period, "PT6H")
        XCTAssertEqual(periodGranularity.timeZone, "America/Los_Angeles")
        XCTAssertNotNil(periodGranularity.origin)

        // Round-trip
        let encoded = try encoder.encode(granularity)
        let redecoded = try decoder.decode(QueryGranularity.self, from: encoded)
        XCTAssertEqual(redecoded, granularity)
    }

    func testPeriodGranularityWithoutOptionals() throws {
        let json = Data("""
        {"type":"period","period":"P1M"}
        """.utf8)

        let granularity = try decoder.decode(QueryGranularity.self, from: json)

        guard case let .period(periodGranularity) = granularity else {
            XCTFail("Expected period granularity")
            return
        }

        XCTAssertEqual(periodGranularity.period, "P1M")
        XCTAssertNil(periodGranularity.timeZone)
        XCTAssertNil(periodGranularity.origin)
    }

    // MARK: - Error Cases

    func testUnknownStringThrows() {
        let json = Data("\"biweekly\"".utf8)
        XCTAssertThrowsError(try decoder.decode(QueryGranularity.self, from: json))
    }

    // MARK: - Precompile with Timezone

    func testPrecompileWithNoTimezoneReturnsUnchanged() {
        let cases: [QueryGranularity] = [
            .day,
            .duration(DurationGranularity(duration: 3600000)),
            .period(PeriodGranularity(period: "P1D", timeZone: "UTC")),
        ]

        for granularity in cases {
            let result = granularity.precompile(withTimezone: nil)
            XCTAssertEqual(result, granularity, "Expected no change for \(granularity) when timezone is nil")
        }
    }

    func testPrecompileDurationReturnsUnchangedEvenWithTimezone() {
        let granularity = QueryGranularity.duration(DurationGranularity(duration: 3600000))
        let result = granularity.precompile(withTimezone: "America/Los_Angeles")
        XCTAssertEqual(result, granularity)
    }

    func testPrecompilePeriodReplacesTimezone() {
        let original = PeriodGranularity(period: "P1D", timeZone: "UTC")
        let granularity = QueryGranularity.period(original)
        let result = granularity.precompile(withTimezone: "America/Los_Angeles")

        guard case let .period(periodGranularity) = result else {
            XCTFail("Expected period granularity")
            return
        }

        XCTAssertEqual(periodGranularity.period, "P1D")
        XCTAssertEqual(periodGranularity.timeZone, "America/Los_Angeles")
        XCTAssertNil(periodGranularity.origin)
    }

    func testPrecompilePeriodPreservesOrigin() throws {
        let json = Data("""
        {"type":"period","period":"PT6H","timeZone":"UTC","origin":"2012-01-01T00:30:00Z"}
        """.utf8)
        let granularity = try decoder.decode(QueryGranularity.self, from: json)
        let result = granularity.precompile(withTimezone: "Europe/Berlin")

        guard case let .period(periodGranularity) = result else {
            XCTFail("Expected period granularity")
            return
        }

        XCTAssertEqual(periodGranularity.period, "PT6H")
        XCTAssertEqual(periodGranularity.timeZone, "Europe/Berlin")
        XCTAssertNotNil(periodGranularity.origin)
    }

    func testPrecompileSimpleConvertsToPeriodWithTimezone() {
        let testCases: [(SimpleGranularity, String)] = [
            (.second, "PT1S"),
            (.minute, "PT1M"),
            (.fifteen_minute, "PT15M"),
            (.thirty_minute, "PT30M"),
            (.hour, "PT1H"),
            (.day, "P1D"),
            (.week, "P1W"),
            (.month, "P1M"),
            (.year, "P1Y"),
        ]

        for (simple, expectedPeriod) in testCases {
            let granularity = QueryGranularity.simple(simple)
            let result = granularity.precompile(withTimezone: "Europe/Berlin")

            guard case let .period(periodGranularity) = result else {
                XCTFail("Expected period granularity for \(simple)")
                continue
            }

            XCTAssertEqual(periodGranularity.period, expectedPeriod, "Wrong period for \(simple)")
            XCTAssertEqual(periodGranularity.timeZone, "Europe/Berlin", "Wrong timezone for \(simple)")
        }
    }

    func testPrecompileSimpleAllAndNoneUnchangedWithTimezone() {
        // .all and .none have no period equivalent, so they should be returned as-is
        for simple in [SimpleGranularity.all, SimpleGranularity.none] {
            let granularity = QueryGranularity.simple(simple)
            let result = granularity.precompile(withTimezone: "America/New_York")
            XCTAssertEqual(result, granularity, "Expected \(simple) to remain unchanged")
        }
    }

    func testPrecompileSimpleQuarterUnchangedWithTimezone() {
        // .quarter has no period equivalent in the mapping
        let granularity = QueryGranularity.quarter
        let result = granularity.precompile(withTimezone: "Asia/Tokyo")
        XCTAssertEqual(result, granularity)
    }

    // MARK: - Error Cases

    func testUnknownTypeThrows() {
        let json = Data("""
        {"type":"custom"}
        """.utf8)
        XCTAssertThrowsError(try decoder.decode(QueryGranularity.self, from: json))
    }

    // MARK: - Druid Documentation Examples

    func testDruidDocDurationExample() throws {
        // From Druid docs: 2-hour buckets starting at 00:30
        let json = Data("""
        {"type":"duration","duration":7200000,"origin":"2012-01-01T00:30:00Z"}
        """.utf8)

        let granularity = try decoder.decode(QueryGranularity.self, from: json)

        guard case let .duration(durationGranularity) = granularity else {
            XCTFail("Expected duration granularity")
            return
        }

        XCTAssertEqual(durationGranularity.duration, 7200000)
        XCTAssertNotNil(durationGranularity.origin)
    }

    func testDruidDocPeriodExample() throws {
        // From Druid docs: 1-day period in Pacific time
        let json = Data("""
        {"type":"period","period":"P1D","timeZone":"America/Los_Angeles"}
        """.utf8)

        let granularity = try decoder.decode(QueryGranularity.self, from: json)

        guard case let .period(periodGranularity) = granularity else {
            XCTFail("Expected period granularity")
            return
        }

        XCTAssertEqual(periodGranularity.period, "P1D")
        XCTAssertEqual(periodGranularity.timeZone, "America/Los_Angeles")
    }
}
