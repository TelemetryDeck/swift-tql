import DateOperations
import Foundation

public struct RelativeTimeInterval: Codable, Hashable, Equatable, Sendable {
    public init(beginningDate: RelativeDate, endDate: RelativeDate) {
        self.beginningDate = beginningDate
        self.endDate = endDate
    }

    public let beginningDate: RelativeDate
    public let endDate: RelativeDate
}

public struct RelativeDate: Codable, Hashable, Equatable, Sendable {
    public enum RelativeDateComponent: String, Codable, Hashable, Equatable, Sendable {
        case hour
        case day
        case week
        case month
        case quarter
        case year

        var calendarComponent: Calendar.Component {
            switch self {
            case .hour:
                return .hour
            case .day:
                return .day
            case .week:
                return .weekOfYear
            case .month:
                return .month
            case .quarter:
                return .quarter
            case .year:
                return .year
            }
        }
    }

    public enum ComponentPosition: String, Codable, Hashable, Equatable, Sendable {
        /// Generate a date at the first possible moment in the specified component
        case beginning

        /// Generate a date at the last possible moment in the specified component
        case end
    }

    public init(_ position: ComponentPosition, of component: RelativeDateComponent, adding offset: Int) {
        self.component = component
        self.offset = offset
        self.position = position
    }

    /// The granularity with which to work in this component
    public let component: RelativeDateComponent

    /// How often to add the component to the current date.
    ///
    /// 0 is the current day/month/component.
    /// Positive values move the date into the future, negative values move the date into the past.
    public let offset: Int

    /// Where in the generated hour/day/month/component should the generated date lie?
    public let position: ComponentPosition
}

public extension Date {
    static func from(relativeDate: RelativeDate, originDate: Date? = nil, timeZone: String? = nil) -> Date {
        let cal = Self.calendar(for: timeZone)
        var date = originDate ?? Date()

        let calendarComponent = relativeDate.component.calendarComponent

        // Swift's Calendar has a known bug where adding/subtracting .quarter doesn't work correctly.
        // Work around this by converting quarters to months (1 quarter = 3 months).
        if relativeDate.component == .quarter {
            date = cal.date(byAdding: .month, value: relativeDate.offset * 3, to: date) ?? date
        } else {
            date = cal.date(byAdding: calendarComponent, value: relativeDate.offset, to: date) ?? date
        }

        // Swift's Calendar also has bugs with beginning(of: .quarter) and end(of: .quarter).
        // Implement custom quarter boundary logic.
        if relativeDate.component == .quarter {
            switch relativeDate.position {
            case .beginning:
                date = Self.beginningOfQuarter(for: date, using: cal) ?? date
            case .end:
                date = Self.endOfQuarter(for: date, using: cal) ?? date
            }
        } else {
            switch relativeDate.position {
            case .beginning:
                date = Self.beginning(of: calendarComponent, for: date, using: cal) ?? date
            case .end:
                date = Self.end(of: calendarComponent, for: date, using: cal) ?? date
            }
        }

        return date
    }

    // MARK: - Calendar with optional timezone

    /// Builds an ISO8601 calendar with the given timezone, falling back to UTC.
    private static func calendar(for timezoneIdentifier: String?) -> Calendar {
        var cal = Calendar(identifier: .iso8601)
        if let timezoneIdentifier, let tz = TimeZone(identifier: timezoneIdentifier) {
            cal.timeZone = tz
        } else {
            cal.timeZone = TimeZone(identifier: "UTC")!
        }
        cal.firstWeekday = 2 // Monday
        return cal
    }

    // MARK: - Beginning/end helpers with explicit Calendar

    /// Reimplements DateOperations' `beginning(of:)` with an explicit Calendar.
    private static func beginning(of component: Calendar.Component, for date: Date, using cal: Calendar) -> Date? {
        if component == .day {
            return cal.startOfDay(for: date)
        }

        var components: Set<Calendar.Component> {
            switch component {
            case .second:
                return [.year, .month, .day, .hour, .minute, .second]
            case .minute:
                return [.year, .month, .day, .hour, .minute]
            case .hour:
                return [.year, .month, .day, .hour]
            case .weekOfYear, .weekOfMonth:
                return [.yearForWeekOfYear, .weekOfYear]
            case .month:
                return [.year, .month]
            case .year:
                return [.year]
            default:
                return []
            }
        }

        guard !components.isEmpty else { return nil }
        return cal.date(from: cal.dateComponents(components, from: date))
    }

