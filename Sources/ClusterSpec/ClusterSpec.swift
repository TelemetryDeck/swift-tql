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
    ///
    /// The gauge reads one query: the first query, or the query that `encoding.source` names.
    /// A second query is for a series in `extraSeries`.
    /// Each query is one request. Use as few queries as possible.
    public var queries: [Query]

    /// The time between two runs of the queries, in seconds. The minimum is 60. The web app uses 3600 without it.
    public var refreshSeconds: Int?

    /// The kind of gauge that the user sees. Without it, the display component chooses a gauge from the query.
    ///
    /// When the query result does not fit the gauge, the gauge shows the error `frameDoesNotFit`.
    /// A chart needs one column for x and one or more number columns for y.
    /// A result with one column fits only the gauges `table` and `bigNumber`.
    public var gauge: Gauge?

    /// The source query and the columns for the chart roles. Without it, the web app uses defaults.
    public var encoding: Encoding?

    /// Settings for a column. A key is a column name. A setting applies to that column in each query.
    ///
    /// A key is the name that the query gives to the column, for example the alias in SQL.
    /// Give each SQL column an alias. A name such as `EXPR$0` changes when the query changes.
    ///
    /// ```json
    /// "columnSettings": { "testModeShare": { "format": "percent", "label": "Test mode share" } }
    /// ```
    public var columnSettings: [String: ColumnSetting]?

    /// eCharts series options for each series that the gauge generates.
    ///
    /// The gauge generates one series for each y column, or one series for each breakdown value.
    /// These options do not apply to a series of `extraSeries`.
    /// `"type": "scatter"` changes each generated series of the gauge `line` into points.
    /// Do not put a mark line here. Each generated series then draws the same line. Use `seriesByName`.
    /// With a breakdown, the names of the series come from the data. `seriesDefaults` is then the only
    /// way to set an option for each series.
    ///
    /// ```json
    /// "seriesDefaults": { "smooth": true, "areaStyle": { "opacity": 0.2 } }
    /// ```
    public var seriesDefaults: Series?

    /// eCharts series options for one generated series. A key is a y column name or a breakdown value.
    ///
    /// Without a breakdown, a key is the name of a y column. It is not the label of the column.
    /// With a breakdown, a key is a breakdown value as text, for example an app version.
    /// A key does not match the series "Other" and the series "(no value)" of a breakdown.
    /// These options merge on top of `seriesDefaults`.
    /// A key without a series gives the warning `seriesNotFound`. The gauge still shows.
    /// A breakdown value that is not in the result of today gives the same warning.
    ///
    /// ```json
    /// "seriesByName": {
    ///   "events": { "lineStyle": { "width": 5 }, "markLine": { "data": [{ "yAxis": 500000, "name": "Target" }] } }
    /// }
    /// ```
    public var seriesByName: [String: Series]?

    /// eCharts series that come after the generated series.
    ///
    /// Use an extra series to show the result of a second query in the same chart.
    /// `seriesDefaults` and `seriesByName` do not apply to an extra series. Put the options into the series itself.
    /// The tooltip shows an extra series below the generated series.
    /// See ``ExtraSeries`` for an example.
    public var extraSeries: [ExtraSeries]?

    /// eCharts options for the complete chart.
    ///
    /// These options merge on top of the options that the gauge generates. A field that is not set keeps its generated value.
    /// The names are the names of eCharts. For the gauge `horizontalBar`, the axis with the categories is `yAxis`.
    /// The gauges `table` and `bigNumber` have no chart and do not use these options.
    ///
    /// ```json
    /// "echarts": { "legend": { "show": true, "top": 0 }, "grid": { "top": 40 } }
    /// ```
    public var echarts: ChartOptions?

    /// The colours of the series. Without it, the web app uses the colour scheme of the app.
    public var colorScheme: ColorScheme?

    /// Markdown text that the web app shows adjacent to the gauge.
    public var explanation: String?

    /// The title that the web app shows above the gauge. A caller with its own title, for example an insight, has priority.
    public var title: String?

    public enum Gauge: String, Codable, Hashable, Sendable {
        /// One line for each y column or for each breakdown value. Use it for values across time.
        /// A value without a value on its two sides shows as a point.
        case line

        /// Vertical bars. With a breakdown, the bars are stacked.
        case bar

        /// Horizontal bars. The first row of the query result is at the top.
        /// Use it for categories with long names. In `echarts`, the axis with the categories is `yAxis`.
        case horizontalBar

        /// One slice for each row. It reads the x column for the names and exactly one y column.
        /// It has no breakdown, no stack, and no `fillZero`. These fields give the warning `unusedField`.
        case pie

        /// Each column of the source query that is not hidden. It uses only `columnSettings`.
        case table

        /// The value of one number column in the first row. Use a query that returns one row.
        /// It shows the label of the column with the value.
        case bigNumber

        /// A chart without generated series and without axes. The spec makes each series in `extraSeries`
        /// and each component in `echarts`, for example a calendar, a matrix, or single axes.
        /// It needs one or more extra series. It uses no field of `encoding`, with the exception of `source`.
        /// The tooltip is the tooltip of eCharts. The column formats do not apply to it.
        /// See ``ChartOptions/calendar`` for an example.
        case custom
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // A later version of the format gets its own decoding here.
        version = try container.decode(Int.self, forKey: .version)
        guard version == 1 else {
            throw DecodingError.dataCorruptedError(forKey: .version, in: container, debugDescription: "Unknown spec version \(version)")
        }

        queries = try container.decode([Query].self, forKey: .queries)
        refreshSeconds = try container.decodeIfPresent(Int.self, forKey: .refreshSeconds)
        gauge = try container.decodeIfPresent(Gauge.self, forKey: .gauge)
        encoding = try container.decodeIfPresent(Encoding.self, forKey: .encoding)
        columnSettings = try container.decodeIfPresent([String: ColumnSetting].self, forKey: .columnSettings)
        seriesDefaults = try container.decodeIfPresent(Series.self, forKey: .seriesDefaults)
        seriesByName = try container.decodeIfPresent([String: Series].self, forKey: .seriesByName)
        extraSeries = try container.decodeIfPresent([ExtraSeries].self, forKey: .extraSeries)
        echarts = try container.decodeIfPresent(ChartOptions.self, forKey: .echarts)
        colorScheme = try container.decodeIfPresent(ColorScheme.self, forKey: .colorScheme)
        explanation = try container.decodeIfPresent(String.self, forKey: .explanation)
        title = try container.decodeIfPresent(String.self, forKey: .title)

        if let refreshSeconds, refreshSeconds < 60 {
            throw DecodingError.dataCorruptedError(forKey: .refreshSeconds, in: container, debugDescription: "The minimum is 60 seconds")
        }
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
        if gauge == .custom, (extraSeries ?? []).isEmpty {
            throw DecodingError.dataCorruptedError(forKey: .extraSeries, in: container, debugDescription: "The gauge custom needs one or more extra series")
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
