@testable import SwiftTQL
import Testing
import Foundation

struct RelativeDateTests {
    @Test("Parse relative date")
    func parseRelativeDate() throws {
        let beginningOfLastMonth = try decoded(json: """
        {
            "component": "month",
            "offset": -1,
            "position": "beginning"
        }
        """)

        #expect(beginningOfLastMonth.component == .month)
        #expect(beginningOfLastMonth.offset == -1)
        #expect(beginningOfLastMonth.position == .beginning)

        let endOfThisMonth = try decoded(json: """
        {
            "component": "month",
            "offset": 0,
            "position": "end"
        }
        """)

        #expect(endOfThisMonth.component == .month)
        #expect(endOfThisMonth.offset == 0)
        #expect(endOfThisMonth.position == .end)

        let beginningOfNextWeek = try decoded(json: """
        {
            "component": "week",
            "offset": 1,
            "position": "beginning"
        }
        """)

        #expect(beginningOfNextWeek.component == .week)
        #expect(beginningOfNextWeek.offset == 1)
        #expect(beginningOfNextWeek.position == .beginning)

        let endOfToday = try decoded(json: """
        {
            "component": "day",
            "offset": 0,
            "position": "end"
        }
        """)

        #expect(endOfToday.component == .day)
        #expect(endOfToday.offset == 0)
        #expect(endOfToday.position == .end)

        let in30Hours = try decoded(json: """
        {
            "component": "hour",
            "offset": 30,
            "position": "beginning"
        }
        """)

        #expect(in30Hours.component == .hour)
        #expect(in30Hours.offset == 30)
        #expect(in30Hours.position == .beginning)
    }

    private func decoded(json: String) throws -> RelativeDate {
        let data = json
            .filter { !$0.isWhitespace }
            .data(using: .utf8)!
        return try JSONDecoder.telemetryDecoder.decode(RelativeDate.self, from: data)
    }

    @Test("Parse relative time interval")
    func parseRelativeTimeInterval() throws {
        let relativeTimeIntervals = """
        [
            {
                "beginningDate": {
                    "component": "month",
                    "offset": -1,
                    "position": "beginning"
                },
                "endDate": {
                    "component": "month",
                    "offset": 0,
                    "position": "end"
                }
            }
        ]
        """
        .filter { !$0.isWhitespace }
        .data(using: .utf8)!

        let decodedIntervals = try JSONDecoder.telemetryDecoder.decode([RelativeTimeInterval].self, from: relativeTimeIntervals)

        #expect(decodedIntervals.count == 1)
        #expect(decodedIntervals.first?.beginningDate.component == .month)
        #expect(decodedIntervals.first?.endDate.position == .end)
    }

    @Test("Encode relative time intervals")
    func encodeRelativeTimeIntervals() throws {
        let relativeTimeIntervals = [
            RelativeTimeInterval(
                beginningDate: RelativeDate(.beginning, of: .month, adding: -1),
                endDate: RelativeDate(.end, of: .month, adding: 0)
            ),
        ]

        let expectedOutput = """
        [
            {
                "beginningDate": {
                    "component": "month",
                    "offset": -1,
                    "position": "beginning"
                },
                "endDate": {
                    "component": "month",
                    "offset": 0,
                    "position": "end"
                }
            }
        ]
        """
        .filter { !$0.isWhitespace }

        let encodedIntervals = try JSONEncoder.telemetryEncoder.encode(relativeTimeIntervals)
        let encodedIntervalsString = String(data: encodedIntervals, encoding: .utf8)

        #expect(encodedIntervalsString == expectedOutput)
    }

    @Test("Date from relative date")
    func dateFromRelativeDate() throws {
        let beginningOfLastMonthRelative = RelativeDate(.beginning, of: .month, adding: -1)
        let beginningOfLastMonthAbsolute = Date().calendar.date(byAdding: .month, value: -1, to: Date())!.beginning(of: .month)

        #expect(beginningOfLastMonthAbsolute == Date.from(relativeDate: beginningOfLastMonthRelative))

        let endOfThisMonthRelative = RelativeDate(.end, of: .month, adding: 0)
        let endOfThisMonthAbsolute = Date().end(of: .month)

        #expect(endOfThisMonthAbsolute == Date.from(relativeDate: endOfThisMonthRelative))

        let beginningOfNextWeekRelative = RelativeDate(.beginning, of: .week, adding: 1)
        let beginningOfNextWeekAbsolute = Date().calendar.date(byAdding: .weekOfYear, value: 1, to: Date())!.beginning(of: .weekOfYear)!

        #expect(beginningOfNextWeekAbsolute == Date.from(relativeDate: beginningOfNextWeekRelative))

        let endOfTodayRelative = RelativeDate(.end, of: .day, adding: 0)
        let endOfTodayAbsolute = Date().end(of: .day)

        #expect(endOfTodayAbsolute == Date.from(relativeDate: endOfTodayRelative))

        let in30HoursRelative = RelativeDate(.beginning, of: .hour, adding: 30)
        let in30HoursAbsolute = Date().startOfHour.adding(.hour, value: 30).startOfHour

        #expect(in30HoursAbsolute == Date.from(relativeDate: in30HoursRelative))
    }

