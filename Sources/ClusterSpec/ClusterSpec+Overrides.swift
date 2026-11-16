import Foundation

// The types in this file are the allowlist of the eCharts options that a user can set in a spec.
// eCharts has many more options. A field is here only after a review.
//
// Steps to add a field:
//
// 1. Name the field and the use.
// 2. Read the eCharts source of the version that the web app installs. The value must not
//    become HTML, an address, an image, or code. Examples of fields that must not be here:
//    a tooltip formatter with HTML, `link`, `symbol`, `graphic`, and a colour as an object.
// 3. Give the field a Swift type that is as narrow as possible. A colour is a `String`.
// 4. Add the field, with a short documentation comment. Add a test: the field survives the
//    encoder and the decoder, and a value of a different type does not decode.
// 5. Release swift-tql, update the backend, and deploy the backend. The web app can then
//    use the field.
// 6. Add the field to section 30.2 of the Cluster design.

public extension ClusterSpec {
    /// eCharts options for one series. All fields are optional.
    struct Series: Codable, Hashable, Sendable {
        /// `true` draws a line as a curve.
        public var smooth: Bool?

        /// Draws a line as steps.
        public var step: Step?

        /// `true` draws a line across missing values.
        public var connectNulls: Bool?

        /// `true` shows a symbol at each point of a line. The gauge shows no symbols by default.
        /// Use it for a line with few points.
        public var showSymbol: Bool?

        /// The size of the symbols, in pixels.
        public var symbolSize: Double?

        public var lineStyle: LineStyle?

        /// The area below a line. An area style makes a line chart into an area chart.
        /// Set a low `opacity`, for example 0.2. Without it, the area hides the lines behind it.
        public var areaStyle: AreaStyle?

        public var itemStyle: ItemStyle?

        /// The width of a bar, in pixels or as a percentage (`"60%"`).
        public var barWidth: NumberOrText?

        /// The position of the y axis for this series in `echarts.yAxis`. `1` is the second y axis.
        /// The axis must exist: `echarts.yAxis` must have an item at this position.
        /// Use a second axis when the values of two series have very different sizes.
        public var yAxisIndex: Int?

        /// The text at each point, bar, or slice. The gauge shows no labels by default, with the exception of the pie.
        /// `{ "show": true, "position": "top" }` shows the value above each bar.
        public var label: Label?

        /// Lines at fixed values, for example a target.
        /// Set it on one series only, in `seriesByName` or in an extra series.
        public var markLine: MarkLine?

        /// Areas between fixed values, for example a range of good values.
        /// Set it on one series only, as a mark line.
        public var markArea: MarkArea?

        public enum Step: String, Codable, Hashable, Sendable {
            case start
            case middle
            case end
        }
    }

    /// A series that the user adds after the generated series. It has all fields of `Series`.
    ///
    /// An extra series needs `type`, `encode.x`, and `encode.y`. Without `encode`, it shows no data.
    /// The x column must have the same type of values as the x axis of the gauge, for example a time column for a time axis.
    /// The web app does not add rows for missing time steps to an extra series, and it does not stack series of different queries.
    /// For the gauge `horizontalBar`, the axes change places: `encode.x` is the value column and `encode.y` is the category column.
    /// An extra series reads all rows of its query. It cannot filter them. Filter in the query.
    /// An extra series without `itemStyle.color` gets the next colour of the colour scheme.
    ///
    /// This example shows the users of a second query as a line on a second y axis:
    ///
    /// ```json
    /// "queries": [
    ///   { "name": "main", "language": "sql", "query": "SELECT ... AS \"day\", COUNT(*) AS \"events\" ..." },
    ///   { "name": "users", "language": "sql", "query": "SELECT ... AS \"day\", ... AS \"users\" ..." }
    /// ],
    /// "gauge": "bar",
    /// "extraSeries": [
    ///   { "type": "line", "name": "Users", "datasetId": "users", "encode": { "x": "day", "y": "users" }, "yAxisIndex": 1 }
    /// ],
    /// "echarts": { "yAxis": [{ "name": "Events" }, { "name": "Users", "position": "left" }], "grid": { "top": 40 } }
    /// ```
    struct ExtraSeries: Codable, Hashable, Sendable {
        public var type: SeriesType

