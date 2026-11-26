@testable import SwiftTQL
import Foundation
import Testing

private func date(_ text: String) -> Date {
    Date(iso8601String: text)!
}

// A Thursday, 11:00 in Berlin.
private let now = date("2026-11-26T10:00:00.000Z")

private let thisMonth = RelativeTimeInterval(beginningDate: .init(.beginning, of: .month, adding: 0), endDate: .init(.end, of: .month, adding: 0))

private func compile(
    relativeIntervals: [RelativeTimeInterval]? = [thisMonth],
    intervals: [QueryTimeInterval]? = nil,
    filter: Filter? = nil,
    aggregations: [Aggregator]? = nil,
    timeZone: String? = nil,
    timeShift: TimeShift?,
    now: Date = now
) throws -> CustomQuery {
    try CustomQuery(
        queryType: .timeseries,
        dataSource: "com.example",
        filter: filter,
        intervals: intervals,
        relativeIntervals: relativeIntervals,
        granularity: .day,
        aggregations: aggregations,
        context: QueryContext(timezone: timeZone),
        timeShift: timeShift
    ).precompile().compileToRunnableQuery(now: now)
}

struct TimeShiftTests {
    @Test("A shift moves now by calendar units of the time zone", arguments: [
        (RelativeDate.RelativeDateComponent.hour, -13, nil, "2026-11-25T21:00:00.000Z"),
        (.day, -4, nil, "2026-11-22T10:00:00.000Z"),
        (.week, -1, nil, "2026-11-19T10:00:00.000Z"),
        (.week, -52, nil, "2025-11-27T10:00:00.000Z"),
        (.month, -1, nil, "2026-10-26T10:00:00.000Z"),
        (.quarter, -1, nil, "2026-08-26T10:00:00.000Z"),
        (.year, -1, nil, "2025-11-26T10:00:00.000Z"),
        (.hour, -13, "Europe/Berlin", "2026-11-25T21:00:00.000Z"),
        (.day, -52, "Europe/Berlin", "2026-10-05T09:00:00.000Z"),
        (.week, -13, "Europe/Berlin", "2026-08-27T09:00:00.000Z"),
        (.month, -1, "Europe/Berlin", "2026-10-26T10:00:00.000Z"),
    ] as [(RelativeDate.RelativeDateComponent, Int, String?, String)])
    func apply(component: RelativeDate.RelativeDateComponent, offset: Int, timeZone: String?, expected: String) {
        #expect(TimeShift(component: component, offset: offset).apply(to: now, timeZone: timeZone) == date(expected))
    }

    @Test("A query with a shift selects the intervals of the moved now", arguments: [
        RelativeDate.RelativeDateComponent.hour, .day, .week, .month, .quarter, .year,
    ], [nil, "Europe/Berlin"] as [String?])
    func relativeIntervals(component: RelativeDate.RelativeDateComponent, timeZone: String?) throws {
        let intervals = [
            thisMonth,
            RelativeTimeInterval(beginningDate: .init(.beginning, of: component, adding: -2), endDate: .init(.end, of: component, adding: 0)),
        ]

        let current = try compile(relativeIntervals: intervals, timeZone: timeZone, timeShift: nil)

        for offset in [-1, -4, -13, -52] {
            let shift = TimeShift(component: component, offset: offset)
            let shifted = try compile(relativeIntervals: intervals, timeZone: timeZone, timeShift: shift)
            let expected = try compile(relativeIntervals: intervals, timeZone: timeZone, timeShift: nil, now: shift.apply(to: now, timeZone: timeZone))

            #expect(shifted.intervals == expected.intervals, "offset \(offset)")
            #expect(try #require(shifted.intervals?.last).endDate < current.intervals!.last!.endDate, "offset \(offset)")
        }
    }

