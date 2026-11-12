import Foundation

/// One gauge of the web app: its queries, its kind, and its settings.
///
/// The web app shows a spec with Cluster. The backend decodes a spec before it saves the spec.
/// A key that this type does not have is not in the encoded spec. The type is thus also the
/// allowlist of the eCharts options that a user can set.
///
/// `null` and an absent key mean the same: the field is not set. The encoder writes no `null`.
public struct ClusterSpec: Codable, Hashable, Sendable {
    /// The version of the spec format. Only version 1 exists.
    public var version: Int

    /// The queries of the gauge. Each query must have a different name.
    public var queries: [Query]

    /// The kind of gauge that the user sees.
    public var gauge: Gauge

    /// The source query and the columns for the chart roles. Without it, the web app uses defaults.
    public var encoding: Encoding?

    /// Settings for a column. A key is a column name. A setting applies to that column in each query.
    public var columnSettings: [String: ColumnSetting]?

    /// eCharts series options for each series that the gauge generates.
    public var seriesDefaults: Series?

    /// eCharts series options for one generated series. A key is a y column name or a breakdown value.
    public var seriesByName: [String: Series]?

    /// eCharts series that come after the generated series.
    public var extraSeries: [ExtraSeries]?

    /// eCharts options for the complete chart.
    public var echarts: ChartOptions?

    /// The colours of the series. Without it, the web app uses the colour scheme of the app.
    public var colorScheme: ColorScheme?

    /// Markdown text that the web app shows adjacent to the gauge.
    public var explanation: String?

    public enum Gauge: String, Codable, Hashable, Sendable {
        case line
        case bar
        case horizontalBar
        case pie
        case table
        case bigNumber
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // A later version of the format gets its own decoding here.
        version = try container.decode(Int.self, forKey: .version)
        guard version == 1 else {
            throw DecodingError.dataCorruptedError(forKey: .version, in: container, debugDescription: "Unknown spec version \(version)")
        }

        queries = try container.decode([Query].self, forKey: .queries)
        gauge = try container.decode(Gauge.self, forKey: .gauge)
        encoding = try container.decodeIfPresent(Encoding.self, forKey: .encoding)
        columnSettings = try container.decodeIfPresent([String: ColumnSetting].self, forKey: .columnSettings)
        seriesDefaults = try container.decodeIfPresent(Series.self, forKey: .seriesDefaults)
        seriesByName = try container.decodeIfPresent([String: Series].self, forKey: .seriesByName)
        extraSeries = try container.decodeIfPresent([ExtraSeries].self, forKey: .extraSeries)
        echarts = try container.decodeIfPresent(ChartOptions.self, forKey: .echarts)
        colorScheme = try container.decodeIfPresent(ColorScheme.self, forKey: .colorScheme)
        explanation = try container.decodeIfPresent(String.self, forKey: .explanation)

        let names = queries.map(\.name)
        guard !names.isEmpty, Set(names).count == names.count else {
            throw DecodingError.dataCorruptedError(forKey: .queries, in: container, debugDescription: "A spec needs one or more queries with different names")
        }
        if let source = encoding?.source, !names.contains(source) {
            throw DecodingError.dataCorruptedError(forKey: .encoding, in: container, debugDescription: "No query has the name \(source)")
        }
        if let datasetId = extraSeries?.compactMap(\.datasetId).first(where: { !names.contains($0) }) {
            throw DecodingError.dataCorruptedError(forKey: .extraSeries, in: container, debugDescription: "No query has the name \(datasetId)")
        }
        if encoding?.breakdown != nil, (encoding?.y ?? []).count > 1 {
            throw DecodingError.dataCorruptedError(forKey: .encoding, in: container, debugDescription: "With a breakdown, y has exactly one column")
        }
    }
}

public extension ClusterSpec {
    /// The name of a colour scheme of the web app, or a list of CSS colour values.
    enum ColorScheme: Codable, Hashable, Sendable {
        case named(Name)
        case colors([String])

        public enum Name: String, Codable, Hashable, Sendable {
            case `default`
            case vibrant
            case emo
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let name = try? container.decode(Name.self) {
                self = .named(name)
                return
            }

            let colors = try container.decode([String].self)
            guard !colors.isEmpty else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "A list of colours needs one or more colours")
            }
            self = .colors(colors)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()

            switch self {
            case let .named(name): try container.encode(name)
            case let .colors(colors): try container.encode(colors)
            }
        }
    }

    /// A value that eCharts accepts as a number or as text, for example a margin (`20` or `"10%"`).
    enum NumberOrText: Codable, Hashable, Sendable {
        case number(Double)
        case text(String)

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let text = try? container.decode(String.self) {
                self = .text(text)
            } else {
                self = try .number(container.decode(Double.self))
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()

            switch self {
            case let .number(number): try container.encode(number)
            case let .text(text): try container.encode(text)
            }
        }
    }
}