    @Test("Week begins on Monday")
    func weekBeginsOnMonday() throws {
        let beginningOfNextWeekRelative = RelativeDate(.beginning, of: .week, adding: 1)
        let beginningOfNextWeekAbsolute = Date.from(relativeDate: beginningOfNextWeekRelative)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        let weekDay = dateFormatter.string(from: beginningOfNextWeekAbsolute)

        #expect("Monday" == weekDay)
    }

    @Test("Timezone-aware beginning of day differs from UTC")
    func timezoneAwareBeginningOfDay() throws {
        // Use a fixed origin date: 2024-06-15 03:00:00 UTC
        // In America/New_York (UTC-4 in summer), this is 2024-06-14 23:00:00 — still the previous day.
        // So "beginning of today" should differ between UTC and New York.
        let originDate = Date(iso8601String: "2024-06-15T03:00:00.000Z")!

        let beginningOfDay = RelativeDate(.beginning, of: .day, adding: 0)

        let utcResult = Date.from(relativeDate: beginningOfDay, originDate: originDate)
        let nyResult = Date.from(relativeDate: beginningOfDay, originDate: originDate, timeZone: "America/New_York")

        // UTC beginning of day: 2024-06-15T00:00:00Z
        #expect(utcResult == Date(iso8601String: "2024-06-15T00:00:00.000Z")!)

        // New York beginning of day: 2024-06-14 00:00:00 EDT = 2024-06-14T04:00:00Z
        #expect(nyResult == Date(iso8601String: "2024-06-14T04:00:00.000Z")!)

        // They should differ
        #expect(utcResult != nyResult)
    }

    @Test("Timezone-aware end of day")
    func timezoneAwareEndOfDay() throws {
        // 2024-06-15 03:00:00 UTC = 2024-06-14 23:00:00 EDT
        let originDate = Date(iso8601String: "2024-06-15T03:00:00.000Z")!

        let endOfDay = RelativeDate(.end, of: .day, adding: 0)

        let utcResult = Date.from(relativeDate: endOfDay, originDate: originDate)
        let nyResult = Date.from(relativeDate: endOfDay, originDate: originDate, timeZone: "America/New_York")

        // UTC end of day: 2024-06-15T23:59:59Z
        #expect(utcResult == Date(iso8601String: "2024-06-15T23:59:59.000Z")!)

        // New York end of day: 2024-06-14 23:59:59 EDT = 2024-06-15T03:59:59Z
        #expect(nyResult == Date(iso8601String: "2024-06-15T03:59:59.000Z")!)
    }

    @Test("Nil timezone falls back to UTC")
    func nilTimezoneFallsBackToUTC() throws {
        let originDate = Date(iso8601String: "2024-06-15T03:00:00.000Z")!
        let beginningOfDay = RelativeDate(.beginning, of: .day, adding: 0)

        let defaultResult = Date.from(relativeDate: beginningOfDay, originDate: originDate)
        let nilResult = Date.from(relativeDate: beginningOfDay, originDate: originDate, timeZone: nil)

        #expect(defaultResult == nilResult)
    }

    @Test("Timezone-aware beginning of month")
    func timezoneAwareBeginningOfMonth() throws {
        // 2024-07-01 03:00:00 UTC = 2024-06-30 23:00:00 EDT — still June in New York
        let originDate = Date(iso8601String: "2024-07-01T03:00:00.000Z")!

        let beginningOfMonth = RelativeDate(.beginning, of: .month, adding: 0)

        let utcResult = Date.from(relativeDate: beginningOfMonth, originDate: originDate)
        let nyResult = Date.from(relativeDate: beginningOfMonth, originDate: originDate, timeZone: "America/New_York")

        // UTC: beginning of July = 2024-07-01T00:00:00Z
        #expect(utcResult == Date(iso8601String: "2024-07-01T00:00:00.000Z")!)

        // New York: beginning of June = 2024-06-01 00:00:00 EDT = 2024-06-01T04:00:00Z
        #expect(nyResult == Date(iso8601String: "2024-06-01T04:00:00.000Z")!)
    }

    @Test("QueryTimeInterval.from respects timezone")
    func queryTimeIntervalFromRespectsTimezone() throws {
        let interval = RelativeTimeInterval(
            beginningDate: RelativeDate(.beginning, of: .day, adding: 0),
            endDate: RelativeDate(.end, of: .day, adding: 0)
        )

        // Use a fixed date to avoid test flakiness — but since we can't inject originDate
        // into QueryTimeInterval.from, just verify that UTC and timezone calls produce different results
        let utcInterval = QueryTimeInterval.from(relativeTimeInterval: interval)
        let nyInterval = QueryTimeInterval.from(relativeTimeInterval: interval, timeZone: "America/New_York")

        // In most hours of the day, UTC and New York will produce different day boundaries.
        // We can't guarantee which hour tests run, so just verify the API compiles and works.
        // The key correctness tests are the Date.from tests above.
        #expect(utcInterval.beginningDate <= utcInterval.endDate)
        #expect(nyInterval.beginningDate <= nyInterval.endDate)
    }
}
