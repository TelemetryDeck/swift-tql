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
        /// The eCharts series type. Without it, a generated series has the type of the gauge.
        /// Set it in `seriesDefaults` to show the series of the gauge `line` as points:
        /// `"seriesDefaults": { "type": "scatter", "itemStyle": { "opacity": 0.4 } }`.
        public var type: SeriesType?

        /// `data` gives each point, bar, or cell its own colour. With a category axis, the colour comes from the category.
        /// Without it, each series has one colour.
        public var colorBy: ColorBy?

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

        /// The position of the y axis for this series in `chartOptions.yAxis`. `1` is the second y axis.
        /// The axis must exist: `chartOptions.yAxis` must have an item at this position.
        /// Use a second axis when the values of two series have very different sizes.
        public var yAxisIndex: Int?

        /// The text at each point, bar, or slice. The gauge shows no labels by default, with the exception of the pie.
        /// `{ "show": true, "position": "top" }` shows the value above each bar.
        public var label: Label?

        /// The text at the last point of a line. `{ "show": true, "formatter": "{a}" }` shows the series name.
        /// It replaces a legend in a chart with many lines. Set `grid.right` to make space for the text.
        public var endLabel: Label?

        /// Moves labels that are on top of each other.
        public var labelLayout: LabelLayout?

        /// What occurs when the pointer is on the series.
        public var emphasis: Emphasis?

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

        public enum ColorBy: String, Codable, Hashable, Sendable {
            case series
            case data
        }

        public struct LabelLayout: Codable, Hashable, Sendable {
            /// The direction in which a label moves away from a different label. Use `shiftY` for the end labels of lines.
            public var moveOverlap: MoveOverlap?

            public enum MoveOverlap: String, Codable, Hashable, Sendable {
                case shiftX
                case shiftY
            }
        }

        public struct Emphasis: Codable, Hashable, Sendable {
            /// `series` makes the other series pale while the pointer is on one series.
            public var focus: Focus?

            public enum Focus: String, Codable, Hashable, Sendable {
                case none
                case `self`
                case series
            }
        }
    }

    /// An eCharts series type.
    enum SeriesType: String, Codable, Hashable, Sendable {
        case line
        case bar
        case scatter

        /// Cells with a colour for each value. It needs `chartOptions.visualMap` and the coordinate system `calendar` or `matrix`.
        /// Use it in an extra series of the gauge `custom`.
        case heatmap
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
    /// "chartOptions": { "version": 1, "yAxis": [{ "name": "Events" }, { "name": "Users", "position": "left" }], "grid": { "top": 40 } }
    /// ```
    struct ExtraSeries: Codable, Hashable, Sendable {
        public var type: SeriesType

        /// The component that gives the series its positions. Without it, the series uses the x axis and the y axis.
        /// The component must exist in `chartOptions`: `calendar`, `matrix`, or `singleAxis`.
        public var coordinateSystem: CoordinateSystem?

        /// The position of the axis for this series in `chartOptions.singleAxis`. `0` is the first axis.
        public var singleAxisIndex: Int?

        /// The name of the series in the legend and in the tooltip. Always set it. Without it, the tooltip line has no text.
        public var name: String?

        /// The name of the query that the series reads. Without it, the series reads the source query of the gauge.
        /// The series reads the result of the query as it is, before a breakdown.
        public var datasetId: String?

        /// The columns of the query that the series shows.
        public var encode: Encode?

        /// The fields of `Series`, without `type`. In JSON they are fields of the extra series itself.
        public var options: Series

        public typealias SeriesType = ClusterSpec.SeriesType

        public enum CoordinateSystem: String, Codable, Hashable, Sendable {
            case cartesian2d
            case calendar
            case matrix
            case singleAxis
        }

        /// A text is a column name. A number is the position of a column, and 0 is the first column.
        /// Use names. A position changes when the query gets a new column.
        /// A name that the query result does not have gives the error `columnNotFound`.
        public struct Encode: Codable, Hashable, Sendable {
            /// The column for the x axis.
            public var x: NumberOrText?

            /// The column for the y axis. The tooltip shows its value with the format of the column.
            public var y: NumberOrText?

            /// The column for the position on a single axis.
            public var single: NumberOrText?

            /// The time column for the days of a calendar.
            public var time: NumberOrText?

            /// The number column for the colour of a heatmap cell or for the size of a point on a single axis.
            public var value: NumberOrText?
        }

        private enum CodingKeys: String, CodingKey {
            case type
            case coordinateSystem
            case singleAxisIndex
            case name
            case datasetId
            case encode
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            type = try container.decode(SeriesType.self, forKey: .type)
            coordinateSystem = try container.decodeIfPresent(CoordinateSystem.self, forKey: .coordinateSystem)
            singleAxisIndex = try container.decodeIfPresent(Int.self, forKey: .singleAxisIndex)
            name = try container.decodeIfPresent(String.self, forKey: .name)
            datasetId = try container.decodeIfPresent(String.self, forKey: .datasetId)
            encode = try container.decodeIfPresent(Encode.self, forKey: .encode)
            options = try Series(from: decoder)
            // `type` is a field of the extra series, not of the options.
            options.type = nil
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encode(type, forKey: .type)
            try container.encodeIfPresent(coordinateSystem, forKey: .coordinateSystem)
            try container.encodeIfPresent(singleAxisIndex, forKey: .singleAxisIndex)
            try container.encodeIfPresent(name, forKey: .name)
            try container.encodeIfPresent(datasetId, forKey: .datasetId)
            try container.encodeIfPresent(encode, forKey: .encode)
            var options = options
            options.type = nil
            try options.encode(to: encoder)
        }
    }

    /// Options for the complete chart. It has no field for series or datasets.
    ///
    /// Version 1 holds eCharts options with the names of eCharts. A later version can hold a different format.
    /// `xAxis`, `yAxis`, and `dataZoom` are lists. Item 0 of a list merges into item 0 of the generated list.
    /// An axis that the gauge does not generate has no style and no column format from the gauge.
    struct ChartOptions: Codable, Hashable, Sendable {
        /// The version of the format of these options. Only version 1 exists.
        public var version: Int

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

        /// The tooltip. The text of the tooltip always comes from the web app or from eCharts. A spec cannot set it.
        public var tooltip: Tooltip?

        /// `true` draws the chart with an animation. The gauge has no animation by default.
        public var animation: Bool?

        /// The time of the first animation, in milliseconds. It applies only with `"animation": true`.
        /// `10000` draws the lines slowly from left to right.
        public var animationDuration: Double?

        /// Changes a number into a colour or into a symbol size. A heatmap needs it.
        public var visualMap: VisualMap?

        /// A calendar with one cell for each day. A series uses it with `"coordinateSystem": "calendar"`.
        ///
        /// This example shows a value for each day as a colour:
        ///
        /// ```json
        /// "gauge": "custom",
        /// "extraSeries": [
        ///   { "type": "heatmap", "coordinateSystem": "calendar", "encode": { "time": "day", "value": "percentOfBestDay" } }
        /// ],
        /// "chartOptions": {
        ///   "version": 1,
        ///   "visualMap": { "type": "piecewise", "min": 0, "max": 100, "orient": "horizontal", "left": "center", "top": 0 },
        ///   "calendar": { "top": 70, "left": 30, "right": 30, "cellSize": ["auto", 20], "range": ["2026-05-20", "2026-11-16"] }
        /// }
        /// ```
        public var calendar: Calendar?

        /// A table of cells with a row and a column for each category. A series uses it with `"coordinateSystem": "matrix"`.
        /// The series names its columns in `encode`: `{ "x": "weekday", "y": "type", "value": "events" }`.
        public var matrix: Matrix?

        /// Axes that stand alone. A series uses one with `"coordinateSystem": "singleAxis"` and `singleAxisIndex`.
        ///
        /// A series cannot filter the rows of a query. A chart with one axis for each category thus needs one query for each axis.
        /// Give each axis a `top` and a `height`, so that the axes are not on top of each other.
        public var singleAxis: [SingleAxis]?

        /// Text in the chart, for example a name for each single axis.
        public var title: [Title]?
    }

    struct Tooltip: Codable, Hashable, Sendable {
        /// `item` shows the tooltip for one point. `axis` shows it for each series at the x value of the pointer.
        /// The gauges with axes use `axis` by default. Use `item` for a scatter series with many points for each category.
        public var trigger: Trigger?

        /// The sequence of the series in the tooltip of eCharts. It applies only to the gauge `custom`.
        public var order: Order?

        public enum Trigger: String, Codable, Hashable, Sendable {
            case item
            case axis
            case none
        }

        public enum Order: String, Codable, Hashable, Sendable {
            case seriesAsc
            case seriesDesc
            case valueAsc
            case valueDesc
        }
    }

    /// Changes the value of one column into a colour or a symbol size.
    ///
    /// A visual map does not read its limits from the data. Without `min` and `max`, the colours are wrong.
    /// When the size of the values is not known, return a percentage of the maximum from the query and use the limits 0 and 100.
    struct VisualMap: Codable, Hashable, Sendable {
        /// `continuous` shows a colour bar. `piecewise` shows a small number of value ranges.
        public var type: MapType?

        /// `false` hides the control. The colours and the sizes still apply.
        public var show: Bool?

        /// The value for the first colour or the smallest size.
        public var min: Double?

        /// The value for the last colour or the largest size.
        public var max: Double?

        /// The position of the column with the value, and 0 is the first column. Without it, eCharts uses the last column.
        public var dimension: Int?

        /// `true` lets the user move the ends of a colour bar to hide values.
        public var calculable: Bool?

        public var orient: Legend.Orient?

        /// The distance from the top edge, in pixels, as a percentage, or as a word (`"middle"`).
        public var top: NumberOrText?
        public var bottom: NumberOrText?

        /// The distance from the left edge, in pixels, as a percentage, or as a word (`"center"`).
        public var left: NumberOrText?
        public var right: NumberOrText?

        /// The look for the values between `min` and `max`.
        public var inRange: Range?

        public enum MapType: String, Codable, Hashable, Sendable {
            case continuous
            case piecewise
        }

        public struct Range: Codable, Hashable, Sendable {
            /// CSS colour values as text, from the colour of `min` to the colour of `max`.
            public var color: [String]?

            /// The symbol sizes of `min` and `max`, in pixels: `[2, 36]`. Use it to show a value as the size of a point.
            public var symbolSize: [Double]?
        }
    }

    struct Calendar: Codable, Hashable, Sendable {
        public var top: NumberOrText?
        public var bottom: NumberOrText?
        public var left: NumberOrText?
        public var right: NumberOrText?

        /// The width and the height of a cell, in pixels or `"auto"`: `["auto", 20]`.
        public var cellSize: [NumberOrText]?

        /// The time that the calendar shows. One item is a year (`["2026"]`) or a month (`["2026-11"]`).
        /// Two items are the first day and the last day (`["2026-05-20", "2026-11-16"]`).
        /// The range is fixed text. A spec cannot make it follow the date range of the dashboard.
        public var range: [String]?

        public var orient: Legend.Orient?

        /// The look of the cells. `borderWidth` is the width of the lines between the cells.
        public var itemStyle: ItemStyle?

        public var yearLabel: Visibility?
        public var monthLabel: Visibility?
        public var dayLabel: Visibility?
    }

    struct Visibility: Codable, Hashable, Sendable {
        public var show: Bool?
    }

    struct Matrix: Codable, Hashable, Sendable {
        public var top: NumberOrText?
        public var bottom: NumberOrText?
        public var left: NumberOrText?
        public var right: NumberOrText?

        /// The columns of the matrix. Without `data`, eCharts makes one column for each value in the data, in the sequence of the rows.
        /// Set `data` to give the columns a fixed sequence, for example the weekdays.
        public var x: Dimension?

        /// The rows of the matrix.
        public var y: Dimension?

        public struct Dimension: Codable, Hashable, Sendable {
            public var show: Bool?
            public var data: [Cell]?
        }

        public struct Cell: Codable, Hashable, Sendable {
            /// The category as text. It must be equal to the value in the query result.
            public var value: String
        }
    }

    struct SingleAxis: Codable, Hashable, Sendable {
        public var top: NumberOrText?
        public var bottom: NumberOrText?
        public var left: NumberOrText?
        public var right: NumberOrText?

        /// The height of the area for the points, in pixels or as a percentage.
        public var height: NumberOrText?

        public var type: Axis.AxisType?
        public var min: NumberOrText?
        public var max: NumberOrText?

        /// The distance between two labels, as a value of the axis.
        public var interval: Double?

        /// The categories of an axis with the type `category`, in their sequence.
        public var data: [String]?
    }

    struct Title: Codable, Hashable, Sendable {
        /// Plain text. eCharts does not read it as HTML.
        public var text: String?

        public var top: NumberOrText?
        public var bottom: NumberOrText?
        public var left: NumberOrText?
        public var right: NumberOrText?

        /// The part of the text that is at the position `top`.
        public var textBaseline: Baseline?

        public enum Baseline: String, Codable, Hashable, Sendable {
            case top
            case middle
            case bottom
        }
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

        /// The categories of an axis with the type `category`, in their sequence.
        /// Without it, the categories have the sequence of the rows. Use it for a fixed sequence, for example the weekdays.
        /// A category that the query result does not have keeps its place on the axis.
        public var data: [String]?

        /// The distance between two labels, as a value of the axis.
        public var interval: Double?

        /// Only for a category axis with a scatter series: the width, in pixels, across which the points of one category spread.
        /// Points with the same category are then adjacent, not on top of each other. `80` is a good value for seven categories.
        public var jitter: Double?

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

        /// The width of the border, in pixels.
        public var borderWidth: Double?

        /// A CSS colour value as text.
        public var borderColor: String?
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