        /// The name of the series in the legend and in the tooltip. Always set it. Without it, the tooltip line has no text.
        public var name: String?

        /// The name of the query that the series reads. Without it, the series reads the source query of the gauge.
        /// The series reads the result of the query as it is, before a breakdown.
        public var datasetId: String?

        /// The columns of the query that the series shows.
        public var encode: Encode?

        /// The fields of `Series`. In JSON they are fields of the extra series itself.
        public var options: Series

        public enum SeriesType: String, Codable, Hashable, Sendable {
            case line
            case bar
            case scatter
        }

        /// A text is a column name. A number is the position of a column, and 0 is the first column.
        /// Use names. A position changes when the query gets a new column.
        /// A name that the query result does not have gives the error `columnNotFound`.
        public struct Encode: Codable, Hashable, Sendable {
            /// The column for the x axis.
            public var x: NumberOrText?

            /// The column for the y axis. The tooltip shows its value with the format of the column.
            public var y: NumberOrText?
        }

        private enum CodingKeys: String, CodingKey {
            case type
            case name
            case datasetId
            case encode
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            type = try container.decode(SeriesType.self, forKey: .type)
            name = try container.decodeIfPresent(String.self, forKey: .name)
            datasetId = try container.decodeIfPresent(String.self, forKey: .datasetId)
            encode = try container.decodeIfPresent(Encode.self, forKey: .encode)
            options = try Series(from: decoder)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encode(type, forKey: .type)
            try container.encodeIfPresent(name, forKey: .name)
            try container.encodeIfPresent(datasetId, forKey: .datasetId)
            try container.encodeIfPresent(encode, forKey: .encode)
            try options.encode(to: encoder)
        }
    }

    /// eCharts options for the complete chart. It has no field for series or datasets.
    ///
    /// `xAxis`, `yAxis`, and `dataZoom` are lists. Item 0 of a list merges into item 0 of the generated list.
    /// An axis that the gauge does not generate has no style and no column format from the gauge.
    struct ChartOptions: Codable, Hashable, Sendable {
        /// The x axes. Item 0 is the axis that the gauge generates.
        public var xAxis: [Axis]?

        /// The y axes. Item 0 is the axis that the gauge generates. Item 1 adds a second y axis.
        ///
        /// Item 0 merges into the generated axis. Write `{}` to keep the generated axis as it is.
        /// The generated axis is on the right side. Give a second axis `"position": "left"`.
        /// A second axis shows nothing until a series has `"yAxisIndex": 1`.
        /// A second axis has no column format. Give each axis a `name`, so that the user knows which series it measures.
        /// An axis name is above the axis. Set `grid.top` to 40 to make space for it.
        public var yAxis: [Axis]?

        public var legend: Legend?

        /// The margins around the chart area.
        public var grid: Grid?

        /// Controls that let the user zoom into a part of the data.
        public var dataZoom: [DataZoom]?
    }

    struct Axis: Codable, Hashable, Sendable {
        /// `false` hides the axis.
        public var show: Bool?

        /// `true` turns the direction of the axis.
        public var inverse: Bool?

        /// The text adjacent to the axis.
        public var name: String?

        /// The lowest value of the axis. A time value is text without an offset, in the time zone of the gauge,
        /// for example `"2026-11-01T00:00:00"` or `"2026-11-01"`.
        public var min: NumberOrText?

        /// The highest value of the axis. A time value is text without an offset, in the time zone of the gauge.
        public var max: NumberOrText?

        /// The gauge sets the type from the type of the column. Set it only for a special axis, for example `log`.
        public var type: AxisType?

        /// The side of the chart that has the axis.
        public var position: Position?

        public var axisLabel: AxisLabel?

        public enum AxisType: String, Codable, Hashable, Sendable {
            case value
            case category
            case time
            case log
        }

        public enum Position: String, Codable, Hashable, Sendable {
            case top
            case bottom
            case left
            case right
        }

        public struct AxisLabel: Codable, Hashable, Sendable {
            /// A text template for the labels, for example `"{value} users"`.
            /// A template replaces the column format on this axis. `{value}` is then the number without a format.
            public var formatter: String?
        }
    }

