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
}