    @Test("A shift of one month from the last day of a month selects the previous month")
    func lastDayOfMonth() throws {
        let query = try compile(timeShift: TimeShift(component: .month, offset: -1), now: date("2026-10-31T12:00:00.000Z"))

        #expect(query.intervals == [QueryTimeInterval(beginningDate: date("2026-09-01T00:00:00.000Z"), endDate: date("2026-09-30T23:59:59.000Z"))])
    }

    @Test("A shift moves the relative dates of an interval filter and of a filtered aggregator")
    func intervalFilter() throws {
        let yesterday = RelativeTimeInterval(beginningDate: .init(.beginning, of: .day, adding: -1), endDate: .init(.end, of: .day, adding: -1))
        let relativeFilter = Filter.interval(.init(dimension: "__time", relativeIntervals: [yesterday]))
        let expectedFilter = Filter.interval(.init(
            dimension: "__time",
            intervals: [QueryTimeInterval(beginningDate: date("2026-10-25T00:00:00.000Z"), endDate: date("2026-10-25T23:59:59.000Z"))]
        ))

        let query = try compile(
            filter: relativeFilter,
            aggregations: [.filtered(.init(filter: relativeFilter, aggregator: .count(.init(name: "count"))))],
            timeShift: TimeShift(component: .month, offset: -1)
        )

        #expect(query.filter == expectedFilter)
        #expect(query.aggregations == [.filtered(.init(filter: expectedFilter, aggregator: .count(.init(name: "count"))))])
    }

    @Test("A shift moves an interval with fixed instants in wall-clock time", arguments: [
        (nil, "2026-10-01T00:00:00.000Z", "2026-10-26T00:00:00.000Z"),
        ("Europe/Berlin", "2026-09-30T23:00:00.000Z", "2026-10-26T00:00:00.000Z"),
    ] as [(String?, String, String)])
    func fixedIntervals(timeZone: String?, beginning: String, end: String) throws {
        let fixed = QueryTimeInterval(beginningDate: date("2026-11-01T00:00:00.000Z"), endDate: date("2026-11-26T00:00:00.000Z"))

        let query = try compile(relativeIntervals: nil, intervals: [fixed], timeZone: timeZone, timeShift: TimeShift(component: .month, offset: -1))

        #expect(query.intervals == [QueryTimeInterval(beginningDate: date(beginning), endDate: date(end))])
    }

    @Test("With toDate, no interval ends after the moved now")
    func toDate() throws {
        let query = try compile(timeShift: TimeShift(component: .month, offset: -1, toDate: true))

        #expect(query.intervals == [QueryTimeInterval(beginningDate: date("2026-10-01T00:00:00.000Z"), endDate: date("2026-10-26T10:00:00.000Z"))])
    }

    @Test("A query without a shift compiles as before")
    func withoutShift() throws {
        let query = try compile(timeShift: nil)

        #expect(query.intervals == [QueryTimeInterval.from(relativeTimeInterval: thisMonth, originDate: now)])
        #expect(query.intervals == [QueryTimeInterval(beginningDate: date("2026-11-01T00:00:00.000Z"), endDate: date("2026-11-30T23:59:59.000Z"))])
    }

    @Test("The key timeShift survives the decoder and the encoder")
    func coding() throws {
        let json = #"{"queryType":"timeseries","timeShift":{"component":"month","offset":-1,"toDate":true}}"#
        let query = try JSONDecoder.telemetryDecoder.decode(CustomQuery.self, from: Data(json.utf8))

        #expect(query.timeShift == TimeShift(component: .month, offset: -1, toDate: true))

        let encoded = try #require(String(data: JSONEncoder.telemetryEncoder.encode(query), encoding: .utf8))
        #expect(encoded.contains(#""timeShift":{"component":"month","offset":-1,"toDate":true}"#))

        let withoutShift = try #require(String(data: JSONEncoder.telemetryEncoder.encode(CustomQuery(queryType: .timeseries)), encoding: .utf8))
        #expect(!withoutShift.contains("timeShift"))
    }
}