    /// The list of series names with their colours. The gauge shows no legend by default.
    ///
    /// A legend at the top is on top of the chart area. Move the chart area down with `grid.top`:
    /// `"legend": { "show": true, "top": 0 }, "grid": { "top": 40 }`.
    struct Legend: Codable, Hashable, Sendable {
        /// `true` shows the legend.
        public var show: Bool?

        /// The distance from the top edge, in pixels, as a percentage, or as a word (`"middle"`).
        public var top: NumberOrText?
        public var bottom: NumberOrText?

        /// The distance from the left edge, in pixels, as a percentage, or as a word (`"center"`).
        public var left: NumberOrText?
        public var right: NumberOrText?

        public var orient: Orient?

        public enum Orient: String, Codable, Hashable, Sendable {
            case horizontal
            case vertical
        }
    }

    /// The margins around the chart area, in pixels or as a percentage.
    /// The gauge generates small margins: 20 at the top and 16 at the bottom.
    /// Set a larger margin when a legend or an axis name needs space.
    struct Grid: Codable, Hashable, Sendable {
        public var top: NumberOrText?
        public var bottom: NumberOrText?
        public var left: NumberOrText?
        public var right: NumberOrText?
    }

    struct DataZoom: Codable, Hashable, Sendable {
        /// `slider` shows a control below the chart. `inside` zooms with the mouse wheel or with two fingers.
        public var type: ZoomType?
        public var show: Bool?

        /// The start of the visible part, as a percentage from 0 to 100.
        public var start: Double?

        /// The end of the visible part, as a percentage from 0 to 100.
        public var end: Double?

        /// The start of the visible part, as a value of the axis.
        /// A time value is text without an offset, in the time zone of the gauge.
        public var startValue: NumberOrText?

        /// The end of the visible part, as a value of the axis.
        public var endValue: NumberOrText?

        public enum ZoomType: String, Codable, Hashable, Sendable {
            case slider
            case inside
        }
    }

    struct LineStyle: Codable, Hashable, Sendable {
        /// The width of the line, in pixels.
        public var width: Double?
        public var type: LineType?

        /// A CSS colour value as text.
        public var color: String?

        public enum LineType: String, Codable, Hashable, Sendable {
            case solid
            case dashed
            case dotted
        }
    }

    struct AreaStyle: Codable, Hashable, Sendable {
        /// From 0 (not visible) to 1.
        public var opacity: Double?

        /// A CSS colour value as text.
        public var color: String?
    }

    /// The look of a bar, a slice, a symbol, or a mark area.
    struct ItemStyle: Codable, Hashable, Sendable {
        /// A CSS colour value as text.
        public var color: String?

        /// From 0 (not visible) to 1.
        public var opacity: Double?
    }

    struct Label: Codable, Hashable, Sendable {
        public var show: Bool?

        /// The position in relation to the point, bar, or slice, for example `"top"` or `"inside"`.
        public var position: String?

        /// A text template, for example `"{c} users"`. eCharts shows it as text, not as HTML.
        /// `{a}` is the series name, `{b}` is the category, and `{c}` is the value.
        /// `{@events}` is the value of the column `events` in the same row.
        /// A template does not use the column format. Round the value in the query.
        public var formatter: String?
    }

    struct MarkLine: Codable, Hashable, Sendable {
        /// One item for each line. An item with `yAxis` is a horizontal line. An item with `xAxis` is a vertical line.
        /// Example: `[{ "yAxis": 500000, "name": "Target" }]`.
        public var data: [MarkPoint]?
        public var lineStyle: LineStyle?
        public var label: Label?
    }

    struct MarkArea: Codable, Hashable, Sendable {
        /// One item for each area. An item is a pair: the start corner and the end corner.
        /// Example of a band between two y values: `[[{ "yAxis": 100 }, { "yAxis": 200 }]]`.
        public var data: [[MarkPoint]]?
        public var itemStyle: ItemStyle?
    }

    /// A position on one axis or on the two axes.
    struct MarkPoint: Codable, Hashable, Sendable {
        /// A value of the x axis. A time value is text without an offset, in the time zone of the gauge.
        public var xAxis: NumberOrText?

        /// A value of the y axis.
        public var yAxis: NumberOrText?

        /// The text of the label.
        public var name: String?
    }
}