    /// Reimplements DateOperations' `end(of:)` with an explicit Calendar.
    private static func end(of component: Calendar.Component, for date: Date, using cal: Calendar) -> Date? {
        switch component {
        case .second:
            let next = cal.date(byAdding: .second, value: 1, to: date)!
            let truncated = cal.date(from: cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: next))!
            return cal.date(byAdding: .second, value: -1, to: truncated)
        case .minute:
            let next = cal.date(byAdding: .minute, value: 1, to: date)!
            let truncated = cal.date(from: cal.dateComponents([.year, .month, .day, .hour, .minute], from: next))!
            return cal.date(byAdding: .second, value: -1, to: truncated)
        case .hour:
            let next = cal.date(byAdding: .hour, value: 1, to: date)!
            let truncated = cal.date(from: cal.dateComponents([.year, .month, .day, .hour], from: next))!
            return cal.date(byAdding: .second, value: -1, to: truncated)
        case .day:
            let next = cal.date(byAdding: .day, value: 1, to: date)!
            let startOfNext = cal.startOfDay(for: next)
            return cal.date(byAdding: .second, value: -1, to: startOfNext)
        case .weekOfYear, .weekOfMonth:
            let beginningOfWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
            let endOfWeek = cal.date(byAdding: .day, value: 7, to: beginningOfWeek)!
            return cal.date(byAdding: .second, value: -1, to: endOfWeek)
        case .month:
            let next = cal.date(byAdding: .month, value: 1, to: date)!
            let truncated = cal.date(from: cal.dateComponents([.year, .month], from: next))!
            return cal.date(byAdding: .second, value: -1, to: truncated)
        case .year:
            let next = cal.date(byAdding: .year, value: 1, to: date)!
            let truncated = cal.date(from: cal.dateComponents([.year], from: next))!
            return cal.date(byAdding: .second, value: -1, to: truncated)
        default:
            return nil
        }
    }

    // MARK: - Quarter helpers with explicit Calendar

    /// Returns the first moment of the quarter containing this date.
    /// Q1: Jan 1, Q2: Apr 1, Q3: Jul 1, Q4: Oct 1
    private static func beginningOfQuarter(for date: Date, using cal: Calendar) -> Date? {
        let month = cal.component(.month, from: date)
        let year = cal.component(.year, from: date)

        // Determine the first month of the quarter (1, 4, 7, or 10)
        let quarterIndex = (month - 1) / 3  // 0, 1, 2, or 3
        let firstMonthOfQuarter = quarterIndex * 3 + 1

        var components = DateComponents()
        components.year = year
        components.month = firstMonthOfQuarter
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        components.nanosecond = 0

        return cal.date(from: components)
    }

    /// Returns the last moment of the quarter containing this date.
    /// Q1: Mar 31 23:59:59, Q2: Jun 30, Q3: Sep 30, Q4: Dec 31
    private static func endOfQuarter(for date: Date, using cal: Calendar) -> Date? {
        guard let nextQuarter = cal.date(byAdding: .month, value: 3, to: date),
              let beginningOfNextQuarter = beginningOfQuarter(for: nextQuarter, using: cal) else {
            return nil
        }

        // Subtract 1 second to get the last moment of the current quarter
        return cal.date(byAdding: .second, value: -1, to: beginningOfNextQuarter)
    }
}

public extension QueryTimeInterval {
    static func from(relativeTimeInterval: RelativeTimeInterval, timeZone: String? = nil) -> QueryTimeInterval {
        QueryTimeInterval(
            beginningDate: Date.from(relativeDate: relativeTimeInterval.beginningDate, timeZone: timeZone),
            endDate: Date.from(relativeDate: relativeTimeInterval.endDate, timeZone: timeZone)
        )
    }
}
