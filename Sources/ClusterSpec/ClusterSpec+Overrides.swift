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

        /// `true` shows a symbol at each point of a line.
        public var showSymbol: Bool?

        /// The size of the symbols, in pixels.
        public var symbolSize: Double?

        public var lineStyle: LineStyle?

        /// The area below a line. An area style makes a line chart into an area chart.
        public var areaStyle: AreaStyle?

        public var itemStyle: ItemStyle?

        /// The width of a bar, in pixels or as a percentage (`"60%"`).
        public var barWidth: NumberOrText?

        /// The position of the y axis for this series in `echarts.yAxis`. `1` is the second y axis.
        public var yAxisIndex: Int?

        /// The text at each point, bar, or slice.
        public var label: Label?

        /// Lines at fixed values, for example a target.
        public var markLine: MarkLine?

        /// Areas between fixed values, for example a range of good values.
        public var markArea: MarkArea?

        public enum Step: String, Codable, Hashable, Sendable {
            case start
            case middle
            case end
        }
    }

    /// A series that the user adds after the generated series. It has all fields of `Series`.
    struct ExtraSeries: Codable, Hashable, Sendable {
        public var type: SeriesType

        /// The name of the series in the legend and in the tooltip.
        public var name: String?

        /// The name of the query that the series reads. Without it, the series reads the source query of the gauge.
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

        /// A text is a column name. A number is the position of a column.
        public struct Encode: Codable, Hashable, Sendable {
            public var x: NumberOrText?
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
    struct ChartOptions: Codable, Hashable, Sendable {
        /// The x axes. Item 0 is the axis that the gauge generates.
        public var xAxis: [Axis]?

        /// The y axes. Item 0 is the axis that the gauge generates. Item 1 adds a second y axis.
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

        /// The lowest value of the axis. A time value is text without an offset, in the time zone of the gauge.
        public var min: NumberOrText?

        /// The highest value of the axis. A time value is text without an offset, in the time zone of the gauge.
        public var max: NumberOrText?

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
            public var formatter: String?
        }
    }

    struct Legend: Codable, Hashable, Sendable {
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
        public var formatter: String?
    }

    struct MarkLine: Codable, Hashable, Sendable {
        /// One item for each line.
        public var data: [MarkPoint]?
        public var lineStyle: LineStyle?
        public var label: Label?
    }

    struct MarkArea: Codable, Hashable, Sendable {
        /// One item for each area. An item is a pair: the start corner and the end corner.
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
