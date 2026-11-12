import Foundation
import SwiftTQL

public extension ClusterSpec {
    /// Settings for one column.
    struct ColumnSetting: Codable, Hashable, Sendable {
        /// How the gauge shows the values of the column.
        public var format: Format?

        /// The text that the gauge shows in the place of the column name.
        public var label: String?

        /// Only for the gauge `table`: `true` shows the share of each row in the column total.
        public var share: Bool?

        /// A map from a value to the text that the gauge shows for it.
        public var valueLabels: [String: String]?
    }

    /// The format of a column. In JSON it is a name (`"compact"`) or an object with a name (`{ "name": "bytes", "base": 1024 }`).
    enum Format: Codable, Hashable, Sendable {
        /// Only for a time column: the web app selects the date text from the step between the time values.
        case auto
        case number

        /// Short numbers, for example 1.2K.
        case compact

        /// Reads the value as a fraction: 0.25 shows as 25%.
        case percent

        /// A duration. The web app reads the value as seconds without a unit.
        case duration(unit: DurationUnit?)

        /// A number of bytes. The web app uses the base 1024 without a base.
        case bytes(base: ByteBase?)

        /// The arguments of `Intl.NumberFormat` in the browser.
        case intl(ValueFormatter)

        public enum DurationUnit: String, Codable, Hashable, Sendable {
            case milliseconds
            case seconds
            case minutes
        }

        public enum ByteBase: Int, Codable, Hashable, Sendable {
            case decimal = 1000
            case binary = 1024
        }

        private enum Name: String, Codable {
            case auto
            case number
            case compact
            case percent
            case duration
            case bytes
            case intl
        }

        private enum CodingKeys: String, CodingKey {
            case name
            case unit
            case base
        }

        public init(from decoder: Decoder) throws {
            // A name as text has no container. It then has no parameters.
            let container = try? decoder.container(keyedBy: CodingKeys.self)
            let name = try container?.decode(Name.self, forKey: .name) ?? decoder.singleValueContainer().decode(Name.self)

            switch name {
            case .auto: self = .auto
            case .number: self = .number
            case .compact: self = .compact
            case .percent: self = .percent
            case .duration: self = try .duration(unit: container?.decodeIfPresent(DurationUnit.self, forKey: .unit) ?? nil)
            case .bytes: self = try .bytes(base: container?.decodeIfPresent(ByteBase.self, forKey: .base) ?? nil)
            case .intl: self = try .intl(ValueFormatter(from: decoder))
            }
        }

        public func encode(to encoder: Encoder) throws {
            switch self {
            case .auto: try encodeName(.auto, to: encoder)
            case .number: try encodeName(.number, to: encoder)
            case .compact: try encodeName(.compact, to: encoder)
            case .percent: try encodeName(.percent, to: encoder)
            case let .duration(unit):
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(Name.duration, forKey: .name)
                try container.encodeIfPresent(unit, forKey: .unit)
            case let .bytes(base):
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(Name.bytes, forKey: .name)
                try container.encodeIfPresent(base, forKey: .base)
            case let .intl(formatter):
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(Name.intl, forKey: .name)
                try formatter.encode(to: encoder)
            }
        }

        private func encodeName(_ name: Name, to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(name)
        }
    }
}
